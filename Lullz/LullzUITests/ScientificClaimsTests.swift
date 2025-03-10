//
//  ScientificClaimsTests.swift
//  LullzUITests
//
//  Created by Adam Scott on 3/1/25.
//

import XCTest

final class ScientificClaimsTests: XCTestCase {
    
    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    @MainActor
    func testScientificInfoAccuracy() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to info section
        app.tabBars.buttons["Information"].tap()
        
        // Verify scientific information is presented
        XCTAssertTrue(app.staticTexts["scientificInfoHeader"].exists)
        
        // Check citation information exists
        XCTAssertTrue(app.staticTexts.matching(identifier: "citationText").count > 0)
        
        // Verify legal disclaimer about claims
        let disclaimerText = app.staticTexts["scientificDisclaimerText"].label
        XCTAssertTrue(disclaimerText.contains("not intended to diagnose"))
        XCTAssertTrue(disclaimerText.contains("not a medical device"))
        
        // Check that references to studies are properly formatted
        let studyReferences = app.staticTexts.matching(identifier: "studyReference")
        XCTAssertTrue(studyReferences.count > 0)
        
        // Verify sound info section
        app.buttons["Sound Science"].tap()
        XCTAssertTrue(app.staticTexts["whiteNoiseExplanation"].exists)
        XCTAssertTrue(app.staticTexts["pinkNoiseExplanation"].exists)
        XCTAssertTrue(app.staticTexts["brownNoiseExplanation"].exists)
    }
    
    @MainActor
    func testLegalComplianceElements() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to settings
        app.tabBars.buttons["Settings"].tap()
        
        // Check privacy policy exists
        XCTAssertTrue(app.buttons["Privacy Policy"].exists)
        app.buttons["Privacy Policy"].tap()
        XCTAssertTrue(app.staticTexts["privacyPolicyContent"].exists)
        app.navigationBars.buttons.firstMatch.tap() // Back button
        
        // Check terms of service exists
        XCTAssertTrue(app.buttons["Terms of Service"].exists)
        app.buttons["Terms of Service"].tap()
        XCTAssertTrue(app.staticTexts["termsOfServiceContent"].exists)
        
        // Verify no medical claims disclaimer
        XCTAssertTrue(app.staticTexts["legalDisclaimerText"].label.contains("not a substitute for medical advice"))
    }
} 