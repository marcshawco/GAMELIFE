import Foundation

// MARK: - App Icon Support

enum AppIconOption: String, CaseIterable, Identifiable {
    /// Signal - primary AppIcon. Selecting clears any alt-icon override.
    case signal
    /// Gold - gold to amber ceremonial alternate.
    case gold
    /// Crimson - pink to crimson on plum-black.
    case crimson
    /// Solar - gold to crimson on coffee.
    case solar
    /// Verdant - mint to periwinkle on deep ink.
    case verdant

    var id: String { rawValue }

    var iconName: String? {
        switch self {
        case .signal:  return nil
        case .gold:    return "AppIconPrismGold"
        case .crimson: return "AppIconPrismCrimson"
        case .solar:   return "AppIconPrismSolar"
        case .verdant: return "AppIconPrismVerdant"
        }
    }

    var displayName: String {
        switch self {
        case .signal:  return "Prism · Signal"
        case .gold:    return "Prism · Gold"
        case .crimson: return "Prism · Crimson"
        case .solar:   return "Prism · Solar"
        case .verdant: return "Prism · Verdant"
        }
    }

    var subtitle: String {
        switch self {
        case .signal:  return "Cyan → pink · primary"
        case .gold:    return "S-Rank ceremonial alternate"
        case .crimson: return "Boss Raid alternate"
        case .solar:   return "Gold → crimson · warm alternate"
        case .verdant: return "Mint → periwinkle · cool alternate"
        }
    }

    var previewAssetName: String {
        switch self {
        case .signal:  return "AppIconPreviewPrismSignal"
        case .gold:    return "AppIconPreviewPrismGold"
        case .crimson: return "AppIconPreviewPrismCrimson"
        case .solar:   return "AppIconPreviewPrismSolar"
        case .verdant: return "AppIconPreviewPrismVerdant"
        }
    }

    /// Resolve the current alternate-icon name into an option. Legacy
    /// Phoenix / pre-rename names migrate to `.signal` so old users land
    /// on the current default.
    init?(iconName: String?) {
        switch iconName {
        case nil,
             "AppIconPrism",
             "AppIconPhoenixIvory", "AppIconPhoenixIvoryV2",
             "AppIconPhoenixWhite", "AppIconPhoenixWhiteV2",
             "AppIconPhoenixDark",  "AppIconPhoenixDarkV2":
            self = .signal
        case "AppIconPrismGold":    self = .gold
        case "AppIconPrismCrimson": self = .crimson
        case "AppIconPrismSolar":   self = .solar
        case "AppIconPrismVerdant": self = .verdant
        default: return nil
        }
    }

    static let alternateIconNames: Set<String> = Set(allCases.compactMap(\.iconName))

    /// Names that no longer have catalog assets - force-migrated to nil
    /// so iOS doesn't try to resolve a dead alt-icon.
    static let legacyAlternateNames: Set<String> = [
        "AppIconPrism",
        "AppIconPhoenixIvory", "AppIconPhoenixIvoryV2",
        "AppIconPhoenixWhite", "AppIconPhoenixWhiteV2",
        "AppIconPhoenixDark",  "AppIconPhoenixDarkV2",
    ]
}

struct AppIconResolvedState: Equatable {
    let currentOption: AppIconOption
    let storedOption: AppIconOption
    let hasLegacyIconOverride: Bool
    let shouldNormalizeIconName: Bool
}

enum AppIconStateResolver {
    static func resolve(
        currentIconName: String?,
        storedOption _: AppIconOption?
    ) -> AppIconResolvedState {
        guard let currentIconName else {
            return AppIconResolvedState(
                currentOption: .signal,
                storedOption: .signal,
                hasLegacyIconOverride: false,
                shouldNormalizeIconName: false
            )
        }

        if AppIconOption.legacyAlternateNames.contains(currentIconName) {
            return AppIconResolvedState(
                currentOption: .signal,
                storedOption: .signal,
                hasLegacyIconOverride: true,
                shouldNormalizeIconName: true
            )
        }

        if let currentOption = AppIconOption(iconName: currentIconName) {
            return AppIconResolvedState(
                currentOption: currentOption,
                storedOption: currentOption,
                hasLegacyIconOverride: false,
                shouldNormalizeIconName: false
            )
        }

        return AppIconResolvedState(
            currentOption: .signal,
            storedOption: .signal,
            hasLegacyIconOverride: true,
            shouldNormalizeIconName: true
        )
    }
}
