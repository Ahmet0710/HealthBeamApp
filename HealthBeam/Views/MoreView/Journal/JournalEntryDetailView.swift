import SwiftUI
import MapKit
import Combine
struct JournalEntryDetailView: View {
    @Bindable var journalEntry: JournalEntry
    @EnvironmentObject var achievementsViewModel: AchievementsViewModel
    @State var showingEditSheet: Bool = false
    var locationAnnotations: [MapAnnotationItem] {
        journalEntry.sortedContentBlocks
            .compactMap { block in
                guard block.type == .location, let lat = block.latitude, let lon = block.longitude, let name = block.locationName else {
                    return nil
                }
                return MapAnnotationItem(name: name, coordinate: .init(latitude: lat, longitude: lon))
            }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(journalEntry.title).font(.largeTitle).bold()
                        Spacer()
                        if let mood = journalEntry.mood, let moodIcon = mood.icon { Text(moodIcon).font(.largeTitle) }
                        if journalEntry.isBookmarked { Image(systemName: "bookmark.fill").foregroundColor(.yellow).font(.title) }
                    }
                    Text(journalEntry.date, formatter: DateFormatters.dateTime).font(.subheadline).foregroundColor(.secondary)
                }

                if !locationAnnotations.isEmpty {
                    MultiLocationMapView(locations: locationAnnotations)
                }
                ForEach(journalEntry.sortedContentBlocks.filter { $0.type != .location }, id: \.id) { block in
                    renderContentBlock(block)
                }
            }
            .padding()
        }
        .navigationTitle("Moment details").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Edit") { showingEditSheet = true } } }
        .sheet(isPresented: $showingEditSheet) {
            EditJournalEntryView(journalEntry: journalEntry)
        }
        .onAppear {
            let calendar = Calendar.current
            if let daysAgo = calendar.date(byAdding: .day, value: -30, to: Date()), journalEntry.date < daysAgo {
                achievementsViewModel.markAchievementCompleted(id: "journaling.look_back")
            }
        }
    }

    @ViewBuilder func renderContentBlock(_ block: ContentBlock) -> some View {
        switch block.type {
        case .text: if let text = block.textValue { Text(text).font(.system(.body, design: .serif)).lineSpacing(6) }
        case .image: if let image = block.image { Image(uiImage: image).resizable().scaledToFit().cornerRadius(12) }
        case .location: EmptyView()
        case .audio: if let url = block.audioURL, let duration = block.audioDuration { AudioThumbnailView(audioURL: url, duration: duration) }
        }
    }
}
