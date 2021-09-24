import Foundation
import Combine
import SpotifyWebAPI

/// Retrieves the client id and client secret from the "CLIENT_ID" and
/// "CLIENT_SECRET" environment variables, respectively.
/// Throws a fatal error if either can't be found.
func getSpotifyCredentialsFromEnvironment() -> (clientId: String, clientSecret: String) {
    guard let clientId = ProcessInfo.processInfo.environment["CLIENT_ID"] else {
        fatalError("couldn't find 'CLIENT_ID' in environment variables")
    }
    guard let clientSecret = ProcessInfo.processInfo.environment["CLIENT_SECRET"] else {
        fatalError("couldn't find 'CLIENT_SECRET' in environment variables")
    }
    return (clientId: clientId, clientSecret: clientSecret)
}

extension ClientCredentialsFlowManager {
    
    /**
     A convenience method that calls through to `authorize()` and then blocks
     the thread until the publisher completes. Returns early if the application
     is already authorized.
     
     This method is defined in *this* app, not in the `SpotifyWebAPI` module.

     - Throws: If `authorize()` finishes with an error.
     */
    func waitUntilAuthorized() throws {
        
        if self.isAuthorized() { return }
        
        let semaphore = DispatchSemaphore(value: 0)
        
        var authorizationError: Error? = nil
        
        let cancellable = self.authorize()
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    authorizationError = error
                }
                semaphore.signal()
            })
        
        _ = cancellable  // suppress warnings
        
        semaphore.wait()
        
        if let authorizationError = authorizationError {
            throw authorizationError
        }
        
    }

}
