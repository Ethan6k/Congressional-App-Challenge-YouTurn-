import Foundation

/// The day-to-day habits a projection is based on: either what the user does
/// now, or what they'd do following the app's plan.
struct Habits {
    var dailyCalories: Int
    var activities: [ExerciseActivity]
    var sleepHours: Double
    var stress: Int

    static func current(_ profile: UserProfile) -> Habits {
        Habits(
            dailyCalories: profile.dailyCalories,
            activities: profile.activities,
            sleepHours: profile.sleepHours,
            stress: profile.stress
        )
    }

    /// Following the plan: eat the calorie target, do the workout plan, and
    /// sleep at least 7 hours (the plan recommends 7-9).
    static func followingPlan(_ profile: UserProfile, nutrition: NutritionPlan, workouts: WorkoutPlan) -> Habits {
        Habits(
            dailyCalories: nutrition.calorieTarget,
            activities: workouts.activities,
            sleepHours: max(profile.sleepHours, 7.5),
            stress: profile.stress
        )
    }
}

struct HealthProjection {
    let currentBMI: Double
    let bmiCategory: String
    let maintenanceCalories: Int
    let exerciseCaloriesPerDay: Int
    let projectedWeightRange: ClosedRange<Double>
    let projectedBMIRange: ClosedRange<Double>
    let weeklyWeightChange: Double
    let weightChangeWarning: String?
    let lifeExpectancyModifierRange: ClosedRange<Double>
    let biologicalAge: Int

    /// How far ahead the projected numbers are.
    let horizonMonths: Int
    /// Their real age at the end of the horizon.
    let futureAge: Int
    /// Body age at the end of the horizon, using their projected weight.
    let futureBiologicalAge: Int

    /// - Parameters:
    ///   - habits: what they do day to day (defaults to their current habits)
    ///   - months: how far ahead to project
    ///   - stopAtWeight: a target weight; once reached, they eat to maintain it
    static func calculate(
        profile: UserProfile,
        habits: Habits? = nil,
        months: Int = 12,
        stopAtWeight: Double? = nil
    ) -> HealthProjection {
        let habits = habits ?? .current(profile)
        let age = profile.age
        let weightPounds = profile.weightPounds
        let heightCentimeters = profile.heightInches * 2.54
        let heightMeters = heightCentimeters / 100
        let currentBMI = bmi(forWeightPounds: weightPounds, heightMeters: heightMeters)

        let guidelineMinutes = habits.activities.guidelineMinutes
        let strengthDays = habits.activities.strengthDaysPerWeek

        // Calories burned per day at a given weight and age.
        // Mifflin-St Jeor resting burn (+5 male, -161 female), x1.2 for normal
        // daily movement, plus what their workouts burn.
        func maintenance(weightPounds: Double, age: Double) -> Double {
            let kilograms = weightPounds * 0.45359237
            let sexAdjustment: Double = profile.sex == .male ? 5 : -161
            let resting = (10 * kilograms) + (6.25 * heightCentimeters) - (5 * age) + sexAdjustment
            return resting * 1.2 + habits.activities.caloriesPerDay(weightKilograms: kilograms)
        }

        let maintenanceToday = maintenance(weightPounds: weightPounds, age: Double(age))
        let weeklyWeightChange = (Double(habits.dailyCalories) - maintenanceToday) * 7 / 3500

        // Simulate week by week. As weight changes, the body burns a different
        // amount, so weight levels off instead of changing forever in a straight line.
        let weeks = Int((Double(months) * 52 / 12).rounded())
        var weight = weightPounds
        for week in 0..<weeks {
            let burned = maintenance(weightPounds: weight, age: Double(age) + Double(week) / 52)
            var change = (Double(habits.dailyCalories) - burned) * 7 / 3500

            if let target = stopAtWeight {
                let remaining = target - weight
                // Once they reach the target, they switch to eating for maintenance.
                if remaining == 0 || (remaining > 0) != (change > 0) {
                    change = 0
                } else if abs(change) > abs(remaining) {
                    change = remaining
                }
            }
            weight += change
        }

        let projectedChange = weight - weightPounds
        let uncertainty = max(abs(projectedChange) * 0.15, 2)
        let lowerWeight = max(80, weight - uncertainty)
        let upperWeight = max(lowerWeight, weight + uncertainty)
        let lowerBMI = bmi(forWeightPounds: lowerWeight, heightMeters: heightMeters)
        let upperBMI = bmi(forWeightPounds: upperWeight, heightMeters: heightMeters)
        let futureAge = age + months / 12

        return HealthProjection(
            currentBMI: currentBMI,
            bmiCategory: bmiCategory(for: currentBMI, age: age),
            maintenanceCalories: Int(maintenanceToday.rounded()),
            exerciseCaloriesPerDay: Int(habits.activities.caloriesPerDay(weightKilograms: profile.weightKilograms).rounded()),
            projectedWeightRange: lowerWeight...upperWeight,
            projectedBMIRange: lowerBMI...upperBMI,
            weeklyWeightChange: weeklyWeightChange,
            weightChangeWarning: weightChangeWarning(for: weeklyWeightChange),
            lifeExpectancyModifierRange: lifeExpectancyModifierRange(
                bmi: currentBMI,
                guidelineMinutes: guidelineMinutes,
                strengthDays: strengthDays,
                sleepHours: habits.sleepHours,
                stress: habits.stress
            ),
            biologicalAge: biologicalAge(
                chronologicalAge: age,
                bmi: currentBMI,
                guidelineMinutes: guidelineMinutes,
                strengthDays: strengthDays,
                sleepHours: habits.sleepHours,
                stress: habits.stress
            ),
            horizonMonths: months,
            futureAge: futureAge,
            futureBiologicalAge: biologicalAge(
                chronologicalAge: futureAge,
                bmi: bmi(forWeightPounds: weight, heightMeters: heightMeters),
                guidelineMinutes: guidelineMinutes,
                strengthDays: strengthDays,
                sleepHours: habits.sleepHours,
                stress: habits.stress
            )
        )
    }

    private static func bmi(forWeightPounds weightPounds: Double, heightMeters: Double) -> Double {
        let weightKilograms = weightPounds * 0.45359237
        return weightKilograms / (heightMeters * heightMeters)
    }

    private static func bmiCategory(for bmi: Double, age: Int) -> String {
        // Adult BMI categories don't apply under 20; doctors use age-based percentiles instead.
        if age < 20 {
            return "Adult categories don't apply under 20"
        }

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
        guidelineMinutes: Int,
        strengthDays: Int,
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

        // CDC: 150+ min/week of moderate activity (vigorous counts double)
        if guidelineMinutes >= 150 {
            midpoint += 1.5
        } else if guidelineMinutes == 0 {
            midpoint -= 1.5
        }

        // CDC: strength training 2+ days/week
        if strengthDays >= 2 {
            midpoint += 0.5
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
        guidelineMinutes: Int,
        strengthDays: Int,
        sleepHours: Double,
        stress: Int
    ) -> Int {
        var adjustment = 0

        if bmi < 18.5 || bmi >= 30 {
            adjustment += 3
        } else if bmi >= 25 {
            adjustment += 1
        }

        if guidelineMinutes >= 150 {
            adjustment -= 2
        } else if guidelineMinutes == 0 {
            adjustment += 2
        }

        if strengthDays >= 2 {
            adjustment -= 1
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
