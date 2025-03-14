//
//  FloatingVolumeControlModifier.swift
//  Lullz
//
//  Created by Adam Scott on 3/12/25.
//

import SwiftUI

/// A view modifier that adds a draggable floating volume control to any view
/// This modifier requires an AudioManagerImpl in the environment
public struct FloatingVolumeControlModifier: ViewModifier {
    // MARK: - Properties
    
    @EnvironmentObject private var audioManager: AudioManagerImpl
    
    @State private var dragPosition: CGPoint
    @GestureState private var isDragging = false
    
    // MARK: - Constants
    
    private enum Constants {
        static let edgeInset: CGFloat = 35
        static let topPadding: CGFloat = 50
        static let bottomPadding: CGFloat = 70
        static let sidePadding: CGFloat = 25
        static let defaultY: CGFloat = UIScreen.main.bounds.height - 120
        static let defaultX: CGFloat = UIScreen.main.bounds.width - edgeInset
    }
    
    // MARK: - Initialization
    
    public init() {
        // Initialize with default position at bottom right
        _dragPosition = State(initialValue: CGPoint(
            x: Constants.defaultX,
            y: Constants.defaultY
        ))
    }
    
    // MARK: - Body
    
    public func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    FloatingVolumeControl(audioManager: audioManager)
                        .position(dragPosition)
                        .gesture(createDragGesture(in: geo))
                }
            )
            .onAppear(perform: setupInitialPosition)
    }
    
    // MARK: - Private Methods
    
    private func createDragGesture(in geometry: GeometryProxy) -> some Gesture {
        DragGesture()
            .updating($isDragging) { _, state, _ in
                state = true
            }
            .onChanged { value in
                updatePosition(with: value.translation, in: geometry)
            }
            .onEnded { value in
                snapToNearestEdge()
            }
    }
    
    private func updatePosition(with translation: CGSize, in geometry: GeometryProxy) {
        var newPosition = CGPoint(
            x: dragPosition.x + translation.width,
            y: dragPosition.y + translation.height
        )
        
        // Calculate safe area bounds
        let safeAreaTop = geometry.safeAreaInsets.top + Constants.topPadding
        let safeAreaBottom = geometry.size.height - geometry.safeAreaInsets.bottom - Constants.bottomPadding
        let safeAreaLeading = geometry.safeAreaInsets.leading + Constants.sidePadding
        let safeAreaTrailing = geometry.size.width - geometry.safeAreaInsets.trailing - Constants.sidePadding
        
        // Constrain position to safe areas
        newPosition.x = max(safeAreaLeading, min(newPosition.x, safeAreaTrailing))
        newPosition.y = max(safeAreaTop, min(newPosition.y, safeAreaBottom))
        
        dragPosition = newPosition
    }
    
    private func snapToNearestEdge() {
        let rightEdge = UIScreen.main.bounds.width - Constants.edgeInset
        let leftEdge = Constants.edgeInset
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            dragPosition.x = dragPosition.x > UIScreen.main.bounds.width / 2 ? rightEdge : leftEdge
        }
    }
    
    private func setupInitialPosition() {
        dragPosition = CGPoint(
            x: Constants.defaultX,
            y: Constants.defaultY
        )
    }
}

// MARK: - View Extension

public extension View {
    /// Adds a floating volume control to the view
    /// - Returns: A view with a floating volume control overlay
    func withFloatingVolumeControl() -> some View {
        modifier(FloatingVolumeControlModifier())
    }
} 