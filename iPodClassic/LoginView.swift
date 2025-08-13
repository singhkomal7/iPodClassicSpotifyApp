import SwiftUI

struct LoginView: View {
    @EnvironmentObject var spotifyManager: SpotifyManager

    var body: some View {
        VStack {
            Text("iPod Classic")
                .font(.system(size: 24)) // Fallback font if Px437_IBM_VGA8 is missing
                .foregroundColor(.white)
                .padding(.bottom, 20)
            
            Button(action: {
                print("🔐 Login button tapped, isLoggedIn: \(spotifyManager.isLoggedIn), id: \(ObjectIdentifier(spotifyManager))")
                spotifyManager.login()
            }) {
                Text("Login with Spotify")
                    .font(.system(size: 18))
                    .foregroundColor(.black)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear {
            print("🔐 LoginView appeared, isLoggedIn: \(spotifyManager.isLoggedIn), id: \(ObjectIdentifier(spotifyManager))")
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(SpotifyManager())
    }
}
