//
//  PlaneProvider.swift
//  ObjectGestures
//
//  Protocol for accessing detected plane entities

import Foundation

/// Provides access to detected plane entity IDs for drop-onto-plane logic.
/// Implement this protocol in your app to connect AR plane detection
/// with the gesture system.
@MainActor
public protocol PlaneProvider: Sendable {
    /// Set of ObjectIdentifiers for all known plane entities
    var planeEntityIDs: Set<ObjectIdentifier> { get }
}
