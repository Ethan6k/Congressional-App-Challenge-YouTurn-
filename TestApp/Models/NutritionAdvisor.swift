//
//  NutritionAdvisor.swift
//  TestApp
//
//  Rule-based diet feedback (no AI). Looks at the user's goal, body, workouts
//  and eating habits, then returns daily targets plus a list of specific fixes.
//

import Foundation

struct NutritionTip: Identifiable {
    enum Priority: Int, Comparable {
        case high, medium, low, good

        static func < (lhs: Priority, rhs: Priority) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    let id = UUID()
    let priority: Priority
    let icon: String
    let title: String
    let detail: String
}

struct NutritionPlan {
    let calorieTarget: Int
    let proteinGrams: ClosedRange<Int>
    let fiberGrams: Int
    let tips: [NutritionTip]
}

enum NutritionAdvisor {

    /// Grams of protein in one serving (a palm-size chicken breast, 4 eggs, ...).
    /// The "How you eat" slide shows this same number to the user.
    static let gramsPerProteinServing = 25
    /// Rough calories in one sugary drink (12 oz soda).
    static let caloriesPerSugaryDrink = 150

    static func plan(for profile: UserProfile, projection: HealthProjection) -> NutritionPlan {
        let calorieTarget = calorieTarget(for: profile, maintenance: projection.maintenanceCalories)
        let protein = proteinRange(for: profile, bmi: projection.currentBMI)
        let fiber = Int((Double(calorieTarget) / 1000 * 14).rounded())  // 14 g per 1,000 calories

        var tips: [NutritionTip] = []
        tips += calorieTips(profile, maintenance: projection.maintenanceCalories, target: calorieTarget)
        tips += proteinTips(profile, target: protein)
        tips += habitTips(profile, fiberTarget: fiber)
        tips += trainingTips(profile)
        tips += dietPreferenceTips(profile)
        tips += doingWellTips(profile, proteinTarget: protein)

        return NutritionPlan(
            calorieTarget: calorieTarget,
            proteinGrams: protein,
            fiberGrams: fiber,
            tips: tips.sorted { $0.priority < $1.priority }
        )
    }

    // MARK: - Targets

    /// Lowest daily calories we'll ever suggest without a doctor.
    static func calorieFloor(for sex: Sex) -> Int {
        sex == .male ? 1500 : 1200
    }

    static func calorieTarget(for profile: UserProfile, maintenance: Int) -> Int {
        let target: Int

        switch profile.goal {
        case .loseWeight:
            // Teens are still growing, so keep the deficit small.
            target = maintenance - (profile.age < 18 ? 250 : 500)
        case .buildMuscle:
            target = maintenance + 300
        case .maintain, .generalHealth:
            target = maintenance
        }

        let rounded = Int((Double(target) / 50).rounded()) * 50
        return max(rounded, calorieFloor(for: profile.sex))
    }

    /// Grams of protein per day. Based on body weight, but for BMI 30+ we use
    /// the weight at BMI 25 so the number doesn't get unrealistically high.
    static func proteinRange(for profile: UserProfile, bmi: Double) -> ClosedRange<Int> {
        var referencePounds = profile.weightPounds
        if bmi >= 30 {
            referencePounds = profile.weightPounds * 25 / bmi
        }

        let gramsPerPound: ClosedRange<Double>
        switch profile.goal {
        case .loseWeight, .buildMuscle:
            gramsPerPound = 0.7...1.0  // ISSN: 1.6-2.2 g/kg
        case .maintain, .generalHealth:
            gramsPerPound = profile.strengthDaysPerWeek > 0 ? 0.6...0.8 : 0.4...0.6
        }

        let low = Int((referencePounds * gramsPerPound.lowerBound / 5).rounded()) * 5
        let high = Int((referencePounds * gramsPerPound.upperBound / 5).rounded()) * 5
        return low...high
    }

    // MARK: - Calories

