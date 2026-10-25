//
//  WorkoutPlanner.swift
//  TestApp
//
//  Builds a weekly workout plan from the user's goal, schedule, experience,
//  where they work out, and their current habits. Rule-based (no AI): it
//  walks a decision tree and records each decision so the app can show the
//  path ("flowchart") and explain why the plan fits.
//

import Foundation

struct PlannedExercise: Identifiable {
    let id = UUID()
    let name: String
    let sets: Int
    let reps: String
}

struct WorkoutDay: Identifiable {
    enum Kind { case strength, cardio, rest }

    let id = UUID()
    let weekday: String
    let kind: Kind
    let name: String
    let exercises: [PlannedExercise]
    /// Plain-English instructions (cardio details, finishers, warm-up).
    let notes: [String]
}

struct PlanDecision: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

struct WorkoutPlan {
    let title: String
    let days: [WorkoutDay]
    let decisions: [PlanDecision]
    let reasons: [String]
    let howTo: [String]
    /// The plan's workouts as activities, so the app can project
    /// "what if you followed this plan".
    let activities: [ExerciseActivity]
}

enum WorkoutPlanner {

    // MARK: - Building blocks

    /// The basic movements every plan is built from.
    enum Movement {
        case squat, hinge, horizontalPush, verticalPush, horizontalPull, verticalPull
        case singleLeg, core, biceps, triceps, calves

        var isCompound: Bool {
            switch self {
            case .squat, .hinge, .horizontalPush, .verticalPush, .horizontalPull, .verticalPull, .singleLeg:
                return true
            case .core, .biceps, .triceps, .calves:
                return false
            }
        }
    }

    /// What equipment the exercises can use.
    enum Equipment {
        case fullGym, homeGym, dumbbells, bodyweight, outdoors
    }

    static func equipment(for location: WorkoutLocation) -> Equipment {
        switch location {
        case .commercialGym: return .fullGym
        case .homeGym: return .homeGym
        case .homeDumbbells, .classes: return .dumbbells
        case .homeNoEquipment: return .bodyweight
        case .outdoors: return .outdoors
        }
    }

