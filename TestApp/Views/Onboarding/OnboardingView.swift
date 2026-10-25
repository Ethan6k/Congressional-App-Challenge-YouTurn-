//
//  OnboardingView.swift
//  TestApp
//
//  The 9 setup slides, one short topic each:
//    About you:  1 you
//    Habits:     2 workouts, 3 sleep & stress, 4 calories & protein,
//                5 fruit, veg & treats, 6 foods you eat often
//    Goals:      7 goal, 8 where you train, 9 schedule
//

import SwiftUI

struct OnboardingView: View {

    @EnvironmentObject var profile: UserProfile
    @Environment(\.dismiss) private var dismiss

    /// Called when they tap the button on the last slide.
    let onFinish: () -> Void

    @State private var step = 0
    @State private var goingForward = true

    private let slideCount = 9

    /// Which of the 3 progress bar sections this slide belongs to.
    private var section: Int {
        switch step {
        case 0: return 0
        case 1...5: return 1
        default: return 2
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            currentSlide
                .id(step)
                .transition(.push(from: goingForward ? .trailing : .leading))
        }
        .themedScreen()
        .toolbar(.hidden, for: .navigationBar)
        .keyboardDoneButton()
        .onChange(of: profile.goal) {
            // Start the target near their current weight in the right direction.
            switch profile.goal {
            case .loseWeight:
                profile.targetWeightPounds = (profile.weightPounds - 10).rounded()
            case .buildMuscle:
                profile.targetWeightPounds = (profile.weightPounds + 10).rounded()
            default:
                profile.targetWeightPounds = profile.weightPounds
            }
        }
    }

