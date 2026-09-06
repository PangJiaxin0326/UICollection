import AIToolKit
import Testing
@testable import AIUICollection

@Suite struct WorkflowValidationTests {
    @MainActor @Test func catalogRejectsOverlappingRunsAndReleasesAdmission() {
        let catalog = AIViewCatalog(sources: [])
        #expect(catalog.beginRun())
        #expect(!catalog.beginRun())
        catalog.endRun()
        #expect(catalog.beginRun())
        catalog.endRun()
    }

    @Test func plansPreserveOrderWithoutExpandingNames() {
        let selection = ToolSelection(toolNames: [" CREATE_CHART ", "create_list", "use create_grid"])
        #expect(ProgressiveViewWorkflowRunner.orderedPlan(from: selection,
            finishingNames: ["create", "create_list", "create_chart", "create_grid"], cap: 4)
            == ["create_chart", "create_list"])
    }

    @Test func negativeLimitsProduceEmptyPreviewsAndPlans() {
        #expect(ProgressiveViewWorkflowRunner.orderedPlan(from: ToolSelection(toolNames: ["create_list"]),
            finishingNames: ["create_list"], cap: -1).isEmpty)
        #expect(AISectionBuilder.capped([], -1).isEmpty)
    }
}
