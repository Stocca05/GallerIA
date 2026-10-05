import SwiftUI

struct WaterfallGrid<Data: RandomAccessCollection, ID: Hashable, Content: View>: View where Data.Element: Identifiable, Data.Element.ID == ID {
    var data: Data
    var id: KeyPath<Data.Element, ID>
    var columns: Int
    var spacing: CGFloat
    var content: (Data.Element) -> Content

    init(_ data: Data, id: KeyPath<Data.Element, ID>, columns: Int = 2, spacing: CGFloat = 8, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.id = id
        self.columns = columns
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        HStack(alignment: .top, spacing: spacing) {
            ForEach(0..<columns, id: \.self) { columnIndex in
                LazyVStack(spacing: spacing) {
                    ForEach(data.enumerated().filter { $0.offset % columns == columnIndex }.map { $0.element }, id: id) { item in
                        content(item)
                    }
                }
            }
        }
    }
}
