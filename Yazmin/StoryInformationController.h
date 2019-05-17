//
//  StoryInformationController.h
//  Yazmin
//
//  Created by David Schweinsberg on 22/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Blorb;
@class IFictionMetadata;

@interface StoryInformationController : NSWindowController {
  IBOutlet NSImageView *imageView;
  IBOutlet NSTextField *title;
  IBOutlet NSTextField *author;
  IBOutlet NSTextView *description;
  Blorb *blorb;
  IFictionMetadata *metadata;
}

- (instancetype)initWithBlorb:(Blorb *)aBlorb;

@end
