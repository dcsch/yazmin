//
//  LibraryViewController.m
//  Yazmin
//
//  Created by David Schweinsberg on 7/12/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#import "LibraryViewController.h"
#import "AppController.h"
#import "BibliographicViewController.h"
#import "IFBibliographic.h"
#import "IFDB.h"
#import "IFDBService.h"
#import "IFStory.h"
#import "IFictionMetadata.h"
#import "Library.h"
#import "LibraryEntry.h"
#import "Story.h"
#import "StoryDocumentController.h"

@interface LibraryViewController () <
    NSUserInterfaceValidations, NSTableViewDataSource, NSTableViewDelegate> {
  IBOutlet NSTableView *tableView;
  IFDBService *ifdbService;
}

- (void)addStoryURLs:(NSArray<NSURL *> *)urls;
- (void)reloadSortedData;
- (IBAction)addStoryToLibrary:(id)sender;
- (IBAction)selectStory:(id)sender;
- (IBAction)removeStory:(id)sender;
- (IBAction)searchStory:(NSSearchField *)sender;
- (IBAction)showStoryInfo:(id)sender;
- (IBAction)fetchMetadata:(id)sender;

- (void)handleMetadataChanged:(NSNotification *)note;

@end

@implementation LibraryViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  AppController *appController = NSApp.delegate;
  self.library = appController.library;
  [tableView registerForDraggedTypes:@[ NSPasteboardTypeFileURL ]];
  [self reloadSortedData];

  NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
  [nc addObserver:self
         selector:@selector(handleMetadataChanged:)
             name:SMMetadataChangedNotification
           object:nil];

  ifdbService = [[IFDBService alloc] init];
}

- (void)viewWillAppear {
  [super viewWillAppear];

  // We don't want this window to appear in the Window menu
  self.view.window.excludedFromWindowsMenu = YES;

  // Setting this programmatically as the storyboard setting
  // doesn't appear to work
  self.view.window.windowController.windowFrameAutosaveName = @"LibraryWindow";
}

- (void)viewDidAppear {
  
  // If the library is empty, give the user sn option to add the built-in
  // stories to library
  if (_library.entries.count == 0) {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Starter Library";
    alert.informativeText = @"Would you like to add a selection of stories to start your collection?";
    [alert addButtonWithTitle:@"Yes Please"];
    [alert addButtonWithTitle:@"No Thanks"];
//    alert.showsSuppressionButton = YES;
    [alert beginSheetModalForWindow:self.view.window
                  completionHandler:^(NSModalResponse returnCode) {
      if (returnCode == NSAlertFirstButtonReturn) {
        NSArray<NSString *> *exts = @[@"z5", @"z8", @"zblorb"];
        NSMutableArray<NSURL *> *urls = [NSMutableArray array];
        NSBundle *bundle = NSBundle.mainBundle;
        for (NSString *ext in exts) {
          [urls addObjectsFromArray:[bundle URLsForResourcesWithExtension:ext
                                                             subdirectory:@"stories"]];
        }
        [self addStoryURLs:urls];
        dispatch_async(dispatch_get_main_queue(), ^{
          for (LibraryEntry *entry  in self->_library.entries) {
            [self fetchMetadataForLibraryEntry:entry];
          }
        });
      }
    }];
  }
}

- (void)addStory:(Story *)story {
  if (![_library containsStory:story]) {
    LibraryEntry *entry =
        [[LibraryEntry alloc] initWithStoryMetadata:story.metadata];
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
                    } else if (error) {
                      [self libraryEntry:libraryEntry alertWithError:error];
                    }
                  }];
}

- (void)reloadSortedData {
  NSArray *filteredEntries;
  if (_filterPredicate)
    filteredEntries =
        [_library.entries filteredArrayUsingPredicate:_filterPredicate];
  else
    filteredEntries = _library.entries;
  _sortedEntries =
      [filteredEntries sortedArrayUsingDescriptors:tableView.sortDescriptors];
  [tableView reloadData];
}

- (void)libraryEntry:(LibraryEntry *)libraryEntry
      alertWithError:(NSError *)error {
  NSAlert *alert = [NSAlert alertWithError:error];
  [alert addButtonWithTitle:@"OK"];
  [alert addButtonWithTitle:@"Remove Entry"];
  [alert beginSheetModalForWindow:self.view.window
                completionHandler:^(NSModalResponse returnCode) {
                  if (returnCode == NSAlertSecondButtonReturn) {
                    [self->_library deleteImageForIFID:libraryEntry.ifid];
                    [self->_library.entries removeObject:libraryEntry];
                    [self reloadSortedData];
                  }
                }];
}

- (void)fetchMetadataForLibraryEntry:(LibraryEntry *)libraryEntry {
  [ifdbService fetchRecordForIFID:libraryEntry.ifid
                completionHandler:^(NSData *data) {
                  IFictionMetadata *metadata =
                      [[IFictionMetadata alloc] initWithData:data];
                  if (metadata.stories.count > 0) {
                    IFStory *story = metadata.stories.firstObject;
                    [libraryEntry updateFromStory:story];
                    if (story.ifdb.coverArt) {

                      // IFDB image links are provided as HTTP, which does
                      // not conform to ATS policy, so reform it as HTTPS
                      NSURLComponents *components = [NSURLComponents
                                componentsWithURL:story.ifdb.coverArt
                          resolvingAgainstBaseURL:YES];
                      components.scheme = @"https";
                      [self->_library fetchImageForIFID:libraryEntry.ifid
                                                    URL:components.URL];
                    }
                    NSNotificationCenter *nc =
                        NSNotificationCenter.defaultCenter;
                    [nc postNotificationName:SMMetadataChangedNotification
                                      object:self];
                  }
                }];
}

