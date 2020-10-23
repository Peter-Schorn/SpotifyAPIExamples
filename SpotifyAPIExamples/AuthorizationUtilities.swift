import Foundation
import Combine
import SpotifyWebAPI

/// Retrieves the client id and client secret from the "client_id" and
/// "client_secret" environment variables, respectively.
/// Throws a fatal error if either can't be found.
func getSpotifyCredentialsFromEnvironment() -> (clientId: String, clientSecret: String) {
    guard let clientdId = ProcessInfo.processInfo.environment["client_id"] else {
        fatalError("couldn't find 'client_id' in enviornment variables")
    }
    guard let clientSecret = ProcessInfo.processInfo.environment["client_secret"] else {
        fatalError("couldn't find 'client_secret' in enviornment variables")
    }
    return (clientId: clientdId, clientSecret: clientSecret)
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
        
        _ = cancellable  // supress warnings
        
        semaphore.wait()
        
        if let authorizationError = authorizationError {
            throw authorizationError
        }
        
    }

}
