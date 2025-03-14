//
//  ButtonStyles.swift
//  Lullz
//
//  Created by Adam Scott
//

import SwiftUI

/// A custom button style that scales the button down when pressed
struct LullzScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

/// A button style with a circular background and pulsing effect
struct CircularButtonStyle: ButtonStyle {
    var backgroundColor: Color = .white.opacity(0.2)
    var foregroundColor: Color = .white
    var size: CGFloat = 80
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: size, height: size)
                .scaleEffect(configuration.isPressed ? 0.95 : 1)
            
            configuration.label
                .font(.system(size: size * 0.45))
                .foregroundColor(foregroundColor)
        }
        .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

/// A pill-shaped button style with background
struct PillButtonStyle: ButtonStyle {
    var backgroundColor: Color = .white.opacity(0.15)
    var foregroundColor: Color = .white
    var isActive: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isActive ? .orange : foregroundColor)
            .padding()
            .frame(maxWidth: .infinity)
            .background(isActive ? backgroundColor.opacity(1.2) : backgroundColor)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

/// A preset card button style
struct PresetCardButtonStyle: ButtonStyle {
    var isSelected: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.white.opacity(0.3) : Color.white.opacity(0.15))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
} 