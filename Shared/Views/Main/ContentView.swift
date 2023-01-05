//
//  ContentView.swift
//  Shared
//
//  Created by Mantton on 2022-02-28.
//

import SwiftUI

struct ContentView: View {
    @State var tabs = AppTabs.defaultSettings
    @AppStorage(STTKeys.IntialTabIndex) var InitialSelection = 3
    @State var selection = 0
    @StateObject var toaster = ToastManager.shared
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        MainContent
            .navigationViewStyle(.stack)
            .onChange(of: scenePhase) { phase in
                switch phase {
                    case .background:
                        STTScheduler.shared.scheduleAll()
                    default: break
                }
            }
            .environmentObject(toaster)
            .environmentObject(DaisukeEngine.shared)
        
    }
    
    var MainContent: some View {
        TabView(selection: $selection) {
            ForEach(Array(zip(tabs.indices, tabs)), id: \.0) { index, tab in
                tab.view()
                    .tag(index)
                    .tabItem {
                        Image(systemName: "\(tab.systemImage())\(selection == index ? ".fill" : "")")
                        // SwiftUI AHIG Override: https://stackoverflow.com/a/70058260
                            .environment(\.symbolVariants, .none)
                    }
                    .toast()
//                    .sttContentBlur() // TODO: Fix
            }
        }
    }
    
    
}


struct STTContentBlur : ViewModifier {
    @AppStorage(STTKeys.BlurWhenAppSwiching) var blurDuringSwitch = false
    @Environment(\.scenePhase) private var scenePhase
    
    func body(content: Content) -> some View {
        Group {
            if ShouldBlur {
                Image("stt_icon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(.all)
                    .transition(.opacity)
            } else {
                content
                    .transition(.opacity)
            }
        }
        .animation(.default, value: scenePhase)
        .animation(.default, value: ShouldBlur)
        
    }
    
    var ShouldBlur: Bool {
        blurDuringSwitch && scenePhase != .active
    }
    var ContentBlur : Double {
        ShouldBlur ? 10 : 0
    }
}

extension View {
    func sttContentBlur() -> some View {
        modifier(STTContentBlur())
    }
}
