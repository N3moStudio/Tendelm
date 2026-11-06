import SwiftUI
import SwiftData
import TendelmCore

struct RecentlyDeletedView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dynamicTypeSize) private var typeSize
    @Query(sort: \RecentlyDeletedRecord.deletedAt, order: .reverse) private var records: [RecentlyDeletedRecord]
    @State private var selecting = false
    @State private var selected: Set<UUID> = []
    @State private var deletion: Deletion?
    @State private var error: String?

    private struct Deletion: Identifiable {
        let id = UUID()
        let ids: Set<UUID>
        let names: String
    }
    private var visible: [RecentlyDeletedRecord] { records.filter { $0.expiresAt > .now } }

    var body: some View {
        List {
            Section {
                if visible.isEmpty {
                    ContentUnavailableView("Nothing recently deleted", systemImage: "trash")
                        .accessibilityIdentifier("trash.empty")
                }
                ForEach(visible) { item in
                    if selecting {
                        Button { toggle(item.id) } label: {
                            HStack(spacing: 12) {
                                Image(systemName: selected.contains(item.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(Color.kadoAccent).accessibilityHidden(true)
                                label(item)
                            }.frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityValue(selected.contains(item.id) ? "Selected" : "Not selected")
                        .accessibilityAddTraits(selected.contains(item.id) ? .isSelected : [])
                        .accessibilityIdentifier("trash.select.\(item.id)")
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            label(item)
                            HStack {
                                Button("Restore") { restore([item.id]) }
                                    .accessibilityIdentifier("trash.restore.\(item.id)")
                                Spacer(minLength: 12)
                                Button("Delete permanently", role: .destructive) { review([item.id]) }
                                    .accessibilityIdentifier("trash.delete.\(item.id)")
                            }.buttonStyle(.borderless).frame(minHeight: 44)
                        }
                    }
                }
            } footer: { Text("Kept for 30 days. Restoring brings back the item and its history.") }
            .listRowBackground(Color.kadoBackgroundSecondary)
        }
        .scrollContentBackground(.hidden)
        .background(Color.kadoBackground)
        .navigationTitle("Recently Deleted")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(selecting ? "Done" : "Select") { selecting.toggle(); selected.removeAll() }
                    .disabled(!selecting && visible.isEmpty)
                    .accessibilityIdentifier("trash.select")
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if selecting && !visible.isEmpty {
                let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 8)) : AnyLayout(HStackLayout(spacing: 16))
                layout {
                    Button(selected.count == visible.count ? "Deselect All" : "Select All") {
                        selected = selected.count == visible.count ? [] : Set(visible.map(\.id))
                    }.accessibilityIdentifier("trash.selectAll")
                    if !typeSize.isAccessibilitySize { Spacer(minLength: 0) }
                    if !selected.isEmpty {
                        Button("Restore") { restore(selected) }.accessibilityIdentifier("trash.restoreSelected")
                    }
                    Button(selected.isEmpty ? "Delete All" : "Delete (\(selected.count))", role: .destructive) {
                        review(selected.isEmpty ? Set(visible.map(\.id)) : selected)
                    }.accessibilityIdentifier("trash.deleteSelected")
                }
                .font(.subheadline.weight(.semibold))
                .buttonStyle(.borderless)
                .frame(minHeight: 44)
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(Color.kadoBackgroundSecondary)
            }
        }
        .onAppear(perform: prune)
        .onChange(of: records.map(\.id)) { _, ids in selected.formIntersection(ids) }
        .confirmationDialog("Permanently delete \(deletion?.ids.count ?? 0) \(deletion?.ids.count == 1 ? "item" : "items")?",
               isPresented: Binding(get: { deletion != nil }, set: { if !$0 { deletion = nil } }), titleVisibility: .visible, presenting: deletion) { plan in
            Button("Cancel", role: .cancel) { deletion = nil }
            Button("Delete permanently", role: .destructive) {
                do { try RecentlyDeletedStore().permanentlyDelete(ids: plan.ids, in: context); selected.subtract(plan.ids) }
                catch { self.error = error.localizedDescription }
                deletion = nil
            }.accessibilityIdentifier("trash.confirmDelete")
        } message: { plan in Text("\(plan.names). This cannot be undone. Items outside Recently Deleted stay as they are.") }
        .alert("Couldn't update Recently Deleted", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(error ?? "") }
    }

    private func label(_ item: RecentlyDeletedRecord) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.name).font(.headline).foregroundStyle(Color.kadoForeground)
                .fixedSize(horizontal: false, vertical: true)
            Text("\(item.kind) · Expires \(item.expiresAt.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption).foregroundStyle(Color.kadoForegroundSecondary)
        }.accessibilityElement(children: .combine)
            .accessibilityIdentifier("trash.item.\(item.id)")
    }
    private func toggle(_ id: UUID) { if !selected.insert(id).inserted { selected.remove(id) } }
    private func review(_ ids: Set<UUID>) {
        let items = visible.filter { ids.contains($0.id) }
        let names = items.prefix(3).map(\.name).joined(separator: ", ") + (items.count > 3 ? " and \(items.count - 3) more" : "")
        deletion = Deletion(ids: Set(items.map(\.id)), names: names)
    }
    private func restore(_ ids: Set<UUID>) {
        do {
            try RecentlyDeletedStore().restore(ids: ids, in: context)
            selected.subtract(ids)
            WidgetReloader.reloadAll(using: context)
        } catch { self.error = error.localizedDescription }
    }
    private func prune() {
        do { try RecentlyDeletedStore().prune(in: context) }
        catch { self.error = error.localizedDescription }
    }
}
