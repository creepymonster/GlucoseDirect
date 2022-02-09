//
//  Lazy.swift
//  LibreDirect
//

import Dispatch
import Foundation

// MARK: - LazyServiceValue

private enum LazyServiceValue<T> {
    case uninitialized(() -> T)
    case initialized(T)
}

// MARK: - LazyService

final class LazyService<T> {
    // MARK: Lifecycle

    init(initialization: @escaping () -> T) {
        _value = .uninitialized(initialization)
    }

    // MARK: Internal

    var value: T {
        var returnValue: T?
        queue.sync {
            switch self._value {
            case .uninitialized(let initialization):
                let result = initialization()
                self._value = .initialized(result)
                returnValue = result
            case .initialized(let result):
                returnValue = result
            }
        }
        assert(returnValue != nil)
        return returnValue!
    }

    // MARK: Private

    private var _value: LazyServiceValue<T>

    /// All reads and writes of `_value` must
    /// happen on this queue.
    private let queue = DispatchQueue(label: "LazyService._value")
}
