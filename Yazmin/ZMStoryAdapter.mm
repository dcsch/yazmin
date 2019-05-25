
#import "ZMStoryAdapter.h"
#import "Story.h"
#import "StoryFacet.h"
#import "ZMachine.h"

ZMStoryAdapter::ZMStoryAdapter(Story *story)
    : _story(story), _storyFacet(nullptr) {
  // Default to the first facet (Z-machine window 0)
  setWindow(0);
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

void ZMStoryAdapter::setColor(int foreground, int background) {
  [_storyFacet setColorForeground:foreground background:background];
}

void ZMStoryAdapter::setCursor(int line, int column) {
  [_storyFacet setCursorLine:line column:column];
}

int ZMStoryAdapter::setFont(int font) { return [_storyFacet setFont:font]; }

void ZMStoryAdapter::setTextStyle(int style) {
  [_storyFacet setTextStyle:style];
}

void ZMStoryAdapter::print(const char *str) {
  NSMutableString *printable = [NSMutableString stringWithUTF8String:str];
  [printable replaceOccurrencesOfString:@"^"
                             withString:@"\n"
                                options:0
                                  range:NSMakeRange(0, printable.length)];
  [printable replaceOccurrencesOfString:@"\r"
                             withString:@"\n"
                                options:0
                                  range:NSMakeRange(0, printable.length)];
  [_storyFacet print:printable];
}

void ZMStoryAdapter::printNumber(int number) {
  [_storyFacet printNumber:number];
}

void ZMStoryAdapter::newLine() { [_storyFacet newLine]; }

size_t ZMStoryAdapter::input(char *str, size_t maxLen) {
  NSString *string = _story.input;
  [string getCString:str maxLength:maxLen encoding:NSASCIIStringEncoding];
  return string.length;
}

void ZMStoryAdapter::setWordWrap(bool wordWrap) {
  // nop -- word wrapping is handled by the window and is permanently
  // on at present
}

char ZMStoryAdapter::inputChar() { return _story.inputChar; }

void ZMStoryAdapter::restore(const void **data, size_t *length) {
  [_story savedSessionData];
}

void ZMStoryAdapter::save(const void *data, size_t length) {
  [_story saveSessionData:[NSData dataWithBytes:data length:length]];
}

uint16_t ZMStoryAdapter::getRestoreOrSaveResult() {
  return [_story lastRestoreOrSaveResult];
}
