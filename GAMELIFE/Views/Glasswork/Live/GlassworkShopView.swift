//
//  GlassworkShopView.swift
//  GAMELIFE
//
//  Live Glasswork Shop tab — wired to MarketplaceManager. Featured hero
//  card (priciest reward), category filter chips, 2-column grid of tappable
//  reward cards. Tap calls MarketplaceManager.purchaseReward; insufficient
//  gold dims the card and shows NEED.
//

import SwiftUI

struct GlassworkShopView: View {
    @EnvironmentObject var gameEngine: GameEngine
    @StateObject private var market = MarketplaceManager.shared

    @State private var selectedCategory: RewardCategory? = nil
    @State private var lastResultMessage: String?

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                GW.bg.ignoresSafeArea()
                GWAurora().ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        header
                        if let hero = featuredReward {
                            featuredCard(hero)
                        }
                        categoryFilterStrip
                        rewardsGrid
                        if let msg = lastResultMessage {
                            statusToast(msg)
                        }
                        Color.clear.frame(height: 8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 130)
                }
            }
        }
        .foregroundStyle(GW.ink)
        
    }

    // MARK: header / featured

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text("SHOP")
                    .font(GW.mono(10, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(GW.mute)
                Text("Marketplace")
                    .font(GW.display(26, weight: .semibold))
                    .tracking(-0.5)
                    .foregroundStyle(GW.ink)
            }
            Spacer()
            GWPill(text: "\(gameEngine.player.gold.formatted())g",
                   color: GW.amber,
                   border: GW.amber.opacity(0.33),
                   glow: GW.amber.opacity(0.33),
                   leadingDot: GW.amber)
        }
    }

    /// Pick the priciest reward in the current filter as the featured hero.
    private var featuredReward: MarketplaceReward? {
        let pool = filteredRewards
        return pool.max(by: { $0.cost < $1.cost })
    }

    @ViewBuilder
    private func featuredCard(_ hero: MarketplaceReward) -> some View {
        let hue = hue(for: hero.category)
        let rarity = rarityLabel(for: hero.cost)
        GWCard(paddingX: 0, paddingY: 0) {
            VStack(spacing: 0) {
                ZStack {
                    RadialGradient(
                        colors: [Color.hsl(hue, 75, 55), Color.hsl(hue, 60, 20)],
                        center: UnitPoint(x: 0.3, y: 0.4),
                        startRadius: 4,
                        endRadius: 220
                    )
                    Image(systemName: hero.icon)
                        .font(.system(size: 60, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
                    VStack {
                        HStack {
                            GWPill(text: rarity,
                                   color: GW.ink,
                                   bg: Color.black.opacity(0.4),
                                   border: GW.hairline)
                            Spacer()
                            GWPill(text: "FEATURED", color: GW.cyan)
                        }
                        Spacer()
                    }
                    .padding(12)
                }
                .frame(height: 140)
                .clipped()

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(hero.name)
                            .font(GW.display(17, weight: .semibold))
                            .tracking(-0.3)
                            .foregroundStyle(GW.ink)
                        Text(hero.description)
                            .font(GW.sans(12))
                            .foregroundStyle(GW.mute)
                            .lineLimit(2)
                    }
                    Spacer()
                    Button {
                        attemptPurchase(hero)
                    } label: {
                        Text("\(hero.cost.formatted())g")
                            .font(GW.sans(12, weight: .semibold))
                            .foregroundStyle(GW.col("3A2A05"))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(GW.gradGold))
                            .shadow(color: GW.gold.opacity(0.35), radius: 8)
                    }
                    .buttonStyle(.plain)
                    .opacity(gameEngine.player.gold >= hero.cost ? 1 : 0.55)
                    .disabled(gameEngine.player.gold < hero.cost)
                }
                .padding(14)
            }
        }
    }

    // MARK: filter chips

    private var categoryFilterStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                chip(label: "ALL", active: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(RewardCategory.allCases, id: \.self) { cat in
                    chip(label: cat.rawValue.uppercased(),
                         active: selectedCategory == cat) {
                        selectedCategory = cat
                    }
                }
            }
        }
    }

    private func chip(label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(GW.mono(9, weight: .medium))
                .tracking(1.4)
                .foregroundStyle(active ? GW.cyan : GW.mute)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(active ? GW.cyan.opacity(0.07) : Color.clear)
                        .overlay(Capsule().stroke(active ? GW.cyan.opacity(0.33) : GW.hairline,
                                                  lineWidth: 1))
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: rewards grid

    private var rewardsGrid: some View {
        let pool = filteredRewards
        let featuredID = featuredReward?.id
        let grid = pool.filter { $0.id != featuredID }
        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 10),
                                   GridItem(.flexible(), spacing: 10)],
                         spacing: 10) {
            ForEach(grid) { item in
                rewardCard(item)
            }
        }
    }

    private var filteredRewards: [MarketplaceReward] {
        guard let cat = selectedCategory else { return market.availableRewards }
        return market.availableRewards.filter { $0.category == cat }
    }

    @ViewBuilder
    private func rewardCard(_ item: MarketplaceReward) -> some View {
        let hue = hue(for: item.category)
        let rarity = rarityLabel(for: item.cost)
        let rc = rarityColor(rarity)
        let canAfford = gameEngine.player.gold >= item.cost

        GWCard(paddingX: 0, paddingY: 0) {
            VStack(spacing: 0) {
                ZStack {
                    RadialGradient(
                        colors: [Color.hsl(hue, 65, 45), Color.hsl(hue, 55, 18)],
                        center: .center,
                        startRadius: 4,
                        endRadius: 90
                    )
                    Image(systemName: item.icon)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.9))
                    VStack {
                        HStack {
                            Text(rarity)
                                .font(GW.mono(8, weight: .medium))
                                .tracking(1.2)
                                .foregroundStyle(rc)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.black.opacity(0.4))
                                        .overlay(Capsule()
                                            .stroke(rc.opacity(0.27), lineWidth: 1))
                                )
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(8)
                }
                .frame(height: 72)
                .clipped()

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(GW.sans(12, weight: .semibold))
                        .foregroundStyle(GW.ink)
                        .lineLimit(1)
                    Text(item.description)
                        .font(GW.sans(10))
                        .foregroundStyle(GW.mute)
                        .lineLimit(2)
                        .frame(minHeight: 26, alignment: .topLeading)
                    HStack {
                        Text("\(item.cost.formatted())g")
                            .font(GW.mono(11))
                            .foregroundStyle(GW.amber)
                        Spacer()
                        Text(canAfford ? "BUY" : "NEED")
                            .font(GW.mono(9, weight: .medium))
                            .tracking(1)
                            .foregroundStyle(canAfford ? GW.cyan : GW.mute)
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill((canAfford ? GW.cyan : GW.mute).opacity(0.07))
                                    .overlay(Capsule().stroke(
                                        (canAfford ? GW.cyan : GW.mute).opacity(0.33),
                                        lineWidth: 1))
                            )
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 10)
                .padding(.top, 8)
                .padding(.bottom, 10)
            }
        }
        .opacity(canAfford ? 1 : 0.55)
        .onTapGesture { attemptPurchase(item) }
    }

    private func statusToast(_ message: String) -> some View {
        Text(message)
            .font(GW.mono(11))
            .tracking(1)
            .foregroundStyle(GW.inkSoft)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(GW.hairline, lineWidth: 1))
            )
    }

    // MARK: action

    private func attemptPurchase(_ reward: MarketplaceReward) {
        let result = market.purchaseReward(reward, player: &gameEngine.player)
        lastResultMessage = result.message
        gameEngine.save()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if lastResultMessage == result.message {
                withAnimation { lastResultMessage = nil }
            }
        }
    }

    // MARK: helpers

    private func hue(for cat: RewardCategory) -> Double {
        switch cat {
        case .treat:         return 320   // pink-rose
        case .entertainment: return 264   // mauve
        case .time:          return 200   // cyan
        case .item:          return 46    // gold
        case .experience:    return 152   // mint
        }
    }

    private func rarityLabel(for cost: Int) -> String {
        switch cost {
        case ..<50:      return "COMMON"
        case 50..<200:   return "RARE"
        case 200..<1000: return "EPIC"
        default:         return "LEGEND"
        }
    }

    private func rarityColor(_ rarity: String) -> Color {
        switch rarity {
        case "RARE":   return GW.cyan
        case "EPIC":   return GW.pink
        case "LEGEND": return GW.gold
        default:       return GW.mute
        }
    }
}
