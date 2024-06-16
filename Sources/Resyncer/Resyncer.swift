//
//  Resyncer.swift
//  Resyncer
//
//  Created by Daniele Pantaleone
//    - Github: https://github.com/danielepantaleone
//    - LinkedIn: https://www.linkedin.com/in/danielepantaleone
//
//  Copyright © 2024 Daniele Pantaleone. Licensed under MIT License.
//

import Foundation

/// `Resyncer` helps making use of asynchronous APIs in a synchronous environment.
public final class Resyncer: Sendable {
    
    // MARK: - Properties
    
    let queue: OperationQueue
    let raiseErrorIfOnMainThread: Bool
    
    // MARK: - Initialization
    
    /// Initialize the `Resyncer`.
    ///
    /// - parameters:
    ///   - maxConcurrentOperationCount: The maximum amount of concurrent asynchronous operations
    public convenience init(maxConcurrentOperationCount: Int = 10) {
        self.init(maxConcurrentOperationCount: maxConcurrentOperationCount, raiseErrorIfOnMainThread: true)
    }
    
    /// Initialize the `Resyncer`.
    ///
    /// - parameters:
    ///   - maxConcurrentOperationCount: The maximum amount of concurrent asynchronous operations
    ///   - raiseErrorIfOnMainThread: A boolean value to indicate whether an error must be thrown if `synchronize` is called from main thread
    init(maxConcurrentOperationCount: Int = 10, raiseErrorIfOnMainThread: Bool = true) {
        self.queue = OperationQueue()
        self.queue.maxConcurrentOperationCount = maxConcurrentOperationCount
        self.raiseErrorIfOnMainThread = raiseErrorIfOnMainThread
    }
    
    // MARK: - Interface
    
    /// Synchronize the result of the provided asynchronous handler.
    ///
    /// Result must be delivered inside the the `Result<T, Error>` enum as callback parameter.
    /// This method must not be called from the main thread since it uses a condition variable to block current thread execution to wait for asynchronous work to complete.
    ///
    /// ```
    /// let x = try resyncer.synchronize { callback in
    ///     self.asyncWork { value, error in
    ///         if let value {
    ///             callback(.success(value))
    ///         } else if let error {
    ///             callback(.failure(error))
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - parameters:
    ///   - timeout: The maximum amount of seconds the asynchronous may take
    ///   - work: The asynchronous operation to synchronize
    ///
    /// - throws: `ResyncerError`
    /// - returns: `T`
    public func synchronize<T>(timeout: TimeInterval = 10.0, work: @escaping (@escaping (Result<T, Error>) -> Void) -> Void) throws -> T {
        guard !raiseErrorIfOnMainThread || !Thread.isMainThread else {
            throw ResyncerError.calledFromMainThread
        }
        let condition = ResyncerCondition()
        var result: Result<T, Error>? = nil
        let operation: BlockOperation = .init {
            work {
                result = $0
                condition.lock()
                condition.signal()
                condition.unlock()
            }
        }
        queue.addOperation(operation)
        condition.lock()
        defer {
            condition.unlock()
        }
        condition.wait(timeout: timeout)
        operation.cancel()
        if let result {
            switch result {
                case .success(let value):
                    return value
                case .failure(let error):
                    throw error
            }
        } else {
            throw ResyncerError.timeout
        }
    }

}
