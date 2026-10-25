//
//  FutureView.swift
//  TestApp
//
//  Created by Ethan Hong on 7/19/26.
//

import SwiftUI
import UIKit

struct FutureView: View {

    @EnvironmentObject var profile: UserProfile
    @EnvironmentObject var gallery: GalleryStore
    @EnvironmentObject var tutorial: TutorialController
    // One AI image per future: current habits vs. following the plan
    @StateObject private var currentPathImage = FutureImageGenerator()
    @StateObject private var planPathImage = FutureImageGenerator()

    // MARK: - Image Picker States
    @State private var inputImage: UIImage?
    @State private var showSourceActionSheet = false
    @State private var showImagePicker = false
    @State private var pickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showCameraUnavailableAlert = false
    /// Shows "here's what will be sent to Google" before the first generate.
    @State private var showSharingConsent = false
    /// True while putting back the saved photo, so it isn't saved again.
    @State private var isRestoringPhoto = false

    private var projection: HealthProjection {
        HealthProjection.calculate(profile: profile)
    }

    private var nutritionPlan: NutritionPlan {
        NutritionAdvisor.plan(for: profile, projection: projection)
    }

    private var scenarios: (current: FutureScenario, plan: FutureScenario) {
        FutureScenario.both(for: profile)
    }

    private var isGenerating: Bool {
        currentPathImage.isGenerating || planPathImage.isGenerating
    }

    private var imageError: String? {
        currentPathImage.errorMessage ?? planPathImage.errorMessage
    }

    var body: some View {
        ScrollViewReader { scroller in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Hi \(profile.name.isEmpty ? "there" : profile.name). Here's where your habits are taking you, and where your plan could take you instead.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)

                    // Input photo & AI visualization section (first thing they see)
                    futureVisualization

                    // Link to the personalized workout plan
                    NavigationLink {
                        WorkoutPlanView()
                            .environmentObject(profile)
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.title)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Your Workout Plan")
                                    .font(.headline)
                                Text("A weekly plan built for your goal and where you train")
                                    .font(.subheadline)
                                    .multilineTextAlignment(.leading)
                                    .opacity(0.9)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .foregroundStyle(Theme.navy)
                        .padding()
                        .background(Theme.amber)
                        .cornerRadius(12)
                    }

                    // Rule-based diet targets and fixes
                    nutritionSection

                    // Weight forecast (based on calories in vs. out)
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader(
                            "Your 1-Year Forecast",
                            subtitle: "What will likely happen to your weight if you keep your current habits for a year."
                        )

                        statRow(
                            "Calories your body burns",
                            value: "~\(projection.maintenanceCalories)/day",
                            explanation: "Eat about this much and your weight stays the same. \(calorieBalanceSentence)"
                        )
                        statRow(
                            "Burned by your workouts",
                            value: "~\(projection.exerciseCaloriesPerDay)/day",
                            explanation: "The extra calories your workouts burn, spread across every day of the week. It's already included in the number above."
                        )
                        statRow(
                            "Weekly weight change",
                            value: "\(signedYears(projection.weeklyWeightChange)) lb/week",
                            explanation: "How fast your weight is heading up (+) or down (-). Losing or gaining 0.5-2 lb a week is a healthy, sustainable pace."
                        )
                        statRow(
                            "Weight in 1 year",
                            value: "\(wholeNumber(projection.projectedWeightRange.lowerBound))-\(wholeNumber(projection.projectedWeightRange.upperBound)) lb",
                            explanation: "Your likely weight a year from now (you're \(wholeNumber(profile.weightPounds)) lb today). It's a range because everyone's body responds a little differently."
                        )
                        .tutorialTarget("future.forecast")
                        statRow(
                            "BMI today",
                            value: "\(oneDecimal(projection.currentBMI)) · \(projection.bmiCategory)",
                            explanation: "BMI (Body Mass Index) is a quick check of your weight compared to your height. For adults, 18.5-24.9 is considered a healthy range. It can't tell muscle from fat, so very muscular people may score high."
                        )
                        statRow(
                            "BMI in 1 year",
                            value: "\(oneDecimal(projection.projectedBMIRange.lowerBound))-\(oneDecimal(projection.projectedBMIRange.upperBound))",
                            explanation: "Your BMI at your forecasted weight."
                        )

                        if let warning = projection.weightChangeWarning {
                            Text(warning)
                                .font(.footnote)
                                .foregroundStyle(.orange)
                        }
                    }
                    .padding()
                    .background(Theme.card)
                    .cornerRadius(8)

