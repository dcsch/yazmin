
#import "ZMStoryAdapter.h"
#import "Preferences.h"
#import "Story.h"
#import "StoryController.h"

ZMStoryAdapter::ZMStoryAdapter(Story *story)
    : _story(story), timer(nil), screenEnabled(true) {}

int ZMStoryAdapter::getScreenWidth() const { return _story.screenWidth; }

int ZMStoryAdapter::getScreenHeight() const { return _story.screenHeight; }

int ZMStoryAdapter::getWindow() const { return _story.window; }

void ZMStoryAdapter::setWindow(int window) { _story.window = window; }

void ZMStoryAdapter::splitWindow(int lines) { [_story splitWindow:lines]; }

void ZMStoryAdapter::eraseWindow(int window) { [_story eraseWindow:window]; }

void ZMStoryAdapter::showStatus() { [_story showStatus]; }

void ZMStoryAdapter::inputStream(int stream) { [_story inputStream:stream]; }

void ZMStoryAdapter::outputStream(int stream) {
  [_story outputStream:stream];
  switch (stream) {
  case 1:
    screenEnabled = true;
    break;
  case -1:
    screenEnabled = false;
    break;
  }
}

void ZMStoryAdapter::getColor(int &foreground, int &background) const {
  if (screenEnabled) {
    foreground = _story.foregroundColorCode;
    background = _story.backgroundColorCode;
  }
}

void ZMStoryAdapter::setColor(int foreground, int background) {
  if (screenEnabled) {
    [_story setColorForeground:foreground background:background];
  }
}

static uint16_t trueColorFromColor(NSColor *color) {
  CGFloat r, g, b, a;
  [color getRed:&r green:&g blue:&b alpha:&a];
  uint16_t rc = static_cast<uint16_t>(31.0 * r);
  uint16_t gc = static_cast<uint16_t>(31.0 * g) << 5;
  uint16_t bc = static_cast<uint16_t>(31.0 * b) << 10;
  return bc | gc | rc;
}

void ZMStoryAdapter::getTrueColor(int &foreground, int &background) const {
  if (screenEnabled) {
    NSColor *color = [_story.foregroundColor
        colorUsingColorSpace:NSColorSpace.genericRGBColorSpace];
    foreground = trueColorFromColor(color);
    color = [_story.backgroundColor
        colorUsingColorSpace:NSColorSpace.genericRGBColorSpace];
    background = trueColorFromColor(color);
  }
}

void ZMStoryAdapter::setTrueColor(int foreground, int background) {
  if (screenEnabled)
    [_story setTrueColorForeground:foreground background:background];
}

void ZMStoryAdapter::getCursor(int &line, int &column) const {
  if (screenEnabled) {
    line = _story.line;
    column = _story.column;
  }
}

void ZMStoryAdapter::setCursor(int line, int column) {
  [_story hackyDidntSetTextStyle];
  if (screenEnabled)
    [_story setCursorLine:line column:column];
}

int ZMStoryAdapter::setFont(int font) {
  [_story hackyDidntSetTextStyle];
  if (screenEnabled) {
    int prevFontId = _story.fontId;
    _story.fontId = font;
    return prevFontId;
  } else
    return 0;
}

void ZMStoryAdapter::setTextStyle(int style) {
  if (screenEnabled) {
    [_story setTextStyle:style];
  }
}

bool ZMStoryAdapter::checkUnicode(uint16_t uc) {
  NSFont *font =
      [[Preferences sharedPreferences] fontForStyle:_story.currentStyle];
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
      [_story print:printable];
    }
  } else {
    NSLog(@"Error: Unprintable string");
  }
  [_story hackyDidntSetTextStyle];
}

void ZMStoryAdapter::printNumber(int number) {
  if (screenEnabled) {
    [_story printNumber:number];
  }
  [_story hackyDidntSetTextStyle];
}

void ZMStoryAdapter::newLine() {
  if (screenEnabled)
    [_story newLine];
  [_story hackyDidntSetTextStyle];
}

void ZMStoryAdapter::setWordWrap(bool wordWrap) {
  // nop -- word wrapping is handled by the window and is permanently
  // on at present
}

void ZMStoryAdapter::beginInput(uint8_t existingLen) {
  [_story hackyDidntSetTextStyle];
  [_story beginInputWithOffset:-existingLen];
}

std::string ZMStoryAdapter::endInput() {
  NSString *string = [_story endInput].lowercaseString;
  std::string str;
  if (string)
    str.assign(string.UTF8String);
  return str;
}

void ZMStoryAdapter::beginInputChar() {
  [_story hackyDidntSetTextStyle];
  [_story beginInputChar];
}

wchar_t ZMStoryAdapter::endInputChar() { return [_story endInputChar]; }

void ZMStoryAdapter::soundEffect(int number, int effect, int repeat,
                                 int volume) {
  [_story soundEffectNumber:number effect:effect repeat:repeat volume:volume];
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
