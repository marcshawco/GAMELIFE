# PRAXIS (Project: GAMELIFE)

PRAXIS is an iOS-first productivity RPG that turns real-world discipline into visible game progression.

User-facing brand is **PRAXIS**. Internal project/target names still use `GAMELIFE` for build/signing continuity.

## Product Purpose

PRAXIS applies game UX to real-life behavior:
- clear objectives (quests)
- immediate feedback (XP, Gold, stat growth)
- long-loop goals (bosses)
- loss/recovery loops (HP + penalties)
- passive automation when Apple data is available

## Core Systems

### Player progression
- Starts at Level 1 with six stats at 0: `STR`, `INT`, `AGI`, `VIT`, `WIL`, `SPI`.
- Quests grant XP and stat growth.
- Gold is granted for non-optional quests.
- Rank/title derives from progression rules.
- HP drives consequences for missed daily behavior.

### Quest system
- Tracking types:
  - `manual`
  - `healthKit`
  - `screenTime`
  - `location`
  - `timer`
- Frequency supports hourly/daily/semi-weekly/weekly/monthly.
- Optional quests supported:
  - grant XP/stats
  - grant no Gold
  - do not trigger missed-quest HP damage
- Metric-based quests can show incremental progress bars.
- Supports reminders and in-app completion flow.

### Boss system
- Standard bosses: fixed HP, damaged by linked quest completions.
- Dynamic bosses support metric-driven HP modeling:
  - weight goal
  - body-fat goal
  - savings goal
  - workout consistency
  - screen-time discipline
- Dynamic bosses can auto-generate linked quests to match cadence/targets.

### Training
- Focus timer with completion/failure outcomes.
- Rewards and progression hooks integrated with engine.

### Death mechanic
- Configurable toggle in Settings: **Death Mechanic Penalties**.
- If enabled and HP hits 0:
  - rank can demote by 1 tier
  - stats are reduced by rank-scaled penalties
  - 20% Gold loss
  - HP reset to full
  - death report UI is shown
- If disabled:
  - HP can still deplete
  - death penalties are not applied

### Achievements / Trophy Room
- Achievement catalog with rarity and category model.
- Unlock rewards can include XP, Gold, and titles.
- Recent achievements strip on Status.
- Trophy Room view with unlock/progress states.

### Shop / economy
- Marketplace rewards with purchase history.
- Includes streak protection and health potion style rewards.
- Purchase + redemption flows update engine state and activity log.

## Integrations (Neural Links)

### HealthKit
- Reads eligible activity/health metrics for auto-progress.
- Can auto-complete quests when thresholds are reached.
- Sync diagnostics available per quest.

### Core Location
- Address validation and geofence tracking.
- Dwell-time progress support for location quests.
- Auto-complete available when in-radius for required duration.

### Screen Time (FamilyControls + DeviceActivity)
- Usage-based quest tracking via selected apps/categories.
- Extension-driven background threshold events.
- Requires FamilyControls distribution entitlement for production behavior.

### Notifications
- Quest completion notifications (immediate/digest style).
- Reminder notifications.
- In-app + OS-level messaging paths.

### CloudKit
- Private database sync for cross-device state.
- No Sign in with Apple flow required for private CloudKit usage.

### watchOS
- Watch app and extension present.
- Snapshot relay and quest completion relay supported via WatchConnectivity.

## Performance and Caching

PRAXIS now uses local runtime caching to reduce expensive re-fetches and speed up UI hydration:

- `RuntimeCacheManager` (`GAMELIFE/Services/DataManagers.swift`)
  - quest ordering snapshot
  - health daily snapshot
  - location runtime snapshot
  - achievement progress snapshot
  - marketplace catalog snapshot
  - status UI snapshot

Implemented paths currently wired:
- HealthKit daily snapshot load/save (`HealthKitManager`)
- Local-first daily progress checks for HealthKit daily quests (`HealthKitManager`)
- Location runtime state load/save (`LocationManager`)

## UI / Settings Features

- Default tab picker
- Appearance controls (system/dark)
- App icon picker with multiple icon variants
- Haptic feedback toggle (multi-strength usage across interactions)
- Quest completion alert mode
- Death mechanic penalties toggle + explanatory info

## App Flow

1. Splash
2. First launch onboarding:
   - name
   - permission linking
   - boss creation (skippable)
   - quest creation
   - stats explanation
   - shop explanation
3. Main tabs:
   - Status
   - Quests
   - Training
   - Bosses
   - Shop

## Architecture

### Core engine
- `GameEngine` is `@MainActor` orchestrator and source of truth.
- Owns player, quests, bosses, penalties, training state, recent activity.
- Handles rewards, level-ups, boss damage, quest undo, penalties, sync hooks, achievements.

### Managers
- `HealthKitManager`
- `LocationManager`
- `ScreenTimeManager`
- `QuestManager`
- `NotificationManager`
- `CloudKitSyncManager`
- `WatchConnectivityManager`
- `PenaltyManager`
- `TrainingManager`
- `MarketplaceManager`
- `HapticManager`

### Project layout
- `GAMELIFE/` main iOS app
- `GAMELIFEMonitor/` DeviceActivity monitor extension
- `GAMELIFEWatch/` watch app target
- `GAMELIFEWatchExtension/` watch extension
- `Tests/` tests + regression scripts
- `GAMELIFE.xcodeproj/` project

## Build and Test

### Simulator build (recommended)

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

## Capabilities Checklist

### iOS target (`GAMELIFE`)
- iCloud + CloudKit
- HealthKit
- App Groups (`group.com.gamelife.shared`)
- Family Controls (if Screen Time features are enabled)
- Location usage strings (`When In Use`, `Always and When In Use`)
- Health usage strings (`NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription`)

### Monitor extension (`GAMELIFEMonitor`)
- `com.apple.deviceactivity.monitor-extension`
- Shared app group
- Family Controls entitlement for screen-time monitoring
- Valid extension plist metadata (`CFBundleDisplayName`, version alignment)

## Release / Beta Notes

- If FamilyControls distribution approval is missing, Screen Time features may work only in limited/dev contexts.
- Simulator output includes many non-actionable platform noise logs (LaunchServices, haptic library, watch pairing, etc.). Validate critical behavior primarily on physical devices.
- Alternate app icon changes can lag in notification banner history due to iOS cache behavior.

## Privacy Summary

- Health and location data are used for automation only.
- Screen Time data (when enabled) is used for usage-based quests.
- Data persists locally and can sync through private CloudKit.
- App-group storage is used for app/extension coordination.
