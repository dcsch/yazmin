
#import "LayoutView.h"
#import "Preferences.h"
#import "StoryFacetView.h"

@implementation LayoutView

- (instancetype)initWithFrame:(NSRect)frameRect {
  if ((self = [super initWithFrame:frameRect]) != nil) {
    NSLog(@"initializing layout view");

    lowerScrollView = [[NSScrollView alloc] initWithFrame:frameRect];
    [lowerScrollView setHasVerticalScroller:YES];
    lowerScrollView.borderType = NSNoBorder;
    lowerScrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self addSubview:lowerScrollView];
  }
  return self;
}

- (StoryController *)controller {
  return controller;
}

- (StoryFacetView *)upperWindow {
  return upperWindow;
}

- (void)setUpperWindow:(StoryFacetView *)view {
  NSLog(@"setUpperWindow");

  upperWindow = view;
  [self addSubview:upperWindow];
}

- (StoryFacetView *)lowerWindow {
  return lowerWindow;
}

- (void)setLowerWindow:(StoryFacetView *)view {
  NSLog(@"setLowerWindow");

  lowerWindow = view;
  lowerScrollView.documentView = lowerWindow;
}

- (NSScrollView *)lowerScrollView {
  return lowerScrollView;
}

- (void)resizeUpperWindow:(int)lines {
  NSRect lowerFrameRect = lowerScrollView.frame;
  float layoutHeight = self.frame.size.height;
  float upperHeight =
      [[Preferences sharedPreferences] monospacedLineHeight] * lines;

  // Move the lower window
  lowerFrameRect.origin.y = upperHeight;
  lowerFrameRect.size.height = layoutHeight - upperHeight;
  lowerScrollView.frame = lowerFrameRect;

  // Move the upper window
  NSRect frameRect = NSMakeRect(0, 0, lowerFrameRect.size.width, upperHeight);
  upperWindow.frame = frameRect;
}

- (BOOL)isFlipped {
  return YES;
}

@end
