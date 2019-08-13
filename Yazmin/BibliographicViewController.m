//
//  BibliographicViewController.m
//  Yazmin
//
//  Created by David Schweinsberg on 8/13/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#import "BibliographicViewController.h"
#import "IFBibliographic.h"
#import "IFStory.h"
#import "Story.h"

@interface BibliographicViewController () {
  IBOutlet NSTextField *titleTextField;
  IBOutlet NSTextField *authorTextField;
  IBOutlet NSTextField *headlineTextField;
  IBOutlet NSTextField *firstPublishedTextField;
  IBOutlet NSPopUpButton *genrePopUpButton;
  IBOutlet NSMenuItem *specialMenuItem;
  IBOutlet NSMenuItem *specialSeparatorMenuItem;
  IBOutlet NSTextField *groupTextField;
}

- (void)matchPopUpGenre:(nullable NSString *)genre;

@end

@implementation BibliographicViewController

- (void)viewDidLoad {
  [super viewDidLoad];
}

- (void)viewWillAppear {
  [super viewWillAppear];

  Story *story = self.representedObject;

  if (story.metadata) {
    IFBibliographic *bib = story.metadata.bibliographic;
    titleTextField.stringValue = bib.title ? bib.title : @"";
    authorTextField.stringValue = bib.author ? bib.author : @"";
    headlineTextField.stringValue = bib.headline ? bib.headline : @"";
    firstPublishedTextField.stringValue =
        bib.firstPublished ? bib.firstPublished : @"";
    groupTextField.stringValue = bib.group ? bib.group : @"";
    [self matchPopUpGenre:bib.genre];
  }
}

- (void)matchPopUpGenre:(NSString *)genre {
  if (genre) {
    for (NSMenuItem *item in genrePopUpButton.itemArray) {
      if ([genre isCaseInsensitiveLike:item.title]) {
        [genrePopUpButton selectItem:item];
        break;
      }
    }
  } else {
    [genrePopUpButton selectItemAtIndex:0];
  }
  specialMenuItem.hidden = YES;
  specialSeparatorMenuItem.hidden = YES;
}

@end
