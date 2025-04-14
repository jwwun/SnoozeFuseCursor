import SwiftUI

// View for managing notification sounds
struct ManageCAFSoundsView: View {
    @ObservedObject var cafManager = CustomCAFManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Notification Sounds") {
                    if !cafManager.cafSounds.isEmpty {
                        // Built-in sounds section
                        ForEach(cafManager.cafSounds.filter { $0.isBuiltIn }) { sound in
                            HStack {
                                Image(systemName: "speaker.wave.2.fill")
                                    .foregroundColor(.blue.opacity(0.7))
                                Text(sound.name)
                                    .foregroundColor(.primary)
                                
                                if cafManager.selectedCAFSoundID == sound.id {
                                    Spacer()
                                    Text("Selected")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        
                        // Custom sounds section (only show if there are custom sounds)
                        if cafManager.cafSounds.contains(where: { !$0.isBuiltIn }) {
                            Section("Detected .caf Sounds") {
                                ForEach(cafManager.cafSounds.filter { !$0.isBuiltIn }) { sound in
                                    HStack {
                                        Image(systemName: "music.note")
                                            .foregroundColor(.green.opacity(0.7))
                                        Text(sound.name)
                                            .foregroundColor(.primary)
                                        
                                        if cafManager.selectedCAFSoundID == sound.id {
                                            Spacer()
                                            Text("Selected")
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                                .onDelete(perform: deleteItems)
                            }
                        }
                    } else {
                        Text("No custom sounds added yet.")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About Notification Sounds")
                            .font(.headline)
                        
                        Text("iOS requires notification sounds to be in .caf (Core Audio Format) format. The built-in sounds are already in this format.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("You can convert audio files to .caf format using various online converters or audio tools like ffmpeg.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Manage Notification Sounds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        // Get only the custom sounds (non-built-in)
        let customSounds = cafManager.cafSounds.filter { !$0.isBuiltIn }
        
        // Map the offsets to the actual IDs of the custom sounds
        let idsToDelete = offsets.map { customSounds[$0].id }
        
        // Delete each sound
        for id in idsToDelete {
            cafManager.removeCAFSound(id: id)
        }
    }
} 
