//
//  KeyboardDismissToolbar.swift
//  GAMELIFE
//
//  Consistent keyboard dismissal affordance for input-heavy flows.
//

import SwiftUI

extension View {
    func keyboardDismissToolbar() -> some View {
        // Keep the call sites stable while avoiding custom keyboard accessory
        // layout. UIKit/SwiftUI already provide return-key and tap-away
        // dismissal, and extra keyboard insets were triggering simulator
        // accessory/input-view constraint churn.
        self
    }
}
