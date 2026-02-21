import SwiftUI
import WatchKit

enum BreathPhase: String {
    case idle = "Rest here."
    case inhale = "Breathe in."
    case topUp = "Top up."
    case exhale = "Breathe out."
}

struct ContentView: View {
    @State private var phase: BreathPhase = .idle
    @State private var scale: CGFloat = 0.5
    @State private var timer: Timer?
    @State private var isActive: Bool = false
    
    let fluidColor = Color(red: 251/255, green: 211/255, blue: 141/255).opacity(0.8) // AppColors.fluidAnxious
    let background = Color.black
    
    var body: some View {
        ZStack {
            background.ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Breathing Shape
                ZStack {
                    Circle()
                        .fill(fluidColor)
                        .blur(radius: 20)
                        .scaleEffect(scale)
                    
                    if isActive {
                        Text(phase.rawValue)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(radius: 2)
                    } else {
                        VStack(spacing: 8) {
                            Text("Made by Anxiety")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .tracking(2)
                                .foregroundColor(Color(red: 251/255, green: 211/255, blue: 141/255))
                            
                            Text("tap to anchor")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(width: 150, height: 150)
                .onTapGesture {
                    if !isActive {
                        startBreathingSession()
                    } else {
                        stopBreathingSession()
                    }
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Tactical Breathing Logic (4-1.5-6)
    func startBreathingSession() {
        isActive = true
        runBreathCycle()
    }
    
    func stopBreathingSession() {
        isActive = false
        phase = .idle
        timer?.invalidate()
        withAnimation(.easeInOut(duration: 1.0)) {
            scale = 0.5
        }
    }
    
    func runBreathCycle() {
        guard isActive else { return }
        
        // 1. Inhale (4s)
        phase = .inhale
        WKInterfaceDevice.current().play(.directionUp)
        withAnimation(.easeInOut(duration: 4.0)) {
            scale = 0.95
        }
        
        // Pulse haptics during inhale continuously
        triggerRhythmicHaptics(count: 4, interval: 0.8, type: .click)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            guard self.isActive else { return }
            
            // 2. Top up / Hold (1.5s)
            self.phase = .topUp
            WKInterfaceDevice.current().play(.success)
            withAnimation(.easeOut(duration: 1.5)) {
                self.scale = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                guard self.isActive else { return }
                
                // 3. Exhale (6s)
                self.phase = .exhale
                WKInterfaceDevice.current().play(.directionDown)
                withAnimation(.easeInOut(duration: 6.0)) {
                    self.scale = 0.5
                }
                
                // Pulse haptics dragging out during exhale
                self.triggerRhythmicHaptics(count: 6, interval: 0.9, type: .directionDown)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                    guard self.isActive else { return }
                    // Loop
                    self.runBreathCycle()
                }
            }
        }
    }
    
    // Emulates the vibration pattern we did in Flutter for WearOS
    func triggerRhythmicHaptics(count: Int, interval: TimeInterval, type: WKHapticType) {
        for i in 0..<count {
            DispatchQueue.main.asyncAfter(deadline: .now() + (interval * Double(i))) {
                if self.isActive {
                    WKInterfaceDevice.current().play(type)
                }
            }
        }
    }
}
