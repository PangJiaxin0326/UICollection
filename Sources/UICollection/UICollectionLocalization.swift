import Foundation
import SwiftUI

enum UICollectionLocalization {
    static func string(_ value: String.LocalizationValue) -> String {
        String(localized: value, bundle: .module)
    }
}

func uiCollectionText(_ key: LocalizedStringKey) -> Text {
    Text(key, bundle: .module)
}