    private static func calorieTips(_ profile: UserProfile, maintenance: Int, target: Int) -> [NutritionTip] {
        var tips: [NutritionTip] = []
        let eating = profile.dailyCalories
        let floor = calorieFloor(for: profile.sex)

        switch profile.goal {
        case .loseWeight:
            if eating > maintenance + 100 {
                tips.append(NutritionTip(
                    priority: .high, icon: "exclamationmark.triangle.fill",
                    title: "You're eating more than you burn",
                    detail: "At \(eating) cal/day that's about \(eating - maintenance) more than your body burns, so you'd gain weight. Aim for about \(target) cal/day."
                ))
            } else if eating < floor {
                tips.append(NutritionTip(
                    priority: .high, icon: "exclamationmark.triangle.fill",
                    title: "You may be eating too little",
                    detail: "Going under \(floor) cal/day makes it hard to get enough nutrients and can cost you muscle. Try about \(target) cal/day instead."
                ))
            } else if eating > target + 100 {
                tips.append(NutritionTip(
                    priority: .medium, icon: "arrow.down.circle",
                    title: "Trim about \(eating - target) calories a day",
                    detail: "\(eating >= maintenance ? "You're eating about what your body burns, so your weight would stay the same." : "You're eating only a little less than your body burns.") Cutting to about \(target) cal/day means roughly 1 lb lost per week."
                ))
            }

            if profile.targetWeightPounds < profile.weightPounds {
                let poundsToLose = profile.weightPounds - profile.targetWeightPounds
                let weeklyLoss = Double(maintenance - target) * 7 / 3500
                if weeklyLoss > 0 {
                    let weeks = Int((poundsToLose / weeklyLoss).rounded(.up))
                    tips.append(NutritionTip(
                        priority: .low, icon: "calendar",
                        title: "Timeline to \(Int(profile.targetWeightPounds)) lb",
                        detail: "At \(target) cal/day you'd lose about \(String(format: "%.1f", weeklyLoss)) lb/week, reaching your target in roughly \(weeks) weeks."
                    ))
                }
            }

        case .buildMuscle:
            if eating < maintenance {
                tips.append(NutritionTip(
                    priority: .high, icon: "exclamationmark.triangle.fill",
                    title: "Eat more to build muscle",
                    detail: "You're eating about \(maintenance - eating) cal/day less than your body burns. Building muscle needs a little extra food, so aim for about \(target) cal/day."
                ))
            } else if eating > maintenance + 600 {
                tips.append(NutritionTip(
                    priority: .medium, icon: "arrow.down.circle",
                    title: "You're eating more extra than you need",
                    detail: "Eating \(eating - maintenance) more than your body burns adds more fat than muscle. About \(target) cal/day is enough to build muscle without much fat."
                ))
            }

            if profile.strengthDaysPerWeek < 2 {
                tips.append(NutritionTip(
                    priority: .high, icon: "dumbbell.fill",
                    title: "Add strength training",
                    detail: "Extra calories and protein only turn into muscle if you challenge your muscles with weights or bodyweight exercises. Aim for at least 2-3 strength days a week."
                ))
            }

        case .maintain, .generalHealth:
            if abs(eating - maintenance) > 300 {
                let direction = eating > maintenance ? "more than" : "less than"
                tips.append(NutritionTip(
                    priority: .medium, icon: "scalemass",
                    title: "Your calories don't match your goal",
                    detail: "You're eating about \(abs(eating - maintenance)) cal/day \(direction) what your body burns. Around \(target) cal/day keeps your weight steady."
                ))
            }
        }

        return tips
    }

    // MARK: - Eating habits
    //
    // Each topic gets ONE tip that combines the user's answers (the counters)
    // with anything they typed about their meals, so tips never contradict.

    /// Protein estimate from the "protein servings a day" answer.
    static func estimatedProtein(for profile: UserProfile) -> Int {
        profile.proteinServingsPerDay * gramsPerProteinServing
    }

    private static func proteinTips(_ profile: UserProfile, target: ClosedRange<Int>) -> [NutritionTip] {
        let meals = profile.mealInsights
        let estimate = estimatedProtein(for: profile)
        let missing = meals.mealsWithoutProtein.isEmpty
            ? ""
            : " From what you typed, your \(list(meals.mealsWithoutProtein)) \(meals.mealsWithoutProtein.count == 1 ? "doesn't" : "don't") seem to have any, so start there."
        let sources = " Good sources for you: \(proteinSources(for: profile.dietPreference))."

        if estimate < target.lowerBound {
            let servingsNeeded = Int((Double(target.lowerBound) / Double(gramsPerProteinServing)).rounded(.up))
            let priority: NutritionTip.Priority =
                (profile.goal == .loseWeight || profile.goal == .buildMuscle) ? .high : .medium
            return [NutritionTip(
                priority: priority, icon: "fork.knife",
                title: "Eat more protein",
                detail: "Your goal is \(target.lowerBound)-\(target.upperBound) g of protein a day, so aim for about \(servingsNeeded) servings (\(gramsPerProteinServing) g each) a day, spread across your meals.\(missing)\(sources)"
            )]
        }

        if !meals.mealsWithoutProtein.isEmpty {
            return [NutritionTip(
                priority: .low, icon: "fork.knife",
                title: "Spread protein across your meals",
                detail: "You're close to your \(target.lowerBound)-\(target.upperBound) g goal.\(missing)\(sources)"
            )]
        }

        return []
    }

