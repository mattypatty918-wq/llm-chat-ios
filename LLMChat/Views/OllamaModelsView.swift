import SwiftUI

// MARK: - Ollama Models View

struct OllamaModelsView: View {
    @StateObject private var svc: OllamaService
    @State private var showDeleteConfirm: OllamaInstalledModel? = nil
    @State private var searchText = ""
    @State private var selectedTag = "All"

    private let tags = ["All", "general", "fast", "reasoning", "coding", "agents", "large", "small"]

    init(settings: AppSettings) {
        _svc = StateObject(wrappedValue: OllamaService(settings: settings))
    }

    var body: some View {
        NavigationStack {
            List {
                // Status banner
                statusSection

                // Installed models
                if !svc.installedModels.isEmpty {
                    installedSection
                }

                // Active pulls
                if !svc.pullProgresses.isEmpty {
                    pullProgressSection
                }

                // Recommended models to pull
                recommendedSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Local Models")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search models…")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { Task { await svc.refreshModels() } } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(svc.isLoading)
                }
            }
            .confirmationDialog(
                "Delete \(showDeleteConfirm?.name ?? "")?",
                isPresented: Binding(
                    get: { showDeleteConfirm != nil },
                    set: { if !$0 { showDeleteConfirm = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let model = showDeleteConfirm {
                        Task {
                            try? await svc.delete(name: model.name)
                            showDeleteConfirm = nil
                        }
                    }
                }
                Button("Cancel", role: .cancel) { showDeleteConfirm = nil }
            } message: {
                Text("This will remove the model and free up \(showDeleteConfirm?.sizeDisplay ?? "") of disk space.")
            }
        }
        .task { await svc.refreshModels() }
    }

    // MARK: Status

    @ViewBuilder
    private var statusSection: some View {
        Section {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(svc.isOnline ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: svc.isOnline ? "server.rack" : "exclamationmark.triangle")
                        .foregroundStyle(svc.isOnline ? .green : .red)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(svc.isOnline ? "Ollama Online" : "Ollama Offline")
                        .font(.body.weight(.medium))
                    Text(svc.isOnline
                        ? "\(svc.installedModels.count) model\(svc.installedModels.count == 1 ? "" : "s") installed"
                        : "Check gateway URL in Settings")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if svc.isLoading { ProgressView().scaleEffect(0.8) }
            }
            .padding(.vertical, 4)

            if !svc.runningModels.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                    Text("In memory: \(svc.runningModels.map(\.name).joined(separator: ", "))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Ollama Server")
        }
    }

    // MARK: Installed

    @ViewBuilder
    private var installedSection: some View {
        Section("Installed (\(svc.installedModels.count))") {
            ForEach(svc.installedModels) { model in
                installedRow(model)
            }
        }
    }

    @ViewBuilder
    private func installedRow(_ model: OllamaInstalledModel) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(width: 36, height: 36)
                Image(systemName: "cpu")
                    .font(.system(size: 14))
                    .foregroundStyle(svc.isRunning(model.name) ? .green : .secondary)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(model.name)
                        .font(.body)
                    if svc.isRunning(model.name) {
                        Text("ACTIVE")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.green)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                Text(model.sizeDisplay)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                showDeleteConfirm = model
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
    }

    // MARK: Pull progress

    @ViewBuilder
    private var pullProgressSection: some View {
        Section("Downloading") {
            ForEach(Array(svc.pullProgresses.keys.sorted()), id: \.self) { name in
                if let prog = svc.pullProgresses[name] {
                    pullProgressRow(name: name, progress: prog)
                }
            }
        }
    }

    @ViewBuilder
    private func pullProgressRow(name: String, progress: OllamaPullProgress) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name)
                    .font(.body.weight(.medium))
                Spacer()
                if progress.status == "Done" {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else if progress.status.hasPrefix("Error") {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                } else {
                    ProgressView().scaleEffect(0.8)
                }
            }
            Text(progress.status)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            if progress.isDownloading, progress.fraction > 0 {
                ProgressView(value: progress.fraction)
                    .tint(.blue)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: Recommended

    @ViewBuilder
    private var recommendedSection: some View {
        // Tag filter strip
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        Button {
                            selectedTag = tag
                        } label: {
                            Text(tag.capitalized)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedTag == tag ? Color.blue : Color(.systemGray5))
                                .foregroundStyle(selectedTag == tag ? .white : .primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        } header: {
            Text("Available to Pull")
        }

        let filtered = RecommendedModel.all.filter { rec in
            let matchTag    = selectedTag == "All" || rec.tags.contains(selectedTag)
            let matchSearch = searchText.isEmpty ||
                rec.displayName.localizedCaseInsensitiveContains(searchText) ||
                rec.description.localizedCaseInsensitiveContains(searchText)
            return matchTag && matchSearch
        }

        Section {
            ForEach(filtered) { rec in
                recommendedRow(rec)
            }
        }
    }

    @ViewBuilder
    private func recommendedRow(_ rec: RecommendedModel) -> some View {
        let installed = svc.isInstalled(rec.id)
        let pulling   = svc.pullProgress(for: rec.id) != nil && svc.pullProgresses[rec.id]?.status != "Done"

        HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(installed ? Color.green.opacity(0.12) : Color(.systemGray5))
                    .frame(width: 44, height: 44)
                Image(systemName: installed ? "checkmark.circle.fill" : "arrow.down.circle")
                    .font(.system(size: 20))
                    .foregroundStyle(installed ? .green : .blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(rec.displayName)
                        .font(.body.weight(.medium))
                    ForEach(rec.tags.prefix(2), id: \.self) { tag in
                        tagBadge(tag)
                    }
                }
                Text(rec.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                HStack(spacing: 12) {
                    Label(rec.sizeEstimate, systemImage: "arrow.down")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Label("\(rec.ramRequired) RAM", systemImage: "memorychip")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            if installed {
                Text("Installed")
                    .font(.caption2)
                    .foregroundStyle(.green)
            } else if pulling {
                ProgressView().scaleEffect(0.7)
            } else {
                Button {
                    svc.pull(name: rec.id)
                } label: {
                    Text("Pull")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func tagBadge(_ tag: String) -> some View {
        let (color, emoji): (Color, String) = {
            switch tag {
            case "reasoning": return (.purple, "🧠")
            case "coding":    return (.orange, "💻")
            case "fast":      return (.green,  "⚡️")
            case "agents":    return (.blue,   "🤖")
            case "large":     return (.red,    "🏋️")
            default:          return (.gray,   "")
            }
        }()
        Text(emoji.isEmpty ? tag : emoji)
            .font(.system(size: 11))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
