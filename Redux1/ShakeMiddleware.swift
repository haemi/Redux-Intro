import Combine
import Foundation
import SwiftRex

class ShakeMiddleware: Middleware {
    // start of boilerplate
    // there are other higher level middlewares implementations
    // that hide most of this code, we're showing the complete
    // stuff to go very basic
    init() { }

    private var getState: GetState<AppState>!
    private var output: AnyActionHandler<AppAction>!
    func receiveContext(getState: @escaping GetState<AppState>, output: AnyActionHandler<AppAction>) {
        self.getState = getState
        self.output = output
    }
    // end of boilerplate

    // Side-effect subscription
    private var shakeGesture: AnyCancellable?

    func handle(action: AppAction, from dispatcher: ActionSource, afterReducer: inout AfterReducer) {
        // an action arrived, do we care about it?
        switch action {
        case .shake(.start):
            // let's start the side-effect observation
            shakeGesture = NotificationCenter.default.publisher(for: Notification.Name.ShakeGesture).sink { [weak self] _ in
                // every time we detect a device shake, we dispatch a .shake(.shaken) action in response
                self?.output.dispatch(.shake(.shaken))
            }

        case .shake(.stop):
            // effect cancellation, user doesn't want this any more, Combine AnyCancellable will stop that for us
            shakeGesture = nil

        case .shake(.shaken):
            // .shake(.shaken) is an action that we dispatched ourselves, and we're receiving it back
            // although this extra roundtrip is optional, it helps to "tell a story" in your logs.
            output.dispatch(.count(.increment))

        case .count:
            // we don't care about incoming count actions
            break
        }
    }
}

// Extra stuff for this gesture
extension Notification.Name {
    public static let ShakeGesture = Notification.Name.init("ShakeGesture")
}
