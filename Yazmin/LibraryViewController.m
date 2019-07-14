//
//  LibraryViewController.m
//  Yazmin
//
//  Created by David Schweinsberg on 7/12/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#import "LibraryViewController.h"
#import "AppController.h"
#import "Blorb.h"
#import "IFBibliographic.h"
#import "IFStory.h"
#import "InformationViewController.h"
#import "Library.h"
#import "LibraryEntry.h"
#import "Story.h"

@interface LibraryViewController () <NSMenuItemValidation,
                                     NSSearchFieldDelegate> {
  IBOutlet NSTableView *tableView;
  IBOutlet NSArrayController *arrayController;
}

- (void)openStory:(LibraryEntry *)libraryEntry;
- (IBAction)selectStory:(id)sender;
- (IBAction)removeStory:(id)sender;
- (IBAction)searchStory:(NSSearchField *)sender;

@end

@implementation LibraryViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  AppController *appController = NSApp.delegate;
  self.library = appController.library;

  // We don't want this window to appear in the Windows menu
  self.view.window.excludedFromWindowsMenu = YES;
}

- (void)addStory:(Story *)story {
  if (![_library containsStory:story]) {
    LibraryEntry *entry =
        [[LibraryEntry alloc] initWithIFID:story.ifid url:story.fileURL];
    entry.storyMetadata = story.metadata;
    [arrayController addObject:entry];
  }
}

- (void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender {
  if ([segue.identifier isEqualToString:@"Information"]) {
    NSInteger row = tableView.clickedRow;
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

    // Fish through all the controllers
    NSWindowController *windowController = segue.destinationController;
    NSTabViewController *tabViewController =
        (NSTabViewController *)windowController.contentViewController;
    InformationViewController *infoViewController =
        (InformationViewController *)tabViewController.tabViewItems[0]
            .viewController;
    infoViewController.storyMetadata = entry.storyMetadata;
    infoViewController.pictureData = pictureData;
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

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
  NSInteger row = tableView.clickedRow;
  if (row > -1) {
    return YES;
  }
  return NO;
}

@end
