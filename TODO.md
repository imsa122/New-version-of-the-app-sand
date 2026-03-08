# TODO: Phase 2 + Phase 3 Implementation (Approved)

## ✅ Planning & Scope Confirmation
- [x] User approved implementing **Phase 2 + 3 together**
- [x] User selected **Option B: 6-digit invite code linking**
- [x] Crash-safe CloudSyncManager already applied

---

## 📋 Implementation Tasks

### Phase 2: Enhanced Elder Features
- [x] Add app role/link settings fields in `AppSettings`
- [x] Add family link model (`FamilyLink.swift`)
- [ ] Add health check-in extensions for manual BP + prayer + medication confirmation
- [ ] Create `FamilyLinkManager` service
- [ ] Create `InactivityMonitor` service
- [ ] Extend `ActivityLogger` with new event categories
- [ ] Extend `HealthKitManager` with BP threshold evaluation helper
- [ ] Extend `MedicationTrackingManager` with explicit medication confirmation hooks

### Phase 3: Family Mode + Dashboard
- [ ] Create `FamilyModeSelectionView`
- [ ] Create `InviteCodeView` (generate code / enter code)
- [ ] Create `FamilyDashboardView`
- [ ] Create `FamilyDashboardViewModel`
- [ ] Update `HomeViewModel` for mode-aware behavior
- [ ] Update `SettingsViewModel` for role + invite/link management
- [ ] Update `EnhancedMainView` to route elder vs family mode
- [ ] Update `HealthDashboardView` with manual BP entry
- [ ] Update `MedicationListView` with “تم التناول” confirmation UX
- [ ] Update `PrayerTimesView` with post-prayer check-in action
- [ ] Update app entry/onboarding flow to include role selection

---

## 🧪 Verification Checklist
- [ ] Elder can generate 6-digit invite code
- [ ] Family can join using valid invite code
- [ ] Invalid invite code shows proper error
- [ ] Manual BP entry works and flags high/low values
- [ ] Inactivity alert triggers after configured threshold
- [ ] Medication “taken” confirmation updates activity log
- [ ] Prayer check-in writes status event
- [ ] Family dashboard reflects latest elder status/events
- [ ] No crashes navigating main app/settings/family views

---

## 🚀 Status
**In Progress** — starting with model + service foundation.
