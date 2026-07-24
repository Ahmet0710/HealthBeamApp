import SwiftUI
import SwiftData
import MapKit
import PhotosUI
import AVFoundation
import Combine
import UIKit
struct AddJournalEntryView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var achievementsViewModel: AchievementsViewModel

    private let initialMood: String?
    @State var title: String = ""
    @State var mainText: String = ""
    @State var selectedMood: String = "🙂 Happy"
    @State private var selectedAchievementTags = Set<JournalAchievementTag>()
    @State var contentBlocks: [ContentBlock] = []
    @State var showingCamera = false
    @State var showingPhotoLibrary = false
    @State var showingLocationPicker = false
    @State var showingAudioRecorder = false
    @State var isSaving = false
    let moods = ["🙂 Happy", "😊 Joyful", "😐 Neutral", "😔 Sad", "😠 Angry", "😴 Tired"]

    init(initialMood: String? = nil) {
        self.initialMood = initialMood
        _selectedMood = State(initialValue: initialMood ?? "🙂 Happy")
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(Date(), formatter: DateFormatters.fullDate)
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding([.horizontal, .top])
                        TextField("Title of the Day", text: $title)
                            .font(.system(size: 36, weight: .bold, design: .serif))
                            .padding(.horizontal)
                        moodSelector
                            .padding(.vertical, 10)
                        achievementTagSelector
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $mainText)
                                .font(.system(.body, design: .serif))
                                .frame(minHeight: 200)
                                .padding(.horizontal)
                            if mainText.isEmpty {
                                Text("Write down what’s on your mind…")
                                    .font(.system(.body, design: .serif))
                                    .foregroundColor(.gray.opacity(0.6))
                                    .padding(.horizontal, 22).padding(.top, 8)
                                    .allowsHitTesting(false)
                            }
                        }
                        ForEach(contentBlocks, id: \.id) { block in
                            renderAddedContent(block)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 120)
                }
                JournalBottomToolbar(
                    onPhoto: { self.showingPhotoLibrary = true },
                    onCamera: { self.showingCamera = true },
                    onAudio: { self.showingAudioRecorder = true },
                    onLocation: { self.showingLocationPicker = true }
                )
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard !isSaving else { return }
                        isSaving = true
                        saveJournalEntry()
                    }.disabled(title.isEmpty || isSaving)
                }
            }
            .sheet(isPresented: $showingPhotoLibrary) { ImagePicker(sourceType: UIImagePickerController.SourceType.photoLibrary, completionHandler: handleImageSelection) }
            .sheet(isPresented: $showingCamera) { CameraView(onPhotoTaken: handleImageSelection) }
            .sheet(isPresented: $showingLocationPicker) { AddLocationView(onLocationSelected: handleLocationSelection) }
            .sheet(isPresented: $showingAudioRecorder) { AudioRecorderView(onAudioRecorded: handleAudioSelection) }
        }
        .background(Color.systemGroupedBackground.ignoresSafeArea())
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    var moodSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's Mood").font(.caption).foregroundColor(.secondary).padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(moods, id: \.self) { mood in
                        Text(mood).padding(.horizontal, 12).padding(.vertical, 8)
                            .background(selectedMood == mood ? Color.customPurple.opacity(0.2) : Color.clear)
                            .cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(selectedMood == mood ? Color.customPurple : Color.gray.opacity(0.3), lineWidth: 1))
                            .onTapGesture { selectedMood = mood }
                    }
                }.padding(.horizontal)
            }
        }
    }

    var achievementTagSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Entry Focus").font(.caption).foregroundColor(.secondary).padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(JournalAchievementTag.allCases) { tag in
                        let isSelected = selectedAchievementTags.contains(tag)
                        Text(tag.title)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(isSelected ? Color.customPurple.opacity(0.2) : Color.clear)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(isSelected ? Color.customPurple : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .onTapGesture {
                                if isSelected {
                                    selectedAchievementTags.remove(tag)
                                } else {
                                    selectedAchievementTags.insert(tag)
                                }
                            }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder func renderAddedContent(_ block: ContentBlock) -> some View {
        switch block.type {
        case .image: if let img = block.image { Image(uiImage: img).resizable().scaledToFit().cornerRadius(12) }
        case .location: if let name = block.locationName, let lat = block.latitude, let lon = block.longitude { LocationThumbnailView(locationName: name, latitude: lat, longitude: lon) }
        case .audio: if let url = block.audioURL, let duration = block.audioDuration { AudioThumbnailView(audioURL: url, duration: duration) }
        default: EmptyView()
        }
    }

    func handleImageSelection(_ image: UIImage?) { if let image = image { contentBlocks.append(ContentBlock(image: image)) } }
    func handleLocationSelection(name: String, coordinate: CLLocationCoordinate2D) { contentBlocks.append(ContentBlock(name: name, latitude: coordinate.latitude, longitude: coordinate.longitude)) }
    func handleAudioSelection(url: URL, duration: TimeInterval) { contentBlocks.append(ContentBlock(url: url, duration: duration)) }

    func saveJournalEntry() {
        let newEntry = JournalEntry(
            date: Date(),
            title: title,
            mood: selectedMood,
            achievementTagValues: selectedAchievementTags.map(\.rawValue).sorted()
        )
        let richContentBlocks = self.contentBlocks.filter { $0.type != .text }
        newEntry.contentBlocks = richContentBlocks
        if !mainText.isEmpty {
            let textBlock = ContentBlock(text: mainText)
            if newEntry.contentBlocks == nil {
                newEntry.contentBlocks = [textBlock]
            } else {
                newEntry.contentBlocks?.append(textBlock)
            }
        }
        modelContext.insert(newEntry)

        achievementsViewModel.markAchievementCompleted(id: "journaling.first_page")
        if mainText.count >= 250 {
            achievementsViewModel.markAchievementCompleted(id: "journaling.deep_thought")
        }
        if contentBlocks.contains(where: { $0.type == .image }) {
            achievementsViewModel.markAchievementCompleted(id: "journaling.capture_moment")
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let allEntries = try? modelContext.fetch(FetchDescriptor<JournalEntry>())
        if let allEntries {
            let entryDays = Set(allEntries.map { calendar.startOfDay(for: $0.date) })
            var streak = 0
            var dateToCheck = today
            while entryDays.contains(dateToCheck) {
                streak += 1
                dateToCheck = calendar.date(byAdding: .day, value: -1, to: dateToCheck)!
            }
            if streak >= 3 {
                achievementsViewModel.markAchievementCompleted(id: "journaling.daily_streak")
            }
            let currentMonth = calendar.component(.month, from: today)
            let currentYear = calendar.component(.year, from: today)
            let entriesThisMonth = allEntries.filter {
                let comps = calendar.dateComponents([.year, .month], from: $0.date)
                return comps.year == currentYear && comps.month == currentMonth
            }
            if entriesThisMonth.count >= 10 {
                achievementsViewModel.markAchievementCompleted(id: "journaling.monthly_writer")
            }
            let moodDays = Set(allEntries.filter { ($0.mood ?? "").isEmpty == false }.map { calendar.startOfDay(for: $0.date) })
            var moodStreak = 0
            var moodDate = today
            while moodDays.contains(moodDate) {
                moodStreak += 1
                moodDate = calendar.date(byAdding: .day, value: -1, to: moodDate)!
            }
            if moodStreak >= 7 {
                achievementsViewModel.markAchievementCompleted(id: "journaling.mood_tracker")
            }
        }
        if selectedAchievementTags.contains(.gratitude) {
            achievementsViewModel.markAchievementCompleted(id: "journaling.gratitude")
        }
        if selectedAchievementTags.contains(.goals) {
            achievementsViewModel.markAchievementCompleted(id: "journaling.set_goals")
        }
        if selectedAchievementTags.contains(.brainstorm) || mainText.count >= 350 {
            achievementsViewModel.markAchievementCompleted(id: "journaling.brainstorm")
        }
        dismiss()
    }
}
struct EditJournalEntryView: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var journalEntry: JournalEntry
    @State var title: String = ""
    @State var mainText: String = ""
    @State var selectedMood: String = "🙂 Happy"
    @State private var selectedAchievementTags = Set<JournalAchievementTag>()
    @State var isSaving = false
    let moods = ["🙂 Happy", "😊 Joyful", "😐 Neutral", "😔 Sad", "😠 Angry", "😴 Tired"]
    @State var showingCamera = false
    @State var showingPhotoLibrary = false
    @State var showingLocationPicker = false
    @State var showingAudioRecorder = false
    var locationAnnotations: [MapAnnotationItem] {
        journalEntry.sortedContentBlocks.compactMap { block in
            guard block.type == .location, let lat = block.latitude, let lon = block.longitude, let name = block.locationName else { return nil }
            return MapAnnotationItem(name: name, coordinate: .init(latitude: lat, longitude: lon))
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        TextField("Title of the Day", text: $title, axis: .vertical).font(.system(size: 36, weight: .bold, design: .serif)).padding(.horizontal)
                        moodSelector.padding(.vertical, 10)
                        achievementTagSelector
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $mainText).font(.system(.body, design: .serif)).frame(minHeight: 200).padding(.horizontal)
                            if mainText.isEmpty {
                                Text("Write down what’s on your mind…").font(.system(.body, design: .serif)).foregroundColor(.gray.opacity(0.6)).padding(.horizontal, 22).padding(.top, 8).allowsHitTesting(false)
                            }
                        }
                        if !locationAnnotations.isEmpty {
                            MultiLocationMapView(locations: locationAnnotations).padding(.horizontal)
                        }
                        ForEach(journalEntry.sortedContentBlocks.filter { $0.type != .text && $0.type != .location }) { block in
                            renderBlockForEditing(block)
                        }
                    }
                    .padding(.bottom, 120)
                }
                JournalBottomToolbar(
                    onPhoto: { self.showingPhotoLibrary = true },
                    onCamera: { self.showingCamera = true },
                    onAudio: { self.showingAudioRecorder = true },
                    onLocation: { self.showingLocationPicker = true }
                )
            }
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard !isSaving else { return }
                        isSaving = true
                        saveChanges()
                    }.disabled(title.isEmpty || isSaving)
                }
            }
            .onAppear(perform: loadData)
            .sheet(isPresented: $showingPhotoLibrary) { ImagePicker(sourceType: UIImagePickerController.SourceType.photoLibrary, completionHandler: handleImageSelection) }
            .sheet(isPresented: $showingCamera) { CameraView(onPhotoTaken: handleImageSelection) }
            .sheet(isPresented: $showingLocationPicker) { AddLocationView(onLocationSelected: handleLocationSelection) }
            .sheet(isPresented: $showingAudioRecorder) { AudioRecorderView(onAudioRecorded: handleAudioSelection) }
        }
        .background(Color.systemGroupedBackground.ignoresSafeArea())
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    func handleImageSelection(_ image: UIImage?) {
        if let image = image {
            let newBlock = ContentBlock(image: image)
            journalEntry.contentBlocks?.append(newBlock)
        }
    }
    func handleLocationSelection(name: String, coordinate: CLLocationCoordinate2D) {
        let newBlock = ContentBlock(name: name, latitude: coordinate.latitude, longitude: coordinate.longitude)
        journalEntry.contentBlocks?.append(newBlock)
    }
    func handleAudioSelection(url: URL, duration: TimeInterval) {
        let newBlock = ContentBlock(url: url, duration: duration)
        journalEntry.contentBlocks?.append(newBlock)
    }
    var moodSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's Mood").font(.caption).foregroundColor(.secondary).padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(moods, id: \.self) { mood in
                        Text(mood).padding(.horizontal, 12).padding(.vertical, 8)
                            .background(selectedMood == mood ? Color.customPurple.opacity(0.2) : Color.clear)
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(selectedMood == mood ? Color.customPurple : Color.gray.opacity(0.3), lineWidth: 1))
                            .onTapGesture { selectedMood = mood }
                    }
                }.padding(.horizontal)
            }
        }
    }
    var achievementTagSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Entry Focus").font(.caption).foregroundColor(.secondary).padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(JournalAchievementTag.allCases) { tag in
                        let isSelected = selectedAchievementTags.contains(tag)
                        Text(tag.title).padding(.horizontal, 12).padding(.vertical, 8)
                            .background(isSelected ? Color.customPurple.opacity(0.2) : Color.clear)
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(isSelected ? Color.customPurple : Color.gray.opacity(0.3), lineWidth: 1))
                            .onTapGesture {
                                if isSelected {
                                    selectedAchievementTags.remove(tag)
                                } else {
                                    selectedAchievementTags.insert(tag)
                                }
                            }
                    }
                }.padding(.horizontal)
            }
        }
    }
    func loadData() {
        self.title = journalEntry.title
        self.selectedMood = journalEntry.mood ?? "🙂 Happy"
        self.selectedAchievementTags = journalEntry.achievementTags
        if let textBlock = journalEntry.sortedContentBlocks.first(where: { $0.type == .text }) {
            self.mainText = textBlock.textValue ?? ""
        }
    }
    func saveChanges() {
        journalEntry.title = self.title
        journalEntry.mood = self.selectedMood
        journalEntry.achievementTagValues = selectedAchievementTags.map(\.rawValue).sorted()
        if let textBlock = journalEntry.contentBlocks?.first(where: { $0.type == .text }) {
            textBlock.textValue = self.mainText
        } else if !mainText.isEmpty {
            let newTextBlock = ContentBlock(text: mainText)
            if journalEntry.contentBlocks == nil {
                journalEntry.contentBlocks = [newTextBlock]
            } else {
                journalEntry.contentBlocks?.append(newTextBlock)
            }
        }
        dismiss()
    }
    @ViewBuilder
    func renderBlockForEditing(_ block: ContentBlock) -> some View {
        switch block.type {
        case .image:
            if let image = block.image {
                Image(uiImage: image).resizable().scaledToFit().cornerRadius(12).padding(.horizontal)
            }
        case .location: EmptyView()
        case .audio:
            if let url = block.audioURL, let duration = block.audioDuration {
                AudioThumbnailView(audioURL: url, duration: duration).padding(.horizontal)
            }
        case .text: EmptyView()
        }
    }
}