#pragma mark - Actions

- (IBAction)addStoryToLibrary:(id)sender {
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  panel.allowedFileTypes = [AllowedFileTypes copy];
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
    [self openStory:_sortedEntries[row]];
}

- (IBAction)removeStory:(id)sender {
  NSIndexSet *selectedRowIndexes = tableView.selectedRowIndexes;

  // If the clicked row is not within the selection set, then perform this
  // action only on the clicked row
  if (tableView.clickedRow != -1 &&
      ![selectedRowIndexes containsIndex:tableView.clickedRow]) {
    selectedRowIndexes = [NSIndexSet indexSetWithIndex:tableView.clickedRow];
  }

  [selectedRowIndexes
      enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *_Nonnull stop) {
        LibraryEntry *libraryEntry = self->_sortedEntries[idx];
        [self->_library deleteImageForIFID:libraryEntry.ifid];
        [self->_library.entries removeObject:libraryEntry];
      }];
  [self reloadSortedData];
}

- (IBAction)searchStory:(NSSearchField *)sender {
  NSString *searchTerm = sender.stringValue;
  if (searchTerm.length > 0) {
    searchTerm = [NSString stringWithFormat:@"*%@*", searchTerm];
    NSPredicate *predicate =
        [NSPredicate predicateWithFormat:@"title like[cd] %@", searchTerm];
    _filterPredicate = predicate;
  } else
    _filterPredicate = nil;
  [self reloadSortedData];
}

- (IBAction)showStoryInfo:(id)sender {
  NSInteger row = tableView.clickedRow;
  if (row == -1)
    row = tableView.selectedRow;
  LibraryEntry *libraryEntry = _sortedEntries[row];

  [NSDocumentController.sharedDocumentController
      openDocumentWithContentsOfURL:libraryEntry.fileURL
                            display:NO
                  completionHandler:^(NSDocument *_Nullable document,
                                      BOOL documentWasAlreadyOpen,
                                      NSError *_Nullable error) {
                    if (document) {
                      Story *story = (Story *)document;
                      [story showStoryInfo:self];
                    } else if (error) {
                      [self libraryEntry:libraryEntry alertWithError:error];
                    }
                  }];
}

- (IBAction)fetchMetadata:(id)sender {
  NSIndexSet *selectedRowIndexes = tableView.selectedRowIndexes;

  // If the clicked row is not within the selection set, then perform this
  // action only on the clicked row
  if (tableView.clickedRow != -1 &&
      ![selectedRowIndexes containsIndex:tableView.clickedRow]) {
    selectedRowIndexes = [NSIndexSet indexSetWithIndex:tableView.clickedRow];
  }

  [selectedRowIndexes
      enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *_Nonnull stop) {
        [self fetchMetadataForLibraryEntry:_sortedEntries[idx]];
      }];
}

- (IBAction)useBlorbMetadata:(id)sender {
  NSMutableArray<NSURL *> *urls = [NSMutableArray array];
  NSIndexSet *selectedRowIndexes = tableView.selectedRowIndexes;
  [selectedRowIndexes
      enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *_Nonnull stop) {
        LibraryEntry *libraryEntry = _sortedEntries[idx];
        [urls addObject:libraryEntry.fileURL];
        [_library deleteImageForIFID:libraryEntry.ifid];
        [_library.entries removeObject:libraryEntry];
      }];
  [self addStoryURLs:urls];
  NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
  [nc postNotificationName:SMMetadataChangedNotification object:self];
}

#pragma mark - Notifications

- (void)handleMetadataChanged:(NSNotification *)note {
  [self reloadSortedData];
}

#pragma mark - NSUserInterfaceValidations

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item {
  if (item.action == @selector(selectStory:) ||
      item.action == @selector(removeStory:) ||
      item.action == @selector(showStoryInfo:) ||
      item.action == @selector(fetchMetadata:) ||
      item.action == @selector(useBlorbMetadata:)) {
    NSInteger row = tableView.clickedRow;
    if (row == -1)
      row = tableView.selectedRow;
    return row != -1;
  }
  return YES;
}

#pragma mark - NSTableViewDataSource Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
  return _sortedEntries.count;
}

- (BOOL)tableView:(NSTableView *)tableView
       acceptDrop:(id<NSDraggingInfo>)info
              row:(NSInteger)row
    dropOperation:(NSTableViewDropOperation)dropOperation {
  NSPasteboard *pb = info.draggingPasteboard;
  NSURL *url = [NSURL URLFromPasteboard:pb];
  [self addStoryURLs:@[ url ]];
  return YES;
}

- (NSDragOperation)tableView:(NSTableView *)tableView
                validateDrop:(id<NSDraggingInfo>)info
                 proposedRow:(NSInteger)row
       proposedDropOperation:(NSTableViewDropOperation)dropOperation {
  NSPasteboard *pb = info.draggingPasteboard;
  if ([pb.types containsObject:NSPasteboardTypeFileURL]) {
    NSURL *url = [NSURL URLFromPasteboard:pb];
    NSString *path = url.path;
    if ([AllowedFileTypes containsObject:path.pathExtension])
      return NSDragOperationLink;
  }
  return NSDragOperationNone;
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
  LibraryEntry *entry = _sortedEntries[row];
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
    tableCellView = [tableView makeViewWithIdentifier:@"FirstPublished"
                                                owner:self];
    tableCellView.textField.stringValue = entry.firstPublished;
  }
  return tableCellView;
}

- (BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row {
  return NO;
}

@end
