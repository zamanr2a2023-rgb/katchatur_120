# Flutter Integration Guide — Door Welcome Overlay

**Status:** Active — handoff for the Flutter / mobile owner.  
**Admin repo:** Bajatzu admin SPA + Cloud Functions + Firestore rules.  
**Firebase project:** `bajatzu-51d09`  
**Related:** [`FLUTTER_CONTRACT_ADMIN_CONTROLS.md`](./FLUTTER_CONTRACT_ADMIN_CONTROLS.md) (canonical schema, status, QR payload).

When this file conflicts with older notes, **this file wins** for door-welcome behaviour only. Field names still follow the main Flutter contract.

---

## 0. Goal

When staff verify a member at the door (camera scan **or** manual payload) and the result is **success**, the **member app** shows a short welcome popup for a few seconds, then dismisses itself.

This is **not** the admin scanner “Welcome, {name}” card. That already exists on the web panel. This feature is **member-app only**.

Typical moment: member has the app open on the QR screen → staff scans → overlay appears on the phone → auto-hides after ~2–3 seconds.

---

## 1. What admin already does (do not duplicate)

| Step | Admin behaviour |
|------|-----------------|
| Parse QR | `bajatzu:{memberId}:{uid}` |
| Load member | `users/{uid}` |
| Allow visit | only if `status == "Active"` |
| On success | write `visits/{visitId}` with `result: "success"` |
| On deny | write `visits/{visitId}` with `result` like `"blocked"`, `"pending_approval"`, etc. |
| Camera vs manual | **same write**. You do not need two listeners. |

Admin does **not** send FCM, does **not** set a field on `users/{uid}`, and does **not** call any member callable.

**Your job:** listen for that visit row and show a one-shot overlay.

---

## 2. Prerequisite (ops / admin repo)

Members can read **their own** `visits` rows (`uid == request.auth.uid`). They still cannot create, update, or delete visits.

If the listener fails with `permission-denied`, rules are not deployed yet. Do not work around this by writing visits from Flutter or by polling `users/{uid}`.

Confirm with admin that rules **and** the `visits` composite index have been deployed:

```bash
firebase deploy --only firestore:rules,firestore:indexes --project bajatzu-51d09
```

---

## 3. Collection: `visits/{visitId}`

Admin-additive scan log. **Flutter never creates, updates, or deletes these documents.**

| Field | Type | Notes |
|-------|------|--------|
| `uid` | `string` | Firebase Auth uid. Always query `==` current user. |
| `fullName` | `string` | Snapshot at scan. Use for “Welcome, {name}”. |
| `memberId` | `string` | Public member id |
| `scannedAt` | `Timestamp` | Server time of the scan |
| `verifiedByAdminId` | `string` | Staff/admin uid. Display optional; do not treat as a customer. |
| `result` | `string` | See §3.1 |
| `qrPayload` | `string` | Raw payload. Do not display. |

Document ID = auto-id from admin `addDoc`. Use this id as the “already shown” key.

### 3.1 `result` values

| `result` | Show welcome? |
|----------|----------------|
| `"success"` | **Yes** |
| `"blocked"` | No |
| `"deactivated"` | No |
| `"pending_approval"` | No |
| `"rejected"` | No |
| `"invalid_payload"` | No |
| `"not_found"` | No |

Denied scans may still appear in the member’s visit history if you ever list them. The overlay is **success only**.

---

## 4. Firestore query (required shape)

Rules only allow a member to read docs where `uid == request.auth.uid`. The query **must** constrain `uid` or every snapshot will fail.

```dart
FirebaseFirestore.instance
    .collection('visits')
    .where('uid', isEqualTo: currentUid)
    .where('result', isEqualTo: 'success')
    .orderBy('scannedAt', descending: true)
    .limit(1)
    .snapshots();
```

Attach this while the member is signed in and `users/{uid}.status == "Active"`. Best surface: **QR / member-home screen** (the phone is already unlocked at the door).

Tear down the listener on sign-out / dispose.

### 4.1 Index

This query needs a composite index on `visits`:

- `uid` Ascending
- `result` Ascending
- `scannedAt` Descending

The admin repo ships this in `firestore.indexes.json`. If the first snapshot errors with `failed-precondition`, open the URL in that error (Firebase Console) and create the index. Wait until the index is **Enabled**.

---

## 5. When to show the overlay

On each snapshot:

1. If there are no docs → do nothing.
2. Read the newest doc (`limit(1)`).
3. **Skip the first snapshot** if it is an old visit (app open, last night’s scan). Treat the first emission as “catch-up”, not a door event — **unless** `scannedAt` is very recent (see freshness window).
4. Show only if **all** of the following are true:

   | Check | Rule |
   |-------|------|
   | Result | `result == "success"` (already in the query) |
   | New id | `visit.id` ≠ last shown id in local storage |
   | Fresh | `scannedAt` is within the last **30 seconds** (use 15–30s; do not use hours) |
   | Status | member is still `"Active"` |

5. After showing: persist `visit.id` locally (`SharedPreferences` / `Hive` / equivalent). Never show the same visit id twice on this device.
6. If `scannedAt` is still `null` (server timestamp pending), wait for the next snapshot instead of showing immediately with a bad clock.

### 5.1 Do not

- Show welcome on app cold start for historical visits.
- Show welcome for denied `result` values.
- Write `visits` from Flutter.
- Write `lastVerifiedAt` / `pendingWelcome` on `users/{uid}` (admin does not ship those fields; `selfUpdateAllowed` would reject them).
- Use FCM as the primary mechanism. The member’s app is already open.
- Poll in a timer loop. Use `snapshots()` only.

---

## 6. UI

Keep it short. This is a confirmation toast/overlay, not a new screen.

**Suggested copy**

- If `fullName` is non-empty: `Welcome, {fullName}`
- Else: `Welcome`

Optional subtitle (do not invent extra Firestore fields):

- `You're verified` or `Enjoy your visit`

**Behaviour**

- Full-screen dim overlay **or** centered card (either is fine).
- Auto-dismiss after **2–3 seconds**.
- No required button. An optional tap-to-dismiss is OK.
- Do not navigate away from the QR screen.
- Do not block scanning on the admin side (you have no control there).

Respect existing membership gates: if `status != "Active"`, the member should not be on this screen at all (see main contract §8).

---

## 7. Suggested Flutter structure

Keep Firebase out of widgets. Mirror admin’s service split:

1. `VisitWelcomeService` — starts/stops the query, maps the doc, exposes a stream of “show this visit once”.
2. Local store — `lastShownVisitId` (string).
3. Widget on QR / home — listens, shows overlay, starts a 2–3s timer, pops.

Map fields **exactly** (`uid`, `fullName`, `memberId`, `scannedAt`, `result`, `qrPayload`, `verifiedByAdminId`). Do not invent spellings.

Null-safe mapping: missing `fullName` → `"Welcome"` with no name.

---

## 8. Edge cases

| Case | Expected |
|------|----------|
| Staff scans while app is backgrounded | Overlay may be missed. That is OK. Do not persist a queue of welcomes. |
| Staff scans twice quickly | Show the newest fresh success; still skip ids already stored. |
| Visit write fails on admin | Admin UI may still say Welcome; Flutter will not fire. Not a Flutter bug. |
| `permission-denied` | Rules not deployed. Stop; do not retry with a collection-wide query. |
| Member id / uid mismatch denied on admin | `result` is not `"success"` → no overlay. |
| User signs out | Cancel listener; do not leak snapshots. |

---

## 9. End-to-end checklist (Flutter)

- [ ] Rules self-read deployed (confirm with admin; listener is not `permission-denied`)
- [ ] Composite index built for `uid` + `result` + `scannedAt`
- [ ] Listener only while signed in and Active
- [ ] Query always includes `where('uid', isEqualTo: currentUid)`
- [ ] Overlay only for `result == "success"`
- [ ] First/old snapshots ignored unless `scannedAt` is within ~30s
- [ ] Same `visit.id` never shown twice (local persistence)
- [ ] Copy: `Welcome, {fullName}` / `Welcome`
- [ ] Auto-hide in 2–3 seconds
- [ ] No Flutter writes to `visits` or new fields on `users/{uid}`
- [ ] Camera scan **and** admin manual verify both trigger the overlay (same `visits` write)

---

## 10. Manual QA (with admin)

1. Sign in as an **Active** test member; leave the QR / home screen open.
2. Admin: camera-scan that member’s QR → overlay appears within ~1–2s → hides after a few seconds.
3. Kill and reopen the member app → overlay must **not** replay.
4. Admin: scan again → overlay appears again (new visit id).
5. Admin: paste the same payload in **manual verify** → overlay appears.
6. Admin: scan a Blocked / Pending member (or the same user after Block) → **no** welcome on the member phone.
7. Confirm denied visits never show the welcome copy.

---

## 11. Out of scope

- Changing QR payload format (`bajatzu:{memberId}:{uid}` stays).
- Push notifications / FCM.
- Visit history UI in the member app (optional later; not required for this overlay).
- Admin scanner UI.
