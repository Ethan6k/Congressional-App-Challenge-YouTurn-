//
//  TestAppApp.swift
//  TestApp
//
//  Created by Ethan Hong on 7/19/26.
//

import SwiftUI
import FirebaseAppCheck
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    #if DEBUG
    // Firebase AI Logic requires App Check. The debug provider prints a token in
    // Xcode's console; register that token in Firebase before testing locally.
    AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
    #endif
    FirebaseApp.configure()

    return true
  }
}

@main
struct TestAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

/// First launch: welcome screen and setup slides. After setup: the tabs.
struct RootView: View {

    // Loads the saved profile, gallery, and workout check-offs from the phone.
    @StateObject private var profile = UserProfile()
    @StateObject private var gallery = GalleryStore()
    @StateObject private var log = WorkoutLog()
    @StateObject private var tutorial = TutorialController()

    @State private var selectedTab: AppTab = .home
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if profile.hasCompletedSetup {
                MainTabView(selectedTab: $selectedTab)
            } else {
                NavigationStack {
                    WelcomeView {
                        selectedTab = .future  // land on their results first
                        profile.hasCompletedSetup = true
                    }
                }
            }
        }
        .overlay {
            TutorialOverlay {
                profile.hasSeenTutorial = true
                tutorial.stop()
                selectedTab = .future  // end back on their results
            }
        }
        .animation(.easeInOut, value: profile.hasCompletedSetup)
        .onChange(of: scenePhase) {
            // Save right away when the app is closed or sent to the background.
            if scenePhase != .active {
                profile.save()
            }
        }
        .environmentObject(tutorial)
        .environmentObject(profile)
        .environmentObject(gallery)
        .environmentObject(log)
        .preferredColorScheme(.dark)
        .tint(Theme.amber)
    }
}
