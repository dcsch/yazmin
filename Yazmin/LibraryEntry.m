//
//  LibraryEntry.m
//  Yazmin
//
//  Created by David Schweinsberg on 27/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "LibraryEntry.h"
#import "IFBibliographic.h"
#import "IFStory.h"

@interface LibraryEntry ()

@end

@implementation LibraryEntry

- (instancetype)initWithIFID:(NSString *)ifid
                         url:(NSURL *)url
               storyMetadata:(IFStory *)storyMetadata {
  self = [super init];
  if (self) {
    _ifid = ifid;
    _fileURL = url;
    _storyMetadata = storyMetadata;
  }
  return self;
}

- (void)updateFromStory:(IFStory *)story {
  if (!_storyMetadata)
    _storyMetadata = [[IFStory alloc] initWithIFID:_ifid];
  [_storyMetadata updateFromStory:story];
}

- (NSString *)title {
  if (_storyMetadata && _storyMetadata.bibliographic.title &&
      ![_storyMetadata.bibliographic.title isEqualToString:@""])
    return _storyMetadata.bibliographic.title;
  else
    return _fileURL.path.lastPathComponent;
}

- (NSString *)sortTitle {
  NSString *title = [self.title lowercaseString];
  if ([title hasPrefix:@"a "])
    return [self.title substringFromIndex:2];
  else if ([title hasPrefix:@"the "])
    return [self.title substringFromIndex:4];
  else
    return self.title;
}

- (NSString *)author {
  return _storyMetadata.bibliographic.author;
}

- (NSString *)genre {
  return _storyMetadata.bibliographic.genre;
}

- (NSString *)group {
  return _storyMetadata.bibliographic.group;
}

- (NSString *)firstPublished {
  return _storyMetadata.bibliographic.firstPublished;
}

@end
