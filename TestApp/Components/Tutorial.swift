//
//  Tutorial.swift
//  TestApp
//
//  The first-time guided tour shown right after setup. The screen darkens,
//  one part of the app is spotlighted, and a card explains it. "Next" moves
//  to the next part, switching tabs and scrolling as needed.
//
//  To spotlight something, add `.tutorialTarget("some.id")` to it and add a
//  step with that id to `TutorialStep.all`.
//

import Combine
import SwiftUI

struct TutorialStep {
    /// Matches a `.tutorialTarget(...)` id. `tabBarTarget` spotlights the tab bar.
    let target: String
    /// Which tab the step is on (the tour switches there automatically).
    let tab: AppTab
    let title: String
    let message: String

    static let tabBarTarget = "tabBar"

    static let all: [TutorialStep] = [
        // Results
        TutorialStep(target: "future.images", tab: .future,
                     title: "Meet your two futures",
                     message: "On the left is you if you keep your current habits. On the right is you if you follow your plan."),
        TutorialStep(target: "future.photo", tab: .future,
                     title: "Add your photo (optional)",
                     message: "With a photo, both futures look like you. Without one, we make a person who matches your info."),
        TutorialStep(target: "future.horizon", tab: .future,
                     title: "Choose how far ahead",
                     message: "Look 6 months to 10 years out. Each time frame keeps its own images."),
        TutorialStep(target: "future.generate", tab: .future,
                     title: "Generate your futures",
                     message: "Tap here to create both images. They're made by Google's Gemini AI from your info (and your photo, if you added one). Every set is saved in your Gallery."),
        TutorialStep(target: "future.nutrition", tab: .future,
                     title: "Your nutrition plan",
                     message: "Daily calorie, protein, and fiber targets, plus the changes that matter most for your goal."),
        TutorialStep(target: "future.forecast", tab: .future,
                     title: "Your 1-year forecast",
                     message: "Where your weight is heading if nothing changes. Every number has a plain-English explanation."),

        // Plan
        TutorialStep(target: "plan.week", tab: .plan,
                     title: "Your week",
                     message: "Tap a day to see its workout. Filled dots are training days, empty ones are rest days."),
        TutorialStep(target: "plan.day", tab: .plan,
                     title: "Check off as you go",
                     message: "Tap each exercise when you finish it. A day you complete gets a checkmark."),
        TutorialStep(target: "plan.why", tab: .plan,
                     title: "Why this plan?",
                     message: "See the flowchart showing how each of your answers shaped your plan."),

        // Home
        TutorialStep(target: "home.progress", tab: .home,
                     title: "Your week at a glance",
                     message: "This ring fills up as you check off workouts. Tap it to jump to your plan."),
        TutorialStep(target: "home.tiles", tab: .home,
                     title: "Today",
                     message: "Today's workout and your top food tip. Tap either one to open it."),
        TutorialStep(target: "home.update", tab: .home,
                     title: "Something changed?",
                     message: "Update your answers anytime. Your plan and numbers update right away."),

        // Getting around
        TutorialStep(target: tabBarTarget, tab: .home,
                     title: "Getting around",
                     message: "Use these tabs to switch between Home, your Future, your Plan, and your Gallery of images. That's it. Let's go!"),
    ]
}

/// Tracks which tutorial step is showing and where each target is on screen.
final class TutorialController: ObservableObject {

    @Published private(set) var stepIndex: Int?

    /// Every target's frame in screen coordinates. Not @Published, so
    /// scrolling doesn't redraw the app; only the current target's changes do.
    private(set) var frames: [String: CGRect] = [:]

    var step: TutorialStep? { stepIndex.map { TutorialStep.all[$0] } }
    var isLastStep: Bool { stepIndex == TutorialStep.all.count - 1 }

    func start() {
        stepIndex = 0
    }

    func next() {
        guard let index = stepIndex, index + 1 < TutorialStep.all.count else { return }
        stepIndex = index + 1
    }

    func stop() {
        stepIndex = nil
    }

    func report(_ id: String, frame: CGRect) {
        guard frames[id] != frame else { return }
        frames[id] = frame
        if step?.target == id {
            objectWillChange.send()
        }
    }
}

extension View {
    /// Marks this view as something the tutorial can spotlight and scroll to.
    func tutorialTarget(_ id: String) -> some View {
        modifier(TutorialTargetModifier(id: id))
    }
}

private struct TutorialTargetModifier: ViewModifier {
    @EnvironmentObject var tutorial: TutorialController
    let id: String

    func body(content: Content) -> some View {
        content
            .id(id)  // lets ScrollViewReader scroll to it
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame in
                tutorial.report(id, frame: frame)
            }
    }
}

