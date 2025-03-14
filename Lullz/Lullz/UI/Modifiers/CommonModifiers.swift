//
//  CommonModifiers.swift
//  Lullz
//
//  Created by Adam Scott
//

import SwiftUI

/// A view modifier that applies the standard app background gradient
struct AppBackgroundModifier: ViewModifier {
    var colorScheme: ColorScheme
    var topColor: Color = Color(red: 0.1, green: 0.1, blue: 0.2)
    var bottomColor: Color = Color(red: 0.05, green: 0.05, blue: 0.1)
    
    func body(content: Content) -> some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    colorScheme == .dark ? topColor : .white,
                    colorScheme == .dark ? bottomColor : Color(white: 0.95)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            content
        }
    }
}

/// A view modifier that applies standard section styling
struct SectionContainerModifier: ViewModifier {
    var colorScheme: ColorScheme
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(colorScheme == .dark ? 
                          Color.white.opacity(0.1) : 
                          Color.black.opacity(0.05))
            )
            .padding(.horizontal)
    }
}

/// A view modifier that applies standard slider styling
struct AppSliderModifier: ViewModifier {
    var colorScheme: ColorScheme
    
    func body(content: Content) -> some View {
        content
            .accentColor(colorScheme == .dark ? .white : .blue)
            .padding(.horizontal, 10)
    }
}

/// A view modifier that applies pulsing animation to a view
struct PulsingModifier: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1)
            .opacity(isPulsing ? 1 : 0.9)
            .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear {
                isPulsing = true
            }
    }
}

// Extension on View to make modifiers easier to use
extension View {
    /// Applies the standard app background
    func withAppBackground(colorScheme: ColorScheme) -> some View {
        self.modifier(AppBackgroundModifier(colorScheme: colorScheme))
    }
    
    /// Wraps the view in a styled container section
    func inSection(colorScheme: ColorScheme) -> some View {
        self.modifier(SectionContainerModifier(colorScheme: colorScheme))
    }
    
    /// Applies standard slider styling
    func withSliderStyle(colorScheme: ColorScheme) -> some View {
        self.modifier(AppSliderModifier(colorScheme: colorScheme))
    }
    
    /// Applies a pulsing animation to the view
    func pulsing() -> some View {
        self.modifier(PulsingModifier())
    }
} 