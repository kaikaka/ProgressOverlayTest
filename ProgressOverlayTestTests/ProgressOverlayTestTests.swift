//
//  ProgressOverlayTestTests.swift
//  ProgressOverlayTestTests
//
//  Created by xiangkai yin on 16/9/7.
//  Copyright © 2016年 kuailao_2. All rights reserved.
//

import XCTest
@testable import ProgressOverlayTest

class ProgressOverlayTestTests: XCTestCase {
  
  var hideExpectation:XCTestExpectation!
  
  
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
  
  func testNonAnimatedConvenienceoverlayPresentation() {
    let rootViewController = UIApplication.sharedApplication().keyWindow?.rootViewController
    let rootView = rootViewController?.view
    let overlay = ProgressOverlay.showOnView(rootView, animated: false)
    XCTAssertNotNil(overlay, "A overlay should be created.")
    self.testOverlayIsVisible(overlay, rootView: rootView!)
    XCTAssertEqual(ProgressOverlay.hideForView(rootView), overlay, "The overlay should be found via the convenience operation.")
    XCTAssertTrue(ProgressOverlay.hideForView(rootView) != nil, "The overlay should be found and removed.")
    XCTAssertFalse(ProgressOverlay.hideForView(rootView) == nil, "A subsequent overlay hide operation should fail.")
    self.testOverlayIsVisible(overlay, rootView: rootView!)
  }
  
  func testOverlayIsVisible(overlay:ProgressOverlay,rootView:UIView) {
    XCTAssertEqual(overlay.superview, rootView, "The overlay should be added to the view.")
    XCTAssertEqual(overlay.alpha, 1.0, "The overlay should be visible.")
    XCTAssertFalse(overlay.hidden, "The overlay should be visible.")
  }
  
  func testOverlayIsHidenAndRemoved(overlay:ProgressOverlay,rootView:UIView) {
    XCTAssertFalse(rootView.subviews.contains(overlay), "The overlay should not be part of the view hierarchy.")
    XCTAssertEqual(overlay.alpha, 0.0, "The overlay should be faded out.")
    XCTAssertNil(overlay.superview, "The overlay should not have a superview.")
  }
  
  func testAnimatedConvenienceoverlayPresentation() {
    let rootViewController = UIApplication.sharedApplication().keyWindow?.rootViewController
    let rootView = rootViewController?.view
    
    let overlay = ProgressOverlay.showOnView(rootView, animated: false)
    XCTAssertNotNil(overlay, "A overlay should be created.")
    self.testOverlayIsVisible(overlay, rootView: rootView!)
    
    XCTAssertEqual(ProgressOverlay.hideForView(rootView), overlay, "The overlay should be found via the convenience operation.")
    XCTAssertTrue(ProgressOverlay.hideForView(rootView) != nil, "The overlay should be found and removed.")
    XCTAssertEqual(overlay.alpha, 1.0, "The overlay should still be visible.")
    XCTAssertTrue(rootView?.subviews.contains(overlay) == true, "The overlay should still be part of the view hierarchy.")
    XCTAssertEqual(overlay.superview, rootView, "The overlay should be added to the view.")
    XCTAssertFalse(ProgressOverlay.hideAllOverlaysForView(rootView, animated: true) == false, "A subsequent overlay hide operation should fail.")
    self.testOverlayIsHidenAndRemoved(overlay, rootView: rootView!)
  }
  
  func testCompletionBlock() {
    let rootViewController = UIApplication.sharedApplication().keyWindow?.rootViewController
    let rootView = rootViewController?.view
    
    self.hideExpectation = expectationWithDescription("The completionBlock: should have been called.")
    let overlay = ProgressOverlay.showOnView(rootView, animated: true)
    overlay.completionBlock = { () in
      self.hideExpectation.fulfill()
    }
    overlay.hideAnimated(true)
    waitForExpectationsWithTimeout(5.0) { (error) in
      
    }
  }
  
  // MARK: - Delay
  
  func testDelayedHide() {
    let rootViewController = UIApplication.sharedApplication().keyWindow?.rootViewController
    let rootView = rootViewController?.view
    
    self.hideExpectation = self.expectationWithDescription("The hudWasHidden: delegate should have been called.")
    let overlay = ProgressOverlay.showOnView(rootView, animated: true)
    
    XCTAssertNotNil(overlay,"A overlay should be created.")
    overlay.hideAnimated(true, delay: 2)
    
    self.testOverlayIsVisible(overlay, rootView: rootView!)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(3 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) { () -> Void in
      self.testOverlayIsHidenAndRemoved(overlay, rootView: rootView!)
      self.hideExpectation.fulfill()
    }
    waitForExpectationsWithTimeout(5) { (eror) in
      
    }
  }
  
