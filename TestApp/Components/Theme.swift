//
//  Theme.swift
//  TestApp
//
//  YouTurn's colors (taken from the logo) and the small building blocks
//  every screen shares: buttons, chips, cards, and number rows.
//

import SwiftUI

enum Theme {
    /// Logo background. Used behind every screen.
    static let navy = Color(hex: 0x1E2A4A)
    /// Slightly lighter navy for cards and input boxes.
    static let card = Color(hex: 0x283659)
    /// One step lighter again, for things sitting on a card.
    static let cardRaised = Color(hex: 0x34405F)
    static let border = Color(hex: 0x3E4B6B)
    /// Logo's gray stroke. Used for anything not selected.
    static let slate = Color(hex: 0x7D879C)
    /// Logo's arrow. Used only for things you tap or that show progress.
    static let amber = Color(hex: 0xFFB547)

    static let text = Color(hex: 0xF4F5F8)
    static let textSecondary = Color(hex: 0xC9CEDA)
    static let textMuted = Color(hex: 0x8F98AB)
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

extension View {
    /// Navy background behind the whole screen, including the nav bar.
    func themedScreen() -> some View {
        background(Theme.navy.ignoresSafeArea())
            .toolbarBackground(Theme.navy, for: .navigationBar)
    }

    /// The lighter-navy box used for rows, tips, and cards.
    func themedCard(cornerRadius: CGFloat = 12) -> some View {
        background(Theme.card, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(Theme.border, lineWidth: 1))
    }
}

// MARK: - Buttons

/// Amber, full-width button (Continue, Save, See my future).
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Theme.navy)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Theme.amber, in: RoundedRectangle(cornerRadius: 14))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

/// Outlined button for secondary actions (Add a workout, Update my info).
struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Theme.amber)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Theme.slate, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
            )
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

// MARK: - Chips

/// One tappable pill. Amber when selected, slate outline when not.
struct Chip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Theme.navy : Theme.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(isSelected ? Theme.amber : Color.clear))
                .overlay(Capsule().stroke(isSelected ? Theme.amber : Theme.slate, lineWidth: 1))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .animation(.easeOut(duration: 0.15), value: isSelected)
    }
}

/// Chips for a fixed list of choices, like Male/Female or Beginner/Advanced.
struct ChipPicker<Value: Hashable>: View {
    let options: [(label: String, value: Value)]
    @Binding var selection: Value

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(options.indices, id: \.self) { index in
                let option = options[index]
                Chip(label: option.label, isSelected: selection == option.value) {
                    selection = option.value
                }
            }
        }
    }
}

/// Chips that each save a number, like "0 1 2 3+" sugary drinks.
/// If `lastMeansOrMore` is on, the last chip also lights up for bigger numbers.
/// If the saved number matches no chip (e.g. 50 min when the chips are
/// 45 and 60), it snaps to the closest chip.
struct NumberChips: View {
    let options: [(label: String, value: Int)]
    @Binding var value: Int
    var lastMeansOrMore = false

    /// Plain number chips, e.g. 0...5 shows "0 1 2 3 4 5+".
    init(_ range: ClosedRange<Int>, value: Binding<Int>, lastMeansOrMore: Bool = true) {
        self.options = range.map { n in
            (n == range.upperBound && lastMeansOrMore ? "\(n)+" : "\(n)", n)
        }
        self._value = value
        self.lastMeansOrMore = lastMeansOrMore
    }

    init(options: [(label: String, value: Int)], value: Binding<Int>, lastMeansOrMore: Bool = false) {
        self.options = options
        self._value = value
        self.lastMeansOrMore = lastMeansOrMore
    }

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(options.indices, id: \.self) { index in
                let option = options[index]
                Chip(label: option.label, isSelected: isSelected(index)) {
                    value = option.value
                }
            }
        }
        .onAppear(perform: snapToClosestChip)
    }

    private func isSelected(_ index: Int) -> Bool {
        if options[index].value == value { return true }
        return lastMeansOrMore && index == options.count - 1 && value > options[index].value
    }

    private func snapToClosestChip() {
        guard !options.indices.contains(where: isSelected) else { return }
        if let closest = options.min(by: { abs($0.value - value) < abs($1.value - value) }) {
            value = closest.value
        }
    }
}

/// A small label above a group of chips.
struct QuestionLabel: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(Theme.textSecondary)
    }
}

// MARK: - Cards and rows

/// The "why we ask" box at the top of a slide.
struct TipCard: View {
    var heading: String? = nil
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let heading {
                Text(heading)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.amber)
            }
            Text(text)
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
    }
}