                    // Long-term estimates (rough, research-based)
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader(
                            "Long-Term Health Outlook",
                            subtitle: "Rough estimates of how your habits affect your health over your lifetime. These are less exact than the forecast above."
                        )

                        statRow(
                            "Body age",
                            value: "~\(projection.biologicalAge)",
                            explanation: "How old your body acts based on your weight, exercise, sleep, and stress, compared to your real age of \(profile.age). \(bodyAgeSentence)"
                        )
                        statRow(
                            "Effect on lifespan",
                            value: "\(signedYears(projection.lifeExpectancyModifierRange.lowerBound)) to \(signedYears(projection.lifeExpectancyModifierRange.upperBound)) years",
                            explanation: "In large studies, people with habits like yours lived about this many years more (+) or fewer (-) than average. It's a trend across many people, not a prediction for you."
                        )
                    }
                    .padding()
                    .background(Theme.card)
                    .cornerRadius(8)

                    Text("These numbers are estimates based on averages from research on large groups of people. They aren't medical advice, a diagnosis, or a guarantee.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .task(id: tutorial.stepIndex) {
                await scrollToTutorialStep(on: .future, using: scroller, tutorial: tutorial)
            }
        }
        .navigationTitle("Your future")
        .themedScreen()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    HowItWorksView()
                } label: {
                    Image(systemName: "info.circle")
                }
                .accessibilityLabel("How YouTurn works")
            }
        }
        .onAppear(perform: restoreSavedState)
        .onChange(of: inputImage) {
            savePickedPhoto()
        }
        // Image generation error alert
        .alert(
            "Image generation unavailable",
            isPresented: Binding(
                get: { imageError != nil },
                set: { if !$0 { clearImageErrors() } }
            )
        ) {
            Button("OK", role: .cancel) {
                clearImageErrors()
            }
        } message: {
            Text(imageError ?? "")
        }
        // Action sheet to pick Camera or Photo Library
        .confirmationDialog("Select Photo Source", isPresented: $showSourceActionSheet, titleVisibility: .visible) {
            Button("Take Photo") {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    pickerSourceType = .camera
                    showImagePicker = true
                } else {
                    showCameraUnavailableAlert = true
                }
            }

            Button("Choose from Library") {
                pickerSourceType = .photoLibrary
                showImagePicker = true
            }

            if inputImage != nil {
                Button("Remove Photo", role: .destructive) {
                    inputImage = nil
                }
            }

            Button("Cancel", role: .cancel) {}
        }
        // Native Apple sheet (Camera or Photo Library)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(sourceType: pickerSourceType, selectedImage: $inputImage)
        }
        // Simulator / missing camera alert
        .alert("Camera Unavailable", isPresented: $showCameraUnavailableAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The camera is not supported on this device or simulator.")
        }
    }

    // MARK: - Nutrition Section
    private var nutritionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Nutrition Plan")
                .font(.headline)

            Text("Goal: \(profile.goal.label)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                targetTile("Calories", value: "\(nutritionPlan.calorieTarget)", unit: "per day")
                targetTile("Protein", value: "\(nutritionPlan.proteinGrams.lowerBound)-\(nutritionPlan.proteinGrams.upperBound)", unit: "g per day")
                targetTile("Fiber", value: "\(nutritionPlan.fiberGrams)+", unit: "g per day")
            }
            .tutorialTarget("future.nutrition")

            VStack(alignment: .leading, spacing: 6) {
                targetExplanation("Calories", "How much to eat each day to reach your goal.")
                targetExplanation("Protein", "Builds and repairs muscle, and keeps you full longer.")
                targetExplanation("Fiber", "Found in fruits, vegetables, beans, and whole grains. Helps digestion and keeps you full.")
            }
            .font(.footnote)

            Label {
                Text("**Allergies and health conditions:** These tips are general. Skip any suggested food you're allergic or sensitive to (like nuts, dairy, eggs, soy, gluten, or shellfish), and check ingredient labels. If you have a medical condition, are pregnant, or take medication, talk to a doctor or registered dietitian before changing your diet.")
                    .font(.footnote)
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            }
            .padding(10)
            .background(Color.orange.opacity(0.12))
            .cornerRadius(8)

            Divider()

            Text("What to change")
                .font(.subheadline)
                .bold()

            if nutritionPlan.tips.isEmpty {
                Label("Your eating habits already match your goal. Keep it up!", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.green)
            }

            ForEach(nutritionPlan.tips) { tip in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: tip.icon)
                        .foregroundStyle(color(for: tip.priority))
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(tip.title)
                            .font(.subheadline)
                            .bold()

                        Text(tip.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Theme.card)
        .cornerRadius(8)
    }

    private func targetTile(_ title: String, value: String, unit: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3)
                .bold()
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(unit)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Theme.cardRaised)
        .cornerRadius(8)
    }

    private func targetExplanation(_ title: String, _ text: String) -> some View {
        Text("\(Text("\(title):").bold()) \(text)")
            .foregroundStyle(.secondary)
    }

    private func color(for priority: NutritionTip.Priority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return Theme.slate
        case .good: return .green
        }
    }

    // MARK: - Plain-English helpers

    private func sectionHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var calorieBalanceSentence: String {
        let difference = profile.dailyCalories - projection.maintenanceCalories
        if abs(difference) < 100 {
            return "You eat about \(profile.dailyCalories), so your weight should stay about the same."
        } else if difference > 0 {
            return "You eat about \(profile.dailyCalories), which is \(difference) more, so you'll slowly gain weight."
        } else {
            return "You eat about \(profile.dailyCalories), which is \(-difference) less, so you'll slowly lose weight."
        }
    }

    private var bodyAgeSentence: String {
        if projection.biologicalAge < profile.age {
            return "Lower than your real age is a good sign!"
        } else if projection.biologicalAge > profile.age {
            return "Higher than your real age means some habits are adding wear and tear. The tips above can bring it down."
        } else {
            return "Matching your real age is normal."
        }
    }

    // MARK: - Visualization Section
    private var futureVisualization: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                "See Your Future Self",
                subtitle: "Compare two futures: one where you keep doing what you do now, and one where you follow your plan."
            )

            // Input reference photo selector
            inputPhotoCard
                .tutorialTarget("future.photo")

            VStack(alignment: .leading, spacing: 6) {
                Text("How far into the future?")
                    .font(.subheadline)
                    .bold()

                Picker("How far into the future?", selection: $profile.visualizeMonths) {
                    ForEach(FutureScenario.horizonOptions, id: \.self) { months in
                        Text(FutureScenario.horizonShortLabel(months: months)).tag(months)
                    }
                }
                .pickerStyle(.segmented)
                // Locked while generating so new images can't land on the wrong time frame.
                .disabled(isGenerating)
            }
            .tutorialTarget("future.horizon")

            let both = scenarios
            HStack(alignment: .top, spacing: 12) {
                scenarioCard(both.current, generator: currentPathImage, color: .orange)
                scenarioCard(both.plan, generator: planPathImage, color: .green)
            }
            .tutorialTarget("future.images")

            // Generate both images
            Button {
                if profile.hasAgreedToImageSharing {
                    Task { await generateBothImages() }
                } else {
                    showSharingConsent = true
                }
            } label: {
                HStack {
                    if isGenerating {
                        ProgressView()
                            .tint(Theme.navy)
                    } else {
                        Image(systemName: currentPathImage.image == nil ? "wand.and.stars" : "arrow.clockwise")
                    }

                    Text(generateButtonTitle)
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .foregroundStyle(Theme.navy)
            .disabled(isGenerating)
            .tutorialTarget("future.generate")

            if isGenerating {
                Label("Creating your images with Gemini. This usually takes 20-40 seconds, so hang tight.", systemImage: "hourglass")
                    .font(.footnote)
                    .foregroundStyle(Theme.amber)
            }

            Text("Images are created by Google's Gemini AI. When you tap Generate, your stats and habits\(inputImage == nil ? "" : " and your photo") are sent to Google to make them. They're illustrations, not a prediction of your exact appearance or health.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .onChange(of: profile.visualizeMonths) {
            showImagesForSelectedHorizon()
        }
        .alert("Send your info to Google?", isPresented: $showSharingConsent) {
            Button("Agree and generate") {
                profile.hasAgreedToImageSharing = true
                Task { await generateBothImages() }
            }
            Button("Not now", role: .cancel) {}
        } message: {
            Text("""
            To make your images, YouTurn sends Google's Gemini AI your age, sex, height, weight, calories, exercise, sleep, your plan's targets, and the app's forecasts\(inputImage == nil ? "" : ", plus your photo").

            Your name, food list, and other answers are never sent. Everything else stays on your phone.
            """)
        }
    }

    private func scenarioCard(_ scenario: FutureScenario, generator: FutureImageGenerator, color: Color) -> some View {
        let p = scenario.projection
        let change = (p.projectedWeightRange.lowerBound + p.projectedWeightRange.upperBound) / 2 - profile.weightPounds

        return VStack(alignment: .leading, spacing: 8) {
            Text(scenario.kind == .currentHabits ? "Current habits" : "Following your plan")
                .font(.caption)
                .bold()
                .foregroundStyle(color)

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.cardRaised)

                if let image = generator.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .overlay(alignment: .topLeading) {
                            if !generator.isGenerating {
                                Text(FutureScenario.horizonShortLabel(months: profile.visualizeMonths))
                                    .font(.caption2.bold())
                                    .foregroundStyle(Theme.navy)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(Theme.amber, in: Capsule())
                                    .padding(6)
                                    .accessibilityLabel("Made for \(FutureScenario.horizonLabel(months: profile.visualizeMonths))")
                            }
                        }
                } else if generator.isGenerating {
                    ProgressView()
                } else {
                    Image(systemName: scenario.kind == .currentHabits ? "person.fill" : "figure.run")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }
            }
            .aspectRatio(3 / 4, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(color, lineWidth: 2))
            .accessibilityLabel("AI-generated image: \(scenario.title.lowercased())")

            VStack(alignment: .leading, spacing: 2) {
                Text("In \(FutureScenario.horizonLabel(months: p.horizonMonths))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(wholeNumber(p.projectedWeightRange.lowerBound))-\(wholeNumber(p.projectedWeightRange.upperBound)) lb")
                    .font(.subheadline)
                    .bold()
                Text(abs(change) < 2 ? "About the same weight" : "\(change > 0 ? "+" : "-")\(wholeNumber(abs(change))) lb from today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Age \(p.futureAge) · body age ~\(p.futureBiologicalAge)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// With a photo, both images edit it at the same time. Without one, the
    /// plan image is based on the first image so it shows the same person.
    private func generateBothImages() async {
        let both = scenarios
        let months = profile.visualizeMonths
        let currentImage: UIImage?
        let planImage: UIImage?

        if let photo = inputImage {
            async let current = currentPathImage.generate(
                prompt: FuturePrompt.withPhoto(both.current, profile: profile),
                referenceImage: photo
            )
            async let plan = planPathImage.generate(
                prompt: FuturePrompt.withPhoto(both.plan, profile: profile),
                referenceImage: photo
            )
            (currentImage, planImage) = await (current, plan)
        } else {
            currentImage = await currentPathImage.generate(
                prompt: FuturePrompt.withoutPhoto(both.current, profile: profile)
            )
            if let currentImage {
                planImage = await planPathImage.generate(
                    prompt: FuturePrompt.matchingPerson(both.plan, profile: profile),
                    referenceImage: currentImage
                )
            } else {
                planImage = await planPathImage.generate(
                    prompt: FuturePrompt.withoutPhoto(both.plan, profile: profile)
                )
            }
        }

        // Save both to the gallery, labeled with the data they were made from.
        let batchID = UUID()
        let fromPhoto = inputImage != nil
        if let currentImage {
            gallery.add(currentImage, kind: .currentHabits, batchID: batchID, fromPhoto: fromPhoto,
                        snapshot: HealthSnapshot(profile: profile, scenario: both.current))
        }
        if let planImage {
            gallery.add(planImage, kind: .followingPlan, batchID: batchID, fromPhoto: fromPhoto,
                        snapshot: HealthSnapshot(profile: profile, scenario: both.plan))
        }
        if currentImage != nil || planImage != nil {
            // These images belong to this time frame only.
            profile.imageBatchByHorizon[months] = batchID
            profile.save()  // right away, in case the app is closed next
        }
    }

    // MARK: - Saving and restoring

    /// When coming back to this screen (or reopening the app), put back the
    /// uploaded photo and the images for the selected time frame.
    private func restoreSavedState() {
        profile.hasCompletedSetup = true

        if inputImage == nil, let entry = gallery.entry(id: profile.referencePhotoID) {
            isRestoringPhoto = true
            inputImage = gallery.image(for: entry)
        }

        if currentPathImage.image == nil && planPathImage.image == nil {
            showImagesForSelectedHorizon()
        }
    }

    /// Shows the images generated for the selected time frame, or empty boxes
    /// if none have been generated for it yet.
    private func showImagesForSelectedHorizon() {
        currentPathImage.reset()
        planPathImage.reset()

        for entry in gallery.entries(inBatch: profile.imageBatchByHorizon[profile.visualizeMonths]) {
            switch entry.kind {
            case .currentHabits: currentPathImage.show(gallery.image(for: entry))
            case .followingPlan: planPathImage.show(gallery.image(for: entry))
            case .uploadedPhoto: break
            }
        }
    }

    /// Saves a newly picked photo to the gallery and remembers it.
    private func savePickedPhoto() {
        if isRestoringPhoto {
            isRestoringPhoto = false
            return
        }

        guard let photo = inputImage else {
            profile.referencePhotoID = nil
            return
        }

        let entry = gallery.add(photo, kind: .uploadedPhoto, fromPhoto: true,
                                snapshot: HealthSnapshot(profile: profile))
        profile.referencePhotoID = entry?.id
    }

    private func clearImageErrors() {
        currentPathImage.clearError()
        planPathImage.clearError()
    }

    // MARK: - Input Photo Card
    private var inputPhotoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let image = inputImage {
                HStack(spacing: 12) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reference Photo Added")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text("Age: \(profile.age) • \(wholeNumber(profile.weightPounds)) lb")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        showSourceActionSheet = true
                    } label: {
                        Text("Change")
                            .font(.subheadline)
                    }

                    Button(role: .destructive) {
                        inputImage = nil
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                }
                .padding(10)
                .background(Theme.card)
                .cornerRadius(10)
            } else {
                Button {
                    showSourceActionSheet = true
                } label: {
                    HStack {
                        Image(systemName: "camera.badge.plus")
                        Text("Take or Upload Reference Photo")
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)

                Text("Your photo is saved on your phone. It's only sent to Google's Gemini when you generate images.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var generateButtonTitle: String {
        if currentPathImage.image == nil && planPathImage.image == nil {
            return inputImage == nil ? "Generate both futures" : "Generate both from my photo"
        } else {
            return "Generate again"
        }
    }

    private func oneDecimal(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    private func wholeNumber(_ value: Double) -> String {
        String(format: "%.0f", value)
    }

    private func signedYears(_ value: Double) -> String {
        String(format: "%+.1f", value)
    }

    private func statRow(_ title: String, value: String, explanation: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(value)
                    .bold()
                    .multilineTextAlignment(.trailing)
            }

            if let explanation {
                Text(explanation)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}