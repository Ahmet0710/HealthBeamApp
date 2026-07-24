import SwiftUI

struct AddHabitSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var icon: String
    @State private var color: Color
    @State private var time: Date
    @State private var selectedCategory: String
    @State private var showDeleteAlert = false

    private let habit: Habit?
    var onSave: (String, String, String, DateComponents, String) -> Void
    var onDelete: (() -> Void)?
    let categories = ["Morning", "Afternoon", "Evening"]

    init(
        habit: Habit? = nil,
        onSave: @escaping (String, String, String, DateComponents, String) -> Void,
        onDelete: (() -> Void)? = nil
    ) {
        self.habit = habit
        self.onSave = onSave
        self.onDelete = onDelete

        if let habit = habit {
            _name = State(initialValue: habit.name)
            _icon = State(initialValue: habit.icon)
            _color = State(initialValue: Color(hex: habit.color) ?? .blue)
            let calendar = Calendar.current
            _time = State(initialValue: calendar.date(from: habit.time) ?? Date())
            _selectedCategory = State(initialValue: habit.category)
        } else {
            _name = State(initialValue: "")
            _icon = State(initialValue: "flame.fill")
            _color = State(initialValue: .blue)
            _time = State(initialValue: Calendar.current.date(
                bySettingHour: 8,
                minute: 0,
                second: 0,
                of: Date()
            ) ?? Date())
            _selectedCategory = State(initialValue: "Morning")
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [color.opacity(0.85), Color.black.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            Color.white.opacity(0.09)
                .ignoresSafeArea()
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        TextField("Habit name", text: $name)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 10)
                            .background(Color.clear)
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.13), lineWidth: 1)
                            )
                        Text("Icon")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.white)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(Self.habitIcons, id: \.self) { iconName in
                                    Button { icon = iconName } label: {
                                        Image(systemName: iconName)
                                            .font(.title2)
                                            .foregroundColor(icon == iconName ? color : .white)
                                            .padding(8)
                                            .background(icon == iconName ? color.opacity(0.14) : Color.clear)
                                            .clipShape(Circle())
                                    }
                                }
                            }
                        }

                        Text("Icon Color")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.white)

                        ColorPicker("Pick a color", selection: $color)
                            .labelsHidden()
                            .padding(.bottom, 8)
                            .preferredColorScheme(.dark)

                        Text("Target Time")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.white)

                        DatePicker("Select Time", selection: $time, displayedComponents: [.hourAndMinute])
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .tint(.white)

                        Text("Category")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.white)

                        Picker("Category", selection: $selectedCategory) {
                            ForEach(categories, id: \.self) { category in
                                Text(String(localized: String.LocalizationValue(category))).foregroundColor(.white)
                            }
                        }
                        .pickerStyle(.segmented)
                        .tint(.white)
                     
                        
                        if habit != nil && onDelete != nil {
                            Button {
                                showDeleteAlert = true
                            } label: {
                                Text("Delete")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                        }
                    }
                    .padding(.bottom, 30)
                }
                .padding(.horizontal)
                .navigationTitle(name.isEmpty ? String(localized: "Add Habit") : String(localized: "Edit Habit"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                            .foregroundColor(.white)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            if !name.isEmpty {
                                let calendar = Calendar.current
                                let components = calendar.dateComponents([.hour, .minute], from: time)
                                onSave(name, icon, color.toHex() ?? "#000000", components, selectedCategory)
                                dismiss()
                            }
                        } label: {
                            Text("Save")
                        }
                        .foregroundColor(.white)
                    }
                }
                .alert("Delete Habit?", isPresented: $showDeleteAlert) {
                    Button("Delete", role: .destructive) {
                        onDelete?()
                        dismiss()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Are you sure you want to delete this habit? This action cannot be undone.")
                }
                .preferredColorScheme(.dark)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    static let habitIcons = [
        "drop.fill", "figure.walk", "book.fill", "brain.head.profile", "bed.double.fill", "flame.fill",
        "heart.fill", "bolt.fill", "star.fill", "clock", "leaf", "pawprint", "bicycle", "car", "cloud.sun",
        "checkmark.seal", "calendar", "pencil", "music.note", "cart.fill", "dumbbell", "figure.run",
        "moon.fill", "sun.max.fill", "sparkles", "bolt.heart", "globe", "applelogo", "camera", "paintpalette",
        "gamecontroller", "hand.thumbsup.fill", "medal.fill", "trophy.fill", "water.waves", "cup.and.saucer.fill",
        "bell.fill", "bookmark.fill", "envelope.fill", "person.2.fill", "house.fill", "scissors", "film",
        "creditcard.fill", "gift.fill", "tree.fill", "umbrella.fill", "wand.and.stars", "graduationcap.fill"
    ]
}
