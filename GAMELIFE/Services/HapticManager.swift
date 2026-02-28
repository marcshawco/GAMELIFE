//
//  HapticManager.swift
//  GAMELIFE
//
//  [SYSTEM]: Tactile feedback module initialized.
//  Physical confirmation enabled.
//

import Foundation
import UIKit

@MainActor
final class HapticManager {

    static let shared = HapticManager()

    private init() {}

    private enum ImpactPreset {
        case micro
        case soft
        case medium
        case solid
        case heavy
        case rigidHeavy

        var style: UIImpactFeedbackGenerator.FeedbackStyle {
            switch self {
            case .micro, .soft: return .soft
            case .medium: return .medium
            case .solid: return .light
            case .heavy: return .heavy
            case .rigidHeavy: return .rigid
            }
        }

        var intensity: CGFloat {
            switch self {
            case .micro: return 0.35
            case .soft: return 0.55
            case .medium: return 0.75
            case .solid: return 0.9
            case .heavy: return 1.0
            case .rigidHeavy: return 1.0
            }
        }
    }

    private var isEnabled: Bool {
        SettingsManager.shared.hapticEnabled && UIApplication.shared.applicationState == .active
    }

    func selection() {
        guard isEnabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light, intensity: CGFloat = 1.0) {
        guard isEnabled else { return }
        let clampedIntensity = max(0, min(1, intensity))
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred(intensity: clampedIntensity)
    }

    private func playImpact(_ preset: ImpactPreset) {
        impact(preset.style, intensity: preset.intensity)
    }

    private func pulse(_ first: ImpactPreset, then second: ImpactPreset, delay: TimeInterval = 0.08) {
        playImpact(first)
        guard isEnabled else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.playImpact(second)
        }
    }

    func success() {
        notification(.success)
        playImpact(.soft)
    }

    func warning() {
        notification(.warning)
        playImpact(.medium)
    }

    func error() {
        notification(.error)
        playImpact(.heavy)
    }

    func questCompleted(isCritical: Bool) {
        if isCritical {
            success()
            pulse(.rigidHeavy, then: .heavy, delay: 0.1)
        } else {
            playImpact(.solid)
        }
    }

    func questUndoApplied() {
        playImpact(.micro)
    }

    func levelUp() {
        success()
        pulse(.rigidHeavy, then: .medium, delay: 0.12)
    }

    func bossDefeated() {
        success()
        pulse(.heavy, then: .rigidHeavy, delay: 0.1)
    }

    func bossHit(isCritical: Bool) {
        if isCritical {
            pulse(.solid, then: .heavy, delay: 0.08)
        } else {
            playImpact(.medium)
        }
    }

    func purchaseSucceeded() {
        playImpact(.medium)
    }

    func purchaseFailed() {
        warning()
    }

    func rewardRedeemed() {
        playImpact(.soft)
    }

    func trainingStarted() {
        playImpact(.medium)
    }

    func trainingCompleted() {
        success()
        pulse(.heavy, then: .solid, delay: 0.09)
    }

    func trainingFailed() {
        pulse(.medium, then: .heavy, delay: 0.08)
    }

    func deathPenaltyApplied() {
        error()
        pulse(.heavy, then: .rigidHeavy, delay: 0.1)
    }

    private func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}
