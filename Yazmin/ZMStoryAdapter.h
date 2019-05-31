
#include "ZMIO.h"

@class Story;
@class StoryFacet;

class ZMStoryAdapter : public ZMIO {
public:
  ZMStoryAdapter(Story *story);

  ~ZMStoryAdapter() override;

  void setWindow(int window) override;

  void splitWindow(int lines) override;

  void eraseWindow(int window) override;

  void showStatus() override;

  void outputStream(int stream) override;

  void setColor(int foreground, int background) override;

  void setCursor(int line, int column) override;

  int setFont(int font) override;

  void setTextStyle(int style) override;

  void print(const char *str) override;

  void printNumber(int number) override;

  void newLine() override;

  void setWordWrap(bool wordWrap) override;

  void beginInput() override;

  size_t endInput(char *str, size_t maxLen) override;

  void beginInputChar() override;

  char endInputChar() override;

  void startTimedRoutine(int time, int routine) override;

  void stopTimedRoutine() override;

  void restore(const void **data, size_t *length) override;

  void save(const void *data, size_t length) override;

  uint16_t getRestoreOrSaveResult() override;

private:
  Story *_story;
  StoryFacet *_storyFacet;
  NSTimer *timer;
  bool screenEnabled;
  bool transcriptEnabled;
};
