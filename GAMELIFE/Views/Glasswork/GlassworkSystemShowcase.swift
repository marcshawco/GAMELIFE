//
//  GlassworkSystemShowcase.swift
//  GAMELIFE
//
//  Design system reference card (palette / type / components). Mirrors
//  system-showcase.jsx. Displayed in the gallery's "Design system" section.
//

import SwiftUI

struct GWPaletteCard: View {
    private struct Swatch { let label: String; let color: Color; let ink: Color; let hex: String }

    private var swatches: [Swatch] {
        [
            Swatch(label: "bg",      color: GW.bg,                  ink: .white,  hex: "#0B0717"),
            Swatch(label: "bg2",     color: GW.bg2,                 ink: .white,  hex: "#150D26"),
            Swatch(label: "surface", color: GW.col("1d152e"),       ink: .white,  hex: "#1D152E"),
            Swatch(label: "ink",     color: GW.ink,                 ink: GW.bg,   hex: "#F5F1FF"),
            Swatch(label: "mute",    color: GW.mute,                ink: GW.bg,   hex: "#A89DC8"),
            Swatch(label: "cyan",    color: GW.cyan,                ink: GW.bg,   hex: "#3DE8E0"),
            Swatch(label: "pink",    color: GW.pink,                ink: GW.bg,   hex: "#FF5BB0"),
            Swatch(label: "amber",   color: GW.amber,               ink: GW.bg,   hex: "#FFB347"),
            Swatch(label: "gold",    color: GW.gold,                ink: GW.bg,   hex: "#F4C557"),
            Swatch(label: "good",    color: GW.good,                ink: GW.bg,   hex: "#5BE38E"),
            Swatch(label: "danger",  color: GW.danger,              ink: GW.ink,  hex: "#FF4D6D"),
        ]
    }

    var body: some View {
        ZStack {
            GW.bg
            GWAurora()
            VStack(alignment: .leading, spacing: 0) {
                Text("02 · GLASSWORK · PALETTE")
                    .font(GW.mono(10, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(GW.mute)
                Text("Aurora on velvet")
                    .font(GW.display(24, weight: .semibold))
                    .tracking(-0.5)
                    .foregroundStyle(GW.ink)
                    .padding(.top, 4)
                Text("Deep indigo base. Cyan→pink as the system gradient. Amber/gold for value & loot. Good and danger only when status demands it.")
                    .font(GW.sans(12))
                    .foregroundStyle(GW.mute)
                    .padding(.top, 6)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4),
                          spacing: 8) {
                    ForEach(swatches, id: \.label) { s in
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(s.color)
                                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(GW.hairline))
                            VStack(alignment: .leading) {
                                Text(s.label)
                                    .font(GW.mono(9, weight: .medium))
                                    .tracking(1)
                                    .foregroundStyle(s.ink)
                                Spacer()
                                Text(s.hex)
                                    .font(GW.mono(9))
                                    .tracking(0.5)
                                    .foregroundStyle(s.ink.opacity(0.7))
                            }
                            .padding(8)
                        }
                        .aspectRatio(1.4, contentMode: .fit)
                    }
                }
                .padding(.top, 18)

                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous).fill(GW.grad)
                    Text("SYSTEM GRADIENT · CYAN → PINK")
                        .font(GW.mono(11, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(GW.bg)
                }
                .frame(height: 36)
                .padding(.top, 14)
            }
            .padding(24)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .foregroundStyle(GW.ink)
    }
}

