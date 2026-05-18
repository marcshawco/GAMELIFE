//
//  GlassworkQuestClearedModal.swift
//  GAMELIFE
//
//  Burst-ring + diamond ✓ + rewards card overlay. Triggered when a quest
//  is tapped complete from the live Glasswork Quests tab. Ported from the
//  Praxis Demo's QuestClearedModal but parameterised over the real
//  QuestCompletionResult so XP / gold / stat gains reflect what just landed.
//

import SwiftUI

struct GlassworkQuestClearedModal: View {
    let questTitle: String
    let primaryStat: String
    let xpAwarded: Int
    let goldAwarded: Int
    let statGains: [(StatType, Int)]
    let onClose: () -> Void

    @State private var ringScale: CGFloat = 0.2
    @State private var ringOpacity: Double = 0
    @State private var diamondScale: CGFloat = 0.2
    @State private var diamondOpacity: Double = 0

    var body: some View {
        ZStack {
            GW.bg.opacity(0.85).ignoresSafeArea()
            GWAurora().opacity(0.4).ignoresSafeArea()

            // Burst rings
            ZStack {
                ForEach(Array([300, 220, 150, 90].enumerated()), id: \.offset) { idx, d in
                    let opacityHex = ["66", "44", "22", "11"][idx]
                    let isPink = idx % 2 != 0
                    let base = isPink ? GW.pink : GW.cyan
                    Circle()
                        .stroke(base.opacity(hexOpacity(opacityHex)), lineWidth: 1)
                        .frame(width: CGFloat(d), height: CGFloat(d))
                        .background(
                            Group {
                                if idx == 3 {
                                    Circle().fill(
                                        RadialGradient(colors: [GW.pink.opacity(0.33), .clear],
                                                       center: .center,
                                                       startRadius: 0,
                                                       endRadius: CGFloat(d) / 2)
                                    )
                                }
                            }
                        )
                }
            }
            .scaleEffect(ringScale)
            .opacity(ringOpacity)
            .offset(y: -160)

            VStack(spacing: 0) {
                VStack(spacing: 6) {
                    Text("[ SYSTEM · NOW ]")
                        .font(GW.mono(10, weight: .medium))
                        .tracking(3)
                        .foregroundStyle(GW.cyan)
                    Text("Quest Cleared")
                        .font(GW.display(30, weight: .semibold))
                        .tracking(-0.5)
                        .foregroundStyle(GW.ink)
                    Text("\(questTitle.uppercased()) · \(primaryStat)")
                        .font(GW.mono(11))
                        .tracking(1.2)
                        .foregroundStyle(GW.mute)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .padding(.top, 80)

                Spacer(minLength: 40)

                // Diamond glyph
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(GW.grad)
                        .frame(width: 96, height: 96)
                        .rotationEffect(.degrees(45))
                        .shadow(color: GW.pink.opacity(0.65), radius: 30)
                        .shadow(color: GW.cyan.opacity(0.35), radius: 60)
                    Text("✓")
                        .font(GW.mono(32, weight: .heavy))
                        .foregroundStyle(GW.bg)
                }
                .scaleEffect(diamondScale)
                .opacity(diamondOpacity)

                Spacer(minLength: 36)

                rewardsCard
                    .padding(.horizontal, 22)
                    .padding(.bottom, 16)

                HStack(spacing: 10) {
                    GWButton(label: "SHARE", variant: .ghost) { onClose() }
                    GWButton(label: "CONTINUE", variant: .primary) { onClose() }
                        .layoutPriority(1.4)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 32)
            }
        }
        .foregroundStyle(GW.ink)
        
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                ringScale = 1
                ringOpacity = 1
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) {
                diamondScale = 1
                diamondOpacity = 1
            }
        }
    }

    private var rewardsCard: some View {
        GWCard(paddingX: 16, paddingY: 14) {
            VStack(alignment: .leading, spacing: 10) {
                Text("REWARDS")
                    .font(GW.mono(9, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(GW.mute)
                rewardRow("Experience", "+\(xpAwarded) XP",  GW.cyan)
                if goldAwarded > 0 {
                    rewardRow("Gold", "+\(goldAwarded) g", GW.amber)
                }
                ForEach(Array(statGains.enumerated()), id: \.offset) { _, gain in
                    rewardRow("\(gain.0.rawValue) stat", "+\(gain.1)", GW.pink)
                }
            }
        }
    }

    private func rewardRow(_ label: String, _ value: String, _ tint: Color) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(GW.sans(13))
                .foregroundStyle(GW.inkSoft)
            Spacer()
            Text(value)
                .font(GW.display(18, weight: .bold))
                .foregroundStyle(tint)
        }
    }

    private func hexOpacity(_ hex: String) -> Double {
        var i: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&i)
        return Double(i) / 255
    }
}
