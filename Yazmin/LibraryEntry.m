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

@interface LibraryEntry () {
}

@end

@implementation LibraryEntry

- (nonnull instancetype)initWithIFID:(nonnull NSString *)ifid
                                 url:(nonnull NSURL *)url {
  self = [super init];
  if (self) {
    _ifid = ifid;
    _fileURL = url;
  }
  return self;
}

- (nonnull NSString *)title {
  if (_storyMetadata && _storyMetadata.bibliographic.title)
    return _storyMetadata.bibliographic.title;
  else
    return _fileURL.path.lastPathComponent;
}

- (nullable NSString *)author {
  return _storyMetadata.bibliographic.author;
}

- (nullable NSString *)genre {
  return _storyMetadata.bibliographic.genre;
}

- (nullable NSString *)group {
  return _storyMetadata.bibliographic.group;
}

- (nullable NSString *)firstPublished {
  return _storyMetadata.bibliographic.firstPublished;
}

@end
