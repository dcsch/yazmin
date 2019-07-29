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
    NSUserInterfaceValidations, NSSearchFieldDelegate, NSTableViewDataSource,
    NSTableViewDelegate> {
  IBOutlet NSTableView *tableView;
  NSPredicate *filterPredicate;
  NSArray<LibraryEntry *> *sortedEntries;
}

- (void)addStoryURLs:(NSArray<NSURL *> *)urls;
- (void)openStory:(LibraryEntry *)libraryEntry;
- (void)reloadSortedData;
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
  [self reloadSortedData];
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
    [_library.entries addObject:entry];
    [self reloadSortedData];
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

- (void)reloadSortedData {
  NSArray *filteredEntries;
  if (filterPredicate)
    filteredEntries =
        [_library.entries filteredArrayUsingPredicate:filterPredicate];
  else
    filteredEntries = _library.entries;
  sortedEntries =
      [filteredEntries sortedArrayUsingDescriptors:tableView.sortDescriptors];
  [tableView reloadData];
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
    row = tableView.selectedRow;
  if (row != -1)
    [self openStory:sortedEntries[row]];
}

- (IBAction)removeStory:(id)sender {
  NSInteger row = tableView.clickedRow;
  if (row == -1)
    row = tableView.selectedRow;
  if (row != -1) {
    LibraryEntry *entry = sortedEntries[row];
    [_library.entries removeObject:entry];
    [self reloadSortedData];
  }
}

- (IBAction)searchStory:(NSSearchField *)sender {
  NSString *searchTerm = sender.stringValue;
  if (searchTerm.length > 0) {
    searchTerm = [NSString stringWithFormat:@"*%@*", searchTerm];
    NSPredicate *predicate =
        [NSPredicate predicateWithFormat:@"title like[cd] %@", searchTerm];
    filterPredicate = predicate;
  } else
    filterPredicate = nil;
  [self reloadSortedData];
}

- (IBAction)showStoryInfo:(id)sender {
  NSInteger row = tableView.clickedRow;
  if (row == -1)
    row = tableView.selectedRow;
  LibraryEntry *libraryEntry = sortedEntries[row];

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

  //  if (arrayController.filterPredicate &&
  //      commandSelector == @selector(insertNewline:)) {
  //    NSArray *objects = arrayController.arrangedObjects;
  //    if (objects.count > 0)
  //      [self openStory:objects[0]];
  //    return YES;
  //  }
  return NO;
}

#pragma mark - NSUserInterfaceValidations

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item {
  if (item.action == @selector(selectStory:) ||
      item.action == @selector(removeStory:) ||
      item.action == @selector(showStoryInfo:)) {
    NSInteger row = tableView.clickedRow;
    if (row == -1)
      row = tableView.selectedRow;
    return row != -1;
  }
  return YES;
}

#pragma mark - NSTableViewDataSource Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
  return sortedEntries.count;
}

- (void)tableView:(NSTableView *)tableView
    sortDescriptorsDidChange:(NSArray<NSSortDescriptor *> *)oldDescriptors {
  [self reloadSortedData];
}

#pragma mark - NSTableViewDelegate Methods

- (NSView *)tableView:(NSTableView *)tableView
    viewForTableColumn:(NSTableColumn *)tableColumn
                   row:(NSInteger)row {
  NSTableCellView *tableCellView = nil;
  LibraryEntry *entry = sortedEntries[row];
  if ([tableColumn.identifier isEqualToString:@"Title"]) {
    tableCellView = [tableView makeViewWithIdentifier:@"Title" owner:self];
    tableCellView.textField.stringValue = entry.title;
  } else if ([tableColumn.identifier isEqualToString:@"Author"] &&
             entry.author != nil) {
    tableCellView = [tableView makeViewWithIdentifier:@"Author" owner:self];
    tableCellView.textField.stringValue = entry.author;
  } else if ([tableColumn.identifier isEqualToString:@"Genre"] &&
             entry.genre != nil) {
    tableCellView = [tableView makeViewWithIdentifier:@"Genre" owner:self];
    tableCellView.textField.stringValue = entry.genre;
  } else if ([tableColumn.identifier isEqualToString:@"Group"] &&
             entry.group != nil) {
    tableCellView = [tableView makeViewWithIdentifier:@"Group" owner:self];
    tableCellView.textField.stringValue = entry.group;
  } else if ([tableColumn.identifier isEqualToString:@"FirstPublished"] &&
             entry.firstPublished != nil) {
    tableCellView =
        [tableView makeViewWithIdentifier:@"FirstPublished" owner:self];
    tableCellView.textField.stringValue = entry.firstPublished;
  }
  return tableCellView;
}

- (BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row {
  return NO;
}

@end
