import Dispatch

/// `DispatchQueue.concurrentPerform` with Darwin's signature on every platform.
///
/// Linux's Dispatch takes a `@Sendable` closure, so code that compiles on macOS — iterations
/// writing disjoint slots of a buffer, reading captured arrays — fails there under Swift 6.
/// This runs `body` the same way on both; as on Darwin, `body` must not race with itself
/// (each iteration writes only its own data, shared state goes through a lock).
package func concurrentPerform(iterations: Int, execute body: (Int) -> Void) {
    withoutActuallyEscaping(body) { body in
        let box = UncheckedSendableBody(body: body)
        DispatchQueue.concurrentPerform(iterations: iterations) { box.body($0) }
    }
}

private struct UncheckedSendableBody: @unchecked Sendable {
    let body: (Int) -> Void
}
