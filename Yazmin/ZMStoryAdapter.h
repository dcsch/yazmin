
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

  void print(const std::string &str) override;

  void printNumber(int number) override;

  void newLine() override;

  void setWordWrap(bool wordWrap) override;

  void beginInput(uint8_t existingLen) override;

  size_t endInput(char *str, size_t maxLen) override;

  void beginInputChar() override;

  char endInputChar() override;

  void startTimedRoutine(int time, int routine) override;

  void stopTimedRoutine() override;

  void beginRestore() const override;

  uint16_t endRestore(const uint8_t **data, size_t *length) const override;

  void save(const uint8_t *data, size_t length) const override;

  uint16_t getRestoreOrSaveResult() override;

private:
  Story *_story;
  StoryFacet *_storyFacet;
  NSTimer *timer;
  bool screenEnabled;
  bool transcriptEnabled;
};
