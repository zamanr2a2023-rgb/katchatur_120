# Flutter Integration Guide — Bajatzu Member App

**Status:** Active — canonical handoff for the Flutter / mobile owner.  
**Admin repo:** this document is maintained with the Bajatzu admin SPA + Cloud Functions.  
**Firebase project:** `bajatzu-51d09`  
**TypeScript mirror:** [`src/types/index.ts`](../src/types/index.ts)

When this file conflicts with older notes, **this file wins**. Do not invent alternate field spellings.

Related: [`BACKEND_CONTRACT_MEMBERSHIP.md`](./BACKEND_CONTRACT_MEMBERSHIP.md) (membership deep-dive), [`FLUTTER_CONTRACT_DOOR_WELCOME.md`](./FLUTTER_CONTRACT_DOOR_WELCOME.md) (in-app welcome after a successful door scan), [`HANDOFF.md`](../HANDOFF.md) (ops), [`functions/README.md`](../functions/README.md) (callables).

---

## 0. What admin already ships (you only wire the member app)

| Area | Admin status |
|------|----------------|
| Membership queue Approve / Reject (+ required reason) | Live (M7 on by default) |
| Block / Unblock / Deactivate / Reactivate / Kick | Live |
| Auth disable + blocklist `beforeCreate` | Live (Functions) |
| In-store benefit 5% / 10% / clear (`memberDiscountPercent`) | Live |
| QR scanner deny for non-Active | Live |
| Staff panel RBAC | Live (operators only; not member accounts) |
| Storage rules `membership_proofs/` | Published from this repo |
| Firestore rules (Pending create, no self-approve) | Published from this repo |

**Your job:** signup → Pending + proof upload, status screens, benefit read, Auth error handling, QR payload unchanged. When you ship that, the product loop is complete.

---

## 1. Firebase configuration (same project as admin)

Use the **same** Firebase web/mobile config as the admin SPA (project `bajatzu-51d09`).

| Item | Value / note |
|------|----------------|
| Project ID | `bajatzu-51d09` |
| Auth | Email/password (and any providers you already use) |
| Firestore | `(default)` database |
| Storage bucket | Same as `VITE_FIREBASE_STORAGE_BUCKET` in admin `.env` |
| Functions region | `us-central1` |
| Callables members may hit | **None required** for membership. Admin callables are panel-only. |

Initialize FlutterFire with this project. Do not point at a second Firebase project.

---

## 2. Schema — `users/{uid}`

Document ID = Firebase Auth `uid`.

### 2.1 Status (PascalCase strings)

| `status` | Member home? | Door QR? | Who sets it |
|----------|--------------|----------|-------------|
| `"Pending"` | No — waiting screen | No | Flutter on signup / resubmit |
| `"Active"` | Yes | Yes | Admin approve / unblock / reactivate |
| `"Rejected"` | No — reason + resubmit | No | Admin reject |
| `"Blocked"` | No — blocked screen | No | Admin block |
| `"Deactivated"` | No — deactivated screen | No | Admin deactivate |

Missing / unknown `status` on **legacy** reads: treat as `"Active"` so old members do not brick. **New creates must write `"Pending"`** (Firestore rules enforce this).

### 2.2 Core fields (keep existing production names)

| Field | Type | Written by | Notes |
|-------|------|------------|-------|
| `email` | `string` | Flutter | |
| `fullName` | `string` | Flutter | |
| `phone` | `string` | Flutter | |
| `memberId` | `string` | Flutter | Stable public id |
| `qrPayload` | `string` | Flutter | Exact format below |
| `tier` | `string` | Flutter | Existing product field |
| `status` | `string` | Both | See transitions |
| `createdAt` | `Timestamp` | Flutter | On create |
| `photoURL` | `string` | Flutter | Optional |

### 2.3 Membership / benefit fields

| Field | Type | Written by | Notes |
|-------|------|------------|-------|
| `reviewProofPath` | `string` | Flutter | Storage **path**, not download URL |
| `reviewPlatform` | `"google"` \| `"tripadvisor"` | Flutter | |
| `submittedAt` | `Timestamp` | Flutter | Last proof submit |
| `resubmissionCount` | `number` | Flutter | +1 each resubmit; first omit or `0` |
| `rejectionReason` | `string` | Admin reject; Flutter clears on resubmit | Show on Rejected screen |
| `reviewedAt` | `Timestamp` | Admin only | |
| `reviewedByAdminId` | `string` | Admin only | |
| `memberDiscountPercent` | `number` | Admin (approve → `10`; or set 5/10/clear) | Prefer for UI |
| `memberBenefit5Percent` | `boolean` | Legacy | Read **only** if percent absent. Never write. |