/// One line: label on the left, "−  170 lb  +" on the right.
/// Tap the number to type it instead.
struct StepperRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double = 1
    var unit: String = ""

    @State private var text = ""
    @FocusState private var isEditing: Bool

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .foregroundStyle(Theme.textSecondary)

            Spacer(minLength: 4)

            stepButton("minus", label: "Decrease \(title.lowercased())") {
                value = max(value - step, range.lowerBound)
            }

            TextField(title, text: $text)
                .keyboardType(step < 1 ? .decimalPad : .numberPad)
                .multilineTextAlignment(.center)
                .font(.body.weight(.semibold).monospacedDigit())
                .foregroundStyle(Theme.text)
                .frame(width: 58)
                .focused($isEditing)

            if !unit.isEmpty {
                Text(unit)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textMuted)
            }

            stepButton("plus", label: "Increase \(title.lowercased())") {
                value = min(value + step, range.upperBound)
            }
        }
        .padding(.leading, 14)
        .padding(.trailing, 6)
        .frame(minHeight: 52)
        .themedCard()
        .onAppear { text = formatted(value) }
        .onChange(of: value) {
            if !isEditing { text = formatted(value) }
        }
        .onChange(of: isEditing) {
            if !isEditing { commitText() }
        }
    }

    private func stepButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.amber)
                .frame(width: 40, height: 40)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .buttonRepeatBehavior(.enabled)  // hold to keep counting
        .accessibilityLabel(label)
    }

    private func commitText() {
        if let typed = Double(text) {
            let clamped = min(max(typed, range.lowerBound), range.upperBound)
            value = (clamped / step).rounded() * step
        }
        text = formatted(value)
    }

    private func formatted(_ number: Double) -> String {
        step < 1 ? String(format: "%.1f", number) : String(format: "%.0f", number)
    }
}

extension StepperRow {
    /// Same row for whole numbers like age or calories.
    init(title: String, intValue: Binding<Int>, range: ClosedRange<Double>, step: Double = 1, unit: String = "") {
        self.init(
            title: title,
            value: Binding(
                get: { Double(intValue.wrappedValue) },
                set: { intValue.wrappedValue = Int($0.rounded()) }
            ),
            range: range,
            step: step,
            unit: unit
        )
    }
}

/// Height as two menus: feet and inches. Stored in total inches.
struct HeightRow: View {
    @Binding var inches: Double
    var range: ClosedRange<Double> = 48...90

    private var feet: Binding<Int> {
        Binding(
            get: { Int(inches) / 12 },
            set: { setHeight(feet: $0, inches: Int(inches) % 12) }
        )
    }

    private var extraInches: Binding<Int> {
        Binding(
            get: { Int(inches) % 12 },
            set: { setHeight(feet: Int(inches) / 12, inches: $0) }
        )
    }

    var body: some View {
        HStack {
            Text("Height")
                .foregroundStyle(Theme.textSecondary)

            Spacer()

            Picker("Feet", selection: feet) {
                ForEach(4...7, id: \.self) { Text("\($0) ft").tag($0) }
            }
            Picker("Inches", selection: extraInches) {
                ForEach(0...11, id: \.self) { Text("\($0) in").tag($0) }
            }
        }
        .pickerStyle(.menu)
        .tint(Theme.text)
        .padding(.leading, 14)
        .padding(.trailing, 4)
        .frame(minHeight: 52)
        .themedCard()
    }

    private func setHeight(feet: Int, inches newInches: Int) {
        let total = Double(feet * 12 + newInches)
        inches = min(max(total, range.lowerBound), range.upperBound)
    }
}

// MARK: - Layout helpers

/// Spreads its children evenly from top to bottom, with equal gaps
/// above, between, and below them.
struct EvenlySpaced<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            ForEach(subviews: content) { subview in
                Spacer(minLength: 14)
                subview
            }
            Spacer(minLength: 14)
        }
    }
}

/// Lays children out left to right and wraps to a new line when full,
/// like words in a paragraph. Used for chips and food bubbles.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var centered = false

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(subviews, maxWidth: proposal.width ?? .infinity)
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(subviews, maxWidth: bounds.width) {
            var x = centered ? bounds.minX + (bounds.width - row.width) / 2 : bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: y + (row.height - size.height) / 2),
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(_ subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let widthIfAdded = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            if widthIfAdded > maxWidth && !current.indices.isEmpty {
                rows.append(current)
                current = Row()
            }
            current.width = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            current.height = max(current.height, size.height)
            current.indices.append(index)
        }
        if !current.indices.isEmpty {
            rows.append(current)
        }
        return rows
    }
}

extension View {
    /// Adds a "Done" button above the number keyboard (it has no return key).
    func keyboardDoneButton() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil
                    )
                }
            }
        }
    }
}
