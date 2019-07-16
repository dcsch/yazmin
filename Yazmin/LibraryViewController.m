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
- (IBAction)showStoryInfo:(id)sender;
- (void)prepareInformationWindowController:
            (NSWindowController *)windowController
                                   withRow:(NSInteger)row;

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
}

- (void)addStory:(Story *)story {
  if (![_library containsStory:story]) {
    LibraryEntry *entry =
        [[LibraryEntry alloc] initWithIFID:story.ifid url:story.fileURL];
    entry.storyMetadata = story.metadata;
    [arrayController addObject:entry];
  }
}

- (void)prepareInformationWindowController:
            (NSWindowController *)windowController
                                   withRow:(NSInteger)row {
  LibraryEntry *entry = arrayController.arrangedObjects[row];
  NSImage *picture = nil;

  windowController.window.representedURL = entry.fileURL;

  // Is this a blorb we can pull data from?
  if ([Blorb isBlorbURL:entry.fileURL]) {
    NSData *data = [NSData dataWithContentsOfURL:entry.fileURL];
    if (data && [Blorb isBlorbData:data]) {
      Blorb *blorb = [[Blorb alloc] initWithData:data];
      picture = [[NSImage alloc] initWithData:blorb.pictureData];
    }
  }

  // Fish through all the controllers
  NSTabViewController *tabViewController =
      (NSTabViewController *)windowController.contentViewController;
  InformationViewController *infoViewController =
      (InformationViewController *)tabViewController.tabViewItems[0]
          .viewController;
  infoViewController.storyMetadata = entry.storyMetadata;
  infoViewController.picture = picture;

  NSViewController *artViewController =
      tabViewController.tabViewItems[1].viewController;
  artViewController.representedObject = picture;
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSStoryboardSegueIdentifier)identifier
                                  sender:(id)sender {
  if ([identifier isEqualToString:@"Information"]) {
    NSInteger row = tableView.clickedRow;
    if (row == -1)
      row = arrayController.selectionIndex;
    if (row != NSIntegerMax) {

      // Is this info window already open?
      // (There can be multiple info windows, but we want only one for each
      // story)
      LibraryEntry *entry = arrayController.arrangedObjects[row];
      for (NSWindow *window in NSApp.windows) {
        if ([window.windowController.contentViewController
                isKindOfClass:NSTabViewController.class] &&
            [window.representedURL isEqualTo:entry.fileURL]) {
          [window makeKeyAndOrderFront:self];
          return NO;
        }
      }
      return YES;
    } else
      return NO;
  }
  return YES;
}

- (void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender {
  if ([segue.identifier isEqualToString:@"Information"]) {
    NSInteger row = tableView.clickedRow;
    if (row == -1)
      row = arrayController.selectionIndex;
    [self prepareInformationWindowController:segue.destinationController
                                     withRow:row];
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

- (IBAction)showStoryInfo:(id)sender {
  [self performSegueWithIdentifier:@"Information" sender:self];
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

@end