### 2.4 Panel-only fields (never write from Flutter)

| Field | Notes |
|-------|--------|
| `role` | `"admin"` \| `"staff"` — panel operators only |
| `permissions` | Staff capability map |
| `staffMeta` | Staff grant/revoke metadata |

Customers omit these. Rules reject client creates with `role` admin/staff.

---

## 3. QR payload (unchanged)

```text
bajatzu:{memberId}:{uid}
```

Example: `bajatzu:BJZ-5218:YtFy7PaGlQYloHKwAP3ZZsAldcn2`

Admin scanner parses this, loads `users/{uid}`, allows visit only if `status == "Active"`.

---

## 4. Storage — review proof

### Enable Storage once (ops)

If deploy fails with “Firebase Storage has not been set up”, open  
https://console.firebase.google.com/project/bajatzu-51d09/storage → **Get Started**, then:

```bash
firebase deploy --only storage --project bajatzu-51d09
```

Rules file: [`storage.rules`](../storage.rules).

### Path

```text
membership_proofs/{uid}/{timestampMs}.{ext}
```

- `uid` must equal Auth uid and Firestore doc id  
- `ext`: `jpg` | `jpeg` | `png` | `webp`  
- Max **5 MiB**, `contentType` `image/*`  
- Store only the path on the user doc, e.g. `membership_proofs/abc/1725400000000.jpg`  
- On resubmit: **new** object (new timestamp). Do not reuse the path.

### Rules (in repo)

- Applicant: read/write own folder  
- Admin or staff with `permissions.membership`: read  
- Not publicly readable  

---

## 5. State machine

```text
signup (+ proof)              → Pending
Pending  + admin Approve      → Active  (+ memberDiscountPercent = 10)
Pending  + admin Reject       → Rejected (+ rejectionReason required)
Rejected + new proof          → Pending  (clear rejectionReason; bump resubmissionCount)
Active   + admin Block        → Blocked  (+ Auth disabled + blocklist row)
Blocked  + admin Unblock      → Active   (+ Auth enabled)
Active   + admin Deactivate   → Deactivated (+ Auth disabled)
Deactivated + Reactivate      → Active   (+ Auth enabled)
Kick                          → Auth refresh tokens revoked; status unchanged
```

**Flutter must never set:** `Active`, `Blocked`, `Deactivated`, `memberDiscountPercent`, `reviewedAt`, `reviewedByAdminId`.

---

## 6. Flutter writes

### 6.1 Signup (after Auth user exists)

1. Upload image → Storage path above.  
2. `setDoc` / `create` `users/{uid}` with core fields **and**:

```text
status: "Pending"
reviewProofPath: "membership_proofs/{uid}/{ts}.jpg"
reviewPlatform: "google" | "tripadvisor"
submittedAt: serverTimestamp()
memberId, qrPayload, email, fullName, phone, tier, createdAt, …
```

Do **not** set `memberDiscountPercent` at signup.

Firestore **create** rule: self + `status == "Pending"` + no panel `role`.

### 6.2 Resubmit (from `"Rejected"`)

1. Upload a **new** Storage object.  
2. `updateDoc`:

| Field | Value |
|-------|--------|
| `status` | `"Pending"` |
| `reviewProofPath` | new path |
| `reviewPlatform` | platform |
| `submittedAt` | `serverTimestamp()` |
| `resubmissionCount` | previous + 1 |
| `rejectionReason` | `deleteField()` or `""` |

Allowed only when current status is `Pending` or `Rejected` and new status is `Pending`.

### 6.3 Profile edits while Active

Update allowed profile fields only; **do not** include `status` in the update (leave Active untouched).

---

## 7. Admin writes (for your reads / UI)

### Approve

| Field | Value |
|-------|--------|
| `status` | `"Active"` |
| `memberDiscountPercent` | `10` |
| `reviewedAt` | server time |
| `reviewedByAdminId` | admin uid |

### Reject

| Field | Value |
|-------|--------|
| `status` | `"Rejected"` |
| `rejectionReason` | non-empty string |
| `reviewedAt` | server time |
| `reviewedByAdminId` | admin uid |

### Benefit (customer detail)

Admin may set `memberDiscountPercent` to `5` or `10`, or delete the field (clear).

### Block / Deactivate / etc.

See §9. Status + Auth side effects.

---

## 8. Post-login gate (required)

Auth can succeed even when Firestore `status` is not Active. **Rules cannot block login.**

1. After Auth success → `getDoc(users/{uid})`.  
2. If member and `status != "Active"` → do **not** enter member home (status screen and/or sign out).  
3. Re-check on app resume / ID token refresh so Approve / Unblock / Reactivate unlocks without reinstall.

Suggested copy:

