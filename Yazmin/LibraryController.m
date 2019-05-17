//
//  LibraryController.m
//  Yazmin
//
//  Created by David Schweinsberg on 23/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "LibraryController.h"
#import "Library.h"
#import "LibraryEntry.h"
#import "AppController.h"

@implementation LibraryController

- (instancetype)init
{
    self = [super initWithWindowNibName:@"Library"];
    if (self)
    {
        AppController *app = NSApp.delegate;
        library = app.library;

        // We don't want this window to appear in the Windows menu
        [self.window setExcludedFromWindowsMenu:YES];

//        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
//                                                             NSUserDomainMask,
//                                                             NO);
//        NSLog(@"Paths: %@", paths);
    }
    return self;
}


- (void)playStory
{
    NSInteger row = tableView.selectedRow;
    if (row >= 0)
    {
        LibraryEntry *entry = library.entries[row];
        [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:entry.fileURL
                                                                               display:YES
                                                                     completionHandler:^(NSDocument * _Nullable document, BOOL documentWasAlreadyOpen, NSError * _Nullable error) {
        }];
    }
}

//- (void)update
//{
//    [tableView reloadData];
//}

- (void)windowDidLoad
{
//    [tableView setDataSource:self];
//    [tableView setTarget:self];
//    [tableView setDoubleAction:@selector(playStory)];
}

//- (id)tableView:(NSTableView *)aTableView
//    objectValueForTableColumn:(NSTableColumn *)aTableColumn
//            row:(int)rowIndex
//{
//    if ([[aTableColumn identifier] isEqualTo:@"title"])
//    {
//        LibraryEntry *entry = [[library entries] objectAtIndex:rowIndex];
//        return [entry title];
//    }
//    return nil;
//}
//
//- (int)numberOfRowsInTableView:(NSTableView *)aTableView
//{
//    return [[library entries] count];
//}
//
//- (void)tableView:(NSTableView *)aTableView
//sortDescriptorsDidChange:(NSArray *)oldDescriptors
//{
//    NSArray *newDescriptors = [tableView sortDescriptors];
//    [[library entries] sortUsingDescriptors:newDescriptors];
//    [tableView reloadData];
//}

@end