    /// The exercise to use for a movement, given equipment and experience.
    static func exercise(for movement: Movement, equipment: Equipment, experience: Experience) -> String {
        let beginner = experience == .beginner

        switch (movement, equipment) {
        // Squat
        case (.squat, .fullGym): return beginner ? "Goblet squat" : "Barbell back squat"
        case (.squat, .homeGym): return beginner ? "Goblet squat (dumbbell or plate)" : "Barbell back squat"
        case (.squat, .dumbbells): return "Goblet squat"
        case (.squat, .bodyweight), (.squat, .outdoors): return beginner ? "Bodyweight squat" : "Jump squat"

        // Hinge
        case (.hinge, .fullGym), (.hinge, .homeGym): return beginner ? "Dumbbell Romanian deadlift" : "Barbell Romanian deadlift"
        case (.hinge, .dumbbells): return "Dumbbell Romanian deadlift"
        case (.hinge, .bodyweight), (.hinge, .outdoors): return beginner ? "Glute bridge" : "Single-leg glute bridge"

        // Horizontal push
        case (.horizontalPush, .fullGym), (.horizontalPush, .homeGym): return beginner ? "Dumbbell bench press" : "Barbell bench press"
        case (.horizontalPush, .dumbbells): return "Dumbbell floor press"
        case (.horizontalPush, .bodyweight), (.horizontalPush, .outdoors): return beginner ? "Incline push-up (hands on a bench or couch)" : "Push-up"

        // Vertical push
        case (.verticalPush, .fullGym), (.verticalPush, .dumbbells): return "Dumbbell shoulder press"
        case (.verticalPush, .homeGym): return beginner ? "Dumbbell shoulder press" : "Barbell overhead press"
        case (.verticalPush, .bodyweight), (.verticalPush, .outdoors): return beginner ? "Pike push-up (knees bent)" : "Pike push-up"

        // Horizontal pull
        case (.horizontalPull, .fullGym): return "Seated cable row"
        case (.horizontalPull, .homeGym): return beginner ? "One-arm dumbbell row" : "Barbell row"
        case (.horizontalPull, .dumbbells): return "One-arm dumbbell row"
        case (.horizontalPull, .bodyweight): return "Table row (lie under a sturdy table and pull up)"
        case (.horizontalPull, .outdoors): return "Inverted row on a low bar"

        // Vertical pull
        case (.verticalPull, .fullGym): return beginner ? "Lat pulldown" : "Pull-up (or lat pulldown)"
        case (.verticalPull, .homeGym), (.verticalPull, .outdoors): return beginner ? "Negative pull-up (jump up, lower slowly)" : "Pull-up"
        case (.verticalPull, .dumbbells): return "Resistance band pulldown (or dumbbell pullover)"
        case (.verticalPull, .bodyweight): return "Doorway row (hold a door frame and pull)"

        // Single leg
        case (.singleLeg, .fullGym), (.singleLeg, .homeGym), (.singleLeg, .dumbbells):
            return beginner ? "Dumbbell reverse lunge" : "Bulgarian split squat"
        case (.singleLeg, .bodyweight), (.singleLeg, .outdoors):
            return beginner ? "Reverse lunge" : "Bulgarian split squat (back foot on a bench)"

        // Core
        case (.core, .fullGym): return beginner ? "Plank" : "Cable crunch"
        case (.core, .homeGym), (.core, .outdoors): return beginner ? "Plank" : "Hanging knee raise"
        case (.core, .dumbbells), (.core, .bodyweight): return beginner ? "Plank" : "Dead bug"

        // Arms
        case (.biceps, .fullGym), (.biceps, .dumbbells): return "Dumbbell curl"
        case (.biceps, .homeGym): return "Barbell curl"
        case (.biceps, .bodyweight): return "Towel curl (pull against your foot)"
        case (.biceps, .outdoors): return "Chin-up"
        case (.triceps, .fullGym): return "Cable triceps pushdown"
        case (.triceps, .homeGym), (.triceps, .dumbbells): return "Dumbbell overhead triceps extension"
        case (.triceps, .bodyweight): return "Diamond push-up"
        case (.triceps, .outdoors): return "Bench dip"

        // Calves
        case (.calves, _): return equipment == .bodyweight || equipment == .outdoors ? "Single-leg calf raise" : "Dumbbell calf raise"
        }
    }

    // Workout templates (which movements go on which day)
    static let fullBodyA: [Movement] = [.squat, .horizontalPush, .horizontalPull, .hinge, .core, .triceps]
    static let fullBodyB: [Movement] = [.hinge, .verticalPush, .verticalPull, .singleLeg, .core, .biceps]
    static let fullBodyC: [Movement] = [.squat, .horizontalPush, .verticalPull, .singleLeg, .core, .calves]
    static let upper: [Movement] = [.horizontalPush, .horizontalPull, .verticalPush, .verticalPull, .biceps, .triceps]
    static let lower: [Movement] = [.squat, .hinge, .singleLeg, .calves, .core]
    static let push: [Movement] = [.horizontalPush, .verticalPush, .triceps, .core]
    static let pull: [Movement] = [.verticalPull, .horizontalPull, .biceps, .core]
    static let legs: [Movement] = [.squat, .hinge, .singleLeg, .calves]

    // MARK: - The decision tree

