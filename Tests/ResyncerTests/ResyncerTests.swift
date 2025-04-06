//
//  ResyncerTests.swift
//  Resyncer
//
//  Created by Daniele Pantaleone
//    - Github: https://github.com/danielepantaleone
//    - LinkedIn: https://www.linkedin.com/in/danielepantaleone
//
//  Copyright © 2024 Daniele Pantaleone. Licensed under MIT License.
//

@testable import Resyncer

import XCTest

final class ResyncerTests: XCTestCase {
    
    // MARK: - Types
    
    enum TestError: Error {
        case randomError
    }
    
    // MARK: - Tests
    
    func testSuccess() throws {
        let resyncer = Resyncer()
        let x = try resyncer.synchronize { callback in
            self.asyncWork(after: 2.0, value: 5) { value, error in
                if let value {
                    callback(.success(value))
                } else if let error {
                    callback(.failure(error))
                }
            }
        }
        XCTAssertEqual(x, 5)
    }
    
    func testSuccessWithHeavyLoad() throws {
        let numberOfOperations = 50
        let resyncer = Resyncer(maxConcurrentOperationCount: numberOfOperations)
        let expectation = expectation(description: "waiting for all tasks to complete")
        expectation.expectedFulfillmentCount = numberOfOperations
        for i in 0..<numberOfOperations {
            DispatchQueue.global().async {
                do {
                    let x = try resyncer.synchronize { callback in
                        self.asyncWork(after: 1.0, value: i) { value, error in
                            if let value {
                                callback(.success(value))
                            } else if let error {
                                callback(.failure(error))
                            }
                        }
                    }
                    XCTAssertEqual(x, i)
                    expectation.fulfill()
                } catch {
                    XCTFail("Failed with unexpected error: \(error)")
                }
            }
        }
        wait(for: [expectation], timeout: 50.0)
    }
    
    func testFailureDueToInternalError() throws {
        let resyncer = Resyncer()
        do {
            let _: Int = try resyncer.synchronize { callback in
                self.asyncWork(after: 2.0, error: TestError.randomError) { value, error in
                    if let value {
                        callback(.success(value))
                    } else if let error {
                        callback(.failure(error))
                    }
                }
            }
            XCTFail("was supposed to raise an error")
        } catch let error as TestError {
            XCTAssertEqual(error, TestError.randomError)
        } catch {
            XCTFail("was supposed to raise TestError.randomError")
        }
    }
    
    func testFailureDueToTimeout() throws {
        do {
            let resyncer = Resyncer()
            _ = try resyncer.synchronize(timeout: 1.0) { callback in
                self.asyncWork(after: 2.0, value: 5) { value, error in
                    if let value {
                        callback(.success(value))
                    } else if let error {
                        callback(.failure(error))
                    }
                }
            }
            XCTFail("was supposed to raise an error")
        } catch let error as ResyncerError {
            XCTAssertEqual(error, ResyncerError.timeout)
        } catch {
            XCTFail("was supposed to raise ResyncerError.timeout")
        }
    }
    
    func testFailureDueToCallOnMainThread() throws {
        do {
            let resyncer = Resyncer(raiseErrorIfOnMainThread: true)
            _ = try resyncer.synchronize(timeout: 1.0) { callback in
                self.asyncWork(after: 2.0, value: 5) { value, error in
                    if let value {
                        callback(.success(value))
                    } else if let error {
                        callback(.failure(error))
                    }
                }
            }
            XCTFail("was supposed to raise an error")
        } catch let error as ResyncerError {
            XCTAssertEqual(error, ResyncerError.calledFromMainThread)
        } catch {
            XCTFail("was supposed to raise ResyncerError.calledFromMainThread")
        }
    }
    
    @available(iOS 13.0, *)
    func testSuccessWithSwiftConcurrency() throws {
        let resyncer = Resyncer()
        let x = try resyncer.synchronize {
            try await self.asyncWork(after: 2.0, value: 5)
        }
        XCTAssertEqual(x, 5)
    }
    
    @available(iOS 13.0, *)
    func testFailureDueToInternalErrorWithSwiftConcurrency() throws {
        do {
            let resyncer = Resyncer()
            let _: Int = try resyncer.synchronize {
                try await self.asyncWork(after: 2.0, error: TestError.randomError)
            }
            XCTFail("was supposed to raise an error")
        } catch let error as TestError {
            XCTAssertEqual(error, TestError.randomError)
        } catch {
            XCTFail("was supposed to raise TestError.randomError")
        }
    }
    
    @available(iOS 13.0, *)
    func testFailureDueToTimeoutErrorWithSwiftConcurrency() throws {
        do {
            let resyncer = Resyncer()
            let _: Int = try resyncer.synchronize(timeout: 1.0) {
                try await self.asyncWork(after: 2.0, value: 5)
            }
            XCTFail("was supposed to raise an error")
        } catch let error as ResyncerError {
            XCTAssertEqual(error, ResyncerError.timeout)
        } catch {
            XCTFail("was supposed to raise ResyncerError.timeout")
        }
    }
    
    @available(iOS 13.0, *)
    func testFailureDueToCallOnMainThreadWithSwiftConcurrency() throws {
        do {
            let resyncer = Resyncer(raiseErrorIfOnMainThread: true)
            let _: Int = try resyncer.synchronize(timeout: 1.0) {
                try await self.asyncWork(after: 2.0, value: 5)
            }
            XCTFail("was supposed to raise an error")
        } catch let error as ResyncerError {
            XCTAssertEqual(error, ResyncerError.calledFromMainThread)
        } catch {
            XCTFail("was supposed to raise ResyncerError.calledFromMainThread")
        }
    }
    
    // MARK: - Internals
    
    func asyncWork(after timeout: TimeInterval, value: Int? = nil, error: Error? = nil, callback: @escaping (Int?, Error?) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
            callback(value, error)
        }
    }
    
    @available(iOS 13.0, *)
    func asyncWork(after timeout: TimeInterval, value: Int? = nil, error: Error? = nil) async throws -> Int {
        try await Task.sleep(nanoseconds: UInt64(timeout) * NSEC_PER_SEC)
        if let error {
            throw error
        } else if let value {
            return value
        }
        return -1
    }
    
}
