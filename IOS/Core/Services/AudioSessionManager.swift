import Foundation
import AVFoundation
import Combine

class AudioSessionManager: ObservableObject {
    @Published var isAudioSessionActive = false
    @Published var currentRoute: AVAudioSession.RouteDescription?
    @Published var isHeadphonesConnected = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupNotifications()
        checkInitialAudioRoute()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP])
            try audioSession.setActive(true)
            
            isAudioSessionActive = true
            print("Audio session configured successfully")
            
        } catch {
            print("Failed to configure audio session: \(error.localizedDescription)")
            isAudioSessionActive = false
        }
    }
    
    func deactivateAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            isAudioSessionActive = false
            print("Audio session deactivated")
        } catch {
            print("Failed to deactivate audio session: \(error.localizedDescription)")
        }
    }
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioSessionRouteChanged),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioSessionInterrupted),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }
    
    private func checkInitialAudioRoute() {
        updateCurrentRoute()
        checkHeadphonesConnection()
    }
    
    private func updateCurrentRoute() {
        currentRoute = AVAudioSession.sharedInstance().currentRoute
    }
    
    private func checkHeadphonesConnection() {
        let audioSession = AVAudioSession.sharedInstance()
        let currentRoute = audioSession.currentRoute
        
        for output in currentRoute.outputs {
            switch output.portType {
            case .headphones, .bluetoothA2DP, .bluetoothLE, .bluetoothHFP:
                isHeadphonesConnected = true
                return
            default:
                continue
            }
        }
        
        isHeadphonesConnected = false
    }
    
    @objc private func audioSessionRouteChanged(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        updateCurrentRoute()
        checkHeadphonesConnection()
        
        switch reason {
        case .newDeviceAvailable:
            print("New audio device available")
            handleNewDeviceAvailable()
            
        case .oldDeviceUnavailable:
            print("Audio device disconnected")
            handleDeviceDisconnected()
            
        case .categoryChange:
            print("Audio session category changed")
            
        case .override:
            print("Audio route override")
            
        case .wakeFromSleep:
            print("Audio session wake from sleep")
            
        case .noSuitableRouteForCategory:
            print("No suitable route for category")
            
        case .routeConfigurationChange:
            print("Route configuration changed")
            
        @unknown default:
            print("Unknown route change reason")
        }
    }
    
    @objc private func audioSessionInterrupted(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            print("Audio session interruption began")
            handleInterruptionBegan()
            
        case .ended:
            print("Audio session interruption ended")
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                handleInterruptionEnded(options: options)
            }
            
        @unknown default:
            break
        }
    }
    private func handleNewDeviceAvailable() {
        print("Audio device connected")
    }
    
    private func handleDeviceDisconnected() {
        if !isHeadphonesConnected {
            print("Headphones disconnected - pausing playback")
            NotificationCenter.default.post(name: .headphonesDisconnected, object: nil)
        }
    }
    
    private func handleInterruptionBegan() {
        print("Audio interrupted - pausing playback")
        NotificationCenter.default.post(name: .audioInterrupted, object: nil)
    }
    
    private func handleInterruptionEnded(options: AVAudioSession.InterruptionOptions) {
        if options.contains(.shouldResume) {
            print("Audio interruption ended - resuming playback")
            NotificationCenter.default.post(name: .audioInterruptionEnded, object: nil)
        } else {
            print("Audio interruption ended - playback should not resume")
        }
    }
    var currentOutputPortType: AVAudioSession.Port.PortType? {
        return currentRoute?.outputs.first?.portType
    }
    
    var currentOutputPortName: String? {
        return currentRoute?.outputs.first?.portName
    }
    
    var isUsingBuiltInSpeaker: Bool {
        return currentOutputPortType == .builtInSpeaker
    }
    
    var isUsingWiredHeadphones: Bool {
        return currentOutputPortType == .headphones
    }
    
    var isUsingBluetoothAudio: Bool {
        guard let portType = currentOutputPortType else { return false }
        return portType == .bluetoothA2DP || portType == .bluetoothLE || portType == .bluetoothHFP
    }
    func setPreferredInputGain(_ gain: Float) {
        let audioSession = AVAudioSession.sharedInstance()
        
        if audioSession.isInputGainSettable {
            do {
                try audioSession.setInputGain(gain)
                print("Input gain set to: \(gain)")
            } catch {
                print("Failed to set input gain: \(error.localizedDescription)")
            }
        }
    }
    var currentSampleRate: Double {
        return AVAudioSession.sharedInstance().sampleRate
    }
    
    var currentIOBufferDuration: TimeInterval {
        return AVAudioSession.sharedInstance().ioBufferDuration
    }
    
    var currentInputNumberOfChannels: Int {
        return AVAudioSession.sharedInstance().inputNumberOfChannels
    }
    
    var currentOutputNumberOfChannels: Int {
        return AVAudioSession.sharedInstance().outputNumberOfChannels
    }
}
extension Notification.Name {
    static let headphonesDisconnected = Notification.Name("headphonesDisconnected")
    static let audioInterrupted = Notification.Name("audioInterrupted")
    static let audioInterruptionEnded = Notification.Name("audioInterruptionEnded")
}
