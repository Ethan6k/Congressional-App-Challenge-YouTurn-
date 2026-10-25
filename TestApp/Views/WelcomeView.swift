//
//  WelcomeView.swift
//  TestApp
//
//  Created by Ethan Hong on 7/19/26.
//

import SwiftUI

struct WelcomeView: View {

    @StateObject var profile = UserProfile()

    var body: some View {

        NavigationStack {

            VStack(spacing: 30) {

                Spacer()

                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(.blue)

                Text("Meet Your Future Self")
                    .font(.largeTitle)
                    .bold()

                Text("""
                Discover how your daily habits
                shape the person you become.
                """)
                .multilineTextAlignment(.center)
                .foregroundStyle(.gray)


                Spacer()


                NavigationLink {

                    NameView()
                        .environmentObject(profile)

                } label: {

                    Text("Begin Journey")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundColor(.white)
                        .cornerRadius(15)

                }
                .padding()

            }

        }

    }
}
