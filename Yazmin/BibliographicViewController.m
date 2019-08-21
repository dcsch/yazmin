//
//  BibliographicViewController.m
//  Yazmin
//
//  Created by David Schweinsberg on 8/13/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#import "BibliographicViewController.h"
#import "AppController.h"
#import "IFBibliographic.h"
#import "IFStory.h"
#import "Story.h"

@interface BibliographicViewController () <NSControlTextEditingDelegate> {
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
  IFBibliographic *bib = story.metadata.bibliographic;
  titleTextField.stringValue = bib.title ? bib.title : @"";
  authorTextField.stringValue = bib.author ? bib.author : @"";
  headlineTextField.stringValue = bib.headline ? bib.headline : @"";
  firstPublishedTextField.stringValue =
      bib.firstPublished ? bib.firstPublished : @"";
  groupTextField.stringValue = bib.group ? bib.group : @"";
  [self matchPopUpGenre:bib.genre];
}

- (void)matchPopUpGenre:(NSString *)genre {
  if (genre) {
    BOOL found = NO;
    for (NSMenuItem *item in genrePopUpButton.itemArray) {
      if ([genre isCaseInsensitiveLike:item.title]) {
        [genrePopUpButton selectItem:item];
        specialMenuItem.hidden = item != specialMenuItem;
        specialSeparatorMenuItem.hidden = item != specialMenuItem;
        found = YES;
        break;
      }
    }
    if (!found)
      [self addCustomGenre:genre];
  } else {
    [genrePopUpButton selectItemAtIndex:0];
    specialMenuItem.hidden = YES;
    specialSeparatorMenuItem.hidden = YES;
  }
}

- (void)addCustomGenre:(NSString *)genre {
  specialMenuItem.hidden = NO;
  specialSeparatorMenuItem.hidden = NO;
  specialMenuItem.title = genre;
  [genrePopUpButton selectItem:specialMenuItem];
  [self selectGenre:self];
}

#pragma mark - Actions

- (IBAction)selectGenre:(id)sender {
  Story *story = self.representedObject;
  IFBibliographic *bib = story.metadata.bibliographic;
  if (genrePopUpButton.selectedTag == 1) {
    bib.genre = nil;
  } else if (genrePopUpButton.selectedTag == 2) {
    [self performSegueWithIdentifier:@"CustomGenre" sender:self];
  } else {
    bib.genre = genrePopUpButton.titleOfSelectedItem;
  }
}

#pragma mark - NSControlTextEditingDelegate Methods

- (void)controlTextDidEndEditing:(NSNotification *)obj {
  Story *story = self.representedObject;
  IFBibliographic *bib = story.metadata.bibliographic;
  if (obj.object == titleTextField) {
    bib.title = titleTextField.stringValue;
  } else if (obj.object == authorTextField) {
    bib.author = authorTextField.stringValue;
  } else if (obj.object == headlineTextField) {
    bib.headline = headlineTextField.stringValue;
  } else if (obj.object == firstPublishedTextField) {
    bib.firstPublished = firstPublishedTextField.stringValue;
  } else if (obj.object == groupTextField) {
    bib.group = groupTextField.stringValue;
  }
  NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
  [nc postNotificationName:SMMetadataChangedNotification object:self];
}

@end
