//
//  ResyncerTests.swift
//  Resyncer
//
//  GitHub Repo and Documentation: https://github.com/danielepantaleone/Resyncer
//
//  Copyright © 2024 Daniele Pantaleone. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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
        let resyncer = Resyncer(raiseErrorIfOnMainThread: false)
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
        let resyncer = Resyncer(maxConcurrentOperationCount: numberOfOperations, raiseErrorIfOnMainThread: false)
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
        let resyncer = Resyncer(raiseErrorIfOnMainThread: false)
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
            let resyncer = Resyncer(raiseErrorIfOnMainThread: false)
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
        let resyncer = Resyncer(raiseErrorIfOnMainThread: false)
        let x = try resyncer.synchronize {
            try await self.asyncWork(after: 2.0, value: 5)
        }
        XCTAssertEqual(x, 5)
    }
    
    @available(iOS 13.0, *)
    func testFailureDueToInternalErrorWithSwiftConcurrency() throws {
        do {
            let resyncer = Resyncer(raiseErrorIfOnMainThread: false)
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
            let resyncer = Resyncer(raiseErrorIfOnMainThread: false)
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