  // MARK: - Ruse
  
  func testNonAnimatedHudReuse() {
    let rootViewController = UIApplication.sharedApplication().keyWindow?.rootViewController
    let rootView = rootViewController?.view
    
    let overlay = ProgressOverlay.init(view:rootView!)
    // 设置隐藏时 不知道remove ，这样在隐藏后，还可以不用创建就显示
    overlay.removeFromSuperViewOnHide = false
    rootView!.addSubview(overlay)
    overlay.showAnimated(false)
    
    XCTAssertNotNil(overlay,"A overlay should be created.")
    overlay.hideAnimated(false)
    overlay.showAnimated(false)

    testOverlayIsVisible(overlay, rootView: rootView!)
    overlay.hideAnimated(false)
    overlay.removeFromSuperview()
  }
  
  func testUnfinishedHidingAnimation() {
    let rootViewController = UIApplication.sharedApplication().keyWindow?.rootViewController
    let rootView = rootViewController?.view
    
    self.hideExpectation = self.expectationWithDescription("The hudWasHidden: delegate should have been called.")
    let overlay = ProgressOverlay.showOnView(rootView, animated: true)
    overlay.backgroundView.layer.removeAllAnimations()
    
    XCTAssertNotNil(overlay,"A overlay should be created.")
    overlay.hideAnimated(true, delay: 2)
    
    self.testOverlayIsVisible(overlay, rootView: rootView!)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(3 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) { () -> Void in
      self.testOverlayIsHidenAndRemoved(overlay, rootView: rootView!)
      self.hideExpectation.fulfill()
    }
    waitForExpectationsWithTimeout(5) { (eror) in
      
    }
  }
  
  // MARK: - Min show time
  
  func testMinShowTime() {
    let rootViewController = UIApplication.sharedApplication().keyWindow?.rootViewController
    let rootView = rootViewController?.view
    
    self.hideExpectation = self.expectationWithDescription("The hudWasHidden: delegate should have been called.")
    let overlay = ProgressOverlay.init(view:rootView!)
    overlay.minShowTime = 2
    rootView?.addSubview(overlay)
    overlay.showAnimated(true)
    XCTAssertNotNil(overlay,"A overlay should be created.")
    overlay.hideAnimated(true)
    
    var checkedAfterOneSecond = false
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) { () -> Void in
     self.testOverlayIsVisible(overlay, rootView: rootView!)
      checkedAfterOneSecond = true
      XCTAssertTrue(checkedAfterOneSecond)
      self.hideExpectation.fulfill()
    }
    
    waitForExpectationsWithTimeout(5.0) { (error) in
      
    }
  }
  
  // MARK: - Grace time
  
  func testGraceTime() {
    let rootViewController = UIApplication.sharedApplication().keyWindow?.rootViewController
    let rootView = rootViewController?.view
    
    self.hideExpectation = self.expectationWithDescription("The hudWasHidden: delegate should have been called.")
    let overlay = ProgressOverlay.init(view:rootView!)
    overlay.graceTime = 2
    rootView?.addSubview(overlay)
    overlay.showAnimated(true)
    XCTAssertNotNil(overlay,"A overlay should be created.")
    XCTAssertEqual(overlay.superview, rootView, "The overlay should be added to the view.")
    XCTAssertEqual(overlay.alpha, 0.0, "The overlay should not be visible.")
    XCTAssertFalse(overlay.hidden, "The overlay should be visible.")
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) { () -> Void in
      XCTAssertEqual(overlay.superview, rootView, "The overlay should be added to the view.")
      XCTAssertEqual(overlay.alpha, 0.0, "The overlay should not be visible.")
      XCTAssertFalse(overlay.hidden, "The overlay should be visible.")
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(3 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) { () -> Void in
      self.testOverlayIsVisible(overlay, rootView: rootView!)
      overlay.hideAnimated(true)
      self.hideExpectation.fulfill()
    }
    waitForExpectationsWithTimeout(5) { (error) in
      
    }
  }
  
}
