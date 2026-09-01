import Foundation

#if DEBUG
/// A test seam, not a feature. `verify/simulator-smoke.sh` injects a token
/// through the launch environment so the gate can prove the signed-in
/// screens render against live GitHub. The `#if DEBUG` guard keeps it out
/// of any Release build.
enum InjectedToken {
    static var value: String? {
        let raw = ProcessInfo.processInfo.environment["REPORUNNER_TOKEN"]
        guard let raw, !raw.isEmpty else { return nil }
        return raw
    }
}
#endif
