
#import "LayoutView.h"
#import "Preferences.h"
#import "StoryFacetView.h"

@interface LayoutView () {
  StoryFacetView *_upperWindow;
  StoryFacetView *_lowerWindow;
}

@end

@implementation LayoutView

- (instancetype)initWithFrame:(NSRect)frameRect {
  if ((self = [super initWithFrame:frameRect]) != nil) {
    _lowerScrollView = [[NSScrollView alloc] initWithFrame:frameRect];
    [_lowerScrollView setHasVerticalScroller:YES];
    _lowerScrollView.borderType = NSNoBorder;
    _lowerScrollView.autoresizingMask =
        NSViewWidthSizable | NSViewHeightSizable;
    [self addSubview:_lowerScrollView];
  }
  return self;
}

- (StoryFacetView *)upperWindow {
  return _upperWindow;
}

- (void)setUpperWindow:(StoryFacetView *)view {
  _upperWindow = view;
  [self addSubview:_upperWindow];
}

- (StoryFacetView *)lowerWindow {
  return _lowerWindow;
}

- (void)setLowerWindow:(StoryFacetView *)view {
  _lowerWindow = view;
  _lowerScrollView.documentView = _lowerWindow;
}

- (void)resizeUpperWindow:(int)lines {
  NSRect lowerFrameRect = _lowerScrollView.frame;
  float layoutHeight = self.frame.size.height;

  NSFont *font = [[Preferences sharedPreferences] fontForStyle:8];
  float lineHeight = [_upperWindow.layoutManager defaultLineHeightForFont:font];
  float upperHeight =
      lines > 0
          ? lineHeight * lines + 2.0 * _upperWindow.textContainerInset.height
          : 0;

  // Move the lower window
  lowerFrameRect.origin.y = upperHeight;
  lowerFrameRect.size.height = layoutHeight - upperHeight;
  _lowerScrollView.frame = lowerFrameRect;

  // Move the upper window
  //_upperWindow.backgroundColor = NSColor.redColor;
  _upperWindow.textContainer.maximumNumberOfLines = lines;

  NSRect frameRect = NSMakeRect(0, 0, lowerFrameRect.size.width, upperHeight);
  _upperWindow.frame = frameRect;

  // Scroll the lower window to compensate for the shift in position
  // (we're keeping this simple for now: just scroll to the bottom)
  [_lowerWindow scrollPoint:NSMakePoint(0, _lowerWindow.frame.size.height)];
}

- (BOOL)isFlipped {
  return YES;
}

@end
