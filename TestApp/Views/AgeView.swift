//
//  AgeView.swift
//  TestApp
//
//  Created by Ethan Hong on 7/19/26.
//

import SwiftUI

struct AgeView: View {

    @EnvironmentObject var profile: UserProfile

    var body: some View {

        VStack(spacing:40) {

            Text("How old are you?")
                .font(.largeTitle)
                .bold()


            Stepper(
                "\(profile.age) years old",
                value: $profile.age,
                in: 5...100
            )
            .padding()


            NavigationLink {

                LifestyleView()
                    .environmentObject(profile)

            } label: {

                ContinueButton()

            }

        }
        .navigationTitle("Step 2")

    }
}
