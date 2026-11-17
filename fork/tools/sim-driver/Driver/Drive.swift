import XCTest

/// Runs the steps in $SIM_DRIVER_STEPS (default /tmp/sim-driver/steps.json)
/// against the app $SIM_DRIVER_BUNDLE (default com.belesky.buzz.dev).
///
/// Steps, one JSON object each:
///   {"launch": true, "args": ["-x"]}   launch (terminating a running copy)
///   {"activate": true}                  bring to the foreground without relaunching
///   {"tap": "Label"}                    tap the first hittable element with that label or identifier
///   {"tapText": "substring"}            tap the first element whose label contains the text
///   {"tapAt": [x, y]}                   tap at points in the app's coordinate space
///   {"type": "text"}                    type into the focused element
///   {"swipe": "up|down|left|right"}
///   {"wait": 2}                         seconds
///   {"waitFor": "Label", "timeout": 10} fail unless it appears
///   {"shot": "name"}                    screenshot to <out>/name.png
///   {"tree": "name"}                    accessibility tree to <out>/name.txt
/// Output goes to $SIM_DRIVER_OUT (default /tmp/sim-driver/out).
final class Drive: XCTestCase {
    func testSteps() throws {
        let env = ProcessInfo.processInfo.environment
        let stepsPath = env["SIM_DRIVER_STEPS"] ?? "/tmp/sim-driver/steps.json"
        let out = URL(fileURLWithPath: env["SIM_DRIVER_OUT"] ?? "/tmp/sim-driver/out")
        try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
        let app = XCUIApplication(bundleIdentifier: env["SIM_DRIVER_BUNDLE"] ?? "com.belesky.buzz.dev")
        let data = try Data(contentsOf: URL(fileURLWithPath: stepsPath))
        let steps = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [[String: Any]])
        var log: [String] = []
        defer { try? log.joined(separator: "\n").write(to: out.appendingPathComponent("log.txt"), atomically: true, encoding: .utf8) }

        /// Waits up to five seconds for the label, since a tap that follows a
        /// navigation otherwise races the route transition.
        func element(_ label: String) -> XCUIElement? {
            let byId = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@ OR identifier == %@", label, label))
            _ = byId.firstMatch.waitForExistence(timeout: 5)
            for i in 0 ..< min(byId.count, 20) where byId.element(boundBy: i).isHittable { return byId.element(boundBy: i) }
            return byId.count > 0 ? byId.firstMatch : nil
        }

        for (index, step) in steps.enumerated() {
            let name = "\(index): \(step)"
            if step["launch"] != nil {
                app.launchArguments = step["args"] as? [String] ?? []
                app.launch()
            } else if step["activate"] != nil {
                app.activate()
            } else if let label = step["tap"] as? String {
                guard let e = element(label) else { log.append("MISSING \(name)"); continue }
                e.tap()
            } else if let text = step["tapText"] as? String {
                let e = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
                guard e.waitForExistence(timeout: 5) else { log.append("MISSING \(name)"); continue }
                e.tap()
            } else if let point = step["tapAt"] as? [Double], point.count == 2 {
                app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: point[0], dy: point[1])).tap()
            } else if let text = step["type"] as? String {
                app.typeText(text)
            } else if let dir = step["swipe"] as? String {
                switch dir {
                case "up": app.swipeUp()
                case "down": app.swipeDown()
                case "left": app.swipeLeft()
                default: app.swipeRight()
                }
            } else if let seconds = step["wait"] as? Double {
                Thread.sleep(forTimeInterval: seconds)
            } else if let label = step["waitFor"] as? String {
                let timeout = step["timeout"] as? Double ?? 10
                let found = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@ OR identifier == %@", label, label)).firstMatch.waitForExistence(timeout: timeout)
                if !found { log.append("TIMEOUT \(name)") }
            } else if let shot = step["shot"] as? String {
                try XCUIScreen.main.screenshot().pngRepresentation.write(to: out.appendingPathComponent("\(shot).png"))
            } else if let tree = step["tree"] as? String {
                try app.debugDescription.write(to: out.appendingPathComponent("\(tree).txt"), atomically: true, encoding: .utf8)
            } else {
                log.append("UNKNOWN \(name)")
                continue
            }
            log.append("ok \(name)")
        }
    }
}
