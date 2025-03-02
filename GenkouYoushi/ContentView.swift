// Thanks to Claude and Deepseek

import SwiftUI
import PDFKit
import PencilKit

struct ContentView: View {
    @Binding var document: GenkouYoushiDocument
    
    var body: some View {
        ZStack {
            MyPDFViewX(data: $document.pdfData)
            MyPKCanvasView()
        }
    }
}

struct MyPDFViewX: UIViewRepresentable {
    @Binding var data: Data
    
    func makeUIView(context: Context) -> MyPDFView {
        let document = PDFDocument(data: self.data)!

        let pdfView = MyPDFView()
        pdfView.loadPDF(document)

        return pdfView
    }
    
    func updateUIView(_ pdfView: MyPDFView, context: Context) {}
}

struct MyPKCanvasView: UIViewRepresentable {
    let toolPicker = MyToolPicker()
    
    func makeUIView(context: Context) -> MyCanvasView {
        let canvasView = MyCanvasView()
        toolPicker.addObserver(canvasView)
        
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        canvasView.becomeFirstResponder()

        return canvasView
    }
    
    func updateUIView(_ canvasView: MyCanvasView, context: Context) {}
}

#Preview {
    ContentView(document: .constant(GenkouYoushiDocument()))
}
