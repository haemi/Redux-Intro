import Foundation
import os.log
import SwiftRex

class LoggerMiddleware: Middleware {
    typealias InputActionType = AppAction
    typealias OutputActionType = AppAction          // No action is generated from this Middleware
    typealias StateType = AppState

    var getState: GetState<AppState>!

    func receiveContext(getState: @escaping GetState<AppState>, output: AnyActionHandler<AppAction>) {
        self.getState = getState
    }

    func handle(action: AppAction, from dispatcher: ActionSource, afterReducer: inout AfterReducer) {
        let stateBefore: AppState = getState()
        let dateBefore = Date()

        afterReducer = .do {
            let stateAfter = self.getState()
            let dateAfter = Date()
            let source = "\(dispatcher.file):\(dispatcher.line) - \(dispatcher.function) | \(dispatcher.info ?? "")"

            print(action, source, stateBefore, stateAfter, dateBefore, dateAfter)
        }
    }
}
