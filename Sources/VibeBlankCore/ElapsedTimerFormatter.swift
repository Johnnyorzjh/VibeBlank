import Foundation

public enum ElapsedTimerFormatter {
    public static func string(elapsedSeconds: Int) -> String {
        let clampedSeconds = max(0, elapsedSeconds)
        let hours = clampedSeconds / 3_600
        let minutes = (clampedSeconds % 3_600) / 60
        let seconds = clampedSeconds % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%02d:%02d", minutes, seconds)
    }
}
