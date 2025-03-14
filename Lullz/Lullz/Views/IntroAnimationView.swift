import SwiftUI

struct IntroAnimationView: View {
    @State private var appear = false
    @State private var logoScale: CGFloat = 0.9
    @State private var lineOffset1: CGFloat = -100
    @State private var lineOffset2: CGFloat = 100
    @State private var wavePhase: CGFloat = 0
    
    // Monochrome color scheme
    private let primaryColor = Color.black
    private let accentColor = Color.gray.opacity(0.7)
    private let backgroundColor = Color.white
    
    // App name settings
    private let appName = "LULLZ"
    private let tagline = "SOUND · FOCUS · BREATHE"
    
    var body: some View {
        ZStack {
            // Clean white background
            backgroundColor.ignoresSafeArea()
            
            // Edge lines - adds edgy design elements
            VStack(spacing: 0) {
                Rectangle()
                    .fill(primaryColor)
                    .frame(width: UIScreen.main.bounds.width, height: 2)
                    .offset(x: appear ? 0 : lineOffset1)
                
                Spacer()
                
                Rectangle()
                    .fill(primaryColor)
                    .frame(width: UIScreen.main.bounds.width, height: 2)
                    .offset(x: appear ? 0 : lineOffset2)
            }
            .ignoresSafeArea()
            
            // Main content
            VStack(spacing: 20) {
                Spacer()
                
                // Animated sound wave logo
                ZStack {
                    // Minimalist sound wave visualization
                    IntroSoundWaveView(phase: wavePhase)
                        .frame(width: 160, height: 80)
                        .foregroundColor(primaryColor)
                }
                .scaleEffect(logoScale)
                .padding(.bottom, 20)
                
                // App name in edgy uppercase style
                Text(appName)
                    .font(.system(size: 50, weight: .black, design: .default))
                    .kerning(5)
                    .foregroundColor(primaryColor)
                    .opacity(appear ? 1 : 0)
                
                // Minimal tagline with dot separators for modern look
                Text(tagline)
                    .font(.system(size: 12, weight: .medium, design: .default))
                    .kerning(2)
                    .foregroundColor(accentColor)
                    .opacity(appear ? 0.8 : 0)
                
                Spacer()
                
                // Edgy design element at bottom
                HStack(spacing: 4) {
                    ForEach(0..<5) { i in
                        Rectangle()
                            .fill(primaryColor)
                            .frame(width: 15, height: appear ? 15 + CGFloat(i * 8) : 2)
                            .animation(
                                Animation.easeInOut(duration: 0.4)
                                    .delay(Double(i) * 0.05),
                                value: appear
                            )
                    }
                }
                .padding(.bottom, 40)
            }
            .padding()
        }
        .onAppear {
            // Staggered animations for edgy effect
            withAnimation(.easeOut(duration: 0.7)) {
                appear = true
                lineOffset1 = 0
                lineOffset2 = 0
            }
            
            // Subtle logo scale animation
            withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                logoScale = 1.0
            }
            
            // Continuous sound wave animation
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                wavePhase = .pi * 2
            }
        }
    }
}

// Modern, minimal sound wave visualization - renamed to avoid conflict
struct IntroSoundWaveView: View {
    var phase: CGFloat
    
    var body: some View {
        Canvas { context, size in
            // Draw a series of vertical bars of varying heights
            let barWidth: CGFloat = 4
            let spacing: CGFloat = 4
            let numberOfBars = Int(size.width / (barWidth + spacing))
            let centerY = size.height / 2
            
            for i in 0..<numberOfBars {
                let x = CGFloat(i) * (barWidth + spacing)
                
                // Calculate dynamic height for each bar
                let progress = CGFloat(i) / CGFloat(numberOfBars)
                let angle = progress * .pi * 4 + phase
                let multiplier = (sin(angle) + 1) / 2 // Range 0 to 1
                
                // Center bars have more height variation
                let heightFactor = 1 - abs(progress - 0.5) * 1.5
                let height = size.height * 0.5 * multiplier * heightFactor + 5
                
                let bar = Path(roundedRect: CGRect(
                    x: x,
                    y: centerY - height/2,
                    width: barWidth,
                    height: height
                ), cornerRadius: 1)
                
                context.fill(bar, with: .color(Color.black))
            }
        }
    }
}

// Preview
struct IntroAnimationView_Previews: PreviewProvider {
    static var previews: some View {
        IntroAnimationView()
    }
} 