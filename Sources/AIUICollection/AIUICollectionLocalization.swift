import Foundation
import SwiftUI

enum AIUICollectionLocalization {
    static func string(_ value: String.LocalizationValue) -> String {
        String(localized: value, bundle: .module)
    }
}

func aiUICollectionText(_ key: LocalizedStringKey) -> Text {
    Text(key, bundle: .module)
}
