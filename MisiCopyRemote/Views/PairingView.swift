//
//  PairingView.swift
//  MisiCopyRemote
//
//  Shows the camera preview with a QR-code overlay. When a valid
//  `PairingPayload` is detected, the Mac is saved and the user lands on
//  the dashboard. On the simulator (no camera) the manual entry sheet is
//  shown directly so the rest of the flow can still be exercised.
//

import SwiftUI
#if canImport(AVFoundation)
import AVFoundation
#endif

struct PairingView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    @State private var error: String?
    @State private var showManualEntry = false

    /// Reachable from the toolbar regardless of whether the user has
    /// paired a Mac yet — covers the gap where WelcomeView's demo button
    /// is only shown to fresh installs.
    private func enterDemoMode() {
        state.session.enableDemoMode()
        dismiss()
    }

    var body: some View {
        Group {
#if targetEnvironment(simulator)
            simulatorFallback
#else
            cameraScanner
#endif
        }
        .navigationTitle("Appairer un Mac")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showManualEntry = true
                    } label: {
                        Label("Saisie manuelle", systemImage: "keyboard")
                    }
                    Button {
                        enterDemoMode()
                    } label: {
                        Label("Mode démo", systemImage: "play.rectangle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showManualEntry) {
            ManualEntrySheet { json in
                handleScannedPayload(json)
                showManualEntry = false
            }
        }
        .alert("Erreur", isPresented: .constant(error != nil), actions: {
            Button("OK") { error = nil }
        }, message: { Text(error ?? "") })
    }

    // MARK: - Real device

#if !targetEnvironment(simulator)
    private var cameraScanner: some View {
        ZStack {
            QRScannerView(onPayload: handleScannedPayload(_:),
                          onError: { error = $0 })
                .ignoresSafeArea()

            // Dimmed overlay with a cut-out viewfinder.
            GeometryReader { geo in
                let side = min(geo.size.width, geo.size.height) * 0.7
                let frame = CGRect(
                    x: (geo.size.width - side) / 2,
                    y: (geo.size.height - side) / 2 - 40,
                    width: side, height: side
                )
                ZStack {
                    Path { p in
                        p.addRect(CGRect(origin: .zero, size: geo.size))
                        p.addRoundedRect(in: frame,
                                         cornerSize: CGSize(width: 22, height: 22))
                    }
                    .fill(Color.black.opacity(0.5), style: FillStyle(eoFill: true))

                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.9), lineWidth: 3)
                        .frame(width: side, height: side)
                        .position(x: frame.midX, y: frame.midY)
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }

            VStack {
                Spacer()
                instructionCard
                    .padding()
            }
        }
    }
#endif

    // MARK: - Simulator

    private var simulatorFallback: some View {
        VStack(spacing: 20) {
            Image(systemName: "iphone.gen2.slash")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)
            Text("Caméra indisponible sur simulateur")
                .font(.headline)
            Text("Lance MisiCopy sur ton Mac, va dans Réglages → iPhone, puis colle le contenu du QR code ici. Utilise le bouton clavier en haut à droite pour ouvrir le champ de saisie.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                showManualEntry = true
            } label: {
                Label("Saisir le payload", systemImage: "keyboard")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 32)
        }
        .padding(.vertical, 40)
    }

    // MARK: - Common UI

    private var instructionCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "qrcode.viewfinder")
                .font(.largeTitle)
                .foregroundStyle(.white)
            Text("Ouvrez MisiCopy sur votre Mac")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Réglages → iPhone → activez le suivi puis scannez le QR code affiché.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.black.opacity(0.55))
        )
    }

    @MainActor
    private func handleScannedPayload(_ rawString: String) {
        guard let payload = try? PairingPayload.decode(from: rawString) else {
            error = "QR code non reconnu"
            return
        }
        state.pairedStore.add(payload)
        dismiss()
    }
}

// MARK: - Manual entry sheet

private struct ManualEntrySheet: View {
    let onSubmit: (String) -> Void
    @State private var payload: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $payload)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 140)
                } header: {
                    Text("Payload (JSON)")
                } footer: {
                    Text("Colle ici le contenu exact du QR code MisiCopy. Tu peux le récupérer depuis MisiCopy Mac → Réglages → iPhone → bouton « Copier le payload ».")
                        .font(.caption)
                }
            }
            .navigationTitle("Saisie manuelle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Appairer") { onSubmit(payload) }
                        .disabled(payload.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
