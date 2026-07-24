import SwiftUI

struct SearchBar: View {
    @Binding public var text: String
    @Binding public var isSearching: Bool
    
    public var placeholder: String = "Search for food..."
    
    public init(text: Binding<String>, isSearching: Binding<Bool>, placeholder: String = "Search for food...") {
        self._text = text
        self._isSearching = isSearching
        self.placeholder = placeholder
    }
    
    public var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField(placeholder, text: $text) { isEditing in
                    withAnimation {
                        isSearching = isEditing
                    }
                } onCommit: {
                    withAnimation {
                        isSearching = false
                        text = ""
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
                .textFieldStyle(PlainTextFieldStyle())
                .disableAutocorrection(true)
                
                if !text.isEmpty {
                    Button(action: {
                        text = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .padding(.horizontal, 8)
    }
}
