//
//  WorkoutLog.swift
//  TestApp
//
//  Remembers which planned exercises the user checked off, by date, so the
//  Plan and Home tabs can show progress for this week. Saved on the phone.
//

import Combine
import Foundation

final class WorkoutLog: ObservableObject {

    /// "2026-10-12" → names of the exercises checked off that day.
    @Published private var done: [String: Set<String>] = [:]

    init() {
        load()
    }

    func isDone(_ item: String, on date: Date) -> Bool {
        done[Self.key(for: date)]?.contains(item) ?? false
    }

    func toggle(_ item: String, on date: Date) {
        let key = Self.key(for: date)
        if done[key, default: []].contains(item) {
            done[key]?.remove(item)
        } else {
            done[key, default: []].insert(item)
        }
        save()
    }

    /// A day counts as done once every item on it is checked off.
    /// Rest days have nothing to check, so they never count.
    func isComplete(_ day: WorkoutDay, on date: Date) -> Bool {
        let items = Self.checklist(for: day)
        return !items.isEmpty && items.allSatisfy { isDone($0, on: date) }
    }

    /// What can be checked off on a day: each exercise on strength days,
    /// or the whole session on cardio days.
    static func checklist(for day: WorkoutDay) -> [String] {
        switch day.kind {
        case .strength: return day.exercises.map(\.name)
        case .cardio: return [day.name]
        case .rest: return []
        }
    }

    /// Erases every check-off.
    func resetAll() {
        done = [:]
        try? FileManager.default.removeItem(at: Self.fileURL)
    }

    // MARK: - This week (Monday to Sunday)

    private static var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 2  // Monday, to match the plan
        return calendar
    }

    /// The 7 dates of the current week, Monday first.
    static func datesThisWeek(containing today: Date = .now) -> [Date] {
        let start = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    /// 0 for Monday through 6 for Sunday.
    static func todayIndex(_ today: Date = .now) -> Int {
        (calendar.component(.weekday, from: today) + 5) % 7
    }

    // MARK: - Saving and loading

    private static func key(for date: Date) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    private static var fileURL: URL {
        URL.applicationSupportDirectory.appending(path: "workout-log.json")
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(at: URL.applicationSupportDirectory, withIntermediateDirectories: true)
            try JSONEncoder().encode(done).write(to: Self.fileURL, options: [.atomic, .completeFileProtectionUnlessOpen])
        } catch {
            print("Could not save workout log: \(error)")
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: Self.fileURL),
              let saved = try? JSONDecoder().decode([String: Set<String>].self, from: data) else {
            return
        }
        done = saved
    }
}
