//
//  GalleryStore.swift
//  TestApp
//
//  Saves every uploaded photo and every generated image on the phone, each
//  labeled with the health data it was made from.
//

import Combine
import Foundation
import UIKit

/// The health data at the moment an image was made.
struct HealthSnapshot: Codable {
    var age: Int
    var heightInches: Double
    var weightPounds: Double
    var goal: String
    var dailyCalories: Int
    var exercise: String
    var sleepHours: Double

    /// Only for generated images: what the image was projecting.
    var projection: ProjectedData?

    struct ProjectedData: Codable {
        var horizonMonths: Int
        var habits: String
        var futureAge: Int
        var weightLow: Double
        var weightHigh: Double
        var bmiLow: Double
        var bmiHigh: Double
        var bodyAge: Int
    }

    init(profile: UserProfile, scenario: FutureScenario? = nil) {
        age = profile.age
        heightInches = profile.heightInches
        weightPounds = profile.weightPounds
        goal = profile.goal.label
        dailyCalories = profile.dailyCalories
        exercise = profile.exerciseSummary
        sleepHours = profile.sleepHours

        if let scenario {
            let p = scenario.projection
            projection = ProjectedData(
                horizonMonths: p.horizonMonths,
                habits: scenario.habitsDescription,
                futureAge: p.futureAge,
                weightLow: p.projectedWeightRange.lowerBound,
                weightHigh: p.projectedWeightRange.upperBound,
                bmiLow: p.projectedBMIRange.lowerBound,
                bmiHigh: p.projectedBMIRange.upperBound,
                bodyAge: p.futureBiologicalAge
            )
        }
    }
}

struct GalleryEntry: Codable, Identifiable {
    enum Kind: String, Codable, CaseIterable {
        case currentHabits, followingPlan, uploadedPhoto

        var label: String {
            switch self {
            case .currentHabits: return "Current habits"
            case .followingPlan: return "Following your plan"
            case .uploadedPhoto: return "Your photo"
            }
        }
    }

    var id = UUID()
    /// Images generated together share a batch (the two futures side by side).
    var batchID: UUID
    var date = Date()
    var kind: Kind
    /// Whether the image was made from the user's own photo.
    var fromPhoto: Bool
    var fileName: String
    var snapshot: HealthSnapshot
}

@MainActor
final class GalleryStore: ObservableObject {
    @Published private(set) var entries: [GalleryEntry] = []

    private var cache: [UUID: UIImage] = [:]

    private static var folder: URL {
        URL.applicationSupportDirectory.appending(path: "Gallery")
    }

    private static var indexURL: URL {
        folder.appending(path: "gallery.json")
    }

    init() {
        if let data = try? Data(contentsOf: Self.indexURL),
           let saved = try? JSONDecoder().decode([GalleryEntry].self, from: data) {
            entries = saved
        }
    }

    /// Saves an image with its health data. Returns the new entry.
    @discardableResult
    func add(_ image: UIImage, kind: GalleryEntry.Kind, batchID: UUID = UUID(), fromPhoto: Bool, snapshot: HealthSnapshot) -> GalleryEntry? {
        let entry = GalleryEntry(
            batchID: batchID,
            kind: kind,
            fromPhoto: fromPhoto,
            fileName: "\(UUID().uuidString).jpg",
            snapshot: snapshot
        )

        do {
            try FileManager.default.createDirectory(at: Self.folder, withIntermediateDirectories: true)
            guard let data = image.jpegData(compressionQuality: 0.85) else { return nil }
            try data.write(to: Self.folder.appending(path: entry.fileName), options: [.atomic, .completeFileProtectionUnlessOpen])
        } catch {
            print("Could not save image: \(error)")
            return nil
        }

        cache[entry.id] = image
        entries.append(entry)
        saveIndex()
        return entry
    }

    func image(for entry: GalleryEntry) -> UIImage? {
        if let cached = cache[entry.id] {
            return cached
        }
        // Read the file by URL. (A text path would turn the space in
        // "Application Support" into "%20" and the file wouldn't be found.)
        let url = Self.folder.appending(path: entry.fileName)
        guard let data = try? Data(contentsOf: url), let image = UIImage(data: data) else {
            return nil
        }
        cache[entry.id] = image
        return image
    }

    func entry(id: UUID?) -> GalleryEntry? {
        entries.first { $0.id == id }
    }

    func entries(inBatch batchID: UUID?) -> [GalleryEntry] {
        entries.filter { $0.batchID == batchID }
    }

    func delete(_ entry: GalleryEntry) {
        try? FileManager.default.removeItem(at: Self.folder.appending(path: entry.fileName))
        cache[entry.id] = nil
        entries.removeAll { $0.id == entry.id }
        saveIndex()
    }

    /// Erases every saved photo and image.
    func deleteAll() {
        try? FileManager.default.removeItem(at: Self.folder)
        cache = [:]
        entries = []
    }

    private func saveIndex() {
        do {
            try JSONEncoder().encode(entries).write(to: Self.indexURL, options: [.atomic, .completeFileProtectionUnlessOpen])
        } catch {
            print("Could not save gallery: \(error)")
        }
    }
}
