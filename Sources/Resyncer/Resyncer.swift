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

/// Resyncer enables you to call asynchronous code within a synchronous environment by pausing the current thread
/// until the asynchronous task completes. It achieves this by offloading the asynchronous work to a separate thread,
/// either using an `OperationQueue` or leveraging Swift concurrency with `Task`.
public final class Resyncer: Sendable {
    
    // MARK: - Properties
    
    let queue: OperationQueue
    let raiseErrorIfOnMainThread: Bool
    
    // MARK: - Initialization
    
    /// Initializes a new instance of the `Resyncer`.
    public convenience init() {
        self.init(raiseErrorIfOnMainThread: true)
    }
    
    /// Initializes a new instance of the `Resyncer`.
    ///
    /// This initializer creates a `Resyncer` with a specified behavior regarding main thread usage.
    ///
    /// - Parameters:
    ///   - raiseErrorIfOnMainThread: A Boolean value indicating whether an error should be thrown if `synchronize` is called from the main thread. The default value is `true`.
    init(raiseErrorIfOnMainThread: Bool = true) {
        self.queue = OperationQueue()
        self.queue.maxConcurrentOperationCount = 10
        self.raiseErrorIfOnMainThread = raiseErrorIfOnMainThread
    }
    
    // MARK: - Interface
    
    /// Synchronizes the result of the provided asynchronous handler.
    ///
    /// This method synchronously waits for the completion of an asynchronous task.
    /// The result of the task must be delivered using a `Result<T, Error>` enum as a callback parameter.
    ///
    /// **Important:** This method must not be called from the main thread, as it uses a condition variable to block
    /// the current thread's execution while waiting for the asynchronous work to complete.
    ///
    /// Example usage:
    ///
    /// ```swift
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
    /// - Parameters:
    ///   - timeout: The maximum time in seconds the asynchronous task is allowed to take. The default value is 10.0 seconds.
    ///   - work: The asynchronous operation to be synchronized. It takes a completion handler with a `Result<T, Error>` parameter.
    ///
    /// - Throws: `ResyncerError` if the operation fails, including cases such as being called on the main thread or a timeout.
    ///
    /// - Returns: The result of type `T` from the asynchronous operation if it completes successfully.
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
        
    /// Synchronizes the result of the provided asynchronous handler.
    ///
    /// This method synchronously waits for the completion of an asynchronous task that uses Swift's async/await pattern.
    ///
    /// **Important:** This method must not be called from the main thread, as it utilizes a condition variable
    /// to block the current thread's execution while waiting for the asynchronous operation to finish.
    ///
    /// Example usage:
    ///
    /// ```swift
    /// let x = try resyncer.synchronize {
    ///     try await self.asyncWork()
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - timeout: The maximum time in seconds the asynchronous operation can take. The default is 10.0 seconds.
    ///   - work: The asynchronous operation to synchronize, which uses Swift's async/await and can throw errors.
    ///
    /// - Throws: `ResyncerError` if the operation encounters an error, including calling from the main thread or exceeding the timeout.
    ///
    /// - Returns: The result of type `T` from the asynchronous operation if it completes successfully.
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
