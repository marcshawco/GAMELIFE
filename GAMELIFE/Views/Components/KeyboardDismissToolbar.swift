//
//  KeyboardDismissToolbar.swift
//  GAMELIFE
//
//  Consistent keyboard dismissal affordance for input-heavy flows.
//

import SwiftUI
import UIKit

extension View {
    /// Adds a system keyboard accessory bar with a trailing "Done" button that
    /// dismisses the keyboard. Input-heavy sheets (quest / boss builders) call
    /// this so the keyboard never traps the user mid-form.
    ///
    /// Uses SwiftUI's `.keyboard` toolbar placement (the OS-managed input
    /// accessory) rather than a custom `inputAccessoryView`, which previously
    /// caused layout-constraint churn.
    func keyboardDismissToolbar() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(action: dismissKeyboard) {
                    HStack(spacing: 6) {
                        Text("Done")
                        Image(systemName: "keyboard.chevron.compact.down")
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

/// Resigns the first responder app-wide, closing whatever keyboard is showing.
func dismissKeyboard() {
    UIApplication.shared.sendAction(
        #selector(UIResponder.resignFirstResponder),
        to: nil,
        from: nil,
        for: nil
    )
}
