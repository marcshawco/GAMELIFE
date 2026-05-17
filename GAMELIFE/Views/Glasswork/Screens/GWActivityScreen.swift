//
//  GWActivityScreen.swift
//  GAMELIFE
//
//  08 · ACTIVITY LOG — summary chips + day-divided log entries.
//  Ported from glasswork/screens-meta.jsx (GWActivity).
//

import SwiftUI

private struct GWLogEntry: Identifiable {
    let id = UUID()
    let t: String
    let cat: String
    let label: String
    let delta: String
    let tint: Color
}

struct GWActivityScreen: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            GWScreen(padBottom: 110) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("SYSTEM LOG")
                        .font(GW.mono(10, weight: .medium))
                        .tracking(2)
                        .foregroundStyle(GW.mute)
                    Text("Activity")
                        .font(GW.display(26, weight: .semibold))
                        .tracking(-0.5)
                        .foregroundStyle(GW.ink)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 8) {
                    summaryCard("XP TODAY", "+780", GW.cyan)
                    summaryCard("GOLD",     "+180", GW.amber)
                    summaryCard("STRIKES",  "3",    GW.pink)
                }

                divider("TODAY · 16 MAY")

                ForEach(todayLog) { entry in
                    logRow(entry)
                }

                divider("YESTERDAY · 15 MAY")

                ForEach(yesterdayLog) { entry in
                    logRow(entry)
                }

                Spacer(minLength: 0)
            }

            GWTabDock(active: .status)
                .padding(.horizontal, 14)
                .padding(.bottom, 18)
        }
    }

    private var todayLog: [GWLogEntry] {
        [
            GWLogEntry(t: "08:42", cat: "QUEST", label: "Run 5 km",        delta: "+220 XP · +60 g", tint: GW.cyan),
            GWLogEntry(t: "07:55", cat: "STAT",  label: "INT reached 188", delta: "+1 stat point",   tint: GW.pink),
            GWLogEntry(t: "07:30", cat: "QUEST", label: "Hydrate · 2 L",   delta: "+80 XP · +20 g",  tint: GW.cyan),
            GWLogEntry(t: "07:00", cat: "WAKE",  label: "Wake-up logged",  delta: "Streak +1",       tint: GW.good),
        ]
    }

    private var yesterdayLog: [GWLogEntry] {
        [
            GWLogEntry(t: "Y · 22:14", cat: "BOSS",  label: "Ironwork",        delta: "−4% HP",        tint: GW.danger),
            GWLogEntry(t: "Y · 21:30", cat: "QUEST", label: "Bed by 23:30",    delta: "+160 XP",       tint: GW.cyan),
            GWLogEntry(t: "Y · 14:02", cat: "LVL",   label: "Reached Lv 47",   delta: "+15 stat pool", tint: GW.gold),
            GWLogEntry(t: "Y · 12:18", cat: "SHOP",  label: "Bought XP Brew",  delta: "−350 g",        tint: GW.amber),
        ]
    }

    @ViewBuilder
    private func summaryCard(_ label: String, _ value: String, _ tint: Color) -> some View {
        GWCard(paddingX: 12, paddingY: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(GW.mono(9, weight: .medium))
                    .tracking(1.4)
                    .foregroundStyle(GW.mute)
                Text(value)
                    .font(GW.display(22, weight: .bold))
                    .foregroundStyle(tint)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func divider(_ label: String) -> some View {
        HStack(spacing: 10) {
            Rectangle().fill(GW.hairline).frame(height: 1)
            Text(label)
                .font(GW.mono(9, weight: .medium))
                .tracking(2)
                .foregroundStyle(GW.mute)
            Rectangle().fill(GW.hairline).frame(height: 1)
        }
    }

    @ViewBuilder
    private func logRow(_ e: GWLogEntry) -> some View {
        GWCard(paddingX: 12, paddingY: 10) {
            HStack(spacing: 10) {
                Circle()
                    .fill(e.tint)
                    .frame(width: 6, height: 6)
                    .shadow(color: e.tint, radius: 4)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(e.cat)
                            .font(GW.mono(9, weight: .medium))
                            .tracking(1.5)
                            .foregroundStyle(e.tint)
                        Text(e.t)
                            .font(GW.mono(9))
                            .foregroundStyle(GW.mute)
                    }
                    Text(e.label)
                        .font(GW.sans(12))
                        .foregroundStyle(GW.ink)
                }
                Spacer()
                Text(e.delta)
                    .font(GW.mono(11))
                    .foregroundStyle(e.tint)
            }
        }
    }
}

#Preview {
    GWActivityScreen()
}
