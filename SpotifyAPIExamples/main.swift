import Foundation
import Combine
import SpotifyWebAPI

var cancellables: Set<AnyCancellable> = []
let dispatchGroup = DispatchGroup()

// Retrieve the client id and client secret from the environment variables.
let spotifyCredentials = getSpotifyCredentialsFromEnvironment()

let spotifyAPI = SpotifyAPI(
    authorizationManager: ClientCredentialsFlowManager(
        clientId: spotifyCredentials.clientId,
        clientSecret: spotifyCredentials.clientSecret
    )
)
// Authorize the application.
try spotifyAPI.authorizationManager.waitUntilAuthorized()

// MARK: - The Application is Now Authorized -

// MARK: Search for Tracks and Albums

dispatchGroup.enter()
spotifyAPI.search(
    query: "The Beatles",
    categories: [.track, .album],
    market: "US"
)
.sink(
    receiveCompletion: { completion in
        print("completion:", completion, terminator: "\n\n\n")
        dispatchGroup.leave()
    },
    receiveValue: { results in
        print("\nReceived results for search for 'The Beatles'")
        let tracks = results.tracks?.items ?? []
        print("found \(tracks.count) tracks:")
        print("------------------------")
        for track in tracks {
            print("\(track.name) - \(track.album?.name ?? "nil")")
        }
        
        let albums = results.albums?.items ?? []
        print("\nfound \(albums.count) albums:")
        print("------------------------")
        for album in albums {
            print("\(album.name)")
        }
        
    }
)
.store(in: &cancellables)
dispatchGroup.wait()


// MARK: Retrieve a Playlist

// "This is Jimi Hendrix"
// https://open.spotify.com/playlist/37i9dQZF1DWTNV753no4ic
let playlistURI = "spotify:playlist:37i9dQZF1DWTNV753no4ic"

dispatchGroup.enter()
spotifyAPI.playlist(playlistURI, market: "US")
    .sink(
        receiveCompletion: { completion in
            print("completion:", completion, terminator: "\n\n\n")
            dispatchGroup.leave()
        },
        receiveValue: { playlist in
            
            print("\nReceived Playlist")
            print("------------------------")
            print("name:", playlist.name)
            print("link:", playlist.externalURLs?["spotify"] ?? "nil")
            print("description:", playlist.description ?? "nil")
            print("total tracks:", playlist.items.total)
            for track in playlist.items.items.compactMap(\.item) {
                print(track.name)
            }
            
        }
    )
    .store(in: &cancellables)
dispatchGroup.wait()


// MARK: Retrieve all the Episodes in a Show

// "The Joe Rogan Experience"
// https://open.spotify.com/show/4rOoJ6Egrf8K2IrywzwOMk
let showURI = "spotify:show:4rOoJ6Egrf8K2IrywzwOMk"

dispatchGroup.enter()
spotifyAPI.showEpisodes(showURI, market: "US", limit: 50)
    // Retrive additional pages of results. In this case,
    // a total of three pages will be retrieved.
    .extendPages(spotifyAPI, maxExtraPages: 2)
    .sink(
        receiveCompletion: { completion in
            print("completion:", completion, terminator: "\n\n\n")
            dispatchGroup.leave()
        },
        receiveValue: { episodes in
            
            let currentPage = (episodes.offset / 50) + 1
            if currentPage == 1 {
                print("Received Show Episodes For The Joe Rogan Experience")
            }
            print("page \(currentPage) of results:")
            print("------------------------")
            for episode in episodes.items {
                print(episode.name)
            }
            print()

        }
    )
    .store(in: &cancellables)
dispatchGroup.wait()

// MARK: Retrieve New Album Releases

dispatchGroup.enter()
spotifyAPI.newAlbumReleases(country: "US")
    .sink(
        receiveCompletion: { completion in
            print("completion:", completion, terminator: "\n\n\n")
            dispatchGroup.leave()
        },
        receiveValue: { newAlbumReleases in
            print("\nReceive New Album Rleases")
            print("------------------------")
            print("message:", newAlbumReleases.message ?? "nil")
            for album in newAlbumReleases.albums.items {
                print("\(album.name) - \(album.artists?.first?.name ?? "nil")")
            }
        }
    )
    .store(in: &cancellables)
dispatchGroup.wait()

// MARK: Artist Top Tracks

// "Cream"
// https://open.spotify.com/artist/74oJ4qxwOZvX6oSsu1DGnw
let artistURI = "spotify:artist:74oJ4qxwOZvX6oSsu1DGnw"

dispatchGroup.enter()
spotifyAPI.artistTopTracks(artistURI, country: "US")
    .sink(
        receiveCompletion: { completion in
            print("completion:", completion, terminator: "\n\n\n")
            dispatchGroup.leave()
        },
        receiveValue: { tracks in
            print("\nReceived top tracks for Cream:")
            print("------------------------")
            for track in tracks {
                print("\(track.name) - \(track.album?.name ?? "nil")")
            }
        }
    )
    .store(in: &cancellables)
dispatchGroup.wait()
