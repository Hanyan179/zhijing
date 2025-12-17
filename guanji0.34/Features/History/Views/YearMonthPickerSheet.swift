import SwiftUI

struct YearMonthPickerSheet: View {
    @Binding var selectedDate: Date
    let minDate: Date?
    let maxDate: Date?
    let onSelect: (Date) -> Void
    @Environment(\.dismiss) private var dismiss
    
    // Generate years dynamically based on available data
    private var years: [Int] {
        let calendar = Calendar.current
        let startYear = minDate != nil ? calendar.component(.year, from: minDate!) : 2020
        let endYear = maxDate != nil ? calendar.component(.year, from: maxDate!) : calendar.component(.year, from: Date())
        // Ensure at least current year is available if no data
        return Array(startYear...max(endYear, startYear)).reversed()
    }
    
    private let months = Calendar.current.monthSymbols
    
    @State private var selectedYear: Int
    @State private var selectedMonthIndex: Int
    
    init(currentDate: Date, minDate: Date? = nil, maxDate: Date? = nil, onSelect: @escaping (Date) -> Void) {
        _selectedDate = .constant(currentDate)
        self.minDate = minDate
        self.maxDate = maxDate
        self.onSelect = onSelect
        
        let calendar = Calendar.current
        _selectedYear = State(initialValue: calendar.component(.year, from: currentDate))
        _selectedMonthIndex = State(initialValue: calendar.component(.month, from: currentDate) - 1)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text(Localization.tr("jumpToDate"))
                    .font(Typography.header)
                    .foregroundColor(Colors.slateText)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(Colors.slate500)
                }
            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            // Pickers
            HStack(spacing: 0) {
                Picker(Localization.tr("year"), selection: $selectedYear) {
                    ForEach(years, id: \.self) { year in
                        Text(String(format: "%d", year)).tag(year)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                
                Picker(Localization.tr("month"), selection: $selectedMonthIndex) {
                    ForEach(0..<months.count, id: \.self) { index in
                        Text(months[index]).tag(index)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
            }
            .frame(height: 150)
            
            // Action Button
            Button(action: {
                let components = DateComponents(year: selectedYear, month: selectedMonthIndex + 1, day: 1)
                if let date = Calendar.current.date(from: components) {
                    onSelect(date)
                    dismiss()
                }
            }) {
                Text(Localization.tr("go"))
                    .font(Typography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Colors.indigo)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .presentationDetents([.height(300)])
        .presentationDragIndicator(.visible)
        .background(Colors.background)
    }
}
