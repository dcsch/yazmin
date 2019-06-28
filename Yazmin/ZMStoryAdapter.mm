
#import "ZMStoryAdapter.h"
#import "Preferences.h"
#import "Story.h"
#import "StoryController.h"
#import "StoryFacet.h"
#import "ZMachine.h"

ZMStoryAdapter::ZMStoryAdapter(Story *story)
    : _story(story), _storyFacet(nil), timer(nil), screenEnabled(true),
      transcriptOutputStream(nil) {

  // Default to the first facet (Z-machine window 0)
  setWindow(0);

  lowSound = [NSSound soundNamed:@"Bottle"];
  highSound = [NSSound soundNamed:@"Hero"];
}

int ZMStoryAdapter::getScreenWidth() const {
  return _story.facets[1].widthInCharacters;
}

int ZMStoryAdapter::getScreenHeight() const {
  return _story.facets[1].heightInLines;
}

int ZMStoryAdapter::getWindow() const {
  if (_storyFacet == _story.facets[1])
    return 1;
  else
    return 0;
}

void ZMStoryAdapter::setWindow(int window) {
  _storyFacet = (_story.facets)[window];
}

void ZMStoryAdapter::splitWindow(int lines) {
  StoryFacet *storyFacet = (_story.facets)[1];
  storyFacet.numberOfLines = lines;
}

void ZMStoryAdapter::eraseWindow(int window) {
  // -1 unsplits the screen and clears
  // -2 clears all windows without unsplitting
  if (window < 0) {
    if (window == -1)
      splitWindow(0);
    eraseWindow(0);
    eraseWindow(1);
  } else {
    StoryFacet *storyFacet = (_story.facets)[window];
    [storyFacet erase];
  }
}

void ZMStoryAdapter::showStatus() {
  // Generate a version 1-3 status line
  StoryFacet *storyFacet = (_story.facets)[1];
  if (storyFacet.numberOfLines == 0)
    splitWindow(1);
  setWindow(1);

  // Display an inverse video bar
  int screenWidth = getScreenWidth();
  [_storyFacet setCursorLine:1 column:1];
  [_storyFacet setTextStyle:1];
  for (unsigned int i = 0; i < screenWidth; ++i)
    [_storyFacet print:@" "];

  // Overlay with text
  [_storyFacet setCursorLine:1 column:2];

  // From the spec:
  // Section 8.2.2
  // The short name of the object whose number is in the first global variable
  // should be printed on the left hand side of the line.
  unsigned int scoreAndMovesLen;
  bool shortDisplay;
  if (screenWidth >= 72) {
    scoreAndMovesLen = 23;
    shortDisplay = false;
  } else {
    scoreAndMovesLen = 8;
    shortDisplay = true;
  }
  unsigned int maxNameLen = screenWidth - scoreAndMovesLen;
  unsigned int objectNumber = [_story.zMachine globalAtIndex:0];
  NSString *name = [_story.zMachine nameOfObject:objectNumber];
  if (name.length <= maxNameLen)
    [_storyFacet print:name];
  else {
    // TODO: Put an ellipsis at the last space that fits in the available line
    [_storyFacet print:name];
  }
  [_storyFacet setCursorLine:1 column:screenWidth - scoreAndMovesLen];

  if (_story.zMachine.isTimeGame) {
    if (!shortDisplay)
      [_storyFacet print:@"Time:  "];
    [_storyFacet printNumber:[[_story zMachine] globalAtIndex:1]];
    [_storyFacet print:@":"];
    unsigned int min = [_story.zMachine globalAtIndex:2];
    if (min < 10)
      [_storyFacet printNumber:0];
    [_storyFacet printNumber:min];
  } else {
    if (!shortDisplay)
      [_storyFacet print:@"Score: "];
    [_storyFacet printNumber:(int)[_story.zMachine globalAtIndex:1]];
    if (!shortDisplay)
      [_storyFacet print:@"  Moves: "];
    else
      [_storyFacet print:@"/"];
    [_storyFacet printNumber:[_story.zMachine globalAtIndex:2]];
  }

  [_storyFacet setTextStyle:0];
  setWindow(0);
}

void ZMStoryAdapter::outputStream(int stream) {
  switch (stream) {
  case 1:
    screenEnabled = true;
    break;
  case -1:
    screenEnabled = false;
    break;
  case 2:
    transcriptOutputStream = [_story transcriptOutputStream];
    [transcriptOutputStream open];
    break;
  case -2:
    [transcriptOutputStream close];
    transcriptOutputStream = nil;
    break;
  }
}

void ZMStoryAdapter::getColor(int &foreground, int &background) const {
  if (screenEnabled) {
    foreground = _storyFacet.foregroundColorCode;
    background = _storyFacet.backgroundColorCode;
  }
}

void ZMStoryAdapter::setColor(int foreground, int background) {
  if (screenEnabled) {
    [_story.facets[0] setColorForeground:foreground background:background];
    [_story.facets[1] setColorForeground:foreground background:background];
  }
}

uint16_t trueColorFromColor(NSColor *color) {
  CGFloat r, g, b, a;
  [color getRed:&r green:&g blue:&b alpha:&a];
  uint16_t rc = static_cast<uint16_t>(31.0 * r);
  uint16_t gc = static_cast<uint16_t>(31.0 * g) << 5;
  uint16_t bc = static_cast<uint16_t>(31.0 * b) << 10;
  return bc | gc | rc;
}

