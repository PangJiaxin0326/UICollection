import Testing
@testable import UICollection

@Test func compactCountFormatterUsesExpectedSuffixes() async throws {
    #expect(ProfileMetricFormatter.compactCount(999) == "999")
    #expect(ProfileMetricFormatter.compactCount(1_200) == "1.2K")
    #expect(ProfileMetricFormatter.compactCount(1_000_000) == "1M")
    #expect(ProfileMetricFormatter.compactCount(2_500_000_000) == "2.5B")
}
