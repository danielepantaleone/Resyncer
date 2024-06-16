//
//  ResyncerError.swift
//  Resyncer
//
//  Created by Daniele Pantaleone
//    - Github: https://github.com/danielepantaleone
//    - LinkedIn: https://www.linkedin.com/in/danielepantaleone
//
//  Copyright © 2024 Daniele Pantaleone. Licensed under MIT License.
//

import Foundation

/// Error thrown by the `Resyncer`
public enum ResyncerError: Error {
    /// Resync operation couldn't be completed within the specified amount of time.
    case asyncOperationTimeout
    /// Resync operation was called from main thread.
    case calledFromMainThread
}
