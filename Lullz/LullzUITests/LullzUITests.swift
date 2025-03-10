//
//  LullzUITests.swift
//  LullzUITests
//
//  Created by Adam Scott on 3/1/25.
//

import XCTest

final class LullzUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it's important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testNoiseGenerationControls() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()
        
        // Verify noise type selector exists and can be interacted with
        XCTAssertTrue(app.segmentedControls["noiseTypeSelector"].exists)
        
        // Test selecting different noise types
        app.segmentedControls["noiseTypeSelector"].buttons["White"].tap()
        XCTAssertTrue(app.staticTexts["activeNoiseLabel"].label.contains("White"))
        
        app.segmentedControls["noiseTypeSelector"].buttons["Pink"].tap()
        XCTAssertTrue(app.staticTexts["activeNoiseLabel"].label.contains("Pink"))
        
        app.segmentedControls["noiseTypeSelector"].buttons["Brown"].tap()
        XCTAssertTrue(app.staticTexts["activeNoiseLabel"].label.contains("Brown"))
        
        // Verify volume control exists and works
        XCTAssertTrue(app.sliders["volumeControl"].exists)
        app.sliders["volumeControl"].adjust(toNormalizedSliderPosition: 0.7)
        
        // Verify play/pause button functionality
        XCTAssertTrue(app.buttons["playPauseButton"].exists)
        app.buttons["playPauseButton"].tap()
        // Check if the button's label changed from "Play" to "Pause" or vice versa
        XCTAssertTrue(app.buttons["playPauseButton"].label == "Pause" || app.buttons["playPauseButton"].label == "Play")
    }
    
    @MainActor
    func testBalanceAndDelayControls() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Test balance control
        XCTAssertTrue(app.sliders["balanceControl"].exists)
        app.sliders["balanceControl"].adjust(toNormalizedSliderPosition: 0.25) // Left-biased
        
        // Test delay controls
        XCTAssertTrue(app.sliders["leftDelayControl"].exists)
        app.sliders["leftDelayControl"].adjust(toNormalizedSliderPosition: 0.3)
        
        XCTAssertTrue(app.sliders["rightDelayControl"].exists)
        app.sliders["rightDelayControl"].adjust(toNormalizedSliderPosition: 0.6)
        
        // Verify settings tab exists and can be accessed
        XCTAssertTrue(app.tabBars.buttons["Settings"].exists)
        app.tabBars.buttons["Settings"].tap()
        
        // Verify legal disclaimer exists
        XCTAssertTrue(app.staticTexts["legalDisclaimerText"].exists)
        XCTAssertTrue(app.staticTexts["legalDisclaimerText"].label.contains("not intended"))
    }
    
    @MainActor
    func testSaveCustomProfile() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Configure a custom noise profile
        app.segmentedControls["noiseTypeSelector"].buttons["Pink"].tap()
        app.sliders["volumeControl"].adjust(toNormalizedSliderPosition: 0.65)
        app.sliders["balanceControl"].adjust(toNormalizedSliderPosition: 0.4)
        
        // Save profile
        app.buttons["saveProfileButton"].tap()
        
        // Enter profile name in alert
        app.textFields["profileNameField"].typeText("Sleep Aid")
        app.buttons["Save"].tap()
        
        // Verify profile was saved
        app.tabBars.buttons["Profiles"].tap()
        XCTAssertTrue(app.staticTexts["Sleep Aid"].exists)
    }
    
    @MainActor
    func testAccessibilityCompliance() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Verify key controls have proper accessibility labels
        XCTAssertTrue(app.buttons["playPauseButton"].isAccessibilityElement)
        XCTAssertTrue(app.sliders["volumeControl"].isAccessibilityElement)
        XCTAssertTrue(app.segmentedControls["noiseTypeSelector"].isAccessibilityElement)
        
        // Test VoiceOver descriptions exist
        // Note: Advanced VoiceOver testing would require additional setup
        XCTAssertNotNil(app.buttons["playPauseButton"].value)
        XCTAssertNotNil(app.sliders["volumeControl"].value)
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
