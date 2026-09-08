# Backend / Mobile Contract — Membership Approval (M7)

**Status:** Active — admin SPA + Storage/Firestore rules ship this contract. Flutter must implement signup / gate / resubmit per this file and the master guide.  
**Canonical Flutter handoff:** [`FLUTTER_CONTRACT_ADMIN_CONTROLS.md`](./FLUTTER_CONTRACT_ADMIN_CONTROLS.md) (complete schema, Auth, benefit, QR, checklists).  
**Owner of this repo:** admin SPA, Cloud Functions, Firestore rules, Storage rules.  
**TypeScript mirror:** [`src/types/index.ts`](../src/types/index.ts).

If field names conflict with live Flutter, **stop and reconcile** — do not invent a second spelling.

---

## 1. What Flutter must implement

1. On signup, create `users/{uid}` with `status: "Pending"` and a review-proof image in Storage.  
2. Gate the member app so non-`"Active"` accounts cannot use member home after Auth sign-in.  
3. On rejection, upload new proof and flip the same user doc back to `"Pending"`.  
4. Read `memberDiscountPercent` for in-store benefit UI.

Admin already: lists Pending/Rejected, shows proof, Approve (→ Active + 10%), Reject (required `rejectionReason`).

---

## 2. Auth login cannot be blocked by Firestore rules

Firebase Auth can succeed regardless of `users/{uid}.status`.

**Required Flutter behaviour:**

1. After Auth succeeds, `getDoc(users/{uid})`.  
2. If `status` is not `"Active"` (members), do not enter member home — status screen and/or sign out.  
3. Re-check on resume / token refresh.

| `status` | Suggested copy |
|----------|----------------|
| `"Pending"` | “Your membership is waiting for review.” |
| `"Rejected"` | Show `rejectionReason` + “Submit new proof.” |
| `"Blocked"` | “This account is blocked…” |
| `"Deactivated"` | “This account is deactivated…” |

**Optional hardening:** Auth `disabled` while not Active — admin already disables Auth on Block/Deactivate via `setAuthDisabled`. Do not rely on that alone for Pending/Rejected.

---

## 3. `users/{uid}` — status and membership fields

### 3.1 Status (PascalCase)

| Value | Member home? | QR visit? |
|-------|--------------|-----------|
| `"Active"` | Yes | Yes |
| `"Pending"` | No | No — `pending_approval` |
| `"Rejected"` | No | No — `rejected` |
| `"Blocked"` | No | No — `blocked` |
| `"Deactivated"` | No | No — `deactivated` |

Legacy docs without `status`: admin mapper treats as `"Active"`. **New creates must be `"Pending"`** (enforced in Firestore rules).

### 3.2 Membership fields

| Field | Type | Written by | Notes |
|-------|------|------------|-------|
| `reviewProofPath` | `string` | Flutter | Storage path, not URL. Example: `membership_proofs/{uid}/1725400000000.jpg` |
| `reviewPlatform` | `"google"` \| `"tripadvisor"` | Flutter | |
| `submittedAt` | `Timestamp` | Flutter | |
| `reviewedAt` | `Timestamp` | Admin | |
| `reviewedByAdminId` | `string` | Admin | |
| `rejectionReason` | `string` | Admin on reject; Flutter clears on resubmit | |
| `resubmissionCount` | `number` | Flutter | |
| `memberDiscountPercent` | `number` | Admin | `10` on approve; may later be 5/10/clear |
| `memberBenefit5Percent` | `boolean` | Legacy | Read only if percent absent. Admin never writes. |

Do not rename existing production fields (`email`, `fullName`, `memberId`, `phone`, `qrPayload`, `tier`, `createdAt`, …).

---

## 4. Storage path

```text
gs://<bucket>/membership_proofs/{uid}/{timestamp}.{ext}
```

- Max **5 MiB**, `image/*`  
- Store **only** `reviewProofPath` on the user doc  
- Resubmit = new object / new timestamp  

Rules file in this repo: [`storage.rules`](../storage.rules) (applicant R/W own folder; admin / membership staff read).

---

## 5. State transitions

```text
signup / first write     → Pending
Pending  + admin approve → Active   (+ memberDiscountPercent = 10)
Pending  + admin reject  → Rejected (+ rejectionReason required)
Rejected + new proof     → Pending  (new path, submittedAt, resubmissionCount++, clear rejectionReason)
Active   + admin block   → Blocked
Blocked  + admin unblock → Active
Active   + deactivate    → Deactivated
Deactivated + reactivate → Active
```

Forbidden for Flutter:

- Setting `status` to `"Active"`, `"Blocked"`, or `"Deactivated"`  
- Writing `memberDiscountPercent`, `reviewedAt`, `reviewedByAdminId`  
- Writing `role` / `permissions` / `staffMeta`  

Admin must not upload or overwrite the proof image.

---

## 6. Admin panel writes

### Approve

| Field | Value |
|-------|--------|
| `status` | `"Active"` |
| `memberDiscountPercent` | `10` |
| `reviewedAt` | `serverTimestamp()` |
| `reviewedByAdminId` | admin uid |

Does not clear `reviewProofPath`. Does not write `memberBenefit5Percent`.

### Reject

| Field | Value |
|-------|--------|
| `status` | `"Rejected"` |
| `rejectionReason` | non-empty string |
| `reviewedAt` | `serverTimestamp()` |
| `reviewedByAdminId` | admin uid |

UI: Membership review → Reject dialog requires a reason before confirm.

---

## 7. Flutter writes

### Signup

After Auth user exists: upload proof, then create `users/{uid}` with production fields **plus** `status: "Pending"`, `reviewProofPath`, `reviewPlatform`, `submittedAt`, and existing `memberId` / `qrPayload` generation.

### Resubmit

New Storage object + update: `status: "Pending"`, new path/platform/`submittedAt`, `resubmissionCount + 1`, clear `rejectionReason`.

---

## 8. Security rules (this repo)

### Firestore ([`firestore.rules`](../firestore.rules))

- Create: self + `status == "Pending"` + no panel role  
- Self update: cannot set Active/Blocked/Deactivated; status change only to `Pending` from `Pending`|`Rejected`  
- Membership decision: `hasPerm('membership')` may write approve/reject fields  
- Moderation / benefit / admin updates as documented in rules  

### Storage ([`storage.rules`](../storage.rules))

See §4. Deploy: `firebase deploy --only storage`.

---

## 9. QR / visit results (admin)

| `users.status` | `visits.result` |
|----------------|-----------------|
| `"Pending"` | `"pending_approval"` |
| `"Rejected"` | `"rejected"` |
| `"Blocked"` | `"blocked"` |
| `"Deactivated"` | `"deactivated"` |

---

## 10. Feature flag (admin SPA)

Membership UI is **on by default**. Hide only with:

```env
VITE_ENABLE_MEMBERSHIP_APPROVAL=false
```

Routes: `/membership`, `/membership/:uid` (requires `membership` permission or admin).

---

## 11. Confirmation checklist

- [ ] Signup → Pending + proof path + platform + `submittedAt`  
- [ ] Flutter blocks member home when `status != "Active"`  
- [ ] Rejected users can resubmit → Pending  
- [ ] Storage rules deployed; proof not public  
- [ ] Flutter reads `memberDiscountPercent`  
- [ ] Reject reason shown from `rejectionReason`  
- [ ] Field names match exactly  
- [ ] Full guide checklist in [`FLUTTER_CONTRACT_ADMIN_CONTROLS.md`](./FLUTTER_CONTRACT_ADMIN_CONTROLS.md) §14
