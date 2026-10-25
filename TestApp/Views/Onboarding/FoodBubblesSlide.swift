//
//  FoodBubblesSlide.swift
//  TestApp
//
//  Slide 6 (optional): type foods you eat often. Each one floats as a bubble;
//  tap a bubble to pop it off the list. The list feeds MealAnalyzer, which
//  looks for foods it recognizes to give more specific tips.
//

import SwiftUI

struct FoodBubblesSlide: View {

    @EnvironmentObject var profile: UserProfile
    let onContinue: () -> Void

    @State private var newFood = ""
    @State private var error: String?
    @FocusState private var isTyping: Bool

    var body: some View {
        Slide(
            title: "Foods you eat often",
            buttonTitle: profile.foods.isEmpty ? "Skip for now" : "Continue",
            fillsHeight: true,
            onContinue: onContinue
        ) {
            Text(profile.foods.isEmpty
                 ? "Optional. Add a few foods or drinks you have most weeks."
                 : "Tap a bubble to pop it off.")
                .font(.footnote)
                .foregroundStyle(Theme.textMuted)
                .frame(maxWidth: .infinity, alignment: .leading)

            // The bubble area stretches to fill the space between the hint and the text box.
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Theme.border, style: StrokeStyle(lineWidth: 1, dash: [6, 5]))

                if profile.foods.isEmpty {
                    Label("Your foods will float here", systemImage: "bubble.left.and.bubble.right")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textMuted)
                }

                FlowLayout(spacing: 10, centered: true) {
                    ForEach(profile.foods, id: \.self) { food in
                        FoodBubble(name: food) {
                            profile.foods.removeAll { $0 == food }
                        }
                        .transition(.scale(scale: 0.2).combined(with: .opacity))
                    }
                }
                .padding(16)
            }
            .frame(maxWidth: .infinity, minHeight: 160, maxHeight: .infinity)
            .animation(.spring(duration: 0.35, bounce: 0.4), value: profile.foods)

            VStack(alignment: .leading, spacing: 6) {
                addRow
                if let error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    /// Text box and Add button: same height, centered on the same line.
    private var addRow: some View {
        HStack(alignment: .center, spacing: 8) {
            TextField("Greek yogurt", text: $newFood)
                .foregroundStyle(Theme.text)
                .focused($isTyping)
                .submitLabel(.done)
                .onSubmit(addFood)
                .onChange(of: newFood) { error = nil }
                .padding(.horizontal, 12)
                .frame(height: 44)
                .themedCard(cornerRadius: 10)

            Button(action: addFood) {
                Label("Add", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.amber)
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.amber, lineWidth: 1))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private func addFood() {
        let food = newFood.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !food.isEmpty else {
            error = "Type a food first."
            return
        }
        guard food.count <= 40 else {
            error = "Keep it short: 40 characters or less."
            return
        }
        guard profile.foods.count < 30 else {
            error = "That's 30 foods, the most you can add."
            return
        }
        if !profile.foods.contains(where: { $0.caseInsensitiveCompare(food) == .orderedSame }) {
            profile.foods.append(food)
        }
        newFood = ""
        isTyping = true  // keep the keyboard up for the next one
    }
}

/// One floating food bubble. Bobs gently; tapping it pops it.
private struct FoodBubble: View {
    let name: String
    let onPop: () -> Void

    @State private var isFloatingUp = false
    @State private var isPopping = false

    var body: some View {
        Text(name)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Theme.amber)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Theme.card, in: Capsule())
            .overlay(Capsule().stroke(Theme.amber, lineWidth: 1.5))
            .offset(y: isFloatingUp ? -4 : 0)
            .scaleEffect(isPopping ? 1.6 : 1)
            .opacity(isPopping ? 0 : 1)
            .onAppear {
                // Each bubble starts at a random moment so they don't bob in sync.
                withAnimation(.easeInOut(duration: 1.5).repeatForever().delay(.random(in: 0...1.5))) {
                    isFloatingUp = true
                }
            }
            .onTapGesture(perform: pop)
            .sensoryFeedback(.impact(weight: .light), trigger: isPopping)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(name)
            .accessibilityHint("Removes this food")
    }

    private func pop() {
        guard !isPopping else { return }
        withAnimation(.easeOut(duration: 0.18)) { isPopping = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18, execute: onPop)
    }
}
