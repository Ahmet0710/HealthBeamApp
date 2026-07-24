import SwiftUI
public struct MacronutrientInputView: View {
    public let title: String
    @Binding public var value: Double
    public let unit: String
    public let color: Color
    
    @State private var stringValue: String = ""
    @FocusState private var isFieldFocused: Bool
    
    public init(title: String, value: Binding<Double>, unit: String, color: Color) {
        self.title = title
        self._value = value
        self.unit = unit
        self.color = color
        let initialValue = value.wrappedValue
        self._stringValue = State(initialValue: initialValue > 0 ? String(format: "%g", initialValue) : "")
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(color.opacity(0.9))
                
                Spacer()
                
                HStack(spacing: 0) {
                    TextField("0", text: $stringValue)
                        .onChange(of: stringValue) { oldValue, newValue in
                            if newValue.isEmpty {
                                value = 0
                                return
                            }
                            
                            let filtered = newValue.filter { "0123456789.".contains($0) }
                            if filtered != newValue {
                                stringValue = filtered
                                return
                            }
                            
                            if newValue.components(separatedBy: ".").count > 2 {
                                stringValue = String(newValue.dropLast())
                                return
                            }
                            
                            if newValue.hasPrefix("0") && newValue.count > 1 && !newValue.hasPrefix("0.") {
                                stringValue = String(newValue.dropFirst())
                                return
                            }
                            
                            if newValue == "." {
                                stringValue = "0."
                                value = 0
                                return
                            }

                            if let doubleValue = Double(newValue) {
                                value = max(0, doubleValue)
                            } else if !newValue.isEmpty {
                                stringValue = value > 0 ? String(format: "%g", value) : ""
                            }
                        }
                        .onTapGesture {
                            isFieldFocused = true
                        }
                        .onAppear {
                            stringValue = formattedString(for: value, keepZero: false)
                        }
                        .onChange(of: value) { oldValue, newValue in
                            guard !isFieldFocused else { return }
                            let shouldKeepZero = !stringValue.isEmpty || oldValue > 0
                            stringValue = formattedString(for: newValue, keepZero: shouldKeepZero)
                        }
                        .onChange(of: isFieldFocused) { _, isFocused in
                            guard !isFocused else { return }
                            stringValue = formattedString(for: value, keepZero: !stringValue.isEmpty)
                        }
                        .focused($isFieldFocused)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    
                    Text(unit)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            Rectangle()
                .frame(height: 1)
                .padding(.horizontal)
                .foregroundColor(color.opacity(0.3))
        }
        .padding(.vertical, 8)
    }

    private func formattedString(for value: Double, keepZero: Bool) -> String {
        guard value != 0 else { return keepZero ? "0" : "" }

        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%g", value)
    }
}
public struct MacronutrientInputView_Previews: PreviewProvider {
    public static var previews: some View {
        VStack {
            MacronutrientInputView(
                title: "Protein",
                value: .constant(25.0),
                unit: "g",
                color: .red
            )
            MacronutrientInputView(
                title: "Carbs",
                value: .constant(30.0),
                unit: "g",
                color: .green
            )
            MacronutrientInputView(
                title: "Fat",
                value: .constant(15.0),
                unit: "g",
                color: .yellow
            )
        }
        .padding()
    }
}
