//
//  SummaryViewController.m
//  Yazmin
//
//  Created by David Schweinsberg on 7/13/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#import "SummaryViewController.h"
#import "Blorb.h"
#import "IFBibliographic.h"
#import "IFStory.h"
#import "Story.h"

@interface SummaryViewController () {
  IBOutlet NSImageView *imageView;
  IBOutlet NSTextField *titleTextField;
  IBOutlet NSTextField *authorTextField;
  IBOutlet NSTextView *descriptionTextView;
  IBOutlet NSTextField *ifidTextField;
}

@end

@implementation SummaryViewController

- (void)viewDidLoad {
  [super viewDidLoad];
}

- (void)viewWillAppear {
  [super viewWillAppear];

  Story *story = self.representedObject;

  ifidTextField.stringValue = story.ifid;

  // Set the artwork
  if (story.coverImage)
    imageView.image = story.coverImage;
  else
    imageView.image = [NSBundle.mainBundle imageForResource:@"NoCoverArt"];

  NSString *title = story.metadata.bibliographic.title;
  if (title && ![title isEqualToString:@""])
    titleTextField.stringValue = title;
  else
    titleTextField.stringValue = story.fileURL.lastPathComponent;
  NSString *author = story.metadata.bibliographic.author;
  if (author && ![author isEqualToString:@""])
    authorTextField.stringValue = author;
  else
    authorTextField.stringValue = @"Anonymous";
  NSString *desc = story.metadata.bibliographic.storyDescription;
  if (!desc || [desc isEqualToString:@""])
    desc = @"No description";

  NSFont *font = [NSFont labelFontOfSize:13.0];
  NSMutableParagraphStyle *paragraphStyle =
      [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
  paragraphStyle.alignment = NSTextAlignmentJustified;
  paragraphStyle.hyphenationFactor = 1.0;
  NSDictionary *attrs = @{
    NSFontAttributeName : font,
    NSForegroundColorAttributeName : NSColor.textColor,
    NSParagraphStyleAttributeName : paragraphStyle
  };
  NSAttributedString *str = [[NSAttributedString alloc] initWithString:desc
                                                            attributes:attrs];
  NSRange existingRange =
      NSMakeRange(0, descriptionTextView.textStorage.length);
  [descriptionTextView.textStorage replaceCharactersInRange:existingRange
                                       withAttributedString:str];
}

@end
