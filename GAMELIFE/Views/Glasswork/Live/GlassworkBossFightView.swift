//
//  GlassworkBossFightView.swift
//  GAMELIFE
//
//  Live Boss Fight detail — ringed sigil, boss meta, HP bar, strike log
//  (pending micro-tasks · tappable), and RETREAT / STRIKE NOW. STRIKE
//  completes the first pending micro-task via gameEngine.completeMicroTask.
//

import SwiftUI

struct GlassworkBossFightView: View {
    @EnvironmentObject var gameEngine: GameEngine
    @Environment(\.dismiss) private var dismiss
    let bossID: UUID
    let hue: Double

    @State private var flashDamage = false

    private var boss: BossFight? {
        gameEngine.activeBossFights.first(where: { $0.id == bossID })
    }

    var body: some View {
        if let b = boss {
            content(boss: b)
        } else {
            ZStack {
                GW.bg.ignoresSafeArea()
                Text("Boss not found")
                    .font(GW.sans(14))
                    .foregroundStyle(GW.mute)
            }
            .preferredColorScheme(.dark)
        }
    }

    private func content(boss b: BossFight) -> some View {
        let glow = Color.hsl(hue, 80, 60)
        let pct = b.hpPercentage
        let pending = b.microTasks.filter { !$0.isCompleted }

        return ZStack(alignment: .top) {
            GW.bg.ignoresSafeArea()
            tintedAurora(glow: glow).ignoresSafeArea()
            dotGrid.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar(boss: b)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                Spacer().frame(height: 40)

                sigilRing(boss: b, glow: glow)

                VStack(spacing: 4) {
                    Text(b.targetStats.first.map { $0.rawValue } ?? "BOSS")
                        .font(GW.mono(10, weight: .medium))
                        .tracking(3)
                        .foregroundStyle(glow)
                    Text(b.title)
                        .font(GW.display(26, weight: .bold))
                        .tracking(-0.5)
                        .foregroundStyle(GW.ink)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    Text(b.description)
                        .font(GW.sans(12))
                        .foregroundStyle(GW.mute)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .padding(.top, 18)
                .padding(.horizontal, 16)

                VStack(spacing: 6) {
                    HStack {
                        Text("BOSS HP")
                            .font(GW.mono(10))
                            .tracking(1)
                            .foregroundStyle(GW.mute)
                        Spacer()
                        Text("\(b.remainingHP.formatted()) / \(b.maxHP.formatted())")
                            .font(GW.mono(10))
                            .tracking(1)
                            .foregroundStyle(glow)
                    }
                    GWBar(pct: pct,
                          height: 8,
                          gradient: AnyShapeStyle(
                              LinearGradient(colors: [glow, GW.pink],
                                             startPoint: .leading, endPoint: .trailing)
                          ),
                          glow: false)
                }
                .padding(.top, 16)
                .padding(.horizontal, 22)

                Spacer()
            }

            VStack(spacing: 0) {
                Spacer()
                strikeLog(boss: b, pending: pending)
                    .padding(.horizontal, 22)
                    .padding(.bottom, 14)
                HStack(spacing: 10) {
                    GWButton(label: "RETREAT", variant: .ghost) { dismiss() }
                    GWButton(label: pending.isEmpty ? "NO STRIKES" : "STRIKE NOW",
                             variant: .danger) {
                        guard let task = pending.first else { return }
                        _ = gameEngine.completeMicroTask(bossId: b.id, taskId: task.id)
                        HapticManager.shared.bossHit(isCritical: false)
                        withAnimation(.easeOut(duration: 0.18)) { flashDamage = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.easeIn(duration: 0.2)) { flashDamage = false }
                        }
                    }
                    .layoutPriority(1.6)
                    .opacity(pending.isEmpty ? 0.45 : 1)
                    .disabled(pending.isEmpty)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 32)
            }
        }
        .foregroundStyle(GW.ink)
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden)
    }

    // MARK: subviews

    private func topBar(boss b: BossFight) -> some View {
        let days = max(0, Calendar.current.dateComponents([.day], from: b.createdAt, to: Date()).day ?? 0)
        let span: String = {
            if let dl = b.deadline {
                let total = max(1, Calendar.current.dateComponents([.day], from: b.createdAt, to: dl).day ?? 30)
                return "\(days) / \(total)"
            }
            return "\(days)"
        }()
        return HStack {
            Button { dismiss() } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(GW.hairline))
                    Text("‹").font(GW.mono(18)).foregroundStyle(GW.mute)
                }
                .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            Spacer()
            Text("BOSS · DAY \(span)")
                .font(GW.mono(9, weight: .medium))
                .tracking(2)
                .foregroundStyle(GW.mute)
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
    }

    private func sigilRing(boss b: BossFight, glow: Color) -> some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 1.5)
                .frame(width: 200, height: 200)
            Circle()
                .trim(from: 0, to: b.hpPercentage)
                .stroke(
                    LinearGradient(colors: [glow, GW.pink],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.6), value: b.hpPercentage)

            Canvas { ctx, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                for i in 0..<60 {
                    let a = CGFloat(i) / 60 * .pi * 2 - .pi / 2
                    let r1: CGFloat = 86, r2: CGFloat = 90
                    let start = CGPoint(x: center.x + cos(a) * r1, y: center.y + sin(a) * r1)
                    let end   = CGPoint(x: center.x + cos(a) * r2, y: center.y + sin(a) * r2)
                    var p = Path(); p.move(to: start); p.addLine(to: end)
                    ctx.stroke(p, with: .color(Color.white.opacity(0.15)), lineWidth: 1)
                }
            }
            .frame(width: 220, height: 220)

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.hsl(hue, 65, 50), Color.hsl(hue, 60, 18)],
                            center: UnitPoint(x: 0.3, y: 0.3),
                            startRadius: 4,
                            endRadius: 140
                        )
                    )
                    .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
                    .shadow(color: glow.opacity(0.45), radius: 40)
                Text(String(b.title.prefix(1)).uppercased())
                    .font(GW.display(64, weight: .bold))
                    .foregroundStyle(GW.ink)
                    .shadow(color: .black.opacity(0.6), radius: 4, y: 2)
            }
            .frame(width: 144, height: 144)

            if flashDamage {
                Text("−\(b.lastDamageDealt) HP")
                    .font(GW.mono(11, weight: .bold))
                    .foregroundStyle(GW.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(GW.gradDanger))
                    .shadow(color: GW.danger.opacity(0.45), radius: 12)
                    .rotationEffect(.degrees(8))
                    .offset(x: 100, y: -100)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .frame(width: 220, height: 220)
    }

    private func strikeLog(boss b: BossFight, pending: [MicroTask]) -> some View {
        GWCard(paddingX: 14, paddingY: 12) {
            VStack(spacing: 10) {
                HStack {
                    Text("STRIKE LOG · TODAY")
                        .font(GW.mono(9, weight: .medium))
                        .tracking(2)
                        .foregroundStyle(GW.mute)
                    Spacer()
                    if b.lastDamageDealt > 0 {
                        Text("−\(b.lastDamageDealt) HP")
                            .font(GW.mono(9, weight: .medium))
                            .tracking(2)
                            .foregroundStyle(GW.danger)
                    }
                }

                if b.microTasks.isEmpty {
                    Text("No strikes yet. Link a daily quest or add a micro-task to start dealing damage.")
                        .font(GW.sans(12))
                        .foregroundStyle(GW.mute)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(spacing: 8) {
                        ForEach(b.microTasks.prefix(4)) { task in
                            strikeRow(task: task, bossID: b.id)
                        }
                    }
                }
            }
        }
    }

    private func strikeRow(task: MicroTask, bossID: UUID) -> some View {
        let done = task.isCompleted
        return HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(done ? "✓" : "◇")
                .font(GW.mono(11, weight: .bold))
                .foregroundStyle(done ? GW.good : GW.cyan)
                .frame(width: 18, alignment: .leading)
            Text(task.title)
                .font(GW.sans(12))
                .foregroundStyle(done ? GW.mute : GW.inkSoft)
                .strikethrough(done)
            Spacer(minLength: 6)
            Text(done ? "DEALT" : "−\(task.estimatedDamage)")
                .font(GW.mono(10))
                .foregroundStyle(done ? GW.mute : GW.danger)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard !done else { return }
            _ = gameEngine.completeMicroTask(bossId: bossID, taskId: task.id)
            HapticManager.shared.bossHit(isCritical: false)
            withAnimation(.easeOut(duration: 0.18)) { flashDamage = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeIn(duration: 0.2)) { flashDamage = false }
            }
        }
    }

    private func tintedAurora(glow: Color) -> some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            func ellipse(_ center: CGPoint, _ rx: CGFloat, _ ry: CGFloat, _ c: Color) {
                let rect = CGRect(x: center.x - rx, y: center.y - ry, width: rx * 2, height: ry * 2)
                let g = Gradient(colors: [c, c.opacity(0)])
                ctx.fill(Path(ellipseIn: rect),
                         with: .radialGradient(g, center: center,
                                               startRadius: 0,
                                               endRadius: max(rx, ry)))
            }
            ellipse(CGPoint(x: w * 0.5, y: h * 0.3), w * 0.8, h * 0.5,
                    Color.hsl(hue, 70, 35).opacity(0.6))
            ellipse(CGPoint(x: w * 0.8, y: h * 1.0), w * 0.6, h * 0.4,
                    GW.pink.opacity(0.2))
        }
    }

    private var dotGrid: some View {
        Canvas { ctx, size in
            let step: CGFloat = 14
            let rows = Int(size.height / step) + 1
            let cols = Int(size.width / step) + 1
            for r in 0..<rows {
                for c in 0..<cols {
                    let p = CGPoint(x: CGFloat(c) * step, y: CGFloat(r) * step)
                    ctx.fill(Path(ellipseIn: CGRect(x: p.x - 0.5, y: p.y - 0.5,
                                                    width: 1, height: 1)),
                             with: .color(Color.white.opacity(0.06)))
                }
            }
        }
        .opacity(0.55)
    }
}
