//
//  GlassworkTrainingView.swift
//  GAMELIFE
//
//  Live Glasswork Training tab. When no dungeon is active, presents a
//  duration-picker start screen. When one is running, shows the timer ring
//  + status card + ABANDON. Wired to gameEngine.activeDungeon /
//  startDungeon(minutes:) / failDungeon().
//

import SwiftUI
import Combine

struct GlassworkTrainingView: View {
    @EnvironmentObject var gameEngine: GameEngine
    @State private var pickedDuration: Int = 45
    @State private var sessionTitle: String = "Ship one PR review"
    @State private var nowTick: Date = Date()

    private let durationOptions: [Int] = [15, 25, 45, 60, 90]

    var body: some View {
        ZStack {
            GW.bg.ignoresSafeArea()
            auroraBg.ignoresSafeArea()
            dotGrid.ignoresSafeArea()

            if let dungeon = gameEngine.activeDungeon {
                activeDungeon(dungeon)
            } else {
                startScreen
            }
        }
        .foregroundStyle(GW.ink)
        .preferredColorScheme(.dark)
    }

    // MARK: Idle / start screen

    private var startScreen: some View {
        // Compose the start screen as a vertically centered column so the
        // pick-a-session card sits in the middle of the available space
        // until the dungeon is actually running. GeometryReader lets the
        // inner VStack stretch to at least the screen height so the
        // Spacers actually do their job.
        GeometryReader { geo in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    Spacer(minLength: 24)

                VStack(spacing: 6) {
                    Text("[ DUNGEON · DEEP FOCUS ]")
                        .font(GW.mono(10, weight: .medium))
                        .tracking(3)
                        .foregroundStyle(GW.cyan)
                    Text("Pick a session")
                        .font(GW.display(28, weight: .semibold))
                        .tracking(-0.5)
                        .foregroundStyle(GW.ink)
                    Text("Phone face-down. The system rewards what you don't quit on.")
                        .font(GW.sans(12))
                        .foregroundStyle(GW.mute)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 280)
                }
                .frame(maxWidth: .infinity)

                GWCard(paddingX: 14, paddingY: 14) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("TASK")
                            .font(GW.mono(9, weight: .medium))
                            .tracking(2)
                            .foregroundStyle(GW.mute)
                        TextField("Ship one PR review",
                                  text: $sessionTitle)
                            .font(GW.sans(15, weight: .medium))
                            .foregroundStyle(GW.ink)
                            .textFieldStyle(.plain)

                        Text("DURATION")
                            .font(GW.mono(9, weight: .medium))
                            .tracking(2)
                            .foregroundStyle(GW.mute)
                            .padding(.top, 4)
                        HStack(spacing: 6) {
                            ForEach(durationOptions, id: \.self) { opt in
                                Button { pickedDuration = opt } label: {
                                    Text("\(opt)M")
                                        .font(GW.mono(11, weight: .medium))
                                        .tracking(1.4)
                                        .foregroundStyle(pickedDuration == opt ? GW.cyan : GW.mute)
                                        .padding(.horizontal, 10).padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(pickedDuration == opt
                                                      ? GW.cyan.opacity(0.07)
                                                      : Color.clear)
                                                .overlay(Capsule().stroke(pickedDuration == opt
                                                                          ? GW.cyan.opacity(0.33)
                                                                          : GW.hairline,
                                                                          lineWidth: 1))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Text("REWARD")
                            .font(GW.mono(9, weight: .medium))
                            .tracking(2)
                            .foregroundStyle(GW.mute)
                            .padding(.top, 4)
                        let approx = max(15, (pickedDuration / 5) * 30)
                        HStack(spacing: 12) {
                            rewardChip("+\(approx) XP", GW.cyan)
                            rewardChip("+\(approx) g",  GW.amber)
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 16)

                    GWButton(label: "ENTER DUNGEON", variant: .primary) {
                        let title = sessionTitle.trimmingCharacters(in: .whitespaces).isEmpty
                            ? "Deep Work Session" : sessionTitle
                        gameEngine.startDungeon(minutes: pickedDuration, title: title)
                    }
                    .padding(.horizontal, 22)

                    Spacer(minLength: 24)
                }
                .frame(maxWidth: .infinity, minHeight: geo.size.height)
                .padding(.bottom, 110)
            }
        }
    }

    private func rewardChip(_ text: String, _ color: Color) -> some View {
        Text(text)
            .font(GW.display(18, weight: .bold))
            .foregroundStyle(color)
    }

    // MARK: Active dungeon

