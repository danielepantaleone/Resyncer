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
            self.myAsyncFunction(after: 4.0, value: 5) { value, error in
                if let value {
                    callback(.success(value))
                } else if let error {
                    callback(.failure(error))
                }
            }
        }
        XCTAssertEqual(x, 5)
    }
    
    func testFailureWithInternalError() throws {
        do {
            let _: Int = try resyncer.synchronize { callback in
                self.myAsyncFunction(after: 4.0, error: TestError.randomError) { value, error in
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
    
    func testFailureWithTimeout() throws {
        do {
            _ = try resyncer.synchronize(timeout: 2.0) { callback in
                self.myAsyncFunction(after: 4.0, value: 5) { value, error in
                    if let value {
                        callback(.success(value))
                    } else if let error {
                        callback(.failure(error))
                    }
                }
            }
            XCTFail("was supposed to raise an error")
        } catch let error as ResyncerError {
            XCTAssertEqual(error, ResyncerError.asyncOperationTimeout)
        } catch {
            XCTFail("was supposed to raise ResyncerError.asyncOperationTimeout")
        }
    }
    
    // MARK: - Internals
    
    func myAsyncFunction(after timeout: TimeInterval, value: Int? = nil, error: Error? = nil, callback: @escaping (Int?, Error?) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
            callback(value, error)
        }
    }
    
}
