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

@interface LibraryViewController () <
    NSMenuItemValidation, NSSearchFieldDelegate, NSTableViewDelegate> {
  IBOutlet NSTableView *tableView;
  IBOutlet NSArrayController *arrayController;
}

- (void)openStory:(LibraryEntry *)libraryEntry;
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

- (IBAction)selectStory:(id)sender {
  NSInteger row = tableView.clickedRow;
  if (row > -1)
    [self openStory:arrayController.arrangedObjects[row]];
}

- (IBAction)removeStory:(id)sender {
  NSInteger row = tableView.clickedRow;
  if (row > -1) {
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

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item {
  if (item.action == @selector(showStoryInfo:)) {
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
