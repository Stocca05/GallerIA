import SwiftUI

enum GalleryStyle {
    static let background = Color(red: 0.055, green: 0.067, blue: 0.063)
    static let surface = Color(red: 0.10, green: 0.12, blue: 0.11)
    static let accent = Color(red: 0.79, green: 0.93, blue: 0.63)
    static let secondary = Color(red: 0.65, green: 0.70, blue: 0.66)
}

struct PrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .foregroundStyle(GalleryStyle.background)
            .background(GalleryStyle.accent, in: RoundedRectangle(cornerRadius: 18))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

extension View {
    func galleryPanel() -> some View {
        self.padding(20)
            .background(GalleryStyle.surface, in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.07)))
    }
}
