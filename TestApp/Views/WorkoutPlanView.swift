//
//  WorkoutPlanView.swift
//  TestApp
//
//  Shows the personalized weekly workout plan, why it fits the user, and
//  the decision path (flowchart) used to build it.
//

import SwiftUI

struct WorkoutPlanView: View {

    @EnvironmentObject var profile: UserProfile

    private var plan: WorkoutPlan {
        let projection = HealthProjection.calculate(profile: profile)
        return WorkoutPlanner.plan(for: profile, bmi: projection.currentBMI)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                VStack(alignment: .leading, spacing: 6) {
                    Text(plan.title)
                        .font(.largeTitle)
                        .bold()
                    Text("\(profile.goal.label) · \(profile.workoutLocation.label) · \(profile.minutesPerWorkout) min per workout")
                        .foregroundStyle(.secondary)
                }

                card {
                    Text("Your Week")
                        .font(.headline)

                    ForEach(plan.days) { day in
                        dayRow(day)
                        if day.id != plan.days.last?.id {
                            Divider()
                        }
                    }
                }

                card {
                    Text("Why This Plan Fits You")
                        .font(.headline)

                    ForEach(plan.reasons, id: \.self) { reason in
                        Label(reason, systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .labelStyle(BulletLabelStyle(color: .green))
                    }
                }

                card {
                    Text("How We Built Your Plan")
                        .font(.headline)
                    Text("Each answer narrowed down the plan, like a flowchart.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    flowchart
                }

                card {
                    Text("How to Use This Plan")
                        .font(.headline)

                    ForEach(plan.howTo, id: \.self) { tip in
                        Label(tip, systemImage: "info.circle.fill")
                            .font(.subheadline)
                            .labelStyle(BulletLabelStyle(color: Theme.slate))
                    }
                }

                Text("Check with a doctor before starting a new exercise program, especially if you have an injury or health condition.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Workout Plan")
        .themedScreen()
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Week

    private func dayRow(_ day: WorkoutDay) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon(for: day.kind))
                    .foregroundStyle(color(for: day.kind))
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(day.weekday)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(day.name)
                        .font(.subheadline)
                        .bold()
                }
            }

            ForEach(day.exercises) { exercise in
                HStack(alignment: .firstTextBaseline) {
                    Text(exercise.name)
                        .font(.subheadline)
                    Spacer()
                    Text("\(exercise.sets) × \(exercise.reps)")
                        .font(.subheadline)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .padding(.leading, 32)
            }

            ForEach(day.notes, id: \.self) { note in
                Text(note)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 32)
            }
        }
    }

    private func icon(for kind: WorkoutDay.Kind) -> String {
        switch kind {
        case .strength: return "dumbbell.fill"
        case .cardio: return "heart.fill"
        case .rest: return "moon.zzz.fill"
        }
    }

    private func color(for kind: WorkoutDay.Kind) -> Color {
        switch kind {
        case .strength: return Theme.amber
        case .cardio: return .red
        case .rest: return .gray
        }
    }

    // MARK: - Flowchart

    private var flowchart: some View {
        VStack(spacing: 6) {
            ForEach(plan.decisions) { decision in
                VStack(spacing: 2) {
                    Text(decision.question)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(decision.answer)
                        .font(.subheadline)
                        .bold()
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(Theme.cardRaised)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Image(systemName: "arrow.down")
                    .foregroundStyle(.secondary)
            }

            Text(plan.title)
                .font(.subheadline)
                .bold()
                .foregroundStyle(Theme.navy)
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(Theme.amber)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Layout helpers

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12, content: content)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Theme.card)
            .cornerRadius(8)
    }
}

/// Icon + text with the icon aligned to the first line.
private struct BulletLabelStyle: LabelStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            configuration.icon
                .foregroundStyle(color)
            configuration.title
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
