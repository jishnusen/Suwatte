//
//  SettingsView.swift
//  Suwatte (iOS)
//
//  Created by Mantton on 2023-01-04.
//

import SwiftUI
import RealmSwift

struct SettingsView: View {
    var body: some View {
        Form {
            MiscSection()
            LibrarySection()
            UpdatesSection()
            PrivacySection()
            NetworkSection()
        }
        .navigationBarTitle("Settings")
    }
}



// MARK: Misc
extension SettingsView {
    
    struct MiscSection: View {
        private let options = AppTabs.defaultSettings
        @AppStorage(STTKeys.IntialTabIndex) var InitialSelection = 3
        @AppStorage(STTKeys.OpenAllTitlesOnAppear) var openAllOnAppear = false
        var body: some View {
            Section {
                // Initial Opening Tab
                OpeningTab
                Toggle("Open Default Collection", isOn: $openAllOnAppear)

            } header: {
                Text("Tab")
            }
            .buttonStyle(.plain)
            
        }
        
        var OpeningTab: some View {
            NavigationLink {
                List {
                    ForEach(Array(zip(options.indices, options)), id: \.0) { index, option in
                        SelectionLabel(label: option.label(), isSelected: index == InitialSelection, action: { InitialSelection = index })
                    }
                }
                .buttonStyle(.plain)
                .navigationTitle("Opening Tab")
            } label: {
                STTLabelView(title: "Opening Tab", label: options[InitialSelection].label())
            }
        }
    }
}


extension SettingsView {
    
    struct UpdatesSection: View {
        @AppStorage(STTKeys.UpdateInterval) var updateInterval: STTUpdateInterval = .oneHour
        @AppStorage(STTKeys.CheckLinkedOnUpdateCheck) var checkLinkedOnUpdate = false
        @AppStorage(STTKeys.UpdateContentData) var updateContent = false
        @AppStorage(STTKeys.UpdateSkipConditions) var skipConditions: [Int] = SkipCondition.allCases.map(\.rawValue)
        var body: some View {
            Section {
                // Update Interval
                Picker("Minimum Update Interval", selection: $updateInterval) {
                    ForEach(STTUpdateInterval.allCases, id: \.rawValue) {
                        Text($0.label)
                            .tag($0)
                    }
                }
                NavigationLink("Skip Conditions") {
                    MultiSelectionView(options: SkipCondition.allCases, selection: .init(get: {
                        return Set(skipConditions.compactMap({ SkipCondition(rawValue: $0) }))
                                   }, set: { value in
                            skipConditions = value.map(\.rawValue)
                        })) { condition in
                        Text(condition.description)
                    }
                    .buttonStyle(.plain)
                    .navigationTitle("Skip Conditions")
                }
                
                
                
            } header: {
                Text("Updates")
            }
            
            Section {
                // Check Linked
                Toggle("Check Linked Titles", isOn: $checkLinkedOnUpdate)
                Toggle("Update Title Information", isOn: $updateContent)
            } header : {
                Text("Updates")
            }
            
        }
    }
}


extension SettingsView {
    struct PrivacySection: View {
        @AppStorage(STTKeys.BlurWhenAppSwiching) var blurDuringSwitch = false
        var body: some View {
            Section {
                Toggle("Blur During App Switch", isOn: $blurDuringSwitch)
                LibraryAuthenticationToggleView()
            } header: {
                Text("Privacy")
            }
        }
    }
}

extension SettingsView {
    struct NetworkSection: View {
        @Preference(\.userAgent) var userAgent
        var body: some View {
            Section {
                HStack {
                    Text("User Agent:")
                        .foregroundColor(.gray)
                    TextField("", text: $userAgent)
                }
                Button("Clear Cookies", role: .destructive) {
                    HTTPCookieStorage.shared.removeCookies(since: .distantPast)
                }
                
            } header: {
                Text("Networking")
            }
        }

    }
}


extension SettingsView {
    struct RunnersSection: View {
        @AppStorage(STTKeys.HideNSFWRunners) var hideNSFWRunners = false

        var body: some View {
            Section {
                Toggle("Hide NSFW Sources", isOn: $hideNSFWRunners)
            } header: {
                Text("Runners")
            }
        }
    }
}

enum SkipCondition:  Int, CaseIterable, Identifiable {
    case INVALID_FLAG, NO_MARKERS, HAS_UNREAD
    
    var description: String {
        switch self {
            case .HAS_UNREAD: return "Has Unread Chapters"
            case .INVALID_FLAG: return "Flag Not Set to 'Reading'"
            case .NO_MARKERS: return "Not Started"
        }
    }
    
    var id: Int {
        rawValue
    }
}


extension SettingsView {
    
    struct LibrarySection : View {
        @AppStorage(STTKeys.AlwaysAskForLibraryConfig) private var alwaysAsk = true
        @ObservedResults(LibraryCollection.self, sortDescriptor: .init(keyPath: "order", ascending: true)) private var collections
        @AppStorage(STTKeys.DefaultCollection) var defaultCollection: String = ""
        @AppStorage(STTKeys.DefaultReadingFlag) var defaultFlag = LibraryFlag.unknown
        var body: some View {
            Section {
                Toggle("Always Prompt", isOn: $alwaysAsk)
                
                if !alwaysAsk {
                    Picker("Default Collection", selection: .init($defaultCollection, deselectTo: "")) {
                        Text("None")
                            .tag("")
                        ForEach(collections) {
                            Text($0.name)
                                .tag($0._id)
                        }
                    }
                    .transition(.slide)

                }
                
                if !alwaysAsk {
                    Picker("Default Reading Flag", selection: $defaultFlag) {
                        ForEach(LibraryFlag.allCases) {
                            Text($0.description)
                                .tag($0)
                        }
                    }
                    .transition(.slide)
                }
            } header: {
                Text("Library")
            }
            .animation(.default, value: alwaysAsk)
        }
    }
}

public extension Binding where Value: Equatable {
    init(_ source: Binding<Value>, deselectTo value: Value) {
        self.init(get: { source.wrappedValue },
                  set: { source.wrappedValue = $0 == source.wrappedValue ? value : $0 }
        )
    }
}