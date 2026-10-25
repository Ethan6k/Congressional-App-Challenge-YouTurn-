import SwiftUI
import Combine

class UserProfile: ObservableObject {

    // About you
    @Published var name: String = ""
    @Published var age: Int = 18
    @Published var sex: Sex = .male
    @Published var heightInches: Double = 68
    @Published var weightPounds: Double = 170

    // Habits
    @Published var activities: [ExerciseActivity] = [
        ExerciseActivity(type: .running, intensity: .moderate, daysPerWeek: 2, minutesPerSession: 30)
    ]
    @Published var sleepHours: Double = 8.0
    @Published var stress: Int = 5

    // Eating habits
    @Published var dailyCalories: Int = 2200
    /// Servings of about 25 g of protein each.
    @Published var proteinServingsPerDay: Int = 2
    @Published var fruitVegServingsPerDay: Int = 3
    @Published var fastFoodMealsPerWeek: Int = 2
    @Published var sugaryDrinksPerDay: Int = 1

    // Optional: foods they eat often, one bubble each
    @Published var foods: [String] = []

    // Goals
    @Published var goal: FitnessGoal = .generalHealth
    @Published var targetWeightPounds: Double = 170
    @Published var workoutLocation: WorkoutLocation = .commercialGym
    @Published var experience: Experience = .beginner
    @Published var trainingDaysAvailable: Int = 3
    @Published var minutesPerWorkout: Int = 45
    @Published var dietPreference: DietPreference = .noPreference

    // Future visualization
    @Published var visualizeMonths: Int = 12
    /// The reference photo they uploaded (stored in the gallery).
    @Published var referencePhotoID: UUID?
    /// The pair of generated images for each time frame (in months), stored
    /// in the gallery. A time frame with no entry shows empty image boxes.
    @Published var imageBatchByHorizon: [Int: UUID] = [:]

    /// True once they've finished the questions and seen their results.
    @Published var hasCompletedSetup = false
    /// True once they've finished (or skipped) the guided tour.
    @Published var hasSeenTutorial = false
    /// True once they've agreed to send their info (and photo) to Google's
    /// Gemini to make images. Asked before anything is sent the first time.
    @Published var hasAgreedToImageSharing = false

    private var autosave: AnyCancellable?

