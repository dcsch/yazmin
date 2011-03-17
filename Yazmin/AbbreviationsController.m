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

- (id)init
{
    self = [super initWithWindowNibName:@"Abbreviations"];
    if (self)
    {
    }
    return self;
}

- (void)dealloc
{
    [abbreviations release];
    [super dealloc];
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName
{
    NSMutableString *ms = [[NSMutableString alloc] initWithString:displayName];
    [ms appendString:@" - Abbreviations"];
    return ms;
}

- (void)windowDidLoad
{
    Story *story = [self document];
    abbreviations = [[story zMachine] abbreviations];
    [abbreviations retain];

    [tableView setDataSource:self];
}

- (id)tableView:(NSTableView *)aTableView
    objectValueForTableColumn:(NSTableColumn *)aTableColumn
            row:(int)rowIndex
{
    if ([[aTableColumn identifier] isEqualTo:@"index"])
        return [NSNumber numberWithInt:rowIndex];
    else
        return [abbreviations objectAtIndex:rowIndex];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [abbreviations count];
}

@end
