//
//  KeyboardDismissToolbar.swift
//  GAMELIFE
//
//  Consistent keyboard dismissal affordance for input-heavy flows.
//

import SwiftUI
import UIKit

private struct KeyboardDismissToolbarModifier: ViewModifier {
    @State private var isKeyboardVisible = false

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if isKeyboardVisible {
                    HStack {
                        Spacer(minLength: 0)

                        Button(action: dismissKeyboard) {
                            Text("Done")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(SystemTheme.textPrimary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(SystemTheme.backgroundTertiary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(SystemTheme.backgroundSecondary)
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(SystemTheme.borderSecondary)
                            .frame(height: 1)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                handleKeyboardFrame(notification)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
                handleKeyboardFrame(notification)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { notification in
                setKeyboardVisible(false, notification: notification)
            }
    }

    private func dismissKeyboard() {
        HapticManager.shared.selection()
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
        withAnimation(.easeOut(duration: 0.2)) {
            isKeyboardVisible = false
        }
    }

    private func handleKeyboardFrame(_ notification: Notification) {
        guard let endFrameValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            setKeyboardVisible(true, notification: notification)
            return
        }

        let endFrame = endFrameValue.cgRectValue
        let screenBounds = UIScreen.main.bounds
        let visibleHeight = max(0, screenBounds.maxY - endFrame.minY)
        setKeyboardVisible(visibleHeight > 0, notification: notification)
    }

    private func setKeyboardVisible(_ visible: Bool, notification: Notification) {
        withAnimation(animation(for: notification)) {
            isKeyboardVisible = visible
        }
    }

    private func animation(for notification: Notification) -> Animation {
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        return .easeOut(duration: duration)
    }
}

extension View {
    func keyboardDismissToolbar() -> some View {
        modifier(KeyboardDismissToolbarModifier())
    }
}
