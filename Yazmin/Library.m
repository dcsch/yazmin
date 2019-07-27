//
//  Library.m
//  Yazmin
//
//  Created by David Schweinsberg on 26/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "Library.h"
#import "Blorb.h"
#import "IFBibliographic.h"
#import "IFStory.h"
#import "IFictionMetadata.h"
#import "LibraryEntry.h"
#import "Story.h"

@interface Library ()
@property(readonly, copy) NSDictionary *ifidURLDictionary;
@property IFictionMetadata *defaultMetadata;
@end

@implementation Library

- (instancetype)init {
  self = [super init];
  if (self) {
    _entries = [[NSMutableArray alloc] init];

    // Load the library entries saved in the user preferences
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *stories = [defaults objectForKey:@"Stories"];
    for (NSString *url in stories) {
      LibraryEntry *entry =
          [[LibraryEntry alloc] initWithIFID:[stories valueForKey:url]
                                         url:[NSURL URLWithString:url]];
      [_entries addObject:entry];
    }

    NSBundle *mainBundle = NSBundle.mainBundle;
    NSURL *url = [mainBundle URLForResource:@"babel" withExtension:@"ifiction"];
    NSData *data = [NSData dataWithContentsOfURL:url];
    _defaultMetadata = [[IFictionMetadata alloc] initWithData:data];
  }
  return self;
}

- (NSDictionary *)ifidURLDictionary {
  NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
  for (LibraryEntry *entry in _entries)
    dictionary[entry.fileURL.absoluteString] = entry.ifid;
  return dictionary;
}

- (IFStory *)metadataForIFID:(NSString *)ifid {
  NSUInteger index = [self.entries
      indexOfObjectPassingTest:^BOOL(LibraryEntry *_Nonnull entry,
                                     NSUInteger idx, BOOL *_Nonnull stop) {
        return [entry.ifid isEqualToString:ifid];
      }];
  if (index != NSNotFound)
    return _entries[index].storyMetadata;
  else
    return [_defaultMetadata storyWithIFID:ifid];
}

- (BOOL)containsStory:(Story *)story {
  NSUInteger index = [self.entries
      indexOfObjectPassingTest:^BOOL(LibraryEntry *_Nonnull entry,
                                     NSUInteger idx, BOOL *_Nonnull stop) {
        return [entry.fileURL isEqualTo:story.fileURL];
      }];
  return index != NSNotFound;
}

- (void)save {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setObject:self.ifidURLDictionary forKey:@"Stories"];
}

- (void)syncMetadata {
  for (LibraryEntry *entry in _entries) {
    NSData *data = [NSData dataWithContentsOfURL:entry.fileURL];
    if (data && [Blorb isBlorbData:data]) {

      // Use metadata as found in blorb
      Blorb *blorb = [[Blorb alloc] initWithData:data];
      NSData *mddata = blorb.metaData;
      if (mddata) {
        IFictionMetadata *ifmd = [[IFictionMetadata alloc] initWithData:mddata];
        if (ifmd.stories.count > 0)
          entry.storyMetadata = ifmd.stories[0];
      }
    } else {
      // Search for metadata that we have stored
      entry.storyMetadata = [_defaultMetadata storyWithIFID:entry.ifid];
    }
  }
}

@end
