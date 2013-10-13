//
//  DebugController.m
//  Yazmin
//
//  Created by David Schweinsberg on 24/08/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "DebugController.h"
#import "Story.h"
#import "ZMachine.h"
#import "DebugInfo.h"
#import "RoutineDebugRecord.h"

@implementation DebugController

- (id)init
{
    self = [super initWithWindowNibName:@"Debug"];
    if (self)
    {
    }
    return self;
}


- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName
{
    NSMutableString *ms = [[NSMutableString alloc] initWithString:displayName];
    [ms appendString:@" - Debugger"];
    return ms;
}

- (void)windowDidLoad
{
//    [self dumpMemory];
//    
//    // Font has to be set after there is some text in the window
//    NSFont *font = [NSFont fontWithName:@"Courier" size:12];
//    [memoryView setFont:font];
}

- (id)tableView:(NSTableView *)aTableView
    objectValueForTableColumn:(NSTableColumn *)aTableColumn
            row:(int)rowIndex
{
    Story *story = [self document];
    if ([[aTableColumn identifier] isEqualTo:@"index"])
        return @(rowIndex);
    else
    {
        // Get a routine name from debug info if possible, otherwise
        // show the routine address
        NSUInteger addr = [[story zMachine] routineAddressForFrame:rowIndex];
        NSString *name = nil;
        if (addr == 0)
            name = @"(Entry Point)";
        else if ([story debugInfo])
        {
            addr -= [[story zMachine] baseHighMemory];
            RoutineDebugRecord *routine = [[story debugInfo] routines][@(addr)];
            name = [routine name];
        }
        else
            name = [NSString stringWithFormat:@"%05lx", (unsigned long)addr];
        return name;
    }
    return nil;
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    Story *story = [self document];
    return [[story zMachine] numberOfFrames];
}

- (NSUInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (selectedRoutine)
        return [[selectedRoutine localNames] count];
    return 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView
            child:(int)index
           ofItem:(id)item
{
    if (selectedRoutine)
        return [selectedRoutine localNames][index];
    return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView
    objectValueForTableColumn:(NSTableColumn *)tableColumn
           byItem:(id)item
{
    if ([[tableColumn identifier] isEqualTo:@"name"])
        return item;
    else
    {
        Story *story = [self document];
        NSUInteger index = [[selectedRoutine localNames] indexOfObject:item];
        NSInteger rowIndex = [callStackView selectedRow];
        NSUInteger localValue = [[story zMachine] localAtIndex:index forFrame:rowIndex];
        return @(localValue);
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    Story *story = [self document];
    NSInteger rowIndex = [callStackView selectedRow];
    selectedRoutine = nil;
    if (rowIndex > -1)
    {
        NSUInteger addr = [[story zMachine] routineAddressForFrame:rowIndex];
        if ([story debugInfo])
        {
            addr -= [[story zMachine] baseHighMemory];
            selectedRoutine = [[story debugInfo] routines][@(addr)];
        }
    }
    [variableView reloadData];
    NSLog(@"Selected routine: %@", [selectedRoutine name]);
}

//- (void)dumpMemory
//{
//    Story *story = [self document];
//    unsigned char *memory = [[story zMachine] memory];
//    int memorySize = [[story zMachine] memorySize];
//    int i;
//    for (i = 0; i < memorySize; i+=8)
//    {
//        NSString *s = [NSString stringWithFormat:@"%05x %02x %02x %02x %02x %02x %02x %02x %02x\n",
//            i, memory[i], memory[i+1], memory[i+2], memory[i+3],
//            memory[i+4], memory[i+5], memory[i+6], memory[i+7]];
//        [[[memoryView textStorage] mutableString] appendString:s];
//    }
//}

@end