    // MARK: - Header (back button + progress)

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Button(action: goBack) {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Back")

                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Capsule()
                            .fill(index <= section ? Theme.amber : Theme.cardRaised)
                            .frame(height: 6)
                    }
                }
                .animation(.easeOut, value: section)
                .accessibilityElement()
                .accessibilityLabel("Step \(step + 1) of \(slideCount)")
            }

            Text("\(step + 1) / \(slideCount)")
                .font(.caption)
                .foregroundStyle(Theme.textMuted)
                .padding(.leading, 44)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Moving between slides

    private func goNext() {
        hideKeyboard()
        if step == slideCount - 1 {
            onFinish()
            return
        }
        goingForward = true
        withAnimation(.easeInOut(duration: 0.3)) { step += 1 }
    }

    private func goBack() {
        hideKeyboard()
        if step == 0 {
            dismiss()
            return
        }
        goingForward = false
        withAnimation(.easeInOut(duration: 0.3)) { step -= 1 }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // MARK: - Slides

    @ViewBuilder
    private var currentSlide: some View {
        switch step {
        case 0: aboutYou
        case 1: WorkoutsSlide(onContinue: goNext)
        case 2: sleepAndStress
        case 3: caloriesAndProtein
        case 4: fruitVegAndTreats
        case 5: FoodBubblesSlide(onContinue: goNext)
        case 6: mainGoal
        case 7: workoutLocation
        default: schedule
        }
    }

    // 1
    private var aboutYou: some View {
        Slide(title: "Let's start with you", onContinue: goNext) {
            TipCard(text: "Your age, size, and sex set your starting calories and body-age estimate. Your answers are saved only on your phone.")

            HStack {
                Text("Name")
                    .foregroundStyle(Theme.textSecondary)
                TextField("Your name", text: $profile.name)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(Theme.text)
                    .textContentType(.givenName)
                    .submitLabel(.done)
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 52)
            .themedCard()

            StepperRow(title: "Age", intValue: $profile.age, range: 13...90, unit: "yrs")

            VStack(alignment: .leading, spacing: 8) {
                QuestionLabel("Sex")
                ChipPicker(options: Sex.allCases.map { ($0.label, $0) }, selection: $profile.sex)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HeightRow(inches: $profile.heightInches)

            StepperRow(title: "Weight", value: $profile.weightPounds, range: 70...500, unit: "lb")
        }
    }

    // 3
    private var sleepAndStress: some View {
        Slide(title: "Sleep and stress", onContinue: goNext) {
            TipCard(text: "Sleep and stress affect hunger, recovery, and how fast you see results.")

            StepperRow(title: "Sleep", value: $profile.sleepHours, range: 0...12, step: 0.5, unit: "hrs")

            question("Stress lately") {
                // Each chip saves a number on the 1-10 scale the health math uses.
                // "High" starts at 8, where the body-age estimate adds a penalty.
                NumberChips(
                    options: [("Low", 2), ("Some", 5), ("High", 8), ("Very high", 10)],
                    value: $profile.stress
                )
            }
        }
    }

    // 4
    private var caloriesAndProtein: some View {
        Slide(title: "Calories and protein", onContinue: goNext) {
            TipCard(
                heading: "1 protein serving ≈ \(NutritionAdvisor.gramsPerProteinServing) g",
                text: proteinExamples
            )

            question("Protein servings a day") {
                NumberChips(0...5, value: $profile.proteinServingsPerDay)
                Text(proteinEstimate)
                    .font(.caption)
                    .foregroundStyle(Theme.textMuted)
                    .contentTransition(.numericText())
                    .animation(.default, value: profile.proteinServingsPerDay)
            }

            VStack(alignment: .leading, spacing: 6) {
                StepperRow(title: "Calories", intValue: $profile.dailyCalories, range: 1000...6000, step: 50, unit: "a day")
                Text("Not sure? Leave the default.")
                    .font(.caption)
                    .foregroundStyle(Theme.textMuted)
            }

            question("Diet") {
                ChipPicker(options: DietPreference.allCases.map { ($0.label, $0) }, selection: $profile.dietPreference)
            }
        }
    }

    private var proteinExamples: String {
        switch profile.dietPreference {
        case .noPreference, .dairyFree:
            return "A palm-size chicken breast, 4 eggs, a can of tuna, or 1½ cups of beans."
        case .vegetarian:
            return "4 eggs, a cup of Greek yogurt, a cup of cottage cheese, or 1½ cups of lentils."
        case .vegan:
            return "A cup of firm tofu, 1½ cups of lentils or beans, or a cup of edamame."
        }
    }

    private var proteinEstimate: String {
        let grams = profile.proteinServingsPerDay * NutritionAdvisor.gramsPerProteinServing
        return profile.proteinServingsPerDay >= 5 ? "About \(grams)+ g of protein a day" : "About \(grams) g of protein a day"
    }

    // 5
    private var fruitVegAndTreats: some View {
        Slide(title: "Fruit, veg, and treats", onContinue: goNext) {
            TipCard(text: "A serving of fruit or veg is about the size of your fist. Sugary drinks include soda, sweet tea, and energy drinks.")

            question("Fruit or veg servings a day") {
                NumberChips(0...5, value: $profile.fruitVegServingsPerDay)
            }

            question("Sugary drinks a day") {
                NumberChips(0...3, value: $profile.sugaryDrinksPerDay)
            }

            question("Fast food meals a week") {
                NumberChips(0...7, value: $profile.fastFoodMealsPerWeek)
            }
        }
    }

    // 7
    private var mainGoal: some View {
        Slide(title: "What's your main goal?", fillsHeight: true, onContinue: goNext) {
            ForEach(FitnessGoal.allCases) { goal in
                OptionCard(
                    icon: goal.icon,
                    title: goal.label,
                    isSelected: profile.goal == goal
                ) {
                    profile.goal = goal
                }
            }

            if profile.goal.hasTargetWeight {
                StepperRow(title: "Target weight", value: $profile.targetWeightPounds, range: 70...500, unit: "lb")
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.2), value: profile.goal)
    }

    // 8
    private var workoutLocation: some View {
        Slide(title: "Where will you work out?", fillsHeight: true, onContinue: goNext) {
            ForEach(WorkoutLocation.allCases) { location in
                OptionCard(
                    icon: location.icon,
                    title: location.label,
                    subtitle: location.details,
                    isSelected: profile.workoutLocation == location
                ) {
                    profile.workoutLocation = location
                }
            }
        }
    }

    // 9
    private var schedule: some View {
        Slide(title: "Your schedule", buttonTitle: "See my future", onContinue: goNext) {
            TipCard(text: "Be realistic. A plan you'll stick to beats a perfect one.")

            question("Days per week") {
                NumberChips(2...6, value: $profile.trainingDaysAvailable, lastMeansOrMore: false)
            }

            question("Minutes per workout") {
                NumberChips(
                    options: [("20", 20), ("30", 30), ("45", 45), ("60", 60), ("90+", 90)],
                    value: $profile.minutesPerWorkout,
                    lastMeansOrMore: true
                )
            }

            question("Experience") {
                ChipPicker(options: Experience.allCases.map { ($0.label, $0) }, selection: $profile.experience)
            }
        }
    }

    /// A label with its answer chips underneath, kept together as one block.
    private func question<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            QuestionLabel(label)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Slide layout

/// Title at the top, Continue at the bottom, and the questions spread evenly
/// in between. Scrolls only if the questions don't fit (small phones,
/// keyboard open). With `fillsHeight`, the questions stretch to fill the
/// space instead (used for the big option buttons).
struct Slide<Content: View>: View {
    let title: String
    var buttonTitle = "Continue"
    var fillsHeight = false
    let onContinue: () -> Void
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.title2.bold())
                .foregroundStyle(Theme.text)
                .padding(.horizontal, 20)
                .padding(.top, 12)

            GeometryReader { geometry in
                ScrollView {
                    Group {
                        if fillsHeight {
                            VStack(spacing: 10) { content }
                                .padding(.vertical, 16)
                        } else {
                            EvenlySpaced { content }
                        }
                    }
                    .padding(.horizontal, 20)
                    .frame(minHeight: geometry.size.height, idealHeight: geometry.size.height)
                }
                .scrollBounceBehavior(.basedOnSize)
                .scrollDismissesKeyboard(.interactively)
            }

            Button(buttonTitle, action: onContinue)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
        }
    }
}

/// A big tappable answer with an icon, used on the goal and location slides.
struct OptionCard: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? Theme.amber : Theme.slate)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(Theme.text)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(Theme.textMuted)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.amber)
                }
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 56, maxHeight: .infinity)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Theme.amber : Theme.border, lineWidth: isSelected ? 1.5 : 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Icons for the option slides

private extension FitnessGoal {
    var icon: String {
        switch self {
        case .loseWeight: return "scalemass"
        case .buildMuscle: return "dumbbell"
        case .maintain: return "equal.circle"
        case .generalHealth: return "heart"
        }
    }
}

private extension WorkoutLocation {
    var icon: String {
        switch self {
        case .commercialGym: return "building.2"
        case .homeGym: return "house"
        case .homeDumbbells: return "dumbbell"
        case .homeNoEquipment: return "figure.strengthtraining.functional"
        case .outdoors: return "tree"
        case .classes: return "person.3"
        }
    }
}
