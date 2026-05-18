//
//  GWQuestCompleteScreen.swift
//  GAMELIFE
//
//  03 · QUEST CLEARED — the burst moment.
//  Concentric ring burst + big diamond ✓ glyph + rewards card (lower-third)
//  and SHARE/CONTINUE pinned to bottom. Ported from screens-loop.jsx.
//

import SwiftUI

struct GWQuestCompleteScreen: View {
    var body: some View {
        ZStack(alignment: .top) {
            GW.bg.ignoresSafeArea()
            GWAurora().ignoresSafeArea()

            burst
                .frame(maxWidth: .infinity)
                .padding(.top, 200)

            VStack(spacing: 6) {
                Text("[ SYSTEM · 08:42 ]")
                    .font(GW.mono(10))
                    .tracking(3)
                    .foregroundStyle(GW.cyan)
                Text("Quest Cleared")
                    .font(GW.display(30, weight: .semibold))
                    .tracking(-0.5)
                    .foregroundStyle(GW.ink)
                Text("RUN 5 KILOMETRES · STR")
                    .font(GW.mono(11))
                    .tracking(1.2)
                    .foregroundStyle(GW.mute)
            }
            .padding(.top, 70)

            diamond
                .padding(.top, 320)

            rewards
                .padding(.horizontal, 22)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 120)

            HStack(spacing: 10) {
                GWButton(label: "SHARE", variant: .ghost)
                GWButton(label: "CONTINUE", variant: .primary)
                    .layoutPriority(1.4)
            }
            .padding(.horizontal, 22)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 32)
        }
        
        .foregroundStyle(GW.ink)
    }

    // MARK: subviews

    private var burst: some View {
        ZStack {
            ForEach(Array([260, 200, 140, 80].enumerated()), id: \.offset) { idx, d in
                let opacityHex = ["66", "44", "22", "11"][idx]
                let isPink = idx % 2 == 0 ? false : true
                let baseColor = isPink ? GW.pink : GW.cyan
                Circle()
                    .stroke(baseColor.opacity(hexOpacity(opacityHex)), lineWidth: 1)
                    .frame(width: CGFloat(d), height: CGFloat(d))
                    .background(
                        Group {
                            if idx == 3 {
                                Circle()
                                    .fill(RadialGradient(colors: [GW.pink.opacity(0.33), .clear],
                                                         center: .center,
                                                         startRadius: 0,
                                                         endRadius: CGFloat(d) / 2))
                            }
                        }
                    )
            }
        }
    }

    private var diamond: some View {
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
    }

    private var rewards: some View {
        GWCard(paddingX: 16, paddingY: 14) {
            VStack(alignment: .leading, spacing: 12) {
                Text("REWARDS")
                    .font(GW.mono(9, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(GW.mute)
                VStack(spacing: 10) {
                    rewardRow("Experience", "+220 XP", GW.cyan)
                    rewardRow("Gold",       "+60 g",   GW.amber)
                    rewardRow("STR stat",   "+12",     GW.pink)
                }
                Divider().overlay(GW.hairline).padding(.top, 4)
                VStack(spacing: 6) {
                    HStack {
                        Text("LV 47 — \(3060.formatted()) / 4,500")
                            .font(GW.mono(10))
                            .tracking(1)
                            .foregroundStyle(GW.mute)
                        Spacer()
                        Text("+4.9%")
                            .font(GW.mono(10))
                            .tracking(1)
                            .foregroundStyle(GW.cyan)
                    }
                    GWBar(pct: 3060.0 / 4500.0)
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

#Preview {
    GWQuestCompleteScreen()
}
