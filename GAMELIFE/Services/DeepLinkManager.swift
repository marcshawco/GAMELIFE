//
//  DeepLinkManager.swift
//  GAMELIFE
//

import Foundation
import Combine

enum AppDeepLinkRoute: Equatable {
    case status
    case quests(questID: UUID?)
    case training
    case bosses(bossID: UUID?)
    case shop

    var tabIndex: Int {
        switch self {
        case .status: return 0
        case .quests: return 1
        case .training: return 2
        case .bosses: return 3
        case .shop: return 4
        }
    }
}

struct PendingDeepLink: Identifiable, Equatable {
    let id = UUID()
    let route: AppDeepLinkRoute
}

@MainActor
final class DeepLinkManager: ObservableObject {
    static let shared = DeepLinkManager()

    @Published private(set) var pendingLink: PendingDeepLink?

    private init() {}

    func handle(_ url: URL) {
        guard let route = parse(url) else { return }
        pendingLink = PendingDeepLink(route: route)
    }

    private func parse(_ url: URL) -> AppDeepLinkRoute? {
        guard let scheme = url.scheme?.lowercased(), scheme == "praxis" else { return nil }

        let destination = (url.host ?? url.pathComponents.dropFirst().first ?? "").lowercased()
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)

        switch destination {
        case "status":
            return .status
        case "quests":
            let questID = components?.queryItems?.first(where: { $0.name == "questID" })?.value.flatMap(UUID.init)
            return .quests(questID: questID)
        case "training":
            return .training
        case "bosses":
            let bossID = components?.queryItems?.first(where: { $0.name == "bossID" })?.value.flatMap(UUID.init)
            return .bosses(bossID: bossID)
        case "shop":
            return .shop
        default:
            return nil
        }
    }
}
