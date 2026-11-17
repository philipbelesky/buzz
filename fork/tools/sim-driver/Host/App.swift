import SwiftUI

// The UI-test target needs a host app; the tests drive another app by bundle id.
@main
struct SimDriverHostApp: App {
    var body: some Scene { WindowGroup { Text("SimDriver host") } }
}
