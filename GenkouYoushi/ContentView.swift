import SwiftUI
import PDFKit

struct ContentView: View {
    @Binding var document: GenkouYoushiDocument
    @State private var isEditing: Bool = false

    var body: some View {
        VStack {
            Button {
                isEditing = true
            } label: {
                Text("Show Toolpicker")
            }
            MyPDFViewX(data: $document.pdfData, isEditing: $isEditing)
        }
    }
}

struct MyPDFViewX: UIViewRepresentable {
    @Binding var data: Data
    @Binding var isEditing: Bool

    func makeUIView(context: Context) -> MyPDFView {
        let document = PDFDocument(data: self.data)!

        let pdfView = MyPDFView()
        pdfView.loadPDF(document)

        return pdfView
    }

    func updateUIView(_ pdfView: MyPDFView, context: Context) {
        pdfView.showToolPicker(isEnabled: isEditing)
    }
}

#Preview {
    ContentView(document: .constant(GenkouYoushiDocument()))
}
