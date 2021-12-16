//
//  State.swift
//  LibreDirect
//

import Combine
import Foundation

// https://danielbernal.co/redux-like-architecture-with-swiftui-basics/
// https://danielbernal.co/redux-like-architecture-with-swiftui-middleware/
// https://danielbernal.co/redux-like-architecture-with-swiftui-error-handling/
// https://danielbernal.co/redux-like-architecture-with-swiftui-real-world-app/

typealias Reducer<State, Action> = (inout State, Action) -> Void
typealias Middleware<State, Action> = (State, Action, State) -> AnyPublisher<Action, AppError>?

// MARK: - AppError

enum AppError: Error {
    case withMessage(_ message: String)
}

// MARK: - Store

final class Store<State, Action>: ObservableObject {
    // MARK: Lifecycle

    init(initialState: State, reducer: @escaping Reducer<State, Action> = { _, _ in }, middlewares: [Middleware<State, Action>] = []) {
        self.state = initialState
        self.reducer = reducer
        self.middlewares = middlewares
    }

    // MARK: Internal

    // Read-only access to app state
    @Published private(set) var state: State

    var tasks = [AnyCancellable]()
    let serialQueue = DispatchQueue(label: "libre-direct.store-queue")
    let middlewares: [Middleware<State, Action>]

    // The dispatch function.
    func dispatch(_ action: Action) {
        let lastState = state
        reducer(&state, action)

        // Dispatch all middleware functions
        for mw in middlewares {
            guard let middleware = mw(state, action, lastState) else {
                break
            }

            middleware
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .failure(.withMessage(message: let message)):
                            AppLog.error(message)
                        default:
                            break
                        }
                    },
                    receiveValue: dispatch
                )
                .store(in: &middlewareCancellables)
        }
    }

    // MARK: Private

    private var middlewareCancellables: Set<AnyCancellable> = []
    private let reducer: Reducer<State, Action>
}
