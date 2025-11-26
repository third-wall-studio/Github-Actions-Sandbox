import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "fireworks")
                .imageScale(.large)
                .foregroundStyle(.tint)

            Text("Look ma, no hands!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
