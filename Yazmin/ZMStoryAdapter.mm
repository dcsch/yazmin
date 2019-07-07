
#import "ZMStoryAdapter.h"
#import "Preferences.h"
#import "Story.h"

ZMStoryAdapter::ZMStoryAdapter(Story *story) : _story(story) {}

int ZMStoryAdapter::getScreenWidth() const { return _story.screenWidth; }

int ZMStoryAdapter::getScreenHeight() const { return _story.screenHeight; }

void ZMStoryAdapter::setWindow(int window) { _story.window = window; }

void ZMStoryAdapter::splitWindow(int lines) { [_story splitWindow:lines]; }

void ZMStoryAdapter::eraseWindow(int window) { [_story eraseWindow:window]; }

void ZMStoryAdapter::eraseLine() { [_story eraseLine]; }

void ZMStoryAdapter::showStatus() { [_story showStatus]; }

void ZMStoryAdapter::inputStream(int stream) { [_story inputStream:stream]; }

void ZMStoryAdapter::outputStream(int stream) { [_story outputStream:stream]; }

void ZMStoryAdapter::getColor(int &foreground, int &background) const {
  foreground = _story.foregroundColorCode;
  background = _story.backgroundColorCode;
}

void ZMStoryAdapter::setColor(int foreground, int background) {
  [_story setColorForeground:foreground background:background];
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
  NSColor *color = [_story.foregroundColor
      colorUsingColorSpace:NSColorSpace.genericRGBColorSpace];
  foreground = trueColorFromColor(color);
  color = [_story.backgroundColor
      colorUsingColorSpace:NSColorSpace.genericRGBColorSpace];
  background = trueColorFromColor(color);
}

void ZMStoryAdapter::setTrueColor(int foreground, int background) {
  [_story setTrueColorForeground:foreground background:background];
}

void ZMStoryAdapter::getCursor(int &line, int &column) const {
  line = _story.line;
  column = _story.column;
}

void ZMStoryAdapter::setCursor(int line, int column) {
  [_story hackyDidntSetTextStyle];
  [_story setCursorLine:line column:column];
}

int ZMStoryAdapter::setFont(int font) {
  NSLog(@"setFont: %d", font);
  [_story hackyDidntSetTextStyle];
  int prevFontId = _story.fontId;
  _story.fontId = font;
  return prevFontId;
}

void ZMStoryAdapter::setTextStyle(int style) { [_story setTextStyle:style]; }

bool ZMStoryAdapter::checkUnicode(uint16_t uc) {
  int style = _story.window == 1 ? 8 : 0;
  NSFont *font =
      [[Preferences sharedPreferences] fontForStyle:_story.currentStyle | style];
  NSCharacterSet *charSet = font.coveredCharacterSet;
//  NSLog(@"checkUnicode: font name: %@", font.displayName);
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
    [_story print:printable];
  } else {
    NSLog(@"Error: Unprintable string");
  }
  [_story hackyDidntSetTextStyle];
}

void ZMStoryAdapter::printNumber(int number) {
  [_story printNumber:number];
  [_story hackyDidntSetTextStyle];
}

void ZMStoryAdapter::newLine() {
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
  [_story startTime:time routine:routine];
}

void ZMStoryAdapter::stopTimedRoutine() { [_story stopTimedRoutine]; }

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
