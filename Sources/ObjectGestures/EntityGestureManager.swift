//
//  EntityGestureManager.swift
//  ObjectGestures
//
//  Manages drag, rotate, and drop-onto-plane gestures for 3D entities

import Foundation
import RealityKit
import simd

#if os(visionOS)
import SwiftUI
#endif

/// Manages drag, rotate, and drop-onto-plane gestures.
/// Provides both a programmatic API (testable) and visionOS gesture builders.
@Observable
@MainActor
public final class EntityGestureManager {

    // MARK: - Configuration

    public struct Configuration: Sendable {
        public var rotationSensitivity: Float
        public var snapToPlaneOnDragEnd: Bool
        public var maxRaycastDistance: Float

        public init(
            rotationSensitivity: Float = 0.05,
            snapToPlaneOnDragEnd: Bool = true,
            maxRaycastDistance: Float = 10.0
        ) {
            self.rotationSensitivity = rotationSensitivity
            self.snapToPlaneOnDragEnd = snapToPlaneOnDragEnd
            self.maxRaycastDistance = maxRaycastDistance
        }
    }

    // MARK: - Dependencies

    public var configuration: Configuration
    public var planeProvider: (any PlaneProvider)?
    public var raycaster: (any SceneRaycaster)?

    // MARK: - Internal State

    private var dragStartOffset: [ObjectIdentifier: SIMD3<Float>] = [:]
    private var activeDrags: Set<ObjectIdentifier> = []

    // MARK: - Init

    public init(configuration: Configuration = .init()) {
        self.configuration = configuration
    }

    // MARK: - visionOS Gestures

    #if os(visionOS)
    public var dragGesture: some Gesture {
        DragGesture()
            .targetedToAnyEntity()
            .onChanged { [weak self] value in
                self?.handleDragChanged(value: value)
            }
            .onEnded { [weak self] value in
                self?.handleDragEnded(for: value.entity)
            }
    }

    public var rotateGesture: some Gesture {
        RotateGesture3D(constrainedToAxis: .y)
            .targetedToAnyEntity()
            .onChanged { [weak self] value in
                guard let self else { return }
                let deltaQ = simd_quatf(value.rotation)
                let newRotation = self.applyRotation(
                    currentRotation: value.entity.transform.rotation,
                    deltaRotation: deltaQ
                )
                value.entity.transform.rotation = newRotation
            }
    }

    private func handleDragChanged(value: EntityTargetValue<DragGesture.Value>) {
        guard let parent = value.entity.parent else { return }

        let id = ObjectIdentifier(value.entity)
        let touchInParent = value.convert(value.location3D, from: .local, to: parent)

        if !activeDrags.contains(id) {
            beginDrag(
                for: id,
                entityPosition: value.entity.position,
                touchPosition: touchInParent
            )
        }

        if let newPosition = updateDrag(for: id, touchPosition: touchInParent) {
            value.entity.position = newPosition
        }
    }

    private func handleDragEnded(for entity: Entity) {
        let id = ObjectIdentifier(entity)
        endDrag(for: id)

        if configuration.snapToPlaneOnDragEnd {
            let worldTransform = entity.transformMatrix(relativeTo: nil)
            let worldPosition = SIMD3<Float>(
                worldTransform.columns.3.x,
                worldTransform.columns.3.y,
                worldTransform.columns.3.z
            )

            if let snappedPosition = dropEntityOntoPlane(entityWorldPosition: worldPosition) {
                if let parent = entity.parent {
                    entity.position = parent.convert(position: snappedPosition, from: nil)
                } else {
                    var t = entity.transform
                    t.translation = snappedPosition
                    entity.transform = t
                }
            }
        }
    }
    #endif

    // MARK: - Testable Programmatic API

    /// Start a drag - records offset between entity position and touch position
    public func beginDrag(
        for entityID: ObjectIdentifier,
        entityPosition: SIMD3<Float>,
        touchPosition: SIMD3<Float>
    ) {
        guard !activeDrags.contains(entityID) else { return }
        dragStartOffset[entityID] = entityPosition - touchPosition
        activeDrags.insert(entityID)
    }

    /// Update a drag - returns new position (touch + stored offset)
    public func updateDrag(
        for entityID: ObjectIdentifier,
        touchPosition: SIMD3<Float>
    ) -> SIMD3<Float>? {
        guard let offset = dragStartOffset[entityID] else { return nil }
        return touchPosition + offset
    }

    /// End a drag - cleans up state
    public func endDrag(for entityID: ObjectIdentifier) {
        dragStartOffset.removeValue(forKey: entityID)
        activeDrags.remove(entityID)
    }

    /// Apply rotation with sensitivity scaling
    public func applyRotation(
        currentRotation: simd_quatf,
        deltaRotation: simd_quatf
    ) -> simd_quatf {
        let axis = simd_normalize(deltaRotation.axis)
        let scaledAngle = deltaRotation.angle * configuration.rotationSensitivity
        let scaledDelta = simd_quatf(angle: scaledAngle, axis: axis)
        return scaledDelta * currentRotation
    }

    /// Drop an entity onto the nearest plane below it
    public func dropEntityOntoPlane(
        entityWorldPosition: SIMD3<Float>
    ) -> SIMD3<Float>? {
        guard let raycaster, let planeProvider else { return nil }

        guard let hit = raycaster.raycastDown(
            from: entityWorldPosition,
            maxDistance: configuration.maxRaycastDistance,
            planeEntityIDs: planeProvider.planeEntityIDs
        ) else { return nil }

        var newPosition = entityWorldPosition
        newPosition.y = hit.position.y
        return newPosition
    }
}
