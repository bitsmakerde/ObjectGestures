//
//  PlaneHitResult.swift
//  ObjectGestures
//
//  Result of a downward raycast against detected planes

import Foundation
import simd

/// Result of a raycast hitting a detected plane
public struct PlaneHitResult: Sendable {
    /// World-space position of the hit point
    public let position: SIMD3<Float>
    /// Distance from the ray origin to the hit point
    public let distance: Float
    /// Name of the hit entity (for debugging)
    public let entityName: String

    public init(position: SIMD3<Float>, distance: Float, entityName: String) {
        self.position = position
        self.distance = distance
        self.entityName = entityName
    }
}
