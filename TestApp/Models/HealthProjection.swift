import Foundation

struct HealthProjection {
    let currentBMI: Double
    let bmiCategory: String
    let maintenanceCalories: Int
    let projectedWeightRange: ClosedRange<Double>
    let projectedBMIRange: ClosedRange<Double>
    let weeklyWeightChange: Double
    let weightChangeWarning: String?
    let lifeExpectancyModifierRange: ClosedRange<Double>
    let biologicalAge: Int

    static func calculate(
        age: Int,
        heightInches: Double,
        weightPounds: Double,
        dailyCalories: Int,
        exercise: String,
        sleepHours: Double,
        stress: Int,
        horizonYears: Int = 1
    ) -> HealthProjection {
        let heightCentimeters = heightInches * 2.54
        let weightKilograms = weightPounds * 0.45359237
        let heightMeters = heightCentimeters / 100
        let currentBMI = weightKilograms / (heightMeters * heightMeters)

        let basalMetabolicRate = (10 * weightKilograms) + (6.25 * heightCentimeters) - (5 * Double(age)) - 78
        let maintenanceCalories = basalMetabolicRate * activityMultiplier(for: exercise)
        let dailyCalorieDelta = Double(dailyCalories) - maintenanceCalories
        let weeklyWeightChange = dailyCalorieDelta * 7 / 3500
        let projectedChange = dailyCalorieDelta * Double(365 * horizonYears) / 3500
        let uncertainty = max(abs(projectedChange) * 0.15, 2)

        let lowerWeight = max(80, weightPounds + projectedChange - uncertainty)
        let upperWeight = max(lowerWeight, weightPounds + projectedChange + uncertainty)
        let lowerBMI = bmi(forWeightPounds: lowerWeight, heightMeters: heightMeters)
        let upperBMI = bmi(forWeightPounds: upperWeight, heightMeters: heightMeters)

        return HealthProjection(
            currentBMI: currentBMI,
            bmiCategory: bmiCategory(for: currentBMI),
            maintenanceCalories: Int(maintenanceCalories.rounded()),
            projectedWeightRange: lowerWeight...upperWeight,
            projectedBMIRange: lowerBMI...upperBMI,
            weeklyWeightChange: weeklyWeightChange,
            weightChangeWarning: weightChangeWarning(for: weeklyWeightChange),
            lifeExpectancyModifierRange: lifeExpectancyModifierRange(
                bmi: currentBMI,
                exercise: exercise,
                sleepHours: sleepHours,
                stress: stress
            ),
            biologicalAge: biologicalAge(
                chronologicalAge: age,
                bmi: currentBMI,
                exercise: exercise,
                sleepHours: sleepHours,
                stress: stress
            )
        )
    }

    private static func activityMultiplier(for exercise: String) -> Double {
        switch exercise {
        case "Daily":
            return 1.725
        case "3-4 days":
            return 1.55
        case "1-2 days":
            return 1.375
        default:
            return 1.2
        }
    }

    private static func bmi(forWeightPounds weightPounds: Double, heightMeters: Double) -> Double {
        let weightKilograms = weightPounds * 0.45359237
        return weightKilograms / (heightMeters * heightMeters)
    }

    private static func bmiCategory(for bmi: Double) -> String {
        switch bmi {
        case ..<18.5:
            return "Underweight"
        case ..<25:
            return "Healthy range"
        case ..<30:
            return "Overweight"
        default:
            return "Obesity range"
        }
    }

    private static func weightChangeWarning(for weeklyWeightChange: Double) -> String? {
        if abs(weeklyWeightChange) <= 2 {
            return nil
        }

        return "This projects faster than 1-2 lb/week, which is commonly considered difficult to sustain."
    }

    private static func lifeExpectancyModifierRange(
        bmi: Double,
        exercise: String,
        sleepHours: Double,
        stress: Int
    ) -> ClosedRange<Double> {
        var midpoint = 0.0

        if bmi < 18.5 || bmi >= 30 {
            midpoint -= 2.0
        } else if bmi >= 25 {
            midpoint -= 1.0
        } else {
            midpoint += 0.5
        }

        if exercise == "Daily" || exercise == "3-4 days" {
            midpoint += 1.5
        } else if exercise == "Never" {
            midpoint -= 1.5
        }

        if sleepHours < 6 || sleepHours > 9 {
            midpoint -= 1.0
        } else if sleepHours >= 7 && sleepHours <= 8.5 {
            midpoint += 0.5
        }

        if stress >= 8 {
            midpoint -= 0.5
        }

        return (midpoint - 1.0)...(midpoint + 1.0)
    }

    private static func biologicalAge(
        chronologicalAge: Int,
        bmi: Double,
        exercise: String,
        sleepHours: Double,
        stress: Int
    ) -> Int {
        var adjustment = 0

        if bmi < 18.5 || bmi >= 30 {
            adjustment += 3
        } else if bmi >= 25 {
            adjustment += 1
        }

        if exercise == "Daily" || exercise == "3-4 days" {
            adjustment -= 2
        } else if exercise == "Never" {
            adjustment += 2
        }

        if sleepHours < 6 || sleepHours > 9 {
            adjustment += 2
        } else if sleepHours >= 7 && sleepHours <= 8.5 {
            adjustment -= 1
        }

        if stress >= 8 {
            adjustment += 1
        }

        return max(chronologicalAge + adjustment, chronologicalAge - 5)
    }
}
