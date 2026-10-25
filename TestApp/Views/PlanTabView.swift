//
//  PlanTabView.swift
//  TestApp
//
//  The Plan tab: a Monday-Sunday strip on top, and the chosen day's
//  workout as a checklist below. "Why this plan?" opens the full plan
//  with the reasons and the flowchart.
//

import SwiftUI

struct PlanTabView: View {

    @EnvironmentObject var profile: UserProfile
    @EnvironmentObject var log: WorkoutLog
    @EnvironmentObject var tutorial: TutorialController

    @State private var selectedIndex = WorkoutLog.todayIndex()

    private var plan: WorkoutPlan {
        let projection = HealthProjection.calculate(profile: profile)
        return WorkoutPlanner.plan(for: profile, bmi: projection.currentBMI)
    }

    private let dates = WorkoutLog.datesThisWeek()

    var body: some View {
        let plan = plan
        let day = plan.days[selectedIndex]
        let date = dates[selectedIndex]

        ScrollViewReader { scroller in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("\(plan.title) · \(profile.minutesPerWorkout) min per workout")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)

                    weekStrip(plan)
                        .tutorialTarget("plan.week")

                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(day.weekday + (selectedIndex == WorkoutLog.todayIndex() ? " · today" : ""))
                                .font(.caption)
                                .foregroundStyle(Theme.textMuted)
                            Text(day.name)
                                .font(.title3.bold())
                                .foregroundStyle(Theme.text)
                        }

                        checklist(day, on: date)

                        if !day.notes.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(day.notes, id: \.self) { note in
                                    Text(note)
                                }
                            }
                            .font(.footnote)
                            .foregroundStyle(Theme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    NavigationLink {
                        WorkoutPlanView()
                    } label: {
                        HStack {
                            Image(systemName: "point.3.connected.trianglepath.dotted")
                            Text("Why this plan? See your flowchart")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.amber)
                        .padding(14)
                        .themedCard()
                    }
                    .tutorialTarget("plan.why")

                    Text("Check with a doctor before starting a new exercise program, especially if you have an injury or health condition.")
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)
                }
                .padding()
            }
            .task(id: tutorial.stepIndex) {
                // Show a training day (not a rest day) when explaining the checklist.
                if tutorial.step?.target == "plan.day", plan.days[selectedIndex].kind == .rest,
                   let firstWorkout = plan.days.firstIndex(where: { $0.kind != .rest }) {
                    selectedIndex = firstWorkout
                }
                await scrollToTutorialStep(on: .plan, using: scroller, tutorial: tutorial)
            }
        }
        .navigationTitle("Your week")
        .themedScreen()
    }

    // MARK: - Week strip

    private func weekStrip(_ plan: WorkoutPlan) -> some View {
        HStack(spacing: 6) {
            ForEach(plan.days.indices, id: \.self) { index in
                let day = plan.days[index]
                let isSelected = index == selectedIndex
                let isComplete = log.isComplete(day, on: dates[index])

                Button {
                    selectedIndex = index
                } label: {
                    VStack(spacing: 6) {
                        Text(day.weekday.prefix(1))
                            .font(.subheadline.weight(.semibold))
                        Image(systemName: isComplete ? "checkmark" : (day.kind == .rest ? "circle" : "circle.fill"))
                            .font(.system(size: isComplete ? 11 : 7, weight: .bold))
                            .frame(height: 12)
                    }
                    .foregroundStyle(isSelected ? Theme.navy : (day.kind == .rest ? Theme.textMuted : Theme.text))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(isSelected ? Theme.amber : Theme.card, in: RoundedRectangle(cornerRadius: 10))
                    .overlay {
                        if index == WorkoutLog.todayIndex() && !isSelected {
                            RoundedRectangle(cornerRadius: 10).stroke(Theme.amber.opacity(0.6), lineWidth: 1)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(day.weekday), \(day.name)\(isComplete ? ", done" : "")")
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }

    // MARK: - Checklist

    @ViewBuilder
    private func checklist(_ day: WorkoutDay, on date: Date) -> some View {
        switch day.kind {
        case .strength:
            VStack(spacing: 8) {
                ForEach(day.exercises.indices, id: \.self) { index in
                    let exercise = day.exercises[index]
                    if index == 0 {
                        // The tour spotlights the first row to show how checking off works.
                        checkRow(exercise.name, detail: "\(exercise.sets) × \(exercise.reps)", on: date)
                            .tutorialTarget("plan.day")
                    } else {
                        checkRow(exercise.name, detail: "\(exercise.sets) × \(exercise.reps)", on: date)
                    }
                }
            }
        case .cardio:
            checkRow("Mark as done", detail: "\(profile.minutesPerWorkout) min", item: day.name, on: date)
                .tutorialTarget("plan.day")
        case .rest:
            EmptyView()
        }
    }

    /// One tappable line with a checkbox. `item` is what gets saved in the
    /// log (defaults to the title).
    private func checkRow(_ title: String, detail: String, item: String? = nil, on date: Date) -> some View {
        let item = item ?? title
        let isDone = log.isDone(item, on: date)

        return Button {
            withAnimation(.easeOut(duration: 0.15)) {
                log.toggle(item, on: date)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isDone ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(isDone ? Theme.amber : Theme.slate)
                Text(title)
                    .foregroundStyle(isDone ? Theme.textMuted : Theme.text)
                    .strikethrough(isDone, color: Theme.textMuted)
                Spacer()
                Text(detail)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 50)
            .themedCard()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isDone)
        .accessibilityValue(isDone ? "Done" : "Not done")
    }
}
