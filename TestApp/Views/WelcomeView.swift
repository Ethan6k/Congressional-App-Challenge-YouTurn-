//
//  WelcomeView.swift
//  TestApp
//
//  Created by Ethan Hong on 7/19/26.
//
//  First screen on first launch: the logo, what YouTurn does, and a button
//  into the setup slides.
//

import SwiftUI

struct WelcomeView: View {

    @EnvironmentObject var profile: UserProfile

    /// Called when they finish the last setup slide.
    let onFinishSetup: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            YouTurnLogo()
                .frame(width: 150)
                .shadow(color: .black.opacity(0.3), radius: 20, y: 10)

            VStack(spacing: 12) {
                Text("YouTurn")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.text)

                Text("See where your habits are taking you,\nand turn toward where you want to be.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal)

            Spacer()

            NavigationLink {
                OnboardingView(onFinish: onFinishSetup)
            } label: {
                Text(profile.name.isEmpty ? "Get started" : "Continue where you left off")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .themedScreen()
        .toolbar(.hidden, for: .navigationBar)
    }
}
