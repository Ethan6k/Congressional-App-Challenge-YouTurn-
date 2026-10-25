//
//  WorkoutsSlide.swift
//  TestApp
//
//  Slide 2: the workouts they already do. Each one is a short summary row;
//  tapping it (or "Add a workout") opens a sheet with the details.
//

import SwiftUI

struct WorkoutsSlide: View {

    @EnvironmentObject var profile: UserProfile
    let onContinue: () -> Void

    /// The workout being added or edited in the sheet.
    @State private var editing: ExerciseActivity?

    var body: some View {
        Slide(title: "How do you work out now?", onContinue: onContinue) {
            TipCard(text: "Add each kind of exercise you do regularly. Skip this if you're starting fresh.")

            if !profile.activities.isEmpty {
                VStack(spacing: 8) {
                    ForEach(profile.activities) { activity in
                        workoutRow(activity)
                    }
                }
            }

            VStack(spacing: 10) {
                Button {
                    editing = ExerciseActivity()
                } label: {
                    Label("Add a workout", systemImage: "plus")
                }
                .buttonStyle(OutlineButtonStyle())

                if !profile.activities.isEmpty {
                    Button("I don't work out yet") {
                        profile.activities.removeAll()
                        onContinue()
                    }
                    .font(.footnote)
                    .foregroundStyle(Theme.textMuted)
                }
            }
        }
        .sheet(item: $editing) { activity in
            AddWorkoutSheet(
                activity: activity,
                isNew: !profile.activities.contains { $0.id == activity.id },
                onSave: save,
                onRemove: { removed in
                    profile.activities.removeAll { $0.id == removed.id }
                }
            )
        }
    }

    private func workoutRow(_ activity: ExerciseActivity) -> some View {
        Button {
            editing = activity
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(activity.type.label)
                        .font(.body.weight(.medium))
                        .foregroundStyle(Theme.text)
                    Text("\(activity.intensity.label) · \(activity.daysPerWeek)×/wk · \(activity.minutesPerSession) min")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: "pencil")
                    .foregroundStyle(Theme.amber)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .themedCard()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Edit this workout")
    }

    private func save(_ activity: ExerciseActivity) {
        if let index = profile.activities.firstIndex(where: { $0.id == activity.id }) {
            profile.activities[index] = activity
        } else {
            profile.activities.append(activity)
        }
    }
}

/// The pop-up for adding or editing one workout.
struct AddWorkoutSheet: View {

    @Environment(\.dismiss) private var dismiss

    @State var activity: ExerciseActivity
    let isNew: Bool
    let onSave: (ExerciseActivity) -> Void
    let onRemove: (ExerciseActivity) -> Void

    var body: some View {
        // In a NavigationStack only so the keyboard's Done button shows up.
        NavigationStack {
            form
                .toolbar(.hidden, for: .navigationBar)
                .keyboardDoneButton()
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.navy)
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(isNew ? "Add a workout" : "Edit workout")
                .font(.title3.bold())
                .foregroundStyle(Theme.text)
                .padding(.horizontal, 20)
                .padding(.top, 24)

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        QuestionLabel("Type")
                        ChipPicker(options: ExerciseType.allCases.map { ($0.label, $0) }, selection: $activity.type)
                        Text(activity.type.examples)
                            .font(.caption)
                            .foregroundStyle(Theme.textMuted)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        QuestionLabel("Intensity")
                        ChipPicker(options: Intensity.allCases.map { ($0.label, $0) }, selection: $activity.intensity)
                        Text(activity.intensity.talkTest)
                            .font(.caption)
                            .foregroundStyle(Theme.textMuted)
                    }

                    StepperRow(title: "Days a week", intValue: $activity.daysPerWeek, range: 1...7)
                    StepperRow(title: "Minutes", intValue: $activity.minutesPerSession, range: 10...240, step: 5, unit: "min")
                }
                .padding(20)
            }
            .scrollBounceBehavior(.basedOnSize)

            VStack(spacing: 10) {
                Button(isNew ? "Save workout" : "Save changes") {
                    onSave(activity)
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle())

                if !isNew {
                    Button("Remove workout", role: .destructive) {
                        onRemove(activity)
                        dismiss()
                    }
                    .font(.subheadline)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .themedScreen()
    }
}
