//
//  DSKPageView.swift
//  Suwatte (iOS)
//
//  Created by Mantton on 2023-07-12.
//

import RealmSwift
import SwiftUI

struct DSKPageView<C: View>: View {
    @StateObject var model: ViewModel
    typealias PageItemModifier = (DSKCommon.Highlight) -> C
    let modifier: PageItemModifier

    init(model: ViewModel, @ViewBuilder _ modifier: @escaping PageItemModifier) {
        _model = StateObject(wrappedValue: model)
        self.modifier = modifier
    }

    var body: some View {
        LoadableView(model.load, $model.loadable) { sections in
            CollectionView(sections: sections, runner: model.runner, modifier)
        }
        .environmentObject(model)
    }
}

extension DSKPageView {
    final class ViewModel: ObservableObject {
        let runner: AnyRunner
        let link: DSKCommon.PageLink
        @Published var loadable = Loadable<[DSKCommon.PageSection]>.idle
        @Published var loadables: [String: Loadable<DSKCommon.ResolvedPageSection>] = [:]
        @Published var errors = Set<String>()

        init(runner: AnyRunner, link: DSKCommon.PageLink) {
            self.runner = runner
            self.link = link
        }

        func load() async throws {
            await MainActor.run {
                loadable = .loading
            }
            let data: [DSKCommon.PageSection] = try await runner.getSectionsForPage(link: link) // Load Page
            if !data.allSatisfy({ $0.items != nil }) {
                try await runner.willResolveSectionsForPage(link: link) // Tell Runner that suwatte will begin resolution of page sections
            }
            await MainActor.run {
                withAnimation {
                    loadable = .loaded(data)
                }
            }
        }

        func load(_ sectionID: String) async {
            await MainActor.run {
                loadables[sectionID] = .loading
                errors.remove(sectionID)
            }
            do {
                let data: DSKCommon.ResolvedPageSection = try await runner.resolvePageSection(link: link, section: sectionID)
                await MainActor.run{
                    if data.items.isEmpty {
                        loadables.removeValue(forKey: sectionID)
                    } else {
                        loadables[sectionID] = .loaded(data)
                    }
                }

            } catch {
                Logger.shared.error(error, runner.id)
                await MainActor.run {
                    loadables[sectionID] = .failed(error)
                    errors.insert(sectionID)
                }
            }
        }
    }
}

struct RunnerPageView: View {
    let runner: AnyRunner
    var link: DSKCommon.PageLink
    var body: some View {
        Group {
            if let runner = runner as? AnyContentSource {
                ContentSourcePageView(source: runner, link: link)
            } else if let runner = runner as? AnyContentTracker {
                ContentTrackerPageView(tracker: runner, link: link)
            } else {
                Text("No Environment")
            }
        }
    }
}
