import Combine
import CombineRex
import Foundation
import SwiftRex

struct AppState {
    var count: Int
}

enum AppAction {
    case increment
    case decrement
}

let counterReducer = Reducer<AppAction, AppState> { action, state in
    switch action {
    case .decrement:
        return AppState(count: state.count - 1)
    case .increment:
        return AppState(count: state.count + 1)
    }
}

let store = ReduxStoreBase<AppAction, AppState>(
    subject: .combine(initialValue: AppState(count: 0)),
    reducer: counterReducer,
    middleware: IdentityMiddleware() // <- No side-effects yet
)

class ViewController: UIViewController {
    private var subscription: AnyCancellable?
    @IBOutlet private var label: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        subscription = store.statePublisher
            .map { $0.count }
            .map { "\($0)" }
            .assign(to: \.text, on: label)
    }
    @IBAction func minusButtonPressed(_ sender: Any) {
        store.dispatch(.decrement)
    }

    @IBAction func plusButtonPressed(_ sender: Any) {
        store.dispatch(.increment)
    }
}

