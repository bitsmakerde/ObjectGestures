//
//  EntityGestureManagerTests.swift
//  ObjectGesturesTests
//
//  Tests for drag, rotate, and drop-onto-plane gesture logic

import XCTest
import simd
@testable import ObjectGestures

final class EntityGestureManagerTests: XCTestCase {

    // MARK: - Mock Types

    struct MockRaycaster: SceneRaycaster {
        var hitResult: PlaneHitResult?

        func raycastDown(
            from origin: SIMD3<Float>,
            maxDistance: Float,
            planeEntityIDs: Set<ObjectIdentifier>
        ) -> PlaneHitResult? {
            return hitResult
        }
    }

    struct MockPlaneProvider: PlaneProvider {
        var planeEntityIDs: Set<ObjectIdentifier> = []
    }

    // MARK: - Drag Tests

    @MainActor
    func test_beginDrag_recordsOffset() {
        let sut = EntityGestureManager()
        let entityID = ObjectIdentifier(NSObject())

        sut.beginDrag(
            for: entityID,
            entityPosition: SIMD3<Float>(1, 2, 3),
            touchPosition: SIMD3<Float>(0.5, 1.5, 2.5)
        )

        let result = sut.updateDrag(
            for: entityID,
            touchPosition: SIMD3<Float>(1, 1, 1)
        )

        // offset = (1,2,3) - (0.5,1.5,2.5) = (0.5, 0.5, 0.5)
        // result = (1,1,1) + (0.5,0.5,0.5) = (1.5, 1.5, 1.5)
        XCTAssertEqual(result, SIMD3<Float>(1.5, 1.5, 1.5))
    }

    @MainActor
    func test_updateDrag_withoutBegin_returnsNil() {
        let sut = EntityGestureManager()
        let entityID = ObjectIdentifier(NSObject())

        let result = sut.updateDrag(
            for: entityID,
            touchPosition: SIMD3<Float>(1, 1, 1)
        )

        XCTAssertNil(result)
    }

    @MainActor
    func test_endDrag_cleansUpState() {
        let sut = EntityGestureManager()
        let entityID = ObjectIdentifier(NSObject())

        sut.beginDrag(
            for: entityID,
            entityPosition: SIMD3<Float>(0, 0, 0),
            touchPosition: SIMD3<Float>(0, 0, 0)
        )
        sut.endDrag(for: entityID)

        let result = sut.updateDrag(
            for: entityID,
            touchPosition: SIMD3<Float>(1, 1, 1)
        )

        XCTAssertNil(result)
    }

    @MainActor
    func test_beginDrag_calledTwice_doesNotResetOffset() {
        let sut = EntityGestureManager()
        let entityID = ObjectIdentifier(NSObject())

        sut.beginDrag(
            for: entityID,
            entityPosition: SIMD3<Float>(1, 0, 0),
            touchPosition: SIMD3<Float>(0, 0, 0)
        )

        // Second call with different offset should be ignored
        sut.beginDrag(
            for: entityID,
            entityPosition: SIMD3<Float>(5, 0, 0),
            touchPosition: SIMD3<Float>(0, 0, 0)
        )

        let result = sut.updateDrag(
            for: entityID,
            touchPosition: SIMD3<Float>(2, 0, 0)
        )

        // First offset (1,0,0) should apply: 2 + 1 = 3
        XCTAssertEqual(result, SIMD3<Float>(3, 0, 0))
    }

    @MainActor
    func test_multipleDrags_independentState() {
        let sut = EntityGestureManager()
        let objA = NSObject()
        let objB = NSObject()
        let entityA = ObjectIdentifier(objA)
        let entityB = ObjectIdentifier(objB)

        sut.beginDrag(for: entityA, entityPosition: SIMD3<Float>(1, 0, 0), touchPosition: .zero)
        sut.beginDrag(for: entityB, entityPosition: SIMD3<Float>(0, 5, 0), touchPosition: .zero)

        let resultA = sut.updateDrag(for: entityA, touchPosition: SIMD3<Float>(2, 0, 0))
        let resultB = sut.updateDrag(for: entityB, touchPosition: SIMD3<Float>(0, 1, 0))

        XCTAssertEqual(resultA, SIMD3<Float>(3, 0, 0))
        XCTAssertEqual(resultB, SIMD3<Float>(0, 6, 0))
    }