    static func plan(for profile: UserProfile, bmi: Double) -> WorkoutPlan {
        var decisions: [PlanDecision] = []
        var reasons: [String] = []

        let days = profile.trainingDaysAvailable
        let gear = equipment(for: profile.workoutLocation)

        // 1. Where do you work out? -> which exercises
        decisions.append(PlanDecision(question: "Where do you work out?", answer: profile.workoutLocation.label))
        reasons.append(locationReason(profile.workoutLocation))

        // 2. What's your goal? + how many days -> strength vs. cardio days
        decisions.append(PlanDecision(question: "What's your goal?", answer: profile.goal.label))
        var strengthDays = strengthDayCount(goal: profile.goal, days: days)

        // 3. Experience -> beginners max 4 strength days, fewer sets
        decisions.append(PlanDecision(question: "How experienced are you?", answer: profile.experience.label))
        if profile.experience == .beginner && strengthDays > 4 {
            strengthDays = 4
        }
        let cardioDays = days - strengthDays
        decisions.append(PlanDecision(
            question: "How many days can you train?",
            answer: "\(days) days → \(strengthDays) strength + \(cardioDays) cardio"
        ))
        reasons.append(splitReason(goal: profile.goal, strengthDays: strengthDays, cardioDays: cardioDays))

        // 4. Split -> how strength days are organized
        let split = strengthSplit(strengthDays: strengthDays)
        decisions.append(PlanDecision(question: "Which workout style?", answer: split.name))
        reasons.append(split.reason)

        // 5. Sets, reps, and how many exercises fit in their time
        let sets = setsPerExercise(profile.experience)
        let reps = repRanges(profile.goal)
        let addsFinisher = (profile.goal == .loseWeight || profile.goal == .generalHealth) && profile.minutesPerWorkout >= 40
        let exerciseCount = exercisesPerWorkout(minutes: profile.minutesPerWorkout - (addsFinisher ? 10 : 0), experience: profile.experience)
        reasons.append(experienceReason(profile.experience, sets: sets))

        // 6. Cardio choice: keep what they already do, go low-impact if needed
        let lowImpact = bmi >= 30
        let cardio = cardioChoice(profile: profile, equipment: gear, lowImpact: lowImpact)
        if let why = cardio.reason {
            reasons.append(why)
        }

        if profile.sleepHours < 7 {
            reasons.append("You sleep under 7 hours. Muscles recover and grow during sleep, so getting 7-9 hours will help you see results faster.")
        }
        if profile.age >= 50 {
            reasons.append("At \(profile.age), balance and joint health matter more, so warm up for a full 10 minutes and add 5 minutes of stretching after each workout.")
        }

        // Build the week
        let schedule = weekSchedule(totalDays: days, cardioDays: cardioDays)
        var strengthIndex = 0
        var cardioIndex = 0
        var week: [WorkoutDay] = []

        for (weekday, slot) in schedule {
            switch slot {
            case .strength:
                let template = split.days[strengthIndex % split.days.count]
                strengthIndex += 1
                let exercises = template.movements.prefix(exerciseCount).map { movement in
                    PlannedExercise(
                        name: exercise(for: movement, equipment: gear, experience: profile.experience),
                        sets: sets,
                        reps: movement == .core && profile.experience == .beginner
                            ? "30-45 sec"
                            : (movement.isCompound ? reps.compound : reps.accessory)
                    )
                }
                var notes = ["Warm up for 5 minutes (light cardio + a lighter set of your first exercise)."]
                if addsFinisher {
                    notes.append("Finish with 10 minutes of \(cardio.finisher).")
                }
                week.append(WorkoutDay(weekday: weekday, kind: .strength, name: template.name, exercises: exercises, notes: notes))

            case .cardio:
                let session = cardioSession(
                    index: cardioIndex, cardio: cardio, minutes: profile.minutesPerWorkout,
                    goal: profile.goal, experience: profile.experience
                )
                cardioIndex += 1
                week.append(WorkoutDay(weekday: weekday, kind: .cardio, name: session.name, exercises: [], notes: session.notes))

            case .rest:
                let restNote = profile.goal == .loseWeight || profile.goal == .generalHealth
                    ? "Take it easy. A 20-30 minute walk helps you reach the CDC's 150 minutes of activity a week."
                    : "Take it easy. A walk or light stretching is great."
                week.append(WorkoutDay(
                    weekday: weekday, kind: .rest, name: "Rest & recover", exercises: [],
                    notes: [restNote]
                ))
            }
        }

        // The same week, described as activities for the projection math.
        let intensity: Intensity = profile.experience == .advanced ? .vigorous : .moderate
        var activities = [ExerciseActivity(
            type: gear == .bodyweight || gear == .outdoors ? .calisthenics : .weightlifting,
            intensity: intensity,
            daysPerWeek: strengthDays,
            minutesPerSession: profile.minutesPerWorkout - (addsFinisher ? 10 : 0)
        )]
        if addsFinisher {
            activities.append(ExerciseActivity(type: cardio.type, intensity: .moderate, daysPerWeek: strengthDays, minutesPerSession: 10))
        }
        if cardioDays > 0 {
            activities.append(ExerciseActivity(type: cardio.type, intensity: .moderate, daysPerWeek: cardioDays, minutesPerSession: profile.minutesPerWorkout))
        }

        let title = "\(days)-Day \(split.name)"
        return WorkoutPlan(
            title: title,
            days: week,
            decisions: decisions,
            reasons: reasons,
            howTo: howTo(goal: profile.goal, equipment: gear, reps: reps),
            activities: activities
        )
    }