    private static func proteinSources(for diet: DietPreference) -> String {
        switch diet {
        case .noPreference: return "chicken, fish, eggs, Greek yogurt, lean beef, beans"
        case .vegetarian: return "eggs, Greek yogurt, cottage cheese, tofu, lentils, tempeh"
        case .vegan: return "tofu, tempeh, lentils, edamame, seitan, pea protein"
        case .dairyFree: return "chicken, fish, eggs, tofu, beans, lean beef"
        }
    }

    private static func habitTips(_ profile: UserProfile, fiberTarget: Int) -> [NutritionTip] {
        let meals = profile.mealInsights
        var tips: [NutritionTip] = []

        // Fruits & vegetables
        let produce = meals.foods(in: .fruit) + meals.foods(in: .vegetables)
        if profile.fruitVegServingsPerDay < 5 {
            var detail = "You said you eat \(profile.fruitVegServingsPerDay) servings of fruits/vegetables a day; aim for 5+. That helps you reach about \(fiberTarget) g of fiber, which keeps you full longer."
            if !produce.isEmpty {
                detail += " You already eat \(list(produce)), so keep \(produce.count == 1 ? "it" : "them") and add one more fruit or vegetable to each meal."
            } else if meals.hasAnyText {
                detail += " We didn't see any in the foods you listed, so try adding one to each meal (fruit at breakfast, a side salad, veggies at dinner)."
            } else {
                detail += " Easy adds: berries, apples, carrots, spinach, broccoli."
            }
            tips.append(NutritionTip(
                priority: profile.fruitVegServingsPerDay < 3 ? .medium : .low, icon: "leaf.fill",
                title: "Eat more fruits and vegetables", detail: detail
            ))
        }

        // Sugary drinks
        let drinks = meals.foods(in: .sugaryDrinks)
        if profile.sugaryDrinksPerDay >= 1 || !drinks.isEmpty {
            var detail: String
            if profile.sugaryDrinksPerDay >= 1 {
                let calories = profile.sugaryDrinksPerDay * caloriesPerSugaryDrink
                detail = "\(profile.sugaryDrinksPerDay) sugary drink\(profile.sugaryDrinksPerDay == 1 ? "" : "s") a day adds about \(calories) calories of sugar with no protein or fiber."
                if !drinks.isEmpty {
                    detail += " (You mentioned \(list(drinks)).)"
                }
            } else {
                detail = "You said 0 sugary drinks a day, but you mentioned \(list(drinks)). Drinks like these count too and add 100-250 calories each."
            }
            detail += " Swap for water, sparkling water, or zero-sugar drinks."
            tips.append(NutritionTip(
                priority: profile.sugaryDrinksPerDay >= 2 || drinks.count >= 2 ? .medium : .low, icon: "cup.and.saucer.fill",
                title: "Cut back on sugary drinks", detail: detail
            ))
        }

        // Fast & fried food
        let friedOrFast = meals.foods(in: .friedOrFastFood)
        if profile.fastFoodMealsPerWeek >= 3 || !friedOrFast.isEmpty {
            var detail = profile.fastFoodMealsPerWeek >= 3
                ? "\(profile.fastFoodMealsPerWeek) fast food meals a week adds a lot of calories, salt, and unhealthy fat. Try cutting to 1-2."
                : "Fried and fast foods are high in calories, salt, and unhealthy fat."
            if !friedOrFast.isEmpty {
                detail += " You mentioned \(list(friedOrFast)); try grilled, baked, or air-fried versions, or make them at home."
            } else {
                detail += " When you do eat out, pick grilled options and skip the fries and soda."
            }
            tips.append(NutritionTip(
                priority: .medium, icon: "takeoutbag.and.cup.and.straw.fill",
                title: "Cut back on fast and fried food", detail: detail
            ))
        }

        // Things only the typed meals can tell us
        let sweets = meals.foods(in: .sweets)
        if !sweets.isEmpty {
            tips.append(NutritionTip(
                priority: .low, icon: "birthday.cake.fill",
                title: "Keep sweets small",
                detail: "You mentioned \(list(sweets)). You don't have to cut them out. Keep portions small, and have them after a meal with protein so they don't spike your hunger."
            ))
        }

        let processed = meals.foods(in: .processedMeat)
        if !processed.isEmpty {
            tips.append(NutritionTip(
                priority: .low, icon: "exclamationmark.circle",
                title: "Go easy on processed meat",
                detail: "You mentioned \(list(processed)). These are very salty and linked to heart disease when eaten often. Chicken, turkey, fish, or eggs are better everyday picks."
            ))
        }

        if !meals.foods(in: .refinedCarbs).isEmpty && meals.foods(in: .wholeGrains).isEmpty {
            tips.append(NutritionTip(
                priority: .low, icon: "arrow.triangle.swap",
                title: "Try whole-grain swaps",
                detail: "You mentioned \(list(meals.foods(in: .refinedCarbs))). Whole-grain versions (brown rice, whole-wheat bread or pasta, oats) have more fiber, so they keep you full longer."
            ))
        }

        if profile.goal == .loseWeight && profile.sleepHours < 7 {
            tips.append(NutritionTip(
                priority: .low, icon: "bed.double.fill",
                title: "Sleep affects hunger",
                detail: "Less than 7 hours of sleep raises hunger hormones and cravings, which makes eating less harder to stick to."
            ))
        }

        if profile.age < 18 && profile.goal == .loseWeight {
            tips.append(NutritionTip(
                priority: .medium, icon: "person.2.fill",
                title: "Check in with a doctor or parent",
                detail: "Your body is still growing, so keep changes gradual and talk to a doctor or trusted adult before dieting."
            ))
        }

        return tips
    }

