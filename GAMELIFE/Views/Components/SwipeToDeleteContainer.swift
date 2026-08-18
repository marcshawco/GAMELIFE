//
//  SwipeToDeleteContainer.swift
//  GAMELIFE
//
//  [SYSTEM]: Reusable swipe-to-reveal delete affordance.
//

import SwiftUI

/// A reusable swipe-to-delete wrapper for rows rendered inside a `ScrollView` /
/// `LazyVStack`, where SwiftUI's List-only `.swipeActions` is unavailable.
///
/// Dragging the row left reveals a red **Delete** action. Tapping it calls
/// `onDelete` — callers are expected to present a confirmation before actually
/// removing anything. Tapping an open row (anywhere but the button) closes it.
struct SwipeToDeleteContainer<Content: View>: View {
    var cornerRadius: CGFloat = SystemRadius.medium
    let onDelete: () -> Void
    @ViewBuilder var content: Content

    @State private var offsetX: CGFloat = 0
    @State private var restOffset: CGFloat = 0
    @State private var axisLocked: Bool?

    private let actionWidth: CGFloat = 92
    private var openOffset: CGFloat { -actionWidth }
    private let triggerThreshold: CGFloat = 55

    var body: some View {
        ZStack(alignment: .trailing) {
            deleteAction
                .opacity(offsetX < -2 ? 1 : 0)

            content
                .contentShape(Rectangle())
                .offset(x: offsetX)
                .overlay {
                    // When open, an invisible layer catches a tap to close the
                    // row without swallowing the row's own controls while closed.
                    if offsetX != 0 {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture { close() }
                    }
                }
                .simultaneousGesture(dragGesture)
        }
    }

    private var deleteAction: some View {
        Button {
            HapticManager.shared.impact(.medium)
            close()
            onDelete()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 18, weight: .semibold))
                Text("Delete")
                    .font(SystemTypography.mono(11, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(width: actionWidth)
            .frame(maxHeight: .infinity)
            .background(SystemTheme.criticalRed)
        }
        .buttonStyle(.plain)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                if axisLocked == nil {
                    axisLocked = abs(value.translation.width) > abs(value.translation.height)
                }
                guard axisLocked == true else { return }
                let proposed = restOffset + value.translation.width
                offsetX = min(0, max(openOffset, proposed))
            }
            .onEnded { _ in
                defer { axisLocked = nil }
                guard axisLocked == true else { return }
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    if offsetX < -triggerThreshold {
                        offsetX = openOffset
                        restOffset = openOffset
                    } else {
                        offsetX = 0
                        restOffset = 0
                    }
                }
            }
    }

    private func close() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            offsetX = 0
            restOffset = 0
        }
    }
}
