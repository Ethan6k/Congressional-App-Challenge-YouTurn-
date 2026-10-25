//
//  MainTabView.swift
//  TestApp
//
//  After setup, the app is four tabs: Home, Future, Plan, and Gallery.
//

import SwiftUI

enum AppTab: Hashable {
    case home, future, plan, gallery
}

struct MainTabView: View {

    @EnvironmentObject var profile: UserProfile
    @EnvironmentObject var tutorial: TutorialController
    @Binding var selectedTab: AppTab

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house", value: AppTab.home) {
                NavigationStack {
                    HomeView(selectedTab: $selectedTab)
                }
            }

            Tab("Future", systemImage: "sparkles", value: AppTab.future) {
                NavigationStack {
                    FutureView()
                }
            }

            Tab("Plan", systemImage: "dumbbell", value: AppTab.plan) {
                NavigationStack {
                    PlanTabView()
                }
            }

            Tab("Gallery", systemImage: "photo.on.rectangle", value: AppTab.gallery) {
                NavigationStack {
                    GalleryView()
                }
            }
        }
        .task {
            // First time here: give the results a moment to appear, then start the tour.
            guard !profile.hasSeenTutorial else { return }
            try? await Task.sleep(for: .seconds(0.8))
            tutorial.start()
        }
        .onChange(of: tutorial.stepIndex) {
            // Each step lives on a tab; go there.
            if let step = tutorial.step {
                selectedTab = step.tab
            }
        }
    }
}
