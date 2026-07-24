import Foundation

class MeditationResourceManager {
    static let shared = MeditationResourceManager()
    
    // ✅ AKTİF İSTEK TAKİBİ: Aynı tag için birden fazla istek açılmasını engeller.
    private var activeRequests: [String: NSBundleResourceRequest] = [:]
    enum ResourceError: Error {
        case fileNotFound
    }

    private var downloadsDirectoryURL: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directoryURL = baseURL.appendingPathComponent("MeditationDownloads", isDirectory: true)

        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }

        return directoryURL
    }

    private func bundledAudioURL(for meditation: Meditation) -> URL? {
        if let url = Bundle.main.url(forResource: meditation.audioFileName, withExtension: "mp3") {
            return url
        }

        return Bundle.main.url(
            forResource: meditation.audioFileName,
            withExtension: "mp3",
            subdirectory: "Meditations"
        )
    }

    private func downloadedFileURL(for meditation: Meditation) -> URL {
        downloadsDirectoryURL.appendingPathComponent("\(meditation.id.uuidString).mp3")
    }

    private func copyToDownloadsIfNeeded(from sourceURL: URL, for meditation: Meditation) throws -> URL {
        let destinationURL = downloadedFileURL(for: meditation)

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            return destinationURL
        }

        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        return destinationURL
    }

    func isDownloaded(meditation: Meditation) -> Bool {
        FileManager.default.fileExists(atPath: downloadedFileURL(for: meditation).path)
    }

    func removeDownload(for meditation: Meditation) {
        let tag = meditation.odrTag

        if let request = activeRequests[tag] {
            request.endAccessingResources()
            activeRequests.removeValue(forKey: tag)
        }

        let localFileURL = downloadedFileURL(for: meditation)
        if FileManager.default.fileExists(atPath: localFileURL.path) {
            try? FileManager.default.removeItem(at: localFileURL)
        }

        NotificationCenter.default.post(name: NSNotification.Name("ResourceDeleted"), object: tag)
        print("🗑️ Deleted local download for: \(meditation.title)")
    }

    private func sourceAudioURL(for meditation: Meditation, categoryTag: String) async throws -> URL {
        if let localFileURL = optionalDownloadedURL(for: meditation) {
            return localFileURL
        }

        if let bundledURL = bundledAudioURL(for: meditation) {
            return bundledURL
        }

        if let existingRequest = activeRequests[categoryTag] {
            if let url = existingRequest.bundle.url(forResource: meditation.audioFileName, withExtension: "mp3") {
                return url
            } else if let url = existingRequest.bundle.url(
                forResource: meditation.audioFileName,
                withExtension: "mp3",
                subdirectory: "Meditations"
            ) {
                return url
            }
        }

        let request = NSBundleResourceRequest(tags: [categoryTag])
        Bundle.main.setPreservationPriority(1.0, forTags: [categoryTag])

        let alreadyAvailable = await request.conditionallyBeginAccessingResources()
        if !alreadyAvailable {
            try await request.beginAccessingResources()
        }

        activeRequests[categoryTag] = request

        if let url = request.bundle.url(forResource: meditation.audioFileName, withExtension: "mp3") {
            return url
        } else if let url = request.bundle.url(
            forResource: meditation.audioFileName,
            withExtension: "mp3",
            subdirectory: "Meditations"
        ) {
            return url
        } else {
            throw ResourceError.fileNotFound
        }
    }

    func getAudioURL(for meditation: Meditation, categoryTag: String) async throws -> URL {
        if let localFileURL = optionalDownloadedURL(for: meditation) {
            return localFileURL
        }

        let sourceURL = try await sourceAudioURL(for: meditation, categoryTag: categoryTag)
        return try copyToDownloadsIfNeeded(from: sourceURL, for: meditation)
    }

    func streamingAudioURL(for meditation: Meditation) async throws -> URL {
        if let localFileURL = optionalDownloadedURL(for: meditation) {
            return localFileURL
        }

        if let bundledURL = bundledAudioURL(for: meditation) {
            return bundledURL
        }

        return try await sourceAudioURL(for: meditation, categoryTag: meditation.odrTag)
    }

    private func optionalDownloadedURL(for meditation: Meditation) -> URL? {
        let localFileURL = downloadedFileURL(for: meditation)
        guard FileManager.default.fileExists(atPath: localFileURL.path) else { return nil }
        return localFileURL
    }
}
