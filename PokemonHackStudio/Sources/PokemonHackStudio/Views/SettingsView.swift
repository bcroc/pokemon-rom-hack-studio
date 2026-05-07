import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: WorkbenchStore
    @ObservedObject private var settings: WorkbenchUserSettings

    init(store: WorkbenchStore) {
        self.store = store
        _settings = ObservedObject(wrappedValue: store.userSettings)
    }

    var body: some View {
        TabView {
            generalTab
                .tabItem { Label("General", systemImage: "gearshape") }

            projectsTab
                .tabItem { Label("Projects", systemImage: "folder") }

            editorTab
                .tabItem { Label("Editor", systemImage: "paintbrush.pointed") }

            healthTab
                .tabItem { Label("Health", systemImage: "checklist") }

            resourcesTab
                .tabItem { Label("Resources", systemImage: "externaldrive.connected.to.line.below") }

            advancedTab
                .tabItem { Label("Advanced", systemImage: "slider.horizontal.3") }
        }
        .frame(minWidth: 520, idealWidth: 620, minHeight: 420, idealHeight: 520)
        .scenePadding()
    }

    private var generalTab: some View {
        Form {
            Section("Startup") {
                Toggle("Load projects at launch", isOn: $settings.autoLoadProjects)
                Toggle("Show source inspector by default", isOn: $settings.showSourceInspectorByDefault)
            }

            Section("Workbench") {
                Picker("Map zoom", selection: $settings.mapZoomDefault) {
                    ForEach(WorkbenchMapZoomDefault.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }

                Toggle("Prefer compact map controls", isOn: $settings.preferCompactMapControls)
            }
        }
        .formStyle(.grouped)
    }

    private var projectsTab: some View {
        Form {
            Section("Project Discovery") {
                Toggle("Include repo-local debug projects", isOn: $settings.includeDefaultDebugProjects)
                Toggle("Include recent projects on refresh", isOn: $settings.includeRecentProjectsInRefresh)
                Toggle("Remember opened projects", isOn: $settings.rememberRecentProjects)
                Stepper(value: $settings.maxRecentProjects, in: 1...20) {
                    Text("Recent project limit: \(settings.maxRecentProjects)")
                }
            }

            Section("Recent Projects") {
                if store.recentProjectRoots.isEmpty {
                    Text("No recent projects")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.recentProjectRoots, id: \.self) { path in
                    Text(path)
                        .font(.system(.caption, design: .monospaced))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    }
                }

                Button("Clear Recent Projects", systemImage: "clock.badge.xmark") {
                    store.clearRecentProjects()
                }
                .disabled(store.recentProjectRoots.isEmpty)
            }
        }
        .formStyle(.grouped)
    }

    private var editorTab: some View {
        Form {
            Section("Map Editor") {
                Picker("Startup tool", selection: $settings.editorStartupTool) {
                    ForEach(WorkbenchEditorStartupTool.allCases) { tool in
                        Text(tool.title).tag(tool)
                    }
                }

                Toggle("Show grid overlay", isOn: $settings.showGridByDefault)
                Toggle("Show collision overlay", isOn: $settings.showCollisionByDefault)
            }

            Section("Mutation Plans") {
                Toggle("Keep source locations visible", isOn: $settings.showSourceInspectorByDefault)
                Toggle("Use compact controls when space is tight", isOn: $settings.preferCompactMapControls)
            }
        }
        .formStyle(.grouped)
    }

    private var healthTab: some View {
        Form {
            Section("Categories") {
                ForEach(WorkbenchHealthCheckCategory.allCases) { category in
                    Toggle(
                        category.title,
                        systemImage: category.systemImage,
                        isOn: healthCategoryBinding(category)
                    )
                }
            }

            Section("Noise") {
                Picker("Rows", selection: $settings.healthNoiseLevel) {
                    ForEach(WorkbenchHealthNoiseLevel.allCases) { level in
                        Text(level.title).tag(level)
                    }
                }
                Toggle("Show not applicable rows", isOn: $settings.showNotApplicableHealthRows)
                Toggle("Include health findings in Diagnostics", isOn: $settings.includeHealthDiagnosticsInGlobalIssues)
                Toggle("Auto-refresh health on project refresh", isOn: $settings.autoRefreshHealthOnProjectRefresh)
            }

            Section("Actions") {
                Button("Refresh Health Checks", systemImage: "arrow.triangle.2.circlepath") {
                    store.refreshHealthChecks()
                }
                .disabled(!store.hasIndexedProjects)
            }
        }
        .formStyle(.grouped)
    }

    private var resourcesTab: some View {
        Form {
            Section("Indexing") {
                Toggle("Refresh resource library after opening a project", isOn: $settings.resourceAutoRefreshOnOpen)
                Toggle("Include reference roots", isOn: $settings.includeReferenceRootsInResources)
                Toggle("Search nested resource items", isOn: $settings.resourceSearchMatchesNestedItems)
                Toggle("Load asset catalog automatically", isOn: $settings.autoLoadAssetCatalog)
            }

            Section("Actions") {
                Button("Refresh Resource Library", systemImage: "externaldrive.badge.arrowtriangle.2.circlepath") {
                    store.refreshResourceLibrary()
                }

                Button("Load Asset Catalog", systemImage: "square.grid.3x3") {
                    store.loadSelectedAssetCatalogIfNeeded(force: true)
                }
                .disabled(store.selectedIndexedProject == nil)
            }
        }
        .formStyle(.grouped)
    }

    private var advancedTab: some View {
        Form {
            Section("Settings") {
                Button("Copy Settings Snapshot", systemImage: "doc.on.doc") {
                    store.exportSettingsSnapshotToPasteboard()
                }

                Button("Reset Settings", systemImage: "arrow.counterclockwise") {
                    settings.resetDefaults()
                }
            }

            Section("Project State") {
                Button("Reveal Selected Project", systemImage: "folder") {
                    store.revealSelectedProjectInFinder()
                }
                .disabled(store.selectedIndexedProject == nil)

                Button("Clear Recent Projects", systemImage: "clock.badge.xmark") {
                    store.clearRecentProjects()
                }
                .disabled(store.recentProjectRoots.isEmpty)
            }
        }
        .formStyle(.grouped)
    }

    private func healthCategoryBinding(_ category: WorkbenchHealthCheckCategory) -> Binding<Bool> {
        Binding {
            settings.isHealthCategoryEnabled(category)
        } set: { isEnabled in
            settings.setHealthCategory(category, isEnabled: isEnabled)
        }
    }
}
