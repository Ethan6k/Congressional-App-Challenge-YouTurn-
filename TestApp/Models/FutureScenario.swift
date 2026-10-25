//
//  FutureScenario.swift
//  TestApp
//
//  The two futures the app compares: keeping current habits vs. following
//  the app's plan, at a horizon the user picks. Also builds the AI image
//  prompts for each.
//

import Foundation

struct FutureScenario {
    enum Kind { case currentHabits, followingPlan }

    let kind: Kind
    let title: String
    /// The same idea worded for the AI prompt ("if they ...").
    let promptPhrase: String
    let habitsDescription: String
    let bodyCompositionHint: String
    let projection: HealthProjection

    static let horizonOptions = [6, 12, 24, 60, 120]

    static func horizonLabel(months: Int) -> String {
        if months < 12 {
            return "\(months) months"
        }
        let years = months / 12
        return years == 1 ? "1 year" : "\(years) years"
    }

    static func horizonShortLabel(months: Int) -> String {
        months < 12 ? "\(months) mo" : "\(months / 12) yr"
    }

    /// Both scenarios at the user's chosen horizon.
    static func both(for profile: UserProfile) -> (current: FutureScenario, plan: FutureScenario) {
        let months = profile.visualizeMonths
        let today = HealthProjection.calculate(profile: profile)
        let nutrition = NutritionAdvisor.plan(for: profile, projection: today)
        let workouts = WorkoutPlanner.plan(for: profile, bmi: today.currentBMI)
        let planHabits = Habits.followingPlan(profile, nutrition: nutrition, workouts: workouts)

        let current = FutureScenario(
            kind: .currentHabits,
            title: "If you keep your current habits",
            promptPhrase: "if they keep their current habits",
            habitsDescription: "Eats about \(profile.dailyCalories) calories/day; exercise: \(profile.exerciseSummary); sleeps \(String(format: "%.1f", profile.sleepHours)) hours/night",
            bodyCompositionHint: profile.activities.bodyCompositionHint,
            projection: HealthProjection.calculate(profile: profile, months: months)
        )

        let plan = FutureScenario(
            kind: .followingPlan,
            title: "If you follow your plan",
            promptPhrase: "if they follow a personalized diet and workout plan",
            habitsDescription: "Eats about \(nutrition.calorieTarget) calories/day with \(nutrition.proteinGrams.lowerBound)-\(nutrition.proteinGrams.upperBound) g protein; follows a \(workouts.title) workout plan (\(workouts.activities.summary)); sleeps \(String(format: "%.1f", planHabits.sleepHours)) hours/night",
            bodyCompositionHint: workouts.activities.bodyCompositionHint,
            projection: HealthProjection.calculate(
                profile: profile,
                habits: planHabits,
                months: months,
                stopAtWeight: profile.goal.hasTargetWeight ? profile.targetWeightPounds : nil
            )
        )

        return (current, plan)
    }
}

// MARK: - AI image prompts

enum FuturePrompt {

    /// Edit the user's own photo to show them in this future.
    static func withPhoto(_ scenario: FutureScenario, profile: UserProfile) -> String {
        let p = scenario.projection
        let horizon = FutureScenario.horizonLabel(months: p.horizonMonths)

        return """
        Edit the provided reference photograph of this person to show what they would realistically look like \(horizon) from now, \(scenario.promptPhrase).

        Today (when the photo was taken):
        - Age: \(profile.age)
        - Sex: \(profile.sex.label)
        - Height: \(feetAndInches(profile.heightInches))
        - Weight: \(Int(profile.weightPounds.rounded())) lb
        - BMI: \(String(format: "%.1f", p.currentBMI))

        Their habits in this scenario:
        - \(scenario.habitsDescription)

        Projected \(horizon) from now:
        - Age: \(p.futureAge)
        - Weight: \(weightRange(p))
        - BMI: \(bmiRange(p))
        - Body age: about \(p.futureBiologicalAge)
        - Training style: \(scenario.bodyCompositionHint)

        Editing instructions:
        - Keep the person's identity: facial features, bone structure, eye shape, nose, mouth, skin tone, and ethnic likeness. They must be clearly recognizable as the same person.
        - \(agingInstruction(p))
        - Adjust facial fullness, jawline definition, skin vitality, and body composition to match the projected weight and training style. If the projected weight is close to today's, keep their size about the same.
        - Keep natural photographic lighting and textures. Do not include text, watermarks, or before-and-after split screens.
        """
    }

