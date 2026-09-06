# UICollection

SwiftUI components and optional AI-driven view generation for iOS, macOS, and visionOS 27.
`UICollection` contains general UI; `AIUICollection` uses the native Foundation Models workflow profiles from AIToolKit.

Requires the Swift 6.4 toolchain for the pinned AIToolKit dependency. Run `swift build` and `swift test`.
The default manifest resolves the audited AIToolKit revision from GitHub. For sibling-checkout development, set `SWIFTPACKAGES_USE_LOCAL_DEPENDENCIES=1` before building.

View-generation runners reject overlapping runs on the same catalog. Invalid selections never enable the full tool set, and failed tool calls are not automatically replayed. Negative component and preview limits produce empty results. Progressive callbacks report only newly created components.
