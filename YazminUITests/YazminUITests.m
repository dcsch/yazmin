//
//  YazminUITests.m
//  YazminUITests
//
//  Created by David Schweinsberg on 12/12/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface YazminUITests : XCTestCase

@end

@implementation YazminUITests

- (void)setUp {
  // Put setup code here. This method is called before the invocation of each
  // test method in the class.

  // In UI tests it is usually best to stop immediately when a failure occurs.
  self.continueAfterFailure = NO;

  // In UI tests it’s important to set the initial state - such as interface
  // orientation - required for your tests before they run. The setUp method is
  // a good place to do this.
}

- (void)tearDown {
}

- (void)testTetrisLowerWindow {
  XCUIApplication *app = [[XCUIApplication alloc] init];
  [app launch];

  XCUIElement *libraryWindow = app.windows[@"Library"];
  [[[libraryWindow.tableRows elementBoundByIndex:27].cells
      elementBoundByIndex:0] doubleClick];

  XCUIElement *storyWindow = app.windows[@"Tetris"];
  XCUIElement *lowerScrollView =
      [storyWindow.scrollViews elementBoundByIndex:1];
  XCUIElement *lowerTextView = [storyWindow.textViews elementBoundByIndex:1];

  // Start the tiles falling
  [lowerTextView typeText:@"\r"];

  CGRect textRect = lowerTextView.frame;
  CGRect scrollRect = lowerScrollView.frame;
  XCTAssertEqual(textRect.origin.y, scrollRect.origin.y,
                 @"textView origin doesn't match scrollView origin");

  [[[XCUIApplication alloc]
       init].windows[@"Tetris"].buttons[XCUIIdentifierCloseWindow] click];
}

@end
