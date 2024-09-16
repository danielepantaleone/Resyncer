//
//  ResyncerCondition.swift
//  Resyncer
//
//  Created by Daniele Pantaleone
//    - Github: https://github.com/danielepantaleone
//    - LinkedIn: https://www.linkedin.com/in/danielepantaleone
//
//  Copyright © 2024 Daniele Pantaleone. Licensed under MIT License.
//

import Foundation

class ResyncerCondition {
    
    // MARK: - Properties
    
    var condition = pthread_cond_t()
    var mutex = pthread_mutex_t()
    
    // MARK: - Initialization
    
    init() {
        var m_attr = pthread_mutexattr_t()
        pthread_mutexattr_init(&m_attr)
        pthread_mutex_init(&mutex, &m_attr)
        pthread_mutexattr_destroy(&m_attr)
        var c_attr = pthread_condattr_t()
        pthread_condattr_init(&c_attr)
        pthread_cond_init(&condition, &c_attr)
        pthread_condattr_destroy(&c_attr)
    }
    
    deinit {
        pthread_cond_destroy(&condition)
        pthread_mutex_destroy(&mutex)
    }
    
    // MARK: - Functions
    
    @inline(__always)
    func lock() {
        pthread_mutex_lock(&mutex)
    }
    
    @inline(__always)
    func unlock() {
        pthread_mutex_unlock(&mutex)
    }
    
    @inline(__always)
    func signal() {
        pthread_cond_signal(&condition)
    }
    
    @discardableResult
    @inline(__always)
    func wait(timeout: TimeInterval) -> Bool {
        let date = Date(timeIntervalSinceNow: timeout)
        let utime = date.timeIntervalSince1970
        var expire = timespec()
        expire.tv_sec = __darwin_time_t(utime)
        expire.tv_nsec = (Int(utime) - expire.tv_sec) * 1_000_000_000
        return pthread_cond_timedwait(&condition, &mutex, &expire) == 0
    }
    
}