    // MARK: - Decisions

    /// How many of the available days are strength training.
    static func strengthDayCount(goal: FitnessGoal, days: Int) -> Int {
        switch goal {
        case .buildMuscle:
            // Muscle needs lifting most; cardio kept light.
            return days
        case .loseWeight:
            // Lift to keep muscle while losing fat; add cardio days to burn more.
            return days <= 3 ? days : days - (days >= 5 ? 2 : 1)
        case .maintain:
            return min(days, 4)
        case .generalHealth:
            // CDC: strength 2+ days, plus 150 min of cardio.
            return days <= 3 ? 2 : (days == 4 ? 2 : 3)
        }
    }

    struct SplitDay {
        let name: String
        let movements: [Movement]
    }

    struct Split {
        let name: String
        let days: [SplitDay]
        let reason: String
    }

    static func strengthSplit(strengthDays: Int) -> Split {
        switch strengthDays {
        case ...3:
            return Split(
                name: "Full Body",
                days: [SplitDay(name: "Full Body A", movements: fullBodyA),
                       SplitDay(name: "Full Body B", movements: fullBodyB),
                       SplitDay(name: "Full Body C", movements: fullBodyC)],
                reason: "With \(strengthDays) strength days, full-body workouts hit every muscle \(strengthDays == 1 ? "each week" : "\(strengthDays) times a week"), which is the fastest way to build strength."
            )
        case 4:
            return Split(
                name: "Upper / Lower",
                days: [SplitDay(name: "Upper Body", movements: upper),
                       SplitDay(name: "Lower Body", movements: lower)],
                reason: "With 4 strength days, splitting upper and lower body lets each area rest while you train the other, and still hits everything twice a week."
            )
        case 5:
            return Split(
                name: "Upper / Lower + Push / Pull / Legs",
                days: [SplitDay(name: "Upper Body", movements: upper),
                       SplitDay(name: "Lower Body", movements: lower),
                       SplitDay(name: "Push (chest, shoulders, triceps)", movements: push),
                       SplitDay(name: "Pull (back, biceps)", movements: pull),
                       SplitDay(name: "Legs", movements: legs)],
                reason: "With 5 strength days, mixing upper/lower and push/pull/legs gives each muscle enough work and rest."
            )
        default:
            return Split(
                name: "Push / Pull / Legs",
                days: [SplitDay(name: "Push (chest, shoulders, triceps)", movements: push),
                       SplitDay(name: "Pull (back, biceps)", movements: pull),
                       SplitDay(name: "Legs", movements: legs)],
                reason: "With 6 strength days, push/pull/legs twice a week gives each muscle group lots of work with 2 days of rest in between."
            )
        }
    }

    static func setsPerExercise(_ experience: Experience) -> Int {
        switch experience {
        case .beginner: return 2
        case .intermediate: return 3
        case .advanced: return 4
        }
    }

