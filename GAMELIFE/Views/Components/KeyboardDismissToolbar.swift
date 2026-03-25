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
                ToolbarItem(placement: .keyboard) {
                    Button {
                        HapticManager.shared.selection()
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil,
                            from: nil,
                            for: nil
                        )
                    } label: {
                        Text("Done")
                            .font(.system(size: 17, weight: .semibold))
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
