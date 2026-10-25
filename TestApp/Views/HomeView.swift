//
//  HomeView.swift
//  TestApp
//
//  The Home tab: this week's progress at a glance, today's workout,
//  the top food tip, and a way to update their answers.
//

import SwiftUI

struct HomeView: View {

    @EnvironmentObject var profile: UserProfile
    @EnvironmentObject var log: WorkoutLog
    @EnvironmentObject var gallery: GalleryStore
    @EnvironmentObject var tutorial: TutorialController
    @Binding var selectedTab: AppTab

    @State private var isEditingInfo = false
    @State private var confirmReset = false

    private var projection: HealthProjection { HealthProjection.calculate(profile: profile) }
    private var plan: WorkoutPlan { WorkoutPlanner.plan(for: profile, bmi: projection.currentBMI) }
    private let dates = WorkoutLog.datesThisWeek()

    var body: some View {
        let plan = plan
        let trainingDays = plan.days.indices.filter { plan.days[$0].kind != .rest }
        let doneCount = trainingDays.filter { log.isComplete(plan.days[$0], on: dates[$0]) }.count
        let today = plan.days[WorkoutLog.todayIndex()]

        ScrollViewReader { scroller in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        YouTurnLogo(showsBackground: false)
                            .frame(width: 40, height: 40)
                            .padding(4)
                            .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
                        Text(profile.name.isEmpty ? "Welcome back" : "Hi \(profile.name)")
                            .font(.largeTitle.bold())
                            .foregroundStyle(Theme.text)
                    }
                    .padding(.bottom, 4)

                    progressCard(done: doneCount, planned: trainingDays.count)
                        .tutorialTarget("home.progress")

                    HStack(spacing: 12) {
                        tile(
                            title: "Today's workout",
                            value: today.kind == .rest ? "Rest day" : today.name,
                            icon: today.kind == .rest ? "moon.zzz" : "figure.strengthtraining.traditional"
                        ) {
                            selectedTab = .plan
                        }
                        tile(title: "Food tip", value: topFoodTip, icon: "fork.knife") {
                            selectedTab = .future
                        }
                    }
                    .tutorialTarget("home.tiles")

                    weekRow(plan)

                    Button {
                        isEditingInfo = true
                    } label: {
                        Label("Update my info", systemImage: "pencil")
                    }
                    .buttonStyle(OutlineButtonStyle())
                    .tutorialTarget("home.update")
                    .padding(.top, 8)

                    NavigationLink {
                        HowItWorksView()
                    } label: {
                        Label("How YouTurn works", systemImage: "info.circle")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                    }
                    .foregroundStyle(Theme.amber)
                    .padding(.top, 16)

                    Button(role: .destructive) {
                        confirmReset = true
                    } label: {
                        Label("Reset all data", systemImage: "trash")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                    }
                    .foregroundStyle(.red)
                    .padding(.top, 8)
                }
                .padding()
            }
            .task(id: tutorial.stepIndex) {
                await scrollToTutorialStep(on: .home, using: scroller, tutorial: tutorial)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .themedScreen()
        .fullScreenCover(isPresented: $isEditingInfo) {
            NavigationStack {
                OnboardingView {
                    isEditingInfo = false
                    // Saved images were made from the old answers.
                    profile.imageBatchByHorizon = [:]
                    selectedTab = .future
                }
            }
            .environmentObject(profile)
        }
        .confirmationDialog(
            "Reset all data?",
            isPresented: $confirmReset,
            titleVisibility: .visible
        ) {
            Button("Erase everything", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("This permanently erases your answers, your plan progress, and every photo and image in your gallery. You'll start over from the welcome screen. This can't be undone.")
        }
    }

    /// Erases everything saved on the phone and goes back to the welcome screen.
    private func resetAllData() {
        tutorial.stop()
        gallery.deleteAll()
        log.resetAll()
        selectedTab = .home
        profile.resetAll()
    }

    private var topFoodTip: String {
        let tips = NutritionAdvisor.plan(for: profile, projection: projection).tips
        return tips.first(where: { $0.priority != .good })?.title ?? "You're on track"
    }

    // MARK: - Pieces

    /// Ring showing how many of this week's workouts are checked off.
    private func progressCard(done: Int, planned: Int) -> some View {
        let fraction = planned == 0 ? 0 : Double(done) / Double(planned)

        return Button {
            selectedTab = .plan
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Theme.cardRaised, lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: fraction)
                        .stroke(Theme.amber, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 0.5), value: fraction)
                    Text("\(done)/\(planned)")
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(Theme.text)
                }
                .frame(width: 72, height: 72)

                VStack(alignment: .leading, spacing: 4) {
                    Text(done >= planned && planned > 0 ? "Week complete!" : "Workouts this week")
                        .font(.headline)
                        .foregroundStyle(Theme.text)
                    Text("See your plan →")
                        .font(.subheadline)
                        .foregroundStyle(Theme.amber)
                }
                Spacer()
            }
            .padding(16)
            .themedCard(cornerRadius: 16)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(done) of \(planned) workouts done this week. Opens your plan.")
    }

    private func tile(title: String, value: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(Theme.amber)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(Theme.textMuted)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
            .padding(14)
            .themedCard(cornerRadius: 16)
        }
        .buttonStyle(.plain)
    }

    /// Seven squares: amber = done, outlined = planned, dim = rest day.
    private func weekRow(_ plan: WorkoutPlan) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("This week")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)

            HStack(spacing: 6) {
                ForEach(plan.days.indices, id: \.self) { index in
                    let day = plan.days[index]
                    let isDone = log.isComplete(day, on: dates[index])

                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isDone ? Theme.amber : (day.kind == .rest ? Theme.cardRaised.opacity(0.5) : Color.clear))
                            .overlay {
                                if !isDone && day.kind != .rest {
                                    RoundedRectangle(cornerRadius: 6).stroke(Theme.slate, lineWidth: 1)
                                }
                            }
                            .frame(height: 28)
                        Text(day.weekday.prefix(1))
                            .font(.caption2.weight(index == WorkoutLog.todayIndex() ? .bold : .regular))
                            .foregroundStyle(index == WorkoutLog.todayIndex() ? Theme.amber : Theme.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(14)
        .themedCard(cornerRadius: 16)
        .accessibilityElement(children: .combine)
    }
}
