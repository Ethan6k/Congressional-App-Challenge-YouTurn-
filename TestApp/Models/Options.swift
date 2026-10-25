//
//  Options.swift
//  TestApp
//
//  The fixed answer choices the user can pick from. Each `label` is the
//  text shown on screen.
//

import Foundation

enum Sex: String, CaseIterable, Identifiable, Codable {
    case male, female

    var id: Self { self }

    var label: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        }
    }
}

enum FitnessGoal: String, CaseIterable, Identifiable, Codable {
    case loseWeight, buildMuscle, maintain, generalHealth

    var id: Self { self }

    var label: String {
        switch self {
        case .loseWeight: return "Lose weight"
        case .buildMuscle: return "Build muscle / gain weight"
        case .maintain: return "Maintain my weight"
        case .generalHealth: return "Improve overall health"
        }
    }

    /// Goals where a target weight makes sense.
    var hasTargetWeight: Bool {
        self == .loseWeight || self == .buildMuscle
    }
}

enum WorkoutLocation: String, CaseIterable, Identifiable, Codable {
    case commercialGym, homeGym, homeDumbbells, homeNoEquipment, outdoors, classes

    var id: Self { self }

    var label: String {
        switch self {
        case .commercialGym: return "Commercial gym"
        case .homeGym: return "Home gym"
        case .homeDumbbells: return "Home with dumbbells / bands"
        case .homeNoEquipment: return "Home, no equipment"
        case .outdoors: return "Outdoors / park"
        case .classes: return "Classes / studio"
        }
    }

    var details: String {
        switch self {
        case .commercialGym: return "Machines, barbells, cables, cardio equipment"
        case .homeGym: return "Squat rack, barbell, bench, plates"
        case .homeDumbbells: return "Dumbbells, kettlebells, resistance bands"
        case .homeNoEquipment: return "Bodyweight only"
        case .outdoors: return "Running paths, pull-up bars, tracks, fields"
        case .classes: return "Spin, CrossFit, yoga, boot camp"
        }
    }
}

enum Experience: String, CaseIterable, Identifiable, Codable {
    case beginner, intermediate, advanced

    var id: Self { self }

    var label: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }
}

enum DietPreference: String, CaseIterable, Identifiable, Codable {
    case noPreference, vegetarian, vegan, dairyFree

    var id: Self { self }

    var label: String {
        switch self {
        case .noPreference: return "No preference"
        case .vegetarian: return "Vegetarian"
        case .vegan: return "Vegan"
        case .dairyFree: return "Dairy-free"
        }
    }
}
