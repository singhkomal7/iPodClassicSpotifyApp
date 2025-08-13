import UIKit
import MediaPlayer
import AVFoundation

class VolumeController: ObservableObject {
    @Published var currentVolume: Float = 0.5
    private var volumeView: MPVolumeView?
    private var volumeSlider: UISlider?
    
    init() {
        setupVolumeControl()
        setupAudioSession()
        getCurrentSystemVolume()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
            print("✅ Audio session configured for volume control")
        } catch {
            print("❌ Failed to configure audio session: \(error)")
        }
    }
    
    private func setupVolumeControl() {
        DispatchQueue.main.async {
            // Create volume view
            self.volumeView = MPVolumeView(frame: CGRect(x: -1000, y: -1000, width: 100, height: 100))
            self.volumeView?.showsVolumeSlider = true
            self.volumeView?.showsRouteButton = false
            
            // Add to a window to make it functional
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.addSubview(self.volumeView!)
                
                // Find the slider after a small delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.findVolumeSlider()
                }
            }
        }
    }
    
    private func findVolumeSlider() {
        guard let volumeView = volumeView else { return }
        
        for subview in volumeView.subviews {
            if let slider = subview as? UISlider {
                self.volumeSlider = slider
                self.currentVolume = slider.value
                print("✅ Found volume slider, current volume: \(Int(slider.value * 100))%")
                break
            }
        }
        
        if volumeSlider == nil {
            print("❌ Could not find volume slider")
        }
    }
    
    func increaseVolume(by increment: Float = 0.1) {
        guard let slider = volumeSlider else {
            print("❌ Volume slider not available")
            setupVolumeControl() // Try to set up again
            return
        }
        
        let newVolume = min(1.0, slider.value + increment)
        setVolume(newVolume)
    }
    
    func decreaseVolume(by decrement: Float = 0.1) {
        guard let slider = volumeSlider else {
            print("❌ Volume slider not available")
            setupVolumeControl() // Try to set up again
            return
        }
        
        let newVolume = max(0.0, slider.value - decrement)
        setVolume(newVolume)
    }
    
    private func setVolume(_ volume: Float) {
        guard let slider = volumeSlider else { return }
        
        let clampedVolume = max(0.0, min(1.0, volume))
        
        DispatchQueue.main.async {
            slider.setValue(clampedVolume, animated: false)
            slider.sendActions(for: .valueChanged)
            
            self.currentVolume = clampedVolume
            print("🔊 Volume set to \(Int(clampedVolume * 100))%")
        }
    }
    
    private func getCurrentSystemVolume() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let slider = self.volumeSlider {
                self.currentVolume = slider.value
                print("📊 Current system volume: \(Int(slider.value * 100))%")
            }
        }
    }
    
    deinit {
        volumeView?.removeFromSuperview()
    }
}
