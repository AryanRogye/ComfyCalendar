import SwiftUI
import EventKit

public enum ComfyCalendarOptions {
    case showMonthly
    case showWeekly
    case showDaily
}

public struct ComfyCalendarView: View {
    
    @Binding var calendars: [EKCalendar]
    @Binding var reminders: [EKReminder]
    @Binding var options: ComfyCalendarOptions
    
    var eventsByDay: [Date: [EKReminder]] {
        Dictionary(grouping: reminders) {
            Calendar.current.startOfDay(for: $0.dueDateComponents?.date ?? Date.distantPast)
        }
    }
    
    
    public init(calendars: Binding<[EKCalendar]>,
                reminders: Binding<[EKReminder]>,
                with options: Binding<ComfyCalendarOptions>
    ) {
        _calendars = calendars
        _reminders = reminders
        _options = options
    }
    
    
    public var body: some View {
        switch options {
        case .showMonthly:
            CalendarMonthView(eventsByDay: eventsByDay)
        case .showWeekly:
            CalendarWeekView(eventsByDay: eventsByDay)
        case .showDaily:
            CalendarDayView(date: Date(), reminders: reminders, isSelected: false , currentOption: .showDaily) {
                // Action for daily view
            }
        }
    }
}

struct CalendarMonthView: View {
    let eventsByDay: [Date: [EKReminder]]
    @State private var selectedDate: Date = Date()
    
    private let calendar = Calendar.current
    @State var days : [Date] = []
    
    var body: some View {
        VStack {
            // Weekday headers
            HStack {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.secondary)
                }
            }

            // Grid of days
            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(20), spacing: 10), count: 7),
                spacing: 4
            )
            {
                ForEach(days, id: \.self) { day in
                    let reminders = eventsByDay[calendar.startOfDay(for: day)] ?? []
                    CalendarDayView(date: day,
                                    reminders: reminders,
                                    isSelected: calendar.isDate(day, inSameDayAs: selectedDate),
                                    currentOption: .showMonthly
                    ) {
                        selectedDate = day
                    }
                }
            }
        }
        .onAppear {
            self.days = generateDaysInMonth(for: Date())
        }
    }
    
    func generateDaysInMonth(for date: Date) -> [Date] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let lastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end - 1)
        else { return [] }
        
        let dates = stride(from: firstWeek.start, through: lastWeek.end, by: 60 * 60 * 24).map { $0 }
        return dates
    }
}


struct CalendarWeekView: View {
    @State private var selectedDate: Date = Date()
    private let calendar = Calendar.current
    private let currentWeek: [Date]
    
    let eventsByDay: [Date: [EKReminder]]
    
    init(eventsByDay: [Date: [EKReminder]] = [:]) {
        self.currentWeek = Self.generateCurrentWeek()
        self.eventsByDay = eventsByDay
    }

    var body: some View {
        VStack(spacing: 4) {
            // Weekday headers
            HStack {
                ForEach(currentWeek, id: \.self) { date in
                    let weekday = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: date) - 1]
                    Text(weekday)
                        .font(.caption2)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.secondary)
                }
            }

            // Days of week
            HStack(spacing: 8) {
                ForEach(currentWeek, id: \.self) { date in
                    let reminders = eventsByDay[calendar.startOfDay(for: date)] ?? []

                    CalendarDayView(
                        date: date,
                        reminders: reminders,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        currentOption: .showWeekly
                    ) {
                        selectedDate = date
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal)
    }

    static func generateCurrentWeek() -> [Date] {
        let calendar = Calendar.current
        guard let startOfWeek = calendar.dateInterval(of: .weekOfMonth, for: Date())?.start else {
            return []
        }

        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)
        }
    }
}

struct CalendarDayView: View {
    let date: Date
    let reminders: [EKReminder]
    let isSelected: Bool
    let currentOption: ComfyCalendarOptions
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                switch currentOption {
                case .showMonthly:
                    Circle()
                        .fill(isSelected ? Color.blue : Color.black)
                        .frame(width: 14, height: 14)
                    Text("\(Calendar.current.component(.day, from: date))")
                        .foregroundStyle(Color.white)
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                case .showWeekly:
                    Circle()
                        .fill(isSelected ? Color.blue : Color.black)
                        .frame(width: 32, height: 32)
                    Text("\(Calendar.current.component(.day, from: date))")
                        .foregroundStyle(Color.white)
                        .font(.system(size: 15, weight: .regular, design: .monospaced))

                case .showDaily:
                    Circle()
                        .fill(isSelected ? Color.blue : Color.black)
                        .frame(width: 48, height: 48)
                    Text("\(Calendar.current.component(.day, from: date))")
                        .foregroundStyle(Color.white)
                        .font(.system(size: 24, weight: .regular, design: .monospaced))
                }
                
                if !reminders.isEmpty {
                    Circle()
                        .fill(.pink)
                        .frame(width: 3, height: 3)
                        .offset(y: 8)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
