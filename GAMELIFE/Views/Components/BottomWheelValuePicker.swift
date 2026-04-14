//
//  BottomWheelValuePicker.swift
//  GAMELIFE
//
//  [SYSTEM]: Precision input interface online.
//

import SwiftUI

struct WheelValueOption: Identifiable, Hashable {
    let id: String
    let value: Double
    let label: String

    init(value: Double, label: String) {
        self.value = value
        self.label = label
        self.id = "\(label)|\(value)"
    }
}

struct BottomWheelValuePickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let subtitle: String?
    let accentColor: Color
    let options: [WheelValueOption]
    @Binding var selection: Double
    var confirmTitle: String = "Confirm"

    @State private var draftValue: Double = 0

    var body: some View {
        ZStack {
            SystemTheme.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 22)
                    .padding(.top, 12)
                    .padding(.bottom, 10)

                pickerBar
            }
            .padding(.bottom, 8)
        }
        .presentationDetents([.fraction(0.5)])
        .presentationDragIndicator(.visible)
        .onAppear {
            draftValue = nearestValue(to: selection)
        }
        .onChange(of: draftValue) { _, _ in
            HapticManager.shared.selection()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(SystemTypography.titleSmall)
                .foregroundStyle(SystemTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .allowsTightening(true)

            Rectangle()
                .fill(accentColor)
                .frame(width: 42, height: 4)
                .clipShape(Capsule())

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(SystemTypography.caption)
                    .foregroundStyle(SystemTheme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
                    .allowsTightening(true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var pickerBar: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3)
                .fill(SystemTheme.textTertiary.opacity(0.45))
                .frame(width: 54, height: 5)
                .padding(.top, 2)
                .padding(.bottom, 12)

            HStack {
                Button {
                    HapticManager.shared.selection()
                    dismiss()
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(accentColor)
                        .frame(width: 44, height: 44)
                }

                Spacer()

                Text(confirmTitle)
                    .font(SystemTypography.body)
                    .foregroundStyle(SystemTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .allowsTightening(true)

                Spacer()

                Button {
                    selection = draftValue
                    HapticManager.shared.success()
                    dismiss()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(accentColor)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)
            .padding(.bottom, 6)

            Picker(title, selection: $draftValue) {
                ForEach(options) { option in
                    Text(option.label)
                        .tag(option.value)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 196)
            .clipped()
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(SystemTheme.backgroundElevated)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func nearestValue(to value: Double) -> Double {
        guard let nearest = options.min(by: { abs($0.value - value) < abs($1.value - value) }) else {
            return value
        }
        return nearest.value
    }
}
