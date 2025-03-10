//
//  LegalSectionView.swift
//  Lullz
//
//  Created by Adam Scott on 3/1/25.
//

import SwiftUI

struct LegalTermsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var hasAcknowledged = UserDefaults.standard.bool(forKey: "hasAcknowledgedLegalTerms")
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Terms of Use")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Group {
                        Text("Welcome to Lullz!")
                            .font(.headline)
                        
                        Text("By using this application, you agree to the following terms and conditions:")
                        
                        Text("1. Acceptance of Terms")
                            .fontWeight(.medium)
                        Text("By accessing and using Lullz, you accept and agree to be bound by the terms and provisions of this agreement.")
                        
                        Text("2. Use License")
                            .fontWeight(.medium)
                        Text("Permission is granted to use this application for personal, non-commercial purposes. This is the grant of a license, not a transfer of title.")
                        
                        Text("3. Disclaimer")
                            .fontWeight(.medium)
                        Text("Lullz is provided on an 'as is' basis. The developer makes no warranties, expressed or implied, and hereby disclaims all implied warranties, including any warranty of merchantability and warranty of fitness for a particular purpose.")
                        
                        Text("4. Limitation of Liability")
                            .fontWeight(.medium)
                        Text("In no event shall the developer be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) arising out of the use or inability to use Lullz.")
                    }
                    
                    Text("Privacy Policy")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    Group {
                        Text("Data Collection")
                            .fontWeight(.medium)
                        Text("Lullz may collect anonymous usage statistics to improve the application. No personally identifiable information is collected unless explicitly provided by you.")
                        
                        Text("HomeKit Data")
                            .fontWeight(.medium)
                        Text("When you enable HomeKit integration, Lullz accesses your HomeKit data with your permission. This data is only used to control your smart home devices and is never transmitted to external servers.")
                        
                        Text("Third-Party Services")
                            .fontWeight(.medium)
                        Text("Lullz may use third-party services for analytics and advertisements. These services may collect anonymous information about your device and usage patterns.")
                    }
                    
                    if !hasAcknowledged {
                        Button(action: acknowledgeTerms) {
                            Text("I Acknowledge and Accept")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.top, 20)
                    }
                }
                .padding()
            }
            .navigationTitle("Legal Information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if hasAcknowledged {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
    private func acknowledgeTerms() {
        // Save acknowledgment date
        UserDefaults.standard.set(Date(), forKey: "legalTermsAcknowledgmentDate")
        UserDefaults.standard.set(true, forKey: "hasAcknowledgedLegalTerms")
        hasAcknowledged = true
        
        // Allow dismissal if this is being presented in a sheet
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }
}

struct LegalTermsView_Previews: PreviewProvider {
    static var previews: some View {
        LegalTermsView()
    }
} 