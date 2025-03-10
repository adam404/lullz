import SwiftUI

enum Legal {}

struct LegalSectionView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var acknowledgedDisclaimer = false
  @State private var showAcknowledgmentAlert = false
  
  var body: some View {
    NavigationStack {
      List {
        Section(header: Text("Important Legal Information")) {
          Text("Please review the following legal documents. By using this app, you agree to be bound by these terms.")
            .font(.footnote)
            .foregroundColor(.secondary)
            .padding(.vertical, 8)
          
          Toggle("I acknowledge I have read the disclaimer", isOn: $acknowledgedDisclaimer)
            .font(.subheadline)
            .tint(.blue) // Updated from .accentColor
        }
        
        Section {
          ForEach(LegalDocumentType.allCases, id: \.self) { documentType in
            NavigationLink(destination: LegalDocumentView(documentType: documentType)) {
              VStack(alignment: .leading) {
                HStack {
                  Image(systemName: iconForDocument(documentType))
                    .foregroundColor(.blue) // Updated from .accentColor
                  Text(documentType.rawValue)
                }
              }
            }
          }
        }
        
        Section(footer: legalFooter) {
          Button(action: {
            if acknowledgedDisclaimer {
              saveAcknowledgment()
              dismiss()
            } else {
              showAcknowledgmentAlert = true
            }
          }) {
            Text("Accept Terms")
              .frame(maxWidth: .infinity)
              .padding(.vertical, 10)
          }
          .disabled(!acknowledgedDisclaimer)
          .buttonStyle(.borderedProminent)
          .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)) // Safer approach
          .listRowBackground(Color.clear)
        }
      }
      .navigationTitle("Legal Information")
      .alert("Acknowledgment Required", isPresented: $showAcknowledgmentAlert) {
        Button("OK", role: .cancel) { }
      } message: {
        Text("Please acknowledge that you have read the disclaimer before proceeding.")
      }
    }
  }
  
  private var legalFooter: some View {
    Text("By accepting these terms, you acknowledge that Lullz is not intended to diagnose, treat, cure, or prevent any disease and is not a substitute for medical advice.")
      .font(.caption2)
      .foregroundColor(.secondary)
      .padding(.top, 8)
  }
  
  private func iconForDocument(_ type: LegalDocumentType) -> String {
    switch type {
    case .disclaimer: return "exclamationmark.shield"
    case .privacyPolicy: return "lock.shield"
    case .termsOfService: return "doc.text"
    case .license: return "key"
    }
  }
  
  private func saveAcknowledgment() {
    UserDefaults.standard.set(true, forKey: "hasAcknowledgedLegalTerms")
    UserDefaults.standard.set(Date(), forKey: "legalTermsAcknowledgmentDate")
  }
}

// Uncomment this enum:
enum LegalDocumentType: String, CaseIterable, Identifiable {
  case disclaimer = "Disclaimer"
  case privacyPolicy = "Privacy Policy"
  case termsOfService = "Terms of Service"
  case license = "License"
  
  var id: String { self.rawValue }
  
  var filename: String {
    switch self {
    case .disclaimer: return "disclaimer"
    case .privacyPolicy: return "privacy_policy"
    case .termsOfService: return "terms_of_service"
    case .license: return "license"
    }
  }
}
