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

    private var selectedIndex: Int {
        guard let index = options.firstIndex(where: { $0.value == draftValue }) else {
            return max(0, options.firstIndex(where: { $0.value == nearestValue(to: draftValue) }) ?? 0)
        }
        return index
    }

    private var previewOptions: [WheelValueOption] {
        guard !options.isEmpty else { return [] }

        let lowerBound = max(0, selectedIndex - 1)
        let upperBound = min(options.count - 1, selectedIndex + 1)
        let slice = Array(options[lowerBound...upperBound])

        if slice.count == 3 {
            return slice
        }

        if options.count >= 3 {
            if lowerBound == 0 {
                return Array(options.prefix(3))
            }
            return Array(options.suffix(3))
        }

        return options
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 18)

                selectionCard
                    .padding(.horizontal, 14)

                Spacer(minLength: 16)

                pickerBar
            }
            .padding(.bottom, 8)
        }
        .presentationDetents([.fraction(0.58)])
        .presentationDragIndicator(.visible)
        .onAppear {
            draftValue = nearestValue(to: selection)
        }
        .onChange(of: draftValue) { _, _ in
            HapticManager.shared.selection()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(SystemTypography.titleSmall)
                .foregroundStyle(.white)

            Rectangle()
                .fill(accentColor)
                .frame(width: 42, height: 4)
                .clipShape(Capsule())

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(SystemTypography.caption)
                    .foregroundStyle(SystemTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var selectionCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(previewOptions.enumerated()), id: \.element.id) { index, option in
                HStack(spacing: 12) {
                    Text("\(index + 1)")
                        .font(SystemTypography.mono(13, weight: .bold))
                        .foregroundStyle(option.value == draftValue ? Color.black : .white.opacity(0.72))
                        .frame(width: 26, height: 26)
                        .background(option.value == draftValue ? accentColor : Color.white.opacity(0.18))
                        .clipShape(Circle())

                    Text(option.label)
                        .font(SystemTypography.mono(18, weight: option.value == draftValue ? .bold : .medium))
                        .foregroundStyle(option.value == draftValue ? .white : .white.opacity(0.55))

                    Spacer()
                }
                .padding(.horizontal, 14)
                .frame(height: 64)
                .background(cardBackground(for: option.value == draftValue))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func cardBackground(for isSelected: Bool) -> some ShapeStyle {
        if isSelected {
            return AnyShapeStyle(Color.white.opacity(0.10))
        }
        return AnyShapeStyle(Color.white.opacity(0.14))
    }

    private var pickerBar: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(0.35))
                .frame(width: 54, height: 5)
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
                    .foregroundStyle(.white)

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
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 4)

            Picker(title, selection: $draftValue) {
                ForEach(options) { option in
                    Text(option.label)
                        .tag(option.value)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 170)
            .clipped()
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.11, green: 0.11, blue: 0.12))
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
