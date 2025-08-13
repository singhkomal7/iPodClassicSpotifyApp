//
//  HapticManager.swift
//  iPodClassic
//
//  Created by Assistant on 7/3/25.
//

import UIKit

class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    // Light haptic for scroll wheel navigation
    func lightFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    // Medium haptic for button presses
    func mediumFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    // Heavy haptic for center button press
    func heavyFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    // Success haptic for successful actions
    func successFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    // Warning haptic for invalid actions
    func warningFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    // Error haptic for errors
    func errorFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    // Selection haptic for menu navigation
    func selectionFeedback() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
