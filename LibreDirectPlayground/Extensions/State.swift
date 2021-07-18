//
//  State.swift
//  LibreDirectPlayground
//
//  Created by Reimar Metzen on 06.07.21.
//

import Foundation
import Combine

//https://danielbernal.co/redux-like-architecture-with-swiftui-basics/
//https://danielbernal.co/redux-like-architecture-with-swiftui-middleware/
//https://danielbernal.co/redux-like-architecture-with-swiftui-error-handling/
//https://danielbernal.co/redux-like-architecture-with-swiftui-real-world-app/

typealias Reducer<State, Action> = (inout State, Action) -> Void
typealias Middleware<State, Action> = (State, Action) -> AnyPublisher<Action, Never>?

final class Store<State, Action>: ObservableObject {
    // Read-only access to app state
    @Published private(set) var state: State

    var tasks = [AnyCancellable]()
    let serialQueue = DispatchQueue(label: "libre-direct.store-queue")
    let middlewares: [Middleware<State, Action>]

    private var middlewareCancellables: Set<AnyCancellable> = []
    private let reducer: Reducer<State, Action>

    init(initialState: State, reducer: @escaping Reducer<State, Action> = { _, _ in }, middlewares: [Middleware<State, Action>] = []) {
        self.state = initialState
        self.reducer = reducer
        self.middlewares = middlewares
    }

    // The dispatch function.
    func dispatch(_ action: Action) {
        reducer(&state, action)

        // Dispatch all middleware functions
        for mw in middlewares {
            guard let middleware = mw(state, action) else {
                break
            }

            middleware.receive(on: DispatchQueue.main)
                .sink(receiveValue: dispatch)
                .store(in: &middlewareCancellables)
        }
    }
}