    private func activeDungeon(_ d: Dungeon) -> some View {
        let pct = d.progress
        let remainingMin = d.remainingSeconds / 60
        let remainingSec = d.remainingSeconds % 60

        return VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text("[ DUNGEON · DEEP FOCUS ]")
                    .font(GW.mono(10, weight: .medium))
                    .tracking(3)
                    .foregroundStyle(GW.cyan)
                Text(d.title)
                    .font(GW.display(22, weight: .semibold))
                    .tracking(-0.3)
                    .foregroundStyle(GW.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                Text(statsLine(for: d))
                    .font(GW.mono(10))
                    .tracking(1)
                    .foregroundStyle(GW.mute)
            }
            .padding(.top, 16)
            .padding(.horizontal, 22)

            Spacer().frame(height: 28)

            timerRing(pct: pct, min: remainingMin, sec: remainingSec, xpOnClear: d.xpReward)

            GWCard(paddingX: 14, paddingY: 12) {
                HStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(d.isActive ? GW.good : GW.mute)
                            .frame(width: 8, height: 8)
                            .shadow(color: d.isActive ? GW.good : .clear, radius: 4)
                        Text(d.isActive ? "Phone face-down · running" : "Session ended")
                            .font(GW.sans(12))
                            .foregroundStyle(GW.inkSoft)
                    }
                    Spacer()
                    Text(d.isActive ? "BONUS ACTIVE" : "IDLE")
                        .font(GW.mono(10, weight: .medium))
                        .tracking(1)
                        .foregroundStyle(d.isActive ? GW.good : GW.mute)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)

            Spacer()

            HStack(spacing: 10) {
                GWButton(label: "ABANDON", variant: .ghost) {
                    gameEngine.failDungeon()
                }
                .layoutPriority(1)
                GWButton(label: "RUNNING", variant: .primary,
                         icon: "❚❚") {
                    // No pause in engine; button is informational.
                }
                .layoutPriority(1.6)
                .opacity(0.55)
                .disabled(true)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 120)
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            nowTick = Date()
        }
    }

    private func statsLine(for d: Dungeon) -> String {
        let stats = d.targetStats.map { $0.rawValue }.joined(separator: " · ")
        return "\(stats) · \(d.durationMinutes)-MIN SESSION · NO PHONE"
    }

    // MARK: Timer ring (same construction as the gallery's Dungeon screen)

    private func timerRing(pct: Double, min: Int, sec: Int, xpOnClear: Int) -> some View {
        let R: CGFloat = 96
        return ZStack {
            Circle()
                .stroke(Color.white.opacity(0.07), lineWidth: 3)
                .frame(width: R * 2, height: R * 2)
            Circle()
                .trim(from: 0, to: max(0.001, pct))
                .stroke(
                    LinearGradient(colors: [GW.cyan, GW.pink],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: R * 2, height: R * 2)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.4), value: pct)

            Canvas { ctx, size in
                let c = CGPoint(x: size.width / 2, y: size.height / 2)
                for i in 0..<60 {
                    let a = CGFloat(i) / 60 * .pi * 2 - .pi / 2
                    let r1: CGFloat = 80
                    let r2: CGFloat = (i % 5 == 0) ? 73 : 76
                    let s = CGPoint(x: c.x + cos(a) * r1, y: c.y + sin(a) * r1)
                    let e = CGPoint(x: c.x + cos(a) * r2, y: c.y + sin(a) * r2)
                    var p = Path(); p.move(to: s); p.addLine(to: e)
                    ctx.stroke(p,
                               with: .color(i % 5 == 0
                                            ? Color.white.opacity(0.3)
                                            : Color.white.opacity(0.1)),
                               lineWidth: 1)
                }
            }
            .frame(width: 240, height: 240)

            VStack(spacing: 4) {
                Text("REMAINING")
                    .font(GW.mono(10, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(GW.mute)
                HStack(spacing: 0) {
                    Text(String(format: "%02d", min))
                        .font(GW.display(56, weight: .semibold))
                        .tracking(-2)
                        .foregroundStyle(GW.ink)
                    Text(":")
                        .font(GW.display(56, weight: .semibold))
                        .foregroundStyle(GW.cyan)
                    Text(String(format: "%02d", sec))
                        .font(GW.display(56, weight: .semibold))
                        .tracking(-2)
                        .foregroundStyle(GW.ink)
                }
                Text("+\(xpOnClear) XP ON CLEAR")
                    .font(GW.mono(9, weight: .medium))
                    .tracking(1.5)
                    .foregroundStyle(GW.mute)
                    .padding(.top, 4)
            }
        }
        .frame(width: 240, height: 240)
    }

    // MARK: backdrops

    private var auroraBg: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            func ellipse(_ c: CGPoint, _ rx: CGFloat, _ ry: CGFloat, _ color: Color) {
                let rect = CGRect(x: c.x - rx, y: c.y - ry, width: rx * 2, height: ry * 2)
                let g = Gradient(colors: [color, color.opacity(0)])
                ctx.fill(Path(ellipseIn: rect),
                         with: .radialGradient(g, center: c,
                                               startRadius: 0,
                                               endRadius: max(rx, ry)))
            }
            ellipse(CGPoint(x: w * 0.5, y: h * 0.4), w * 0.7, h * 0.5, GW.cyan.opacity(0.13))
            ellipse(CGPoint(x: w * 0.5, y: h * 1.0), w * 0.5, h * 0.4, GW.pink.opacity(0.13))
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
                             with: .color(Color.white.opacity(0.05)))
                }
            }
        }
        .opacity(0.55)
    }
}
