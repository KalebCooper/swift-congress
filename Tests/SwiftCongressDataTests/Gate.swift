/// A one-shot signal that holds waiters until it opens, so a test can pause a transport response.
actor Gate {
  private var continuations: [CheckedContinuation<Void, Never>] = []
  private var isOpen = false

  func open() {
    isOpen = true
    for continuation in continuations { continuation.resume() }
    continuations = []
  }

  func wait() async {
    if isOpen { return }
    await withCheckedContinuation { continuations.append($0) }
  }
}
