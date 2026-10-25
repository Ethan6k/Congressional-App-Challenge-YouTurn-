//
//  LifestyleView.swift
//  TestApp
//
//  Created by Ethan Hong on 7/19/26.
//

import SwiftUI


struct LifestyleView: View {

    @EnvironmentObject var profile: UserProfile


    var body: some View {

        Form {


            Section("Sleep") {

                Slider(
                    value: $profile.sleepHours,
                    in: 0...12,
                    step: 0.5
                )

                Text(
                    "\(profile.sleepHours, specifier: "%.1f") hours"
                )

            }



            Section("Exercise") {

                Picker(
                    "Exercise",
                    selection: $profile.exercise
                ) {

                    Text("Never")
                        .tag("Never")

                    Text("1-2 days")
                        .tag("1-2 days")

                    Text("3-4 days")
                        .tag("3-4 days")

                    Text("Daily")
                        .tag("Daily")
                }

            }



            Section("Stress") {

                Stepper(
                    "Stress \(profile.stress)/10",
                    value: $profile.stress,
                    in: 1...10
                )

            }



            NavigationLink {

                FutureView()
                    .environmentObject(profile)

            } label: {

                ContinueButton()

            }

        }
        .navigationTitle("Step 3")

    }
}
