//
//  GlassworkTrainingView.swift
//  GAMELIFE
//
//  Live Glasswork Training tab. Idle: task + duration picker (15/25/45/60/
//  90/custom) with reward preview that scales with the selected duration.
//  Active: countdown ring, elapsed time, live "earned so far" payout, and
//  a single obvious END button that ends the session with proportional
//  rewards (gameEngine.endDungeonEarly).
//

import SwiftUI
import Combine

struct GlassworkTrainingView: View {
    @EnvironmentObject var gameEngine: GameEngine

    // Idle-screen state
    @State private var pickedDuration: Int = 45
    @State private var sessionTitle: String = "Ship one PR review"
    @State private var customDuration: String = ""
    @State private var showCustomEditor: Bool = false
    @FocusState private var customDurationFocused: Bool

    // Active-dungeon state
    @State private var nowTick: Date = Date()
    @State private var showEndConfirmation: Bool = false

    private let durationOptions: [Int] = [15, 25, 45, 60, 90]
    private let minCustomMinutes = 5
    private let maxCustomMinutes = 240

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
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            // Drives recomputation of activeDungeon's countdown UI.
            nowTick = Date()
        }
    }

    // MARK: - Reward preview (scales with selected duration)

    /// Reward formula matches the engine's Dungeon init:
    /// xp = (minutes / 5) * questXP(difficulty: .normal)
    /// gold = (minutes / 5) * questGold(difficulty: .normal)
    /// difficulty .normal → questXP = 30, questGold = ~25 (see GameFormulas).
    private func rewardPreview(for minutes: Int) -> (xp: Int, gold: Int) {
        let blocks = max(1, minutes / 5)
        return (xp: blocks * 30, gold: blocks * 25)
    }

    // MARK: - Idle / start screen

    private var startScreen: some View {
        GeometryReader { geo in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    Spacer(minLength: 8)

                    header

                    hunterLogStrip

                    quickStartRow

                    sessionCard

                    if showCustomEditor {
                        customDurationCard
                    }

                    GWButton(label: "ENTER DUNGEON", variant: .primary) {
                        startSession()
                    }
                    .padding(.horizontal, 22)

                    motivationalQuote
                        .padding(.horizontal, 28)
                        .padding(.top, 4)

                    Spacer(minLength: 24)
                }
                .frame(maxWidth: .infinity, minHeight: geo.size.height)
                .padding(.bottom, 110)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            PulsingRune()
                .frame(width: 64, height: 64)
            HStack(spacing: 6) {
                BreathingDot(color: GW.cyan, size: 6)
                Text("[ DUNGEON · DEEP FOCUS ]")
                    .font(GW.mono(10, weight: .medium))
                    .tracking(3)
                    .foregroundStyle(GW.cyan)
            }
            Text("Deep Focus Session")
                .font(GW.display(28, weight: .semibold))
                .tracking(-0.5)
                .foregroundStyle(GW.ink)
                .multilineTextAlignment(.center)
            Text("Phone face-down. The system rewards what you don't quit on.")
                .font(GW.sans(12))
                .foregroundStyle(GW.mute)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Hunter log strip — quick stats above the picker

    private var hunterLogStrip: some View {
        let cleared = gameEngine.player.dungeonsClearedCount
        let streak = gameEngine.player.currentStreak
        let level = gameEngine.player.level
        return HStack(spacing: 10) {
            statTile(value: "\(cleared)", label: "CLEARED", tint: GW.cyan)
            statTile(value: "\(streak)", label: "STREAK · D", tint: GW.amber)
            statTile(value: "LV \(level)", label: "HUNTER", tint: GW.pink)
        }
        .padding(.horizontal, 16)
    }

    private func statTile(value: String, label: String, tint: Color) -> some View {
        GWCard(paddingX: 10, paddingY: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(GW.mono(8, weight: .medium))
                    .tracking(1.4)
                    .foregroundStyle(GW.mute)
                Text(value)
                    .font(GW.display(20, weight: .bold))
                    .foregroundStyle(tint)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Quick-start presets — visual entry points for common sessions

    private struct Preset {
        let label: String
        let glyph: String
        let minutes: Int
        let blurb: String
    }

    private var presets: [Preset] {
        [
            Preset(label: "SPRINT",   glyph: "bolt.fill",       minutes: 15, blurb: "Quick burn"),
            Preset(label: "POMODORO", glyph: "circle.hexagonpath.fill", minutes: 25, blurb: "Classic 25"),
            Preset(label: "DEEP",     glyph: "moon.stars.fill", minutes: 45, blurb: "Real work"),
            Preset(label: "MARATHON", glyph: "flame.fill",      minutes: 90, blurb: "All in"),
        ]
    }

    private var quickStartRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(presets, id: \.label) { p in
                    presetCard(p)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func presetCard(_ p: Preset) -> some View {
        let isSelected = pickedDuration == p.minutes && !showCustomEditor
        return Button {
            pickedDuration = p.minutes
            showCustomEditor = false
            customDurationFocused = false
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: p.glyph)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isSelected ? GW.cyan : GW.mute)
                Text(p.label)
                    .font(GW.mono(10, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(isSelected ? GW.cyan : GW.inkSoft)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(p.minutes)")
                        .font(GW.display(20, weight: .bold))
                        .foregroundStyle(isSelected ? GW.cyan : GW.ink)
                    Text("M")
                        .font(GW.mono(10))
                        .foregroundStyle(GW.mute)
                }
                Text(p.blurb)
                    .font(GW.mono(8))
                    .tracking(0.8)
                    .foregroundStyle(GW.mute)
            }
            .padding(12)
            .frame(width: 110, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        LinearGradient(
                            colors: isSelected
                                ? [GW.cyan.opacity(0.10), GW.pink.opacity(0.05)]
                                : [Color.white.opacity(0.04), Color.clear],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(
                                isSelected ? GW.cyan.opacity(0.45) : GW.hairline,
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: isSelected ? GW.cyan.opacity(0.18) : .clear, radius: 12)
        }
        .buttonStyle(.plain)
    }

    private var sessionCard: some View {
        let preview = rewardPreview(for: pickedDuration)

        return GWCard(paddingX: 14, paddingY: 14) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("TASK · TAP TO EDIT")
                        .font(GW.mono(9, weight: .medium))
                        .tracking(2)
                        .foregroundStyle(GW.mute)
                    Spacer()
                    Image(systemName: "pencil")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(GW.mute)
                }
                TextField("Ship one PR review", text: $sessionTitle)
                    .font(GW.sans(15, weight: .medium))
                    .foregroundStyle(GW.ink)
                    .textFieldStyle(.plain)
                    .submitLabel(.done)
                    .padding(.horizontal, 10).padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(GW.cyan.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(GW.cyan.opacity(0.20), lineWidth: 1)
                            )
                    )

                Text("DURATION")
                    .font(GW.mono(9, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(GW.mute)
                    .padding(.top, 4)

                durationChips

                Text("REWARD")
                    .font(GW.mono(9, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(GW.mute)
                    .padding(.top, 4)
                HStack(spacing: 12) {
                    rewardChip("+\(preview.xp) XP", GW.cyan)
                    rewardChip("+\(preview.gold) g", GW.amber)
                    Spacer()
                }
                Text("End early and you still earn proportional rewards.")
                    .font(GW.mono(9))
                    .tracking(0.5)
                    .foregroundStyle(GW.mute)
            }
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var durationChips: some View {
        // Two rows: preset chips, then a "Custom..." toggle showing the
        // current custom value when set.
        FlowingChipsRow {
            ForEach(durationOptions, id: \.self) { opt in
                durationChip(label: "\(opt)M",
                             selected: pickedDuration == opt && !showCustomEditor) {
                    pickedDuration = opt
                    showCustomEditor = false
                    customDurationFocused = false
                }
            }
            durationChip(label: showCustomEditor || !durationOptions.contains(pickedDuration)
                                ? "CUSTOM · \(pickedDuration)M"
                                : "CUSTOM",
                         selected: showCustomEditor || !durationOptions.contains(pickedDuration)) {
                showCustomEditor = true
                customDuration = "\(pickedDuration)"
                customDurationFocused = true
            }
        }
    }

    private func durationChip(label: String, selected: Bool, tap: @escaping () -> Void) -> some View {
        Button(action: tap) {
            Text(label)
                .font(GW.mono(11, weight: .medium))
                .tracking(1.4)
                .foregroundStyle(selected ? GW.cyan : GW.mute)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(selected ? GW.cyan.opacity(0.07) : Color.clear)
                        .overlay(
                            Capsule().stroke(
                                selected ? GW.cyan.opacity(0.33) : GW.hairline,
                                lineWidth: 1
                            )
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private var customDurationCard: some View {
        GWCard(paddingX: 14, paddingY: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("CUSTOM DURATION · MINUTES")
                    .font(GW.mono(9, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(GW.mute)
                HStack(spacing: 8) {
                    TextField("e.g. 35", text: $customDuration)
                        .keyboardType(.numberPad)
                        .focused($customDurationFocused)
                        .font(GW.display(18, weight: .semibold))
                        .foregroundStyle(GW.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onChange(of: customDuration) { _, new in
                            // Live-validate while typing — restrict to digits,
                            // clamp, and reflect on the preview card.
                            let digits = new.filter(\.isNumber)
                            if digits != new {
                                customDuration = digits
                                return
                            }
                            if let v = Int(digits) {
                                pickedDuration = clampedCustom(v)
                            }
                        }
                    Stepper("", value: Binding(
                        get: { pickedDuration },
                        set: { new in
                            pickedDuration = clampedCustom(new)
                            customDuration = "\(pickedDuration)"
                        }
                    ), in: minCustomMinutes...maxCustomMinutes, step: 5)
                    .labelsHidden()
                }
                Text("\(minCustomMinutes)–\(maxCustomMinutes) minutes")
                    .font(GW.mono(9))
                    .foregroundStyle(GW.mute)
            }
        }
        .padding(.horizontal, 16)
    }

    private func clampedCustom(_ v: Int) -> Int {
        max(minCustomMinutes, min(maxCustomMinutes, v))
    }

    private func rewardChip(_ text: String, _ color: Color) -> some View {
        Text(text)
            .font(GW.display(18, weight: .bold))
            .foregroundStyle(color)
    }

    private var motivationalQuote: some View {
        // Picks one of N lines deterministically per minute so the prompt
        // varies between sessions without churning every render.
        let lines = [
            "Focus is a kept promise.",
            "The system rewards what you don't quit on.",
            "Sit. Stay. Earn.",
            "Hunters fight the urge first.",
            "Small windows. Real damage.",
            "Phone face-down. Future face-up.",
        ]
        let idx = Int(Date().timeIntervalSince1970 / 60) % lines.count
        return Text(lines[idx])
            .font(GW.mono(10))
            .tracking(1.2)
            .foregroundStyle(GW.mute)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    private func startSession() {
        customDurationFocused = false
        let minutes = clampedCustom(pickedDuration)
        let trimmed = sessionTitle.trimmingCharacters(in: .whitespaces)
        let title = trimmed.isEmpty ? "Deep Work Session" : trimmed
        gameEngine.startDungeon(minutes: minutes, title: title)
    }

    // MARK: - Active dungeon

    private func activeDungeon(_ d: Dungeon) -> some View {
        let pct = d.progress
        let remainingMin = d.remainingSeconds / 60
        let remainingSec = d.remainingSeconds % 60
        let earned = rewardPreview(for: d.durationMinutes)
        let earnedSoFarXP = Int((Double(earned.xp) * pct).rounded())
        let earnedSoFarGold = Int((Double(earned.gold) * pct).rounded())
        let elapsedMin = d.elapsedSeconds / 60
        let elapsedSec = d.elapsedSeconds % 60

        return VStack(spacing: 0) {
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    BreathingDot(color: GW.cyan, size: 6)
                    Text("[ DUNGEON · DEEP FOCUS ]")
                        .font(GW.mono(10, weight: .medium))
                        .tracking(3)
                        .foregroundStyle(GW.cyan)
                }
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

            Spacer().frame(height: 22)

            timerRing(pct: pct, min: remainingMin, sec: remainingSec)

            elapsedAndEarnedCard(elapsedMin: elapsedMin,
                                 elapsedSec: elapsedSec,
                                 earnedXP: earnedSoFarXP,
                                 earnedGold: earnedSoFarGold,
                                 cleared: earned)
                .padding(.horizontal, 22)
                .padding(.top, 18)

            statusCard(d: d)
                .padding(.horizontal, 22)
                .padding(.top, 10)

            Spacer()

            GWButton(label: "END SESSION", variant: .danger) {
                showEndConfirmation = true
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 120)
        }
        .alert("End session early?",
               isPresented: $showEndConfirmation) {
            Button("Keep going", role: .cancel) { }
            Button("End now", role: .destructive) {
                gameEngine.endDungeonEarly()
            }
        } message: {
            Text("You'll earn \(Int((gameEngine.activeDungeon?.progress ?? 0) * 100))% of the rewards — about +\(Int((Double(rewardPreview(for: d.durationMinutes).xp) * (gameEngine.activeDungeon?.progress ?? 0)).rounded())) XP and +\(Int((Double(rewardPreview(for: d.durationMinutes).gold) * (gameEngine.activeDungeon?.progress ?? 0)).rounded())) g. No penalty.")
        }
    }

    private func statsLine(for d: Dungeon) -> String {
        let stats = d.targetStats.map { $0.rawValue }.joined(separator: " · ")
        return "\(stats) · \(d.durationMinutes)-MIN SESSION · NO PHONE"
    }

    @ViewBuilder
    private func elapsedAndEarnedCard(elapsedMin: Int,
                                      elapsedSec: Int,
                                      earnedXP: Int,
                                      earnedGold: Int,
                                      cleared: (xp: Int, gold: Int)) -> some View {
        GWCard(paddingX: 14, paddingY: 12) {
            VStack(spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text("ELAPSED")
                        .font(GW.mono(9, weight: .medium))
                        .tracking(2)
                        .foregroundStyle(GW.mute)
                    Spacer()
                    Text(String(format: "%02d:%02d", elapsedMin, elapsedSec))
                        .font(GW.mono(13, weight: .semibold))
                        .foregroundStyle(GW.ink)
                }
                Divider().overlay(GW.hairline)
                HStack(alignment: .firstTextBaseline) {
                    Text("EARNED SO FAR")
                        .font(GW.mono(9, weight: .medium))
                        .tracking(2)
                        .foregroundStyle(GW.mute)
                    Spacer()
                    Text("+\(earnedXP) XP")
                        .font(GW.mono(13, weight: .semibold))
                        .foregroundStyle(GW.cyan)
                    Text("·")
                        .font(GW.mono(13))
                        .foregroundStyle(GW.mute)
                    Text("+\(earnedGold) g")
                        .font(GW.mono(13, weight: .semibold))
                        .foregroundStyle(GW.amber)
                }
                HStack {
                    Text("ON CLEAR")
                        .font(GW.mono(9, weight: .medium))
                        .tracking(2)
                        .foregroundStyle(GW.mute)
                    Spacer()
                    Text("+\(cleared.xp) XP · +\(cleared.gold) g")
                        .font(GW.mono(11))
                        .foregroundStyle(GW.mute)
                }
            }
        }
    }

    private func statusCard(d: Dungeon) -> some View {
        GWCard(paddingX: 14, paddingY: 12) {
            HStack {
                HStack(spacing: 8) {
                    BreathingDot(color: d.isActive ? GW.good : GW.mute, size: 8)
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
    }

    // MARK: Timer ring

    private func timerRing(pct: Double, min: Int, sec: Int) -> some View {
        let R: CGFloat = 96
        return ZStack {
            Circle()
                .stroke(GW.hairlineHi, lineWidth: 3)
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
                Text("\(Int(pct * 100))% complete")
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

// MARK: - PulsingRune — a Prism-style rotating-square glyph that pulses

private struct PulsingRune: View {
    @State private var rotation: Double = 0
    @State private var pulse: CGFloat = 0.85

    var body: some View {
        ZStack {
            // Halo
            Circle()
                .fill(
                    RadialGradient(colors: [GW.pink.opacity(0.35), .clear],
                                   center: .center,
                                   startRadius: 0,
                                   endRadius: 48)
                )
                .scaleEffect(pulse)

            // Outer hairline
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(GW.cyan.opacity(0.5), lineWidth: 1.5)
                .frame(width: 44, height: 44)
                .rotationEffect(.degrees(45 + rotation))

            // Inner gradient face
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(GW.grad)
                .frame(width: 28, height: 28)
                .rotationEffect(.degrees(45 + rotation))
                .shadow(color: GW.pink.opacity(0.45), radius: 12)

            // White spark
            Circle()
                .fill(Color.white.opacity(0.95))
                .frame(width: 4, height: 4)
                .offset(x: -10, y: -10)
                .rotationEffect(.degrees(rotation))
        }
        .onAppear {
            withAnimation(.linear(duration: 24).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                pulse = 1.15
            }
        }
    }
}

// MARK: - BreathingDot — pulses cyan/good to signal a live state

private struct BreathingDot: View {
    let color: Color
    let size: CGFloat
    @State private var scale: CGFloat = 1
    @State private var glow: CGFloat = 0.4

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .scaleEffect(scale)
            .shadow(color: color.opacity(glow), radius: size * 1.2)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    scale = 1.3
                    glow = 0.9
                }
            }
    }
}

// MARK: - FlowingChipsRow — wraps chips to next line when row overflows

private struct FlowingChipsRow<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        // Simple wrapping: HStack with .wrap-ish behavior via a LazyVGrid
        // of one row that flows by adaptive sizing.
        FlowLayout(spacing: 6) {
            content
        }
    }
}

/// Minimal flow layout — wraps subviews into multiple rows.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var (rowWidth, rowHeight, totalHeight): (CGFloat, CGFloat, CGFloat) = (0, 0, 0)
        for sub in subviews {
            let sz = sub.sizeThatFits(.unspecified)
            if rowWidth + sz.width > maxWidth, rowWidth > 0 {
                totalHeight += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += sz.width + spacing
            rowHeight = max(rowHeight, sz.height)
        }
        totalHeight += rowHeight
        return CGSize(width: maxWidth.isFinite ? maxWidth : rowWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for sub in subviews {
            let sz = sub.sizeThatFits(.unspecified)
            if x + sz.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(sz))
            x += sz.width + spacing
            rowHeight = max(rowHeight, sz.height)
        }
    }
}
