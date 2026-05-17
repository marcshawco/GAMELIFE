//
//  GWShopScreen.swift
//  GAMELIFE
//
//  07 · SHOP — featured banner + tabs + 2-col item grid.
//  Ported from glasswork/screens-meta.jsx (GWShop).
//

import SwiftUI

private struct GWShopItem {
    let name: String
    let sub: String
    let price: Int
    let rarity: String
    let hue: Double
}

private let GW_SHOP_FEATURED = GWShopItem(
    name: "Phoenix Cloak",
    sub: "Auto-revive once when HP hits 0",
    price: 4800,
    rarity: "EPIC",
    hue: 320
)

private let GW_SHOP_ITEMS: [GWShopItem] = [
    GWShopItem(name: "Streak Insurance", sub: "7-day streak shield",     price: 1200, rarity: "RARE",   hue: 200),
    GWShopItem(name: "XP Brew · Lesser", sub: "×1.25 XP for 1 hour",     price:  350, rarity: "COMMON", hue: 152),
    GWShopItem(name: "Mind's Eye",       sub: "Reveal next quest stat",  price: 2400, rarity: "RARE",   hue: 260),
    GWShopItem(name: "Crown of Rest",    sub: "Skip a daily, no penalty", price: 5400, rarity: "LEGEND", hue: 46),
]

struct GWShopScreen: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            GWScreen(padBottom: 110) {
                // Header
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
                    GWPill(text: "\(GW_PLAYER.gold.formatted())g",
                           color: GW.amber,
                           border: GW.amber.opacity(0.33),
                           leadingDot: GW.amber)
                }

                featuredCard

                HStack(spacing: 6) {
                    ForEach(Array(["ITEMS", "COSMETIC", "TITLES", "KEYS"].enumerated()),
                            id: \.element) { i, t in
                        GWFilterChip(label: t, active: i == 0)
                    }
                    Spacer()
                }

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10),
                                    GridItem(.flexible(), spacing: 10)],
                          spacing: 10) {
                    ForEach(GW_SHOP_ITEMS, id: \.name) { item in
                        itemCard(item)
                    }
                }

                Spacer(minLength: 0)
            }

            GWTabDock(active: .shop)
                .padding(.horizontal, 14)
                .padding(.bottom, 18)
        }
    }

    private var featuredCard: some View {
        GWCard(paddingX: 0, paddingY: 0) {
            VStack(spacing: 0) {
                ZStack {
                    RadialGradient(
                        colors: [Color.hsl(GW_SHOP_FEATURED.hue, 75, 55),
                                 Color.hsl(GW_SHOP_FEATURED.hue, 60, 20)],
                        center: UnitPoint(x: 0.3, y: 0.4),
                        startRadius: 4,
                        endRadius: 200
                    )

                    Text("✦")
                        .font(GW.display(88, weight: .bold))
                        .tracking(-2)
                        .foregroundStyle(Color.white.opacity(0.85))
                        .shadow(color: .black.opacity(0.5), radius: 8, y: 4)

                    VStack {
                        HStack {
                            GWPill(text: GW_SHOP_FEATURED.rarity,
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
                        Text(GW_SHOP_FEATURED.name)
                            .font(GW.display(17, weight: .semibold))
                            .tracking(-0.3)
                            .foregroundStyle(GW.ink)
                        Text(GW_SHOP_FEATURED.sub)
                            .font(GW.sans(12))
                            .foregroundStyle(GW.mute)
                    }
                    Spacer()
                    Button(action: {}) {
                        Text("\(GW_SHOP_FEATURED.price.formatted())g")
                            .font(GW.sans(12, weight: .semibold))
                            .foregroundStyle(GW.col("3A2A05"))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(GW.gradGold))
                            .shadow(color: GW.gold.opacity(0.35), radius: 8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(14)
            }
        }
    }

    @ViewBuilder
    private func itemCard(_ it: GWShopItem) -> some View {
        let rarityColor: Color = {
            switch it.rarity {
            case "RARE":   return GW.cyan
            case "EPIC":   return GW.pink
            case "LEGEND": return GW.gold
            default:       return GW.mute
            }
        }()

        GWCard(paddingX: 0, paddingY: 0) {
            VStack(spacing: 0) {
                ZStack {
                    RadialGradient(
                        colors: [Color.hsl(it.hue, 65, 45),
                                 Color.hsl(it.hue, 55, 18)],
                        center: .center,
                        startRadius: 4,
                        endRadius: 90
                    )
                    Text("◇")
                        .font(GW.display(36))
                        .foregroundStyle(Color.white.opacity(0.85))

                    VStack {
                        HStack {
                            Text(it.rarity)
                                .font(GW.mono(8, weight: .medium))
                                .tracking(1.2)
                                .foregroundStyle(rarityColor)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.black.opacity(0.4))
                                        .overlay(Capsule()
                                            .stroke(rarityColor.opacity(0.27), lineWidth: 1))
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
                    Text(it.name)
                        .font(GW.sans(12, weight: .semibold))
                        .foregroundStyle(GW.ink)
                    Text(it.sub)
                        .font(GW.sans(10))
                        .foregroundStyle(GW.mute)
                        .lineLimit(2)
                        .frame(minHeight: 26, alignment: .topLeading)
                    HStack {
                        Text("\(it.price.formatted())g")
                            .font(GW.mono(11))
                            .foregroundStyle(GW.amber)
                        Spacer()
                        Text("BUY")
                            .font(GW.mono(9, weight: .medium))
                            .tracking(1)
                            .foregroundStyle(GW.cyan)
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(GW.cyan.opacity(0.07))
                                    .overlay(Capsule().stroke(GW.cyan.opacity(0.33), lineWidth: 1))
                            )
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 10)
                .padding(.top, 8)
                .padding(.bottom, 10)
            }
        }
    }
}

#Preview {
    GWShopScreen()
}
