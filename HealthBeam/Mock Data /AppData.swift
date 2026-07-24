import SwiftUI
import Combine
class AppState: ObservableObject {
    @Published var isDemoMode: Bool = true
}
