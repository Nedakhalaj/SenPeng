import Foundation
import os

/// The real `SiteRepository`: downloads SL's stop list and keeps a copy on the device.
///
/// - A saved copy younger than `maxCacheAge` is used without asking the server.
/// - An older copy is refreshed. If that fails (for example offline), the old copy
///   is still used, because stops rarely change and an old list beats no list.
actor LiveSiteRepository: SiteRepository {

    /// The downloaded list and when it was downloaded, as saved on the device.
    private struct Cache: Codable {
        let fetchedAt: Date
        let sites: [SiteDTO]
    }

    /// Sends the download request.
    private let apiClient: any APIClient

    /// Where the saved copy is stored.
    private let cacheURL: URL

    /// How long a saved copy is used before it's refreshed.
    private let maxCacheAge: TimeInterval

    /// Returns the current time. Injected so tests can control time.
    private let now: @Sendable () -> Date

    /// The saved copy, kept in memory after the first read.
    private var cache: Cache?

    /// Creates the repository.
    /// - Parameters:
    ///   - apiClient: Sends the download request.
    ///   - cacheURL: Where to save the copy. By default in the app's Caches folder,
    ///     which iOS may clear when space is low; the list is then downloaded again.
    ///   - maxCacheAge: How long to use a saved copy. One week by default.
    ///   - now: Returns the current time.
    init(
        apiClient: any APIClient,
        cacheURL: URL = .cachesDirectory.appending(path: "sl-sites.json"),
        maxCacheAge: TimeInterval = 7 * 24 * 60 * 60,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.apiClient = apiClient
        self.cacheURL = cacheURL
        self.maxCacheAge = maxCacheAge
        self.now = now
    }

    func sites() async throws(NetworkError) -> [Site] {
        let saved = cache ?? readCache()
        if let saved, now().timeIntervalSince(saved.fetchedAt) < maxCacheAge {
            return saved.sites.map { $0.toSite() }
        }

        do {
            let downloaded = try await apiClient.send(SLTransportAPI.sites())
            let fresh = Cache(fetchedAt: now(), sites: downloaded)
            cache = fresh
            writeCache(fresh)
            return downloaded.map { $0.toSite() }
        } catch {
            guard let saved else {
                throw error
            }
            Logger.networking.notice("Using saved stop list; refresh failed: \(String(describing: error), privacy: .public)")
            return saved.sites.map { $0.toSite() }
        }
    }

    /// Reads the saved copy from disk, or `nil` if there is none or it can't be read.
    private func readCache() -> Cache? {
        guard let data = try? Data(contentsOf: cacheURL) else {
            return nil
        }
        do {
            let saved = try JSONDecoder().decode(Cache.self, from: data)
            cache = saved
            return saved
        } catch {
            // A broken file is ignored and replaced by the next download.
            Logger.persistence.error("Saved stop list unreadable: \(String(describing: error), privacy: .public)")
            return nil
        }
    }

    /// Saves a copy to disk. A failure is only logged; the app still works without it.
    private func writeCache(_ cache: Cache) {
        do {
            let data = try JSONEncoder().encode(cache)
            try data.write(to: cacheURL, options: .atomic)
        } catch {
            Logger.persistence.error("Saving stop list failed: \(String(describing: error), privacy: .public)")
        }
    }
}
