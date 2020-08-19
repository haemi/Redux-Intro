import Combine
import CombineRex
import Foundation
import SwiftRex

struct AppState {
    var count: Int
}

enum AppAction {
    case count(CountAction)
    // case another action category
    // case and another action category
}

enum CountAction {
    case increment
    case decrement
}

let counterReducer = Reducer<CountAction, Int> { action, state in
    switch action {
    case .decrement:
        return state - 1
    case .increment:
        return state + 1
    }
}

let appReducer = counterReducer.lift(
    actionGetter: { (appAction: AppAction) -> CountAction? in
        guard case let AppAction.count(countAction) = appAction else { return nil }
        return countAction
    },
    stateGetter: { (appState: AppState) -> Int in
        appState.count
    },
    stateSetter: { (appState: inout AppState, newCount: Int) in
        appState.count = newCount
    }
)

let store = ReduxStoreBase<AppAction, AppState>(
    subject: .combine(initialValue: AppState(count: 0)),
    reducer: appReducer,
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
        store.dispatch(.count(.decrement))
    }

    @IBAction func plusButtonPressed(_ sender: Any) {
        store.dispatch(.count(.increment))
    }
}