| Status | Screen |
|--------|--------|
| Pending | “Your membership is waiting for review.” |
| Rejected | Show `rejectionReason` + “Submit new proof”. |
| Blocked | “This account is blocked. Contact support if you believe this is an error.” |
| Deactivated | “This account is deactivated. Contact support to reactivate.” |

Optional: treat `role == "admin"` as allowed for an internal Flutter surface; **customers** still need `"Active"`.

---

## 9. Auth side effects (Cloud Functions — admin calls these)

Region: **`us-central1`**. Members do not call these; you only handle the Auth client outcomes.

| Callable | Payload | Effect |
|----------|---------|--------|
| `setAuthDisabled` | `{ uid: string, disabled: boolean }` | Block/Deactivate → `true`; Unblock/Reactivate → `false` |
| `revokeUserSession` | `{ uid: string }` | Kick — `revokeRefreshTokens` |

| Admin action | Firestore | Auth |
|--------------|-----------|------|
| Block | `status: "Blocked"` + `blocked_identifiers` row | `disabled: true` (+ best-effort Kick) |
| Unblock | `status: "Active"` | `disabled: false` |
| Deactivate | `status: "Deactivated"` | `disabled: true` |
| Reactivate | `status: "Active"` | `disabled: false` |
| Kick | unchanged | refresh tokens revoked |

Flutter must:

- Handle `user-disabled` on sign-in with friendly copy.  
- After Kick, force re-auth when the ID token fails.  
- Still gate on Firestore `status` (do not rely on Auth disable alone).

### Blocklist signup

Auth blocking function `beforeCreate` rejects signup when email (primary) or phone (when present) matches `blocked_identifiers`. Show a clear registration error (e.g. “This email is blocked from registering.”). Identity Platform blocking functions must be enabled in Firebase Console (ops).

---

## 10. In-store benefit read rule

1. If `memberDiscountPercent` is a number → show that % (5 or 10).  
2. Else if `memberBenefit5Percent === true` → show 5% (legacy only).  
3. Else → no benefit badge.

Approve sets `10`. Admin can later change to 5/10/clear on the customer page.

---

## 11. Collection: `blocked_identifiers/{id}` (admin-written)

| Field | Type |
|-------|------|
| `email` | lower-case string |
| `phone` | digits / E.164-ish |
| `uid` | source Auth uid |
| `blockedByAdminId` | admin uid |
| `blockedAt` | Timestamp |

Client read/write not required for Flutter.

---

## 12. Collection: `visits/{id}` (admin scanner)

Admin appends scan logs. You do not write visits from the member app for door verification.

Members **may read their own** rows (`uid == Auth uid`) to show a short welcome overlay after a successful scan. Full instructions: [`FLUTTER_CONTRACT_DOOR_WELCOME.md`](./FLUTTER_CONTRACT_DOOR_WELCOME.md).

Denied results you may see in admin history: `pending_approval`, `rejected`, `blocked`, `deactivated`, etc. Do **not** show the welcome overlay unless `result == "success"`.

---

## 13. Staff / admin panel accounts

`role: "admin"` | `"staff"` are **web panel operators**, not club members. Created via Admin SDK (`upsertStaffAccess`). Do not treat them as normal customers in member home unless you explicitly productize that.

---

## 14. End-to-end checklist (Flutter)

- [ ] Signup uploads proof to `membership_proofs/{uid}/{ts}.{ext}`
- [ ] Signup creates `users/{uid}` with `status: "Pending"` + path/platform/`submittedAt`
- [ ] Pending screen after login; no member home
- [ ] Rejected screen shows `rejectionReason` + resubmit
- [ ] Resubmit → new Storage object + back to Pending
- [ ] Active → member home; benefit from `memberDiscountPercent`
- [ ] Blocked / Deactivated screens distinct
- [ ] `user-disabled` and Kick / invalid token handled
- [ ] Blocked signup (`beforeCreate`) friendly error
- [ ] QR payload remains `bajatzu:{memberId}:{uid}`
- [ ] Door welcome overlay after successful scan — see [`FLUTTER_CONTRACT_DOOR_WELCOME.md`](./FLUTTER_CONTRACT_DOOR_WELCOME.md)
- [ ] Never write `role` / `permissions` / `staffMeta` / `memberDiscountPercent` / `reviewed*`
- [ ] Field names match this doc exactly (PascalCase statuses, camelCase fields)

---

## 15. Admin verification after you wire

1. New signup appears under **Membership** (and Customers → Pending).  
2. Proof image loads on review.  
3. Reject requires a reason; app shows it.  
4. Approve → Active + 10% benefit; QR scan succeeds.  
5. Block / Deactivate disable login; Unblock / Reactivate restore.
