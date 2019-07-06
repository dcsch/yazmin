//
//  LibraryController.m
//  Yazmin
//
//  Created by David Schweinsberg on 23/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "LibraryController.h"
#import "Blorb.h"
#import "IFBibliographic.h"
#import "IFStory.h"
#import "Library.h"
#import "LibraryEntry.h"
#import "Story.h"
#import "StoryInformationController.h"

@interface LibraryController () <NSMenuItemValidation, NSSearchFieldDelegate> {
  IBOutlet NSTableView *tableView;
  IBOutlet NSArrayController *arrayController;
  IBOutlet NSSearchField *searchField;
  Library *library;
}

- (void)openStory:(LibraryEntry *)libraryEntry;
- (IBAction)selectStory:(id)sender;
- (IBAction)showStoryInfo:(id)sender;
- (IBAction)removeStory:(id)sender;
- (IBAction)searchStory:(id)sender;

@end

@implementation LibraryController

- (instancetype)initWithLibrary:(Library *)aLibrary {
  self = [super initWithWindowNibName:@"Library"];
  if (self) {
    library = aLibrary;

    // We don't want this window to appear in the Windows menu
    self.window.excludedFromWindowsMenu = YES;
  }
  return self;
}

- (void)addStory:(Story *)story {
  if (![library containsStory:story]) {
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
                                      NSError *_Nullable error){
                  }];
}

- (IBAction)selectStory:(id)sender {
  NSInteger row = tableView.clickedRow;
  if (row > -1)
    [self openStory:arrayController.arrangedObjects[row]];
}

- (IBAction)showStoryInfo:(id)sender {
  NSInteger row = tableView.clickedRow;
  if (row > -1) {
    LibraryEntry *entry = arrayController.arrangedObjects[row];
    NSData *pictureData = nil;

    // Is this a blorb we can pull data from?
    if ([Blorb isBlorbURL:entry.fileURL]) {
      NSData *data = [NSData dataWithContentsOfURL:entry.fileURL];
      if (data && [Blorb isBlorbData:data]) {
        Blorb *blorb = [[Blorb alloc] initWithData:data];
        pictureData = blorb.pictureData;
      }
    }

    StoryInformationController *infoController =
        [[StoryInformationController alloc]
            initWithStoryMetadata:entry.storyMetadata
                      pictureData:pictureData];
    [self.document addWindowController:infoController];
    [infoController showWindow:self];
  }
}

- (IBAction)removeStory:(id)sender {
  NSInteger row = tableView.clickedRow;
  if (row > -1) {
    LibraryEntry *entry = arrayController.arrangedObjects[row];
    [arrayController removeObject:entry];
  }
}

- (IBAction)searchStory:(id)sender {
  NSString *searchTerm = searchField.stringValue;
  if (searchTerm.length > 0) {
    searchTerm = [NSString stringWithFormat:@"*%@*", searchTerm];
    NSPredicate *predicate =
        [NSPredicate predicateWithFormat:@"title like[cd] %@", searchTerm];
    arrayController.filterPredicate = predicate;
  } else
    arrayController.filterPredicate = nil;
}

- (BOOL)control:(NSControl *)control
               textView:(NSTextView *)textView
    doCommandBySelector:(SEL)commandSelector {
  if (arrayController.filterPredicate &&
      commandSelector == @selector(insertNewline:)) {
    NSArray *objects = arrayController.arrangedObjects;
    if (objects.count > 0)
      [self openStory:objects[0]];
    return YES;
  }
  return NO;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
  NSInteger row = tableView.clickedRow;
  if (row > -1) {
    return YES;
  }
  return NO;
}

@end