struct GWTypeCard: View {
    var body: some View {
        ZStack {
            GW.bg
            GWAurora()
            VStack(alignment: .leading, spacing: 0) {
                Text("02 · GLASSWORK · TYPE")
                    .font(GW.mono(10, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(GW.mute)
                Text("Three voices")
                    .font(GW.display(24, weight: .semibold))
                    .tracking(-0.5)
                    .foregroundStyle(GW.ink)
                    .padding(.top, 4)

                VStack(alignment: .leading, spacing: 18) {
                    typeRow(label: "DISPLAY · SPACE GROTESK",
                            content: AnyView(
                                Text("Level Up")
                                    .font(GW.display(44, weight: .semibold))
                                    .tracking(-1)
                                    .foregroundStyle(GW.ink)
                            ),
                            footer: "600 weight · neg tracking · headlines & numerals")
                    typeRow(label: "BODY · INTER TIGHT",
                            content: AnyView(
                                Text("The System recognizes you, Hunter. Each cleared quest deals damage to one of your boss fights.")
                                    .font(GW.sans(14))
                                    .foregroundStyle(GW.inkSoft)
                            ),
                            footer: nil)
                    typeRow(label: "SYSTEM LABEL · JETBRAINS MONO",
                            content: AnyView(
                                Text("[ SYSTEM · STR +12 · LV 47 → 48 ]")
                                    .font(GW.mono(11))
                                    .tracking(2)
                                    .foregroundStyle(GW.cyan)
                            ),
                            footer: nil)
                }
                .padding(.top, 22)
            }
            .padding(24)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .foregroundStyle(GW.ink)
    }

    private func typeRow(label: String, content: AnyView, footer: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(GW.mono(9, weight: .medium))
                .tracking(1.5)
                .foregroundStyle(GW.mute)
            content
            if let footer = footer {
                Text(footer)
                    .font(GW.mono(9))
                    .foregroundStyle(GW.mute)
            }
        }
    }
}

struct GWComponentsCard: View {
    var body: some View {
        ZStack {
            GW.bg
            GWAurora()
            VStack(alignment: .leading, spacing: 0) {
                Text("02 · GLASSWORK · COMPONENTS")
                    .font(GW.mono(10, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(GW.mute)
                Text("Building blocks")
                    .font(GW.display(24, weight: .semibold))
                    .tracking(-0.5)
                    .foregroundStyle(GW.ink)
                    .padding(.top, 4)

                VStack(alignment: .leading, spacing: 14) {
                    componentSection("BUTTONS") {
                        HStack(spacing: 8) {
                            GWButton(label: "PRIMARY", variant: .primary, size: .sm)
                            GWButton(label: "GHOST",   variant: .ghost,   size: .sm)
                            GWButton(label: "GOLD",    variant: .gold,    size: .sm)
                            GWButton(label: "STRIKE",  variant: .danger,  size: .sm)
                        }
                    }

                    componentSection("PILLS") {
                        FlowStack(spacing: 6) {
                            GWPill(text: "NEUTRAL")
                            GWPill(text: "FOCUSED",
                                   color: GW.cyan,
                                   bg: GW.cyan.opacity(0.07),
                                   border: GW.cyan.opacity(0.33))
                            GWPill(text: "+220 XP",
                                   color: GW.amber,
                                   border: GW.amber.opacity(0.33))
                            GWPill(text: "STREAK +1",
                                   color: GW.good,
                                   border: GW.good.opacity(0.33))
                            GWPill(text: "−4 HP",
                                   color: GW.danger,
                                   border: GW.danger.opacity(0.33))
                        }
                    }

                    componentSection("PROGRESS") {
                        VStack(spacing: 6) {
                            GWBar(pct: 0.64)
                            GWBar(pct: 0.78,
                                  gradient: AnyShapeStyle(
                                      LinearGradient(colors: [GW.pink, GW.amber],
                                                     startPoint: .leading, endPoint: .trailing)
                                  ),
                                  glow: false)
                            GWBar(pct: 0.41,
                                  gradient: AnyShapeStyle(GW.gradGold),
                                  glow: false)
                        }
                    }

                    GWCard(paddingX: 14, paddingY: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("GLASS CARD")
                                .font(GW.mono(9, weight: .medium))
                                .tracking(1.5)
                                .foregroundStyle(GW.mute)
                            Text("Backdrop blur · subtle gradient overlay · hairline border · soft shadow.")
                                .font(GW.sans(13))
                                .foregroundStyle(GW.ink)
                        }
                    }
                }
                .padding(.top, 18)
            }
            .padding(24)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .foregroundStyle(GW.ink)
    }

    @ViewBuilder
    private func componentSection<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(GW.mono(9, weight: .medium))
                .tracking(1.5)
                .foregroundStyle(GW.mute)
            content()
        }
    }
}

// Simple wrapping HStack for pills row in the components card.
private struct FlowStack<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            HStack(spacing: spacing) { content }
        }
    }
}
