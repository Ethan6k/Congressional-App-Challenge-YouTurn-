//
//  HowItWorksView.swift
//  TestApp
//
//  Explains where every number in the app comes from, what data leaves the
//  phone, and what tools (including AI) were used to build YouTurn.
//

import SwiftUI

struct HowItWorksView: View {

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Every number in YouTurn comes from fixed formulas and published guidelines, not AI. Only the future images use AI.")
                    .foregroundStyle(Theme.textSecondary)

                topic(
                    "Calories you burn",
                    icon: "flame.fill",
                    text: "Your resting burn uses the Mifflin-St Jeor equation (age, sex, height, weight). We multiply it by 1.2 for normal daily movement, then add what your workouts burn.",
                    sources: ["Mifflin MD, St Jeor ST, et al. American Journal of Clinical Nutrition, 1990"]
                )

                topic(
                    "Calories burned by workouts",
                    icon: "figure.run",
                    text: "Each exercise type and intensity has a MET value: how many times more energy it uses than sitting still. Workout calories = (MET - 1) × your weight × time.",
                    sources: ["Compendium of Physical Activities (Ainsworth et al.)"]
                )

                topic(
                    "Weight forecast",
                    icon: "chart.line.uptrend.xyaxis",
                    text: "About 3,500 extra calories adds roughly 1 lb, and 3,500 fewer removes about 1 lb. We simulate week by week and recalculate how much you burn as your weight changes, so weight levels off instead of changing forever in a straight line. Results are shown as a range because every body responds differently.",
                    sources: ["Hall KD, et al. \"Quantification of the effect of energy imbalance on bodyweight.\" The Lancet, 2011"]
                )

                topic(
                    "Activity guidelines",
                    icon: "heart.fill",
                    text: "Adults should get at least 150 minutes of moderate activity a week (vigorous minutes count double) and strength train at least 2 days a week. Intensity uses the \"talk test.\"",
                    sources: ["Physical Activity Guidelines for Americans, 2nd edition (U.S. Dept. of Health and Human Services, 2018)", "CDC: Measuring Physical Activity Intensity"]
                )

                topic(
                    "Protein, fiber, and calorie targets",
                    icon: "fork.knife",
                    text: "Protein: about 0.7-1.0 g per lb of body weight when losing weight or building muscle, less for general health. Fiber: 14 g per 1,000 calories. Calories: about 500 less than you burn to lose weight (250 for teens), about 300 more to build muscle. We never suggest less than 1,200 (women) or 1,500 (men) calories a day.",
                    sources: ["International Society of Sports Nutrition position stand: protein and exercise (Jäger et al., 2017)", "Morton RW, et al. British Journal of Sports Medicine, 2018", "Dietary Guidelines for Americans, 2020-2025", "NIH National Heart, Lung, and Blood Institute guidance on calorie levels for weight loss"]
                )

                topic(
                    "BMI",
                    icon: "scalemass.fill",
                    text: "BMI is weight compared to height. Adult categories (18.5-24.9 is the healthy range) don't apply under 20, so we don't label BMI for younger users.",
                    sources: ["CDC: About Adult BMI"]
                )

                topic(
                    "Workout plans",
                    icon: "dumbbell.fill",
                    text: "Your plan comes from a set of rules (a decision tree): where you train picks the exercises, your goal and available days pick the mix of strength and cardio, and your experience picks sets and difficulty. Rep ranges follow common strength-training guidelines.",
                    sources: ["American College of Sports Medicine: Resistance training guidelines"]
                )

                topic(
                    "Body age and lifespan effect",
                    icon: "hourglass",
                    text: "These are rough, illustrative scores we built from general research trends: regular exercise, enough sleep, and a healthy weight are linked to longer, healthier lives. They are not a medical test or a prediction for you.",
                    sources: []
                )

                topic(
                    "Future images",
                    icon: "sparkles",
                    text: "The two future images are made by Google's Gemini AI. When you tap Generate, your stats and habits (and your photo, if you added one) are sent to Gemini through Google Firebase to create them. The images are illustrations, not predictions of exactly how you'll look.",
                    sources: []
                )

                topic(
                    "Your privacy",
                    icon: "lock.fill",
                    text: "Your answers, photos, generated images, and workout check-offs are saved only on this phone, and iOS encrypts them while your phone is locked. The only time anything leaves your phone is when you generate images: the app asks first, then sends your stats, habits, plan targets, and forecasts (plus your photo, if you added one) over an encrypted connection. Your name and food list are never sent. YouTurn has no accounts, ads, or tracking. \"Reset all data\" on the Home tab erases everything.",
                    sources: []
                )

                topic(
                    "Built with",
                    icon: "hammer.fill",
                    text: "YouTurn was created by Ethan Hong using Swift and SwiftUI in Xcode, with Google Firebase AI Logic for image generation. The app's code was written with help from Claude, an AI assistant made by Anthropic. Ethan designed the features and how the app works, reviewed the health rules, and tested the app.",
                    sources: []
                )

                Text("YouTurn is for general wellness and education. It isn't medical advice. Talk to a doctor before making big changes to your diet or exercise, especially if you have a health condition.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textMuted)
            }
            .padding()
        }
        .navigationTitle("How YouTurn works")
        .navigationBarTitleDisplayMode(.inline)
        .themedScreen()
    }

    private func topic(_ title: String, icon: String, text: String, sources: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(Theme.text)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if !sources.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sources")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.amber)
                    ForEach(sources, id: \.self) { source in
                        Text("• \(source)")
                            .font(.caption)
                            .foregroundStyle(Theme.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .themedCard()
    }
}
