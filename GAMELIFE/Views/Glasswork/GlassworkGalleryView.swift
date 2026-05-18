//
//  GlassworkGalleryView.swift
//  GAMELIFE
//
//  Entry point for the Glasswork preview gallery. Lists the design system
//  cards and all 10 screens grouped by flow. Wire this anywhere — Settings,
//  a debug menu, or a temporary toolbar — to preview the redesign without
//  touching the live tabs.
//
//  Example:
//      .sheet(isPresented: $showGlasswork) { GlassworkGalleryView() }
//

import SwiftUI

struct GlassworkGalleryView: View {
    private struct GallerySection: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let entries: [Entry]
    }

    private struct Entry: Identifiable {
        let id = UUID()
        let label: String
        let view: () -> AnyView
    }

    private var sections: [GallerySection] {
        [
            GallerySection(
                title: "Design system",
                subtitle: "Palette · type · components.",
                entries: [
                    Entry(label: "Palette",    view: { AnyView(SystemShowcasePage(card: .palette)) }),
                    Entry(label: "Type stack", view: { AnyView(SystemShowcasePage(card: .type)) }),
                    Entry(label: "Components", view: { AnyView(SystemShowcasePage(card: .components)) }),
                ]
            ),
            GallerySection(
                title: "Daily loop",
                subtitle: "Status → Quests → Burst.",
                entries: [
                    Entry(label: "01 · Status (Home)",  view: { AnyView(GWStatusScreen()) }),
                    Entry(label: "02 · Quests list",    view: { AnyView(GWQuestsScreen()) }),
                    Entry(label: "03 · Quest cleared",  view: { AnyView(GWQuestCompleteScreen()) }),
                ]
            ),
            GallerySection(
                title: "Combat",
                subtitle: "Multi-week bosses · deep-focus dungeons.",
                entries: [
                    Entry(label: "04 · Boss list",            view: { AnyView(GWBossesScreen()) }),
                    Entry(label: "05 · Boss fight",           view: { AnyView(GWBossFightScreen()) }),
                    Entry(label: "06 · Dungeon (focus)",      view: { AnyView(GWDungeonScreen()) }),
                ]
            ),
            GallerySection(
                title: "Economy & log",
                subtitle: "Loot, marketplace, history.",
                entries: [
                    Entry(label: "07 · Shop",         view: { AnyView(GWShopScreen()) }),
                    Entry(label: "08 · Activity log", view: { AnyView(GWActivityScreen()) }),
                ]
            ),
            GallerySection(
                title: "Ceremony",
                subtitle: "Big moments earn big chrome.",
                entries: [
                    Entry(label: "09 · Level up",                view: { AnyView(GWLevelUpScreen()) }),
                    Entry(label: "10 · Onboarding rank reveal",  view: { AnyView(GWOnboardingScreen()) }),
                ]
            )
        ]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GW.bg.ignoresSafeArea()
                GWAurora().ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 26) {
                        header
                        ForEach(sections) { section in
                            sectionView(section)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("PRAXIS · 02 GLASSWORK")
                        .font(GW.mono(11, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(GW.cyan)
                }
            }
            .toolbarBackground(GW.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        
        .foregroundStyle(GW.ink)
        .accentColor(GW.cyan)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DIRECTION 02 · 16 MAY 2026")
                .font(GW.mono(10, weight: .medium))
                .tracking(3)
                .foregroundStyle(GW.mute)
            Text("Glasswork — fully fleshed out")
                .font(GW.display(32, weight: .bold))
                .tracking(-1)
                .foregroundStyle(GW.ink)
            Text("Frosted dark UI with a cyan→pink system gradient and an aurora background. Surfaces float on velvet; mono labels handle the System voice; Space Grotesk does the heavy lifting on numerals.")
                .font(GW.sans(13))
                .foregroundStyle(GW.inkSoft)
                .lineSpacing(3)
        }
        .padding(.top, 4)
    }

    private func sectionView(_ section: GallerySection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(section.title.uppercased())
                    .font(GW.mono(11, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(GW.cyan)
                Text(section.subtitle)
                    .font(GW.sans(13))
                    .foregroundStyle(GW.mute)
            }

            VStack(spacing: 8) {
                ForEach(section.entries) { entry in
                    NavigationLink {
                        ZStack {
                            GW.bg.ignoresSafeArea()
                            entry.view()
                        }
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                Text(entry.label.uppercased())
                                    .font(GW.mono(10, weight: .bold))
                                    .tracking(2)
                                    .foregroundStyle(GW.mute)
                            }
                        }
                        .toolbarBackground(GW.bg, for: .navigationBar)
                        .toolbarBackground(.visible, for: .navigationBar)
                    } label: {
                        entryRow(entry.label)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func entryRow(_ label: String) -> some View {
        GWCard(paddingX: 14, paddingY: 14) {
            HStack {
                Text(label)
                    .font(GW.sans(14, weight: .medium))
                    .foregroundStyle(GW.ink)
                Spacer()
                Text("›")
                    .font(GW.mono(18, weight: .medium))
                    .foregroundStyle(GW.mute)
            }
        }
    }
}

private struct SystemShowcasePage: View {
    enum Card { case palette, type, components }
    let card: Card

    var body: some View {
        ZStack {
            GW.bg.ignoresSafeArea()
            ScrollView {
                Group {
                    switch card {
                    case .palette:    GWPaletteCard()
                    case .type:       GWTypeCard()
                    case .components: GWComponentsCard()
                    }
                }
                .padding(20)
            }
        }
        
        .foregroundStyle(GW.ink)
    }
}

#Preview {
    GlassworkGalleryView()
}
