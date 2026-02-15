# GAMELIFE

GAMELIFE is an iOS-first productivity RPG that turns real-world discipline into game progression.

Instead of a plain habit app, the user gets:
- clear quests
- instant XP/Gold feedback
- long-term "Boss" goals with HP
- automatic completion from Apple data sources when possible

The design language is inspired by a "system HUD" style (Solo Leveling influence), but the engine is practical: stateful models, explicit reward formulas, local persistence, and optional cloud/watch sync.

## Product Intent

GAMELIFE is built around one thesis:

> Real life has bad UX. Games have better UX.

So the app maps daily behavior into game systems:
- **Daily Quests** = low-friction repeatable actions
- **Boss Fights** = larger projects/goals broken into progress over time
- **Training** = deep-work sessions with stakes
- **Shop** = real-life rewards purchased with in-app gold
- **Status** = a visible identity layer (stats, level, activity log)

## Core Gameplay Model

### Player progression
- Player starts at **Level 1** with all six stats at **0**.
- Stats: `STR`, `INT`, `AGI`, `VIT`, `WIL`, `SPI`.
- Completing quests grants XP + gold + stat XP.
- Rank/title derive from level/rules in player models.
- HP is part of the loss-aversion loop and penalty mechanics.

### Quest system
- `DailyQuest` supports:
  - `manual`
  - `healthKit`
  - `screenTime`
  - `location`
  - `timer`
- Frequency options: hourly/daily/semi-weekly/weekly/monthly.
- Metric quests can show incremental progress bars.
- Reminders are integrated into schedule behavior.

### Boss system
- Classic boss: fixed HP, chipped away by linked quest completions.
- Dynamic boss: HP derives from real metrics (`DynamicBossGoal`):
  - weight
  - body fat
  - savings
  - workout consistency
  - screen-time discipline
- Dynamic bosses can auto-generate linked quests aligned to cadence.

### Training
- Focus timer with app-exit fail behavior.
- Can integrate Screen Time blocking during session (when enabled/authorized).

## Integrations (Neural Links)

### HealthKit
- Auto-tracks eligible quests (e.g. steps, workouts, stand minutes, etc.).
- Quest progress can auto-complete when target reached.
- Health data updates trigger quest sync and UI updates.

### Core Location
- Address/location quests use geofences + dwell-time progression.
- Location progress can fill live while user remains in range.
- Status API exposes whether quest is monitoring, in-range, invalid address, etc.

### Screen Time (FamilyControls + DeviceActivity)
- Tracks selected apps/categories for usage-based quests.
- DeviceActivity monitor extension can report threshold completions in background.
- Can optionally support focus blocking workflows.

Important for distribution:
- FamilyControls **distribution** entitlement must be approved by Apple for production/TestFlight behavior.
- Development entitlement may work locally but is not sufficient for broad distribution.

### Notifications
- Quest completions send OS notifications (immediate or digest mode).
- Reminder notifications support action flows.
- Screen Time extension can emit completion notifications.

### CloudKit sync
- Uses private CloudKit DB to sync game snapshot across Apple devices.
- No Sign in with Apple implementation is required for private CloudKit.
- Requires user signed into iCloud with CloudKit available.

### Apple Watch
- watchOS app + extension included.
- Watch receives snapshot (player + quests + activity summary).
- User can complete quests from watch; completion is relayed back to phone.

## Current App Flow

1. Splash
2. First-launch onboarding (`FirstLaunchSetupView`):
   - Name
   - Permission linking
   - Boss creation (skippable)
   - Quest creation
   - Stats explanation
   - Shop explanation
3. Main tabs:
   - Status
   - Quests
   - Training
   - Bosses
   - Shop

## Architecture Overview

### Core engine
- `GameEngine` is the central state + logic orchestrator (`@MainActor`, singleton).
- Owns player, quests, bosses, dungeon, penalties, loot, recent activity.
- Applies rewards, leveling, stat updates, boss damage, penalties, sync hooks.

### Data + persistence
- Data managers serialize/load models locally.
- App state is saved frequently and synced outward (CloudKit/watch) from engine.

