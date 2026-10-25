//
//  GalleryView.swift
//  TestApp
//
//  Every uploaded photo and generated image, newest first. Images generated
//  together are grouped, and each is labeled with the data it was made from.
//

import SwiftUI

struct GalleryView: View {

    @EnvironmentObject var gallery: GalleryStore

    enum Filter: String, CaseIterable, Identifiable {
        case all = "All"
        case currentHabits = "Current"
        case followingPlan = "Plan"
        case photos = "My photos"

        var id: Self { self }

        func includes(_ kind: GalleryEntry.Kind) -> Bool {
            switch self {
            case .all: return true
            case .currentHabits: return kind == .currentHabits
            case .followingPlan: return kind == .followingPlan
            case .photos: return kind == .uploadedPhoto
            }
        }
    }

    @State private var filter: Filter = .all

    /// Entries grouped by when they were made together, newest group first.
    private var groups: [[GalleryEntry]] {
        let matching = gallery.entries.filter { filter.includes($0.kind) }
        let byBatch = Dictionary(grouping: matching, by: \.batchID)
        return byBatch.values
            .map { $0.sorted { order($0.kind) < order($1.kind) } }
            .sorted { $0[0].date > $1[0].date }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Picker("Show", selection: $filter) {
                    ForEach(Filter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)

                if groups.isEmpty {
                    ContentUnavailableView(
                        "No images yet",
                        systemImage: "photo.on.rectangle",
                        description: Text("Photos you upload and futures you generate will be saved here.")
                    )
                    .padding(.top, 40)
                }

                ForEach(groups, id: \.first!.id) { group in
                    groupCard(group)
                }
            }
            .padding()
        }
        .navigationTitle("Gallery")
        .themedScreen()
    }

    private func groupCard(_ group: [GalleryEntry]) -> some View {
        let first = group[0]

        return VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(groupTitle(first))
                    .font(.headline)
                Text(first.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .top, spacing: 12) {
                ForEach(group) { entry in
                    NavigationLink {
                        GalleryDetailView(entry: entry)
                    } label: {
                        thumbnail(entry)
                    }
                    .buttonStyle(.plain)
                }
                if group.count == 1 {
                    Spacer()
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(Theme.card)
        .cornerRadius(12)
    }

    private func thumbnail(_ entry: GalleryEntry) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Group {
                if let image = gallery.image(for: entry) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Theme.cardRaised
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(3 / 4, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(entry.kind.color, lineWidth: 2))

            Text(entry.kind.label)
                .font(.caption)
                .bold()
                .foregroundStyle(entry.kind.color)

            if let p = entry.snapshot.projection {
                Text("\(Int(p.weightLow.rounded()))-\(Int(p.weightHigh.rounded())) lb")
                    .font(.caption)
                Text("Age \(p.futureAge) · body age ~\(p.bodyAge)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("\(Int(entry.snapshot.weightPounds.rounded())) lb · age \(entry.snapshot.age)")
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func groupTitle(_ entry: GalleryEntry) -> String {
        guard let p = entry.snapshot.projection else {
            return "Uploaded photo"
        }
        return "\(FutureScenario.horizonLabel(months: p.horizonMonths)) ahead\(entry.fromPhoto ? " · from your photo" : "")"
    }

    private func order(_ kind: GalleryEntry.Kind) -> Int {
        switch kind {
        case .currentHabits: return 0
        case .followingPlan: return 1
        case .uploadedPhoto: return 2
        }
    }
}

extension GalleryEntry.Kind {
    var color: Color {
        switch self {
        case .currentHabits: return .orange
        case .followingPlan: return .green
        case .uploadedPhoto: return Theme.slate
        }
    }
}

/// One image, full size, with all the data it was made from.
struct GalleryDetailView: View {

    @EnvironmentObject var gallery: GalleryStore
    @Environment(\.dismiss) private var dismiss
    let entry: GalleryEntry

    @State private var confirmDelete = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let image = gallery.image(for: entry) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Text(entry.kind.label)
                    .font(.title2)
                    .bold()
                    .foregroundStyle(entry.kind.color)

                if let p = entry.snapshot.projection {
                    section("Projected \(FutureScenario.horizonLabel(months: p.horizonMonths)) ahead") {
                        row("Age", "\(p.futureAge)")
                        row("Weight", "\(Int(p.weightLow.rounded()))-\(Int(p.weightHigh.rounded())) lb")
                        row("BMI", String(format: "%.1f-%.1f", p.bmiLow, p.bmiHigh))
                        row("Body age", "~\(p.bodyAge)")
                        Text(p.habits)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                section("Your data when this was made") {
                    let s = entry.snapshot
                    row("Date", entry.date.formatted(date: .abbreviated, time: .shortened))
                    row("Age", "\(s.age)")
                    row("Height", "\(Int(s.heightInches) / 12)' \(Int(s.heightInches) % 12)\"")
                    row("Weight", "\(Int(s.weightPounds.rounded())) lb")
                    row("Goal", s.goal)
                    row("Calories", "\(s.dailyCalories)/day")
                    row("Sleep", String(format: "%.1f hrs/night", s.sleepHours))
                    row("Exercise", s.exercise)
                    if entry.snapshot.projection != nil {
                        row("Made from", entry.fromPhoto ? "Your photo" : "AI-created person")
                    }
                }

                Button("Delete from gallery", role: .destructive) {
                    confirmDelete = true
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .navigationTitle(entry.date.formatted(date: .abbreviated, time: .omitted))
        .themedScreen()
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete this image?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                gallery.delete(entry)
                dismiss()
            }
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card)
        .cornerRadius(8)
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .bold()
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}