    // MARK: - Rotation Tests

    @MainActor
    func test_applyRotation_respectsSensitivity() {
        let sut = EntityGestureManager(configuration: .init(rotationSensitivity: 0.05))

        let current = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))
        let delta = simd_quatf(angle: .pi / 2, axis: SIMD3<Float>(0, 1, 0))

        let result = sut.applyRotation(currentRotation: current, deltaRotation: delta)

        // Expected: 90 * 0.05 = 4.5 degrees = pi/40
        let expectedAngle: Float = .pi / 40
        XCTAssertEqual(result.angle, expectedAngle, accuracy: 0.001)
    }

    @MainActor
    func test_applyRotation_highSensitivity() {
        let sut = EntityGestureManager(configuration: .init(rotationSensitivity: 1.0))

        let current = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))
        let delta = simd_quatf(angle: .pi / 4, axis: SIMD3<Float>(0, 1, 0))

        let result = sut.applyRotation(currentRotation: current, deltaRotation: delta)

        // With sensitivity 1.0, angle should be unchanged
        XCTAssertEqual(result.angle, .pi / 4, accuracy: 0.001)
    }

    // MARK: - Drop Tests

    @MainActor
    func test_dropOntoPlane_withHit_returnsAdjustedY() {
        var raycaster = MockRaycaster()
        raycaster.hitResult = PlaneHitResult(
            position: SIMD3<Float>(0, 0.5, 0),
            distance: 1.5,
            entityName: "floor"
        )

        let sut = EntityGestureManager()
        sut.raycaster = raycaster
        sut.planeProvider = MockPlaneProvider()

        let result = sut.dropEntityOntoPlane(
            entityWorldPosition: SIMD3<Float>(1, 2, 3)
        )

        XCTAssertEqual(result, SIMD3<Float>(1, 0.5, 3))
    }

    @MainActor
    func test_dropOntoPlane_noHit_returnsNil() {
        let raycaster = MockRaycaster() // hitResult = nil

        let sut = EntityGestureManager()
        sut.raycaster = raycaster
        sut.planeProvider = MockPlaneProvider()

        let result = sut.dropEntityOntoPlane(
            entityWorldPosition: SIMD3<Float>(1, 2, 3)
        )

        XCTAssertNil(result)
    }

    @MainActor
    func test_dropOntoPlane_noRaycaster_returnsNil() {
        let sut = EntityGestureManager()

        let result = sut.dropEntityOntoPlane(
            entityWorldPosition: SIMD3<Float>(1, 2, 3)
        )

        XCTAssertNil(result)
    }

    @MainActor
    func test_dropOntoPlane_noPlaneProvider_returnsNil() {
        let sut = EntityGestureManager()
        sut.raycaster = MockRaycaster()

        let result = sut.dropEntityOntoPlane(
            entityWorldPosition: SIMD3<Float>(1, 2, 3)
        )

        XCTAssertNil(result)
    }

    // MARK: - Configuration Tests

    @MainActor
    func test_defaultConfiguration() {
        let config = EntityGestureManager.Configuration()
        XCTAssertEqual(config.rotationSensitivity, 0.05)
        XCTAssertTrue(config.snapToPlaneOnDragEnd)
        XCTAssertEqual(config.maxRaycastDistance, 10.0)
    }

    @MainActor
    func test_customConfiguration() {
        let config = EntityGestureManager.Configuration(
            rotationSensitivity: 0.1,
            snapToPlaneOnDragEnd: false,
            maxRaycastDistance: 20.0
        )
        XCTAssertEqual(config.rotationSensitivity, 0.1)
        XCTAssertFalse(config.snapToPlaneOnDragEnd)
        XCTAssertEqual(config.maxRaycastDistance, 20.0)
    }
    
    // MARK: - PlaneHitResult Tests
    
    func test_planeHitResult_storesValues() {
        let hit = PlaneHitResult(
            position: SIMD3<Float>(1, 2, 3),
            distance: 5.0,
            entityName: "floor"
        )
        XCTAssertEqual(hit.position, SIMD3<Float>(1, 2, 3))
        XCTAssertEqual(hit.distance, 5.0)
        XCTAssertEqual(hit.entityName, "floor")
    }
}