/// Scrolls a tab's ScrollView so the current step's target is in view.
@MainActor
func scrollToTutorialStep(on tab: AppTab, using scroller: ScrollViewProxy, tutorial: TutorialController) async {
    guard let step = tutorial.step, step.tab == tab else { return }
    try? await Task.sleep(for: .milliseconds(150))  // let the tab finish appearing
    withAnimation(.easeInOut(duration: 0.4)) {
        scroller.scrollTo(step.target, anchor: .center)
    }
}

// MARK: - The overlay

/// Covers the whole screen: dark everywhere except a cutout around the
/// current target, plus the explanation card with Next / Skip.
struct TutorialOverlay: View {
    @EnvironmentObject var tutorial: TutorialController
    let onFinish: () -> Void

    var body: some View {
        if let step = tutorial.step, let index = tutorial.stepIndex {
            GeometryReader { proxy in
                let insets = proxy.safeAreaInsets
                let screen = CGSize(
                    width: proxy.size.width + insets.leading + insets.trailing,
                    height: proxy.size.height + insets.top + insets.bottom
                )
                let cutout = cutoutRect(for: step, screen: screen, insets: insets)

                ZStack(alignment: .topLeading) {
                    SpotlightShape(cutout: cutout, cornerRadius: step.target == TutorialStep.tabBarTarget ? 34 : 16)
                        .fill(Color.black.opacity(0.72), style: FillStyle(eoFill: true))
                        .contentShape(Rectangle())  // blocks taps on the app while the tour runs
                        .onTapGesture {}

                    if let cutout {
                        RoundedRectangle(cornerRadius: step.target == TutorialStep.tabBarTarget ? 34 : 16)
                            .stroke(Theme.amber, lineWidth: 2)
                            .frame(width: cutout.width, height: cutout.height)
                            .offset(x: cutout.minX, y: cutout.minY)
                            .allowsHitTesting(false)
                    }

                    let placement = cardPlacement(cutout, screen: screen, insets: insets)
                    card(step, index: index)
                        .frame(width: min(screen.width - 32, 420))
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: .infinity, alignment: placement.alignment)
                        .padding(.top, placement.top)
                        .padding(.bottom, placement.bottom)
                }
                .frame(width: screen.width, height: screen.height)
                .offset(x: -insets.leading, y: -insets.top)
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: index)
        }
    }

    private func card(_ step: TutorialStep, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(index + 1) of \(TutorialStep.all.count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.amber)

            Text(step.title)
                .font(.title3.bold())
                .foregroundStyle(Theme.text)

            Text(step.message)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                if !tutorial.isLastStep {
                    Button("Skip tour", action: onFinish)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textMuted)
                }
                Spacer()
                Button {
                    if tutorial.isLastStep {
                        onFinish()
                    } else {
                        tutorial.next()
                    }
                } label: {
                    Text(tutorial.isLastStep ? "Get started" : "Next")
                        .font(.headline)
                        .foregroundStyle(Theme.navy)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 10)
                        .background(Theme.amber, in: Capsule())
                }
            }
            .padding(.top, 4)
        }
        .padding(18)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.border, lineWidth: 1))
        .id(index)  // fade between cards instead of morphing the text
    }

    /// Where to cut the hole, padded a little and kept on screen.
    private func cutoutRect(for step: TutorialStep, screen: CGSize, insets: EdgeInsets) -> CGRect? {
        if step.target == TutorialStep.tabBarTarget {
            // The floating tab bar sits just above the home indicator.
            return CGRect(x: 16, y: screen.height - insets.bottom - 52, width: screen.width - 32, height: 70)
        }
        guard let frame = tutorial.frames[step.target], frame.width > 0 else { return nil }
        let padded = frame.insetBy(dx: -8, dy: -8)
        let visible = CGRect(x: 0, y: insets.top, width: screen.width, height: screen.height - insets.top - insets.bottom)
        let clipped = padded.intersection(visible)
        return clipped.isNull ? nil : clipped
    }

    /// Put the card on whichever side of the cutout has more room. If the
    /// cutout is so tall that neither side fits the card, it sits near the
    /// bottom of the screen, over the cutout.
    private func cardPlacement(_ cutout: CGRect?, screen: CGSize, insets: EdgeInsets)
        -> (alignment: Alignment, top: CGFloat, bottom: CGFloat) {
        let neededSpace: CGFloat = 250
        guard let cutout else {
            return (.center, 0, 0)
        }
        let spaceAbove = cutout.minY - insets.top
        let spaceBelow = screen.height - insets.bottom - cutout.maxY
        if max(spaceAbove, spaceBelow) < neededSpace {
            return (.bottom, 0, insets.bottom + 90)
        }
        if spaceBelow >= spaceAbove {
            return (.top, cutout.maxY + 16, 0)
        }
        return (.bottom, 0, screen.height - cutout.minY + 16)
    }
}

/// A full-screen rectangle with a rounded hole (drawn with even-odd fill).
private struct SpotlightShape: Shape {
    let cutout: CGRect?
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path(rect)
        if let cutout {
            path.addRoundedRect(in: cutout, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
        }
        return path
    }
}
