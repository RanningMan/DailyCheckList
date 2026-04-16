import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    @State private var sheetURLString = ""
    @State private var remindersEnabled = false
    @State private var reminderDate = Date.now

    var body: some View {
        Form {
            Section {
                TextField("Published worksheet CSV URL", text: $sheetURLString, axis: .vertical)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(AppTheme.monoFont(.caption))
                    .foregroundStyle(theme.textPrimary)

                Button {
                    model.saveSheetURL(sheetURLString)
                } label: {
                    Text("Save Source URL")
                        .font(AppTheme.monoFont(.body, weight: .semibold))
                        .foregroundStyle(theme.accent)
                }

                Button {
                    Task {
                        await model.refreshIfConfigured()
                    }
                } label: {
                    Text("Refresh Now")
                        .font(AppTheme.monoFont(.body, weight: .semibold))
                        .foregroundStyle(theme.accent)
                }
                .disabled(model.configuration.sheetURLString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } header: {
                Text("Google Sheet")
                    .font(AppTheme.monoFont(.caption, weight: .bold))
                    .foregroundStyle(theme.accent)
            }

            Section {
                ForEach(AppThemeID.allCases) { themeID in
                    Button {
                        model.setTheme(themeID)
                    } label: {
                        HStack(spacing: 12) {
                            // Color preview dots
                            HStack(spacing: 4) {
                                Circle().fill(themeID.theme.accent).frame(width: 12, height: 12)
                                Circle().fill(themeID.theme.completedAccent).frame(width: 12, height: 12)
                                Circle().fill(themeID.theme.background).frame(width: 12, height: 12)
                                    .overlay(Circle().strokeBorder(theme.dimAccent, lineWidth: 1))
                            }

                            Text(themeID.displayName)
                                .font(AppTheme.monoFont(.body))
                                .foregroundStyle(theme.textPrimary)

                            Spacer()

                            if model.configuration.themeID == themeID {
                                Image(systemName: "checkmark")
                                    .font(.body.weight(.bold))
                                    .foregroundStyle(theme.accent)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Theme")
                    .font(AppTheme.monoFont(.caption, weight: .bold))
                    .foregroundStyle(theme.accent)
            }

            Section {
                Toggle("Daily reminder", isOn: $remindersEnabled)
                    .font(AppTheme.monoFont(.body))
                    .tint(theme.completedAccent)
                    .onChange(of: remindersEnabled) { _, newValue in
                        Task {
                            await model.setRemindersEnabled(newValue)
                            remindersEnabled = model.configuration.remindersEnabled
                        }
                    }

                DatePicker("Time", selection: $reminderDate, displayedComponents: .hourAndMinute)
                    .font(AppTheme.monoFont(.body))
                    .disabled(!remindersEnabled)
                    .onChange(of: reminderDate) { _, newValue in
                        Task {
                            await model.setReminderTime(newValue)
                            reminderDate = model.reminderDate
                        }
                    }
            } header: {
                Text("Reminder")
                    .font(AppTheme.monoFont(.caption, weight: .bold))
                    .foregroundStyle(theme.accent)
            }

            Section {
                Text(model.syncStatusText)
                    .font(AppTheme.monoFont(.caption))
                    .foregroundStyle(theme.textSecondary)
            } header: {
                Text("Status")
                    .font(AppTheme.monoFont(.caption, weight: .bold))
                    .foregroundStyle(theme.accent)
            }
        }
        .scrollContentBackground(.hidden)
        .background(theme.background)
        .navigationTitle("Settings")
        .toolbarColorScheme(theme.useDarkMode ? .dark : .light, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(AppTheme.monoFont(.body, weight: .semibold))
                        .foregroundStyle(theme.accent)
                }
            }
        }
        .preferredColorScheme(theme.useDarkMode ? .dark : .light)
        .onAppear {
            sheetURLString = model.configuration.sheetURLString
            remindersEnabled = model.configuration.remindersEnabled
            reminderDate = model.reminderDate
        }
    }
}
