
#import "ZMStoryAdapter.h"
#import "Story.h"
#import "StoryController.h"
#import "StoryFacet.h"
#import "ZMachine.h"

ZMStoryAdapter::ZMStoryAdapter(Story *story)
    : _story(story), _storyFacet(nil), timer(nil), screenEnabled(true),
      transcriptEnabled(false) {

  // Default to the first facet (Z-machine window 0)
  setWindow(0);

  lowSound = [NSSound soundNamed:@"Bottle"];
  highSound = [NSSound soundNamed:@"Hero"];
}

ZMStoryAdapter::~ZMStoryAdapter() {}

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
  unsigned int screenWidth = [_story.zMachine screenWidth];
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
    transcriptEnabled = true;
    break;
  case -2:
    transcriptEnabled = false;
    break;
  }
}

void ZMStoryAdapter::setColor(int foreground, int background) {
  if (screenEnabled)
    [_storyFacet setColorForeground:foreground background:background];
}

void ZMStoryAdapter::setTrueColor(int foreground, int background) {
  if (screenEnabled)
    [_storyFacet setTrueColorForeground:foreground background:background];
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

void ZMStoryAdapter::print(const std::string &str) {
  NSMutableString *printable =
      [NSMutableString stringWithUTF8String:str.c_str()];
  [printable replaceOccurrencesOfString:@"^"
                             withString:@"\n"
                                options:0
                                  range:NSMakeRange(0, printable.length)];
  [printable replaceOccurrencesOfString:@"\r"
                             withString:@"\n"
                                options:0
                                  range:NSMakeRange(0, printable.length)];
  if (screenEnabled) {
    _storyFacet.forceFixedPitchFont = _story.zMachine.forcedFixedPitchFont;
    [_storyFacet print:printable];
  }
}

void ZMStoryAdapter::printNumber(int number) {
  if (screenEnabled) {
    _storyFacet.forceFixedPitchFont = _story.zMachine.forcedFixedPitchFont;
    [_storyFacet printNumber:number];
  }
}

void ZMStoryAdapter::newLine() {
  if (screenEnabled)
    [_storyFacet newLine];
}

void ZMStoryAdapter::setWordWrap(bool wordWrap) {
  // nop -- word wrapping is handled by the window and is permanently
  // on at present
}

void ZMStoryAdapter::beginInput(uint8_t existingLen) {
  [_story beginInputWithOffset:-existingLen];
}

size_t ZMStoryAdapter::endInput(char *str, size_t maxLen) {
  NSString *string = [_story endInput];
  [string getCString:str maxLength:maxLen encoding:NSASCIIStringEncoding];
  return string.length;
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
  timer = [NSTimer
      scheduledTimerWithTimeInterval:interval
                             repeats:YES
                               block:^(NSTimer *_Nonnull timer) {
                                 if ([this->_story.zMachine
                                         callRoutine:routine])
                                   [this->_story.storyController executeStory];
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
