//
//  LegalDocumentView.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import SwiftUI

// Replace the duplicate enum with an import or comment out if it's defined elsewhere
// enum LegalDocumentType {
//     case termsOfService
//     case privacyPolicy
//     case disclaimer
//     case license
// }

// If it's defined in a shared location, import that file
// import LegalTypes

struct LegalDocumentView: View {
    let documentType: LegalDocumentType
    @State private var documentText: String = ""
    @State private var isLoading: Bool = true
    
    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView()
                    .padding()
            } else {
                Text(.init(documentText))
                    .padding()
            }
        }
        .navigationTitle(documentType.rawValue)
        .onAppear {
            loadDocument()
        }
    }
    
    private func loadDocument() {
        isLoading = true
        if let path = Bundle.main.path(forResource: documentType.filename, ofType: "md", inDirectory: "Legal") {
            do {
                documentText = try String(contentsOfFile: path, encoding: .utf8)
                isLoading = false
            } catch {
                documentText = "Error loading document: \(error.localizedDescription)"
                isLoading = false
            }
        } else {
            documentText = "Document not found"
            isLoading = false
        }
    }
} 