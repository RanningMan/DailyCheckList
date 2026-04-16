import SwiftUI

struct ChecklistHomeView: View {
    @ObservedObject var model: AppModel
    @Environment(\.appTheme) private var theme
    @State private var isShowingSettings = false
    @State private var expandedDateID: String?
    @State private var burnedTaskID: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Date header
                    VStack(alignment: .leading, spacing: 6) {
                        Text(Date.now, format: .dateTime.weekday(.wide).month().day())
                            .font(AppTheme.monoFont(.title2, weight: .bold))
                            .foregroundStyle(theme.accent)
                        Text(model.syncStatusText)
                            .font(AppTheme.monoFont(.caption))
                            .foregroundStyle(theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Today's tasks
                    if model.tasks.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "flame")
                                .font(.largeTitle)
                                .foregroundStyle(theme.dimAccent)
                            Text("No Targets Today")
                                .font(AppTheme.monoFont(.headline))
                                .foregroundStyle(theme.textPrimary)
                            Text(emptyStateCopy)
                                .font(AppTheme.monoFont(.caption))
                                .foregroundStyle(theme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 32)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(model.tasks) { task in
                                Button {
                                    let wasCompleted = task.isCompleted
                                    model.toggle(task)
                                    if !wasCompleted {
                                        burnedTaskID = task.id
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                                            if burnedTaskID == task.id {
                                                burnedTaskID = nil
                                            }
                                        }
                                    }
                                } label: {
                                    taskRow(task)
                                }
                                .buttonStyle(.plain)
                                .burnEffect(isTriggered: burnedTaskID == task.id)

                                if task.id != model.tasks.last?.id {
                                    Divider()
                                        .background(theme.accent.opacity(0.15))
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .background(theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(theme.accent.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal)
                    }

                    // Past dates history
                    ForEach(model.historyEntries, id: \.dateID) { entry in
                        VStack(spacing: 0) {
                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    if expandedDateID == entry.dateID {
                                        expandedDateID = nil
                                    } else {
                                        expandedDateID = entry.dateID
                                    }
                                }
                            } label: {
                                historyHeader(entry)
                            }
                            .buttonStyle(.plain)

                            if expandedDateID == entry.dateID {
                                Divider()
                                    .background(theme.accent.opacity(0.15))

                                ForEach(entry.tasks) { task in
                                    historyTaskRow(task)

                                    if task.id != entry.tasks.last?.id {
                                        Divider()
                                            .background(theme.accent.opacity(0.1))
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .background(theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(theme.accent.opacity(0.12), lineWidth: 1)
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 20)
            }
            .background(theme.background)
            .navigationTitle("BURNLIST")
            .toolbarColorScheme(theme.useDarkMode ? .dark : .light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if model.isRefreshing {
                        ProgressView()
                            .tint(theme.accent)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(theme.accent)
                    }
                }
            }
            .refreshable {
                await model.refreshIfConfigured()
            }
            .task {
                await model.refreshIfConfigured()
            }
            .sheet(isPresented: $isShowingSettings) {
                NavigationStack {
                    SettingsView(model: model)
                        .environment(\.appTheme, theme)
                }
            }
        }
        .tint(theme.accent)
        .preferredColorScheme(theme.useDarkMode ? .dark : .light)
    }

    // MARK: - Today's Task Row

    private func taskRow(_ task: DailyTask) -> some View {
        HStack(spacing: 12) {
            Image(systemName: task.isCompleted ? "flame.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(task.isCompleted ? theme.completedAccent : theme.dimAccent)
                .shadow(color: task.isCompleted ? theme.completedAccent.opacity(0.6) : .clear, radius: 6)

            Text(task.title)
                .font(AppTheme.monoFont(.body))
                .foregroundStyle(task.isCompleted ? theme.completedAccent.opacity(0.5) : theme.textPrimary)
                .strikethrough(task.isCompleted, color: theme.completedAccent.opacity(0.4))

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    // MARK: - History Header

    private func historyHeader(_ entry: (dateID: String, tasks: [DailyTask])) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formattedDate(entry.dateID))
                    .font(AppTheme.monoFont(.subheadline, weight: .semibold))
                    .foregroundStyle(theme.accent)
                Text(summaryText(for: entry.tasks))
                    .font(AppTheme.monoFont(.caption))
                    .foregroundStyle(theme.textSecondary)
            }

            Spacer()

            completionBadge(for: entry.tasks)

            Image(systemName: expandedDateID == entry.dateID ? "chevron.up" : "chevron.down")
                .font(.caption)
                .foregroundStyle(theme.dimAccent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    // MARK: - History Task Row

    private func historyTaskRow(_ task: DailyTask) -> some View {
        HStack(spacing: 12) {
            Image(systemName: task.isCompleted ? "flame.circle.fill" : "circle")
                .font(.body)
                .foregroundStyle(task.isCompleted ? theme.completedAccent.opacity(0.7) : theme.dimAccent.opacity(0.6))
                .shadow(color: task.isCompleted ? theme.completedAccent.opacity(0.4) : .clear, radius: 4)

            Text(task.title)
                .font(AppTheme.monoFont(.caption))
                .foregroundStyle(task.isCompleted ? theme.textSecondary : theme.textPrimary.opacity(0.7))
                .strikethrough(task.isCompleted, color: theme.completedAccent.opacity(0.3))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    // MARK: - Helpers

    private var emptyStateCopy: String {
        if model.configuration.sheetURLString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Add your published Google Sheet URL in Settings to start syncing."
        }
        return "The current date row does not contain any planned task cells."
    }

    private func formattedDate(_ dateID: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        guard let date = formatter.date(from: dateID) else { return dateID }

        let display = DateFormatter()
        display.dateStyle = .medium
        display.timeStyle = .none
        return display.string(from: date)
    }

    private func summaryText(for tasks: [DailyTask]) -> String {
        let completed = tasks.filter(\.isCompleted).count
        return "\(completed)/\(tasks.count) burned"
    }

    private func completionBadge(for tasks: [DailyTask]) -> some View {
        let completed = tasks.filter(\.isCompleted).count
        let total = tasks.count
        let fraction = total > 0 ? Double(completed) / Double(total) : 0
        let badgeColor = fraction >= 1.0 ? theme.successBadge : (fraction > 0 ? theme.completedAccent : theme.dimAccent)

        return Text("\(Int(fraction * 100))%")
            .font(AppTheme.monoFont(.caption2, weight: .bold))
            .foregroundStyle(badgeColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeColor.opacity(0.15), in: Capsule())
            .shadow(color: badgeColor.opacity(0.3), radius: 4)
    }
}
