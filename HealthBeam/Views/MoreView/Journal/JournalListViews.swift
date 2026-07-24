import SwiftUI
import SwiftData
import LocalAuthentication
import Combine

enum TimeOfDay: String, CaseIterable, Comparable {
    case earlyMorning = "Early Morning"
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"
    case night = "Night"

    init(from date: Date) {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 4..<7: self = .earlyMorning
        case 7..<12: self = .morning
        case 12..<18: self = .afternoon
        case 18..<22: self = .evening
        default: self = .night
        }
    }

    private var sortOrder: Int {
        switch self {
        case .earlyMorning: 0; case .morning: 1; case .afternoon: 2; case .evening: 3; case .night: 4
        }
    }

    static func < (lhs: TimeOfDay, rhs: TimeOfDay) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

struct JournalListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) var scenePhase

    // SwiftData Query (Gerçek Veriler)
    @Query(sort: \JournalEntry.date, order: .reverse) private var journalEntries: [JournalEntry]

    @State private var showingAddSheet = false
    @State private var showingSettingsSheet = false
    @State private var entryToEdit: JournalEntry?

    @StateObject private var authService = AuthenticationService()
    @AppStorage("isJournalLocked") private var isJournalLocked = false
    
    // MARK: - Demo Mode Logic
    // Demo modu açıksa Mock verileri, değilse gerçek SwiftData verilerini kullan
    private var activeEntries: [JournalEntry] {
        if AppReviewManager.shared.isDemoMode {
            return MockJournal.sampleEntries
        }
        return journalEntries
    }

    private var groupedEntries: [Date: [TimeOfDay: [JournalEntry]]] {
        // journalEntries yerine activeEntries kullanıyoruz
        let groupedByDate = Dictionary(grouping: activeEntries) { entry in
            Calendar.current.startOfDay(for: entry.date)
        }
        return groupedByDate.mapValues { entriesOnDate in
            Dictionary(grouping: entriesOnDate) { entry in TimeOfDay(from: entry.date) }
        }
    }

    private var sortedDateKeys: [Date] { groupedEntries.keys.sorted(by: >) }

    var body: some View {
        if isJournalLocked && !authService.isUnlocked {
            lockedView
        } else {
            journalContent
        }
    }

    private var journalContent: some View {
        ZStack(alignment: .bottomTrailing) {
            LinearGradient(
                colors: [Color(red: 40/255, green: 0/255, blue: 60/255), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
                .ignoresSafeArea()
            Group {
                if activeEntries.isEmpty { // Boş durum kontrolü de activeEntries üzerinden
                    emptyStateView
                } else {
                    List {
                        ForEach(sortedDateKeys, id: \.self) { date in
                            let entriesByTime = groupedEntries[date] ?? [:]
                            let sortedTimeKeys = entriesByTime.keys.sorted()
                            sectionView(for: date, entriesByTime: entriesByTime, sortedTimeKeys: sortedTimeKeys)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }

            if #available(iOS 26.0, *) {
                Button("New Entry") {
                    showingAddSheet = true
                }
                .font(.headline)
                .buttonStyle(.glass)
                .foregroundColor(.white)
                .padding()
                .background(Color.clear.opacity(1.0))
                .clipShape(Capsule())
                .shadow(radius: 5, y: 2)
                .padding(.trailing, 20)
                .padding(.bottom, 10)
            } else {
                // Fallback on earlier versions
            }

        }
        .navigationTitle("Journal")
        .toolbarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingSettingsSheet = true }) {
                    Image(systemName: "gearshape")
                    .foregroundStyle(.white)
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) { AddJournalEntryView() }
        .sheet(isPresented: $showingSettingsSheet) { JournalSettingsView(authService: authService) }
        .sheet(item: $entryToEdit) { entry in EditJournalEntryView(journalEntry: entry) }
        .onAppear(perform: authenticateIfNeeded)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background || newPhase == .inactive {
                authService.lock()
            }
            if newPhase == .active {
                if !showingAddSheet && !showingSettingsSheet && entryToEdit == nil {
                    authenticateIfNeeded()
                }
            }
        }
    }

    @ViewBuilder
    private func journalEntryRows(entries: [JournalEntry]) -> some View {
        ForEach(entries) { entry in
            NavigationLink(destination: JournalEntryDetailView(journalEntry: entry)) {
                JournalRowView(entry: entry)
            }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button { entry.isBookmarked.toggle() } label: {
                    Label("Bookmark", systemImage: entry.isBookmarked ? "bookmark.slash.fill" : "bookmark.fill")
                }.tint(.yellow)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) { delete(entry: entry) } label: {
                    Label("Delete", systemImage: "trash.fill")
                }
                Button { entryToEdit = entry } label: {
                    Label("Edit", systemImage: "pencil")
                }.tint(.purple)
            }
        }
    }

    private func sectionView(for date: Date, entriesByTime: [TimeOfDay: [JournalEntry]], sortedTimeKeys: [TimeOfDay]) -> some View {
        Section(header: Text(formatDateHeader(date))) {
            ForEach(sortedTimeKeys, id: \.self) { timeOfDay in
                Text(timeOfDay.rawValue)
                    .font(.caption).foregroundColor(.secondary)
                    .padding(.leading, 5)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))

                if let entriesForTime = entriesByTime[timeOfDay] {
                    ForEach(entriesForTime) { entry in
                        NavigationLink(destination: JournalEntryDetailView(journalEntry: entry)) {
                            JournalRowView(entry: entry)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button { entry.isBookmarked.toggle() } label: {
                                Label("Bookmark", systemImage: entry.isBookmarked ? "bookmark.slash.fill" : "bookmark.fill")
                            }.tint(.yellow)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) { delete(entry: entry) } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }
                            Button { entryToEdit = entry } label: {
                                Label("Edit", systemImage: "pencil")
                            }.tint(.purple)
                        }
                    }
                }
            }
        }
    }

    private var lockedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill")
                .font(.system(size: 44))
                .foregroundColor(.secondary)
            Text("Journal is Locked")
                .font(.title2.bold())

            if authService.canAuthenticate {
                Button("Unlock") {
                    Task { await authService.authenticate() }
                }
                .buttonStyle(.borderedProminent)
                .tint(.customPurple)
            } else {
                Text("To use this feature, Face ID, Touch ID, or a Passcode must be set up on your device.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .navigationTitle("Journal")
        .onAppear(perform: authenticateIfNeeded)
    }

    private func authenticateIfNeeded() {
        if isJournalLocked && !authService.isUnlocked {
            Task { await authService.authenticate() }
        }
    }

    private func delete(entry: JournalEntry) {
        // Demo modunda silmeyi engelle
        if AppReviewManager.shared.isDemoMode { return }
        withAnimation { modelContext.delete(entry) }
    }

    private func formatDateHeader(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(date: .long, time: .omitted)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "moon.stars.fill").font(.system(size: 60)).foregroundColor(.customPurple.opacity(0.5))
            Text("There is no entry yet").font(.title2).bold()
            Text("“Start writing your first journal entry by tapping the ‘New Entry’ button at the bottom right.”")
                .font(.subheadline).foregroundColor(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct JournalRowView: View {
    let entry: JournalEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 12) {
                Text(entry.title).font(.headline).fontWeight(.bold)
                Text(entry.date, formatter: DateFormatters.shortTime).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            if let mood = entry.mood {
                let emoji = moodEmoji(for: mood)
                Text(emoji).font(.title2)
            }
            if entry.isBookmarked { Image(systemName: "bookmark.fill").foregroundColor(.yellow).font(.caption).padding(.leading, 4) }
        }
        .padding(.vertical, 8).padding(.horizontal, 16)
    }
    
    // Basit bir mood -> emoji çevirici (Sizin mood mantığınıza göre uyarlayın)
    func moodEmoji(for mood: String) -> String {
        switch mood.lowercased() {
        case "happy": return "😊"
        case "relaxed": return "😌"
        case "grateful": return "🙏"
        case "thoughtful": return "🤔"
        case "excited": return "🤩"
        default: return "😐"
        }
    }
}
