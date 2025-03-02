import SwiftUI

struct PupCalendarView: View {
    @EnvironmentObject var viewModel: PupViewModel
    
    @State private var selectedDate: Date = Date()
    @State private var currentMonth: Date = Date()
    @State private var showExporter = false
    @State private var csvURL: URL?
    
    let columns = 7
    let calendar = Calendar.current
    
    var body: some View {
        NavigationStack {
            VStack {
                monthHeader
                calendarGrid
                
                // Show logs for selected date
                List {
                    let dayLogs = viewModel.logs(for: selectedDate)
                    if dayLogs.isEmpty {
                        Text("No tasks logged on this day.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(dayLogs) { entry in
                            Text("\(entry.taskName) at \(entry.timestamp, style: .time)")
                        }
                    }
                }
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if let url = viewModel.exportLogsToCSV() {
                            csvURL = url
                            showExporter = true
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showExporter) {
                if let csvURL {
                    ShareSheet(activityItems: [csvURL])
                }
            }
        }
    }
    
    private var monthHeader: some View {
        HStack {
            Button {
                moveMonth(-1)
            } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(monthTitleString(currentMonth))
                .font(.headline)
            Spacer()
            Button {
                moveMonth(1)
            } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding(.horizontal)
    }
    
    private var calendarGrid: some View {
        let days = makeDaysInMonth(for: currentMonth)
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: columns), spacing: 8) {
            ForEach(days, id: \.self) { date in
                VStack {
                    Text("\(calendar.component(.day, from: date))")
                        .font(.callout)
                        .foregroundColor(
                            isSameMonth(date, as: currentMonth) ? .primary : .gray
                        )
                    
                    // Pastel dot if logs exist
                    if !viewModel.logs(for: date).isEmpty {
                        Circle()
                            .fill(Color("PastelBlue"))
                            .frame(width: 6, height: 6)
                    }
                }
                .frame(minHeight: 40)
                .onTapGesture {
                    selectedDate = date
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func makeDaysInMonth(for base: Date) -> [Date] {
        guard let interval = calendar.dateInterval(of: .month, for: base) else { return [] }
        
        var days: [Date] = []
        
        // Leading offset
        var current = interval.start
        let weekdayOffset = calendar.component(.weekday, from: current) - calendar.firstWeekday
        for _ in 0..<(weekdayOffset < 0 ? weekdayOffset + 7 : weekdayOffset) {
            if let prev = calendar.date(byAdding: .day, value: -1, to: current) {
                current = prev
                days.insert(current, at: 0)
            }
        }
        
        // Month days
        current = interval.start
        while current < interval.end {
            days.append(current)
            if let nxt = calendar.date(byAdding: .day, value: 1, to: current) {
                current = nxt
            } else {
                break
            }
        }
        
        // Trailing offset
        while days.count % 7 != 0 {
            if let nxt = calendar.date(byAdding: .day, value: 1, to: days.last!) {
                days.append(nxt)
            } else {
                break
            }
        }
        
        return days
    }
    
    private func isSameMonth(_ d1: Date, as d2: Date) -> Bool {
        calendar.component(.month, from: d1) == calendar.component(.month, from: d2) &&
        calendar.component(.year, from: d1) == calendar.component(.year, from: d2)
    }
    
    private func monthTitleString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func moveMonth(_ offset: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: offset, to: currentMonth) {
            currentMonth = newMonth
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}