    // MARK: - Training

    private static func trainingTips(_ profile: UserProfile) -> [NutritionTip] {
        var tips: [NutritionTip] = []

        if profile.weeklyCardioMinutes >= 150 {
            tips.append(NutritionTip(
                priority: .low, icon: "figure.run",
                title: "Fuel your cardio with carbs",
                detail: "With \(profile.weeklyCardioMinutes) min of cardio a week, carbs like oats, rice, fruit, or potatoes 1-3 hours before training will improve your energy and performance."
            ))
        }

        let totalMinutes = profile.activities.reduce(0) { $0 + $1.weeklyMinutes }
        if totalMinutes >= 300 {
            tips.append(NutritionTip(
                priority: .low, icon: "drop.fill",
                title: "Drink extra water on training days",
                detail: "You train about \(totalMinutes) min a week. Add roughly 16-24 oz of water for each hour of exercise."
            ))
        }

        return tips
    }

    // MARK: - What's already working

    private static func doingWellTips(_ profile: UserProfile, proteinTarget: ClosedRange<Int>) -> [NutritionTip] {
        let meals = profile.mealInsights
        var good: [String] = []

        if estimatedProtein(for: profile) >= proteinTarget.lowerBound {
            good.append("you're getting enough protein")
        } else if !meals.foods(in: .protein).isEmpty {
            good.append("\(list(meals.foods(in: .protein))) \(meals.foods(in: .protein).count == 1 ? "is a" : "are") good protein \(meals.foods(in: .protein).count == 1 ? "source" : "sources")")
        }
        if profile.fruitVegServingsPerDay >= 5 {
            good.append("you eat 5+ servings of fruits and vegetables")
        }
        if profile.sugaryDrinksPerDay == 0 && meals.foods(in: .sugaryDrinks).isEmpty {
            good.append("you skip sugary drinks")
        }
        if !meals.foods(in: .wholeGrains).isEmpty {
            good.append("\(list(meals.foods(in: .wholeGrains))) for whole grains")
        }
        if !meals.foods(in: .healthyFats).isEmpty {
            good.append("\(list(meals.foods(in: .healthyFats))) for healthy fats")
        }

        guard !good.isEmpty else { return [] }
        return [NutritionTip(
            priority: .good, icon: "checkmark.circle.fill",
            title: "What you're doing well",
            detail: good.map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined(separator: ". ") + "."
        )]
    }

    /// "a", "a and b", "a, b, and c"
    private static func list(_ items: [String]) -> String {
        switch items.count {
        case 0: return ""
        case 1: return items[0]
        case 2: return "\(items[0]) and \(items[1])"
        default: return items.dropLast().joined(separator: ", ") + ", and " + items.last!
        }
    }

    // MARK: - Diet preference

    private static func dietPreferenceTips(_ profile: UserProfile) -> [NutritionTip] {
        switch profile.dietPreference {
        case .noPreference:
            return []
        case .vegetarian:
            return [NutritionTip(
                priority: .low, icon: "carrot.fill",
                title: "Watch iron and B12",
                detail: "Plant iron absorbs better with vitamin C (e.g. beans with peppers or citrus). Eggs and dairy help with B12."
            )]
        case .vegan:
            return [NutritionTip(
                priority: .medium, icon: "carrot.fill",
                title: "Cover B12, iron, and omega-3",
                detail: "B12 only comes from fortified foods or a supplement. Pair iron-rich foods with vitamin C, and get omega-3s from chia, flax, walnuts, or algae oil."
            )]
        case .dairyFree:
            return [NutritionTip(
                priority: .low, icon: "carrot.fill",
                title: "Get calcium and vitamin D elsewhere",
                detail: "Choose fortified soy or oat milk, leafy greens, tofu made with calcium, or canned salmon with bones."
            )]
        }
    }
}