    static func repRanges(_ goal: FitnessGoal) -> (compound: String, accessory: String, rest: String) {
        switch goal {
        case .buildMuscle: return ("6-10", "10-15", "1.5-2 min on big lifts, 1 min on the rest")
        case .loseWeight: return ("10-12", "12-15", "45-60 sec")
        case .maintain: return ("8-12", "10-15", "1-1.5 min")
        case .generalHealth: return ("10-15", "12-15", "1 min")
        }
    }

    /// About 2 minutes per set (doing it + resting), after a 5-minute warm-up,
    /// capped by experience.
    static func exercisesPerWorkout(minutes: Int, experience: Experience) -> Int {
        let sets = setsPerExercise(experience)
        let cap = experience == .beginner ? 5 : 6
        return max(3, min(cap, (minutes - 5) / (sets * 2)))
    }

    struct CardioChoice {
        let type: ExerciseType
        let name: String
        let finisher: String
        let reason: String?
    }

    static func cardioChoice(profile: UserProfile, equipment: Equipment, lowImpact: Bool) -> CardioChoice {
        // Keep cardio they already enjoy.
        let cardioTypes: [ExerciseType] = [.sports, .running, .cycling, .swimming, .hiit, .walking]
        if let favorite = cardioTypes.first(where: { type in profile.activities.contains { $0.type == type } }),
           !(lowImpact && (favorite == .running || favorite == .hiit)) {
            let name: String
            switch favorite {
            case .sports: name = "your sport"
            case .running: name = "running"
            case .cycling: name = "cycling"
            case .swimming: name = "swimming"
            case .hiit: name = "HIIT"
            default: name = "brisk walking"
            }
            return CardioChoice(
                type: favorite,
                name: name,
                finisher: favorite == .sports || favorite == .swimming ? "brisk walking or biking" : name,
                reason: "You already do \(favorite == .sports ? "sports" : name), so your cardio days use it. Sticking with exercise you enjoy is the best way to stay consistent."
            )
        }

        if lowImpact {
            let option = equipment == .fullGym ? "stationary bike or incline treadmill walk" : "brisk walking or biking"
            return CardioChoice(
                type: .cycling, name: option, finisher: option,
                reason: "Your cardio is low-impact (\(option)) to be easier on your knees and joints while you build fitness."
            )
        }

        switch equipment {
        case .fullGym:
            return CardioChoice(type: .running, name: "treadmill, bike, or rower", finisher: "incline treadmill walk or bike", reason: nil)
        case .outdoors:
            return CardioChoice(type: .running, name: "running or brisk walking", finisher: "running or brisk walking", reason: nil)
        default:
            if profile.workoutLocation == .classes {
                return CardioChoice(type: .cycling, name: "a spin or HIIT class", finisher: "jumping jacks and mountain climbers", reason: nil)
            }
            return CardioChoice(type: .walking, name: "brisk walk, jog, or bike", finisher: "jumping jacks, mountain climbers, and high knees", reason: nil)
        }
    }

    static func cardioSession(index: Int, cardio: CardioChoice, minutes: Int, goal: FitnessGoal, experience: Experience) -> (name: String, notes: [String]) {
        // Alternate steady sessions with intervals for non-beginners trying to lose weight.
        if goal == .loseWeight && experience != .beginner && index % 2 == 1 {
            let rounds = max(4, min(10, (minutes - 10) / 3))
            return ("Interval Cardio", [
                "Warm up 5 minutes, easy pace.",
                "\(rounds) rounds: 1 minute hard (hard to talk), 2 minutes easy. Use \(cardio.name).",
                "Cool down 5 minutes."
            ])
        }

        let intensity = experience == .beginner
            ? "moderate pace (you can talk, but not sing)"
            : "moderate to brisk pace"
        return ("Steady Cardio", [
            "\(minutes) minutes of \(cardio.name) at a \(intensity)."
        ])
    }

    enum Slot { case strength, cardio, rest }

