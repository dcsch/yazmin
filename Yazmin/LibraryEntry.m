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

- (instancetype)initWithIFID:(NSString *)ifid url:(NSURL *)url {
  self = [super init];
  if (self) {
    _ifid = ifid;
    _fileURL = url;
    _storyMetadata = nil;
  }
  return self;
}

- (NSString *)title {
  if (_storyMetadata && _storyMetadata.bibliographic.title)
    return _storyMetadata.bibliographic.title;
  else
    return _fileURL.path.lastPathComponent;
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
