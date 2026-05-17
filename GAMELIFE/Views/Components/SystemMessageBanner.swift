//
//  SystemMessageBanner.swift
//  GAMELIFE
//
//  [SYSTEM]: Communication relay initialized.
//  In-app notifications flow through this conduit.
//

import SwiftUI

// MARK: - System Message

/// A system notification displayed as an in-app banner
struct SystemMessage: Identifiable, Equatable {
    let id = UUID()
    let type: MessageType
    let title: String
    let message: String
    let duration: TimeInterval

    init(type: MessageType, title: String, message: String, duration: TimeInterval = 4.0) {
        self.type = type
        self.title = title
        self.message = message
        self.duration = duration
    }

    // MARK: - Message Types

    enum MessageType: String {
        case info = "Info"
        case success = "Success"
        case warning = "Warning"
        case critical = "Critical"
        case levelUp = "Level Up"
        case questComplete = "Quest Complete"

        var color: Color {
            switch self {
            case .info: return GW.cyan
            case .success: return GW.good
            case .warning: return GW.amber
            case .critical: return GW.danger
            case .levelUp: return GW.gold
            case .questComplete: return GW.cyan
            }
        }

        var icon: String {
            switch self {
            case .info: return "diamond.fill"
            case .success: return "checkmark.diamond.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .critical: return "xmark.diamond.fill"
            case .levelUp: return "arrow.up.circle.fill"
            case .questComplete: return "star.fill"
            }
        }
    }

    // MARK: - Static Helpers

    static func questCompleted(title: String, xp: Int, gold: Int) -> SystemMessage {
        let detail: String
        if gold > 0 {
            detail = "\(title) - +\(xp) XP, +\(gold) Gold"
        } else {
            detail = "\(title) - +\(xp) XP (optional quest)"
        }
        return SystemMessage(
            type: .questComplete,
            title: "Quest Complete",
            message: detail
        )
    }

    static func levelUp(level: Int, rank: String) -> SystemMessage {
        SystemMessage(
            type: .levelUp,
            title: "LEVEL UP!",
            message: "You have reached Level \(level). Rank: \(rank)",
            duration: 6.0
        )
    }

    static func warning(_ message: String) -> SystemMessage {
        SystemMessage(type: .warning, title: "Warning", message: message)
    }

    static func info(_ title: String, _ message: String) -> SystemMessage {
        SystemMessage(type: .info, title: title, message: message)
    }
}

// MARK: - System Message Banner View

/// Holographic banner for in-app notifications
struct SystemMessageBanner: View {

    let message: SystemMessage
    let onDismiss: () -> Void

    @State private var opacity: Double = 0
    @State private var offsetY: CGFloat = -100
    @State private var dismissTask: Task<Void, Never>?

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: message.type.icon)
                .font(.system(size: 22))
                .foregroundStyle(message.type.color)
                .shadow(color: message.type.color.opacity(0.6), radius: 6)

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text("[ SYSTEM · \(message.title.uppercased()) ]")
                    .font(GW.mono(11, weight: .medium))
                    .tracking(1.6)
                    .foregroundStyle(message.type.color)

                Text(message.message)
                    .font(GW.sans(12))
                    .foregroundStyle(GW.inkSoft)
                    .lineLimit(2)
            }

            Spacer()

            // Dismiss button
            Button {
                dismissBanner()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(GW.mute)
                    .padding(8)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    LinearGradient(colors: [Color.white.opacity(0.07), Color.white.opacity(0.02)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(message.type.color.opacity(0.4), lineWidth: 1)
        )
        .overlay(alignment: .top) {
            // Accent hairline along the top edge in the message color
            Rectangle()
                .fill(LinearGradient(colors: [.clear, message.type.color, .clear],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(height: 1)
                .padding(.horizontal, 14)
                .offset(y: -0.5)
        }
        .shadow(color: message.type.color.opacity(0.25), radius: 12, y: 6)
        .shadow(color: .black.opacity(0.4), radius: 18, y: 12)
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .offset(y: offsetY)
        .opacity(opacity)
        .onAppear {
            // Animate in
            withAnimation(.easeOut(duration: 0.2)) {
                opacity = 1
                offsetY = 0
            }

            // Schedule auto-dismiss
            dismissTask = Task {
                try? await Task.sleep(nanoseconds: UInt64(message.duration * 1_000_000_000))
                if !Task.isCancelled {
                    await MainActor.run {
                        dismissBanner()
                    }
                }
            }
        }
        .onDisappear {
            dismissTask?.cancel()
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height < -20 {
                        dismissBanner()
                    }
                }
        )
    }

    private func dismissBanner() {
        dismissTask?.cancel()
        withAnimation(.easeOut(duration: 0.25)) {
            opacity = 0
            offsetY = -100
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - View Extension

extension View {
    /// Displays system messages as banners
    func systemMessage(_ message: Binding<SystemMessage?>) -> some View {
        ZStack(alignment: .top) {
            self

            if let msg = message.wrappedValue {
                SystemMessageBanner(message: msg) {
                    message.wrappedValue = nil
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

// MARK: - System Message Helper

/// Helper class to post system messages from anywhere
class SystemMessageHelper {
    static func show(_ message: SystemMessage) {
        NotificationCenter.default.post(
            name: .showSystemMessage,
            object: message
        )
    }

    static func showQuestComplete(title: String, xp: Int, gold: Int) {
        show(.questCompleted(title: title, xp: xp, gold: gold))
    }

    static func showLevelUp(level: Int, rank: String) {
        show(.levelUp(level: level, rank: rank))
    }

    static func showWarning(_ message: String) {
        show(.warning(message))
    }

    static func showInfo(_ title: String, _ message: String) {
        show(.info(title, message))
    }
}

// MARK: - Preview

#Preview("Info Banner") {
    ZStack {
        SystemTheme.backgroundPrimary.ignoresSafeArea()

        VStack {
            SystemMessageBanner(
                message: .info("Training Complete", "You have completed a 25-minute focus session. +50 XP")
            ) {}

            Spacer()
        }
    }
}

#Preview("Level Up Banner") {
    ZStack {
        SystemTheme.backgroundPrimary.ignoresSafeArea()

        VStack {
            SystemMessageBanner(
                message: .levelUp(level: 25, rank: "C-Rank Hunter")
            ) {}

            Spacer()
        }
    }
}
