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

/// Resyncer enables you to call asynchronous code within a synchronous environment by pausing the current thread until the asynchronous task completes.
public final class Resyncer {
    
    // MARK: - Properties
    
    let queue: OperationQueue
    let raiseErrorIfOnMainThread: Bool
    
    // MARK: - Initialization
    
    /// Initializes a new instance of the `Resyncer`.
    ///
    /// - Parameters:
    ///   - maxConcurrentOperationCount: The maximum number of operations that can be executed concurrently.
    ///   - qos: The quality of service the the internal operation queue.
    public convenience init(maxConcurrentOperationCount: Int = 10, qos: QualityOfService = .userInitiated) {
        self.init(
            maxConcurrentOperationCount: maxConcurrentOperationCount,
            qos: qos,
            raiseErrorIfOnMainThread: !isRunningInXCTest())
    }
    
    /// Initializes a new instance of the `Resyncer`.
    ///
    /// This initializer creates a `Resyncer` with a specified behavior regarding main thread usage.
    ///
    /// - Parameters:
    ///   - maxConcurrentOperationCount: The maximum number of operations that can be executed concurrently.
    ///   - qos: The quality of service the the internal operation queue.
    ///   - raiseErrorIfOnMainThread: A Boolean value indicating whether an error should be thrown if `synchronize` is called from the main thread. The default value is `true`.
    init(maxConcurrentOperationCount: Int = 10, qos: QualityOfService = .userInitiated, raiseErrorIfOnMainThread: Bool = true) {
        self.queue = OperationQueue()
        self.queue.maxConcurrentOperationCount = maxConcurrentOperationCount
        self.queue.qualityOfService = qos
        self.raiseErrorIfOnMainThread = raiseErrorIfOnMainThread
    }
    
    // MARK: - Interface
    
    /// Synchronizes the result of the provided asynchronous handler.
    ///
    /// This method synchronously waits for the completion of an asynchronous task.
    /// The result of the task must be delivered using a `Result<T, Error>` enum as a callback parameter.
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
    /// - Returns: The result of type `T` from the asynchronous operation if it completes successfully.
    /// - Important: This method must not be called from the main thread, as it utilizes a condition variable to block the current thread's execution while waiting for the asynchronous operation to finish.
    public func synchronize<T>(timeout: TimeInterval = 10.0, work: @escaping (@escaping (Result<T, Error>) -> Void) -> Void) throws -> T {
        
        guard !raiseErrorIfOnMainThread || !Thread.isMainThread else {
            throw ResyncerError.calledFromMainThread
        }
        
        let condition = NSCondition()
        var completed = false
        var result: Result<T, Error>?
        let operation: BlockOperation = .init {
            work { r in
                condition.withLock {
                    completed = true
                    result = r
                    condition.signal()
                }
            }
        }
        
        queue.addOperation(operation)
        
        condition.withLock {
            let deadline = Date(timeIntervalSinceNow: timeout)
            while !completed {
                if !condition.wait(until: deadline) {
                    break
                }
            }
        }
        
        operation.cancel()
        
        guard let result, completed else {
            throw ResyncerError.timeout
        }
        
        switch result {
            case .success(let value):
                return value
            case .failure(let error):
                throw error
        }
        
    }
        
    /// Synchronizes the result of the provided asynchronous handler.
    ///
    /// This method synchronously waits for the completion of an asynchronous task that uses Swift's async/await pattern.
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
    /// - Important: This method must not be called from the main thread, as it utilizes a condition variable to block the current thread's execution while waiting for the asynchronous operation to finish.
    @available(iOS 13.0, *)
    public func synchronize<T>(timeout: TimeInterval = 10.0, work: @escaping () async throws -> T) throws -> T {
        
        guard !raiseErrorIfOnMainThread || !Thread.isMainThread else {
            throw ResyncerError.calledFromMainThread
        }
        
        let condition = NSCondition()
        var completed = false
        var result: Result<T, Error>?
        
        Task {
            let r: Result<T, Error>
            do {
                r = .success(try await work())
            } catch {
                r = .failure(error)
            }
            condition.withLock {
                completed = true
                result = r
                condition.signal()
            }
        }
        
        condition.withLock {
            let deadline = Date(timeIntervalSinceNow: timeout)
            while !completed {
                if !condition.wait(until: deadline) {
                    break
                }
            }
        }

        guard let result, completed else {
            throw ResyncerError.timeout
        }
        
        switch result {
            case .success(let value):
                return value
            case .failure(let error):
                throw error
        }
        
    }

}

/// Checks whether the current code is running in an XCTest environment.
///
/// This function examines the process environment to determine if it contains
/// the `XCTestConfigurationFilePath` key, which is set by the XCTest framework when running unit tests.
///
/// - Returns: A Boolean value indicating whether the code is running inside an XCTest target (`true`) or not (`false`).
func isRunningInXCTest() -> Bool {
    return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
}
