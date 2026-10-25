//
//  Exercise.swift
//  TestApp
//
//  The kinds of workouts a user can log, how hard they are, and how many
//  calories they burn.
//
//  Burn is estimated with METs (how many times more energy an activity uses
//  than sitting still). Values are approximations from the Compendium of
//  Physical Activities.
//

import Foundation

enum ExerciseType: String, CaseIterable, Identifiable, Codable {
    case weightlifting, calisthenics, running, cycling, swimming, hiit, sports, walking, yoga

    var id: Self { self }

    var label: String {
        switch self {
        case .weightlifting: return "Weightlifting"
        case .calisthenics: return "Calisthenics / bodyweight"
        case .running: return "Running / jogging"
        case .cycling: return "Cycling / spin"
        case .swimming: return "Swimming"
        case .hiit: return "HIIT / circuits"
        case .sports: return "Sports"
        case .walking: return "Walking / hiking"
        case .yoga: return "Yoga / Pilates / stretching"
        }
    }

    var examples: String {
        switch self {
        case .weightlifting: return "Barbells, dumbbells, machines"
        case .calisthenics: return "Push-ups, pull-ups, dips, squats"
        case .running: return "Treadmill, track, outdoor runs"
        case .cycling: return "Road, stationary bike, spin class"
        case .swimming: return "Laps, water aerobics"
        case .hiit: return "Interval training, CrossFit-style circuits"
        case .sports: return "Basketball, soccer, tennis, etc."
        case .walking: return "Brisk walks, hikes, stair climbing"
        case .yoga: return "Yoga, Pilates, mobility work"
        }
    }

    /// Builds muscle (counts toward the 2-days-a-week strength guideline).
    var isStrength: Bool {
        self == .weightlifting || self == .calisthenics
    }

    /// METs at light / moderate / vigorous effort.
    func met(at intensity: Intensity) -> Double {
        let values: (light: Double, moderate: Double, vigorous: Double)

        switch self {
        case .weightlifting: values = (3.5, 5.0, 6.0)
        case .calisthenics: values = (3.5, 4.5, 8.0)
        case .running: values = (6.0, 8.3, 11.0)
        case .cycling: values = (4.0, 7.0, 10.0)
        case .swimming: values = (5.0, 7.0, 9.8)
        case .hiit: values = (5.0, 8.0, 10.0)
        case .sports: values = (4.0, 6.5, 8.0)
        case .walking: values = (2.8, 3.5, 5.3)
        case .yoga: values = (2.5, 3.0, 4.0)
        }

        switch intensity {
        case .light: return values.light
        case .moderate: return values.moderate
        case .vigorous: return values.vigorous
        }
    }
}

enum Intensity: String, CaseIterable, Identifiable, Codable {
    case light, moderate, vigorous

    var id: Self { self }

    var label: String {
        switch self {
        case .light: return "Light"
        case .moderate: return "Moderate"
        case .vigorous: return "Vigorous"
        }
    }

    /// The "talk test" from the CDC.
    var talkTest: String {
        switch self {
        case .light: return "Easy: you could sing"
        case .moderate: return "Medium: you can talk, but not sing"
        case .vigorous: return "Hard: only a few words at a time"
        }
    }
}

/// One workout the user does regularly, e.g. "Weightlifting, vigorous, 4 days, 60 min".
struct ExerciseActivity: Identifiable, Equatable, Codable {
    var id = UUID()
    var type: ExerciseType = .weightlifting
    var intensity: Intensity = .moderate
    var daysPerWeek: Int = 3
    var minutesPerSession: Int = 45

    var weeklyMinutes: Int { daysPerWeek * minutesPerSession }

    var met: Double { type.met(at: intensity) }

    /// Extra calories burned per week on top of resting
    /// (MET - 1, because resting burn is already counted separately).
    func weeklyCaloriesBurned(weightKilograms: Double) -> Double {
        (met - 1) * weightKilograms * Double(weeklyMinutes) / 60
    }

    /// Minutes that count toward the CDC's 150 min/week guideline.
    /// Vigorous activity (6+ METs) counts double; light activity (< 3 METs) doesn't count.
    var guidelineMinutes: Int {
        switch met {
        case 6...: return weeklyMinutes * 2
        case 3..<6: return weeklyMinutes
        default: return 0
        }
    }

    var summary: String {
        "\(type.label.lowercased()) (\(intensity.label.lowercased())) \(daysPerWeek)x/week, \(minutesPerSession) min"
    }
}

/// Totals for a whole list of workouts (used for both current habits and the plan).
extension Array where Element == ExerciseActivity {

    /// Extra calories burned by workouts, averaged over a day.
    func caloriesPerDay(weightKilograms: Double) -> Double {
        reduce(0) { $0 + $1.weeklyCaloriesBurned(weightKilograms: weightKilograms) } / 7
    }

    /// Minutes per week that count toward the CDC's 150-minute guideline.
    var guidelineMinutes: Int {
        reduce(0) { $0 + $1.guidelineMinutes }
    }

    /// Days per week of strength training (capped at 7).
    var strengthDaysPerWeek: Int {
        Swift.min(7, filter { $0.type.isStrength }.reduce(0) { $0 + $1.daysPerWeek })
    }

    /// Weekly minutes of cardio-style training (running, cycling, swimming, HIIT, sports).
    var cardioMinutes: Int {
        let cardio: Set<ExerciseType> = [.running, .cycling, .swimming, .hiit, .sports]
        return filter { cardio.contains($0.type) }.reduce(0) { $0 + $1.weeklyMinutes }
    }

    /// How this training should show up in a future image.
    var bodyCompositionHint: String {
        let strengthMinutes = filter { $0.type.isStrength }.reduce(0) { $0 + $1.weeklyMinutes }

        if isEmpty {
            return "No regular training, so no added muscle definition."
        } else if strengthMinutes >= 90 && strengthMinutes >= cardioMinutes {
            return "Regular strength training: show more visible muscle tone and fuller shoulders, arms, and chest."
        } else if cardioMinutes >= 120 {
            return "Mostly cardio/endurance training: show a leaner, athletic endurance build."
        } else {
            return "Light, mixed activity: show modest improvements in posture and tone."
        }
    }

    /// Plain-English description, e.g. for the AI image prompt.
    var summary: String {
        isEmpty ? "no regular exercise" : map(\.summary).joined(separator: "; ")
    }
}
