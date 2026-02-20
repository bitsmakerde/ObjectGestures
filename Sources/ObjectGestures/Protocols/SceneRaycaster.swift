//
//  SceneRaycaster.swift
//  ObjectGestures
//
//  Protocol for scene raycasting abstraction

import Foundation
import simd

/// Abstracts scene raycasting for testability.
/// The default implementation uses RealityKit's scene.raycast().
@MainActor
public protocol SceneRaycaster: Sendable {
    /// Cast a ray downward from the given origin and return the nearest plane hit.
    func raycastDown(
        from origin: SIMD3<Float>,
        maxDistance: Float,
        planeEntityIDs: Set<ObjectIdentifier>
    ) -> PlaneHitResult?
}
