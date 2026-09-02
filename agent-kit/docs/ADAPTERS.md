# Transports

The pluggable seam. Apropos has one: `Transport`, in
`ios/Apropos/Core/Transport.swift`.

```swift
protocol Transport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}
```

Everything that touches the network takes one: `GitHubAPI`,
`DeviceFlowAuth`, `IPAInspector`, and `SessionStore`. Nothing else calls
`URLSession`.

## Implementations

| Transport | Where | When |
|---|---|---|
| `URLSession` | `Transport.swift` | The app. The default argument of every initialiser. |
| `StubTransport` | `AproposTests/StubTransport.swift` | Unit tests. Answers from a queue of canned replies and records what was sent. |
| `RangeTransport` | `AproposTests/TestZip.swift` | Unit tests for `IPAInspector`. Serves one blob and honours `Range`, the way a release-asset host does. |

## The contract for a new transport

1. Return the body and the `HTTPURLResponse`. Never interpret the status
   code; `GitHubAPI.throwIfFailure` owns that.
2. Throw `URLError` for transport failures. The API layer maps it to
   `GitHubError.transport`.
3. Honour the `Range` header, or answer 200 with the whole body.
   `RemoteFile` treats a 200 as `rangeNotSupported` and says so.
4. Be `Sendable`. Calls come from any task.