### Managers
- `HealthKitManager`
- `LocationManager`
- `ScreenTimeManager`
- `QuestManager` (DeviceActivity scheduling and extension bridge)
- `NotificationManager`
- `CloudKitSyncManager`
- `WatchConnectivityManager`
- `PenaltyManager`, `TrainingManager`, `MarketplaceManager`

### UI layers
- Views are grouped by feature (`Status`, `Quests`, `Training`, `Bosses`, `Shop`, `Settings`, `Onboarding`).
- Shared visual system in `Design/SystemTheme.swift`.

## Project Structure

- `GAMELIFE/` main iOS app source
- `GAMELIFEMonitor/` DeviceActivity monitor extension
- `GAMELIFEWatch/` watch app container
- `GAMELIFEWatchExtension/` watch app logic/UI
- `Tests/` model tests + regression shell script
- `GAMELIFE.xcodeproj/` Xcode project

## Build and Run

### Recommended local simulator build

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project GAMELIFE.xcodeproj \
  -scheme GAMELIFE \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' \
  build
```

### Regression script

```bash
bash Tests/run_regression_checks.sh
```

Note:
- The script currently builds with `generic/platform=iOS Simulator`, which can fail when watch targets are present depending on local toolchain resolution.
- Use explicit simulator destination for reliable local verification.

## Configuration and Capabilities Checklist

### iOS target (`GAMELIFE`)
- iCloud + CloudKit
- HealthKit (+ background delivery)
- App Groups (`group.com.gamelife.shared`)
- Family Controls (if Screen Time feature enabled)
- Location usage descriptions (When In Use / Always+When In Use)
- Health usage descriptions (`NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription`)

### Monitor extension (`GAMELIFEMonitor`)
- Extension point: `com.apple.deviceactivity.monitor-extension`
- App group shared with main app
- Family Controls entitlement when screen-time monitoring active
- `CFBundleDisplayName` should be present in extension plist for archive/upload validation

## Feature Flag for Beta

`AppFeatureFlags.screenTimeEnabled` lives in:
- `GAMELIFE/Models/QuestModels.swift`

Use this to temporarily disable Screen Time flows during beta if entitlement/review timing blocks release.

When disabled, app should:
- hide Screen Time tracking options in UI
- skip Screen Time authorization/monitor wiring
- migrate existing screen-time quests/goals to safe fallback paths

## Known Operational Caveats

1. **FamilyControls distribution approval**
- Screen Time production behavior may be limited without Apple approval for distribution capability.

2. **Simulator realism limits**
- HealthKit, Screen Time, and geofencing behaviors differ from physical-device behavior.
- Treat simulator as UI/dev validation, not final integration truth.

3. **CloudKit availability**
- Sync requires iCloud account + CloudKit availability; manager exposes status/events.

## Recent Stability Hardening

To prevent refresh-time crashes:
- Pull-to-refresh in Quests is guarded against reentrancy.
- Async update loops now use ID snapshots + index re-lookup before mutation.
- This avoids stale-index crashes when arrays change during `await` points.

## Recommended Beta Test Scope

1. Manual quest lifecycle (create/edit/complete/reset)
2. HealthKit auto-complete and quest progress bars
3. Location address quest validation + dwell-time progress
4. Boss linking and dynamic-goal HP behavior
5. Reminder notifications + completion notifications
6. Cross-device sync (CloudKit)
7. Watch quest completion round-trip
8. Light/dark appearance and layout scaling across iPhone sizes

## Privacy / Data Summary

- Health and location data are used for quest progress automation.
- Screen Time data (when enabled) is used for usage-based quests.
- Data is stored locally and optionally synced via user private CloudKit.
- App-group shared storage is used between main app and monitor extension.

## Quick Start for New Developers

1. Open `GAMELIFE.xcodeproj`.
2. Confirm signing team and capabilities for all targets.
3. Verify app group + iCloud container IDs match your environment.
4. Build and run iOS app target.
5. Run regression checks.
6. Validate at least one quest flow per tracking type you plan to ship.

---

If you are shipping a beta quickly, keep Screen Time behind the feature flag until entitlement/distribution approval is confirmed end-to-end.
