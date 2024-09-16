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

/// `Resyncer` helps making use of asynchronous API in a synchronous environment.
public final class Resyncer: Sendable {
    
    // MARK: - Properties
    
    let queue: OperationQueue
    let raiseErrorIfOnMainThread: Bool
    
    // MARK: - Initialization
    
    /// Initialize the `Resyncer`.
    public convenience init() {
        self.init(raiseErrorIfOnMainThread: true)
    }
    
    /// Initialize the `Resyncer`.
    ///
    /// - parameters:
    ///   - raiseErrorIfOnMainThread: A boolean value to indicate whether an error must be thrown if `synchronize` is called from main thread
    init(raiseErrorIfOnMainThread: Bool = true) {
        self.queue = OperationQueue()
        self.queue.maxConcurrentOperationCount = 10
        self.raiseErrorIfOnMainThread = raiseErrorIfOnMainThread
    }
    
    // MARK: - Interface
    
    /// Synchronize the result of the provided asynchronous handler.
    ///
    /// Result must be delivered inside a `Result<T, Error>` enum as callback parameter.
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
    ///   - timeout: The maximum amount of seconds the asynchronous work may take
    ///   - work: The asynchronous operation to synchronize
    ///
    /// - throws: `ResyncerError`
    /// - returns: `T`
    public func synchronize<T>(timeout: TimeInterval = 10.0, work: @escaping (@escaping (Result<T, Error>) -> Void) -> Void) throws -> T {
        guard !raiseErrorIfOnMainThread || !Thread.isMainThread else {
            throw ResyncerError.calledFromMainThread
        }
        let condition = ResyncerCondition()
        var result: Result<T, Error>?
        let operation: BlockOperation = .init {
            work {
                defer {
                    condition.lock()
                    condition.signal()
                    condition.unlock()
                }
                result = $0
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
        
    /// Synchronize the result of the provided asynchronous handler.
    ///
    /// This method must not be called from the main thread since it uses a condition variable to block current thread execution to wait for asynchronous work to complete.
    ///
    /// ```
    /// let x = try resyncer.synchronize {
    ///     try await self.asyncWork()
    /// }
    /// ```
    ///
    /// - parameters:
    ///   - timeout: The maximum amount of seconds the asynchronous work may take
    ///   - work: The asynchronous operation to synchronize
    ///
    /// - throws: `ResyncerError`
    /// - returns: `T`
    @available(iOS 13.0, *)
    public func synchronize<T>(timeout: TimeInterval = 10.0, work: @escaping () async throws -> T) throws -> T {
        guard !raiseErrorIfOnMainThread || !Thread.isMainThread else {
            throw ResyncerError.calledFromMainThread
        }
        let condition = ResyncerCondition()
        let wrapper: ResyncerWrapper<T> = .init()
        Task {
            defer {
                condition.lock()
                condition.signal()
                condition.unlock()
            }
            do {
                wrapper.result = .success(try await work())
            } catch {
                wrapper.result = .failure(error)
            }
        }
        condition.lock()
        defer {
            condition.unlock()
        }
        condition.wait(timeout: timeout)
        if let result = wrapper.result {
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
