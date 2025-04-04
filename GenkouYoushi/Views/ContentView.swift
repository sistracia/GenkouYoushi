import SwiftUI

struct ContentView: View {
    @Binding var document: GenkouYoushiDocument
    @State private var isEditing: Bool = false
    @State private var showInitDialog: Bool = false
    
    @State private var showKanjiForm: Bool = false
    @State private var kanjiFormHeight: CGFloat = .zero
    
    var body: some View {
        VStack {
            if document.pdfData.isEmpty {
                Button {
                    showInitDialog = true
                } label: {
                    Text("Create Paper")
                }
                .buttonStyle(.borderedProminent)
                .confirmationDialog("Choose how will you initialize your paper?",
                                    isPresented: $showInitDialog,
                                    titleVisibility: .hidden
                ) {
                    Button {
                        showInitDialog = false
                        document.pdfData = initStroke()
                    } label: {
                        Text("Empty Paper")
                    }
                    
                    Button {
                        showInitDialog = false
                        showKanjiForm = true
                    } label: {
                        Text("With Kanji")
                    }
                }
            } else {
                MyPDFViewPresentable(data: $document.pdfData, isEditing: $isEditing)
            }
        }
        .toolbar {
            ToolbarItemGroup {
                if !document.pdfData.isEmpty {
                    Toggle(isOn: $isEditing) {
                        Image(systemName: "pencil.tip.crop.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showKanjiForm) {
            KanjiForm()
                .onKanjiSelected({ kanjiText in })
                .onSave({ description, kanjiImage, kanjiOrders in
                    showKanjiForm = false
                    document.pdfData = initStroke(image: kanjiImage, description: description, kanjiOrders: kanjiOrders.reversed())
                })
                .presentationSizing(.form.fitted(horizontal: false, vertical: true))
        }
    }
    
    func initStroke() -> Data {
        return self.initStroke(image: nil, description: nil, kanjiOrders: [])
    }
    
    func initStroke(image: UIImage?, description: String?, kanjiOrders: [UIImage?]) -> Data {
        let pageMaxWidth: CGFloat = 1600
        let pageMaxHeight: CGFloat = 2400
        
        let blockStartHeight: CGFloat = pageMaxHeight -  pageMaxWidth
        let cellSize: CGFloat = 80
        
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageMaxWidth, height: pageMaxHeight))
        let pdf = renderer.pdfData { context in
            context.beginPage()
            
            let path = UIBezierPath()
            
            // Draw vertical lines
            for i in stride(from: cellSize, to: pageMaxWidth, by: cellSize) {
                path.move(to: CGPoint(x: i, y: blockStartHeight))
                path.addLine(to: CGPoint(x: i, y: pageMaxHeight))
                path.stroke()
            }
            
            // Draw horizontal lines
            for i in stride(from: blockStartHeight, to: pageMaxHeight, by: cellSize) {
                path.move(to: CGPoint(x: 0, y: i))
                path.addLine(to: CGPoint(x: pageMaxHeight, y: i))
                path.stroke()
            }
            
            if let image = image {
                let minDimension = blockStartHeight * 0.8
                let centerX = (blockStartHeight - minDimension) / 2
                let centerY = (blockStartHeight - minDimension) / 2
                
                image.draw(in: CGRect(x: centerX, y: centerY, width: minDimension, height: minDimension))
            }
            
            if let description = description as NSString? {
                let minDimension = blockStartHeight * 0.9
                let centerY = (blockStartHeight - minDimension) / 2
                
                description.draw(in: CGRect(x: blockStartHeight, y: centerY, width: minDimension, height: minDimension),
                                 withAttributes: [.font: UIFont.systemFont(ofSize: 32)])
            }
            
            let verticalLines: CGFloat = pageMaxWidth / cellSize
            let horizontalLines: CGFloat = (pageMaxHeight - blockStartHeight) / cellSize
            
            for i in 0..<kanjiOrders.count {
                guard let kanjiOrderImage = kanjiOrders[i]else {
                    continue
                }
                
                kanjiOrderImage.draw(in: CGRect(x: cellSize * CGFloat(i).truncatingRemainder(dividingBy: verticalLines),
                                                y: blockStartHeight + (cellSize * (CGFloat(i) / horizontalLines).rounded(.towardZero)),
                                                width: cellSize,
                                                height: cellSize))
            }
        }
        
        return pdf
    }
}

#Preview {
    @Previewable @State var document = GenkouYoushiDocument()
    @Previewable @State var modelData = ModelData()
    
    ContentView(document: $document).environment(modelData)
}