    /// No photo: create a fictional person matching the user's stats.
    static func withoutPhoto(_ scenario: FutureScenario, profile: UserProfile) -> String {
        let p = scenario.projection
        let horizon = FutureScenario.horizonLabel(months: p.horizonMonths)

        return """
        Create a realistic, respectful photo of one fictional \(profile.sex.label.lowercased()) adult, about \(p.futureAge) years old, \(feetAndInches(profile.heightInches)) tall, weighing about \(midWeight(p)) lb (BMI about \(String(format: "%.1f", (p.projectedBMIRange.lowerBound + p.projectedBMIRange.upperBound) / 2))). This shows a health-app user \(horizon) from now, \(scenario.promptPhrase).

        Their habits: \(scenario.habitsDescription).
        Training style: \(scenario.bodyCompositionHint)

        Show the person from head to knees, standing outdoors in natural light, in everyday athletic clothes. Make their body realistically match the weight and training style above. Use a polished but believable photographic style. Do not make the person resemble any specific real person. Do not include text, logos, medical imagery, before-and-after panels, scales, measurements, or body-shaming cues.
        """
    }

    /// No photo, second image: same fictional person as the first image, but in this scenario.
    static func matchingPerson(_ scenario: FutureScenario, profile: UserProfile) -> String {
        let p = scenario.projection
        let horizon = FutureScenario.horizonLabel(months: p.horizonMonths)

        return """
        The provided image shows a fictional person. Create a new photo of the SAME fictional person (same face, hair, and skin tone, same age of about \(p.futureAge)), but showing how they would look \(horizon) from now \(scenario.promptPhrase) instead.

        In this version they weigh about \(midWeight(p)) lb (\(feetAndInches(profile.heightInches)) tall).
        Their habits: \(scenario.habitsDescription).
        Training style: \(scenario.bodyCompositionHint)

        Match the framing, setting, and lighting of the provided image so the two can be compared. Make their body realistically match the weight and training style above. Do not include text, logos, before-and-after panels, scales, measurements, or body-shaming cues.
        """
    }

    // MARK: - Helpers

    private static func agingInstruction(_ p: HealthProjection) -> String {
        if p.horizonMonths < 12 {
            return "Only \(p.horizonMonths) months pass, so do not visibly age them."
        }
        let years = p.horizonMonths / 12
        return "Realistically age their appearance by \(years) year\(years == 1 ? "" : "s") (to about \(p.futureAge)), reflecting a body age of about \(p.futureBiologicalAge)."
    }

    private static func feetAndInches(_ inches: Double) -> String {
        "\(Int(inches) / 12)'\(Int(inches) % 12)\""
    }

    private static func midWeight(_ p: HealthProjection) -> Int {
        Int(((p.projectedWeightRange.lowerBound + p.projectedWeightRange.upperBound) / 2).rounded())
    }

    private static func weightRange(_ p: HealthProjection) -> String {
        "\(Int(p.projectedWeightRange.lowerBound.rounded()))-\(Int(p.projectedWeightRange.upperBound.rounded())) lb"
    }

    private static func bmiRange(_ p: HealthProjection) -> String {
        "\(String(format: "%.1f", p.projectedBMIRange.lowerBound))-\(String(format: "%.1f", p.projectedBMIRange.upperBound))"
    }
}
