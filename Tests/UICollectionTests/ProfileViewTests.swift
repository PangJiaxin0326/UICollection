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

private struct TestProfileDetailContent: ProfileDetailViewContent {
    var avatarURL = URL(string: "https://example.com/avatar.png")!
    var userName: Binding<String> = .constant("Alex")
    var userPronouns: Binding<String> = .constant("they/them")
    var userBio: Binding<String> = .constant("A short bio")
    var journalingFocus: Binding<String> = .constant("Reflection")
    var profileNotes: Binding<String> = .constant("Remember context")
    var countryDisplay: String? = "United States (US)"
    var birthdayDisplay: String? = "June 7, 2026"
    var constellation: ProfileDetailConstellation? = .init(name: "Gemini", symbol: "Gemini")

    func saveAvatarData(_ data: Data) async {}
}

@Test @MainActor func profileViewConfigAcceptsSnapshotProtocol() {
    let config = ProfileView<EmptyView>.Config(snapshot: TestProfileSnapshot())

    #expect(config.snapshot?.sessionCount == 1)
    #expect(config.snapshot?.activeDayCount == 6)
}

@Test @MainActor func profileDetailViewAcceptsContentProtocol() {
    let content = TestProfileDetailContent()
    let view = ProfileDetailView(content: content)

    #expect(content.userName.wrappedValue == "Alex")
    #expect(content.constellation?.name == "Gemini")
    _ = view
}
