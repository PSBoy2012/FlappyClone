import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                // Background image
                Image("menuBackground")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                VStack(spacing: 30) {
                    // Bird image
                    Image("bird")
                        .resizable()
                        .frame(width: 55, height: 40)
                        .shadow(radius: 4)

                    // Game title
                    Text("FlappyBird!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                        .shadow(radius: 2)

                    // Start button
                    NavigationLink("Start Flapping!") {
                        GameView()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
                .padding()
            }
        }
    }
}
