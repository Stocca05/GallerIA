import XCTest
import StoreKitTest
import StoreKit
@testable import GallerIA

final class ProEntitlementTests: XCTestCase {
    @MainActor func testVerifiedPurchaseUnlocksProAndRefundRevokesIt() async throws {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "GallerIA", withExtension: "storekit"))
        let session = try SKTestSession(contentsOf: url)
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true
        defer { session.clearTransactions() }
        let manager = ProManager(automaticallyLoad: false)
        await manager.loadProduct()
        XCTAssertEqual(manager.product?.id, ProManager.productID, manager.message ?? "Product unavailable")
        await manager.refreshEntitlements()
        XCTAssertFalse(manager.isPro)
        manager.purchasePro()
        for _ in 0..<100 {
            if !manager.isLoading { break }
            try await Task.sleep(for: .milliseconds(50))
        }
        XCTAssertFalse(manager.isLoading)
        XCTAssertNil(manager.message)
        for await result in Transaction.currentEntitlements {
            if case .unverified(_, let error) = result { XCTFail("Local StoreKit verification failed: \(error)") }
        }
        await manager.refreshEntitlements()
        XCTAssertTrue(manager.isPro)
        let purchase = try XCTUnwrap(session.allTransactions().first)
        try session.refundTransaction(identifier: purchase.identifier)
        for _ in 0..<100 {
            await manager.refreshEntitlements()
            if !manager.isPro { break }
            try await Task.sleep(for: .milliseconds(50))
        }
        XCTAssertFalse(manager.isPro)
    }
}
