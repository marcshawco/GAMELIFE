#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT/GAMELIFE.xcodeproj"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

echo "Running static regression checks..."

grep -q 'INFOPLIST_KEY_NSHealthShareUsageDescription' "$PROJECT/project.pbxproj" || fail "Missing NSHealthShareUsageDescription"
grep -q 'INFOPLIST_KEY_NSHealthUpdateUsageDescription' "$PROJECT/project.pbxproj" || fail "Missing NSHealthUpdateUsageDescription required by App Store HealthKit validation"
if grep -q 'INFOPLIST_KEY_NSHealthClinicalHealthRecordsShareUsageDescription' "$PROJECT/project.pbxproj"; then
  fail "Clinical health records usage description should not be present without clinical record access"
fi
grep -Fq 'requestAuthorization(toShare: [], read: readTypes)' "$ROOT/GAMELIFE/Services/HealthKitManager.swift" || fail "HealthKit authorization should remain read-only"
grep -q 'INFOPLIST_KEY_NSLocationWhenInUseUsageDescription = "' "$PROJECT/project.pbxproj" || fail "Missing NSLocationWhenInUseUsageDescription"
grep -q 'INFOPLIST_KEY_NSLocationAlwaysAndWhenInUseUsageDescription = "' "$PROJECT/project.pbxproj" || fail "Missing NSLocationAlwaysAndWhenInUseUsageDescription"
grep -q 'NSPrivacyAccessedAPICategoryUserDefaults' "$ROOT/GAMELIFE/PrivacyInfo.xcprivacy" || fail "App privacy manifest missing UserDefaults required-reason declaration"
grep -q 'NSPrivacyAccessedAPICategoryUserDefaults' "$ROOT/PRAXISWidgets/PrivacyInfo.xcprivacy" || fail "Widget privacy manifest missing UserDefaults required-reason declaration"

APP_ICON_SUPPORT="$ROOT/GAMELIFE/Services/AppIconSupport.swift"
APP_ICON_SETTINGS="$ROOT/GAMELIFE/Views/Settings/SettingsView.swift"
APP_ICON_NAMES=(
  AppIconPrismGold
  AppIconPrismCrimson
  AppIconPrismSolar
  AppIconPrismVerdant
)

grep -q 'AppIconStateResolver.resolve' "$APP_ICON_SETTINGS" || fail "App icon manager should resolve state from the actual system icon"
if grep -Fq 'currentOption = storedOption ?? .signal' "$APP_ICON_SETTINGS"; then
  fail "App icon manager should not display stale stored selections when the system icon is default"
fi
for icon_name in "${APP_ICON_NAMES[@]}"; do
  grep -Fq "$icon_name" "$PROJECT/project.pbxproj" || fail "Missing alternate app icon build setting for $icon_name"
  grep -Fq "\"$icon_name\"" "$APP_ICON_SUPPORT" || fail "Missing AppIconOption mapping for $icon_name"
  [[ -d "$ROOT/GAMELIFE/Assets.xcassets/$icon_name.appiconset" ]] || fail "Missing asset catalog appiconset for $icon_name"
done
grep -Fq 'TARGETED_DEVICE_FAMILY = "1,2";' "$PROJECT/project.pbxproj" || fail "App target should generate complete iPhone and iPad icon metadata"
if grep -RInF 'UserDefaults(suiteName:' "$ROOT/GAMELIFE" "$ROOT/PRAXISWidgets" >/dev/null; then
  fail "App/widget app-group bridge should use files instead of CFPrefs-backed suite defaults"
fi
grep -Fq 'if #available(iOS 18.0, *)' "$ROOT/GAMELIFE/Views/MainTabView.swift" || fail "Main tab view missing iOS 18 bottom navigation padding guard"
grep -Fq 'safeAreaInset(edge: .bottom' "$ROOT/GAMELIFE/Views/MainTabView.swift" || fail "Main tab view missing bottom navigation safe-area padding"

REMOVED_ENTITLEMENT='com.apple.developer.family-''controls'
if grep -q "$REMOVED_ENTITLEMENT" "$ROOT/GAMELIFE/GAMELIFE.entitlements"; then
  fail "Family Controls entitlement should not be present"
fi
REMOVED_TRACKING_PATTERN='Family''Controls|Managed''Settings|Device''Activity|Family''Activity''Picker|Authorization''Center|Screen''TimeManager|GAMELIFE''Monitor|screen''TimeDataDidUpdate'
if grep -RInE "$REMOVED_TRACKING_PATTERN" "$ROOT/GAMELIFE" "$ROOT/README.md" "$PROJECT/project.pbxproj" >/dev/null; then
  fail "Removed tracking API remnants found"
fi

if grep -RInF '.preferredColorScheme(.dark)' "$ROOT/GAMELIFE" >/dev/null; then
  fail "Found hard-forced dark mode call(s)"
fi

if grep -RInF 'overrideUserInterfaceStyle' "$ROOT/GAMELIFE" >/dev/null; then
  fail "Found UIKit appearance override forcing color scheme"
fi

grep -q 'configureBackgroundLocationUpdates()' "$ROOT/GAMELIFE/Services/LocationManager.swift" || fail "Location manager should configure background updates safely"
grep -q 'hasLocationBackgroundMode' "$ROOT/GAMELIFE/Services/LocationManager.swift" || fail "Location manager missing background mode capability guard"
grep -q 'requestWhenInUseAuthorization()' "$ROOT/GAMELIFE/Services/LocationManager.swift" || fail "Location manager not using requestWhenInUseAuthorization"
grep -q 'requestAlwaysAuthorization()' "$ROOT/GAMELIFE/Services/LocationManager.swift" || fail "Location manager not escalating to Always authorization"

