import SwiftUI
import PencilKit
import PDFKit

struct ContentView: View {
    var document: MyPDFDocument
    @State private var isOpen: Bool = false
    @State private var isEditing: Bool = false
    
    init(url: URL) {
        self.document = MyPDFDocument(fileURL: url)
    }
    
    var body: some View {
        VStack {
            if (isOpen) {
                Button {
                    isEditing = true
                } label: {
                    Text("Start Editing")
                }
                MyPDFViewX(document: document, isEditing: $isEditing)
            }
        }.task {
            isOpen = await self.document.open()
        }
    }
}

struct MyPDFViewX: UIViewRepresentable {
    var document: MyPDFDocument
    @Binding var isEditing: Bool
    
    func makeUIView(context: Context) -> MyPDFView {
        let pdfView = MyPDFView()
        if let document = document.document {
            pdfView.loadPDF(document: document)
        }
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: MyPDFView, context: Context) {
        pdfView.setCanvasDelegate(context.coordinator)
        pdfView.showToolPicker(isEnabled: self.isEditing)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: MyPDFViewX
        
        init(_ parent: MyPDFViewX) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            DispatchQueue.global(qos: .background).sync {
                self.parent.document.save(to: self.parent.document.fileURL, for: .forOverwriting) { success in
                    debugPrint(success)
                }
            }
        }
    }
}
