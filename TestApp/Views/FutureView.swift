//
//  FutureView.swift
//  TestApp
//
//  Created by Ethan Hong on 7/19/26.
//

import SwiftUI

struct FutureView: View {

    @EnvironmentObject var profile: UserProfile

    private var projection: HealthProjection {
        HealthProjection.calculate(
            age: profile.age,
            heightInches: profile.heightInches,
            weightPounds: profile.weightPounds,
            dailyCalories: profile.dailyCalories,
            exercise: profile.exercise,
            sleepHours: profile.sleepHours,
            stress: profile.stress
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Your Future Self")
                    .font(.largeTitle)
                    .bold()

                Text("Hello \(profile.name.isEmpty ? "there" : profile.name). Here is a first 1-year projection based on your current inputs.")
                    .font(.title3)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Tier 1: Health Projection")
                        .font(.headline)

                    statRow("Current BMI", value: "\(projection.currentBMI, specifier: "%.1f") - \(projection.bmiCategory)")
                    statRow("Maintenance", value: "~\(projection.maintenanceCalories) calories/day")
                    statRow("Projected weight", value: "\(projection.projectedWeightRange.lowerBound, specifier: "%.0f")-\(projection.projectedWeightRange.upperBound, specifier: "%.0f") lb")
                    statRow("Projected BMI", value: "\(projection.projectedBMIRange.lowerBound, specifier: "%.1f")-\(projection.projectedBMIRange.upperBound, specifier: "%.1f")")
                    statRow("Life expectancy association", value: "\(projection.lifeExpectancyModifierRange.lowerBound, specifier: "%+.1f") to \(projection.lifeExpectancyModifierRange.upperBound, specifier: "%+.1f") years")

                    if let warning = projection.weightChangeWarning {
                        Text(warning)
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Tier 2: Illustrative")
                        .font(.headline)

                    statRow("Biological age", value: "~\(projection.biologicalAge)")
                    statRow("Weekly trend", value: "\(projection.weeklyWeightChange, specifier: "%+.1f") lb/week")
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)

                Text("These outputs describe population-level statistical associations for people with similar inputs. They are not medical advice, diagnosis, or a guaranteed prediction.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Future You")
    }

    private func statRow(_ title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .bold()
                .multilineTextAlignment(.trailing)
        }
    }
}
