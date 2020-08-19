import Combine
import CombineRex
import Foundation
import SwiftRex

struct AppState {
    var count: Int
}

struct CounterViewState: Equatable {
    let formattedCount: String

    static func from(appState: AppState) -> CounterViewState {
        .init(formattedCount: "\(appState.count)")
    }
}

enum AppAction {
    case count(CountAction)
    case shake(ShakeAction)
}

enum CountAction {
    case increment
    case decrement
}

enum ShakeAction {
    case start
    case shaken
    case stop
}

enum CounterViewAction {
    case tapPlus
    case tapMinus

    var asAppAction: AppAction? {
        switch self {
        case .tapPlus: return .count(.increment)
        case .tapMinus: return .count(.decrement)
        }
    }
}

let viewModel: StoreProjection<CounterViewAction, CounterViewState> =
    store.projection(
        action: \CounterViewAction.asAppAction,
        state: CounterViewState.from(appState:)
    )


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
    middleware: LoggerMiddleware() <> ShakeMiddleware()
)

class ViewController: UIViewController {
    private var subscription: AnyCancellable?
    @IBOutlet private var label: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        subscription = viewModel.statePublisher
            .map { $0.formattedCount }
            .assign(to: \.text, on: label)

        store.dispatch(.shake(.start))
    }
    @IBAction func minusButtonPressed(_ sender: Any) {
        viewModel.dispatch(.tapMinus)
    }

    @IBAction func plusButtonPressed(_ sender: Any) {
        viewModel.dispatch(.tapPlus)
    }
}

extension ViewController {
    override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard motion == .motionShake else { return }
        NotificationCenter.default.post(name: NSNotification.Name.ShakeGesture, object: nil)
    }
}
