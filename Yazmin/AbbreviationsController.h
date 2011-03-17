//
//  AbbreviationsController.h
//  Yazmin
//
//  Created by David Schweinsberg on 29/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AbbreviationsController : NSWindowController <NSTableViewDataSource>
{
    IBOutlet NSTableView *tableView;
    NSArray *abbreviations;
}

@end
