# TODO: Phase 2+3 (Option B) - Family Linking Security Upgrade

## ✅ Planning
- [x] Analyze current family panel/linking implementation
- [x] Define Option B scope (dual-role + secure code flow)
- [x] Get user approval

## 🚧 Implementation Steps
- [ ] Upgrade `FamilyLinkManager` security model
  - [ ] 10-minute expiry
  - [ ] one-time-use enforcement
  - [ ] failed-attempt limit + lock
  - [ ] pending join request + father approval
- [ ] Update `FamilyDashboardViewModel`
  - [ ] father: generate code
  - [ ] family: submit code
  - [ ] father: approve/reject pending request
  - [ ] persist role/link settings
- [ ] Update `FamilyDashboardView`
  - [ ] add dual sections:
    - [ ] "أنا الأب" (generate code)
    - [ ] "أنا أحد أفراد العائلة" (enter code)
  - [ ] add pending-approval UI
  - [ ] keep linked status + alerts section
- [ ] Verify navigation from `EnhancedMainView` family button

## 🧪 Pending Testing (not executed yet)
- [ ] Build compile in Xcode (Sanad target)
- [ ] Father flow: generate code
- [ ] Family flow: enter valid code
- [ ] Father approval required before activation
- [ ] Wrong code lock after max attempts
- [ ] Expired code rejection
- [ ] Reuse code rejection after successful link
