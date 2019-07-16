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
  IFStory *_storyMetadata;
}

@end

@implementation LibraryEntry

- (instancetype)initWithIFID:(NSString *)ifid
                         url:(NSURL *)url {
  self = [super init];
  if (self) {
    _ifid = ifid;
    _fileURL = url;
  }
  return self;
}

- (IFStory *)storyMetadata {
  if (_storyMetadata == nil) {
    return [[IFStory alloc] initWithTitle:_fileURL.path.lastPathComponent];
  }
  return _storyMetadata;
}

- (void)setStoryMetadata:(IFStory *)storyMetadata {
  _storyMetadata = storyMetadata;
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
