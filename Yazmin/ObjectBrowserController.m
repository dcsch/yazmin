//
//  ObjectBrowserController.m
//  Yazmin
//
//  Created by David Schweinsberg on 22/10/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "ObjectBrowserController.h"
#import "Story.h"
#import "ZMachine.h"
#import "DebugInfo.h"

@implementation ObjectBrowserController

- (id)init
{
    self = [super initWithWindowNibName:@"ObjectBrowser"];
    if (self)
    {
        selectedObject = 0;
    }
    return self;
}


- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName
{
    NSMutableString *ms = [[NSMutableString alloc] initWithString:displayName];
    [ms appendString:@" - Object Browser"];
    return ms;
}

- (void)windowDidLoad
{
}

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    Story *story = [self document];
    return [[story zMachine] numberOfChildrenOfObject:item == nil ? 0 : [item intValue]];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    Story *story = [self document];
    return [[story zMachine] numberOfChildrenOfObject:item == nil ? 0 : [item intValue]];
}

- (id)outlineView:(NSOutlineView *)outlineView
            child:(int)index
           ofItem:(id)item
{
    Story *story = [self document];
    int obj = [[story zMachine] child:index ofObject:item == nil ? 0 : [item intValue]];
    return @(obj);
}

- (id)outlineView:(NSOutlineView *)outlineView
    objectValueForTableColumn:(NSTableColumn *)tableColumn
           byItem:(id)item
{
    Story *story = [self document];
    NSString *name = nil;
    if ([story debugInfo])
        name = [[story debugInfo] objectNames][item];

    if (!name)
        name = [[story zMachine] nameOfObject:[item intValue]];
    
    if (name)
        return [NSString stringWithFormat:@"%@ (%@)", name, item];
    else
        return [NSString stringWithFormat:@"(%@)", item];
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    selectedObject = [[outlineView itemAtRow:[outlineView selectedRow]] intValue];
    [propView reloadData];
    NSLog(@"Selected object: %d", selectedObject);
}

- (id)tableView:(NSTableView *)aTableView
    objectValueForTableColumn:(NSTableColumn *)aTableColumn
            row:(int)rowIndex
{
    if (selectedObject > 0)
    {
        Story *story = [self document];
        if ([[aTableColumn identifier] isEqualTo:@"property"])
        {
            int prop = [[story zMachine] property:rowIndex ofObject:selectedObject];
            NSString *propName = nil;
            if ([story debugInfo] && (prop > -1))
                propName = [[story debugInfo] propertyNames][@(prop)];
            if (propName == nil)
                propName = [NSString stringWithFormat:@"[%d]", prop];
            return propName;
        }
        else
            return [[story zMachine] propertyData:rowIndex ofObject:selectedObject];
    }
    return nil;
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if (selectedObject > 0)
    {
        Story *story = [self document];
        return [[story zMachine] numberOfPropertiesOfObject:selectedObject];
    }
    return 0;
}

- (void)update
{
    // Note the currently selected item
    NSNumber *selectedItem = [outlineView itemAtRow:[outlineView selectedRow]];

    // Go through all the top-level items and reload the lot
    int i;
    for (i = 0; i < [outlineView numberOfRows]; ++i)
    {
        id item = [outlineView itemAtRow:i];
        if ([outlineView levelForItem:item] != 0)
            continue;
        [outlineView reloadItem:item reloadChildren:YES];
    }

    // Find the selected item (if possible -- it may now be in an unexpanded
    // node)
    for (i = 0; i < [outlineView numberOfRows]; ++i)
    {
        NSNumber *item = [outlineView itemAtRow:i];
        if ([item isEqualToNumber:selectedItem])
        {
            [outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:i]
                     byExtendingSelection:NO];
            break;
        }
    }
    
    // Make sure the current selection is up to date
    selectedObject = [[outlineView itemAtRow:[outlineView selectedRow]] intValue];
    [propView reloadData];
}

@end