    /// Spreads training days across the week, with cardio days between strength days.
    static func weekSchedule(totalDays: Int, cardioDays: Int) -> [(String, Slot)] {
        let weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        let trainingDayIndexes: [Int]
        switch totalDays {
        case ...2: trainingDayIndexes = [0, 3]
        case 3: trainingDayIndexes = [0, 2, 4]
        case 4: trainingDayIndexes = [0, 1, 3, 4]
        case 5: trainingDayIndexes = [0, 1, 2, 4, 5]
        default: trainingDayIndexes = [0, 1, 2, 3, 4, 5]
        }

        // Pick which training days are cardio, spaced out evenly.
        var cardioPositions = Set<Int>()
        for k in 0..<cardioDays {
            let position = Int((Double(k) + 0.5) * Double(trainingDayIndexes.count) / Double(cardioDays))
            cardioPositions.insert(min(position, trainingDayIndexes.count - 1))
        }

        return weekdays.enumerated().map { index, name in
            guard let position = trainingDayIndexes.firstIndex(of: index) else {
                return (name, .rest)
            }
            return (name, cardioPositions.contains(position) ? .cardio : .strength)
        }
    }

    // MARK: - Plain-English explanations

    static func locationReason(_ location: WorkoutLocation) -> String {
        switch location {
        case .commercialGym: return "You train at a gym, so the plan uses barbells, dumbbells, cables, and machines."
        case .homeGym: return "You have a home gym, so the plan is built around your barbell, bench, and rack."
        case .homeDumbbells: return "You train at home with dumbbells or bands, so every exercise uses those or your body weight."
        case .homeNoEquipment: return "You don't have equipment, so every exercise uses only your body weight and things around the house."
        case .outdoors: return "You train outdoors, so the plan uses bodyweight moves, park bars and benches, and running."
        case .classes: return "You go to classes, so your cardio days can be classes and strength days use dumbbells found at most studios."
        }
    }

    static func splitReason(goal: FitnessGoal, strengthDays: Int, cardioDays: Int) -> String {
        switch goal {
        case .loseWeight:
            return "To lose weight, \(strengthDays) days are strength training (to keep your muscle while you lose fat)\(cardioDays > 0 ? " and \(cardioDays) \(cardioDays == 1 ? "is" : "are") cardio (to burn extra calories)" : "")."
        case .buildMuscle:
            return "To build muscle, \(strengthDays == strengthDays + cardioDays ? "all" : "\(strengthDays)") of your training days are strength training. Muscle grows from lifting, plus enough food and protein."
        case .maintain:
            return "To maintain, you'll mix \(strengthDays) strength days\(cardioDays > 0 ? " with \(cardioDays) cardio \(cardioDays == 1 ? "day" : "days")" : "") to keep your current muscle and fitness."
        case .generalHealth:
            return "For overall health, the CDC recommends strength training at least 2 days a week plus 150 minutes of cardio, so you get \(strengthDays) strength days and \(cardioDays) cardio \(cardioDays == 1 ? "day" : "days")."
        }
    }

    static func experienceReason(_ experience: Experience, sets: Int) -> String {
        switch experience {
        case .beginner:
            return "As a beginner, you'll do \(sets) sets of each exercise using easier versions, so you can learn good form without getting too sore."
        case .intermediate:
            return "At an intermediate level, \(sets) sets per exercise gives your muscles enough challenge to keep improving."
        case .advanced:
            return "As an advanced lifter, \(sets) sets per exercise and harder exercise versions keep pushing your progress."
        }
    }

    static func howTo(goal: FitnessGoal, equipment: Equipment, reps: (compound: String, accessory: String, rest: String)) -> [String] {
        let progress = (equipment == .bodyweight || equipment == .outdoors)
            ? "When you can do the top number of reps for every set, make it harder: add reps, slow down, or move to a harder version."
            : "When you can do the top number of reps for every set, add a little weight next time."
        return [
            "\"3 × 8-12\" means 3 sets of 8 to 12 reps. Pick a weight where the last 2 reps feel hard but your form stays good.",
            "Rest \(reps.rest) between sets.",
            progress,
            "Sore for a day or two is normal. Sharp pain is not, so stop that exercise."
        ]
    }
}
