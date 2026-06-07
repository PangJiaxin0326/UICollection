import Foundation
import SwiftUI
import Testing
@testable import UICollection

private struct TestProfileSnapshot: ProfileViewSnapshot {
    var sessionCount = 1
    var messageCount = 2
    var totalTokenUsage = 3
    var streakDays = 4
    var longestStreakDays = 5
    var activeDayCount = 6
    var activityDates: [Date] = []
    var activeSinceDate: Date?
}

@Test @MainActor func profileViewConfigAcceptsSnapshotProtocol() {
    let config = ProfileView<EmptyView>.Config(snapshot: TestProfileSnapshot())

    #expect(config.snapshot?.sessionCount == 1)
    #expect(config.snapshot?.activeDayCount == 6)
}
