//
//  KeyboardDismissToolbar.swift
//  GAMELIFE
//
//  Consistent keyboard dismissal affordance for input-heavy flows.
//

import SwiftUI
import UIKit

private struct KeyboardDismissToolbarModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()

                    Button {
                        HapticManager.shared.selection()
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil,
                            from: nil,
                            for: nil
                        )
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "keyboard.chevron.compact.down")
                                .font(.system(size: 16, weight: .bold))
                            Text("Dismiss Keyboard")
                                .font(SystemTypography.mono(13, weight: .bold))
                        }
                        .foregroundStyle(SystemTheme.backgroundPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(SystemTheme.primaryBlue)
                        .clipShape(Capsule())
                    }
                }
            }
    }
}

extension View {
    func keyboardDismissToolbar() -> some View {
        modifier(KeyboardDismissToolbarModifier())
    }
}
