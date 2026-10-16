import SwiftUI
import UIKit

/// A separate scene window covers presented sheets as well as the main screen and app snapshots.
struct PrivacyShield: UIViewRepresentable {
    let enabled: Bool
    let phase: ScenePhase
    @ObservedObject var authManager: AuthManager

    func makeCoordinator() -> Coordinator { Coordinator() }
    func makeUIView(context: Context) -> ShieldAnchorView {
        let view = ShieldAnchorView()
        let coordinator = context.coordinator
        coordinator.anchor = view
        view.onWindowChange = { [weak coordinator] in coordinator?.render() }
        return view
    }
    func updateUIView(_ uiView: ShieldAnchorView, context: Context) {
        context.coordinator.enabled = enabled
        context.coordinator.phase = phase
        context.coordinator.authManager = authManager
        context.coordinator.render()
    }
    static func dismantleUIView(_ uiView: ShieldAnchorView, coordinator: Coordinator) {
        coordinator.shield?.isHidden = true
        coordinator.shield = nil
    }

    @MainActor final class Coordinator {
        weak var anchor: ShieldAnchorView?
        var shield: UIWindow?
        var displayedActive: Bool?
        var enabled = false
        var phase = ScenePhase.active
        var authManager: AuthManager?
        func render() {
            guard let authManager, enabled, phase != .active || !authManager.isAuthenticated,
                  let scene = anchor?.window?.windowScene else {
                shield?.isHidden = true
                shield = nil
                displayedActive = nil
                return
            }
            if shield == nil {
                let window = UIWindow(windowScene: scene)
                window.windowLevel = .alert + 1
                shield = window
            }
            let active = phase == .active
            if displayedActive != active {
                shield?.rootViewController = UIHostingController(rootView: PrivacyGate(active: active)
                    .environmentObject(authManager))
                displayedActive = active
            }
            shield?.isHidden = false
        }
    }
}

final class ShieldAnchorView: UIView {
    var onWindowChange: (() -> Void)?
    override func didMoveToWindow() { super.didMoveToWindow(); onWindowChange?() }
}

private struct PrivacyGate: View {
    let active: Bool
    var body: some View {
        if active { LockView() }
        else {
            ZStack {
                GalleryStyle.background.ignoresSafeArea()
                Label("GallerIA", systemImage: "lock.shield").font(.title).foregroundStyle(GalleryStyle.accent)
            }
        }
    }
}
