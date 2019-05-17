//
//  DebugController.h
//  Yazmin
//
//  Created by David Schweinsberg on 24/08/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RoutineDebugRecord;

@interface DebugController : NSWindowController {
  IBOutlet NSTableView *callStackView;
  IBOutlet NSOutlineView *variableView;
  IBOutlet NSTextView *sourceView;
  RoutineDebugRecord *selectedRoutine;
}

//- (void)dumpMemory;

@end