    /// - Parameter loadSaved: false makes a blank profile with default answers.
    init(loadSaved: Bool = true) {
        guard loadSaved else { return }
        load()
        // Save automatically shortly after any change.
        autosave = objectWillChange
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.save() }
    }

    /// Erases every answer and goes back to the defaults (and the welcome screen).
    func resetAll() {
        apply(UserProfile(loadSaved: false).saved)
        save()
    }

    var mealInsights: MealInsights {
        // The food list isn't split into meals, so it's checked like snacks
        // (no "this meal has no protein" warning).
        MealAnalyzer.analyze([("snacks", foods.joined(separator: ", "))])
    }

    var weightKilograms: Double { weightPounds * 0.45359237 }

    /// Extra calories burned by workouts, averaged over a day.
    var exerciseCaloriesPerDay: Double {
        activities.caloriesPerDay(weightKilograms: weightKilograms)
    }

    /// Minutes per week that count toward the CDC's 150-minute guideline.
    var weeklyGuidelineMinutes: Int { activities.guidelineMinutes }

    /// Days per week of strength training (capped at 7).
    var strengthDaysPerWeek: Int { activities.strengthDaysPerWeek }

    /// Weekly minutes of cardio-style training (running, cycling, swimming, HIIT, sports).
    var weeklyCardioMinutes: Int { activities.cardioMinutes }

    /// Plain-English exercise description, used in the AI image prompt.
    var exerciseSummary: String { activities.summary }

    /// How their training should show up in the future image.
    var bodyCompositionHint: String { activities.bodyCompositionHint }

    // MARK: - Saving and loading

    /// Everything we save to the phone, as one JSON file.
    private struct SavedProfile: Codable {
        var name: String
        var age: Int
        var sex: Sex
        var heightInches: Double
        var weightPounds: Double
        var activities: [ExerciseActivity]
        var sleepHours: Double
        var stress: Int
        var dailyCalories: Int
        var proteinMealsPerDay: Int  // older name, kept so saved profiles still load
        var fruitVegServingsPerDay: Int
        var fastFoodMealsPerWeek: Int
        var sugaryDrinksPerDay: Int
        var foods: [String]?  // optional so profiles saved before this existed still load
        var goal: FitnessGoal
        var targetWeightPounds: Double
        var workoutLocation: WorkoutLocation
        var experience: Experience
        var trainingDaysAvailable: Int
        var minutesPerWorkout: Int
        var dietPreference: DietPreference
        var visualizeMonths: Int
        var referencePhotoID: UUID?
        var imageBatchByHorizon: [Int: UUID]?  // optional so older saved profiles still load
        var hasCompletedSetup: Bool
        var hasSeenTutorial: Bool?  // optional so older saved profiles still load
        var hasAgreedToImageSharing: Bool?  // optional so older saved profiles still load
    }

    private static var fileURL: URL {
        URL.applicationSupportDirectory.appending(path: "profile.json")
    }

    func save() {
        do {
            try FileManager.default.createDirectory(at: URL.applicationSupportDirectory, withIntermediateDirectories: true)
            // Encrypted by iOS while the phone is locked.
            try JSONEncoder().encode(saved).write(to: Self.fileURL, options: [.atomic, .completeFileProtectionUnlessOpen])
        } catch {
            print("Could not save profile: \(error)")
        }
    }

    private var saved: SavedProfile {
        SavedProfile(
            name: name, age: age, sex: sex, heightInches: heightInches, weightPounds: weightPounds,
            activities: activities, sleepHours: sleepHours, stress: stress,
            dailyCalories: dailyCalories, proteinMealsPerDay: proteinServingsPerDay,
            fruitVegServingsPerDay: fruitVegServingsPerDay, fastFoodMealsPerWeek: fastFoodMealsPerWeek,
            sugaryDrinksPerDay: sugaryDrinksPerDay,
            foods: foods,
            goal: goal, targetWeightPounds: targetWeightPounds, workoutLocation: workoutLocation,
            experience: experience, trainingDaysAvailable: trainingDaysAvailable,
            minutesPerWorkout: minutesPerWorkout, dietPreference: dietPreference,
            visualizeMonths: visualizeMonths, referencePhotoID: referencePhotoID,
            imageBatchByHorizon: imageBatchByHorizon, hasCompletedSetup: hasCompletedSetup,
            hasSeenTutorial: hasSeenTutorial,
            hasAgreedToImageSharing: hasAgreedToImageSharing
        )
    }

    private func load() {
        guard let data = try? Data(contentsOf: Self.fileURL),
              let saved = try? JSONDecoder().decode(SavedProfile.self, from: data) else {
            return  // First launch: keep the defaults.
        }
        apply(saved)
    }

    private func apply(_ saved: SavedProfile) {
        name = saved.name
        age = saved.age
        sex = saved.sex
        heightInches = saved.heightInches
        weightPounds = saved.weightPounds
        activities = saved.activities
        sleepHours = saved.sleepHours
        stress = saved.stress
        dailyCalories = saved.dailyCalories
        proteinServingsPerDay = saved.proteinMealsPerDay
        fruitVegServingsPerDay = saved.fruitVegServingsPerDay
        fastFoodMealsPerWeek = saved.fastFoodMealsPerWeek
        sugaryDrinksPerDay = saved.sugaryDrinksPerDay
        foods = saved.foods ?? []
        goal = saved.goal
        targetWeightPounds = saved.targetWeightPounds
        workoutLocation = saved.workoutLocation
        experience = saved.experience
        trainingDaysAvailable = saved.trainingDaysAvailable
        minutesPerWorkout = saved.minutesPerWorkout
        dietPreference = saved.dietPreference
        visualizeMonths = saved.visualizeMonths
        referencePhotoID = saved.referencePhotoID
        imageBatchByHorizon = saved.imageBatchByHorizon ?? [:]
        hasCompletedSetup = saved.hasCompletedSetup
        hasSeenTutorial = saved.hasSeenTutorial ?? false
        hasAgreedToImageSharing = saved.hasAgreedToImageSharing ?? false
    }

}