void ZMStoryAdapter::getTrueColor(int &foreground, int &background) const {
  if (screenEnabled) {
    NSColor *color = [_storyFacet.foregroundColor
        colorUsingColorSpace:NSColorSpace.genericRGBColorSpace];
    foreground = trueColorFromColor(color);
    color = [_storyFacet.backgroundColor
        colorUsingColorSpace:NSColorSpace.genericRGBColorSpace];
    background = trueColorFromColor(color);
  }
}

void ZMStoryAdapter::setTrueColor(int foreground, int background) {
  if (screenEnabled)
    [_storyFacet setTrueColorForeground:foreground background:background];
}

void ZMStoryAdapter::getCursor(int &line, int &column) const {
  if (screenEnabled) {
    line = _storyFacet.line;
    column = _storyFacet.column;
  }
}

void ZMStoryAdapter::setCursor(int line, int column) {
  if (screenEnabled)
    [_storyFacet setCursorLine:line column:column];
}

int ZMStoryAdapter::setFont(int font) {
  if (screenEnabled)
    return [_storyFacet setFont:font];
  else
    return 0;
}

void ZMStoryAdapter::setTextStyle(int style) {
  if (screenEnabled)
    [_storyFacet setTextStyle:style];
}

bool ZMStoryAdapter::checkUnicode(uint16_t uc) {
  NSFont *font = _storyFacet.currentAttributes[NSFontAttributeName];
  NSCharacterSet *charSet = font.coveredCharacterSet;
  return [charSet characterIsMember:uc];
}

void ZMStoryAdapter::print(const std::string &str) {
  NSMutableString *printable =
      [NSMutableString stringWithUTF8String:str.c_str()];
  if (printable) {
    [printable replaceOccurrencesOfString:@"\r"
                               withString:@"\n"
                                  options:0
                                    range:NSMakeRange(0, printable.length)];
    if (screenEnabled) {
      _storyFacet.forceFixedPitchFont = _story.zMachine.forcedFixedPitchFont;
      [_storyFacet print:printable];
    }
    if (transcriptOutputStream && getWindow() == 0) {
      [transcriptOutputStream write:(const uint8_t *)printable.UTF8String
                          maxLength:str.length()];
    }
  } else {
    NSLog(@"Error: Unprintable string");
  }
}

void ZMStoryAdapter::printNumber(int number) {
  if (screenEnabled) {
    _storyFacet.forceFixedPitchFont = _story.zMachine.forcedFixedPitchFont;
    [_storyFacet printNumber:number];
  }
  if (transcriptOutputStream && getWindow() == 0) {
    std::string str = std::to_string(number);
    [transcriptOutputStream write:(const uint8_t *)str.c_str()
                        maxLength:str.length()];
  }
}

void ZMStoryAdapter::newLine() {
  if (screenEnabled)
    [_storyFacet newLine];
  if (transcriptOutputStream && getWindow() == 0)
    [transcriptOutputStream write:(const uint8_t *)"\n" maxLength:1];
}

void ZMStoryAdapter::setWordWrap(bool wordWrap) {
  // nop -- word wrapping is handled by the window and is permanently
  // on at present
}

void ZMStoryAdapter::beginInput(uint8_t existingLen) {
  [_story beginInputWithOffset:-existingLen];
}

std::string ZMStoryAdapter::endInput() {
  NSString *string = [_story endInput].lowercaseString;
  std::string str;
  if (string)
    str.assign(string.UTF8String);
  if (transcriptOutputStream && getWindow() == 0) {
    [transcriptOutputStream write:(const uint8_t *)str.c_str()
                        maxLength:str.length()];
    [transcriptOutputStream write:(const uint8_t *)"\n" maxLength:1];
  }
  return str;
}

void ZMStoryAdapter::beginInputChar() { [_story beginInputChar]; }

wchar_t ZMStoryAdapter::endInputChar() { return [_story endInputChar]; }

void ZMStoryAdapter::soundEffect(int number, int effect, int repeat,
                                 int volume) {

  // Minimal implementation
  if (number == 1 || number == 0)
    [highSound play];
  else if (number == 2)
    [lowSound play];
}

void ZMStoryAdapter::startTimedRoutine(int time, int routine) {
  NSTimeInterval interval = time / 10.0;
  timer = [NSTimer scheduledTimerWithTimeInterval:interval
                                          repeats:YES
                                            block:^(NSTimer *_Nonnull timer) {
                                              BOOL retVal =
                                                  [this->_story.storyController
                                                      executeRoutine:routine];
                                              if (retVal) {
                                                [timer invalidate];
                                                [this->_story.storyController
                                                    stringInput:nil];
                                              }
                                            }];
}

void ZMStoryAdapter::stopTimedRoutine() {
  [timer invalidate];
  timer = nil;
}

void ZMStoryAdapter::beginRestore() const { [_story restoreSession]; }

uint16_t ZMStoryAdapter::endRestore(const uint8_t **data,
                                    size_t *length) const {
  if (_story.restoreData) {
    *length = _story.restoreData.length;
    *data = new uint8_t[*length];
    [_story.restoreData getBytes:(void *)*data length:*length];
  }
  return [_story lastRestoreOrSaveResult];
}

void ZMStoryAdapter::save(const uint8_t *data, size_t length) const {
  [_story saveSessionData:[NSData dataWithBytes:data length:length]];
}

uint16_t ZMStoryAdapter::getRestoreOrSaveResult() {
  return [_story lastRestoreOrSaveResult];
}
