import Foundation
import StoreKit

@MainActor
final class ProManager: ObservableObject {
    static let shared = ProManager()
    static let productID = "com.stocca.GallerIA.pro.lifetime"
    @Published private(set) var isPro = false
    @Published private(set) var product: Product?
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingProduct = false
    @Published var message: String?
    private var updates: Task<Void, Never>?
    private var entitlementGeneration = UUID()

    init(automaticallyLoad: Bool = true) {
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                if case .verified(let transaction) = result, transaction.productID == Self.productID {
                    await self.refreshEntitlements()
                    await transaction.finish()
                }
            }
        }
        if automaticallyLoad { Task { await refreshEntitlements(); await loadProduct() } }
    }

    deinit { updates?.cancel() }

    func loadProduct() async {
        guard !isLoadingProduct else { return }
        isLoadingProduct = true
        defer { isLoadingProduct = false }
        message = nil
        do {
            product = try await Product.products(for: [Self.productID]).first(where: { $0.type == .nonConsumable })
            if product == nil { message = "Gli acquisti non sono ancora disponibili. Riprova più tardi." }
        } catch { message = "Impossibile contattare App Store. Controlla la connessione e riprova." }
    }

    func purchasePro() {
        guard let product, !isLoading else { return }
        isLoading = true
        message = nil
        Task {
            defer { isLoading = false }
            do {
                switch try await product.purchase() {
                case .success(let result):
                    guard case .verified(let transaction) = result, transaction.productID == Self.productID, transaction.revocationDate == nil else {
                        message = "Non è stato possibile verificare l’acquisto."; return
                    }
                    await refreshEntitlements()
                    await transaction.finish()
                case .pending: message = "Acquisto in attesa di approvazione. Pro si attiverà dopo la conferma."
                case .userCancelled: break
                @unknown default: message = "Acquisto non completato. Riprova."
                }
            } catch { message = "Acquisto non completato: \(error.localizedDescription)" }
        }
    }

    func restorePurchases() {
        guard !isLoading else { return }
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                try await AppStore.sync()
                await refreshEntitlements()
                message = isPro ? "GallerIA Pro è attivo." : "Nessun acquisto Pro trovato per questo account Apple."
            } catch { message = "Ripristino non riuscito. Riprova più tardi." }
        }
    }

    func refreshEntitlements() async {
        let token = UUID()
        entitlementGeneration = token
        var entitled = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.productID,
               transaction.revocationDate == nil,
               !transaction.isUpgraded {
                entitled = true
            }
        }
        if entitlementGeneration == token { isPro = entitled }
    }
}
