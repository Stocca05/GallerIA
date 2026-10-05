import UIKit
import PDFKit

class PDFReportGenerator {
    static let shared = PDFReportGenerator()

    private init() {}

    func generateAestheticReport(iterations: Int, totalSamples: Int, score: Double) -> URL? {
        let pdfMetaData = [
            kCGPDFContextCreator: "GallerIA AI",
            kCGPDFContextAuthor: "GallerIA Pro",
            kCGPDFContextTitle: "Report Estetico Neurale"
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            context.beginPage()

            // Background
            UIColor.black.set()
            context.fill(pageRect)

            // Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 36, weight: .bold),
                .foregroundColor: UIColor.cyan
            ]
            let titleString = "GallerIA - Report Neurale"
            titleString.draw(at: CGPoint(x: 40, y: 40), withAttributes: titleAttributes)

            // Subtitle
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .regular),
                .foregroundColor: UIColor.lightGray
            ]
            let subtitleString = "Estratto ufficiale dei parametri di intelligenza artificiale."
            subtitleString.draw(at: CGPoint(x: 40, y: 90), withAttributes: subtitleAttributes)

            // Draw a separator
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 40, y: 130))
            path.addLine(to: CGPoint(x: pageWidth - 40, y: 130))
            UIColor.cyan.withAlphaComponent(0.5).setStroke()
            path.lineWidth = 2
            path.stroke()

            // Body
            let bodyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 22, weight: .medium),
                .foregroundColor: UIColor.white
            ]

            let stats = """
            Statistiche di Addestramento:

            • Campioni Analizzati: \(totalSamples) foto
            • Iterazioni Completate: \(iterations) epochs
            • Affinità Estetica Media: \(Int(score * 100))%
            """

            let textRect = CGRect(x: 40, y: 160, width: pageWidth - 80, height: 400)
            stats.draw(in: textRect, withAttributes: bodyAttributes)

            // Footer stamp
            let stampAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 14, weight: .bold),
                .foregroundColor: UIColor.purple
            ]
            let stampString = "CERTIFICATO DALL'IA ON-DEVICE - \(Date().formatted())"
            stampString.draw(at: CGPoint(x: 40, y: pageHeight - 60), withAttributes: stampAttributes)
        }

        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("GallerIAReport.pdf")
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Could not create PDF file: \(error)")
            return nil
        }
    }
}
