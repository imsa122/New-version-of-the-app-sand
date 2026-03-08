# TODO: Phase 2 + 3 (Option B) — Elder/Family Monitoring

## ✅ Completed
- [x] Add app mode/link fields in `AppSettings`
- [x] Add `FamilyLink` model
- [x] Add `FamilyLinkManager` service
- [x] Extend `ActivityType` for BP/inactivity/prayer/family events
- [x] Add `InactivityMonitor`
- [x] Add ActivityLogger helpers (`logBloodPressure`, `logPrayerCheckIn`)
- [x] Add medication confirmation hooks in `MedicationTrackingManager`
- [x] Add manual BP entry card in `HealthDashboardView`
- [x] Add prayer check-in in `PrayerTimesView`
- [x] Add inactivity bootstrap in `SanadApp`

## 🚧 In Progress (approved now)
- [ ] Create son-side Family Dashboard UI + ViewModel
- [ ] Add shared elder-status model/service (location/medication/BP/fall)
- [ ] Wire father-side events to publish elder status updates
- [ ] Add critical alert hooks for son notification flow (fall + low/high BP)
- [ ] Integrate Family mode navigation entry points

## 🧪 Pending Testing
- [ ] Build compile check (Sanad target)
- [ ] Critical-path manual test:
  - [ ] BP save + status + log
  - [ ] Prayer check-in log
  - [ ] Medication confirmation flow
  - [ ] Inactivity monitor elder/family mode behavior
  - [ ] Family dashboard reflects synced status
  - [ ] Critical alert events reach family alert feed
