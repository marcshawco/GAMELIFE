# PRAXIS

PRAXIS is an iOS-first behavior engine that turns real-world execution into RPG progression.

You do the work. PRAXIS closes the feedback loop instantly with quests, XP, Gold, boss damage, and visible character growth.

> Internal Xcode target names remain `GAMELIFE` for project continuity. User-facing product name is **PRAXIS**.

## TL;DR

- iOS productivity app with RPG systems (quests, bosses, stats, leveling, economy)
- Auto-tracking via HealthKit, Location, and optional Screen Time APIs
- Dynamic Bosses that react to real metric progress (weight, body fat, savings, workout consistency)
- CloudKit sync, watchOS companion, onboarding, achievements, and configurable death/streak mechanics

## Product Thesis

Most productivity tools are informational. PRAXIS is motivational infrastructure.

Real life fails on three things games do exceptionally well:

1. Clear objectives
2. Immediate feedback
3. Meaningful stakes

PRAXIS implements all three so discipline feels like progression, not friction.

## Core Loops

### 1) Quest Loop

- Tracking types: `manual`, `healthKit`, `screenTime` (optional), `location`, `timer`
- Cadence: hourly, daily, semi-weekly, weekly, monthly
- Optional quests:
  - grant XP and stat growth
  - grant no Gold
  - do not apply missed-quest HP damage
- Metric quests support incremental progress bars and diagnostics
- Reminders and completion flows are integrated

### 2) Boss Loop

- Standard bosses: fixed HP, quest completions deal damage
- Dynamic bosses (metric-driven):
  - weight goal
  - body fat goal
  - savings goal
  - workout consistency
  - screen-time discipline
- Dynamic configurations can auto-generate linked quests

### 3) Training Loop

- Structured focus sessions with complete/fail outcomes
- Hooks into XP, logs, and stat progression

### 4) Risk + Recovery Loop

- HP drops for missed required behavior
- Death mechanic (toggleable penalties):
  - one-rank demotion
  - rank-scaled stat reduction
  - 20% Gold loss
  - HP reset
  - post-death report modal
- If penalties are disabled, HP still depletes

### 5) Mastery + Identity Loop

- Six attributes: `STR`, `INT`, `AGI`, `VIT`, `WIL`, `SPI`
- Trophy Room + achievements with rarity tiers and rewards
- Persistent display preferences on Status dashboard

## Integrations (Neural Links)

### HealthKit

- Auto-progress and auto-complete for eligible health/activity quests
- Per-quest sync diagnostics

### Core Location

- Apple Maps address validation
- Geofence + dwell-time tracking
- Location status and progress surfaced in quest cards

### Screen Time (Optional)

- Uses `FamilyControls` + `DeviceActivity`
- App/category-driven usage quests
- Background completion through monitor extension
- TestFlight/App Store distribution requires Family Controls distribution entitlement

### Notifications

- Immediate or digest completion notifications
- Reminder notifications
- Foreground iOS banners suppressed while actively using PRAXIS (in-app feedback remains)

### CloudKit

- Private DB sync across Apple devices
- No Sign in with Apple required for private CloudKit sync

### watchOS

- Watch app + extension included
- WatchConnectivity relay for snapshots and quest actions

## Feature Highlights

- Status dashboard with radar/grid stat toggle and persisted preference
- Tabbed Activity/Achievements module with persisted preference
- Next Up prioritization for high-impact quests
- Undo completion pipeline with stat/economy reconciliation
- Marketplace rewards, including health potion recovery
- Haptic system with user-configurable toggle
- Multiple app icons with in-app switching
- Guided onboarding flow for first-run activation

## Architecture

### Source of Truth

`GameEngine` (`@MainActor`) owns canonical game state:

- player profile
- quests
- bosses
- activity logs
- penalties
- training sessions
- achievements

It also executes:

- XP/level/rank transitions
- stat mutations
- quest completion and undo logic
- boss damage and dynamic boss recalculation
- risk/death mechanics
- sync orchestration hooks

### Services

- `HealthKitManager`
- `LocationManager`
- `ScreenTimeManager`
- `QuestManager`
- `NotificationManager`
- `CloudKitSyncManager`
- `WatchConnectivityManager`
- `TrainingManager`
- `PenaltyManager`
- `MarketplaceManager`
- `HapticManager`

### Targets

- `GAMELIFE` (iOS app)
- `GAMELIFEMonitor` (DeviceActivity monitor extension)
- `GAMELIFEWatch` (watch app)
- `GAMELIFEWatchExtension` (watch extension)

## Performance + Local Caching

PRAXIS keeps runtime snapshots to reduce recomputation and improve launch/resume responsiveness.

`RuntimeCacheManager` caches:

- quest ordering
- daily HealthKit snapshot
- runtime location state
- achievement progress
- marketplace catalog
- status UI state

Currently wired:

- local-first HealthKit daily loads
- daily HealthKit snapshot persistence
- location state restore on launch

## Quickstart

### Requirements

- macOS + Xcode 16+
- iOS 18+ simulator/device (iOS 26.2 simulator used in repo workflows)
- Apple Developer account for full entitlement testing

### Build

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project GAMELIFE.xcodeproj \
  -scheme GAMELIFE \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' \
  build
```

### Run regression checks

```bash
bash Tests/run_regression_checks.sh
```

## Capabilities + Entitlements Checklist

### iOS target (`GAMELIFE`)

- iCloud + CloudKit
- HealthKit
- App Groups (`group.com.gamelife.shared`)
- Family Controls (if Screen Time is enabled)
- Location permissions (`When In Use`, `Always and When In Use`)
- Health usage descriptions in `Info.plist`

### Monitor extension (`GAMELIFEMonitor`)

- Extension point: `com.apple.deviceactivity.monitor-extension`
- Shared app group
- Family Controls entitlement
- Aligned bundle versions with containing app
- Required `Info.plist` metadata (including `CFBundleDisplayName`)

## Beta / Release Readiness Notes

- **Simulator logs include framework noise** (WatchConnectivity pairing, LaunchServices, haptics, RenderBox). Validate final behavior on physical devices.
- `WCSession counterpart app not installed` is expected when watch app is not paired/installed.
- Without Family Controls distribution entitlement, Screen Time features may be partially blocked outside development.
- iOS notification history may show stale icon assets after icon swaps due to system caching.

## Privacy Model

- Health and location data are used strictly for quest automation.
- Screen Time data (if enabled) is used only for usage-based quest progression.
- User game state is local-first and can sync to the user’s private CloudKit.
- App-group storage is used for app/extension communication.

## Roadmap Focus

Current beta core is stable. Near-term priorities:

1. Reliability hardening for all automation paths
2. Entitlement readiness for distribution environments
3. Metrics-driven balancing of risk/reward loops
4. Continuous UX refinement from beta feedback

---

Built for people who want execution to feel like progression.