if awk '/struct StatusView: View/{flag=1} /\/\/ MARK: - Compact Header View/{flag=0} flag' \
  "$ROOT/GAMELIFE/Views/Status/StatusView.swift" | grep -n 'ScrollView' >/dev/null; then
  fail "Top-level StatusView should remain non-scrollable"
fi

grep -q 'FirstLaunchSetupView' "$ROOT/GAMELIFE/GAMELIFEApp.swift" || fail "First launch setup view missing"
grep -Fq 'loadDailyQuests() ?? []' "$ROOT/GAMELIFE/Services/GameEngine.swift" || fail "GameEngine should not seed default quests"
grep -q 'case \.location: return "Location"' "$ROOT/GAMELIFE/Views/Quests/QuestFormSheet.swift" || fail "Quest form missing Address tracking segment"
grep -q 'Text(\"Schedule\")' "$ROOT/GAMELIFE/Views/Quests/QuestFormSheet.swift" || fail "Quest form missing unified schedule section"
grep -q 'Toggle(\"Enable Reminder\"' "$ROOT/GAMELIFE/Views/Quests/QuestFormSheet.swift" || fail "Quest form missing reminder toggle"
grep -q 'case workoutCount = \"workoutCount\"' "$ROOT/GAMELIFE/Views/Quests/QuestFormSheet.swift" || fail "Quest form missing workout-count HealthKit option"
grep -q 'healthKitDataDidUpdate' "$ROOT/GAMELIFE/Services/HealthKitManager.swift" || fail "HealthKit update notification missing"
grep -q 'healthKitDataDidUpdate' "$ROOT/GAMELIFE/Services/GameEngine.swift" || fail "GameEngine should react to HealthKit updates"
grep -q 'minimumVisitMinutes: configuredMinimumStay' "$ROOT/GAMELIFE/Services/LocationManager.swift" || fail "Location quest dwell-time configuration missing"
grep -q 'failForAppExit' "$ROOT/GAMELIFE/Services/TrainingManager.swift" || fail "Training manager missing app-exit fail handler"
grep -q 'phase == .background && trainingManager.isActive' "$ROOT/GAMELIFE/Views/Training/TrainingView.swift" || fail "Training view missing background fail trigger"
grep -q 'maxHP' "$ROOT/GAMELIFE/Models/PlayerModels.swift" || fail "Player HP model missing"
grep -q 'awardXP(xp)' "$ROOT/GAMELIFE/Services/TrainingManager.swift" || fail "Training rewards should route through GameEngine.awardXP"

if grep -RInF 'Text("[QUESTS]")' "$ROOT/GAMELIFE/Views" >/dev/null; then
  fail "Found old [QUESTS] badge"
fi

if grep -RInF 'Text("[TRAINING]")' "$ROOT/GAMELIFE/Views" >/dev/null; then
  fail "Found old [TRAINING] badge"
fi

if grep -RInF 'Text("[BOSSES]")' "$ROOT/GAMELIFE/Views" >/dev/null; then
  fail "Found old [BOSSES] badge"
fi

echo "Running model logic tests..."
swiftc -o /tmp/gamelife_model_logic_tests \
  "$ROOT/Tests/test_theme_stub.swift" \
  "$ROOT/Tests/test_data_manager_stubs.swift" \
  "$ROOT/GAMELIFE/Models/PlayerModels.swift" \
  "$ROOT/GAMELIFE/Models/QuestModels.swift" \
  "$ROOT/GAMELIFE/Models/ActivityLogModels.swift" \
  "$ROOT/GAMELIFE/Services/DataManagers.swift" \
  "$ROOT/Tests/model_logic_tests.swift"
/tmp/gamelife_model_logic_tests

echo "Running app icon support tests..."
swiftc -o /tmp/gamelife_app_icon_support_tests \
  "$ROOT/GAMELIFE/Services/AppIconSupport.swift" \
  "$ROOT/Tests/app_icon_support_tests.swift"
/tmp/gamelife_app_icon_support_tests

echo "Running project build..."
SYMROOT="/tmp/gamelife_regression_symroot"
OBJROOT="/tmp/gamelife_regression_objroot"
rm -rf "$SYMROOT" "$OBJROOT"
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild \
  -project "$PROJECT" \
  -target GAMELIFE \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO \
  SYMROOT="$SYMROOT" \
  OBJROOT="$OBJROOT" \
  build >/tmp/gamelife_regression_build.log 2>&1 || {
  tail -n 120 /tmp/gamelife_regression_build.log
  fail "xcodebuild failed"
}

APP_INFO_PLIST="$SYMROOT/Debug-iphoneos/GAMELIFE.app/Info.plist"
[[ -d "$SYMROOT/Debug-iphoneos/GAMELIFE.app/Watch/GAMELIFEWatch.app" ]] || fail "Built app missing embedded watch app"
for icon_name in "${APP_ICON_NAMES[@]}"; do
  /usr/libexec/PlistBuddy -c "Print :CFBundleIcons:CFBundleAlternateIcons:$icon_name:CFBundleIconName" "$APP_INFO_PLIST" | grep -Fxq "$icon_name" || fail "Built Info.plist missing iPhone alternate icon $icon_name"
  /usr/libexec/PlistBuddy -c "Print :CFBundleIcons~ipad:CFBundleAlternateIcons:$icon_name:CFBundleIconName" "$APP_INFO_PLIST" | grep -Fxq "$icon_name" || fail "Built Info.plist missing iPad alternate icon $icon_name"
done

echo "All regression checks passed."
