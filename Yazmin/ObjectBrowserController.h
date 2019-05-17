//
//  ObjectBrowserController.h
//  Yazmin
//
//  Created by David Schweinsberg on 22/10/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ObjectBrowserController : NSWindowController {
  IBOutlet NSOutlineView *outlineView;
  IBOutlet NSTableView *propView;
  int selectedObject;
}

- (void)update;

@end
