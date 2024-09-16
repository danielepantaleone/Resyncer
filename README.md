# Resyncer

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fdanielepantaleone%2FResyncer%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/danielepantaleone/Resyncer)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fdanielepantaleone%2FResyncer%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/danielepantaleone/Resyncer)
![Cocoapods](https://img.shields.io/cocoapods/v/Resyncer?style=flat-square)
![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/danielepantaleone/Resyncer?style=flat-square)
![GitHub](https://img.shields.io/github/license/danielepantaleone/Resyncer?style=flat-square)
[![GitHub Workflow Status (with event)](https://img.shields.io/github/actions/workflow/status/danielepantaleone/Resyncer/swift-tests.yml?style=flat-square&logo=github)](https://github.com/danielepantaleone/Resyncer/actions/workflows/swift-tests.yml)

Resyncer is a Swift library designed to seamlessly integrate asynchronous APIs within synchronous environments. 
It allows developers to call asynchronous code—whether using callbacks or Swift’s async/await pattern—and block 
the calling thread until the asynchronous task is complete. This ensures that a result is available before proceeding 
with the synchronous workflow, making it ideal for scenarios where sequential execution is critical, but asynchronous 
tasks are involved.

## Table of contents

* [Feature Highlights](#feature-highlights)
* [Basic usage](#basic-usage)
* [Installation](#installation)
    * [Cocoapods](#cocoapods)
    * [Swift Package Manager](#swift-package-manager)
* [Contributing](#contributing)
* [License](#license)

## Feature Highlights

- Compatible with iOS and macOS
- No deadlocks
- Support for callback based asynchronous code
- Support for swift-concurrency based asynchronous code

## Basic usage

Resyncer enables you to call asynchronous code within a synchronous environment by pausing the current thread 
until the asynchronous task completes. It achieves this by offloading the asynchronous work to a separate thread, 
either using an [OperationQueue](https://developer.apple.com/documentation/foundation/operationqueue) or leveraging 
Swift concurrency with [Task](https://developer.apple.com/documentation/swift/task).

**Because Resyncer is going to block the calling thread, make sure not to use it from the Main Thread.**

### Usage with callback based asynchronous code

If you have an asynchronous function that posts a value on a provided callback using swift `Result` (or also without `Result`, you can construct it yourself):

```swift
func asyncWork(_ completion: @escaping (Result<Int, Error>) -> Void) { ... }
```

You can use Resyncher to obtain the produced value in a synchronous environment:

```swift
let x = try resyncer.synchronize { callback in
    self.asyncWork { result in
        callback(result)
    }
}
```

### Usage with swift-concurrency based asynchronous code

If you have an asynchronous function that returns a value:

```swift
func asyncWork() async throws -> Int { ... }
```

You can use Resyncher to obtain the produced value in a synchronous environment:

```swift
let x = try resyncer.synchronize {
    try await self.asyncWork()
}
```

## Installation

### Cocoapods

Add the dependency to the `Resyncer` framework in your `Podfile`:

```ruby
pod 'Resyncer', '~> 1.1.0'
```

### Swift Package Manager

Add it as a dependency in a Swift Package:

```swift
dependencies: [
    .package(url: "https://github.com/danielepantaleone/Resyncer.git", .upToNextMajor(from: "1.1.0"))
]
```

## Contributing

If you like this project you can contribute it by:

- Submit a bug report by opening an [issue](https://github.com/danielepantaleone/Resyncer/issues)
- Submit code by opening a [pull request](https://github.com/danielepantaleone/Resyncer/pulls)

## License

```
MIT License

Copyright (c) 2024 Daniele Pantaleone

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
