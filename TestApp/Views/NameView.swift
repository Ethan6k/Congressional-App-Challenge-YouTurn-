//
//  NameView.swift
//  TestApp
//
//  Created by Ethan Hong on 7/19/26.
//

import SwiftUI

struct NameView: View {

    @EnvironmentObject var profile: UserProfile

    var body: some View {

        VStack(spacing:40) {

            Text("What's your name?")
                .font(.largeTitle)
                .bold()


            TextField(
                "Enter name",
                text: $profile.name
            )
            .textFieldStyle(.roundedBorder)
            .padding()


            NavigationLink {

                AgeView()
                    .environmentObject(profile)

            } label: {

                ContinueButton()

            }

        }
        .navigationTitle("Step 1")

    }
}
