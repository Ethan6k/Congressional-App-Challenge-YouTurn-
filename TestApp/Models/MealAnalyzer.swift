//
//  MealAnalyzer.swift
//  TestApp
//
//  Reads what the user typed about their meals and picks out foods it
//  recognizes from a fixed word list (no AI, nothing sent online).
//

import Foundation

enum FoodCategory: CaseIterable {
    case protein, vegetables, fruit, wholeGrains, healthyFats
    case friedOrFastFood, sweets, sugaryDrinks, processedMeat, refinedCarbs

    /// Words that put a food in this category. Single words must match a whole
    /// word (plus a plain "s"/"es" plural); phrases match anywhere in the text.
    var keywords: [String] {
        switch self {
        case .protein:
            return ["chicken", "beef", "steak", "fish", "salmon", "tuna", "shrimp", "egg", "turkey",
                    "pork", "tofu", "tempeh", "bean", "lentil", "chickpea", "edamame", "seitan",
                    "greek yogurt", "cottage cheese", "protein shake", "protein bar", "protein powder"]
        case .vegetables:
            return ["salad", "broccoli", "spinach", "carrot", "vegetable", "veggie", "lettuce", "kale",
                    "pepper", "tomato", "cucumber", "green bean", "asparagus", "zucchini", "cauliflower",
                    "cabbage", "mushroom", "onion", "corn", "peas", "sweet potato", "brussels sprout"]
        case .fruit:
            return ["apple", "banana", "berry", "berries", "strawberry", "strawberries", "blueberry",
                    "blueberries", "orange", "grape", "fruit", "mango", "pineapple", "melon",
                    "watermelon", "peach", "pear", "kiwi", "cherry", "cherries"]
        case .wholeGrains:
            return ["oat", "oatmeal", "oats", "brown rice", "quinoa", "whole wheat", "whole grain",
                    "whole-wheat", "whole-grain", "barley"]
        case .healthyFats:
            return ["avocado", "nut", "almond", "walnut", "cashew", "peanut butter", "almond butter",
                    "olive oil", "seed", "chia", "flax"]
        case .friedOrFastFood:
            return ["fried", "fries", "chip", "nugget", "wing", "pizza", "burger", "cheeseburger",
                    "hot dog", "corn dog", "mcdonalds", "mcdonald's", "burger king", "wendys", "wendy's",
                    "taco bell", "kfc", "popeyes", "chick-fil-a", "five guys", "in-n-out", "dominos",
                    "domino's", "panda express", "fast food", "takeout", "drive-thru"]
        case .sweets:
            return ["candy", "cookie", "cake", "donut", "doughnut", "ice cream", "chocolate", "pastry",
                    "brownie", "pop-tart", "poptart", "muffin", "cupcake", "pie", "sugary cereal"]
        case .sugaryDrinks:
            return ["soda", "coke", "pepsi", "sprite", "dr pepper", "mountain dew", "energy drink",
                    "red bull", "monster", "sweet tea", "juice", "lemonade", "frappuccino", "boba",
                    "milkshake", "slushie", "gatorade"]
        case .processedMeat:
            return ["bacon", "sausage", "pepperoni", "salami", "deli meat", "ham", "jerky", "bologna"]
        case .refinedCarbs:
            return ["white bread", "white rice", "pasta", "bagel", "ramen", "mac and cheese",
                    "noodle", "spaghetti", "pancake", "waffle"]
        }
    }
}

struct MealInsights {
    /// Foods found in each category, in the words the user typed.
    let found: [FoodCategory: [String]]
    /// Meals (e.g. "breakfast") the user described that have no protein food.
    let mealsWithoutProtein: [String]
    let hasAnyText: Bool

    func foods(in category: FoodCategory) -> [String] {
        found[category] ?? []
    }
}

enum MealAnalyzer {

    static func analyze(_ meals: [(name: String, text: String)]) -> MealInsights {
        var found: [FoodCategory: [String]] = [:]
        var mealsWithoutProtein: [String] = []
        var hasAnyText = false

        for meal in meals {
            // Juice is a sugary drink, not a serving of fruit.
            let text = meal.text.lowercased()
                .replacingOccurrences(of: "orange juice", with: "juice")
                .replacingOccurrences(of: "apple juice", with: "juice")
            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
            hasAnyText = true

            let words = Set(text.components(separatedBy: CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "'-")).inverted))
            var mealHasProtein = false

            for category in FoodCategory.allCases {
                for keyword in category.keywords {
                    guard let food = match(keyword, text: text, words: words) else { continue }
                    if !(found[category] ?? []).contains(food) {
                        found[category, default: []].append(food)
                    }
                    if category == .protein {
                        mealHasProtein = true
                    }
                }
            }

            // Snacks don't need protein every time.
            if !mealHasProtein && meal.name != "snacks" {
                mealsWithoutProtein.append(meal.name)
            }
        }

        return MealInsights(found: found, mealsWithoutProtein: mealsWithoutProtein, hasAnyText: hasAnyText)
    }

    /// The food as the user wrote it (e.g. "chips" for keyword "chip"), or nil if not found.
    private static func match(_ keyword: String, text: String, words: Set<String>) -> String? {
        if keyword.contains(" ") {
            return text.contains(keyword) ? keyword : nil
        }
        return [keyword, keyword + "s", keyword + "es"].first { words.contains($0) }
    }
}
