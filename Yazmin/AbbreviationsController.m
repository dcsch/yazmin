//
//  AbbreviationsController.m
//  Yazmin
//
//  Created by David Schweinsberg on 29/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "AbbreviationsController.h"
#import "Story.h"
#import "ZMachine.h"

@implementation AbbreviationsController

- (instancetype)init
{
    self = [super initWithWindowNibName:@"Abbreviations"];
    if (self)
    {
    }
    return self;
}


- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName
{
    NSMutableString *ms = [[NSMutableString alloc] initWithString:displayName];
    [ms appendString:@" - Abbreviations"];
    return ms;
}

- (void)windowDidLoad
{
    Story *story = self.document;
    abbreviations = [[story zMachine] abbreviations];

    tableView.dataSource = self;
}

- (id)tableView:(NSTableView *)aTableView
    objectValueForTableColumn:(NSTableColumn *)aTableColumn
            row:(NSInteger)rowIndex
{
    if ([aTableColumn.identifier isEqualTo:@"index"])
        return @(rowIndex);
    else
        return abbreviations[rowIndex];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return abbreviations.count;
}

@end
