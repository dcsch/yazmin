//
//  LibraryViewController.m
//  Yazmin
//
//  Created by David Schweinsberg on 7/12/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#import "LibraryViewController.h"
#import "AppController.h"
#import "Library.h"
#import "LibraryEntry.h"
#import "Story.h"
#import "StoryDocumentController.h"

@interface LibraryViewController () <
    NSUserInterfaceValidations, NSSearchFieldDelegate, NSTableViewDelegate> {
  IBOutlet NSTableView *tableView;
  IBOutlet NSArrayController *arrayController;
}

- (void)addStoryURLs:(NSArray<NSURL *> *)urls;
- (void)openStory:(LibraryEntry *)libraryEntry;
- (IBAction)addStoryToLibrary:(id)sender;
- (IBAction)selectStory:(id)sender;
- (IBAction)removeStory:(id)sender;
- (IBAction)searchStory:(NSSearchField *)sender;
- (IBAction)showStoryInfo:(id)sender;

@end

@implementation LibraryViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  AppController *appController = NSApp.delegate;
  self.library = appController.library;
}

- (void)viewWillAppear {
  [super viewWillAppear];

  // We don't want this window to appear in the Window menu
  self.view.window.excludedFromWindowsMenu = YES;

  // Setting this programmatically as the storyboard setting
  // doesn't appear to work
  self.view.window.windowController.windowFrameAutosaveName = @"LibraryWindow";
}

- (void)addStory:(Story *)story {
  if (![_library containsStory:story]) {
    LibraryEntry *entry =
        [[LibraryEntry alloc] initWithIFID:story.ifid url:story.fileURL];
    entry.storyMetadata = story.metadata;
    [arrayController addObject:entry];
  }
}

- (void)addStoryURLs:(NSArray<NSURL *> *)urls {
  StoryDocumentController *docController =
      NSDocumentController.sharedDocumentController;
  docController.onlyPeeking = YES;
  __block NSUInteger count = urls.count;
  for (NSURL *url in urls)
    [docController
        openDocumentWithContentsOfURL:url
                              display:NO
                    completionHandler:^(NSDocument *_Nullable document,
                                        BOOL documentWasAlreadyOpen,
                                        NSError *_Nullable error) {
                      if (!documentWasAlreadyOpen) {
                        [document close];
                      }
                      if (--count == 0)
                        docController.onlyPeeking = NO;
                    }];
}

- (void)openStory:(LibraryEntry *)libraryEntry {
  [NSDocumentController.sharedDocumentController
      openDocumentWithContentsOfURL:libraryEntry.fileURL
                            display:YES
                  completionHandler:^(NSDocument *_Nullable document,
                                      BOOL documentWasAlreadyOpen,
                                      NSError *_Nullable error) {
                    Story *story = (Story *)document;
                    if (documentWasAlreadyOpen &&
                        story.storyViewController == nil) {
                      [story makeWindowControllers];
                      [story showWindows];
                    }
                  }];
}

#pragma mark - Actions

- (IBAction)addStoryToLibrary:(id)sender {
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  panel.allowedFileTypes = @[ @"z3", @"z4", @"z5", @"z7", @"z8", @"zblorb" ];
  panel.allowsMultipleSelection = YES;
  [panel beginSheetModalForWindow:self.view.window
                completionHandler:^(NSInteger result) {
                  if (result == NSModalResponseOK) {
                    [self addStoryURLs:panel.URLs];
                  }
                }];
}

- (IBAction)selectStory:(id)sender {
  NSInteger row = tableView.clickedRow;
  if (row == -1)
    row = arrayController.selectionIndex;
  if (row != NSIntegerMax)
    [self openStory:arrayController.arrangedObjects[row]];
}

- (IBAction)removeStory:(id)sender {
  NSInteger row = tableView.clickedRow;
  if (row == -1)
    row = arrayController.selectionIndex;
  if (row != NSIntegerMax) {
    LibraryEntry *entry = arrayController.arrangedObjects[row];
    [arrayController removeObject:entry];
  }
}

- (IBAction)searchStory:(NSSearchField *)sender {
  NSString *searchTerm = sender.stringValue;
  if (searchTerm.length > 0) {
    searchTerm = [NSString stringWithFormat:@"*%@*", searchTerm];
    NSPredicate *predicate =
        [NSPredicate predicateWithFormat:@"title like[cd] %@", searchTerm];
    arrayController.filterPredicate = predicate;
  } else
    arrayController.filterPredicate = nil;
}

- (IBAction)showStoryInfo:(id)sender {
  NSInteger row = tableView.clickedRow;
  if (row == -1)
    row = arrayController.selectionIndex;
  LibraryEntry *libraryEntry = arrayController.arrangedObjects[row];

  [NSDocumentController.sharedDocumentController
      openDocumentWithContentsOfURL:libraryEntry.fileURL
                            display:NO
                  completionHandler:^(NSDocument *_Nullable document,
                                      BOOL documentWasAlreadyOpen,
                                      NSError *_Nullable error) {
                    Story *story = (Story *)document;
                    [story showStoryInfo:self];
                  }];
}

#pragma mark - NSControlTextEditingDelegate

- (BOOL)control:(NSControl *)control
               textView:(NSTextView *)textView
    doCommandBySelector:(SEL)commandSelector {

  // TODO: Replace with a segue

  if (arrayController.filterPredicate &&
      commandSelector == @selector(insertNewline:)) {
    NSArray *objects = arrayController.arrangedObjects;
    if (objects.count > 0)
      [self openStory:objects[0]];
    return YES;
  }
  return NO;
}

#pragma mark - NSUserInterfaceValidations

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item {
  if (item.action == @selector(selectStory:) ||
      item.action == @selector(removeStory:) ||
      item.action == @selector(showStoryInfo:)) {
    NSInteger row = tableView.clickedRow;
    if (row == -1)
      row = arrayController.selectionIndex;
    return row != NSIntegerMax;
  }
  return YES;
}

#pragma mark - NSTableViewDelegate Methods

- (BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row {
  return NO;
}

@end
