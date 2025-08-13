import SwiftUI
import UIKit

struct ClickWheelView: View {
    @State private var rotationAngle: Double = 0
    @State private var lastAngle: Double = 0
    @State private var isDragging = false
    @State private var menuButtonPressed = false
    @State private var playPauseButtonPressed = false
    @State private var previousButtonPressed = false
    @State private var nextButtonPressed = false
    @State private var centerButtonPressed = false
    @State private var accumulatedRotation: Double = 0
    
    // Callbacks for different actions
    let onMenuPress: () -> Void
    let onPlayPausePress: () -> Void
    let onPreviousPress: () -> Void
    let onNextPress: () -> Void
    let onCenterPress: () -> Void
    let onScrollUp: () -> Void
    let onScrollDown: () -> Void
    let onScrollLeft: () -> Void
    let onScrollRight: () -> Void
    let onVolumeUp: () -> Void
    let onVolumeDown: () -> Void
    
    // Visual constants
    private let wheelSize: CGFloat = 280
    private let centerButtonSize: CGFloat = 120
    private let touchAreaWidth: CGFloat = 80
    
    var body: some View {
        ZStack {
            // Outer ring (click wheel)
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.gray.opacity(0.3),
                            Color.gray.opacity(0.1),
                            Color.white.opacity(0.8),
                            Color.gray.opacity(0.2)
                        ]),
                        center: .center,
                        startRadius: centerButtonSize/2,
                        endRadius: wheelSize/2
                    )
                )
                .frame(width: wheelSize, height: wheelSize)
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                )
            
            // Touch-sensitive ring area
            Circle()
                .fill(Color.clear)
                .frame(width: wheelSize, height: wheelSize)
                .contentShape(Circle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let center = CGPoint(x: wheelSize/2, y: wheelSize/2)
                            let vector = CGPoint(
                                x: value.location.x - center.x,
                                y: value.location.y - center.y
                            )
                            
                            let distance = sqrt(vector.x * vector.x + vector.y * vector.y)
                            let minRadius = centerButtonSize/2 + 10
                            let maxRadius = wheelSize/2 - 10
                            
                            // Only respond to touches in the ring area
                            if distance > minRadius && distance < maxRadius {
                                if !isDragging {
                                    isDragging = true
                                    lastAngle = atan2(vector.y, vector.x)
                                }
                                
                                let currentAngle = atan2(vector.y, vector.x)
                                var angleDiff = currentAngle - lastAngle
                                
                                // Handle angle wrap-around
                                if angleDiff > .pi {
                                    angleDiff -= 2 * .pi
                                } else if angleDiff < -.pi {
                                    angleDiff += 2 * .pi
                                }
                                
                                // Accumulate rotation for volume control
                                accumulatedRotation += angleDiff
                                
                                // Volume control based on accumulated rotation
                                let volumeThreshold: Double = 0.3
                                if abs(accumulatedRotation) > volumeThreshold {
                                    if accumulatedRotation > 0 {
                                        print("🔊⟳ Clockwise swipe - Volume UP")
                                        HapticManager.shared.lightFeedback()
                                        onVolumeUp()
                                    } else {
                                        print("🔊⟲ Counter-clockwise swipe - Volume DOWN")
                                        HapticManager.shared.lightFeedback()
                                        onVolumeDown()
                                    }
                                    accumulatedRotation = 0 // Reset after volume change
                                }
                                
                                // Navigation control (for list scrolling)
                                if abs(angleDiff) > 0.15 {
                                    if angleDiff > 0 {
                                        onScrollDown()
                                    } else {
                                        onScrollUp()
                                    }
                                    lastAngle = currentAngle
                                }
                            }
                        }
                        .onEnded { _ in
                            isDragging = false
                            accumulatedRotation = 0 // Reset accumulated rotation
                        }
                )
            
            // Control buttons positioned around the wheel
            ZStack {
                // Menu button (top)
                Button(action: {
                    menuButtonPressed = true
                    HapticManager.shared.mediumFeedback()
                    onMenuPress()
                    
                    // Reset the pressed state after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        menuButtonPressed = false
                    }
                }) {
                    Text("MENU")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(menuButtonPressed ? .white : .black)
                        .opacity(menuButtonPressed ? 1.0 : 0.7)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(menuButtonPressed ? Color.blue.opacity(0.8) : Color.clear)
                        )
                }
                .position(x: wheelSize/2, y: 40)
                
                // Play/Pause button (bottom)
                Button(action: {
                    playPauseButtonPressed = true
                    HapticManager.shared.mediumFeedback()
                    onPlayPausePress()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        playPauseButtonPressed = false
                    }
                }) {
                    Image(systemName: "playpause.fill")
                        .font(.system(size: 14))
                        .foregroundColor(playPauseButtonPressed ? .white : .black)
                        .opacity(playPauseButtonPressed ? 1.0 : 0.7)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(playPauseButtonPressed ? Color.blue.opacity(0.8) : Color.clear)
                        )
                }
                .position(x: wheelSize/2, y: wheelSize - 40)
                
                // Previous button (left)
                Button(action: {
                    previousButtonPressed = true
                    HapticManager.shared.mediumFeedback()
                    onPreviousPress()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        previousButtonPressed = false
                    }
                }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 14))
                        .foregroundColor(previousButtonPressed ? .white : .black)
                        .opacity(previousButtonPressed ? 1.0 : 0.7)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(previousButtonPressed ? Color.blue.opacity(0.8) : Color.clear)
                        )
                }
                .position(x: 40, y: wheelSize/2)
                
                // Next button (right)  
                Button(action: {
                    nextButtonPressed = true
                    HapticManager.shared.mediumFeedback()
                    onNextPress()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        nextButtonPressed = false
                    }
                }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 14))
                        .foregroundColor(nextButtonPressed ? .white : .black)
                        .opacity(nextButtonPressed ? 1.0 : 0.7)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(nextButtonPressed ? Color.blue.opacity(0.8) : Color.clear)
                        )
                }
                .position(x: wheelSize - 40, y: wheelSize/2)
            }
            
            // Center button
            Button(action: {
                centerButtonPressed = true
                HapticManager.shared.heavyFeedback()
                onCenterPress()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    centerButtonPressed = false
                }
            }) {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                centerButtonPressed ? Color.blue.opacity(0.3) : Color.white,
                                centerButtonPressed ? Color.blue.opacity(0.5) : Color.gray.opacity(0.3),
                                centerButtonPressed ? Color.blue.opacity(0.8) : Color.gray.opacity(0.6)
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: centerButtonSize/2
                        )
                    )
                    .frame(width: centerButtonSize, height: centerButtonSize)
                    .overlay(
                        Circle()
                            .stroke(centerButtonPressed ? Color.blue.opacity(0.8) : Color.gray.opacity(0.4), lineWidth: 1)
                    )
                    .scaleEffect(isDragging || centerButtonPressed ? 0.98 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: isDragging)
                    .animation(.easeInOut(duration: 0.1), value: centerButtonPressed)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(width: wheelSize, height: wheelSize)
    }
}

// Preview
struct ClickWheelView_Previews: PreviewProvider {
    static var previews: some View {
        ClickWheelView(
            onMenuPress: { print("Menu pressed") },
            onPlayPausePress: { print("Play/Pause pressed") },
            onPreviousPress: { print("Previous pressed") },
            onNextPress: { print("Next pressed") },
            onCenterPress: { print("Center pressed") },
            onScrollUp: { print("Scroll up") },
            onScrollDown: { print("Scroll down") },
            onScrollLeft: { print("Scroll left") },
            onScrollRight: { print("Scroll right") },
            onVolumeUp: { print("Volume up") },
            onVolumeDown: { print("Volume down") }
        )
        .padding()
        .background(Color.black)
        .previewLayout(.sizeThatFits)
    }
}
