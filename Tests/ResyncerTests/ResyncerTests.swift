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

class ResyncerTests: XCTestCase {
    
    // MARK: - Types
    
    enum TestError: Error {
        case randomError
    }
    
    // MARK: - Properties
    
    var resyncer: Resyncer!
    
    // MARK: - Initialization

    override func setUpWithError() throws {
        resyncer = Resyncer(raiseErrorIfOnMainThread: false)
    }
    
    override func tearDownWithError() throws {
        resyncer = nil
    }
    
    // MARK: - Tests
    
    func testSuccess() throws {
        let x = try resyncer.synchronize { callback in
            self.asyncWork(after: 4.0, value: 5) { value, error in
                if let value {
                    callback(.success(value))
                } else if let error {
                    callback(.failure(error))
                }
            }
        }
        XCTAssertEqual(x, 5)
    }
    
    func testSuccessWithSwiftConcurrency() throws {
        let x = try resyncer.synchronize {
            try await self.asyncWork(after: 4.0, value: 5)
        }
        XCTAssertEqual(x, 5)
    }
    
    func testFailureDueToInternalError() throws {
        do {
            let _: Int = try resyncer.synchronize { callback in
                self.asyncWork(after: 4.0, error: TestError.randomError) { value, error in
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
    
    func testFailureDueToInternalErrorWithSwiftConcurrency() throws {
        do {
            let _: Int = try resyncer.synchronize {
                try await self.asyncWork(after: 4.0, error: TestError.randomError)
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
            _ = try resyncer.synchronize(timeout: 2.0) { callback in
                self.asyncWork(after: 4.0, value: 5) { value, error in
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
            XCTFail("was supposed to raise ResyncerError.asyncOperationTimeout")
        }
    }
    
    func testFailureDueToTimeoutErrorWithSwiftConcurrency() throws {
        do {
            let _: Int = try resyncer.synchronize(timeout: 2.0) {
                try await self.asyncWork(after: 4.0, value: 5)
            }
            XCTFail("was supposed to raise an error")
        } catch let error as ResyncerError {
            XCTAssertEqual(error, ResyncerError.timeout)
        } catch {
            XCTFail("was supposed to raise TestError.timeout")
        }
    }
    
    // MARK: - Internals
    
    func asyncWork(after timeout: TimeInterval, value: Int? = nil, error: Error? = nil, callback: @escaping (Int?, Error?) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
            callback(value, error)
        }
    }
    
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
