//
//  Entity+GestureInput.swift
//  ObjectGestures
//
//  Extension to enable gesture input on RealityKit entities

import RealityKit

extension Entity {
    /// Enable gesture input on this entity (replaces makeTappable).
    /// Sets up InputTargetComponent and generates collision shapes.
    @available(macOS 15.0, iOS 18.0, visionOS 2.0, *)
    public func enableGestureInput(allowedInputTypes: InputTargetComponent.InputType = .indirect) {
        let bounds = self.visualBounds(relativeTo: nil)
        let size = SIMD3<Float>(bounds.extents.x, bounds.extents.y, bounds.extents.z)
        let shape = ShapeResource.generateBox(size: size)

        var input = InputTargetComponent()
        input.allowedInputTypes = [allowedInputTypes]
        self.components.set(input)
        self.components.set(CollisionComponent(shapes: [shape]))
    }
}
