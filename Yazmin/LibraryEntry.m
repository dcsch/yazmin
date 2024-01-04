//
//  LibraryEntry.m
//  Yazmin
//
//  Created by David Schweinsberg on 27/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "LibraryEntry.h"
#import "IFAnnotation.h"
#import "IFBibliographic.h"
#import "IFIdentification.h"
#import "IFStory.h"
#import "IFYazmin.h"

@interface LibraryEntry ()

@property(nonatomic, nullable) NSString *cachedTitle;

+ (NSURL *)URLRelativeToLibrary:(NSURL *)storyURL;

@end

@implementation LibraryEntry

+ (NSURL *)URLRelativeToLibrary:(NSURL *)storyURL {
  NSUserDefaults *userDefaults =
      [[NSUserDefaults alloc] initWithSuiteName:NSArgumentDomain];
  NSString *libraryURLStr = [userDefaults stringForKey:@"LibraryURL"];
  NSURL *libraryURL = [NSURL URLWithString:libraryURLStr];
  NSArray<NSString *> *components = libraryURL.pathComponents;
  NSArray<NSString *> *rootComponents =
      [components subarrayWithRange:NSMakeRange(0, components.count - 1)];
  NSArray<NSString *> *fileComponents =
      [rootComponents arrayByAddingObjectsFromArray:storyURL.pathComponents];
  return [NSURL fileURLWithPathComponents:fileComponents];
}

- (instancetype)initWithStoryMetadata:(IFStory *)storyMetadata {
  self = [super init];
  if (self) {
    _storyMetadata = storyMetadata;
  }
  return self;
}

- (void)updateFromStory:(IFStory *)story {
  [_storyMetadata updateFromStory:story];
}

- (NSString *)ifid {
  return _storyMetadata.identification.ifids.firstObject;
}

- (NSURL *)fileURL {
  NSURL *storyURL = [self URLFromBookmarkData];
  if (storyURL)
    return storyURL;

  // Earlier-format libraries stored the URL as a string
  storyURL = _storyMetadata.annotation.yazmin.storyURL;
  if (storyURL && storyURL.scheme == nil) {
    storyURL = [LibraryEntry URLRelativeToLibrary:storyURL];
  }
  return storyURL;
}

- (NSString *)title {
  if (_storyMetadata && _storyMetadata.bibliographic.title &&
      ![_storyMetadata.bibliographic.title isEqualToString:@""])
    return _storyMetadata.bibliographic.title;
  else if (!self.cachedTitle)
    self.cachedTitle = self.fileURL.path.lastPathComponent;

  if (self.cachedTitle)
    return self.cachedTitle;
  else
    return @"(null)";
}

- (NSString *)sortTitle {
  NSString *title = [self.title lowercaseString];
  if ([title hasPrefix:@"a "])
    return [self.title substringFromIndex:2];
  else if ([title hasPrefix:@"the "])
    return [self.title substringFromIndex:4];
  else if (title)
    return self.title;
  else
    return @"(null)";
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

#pragma mark - Private Methods

- (nullable NSURL *)URLFromBookmarkData
{
  NSData *bookmarkData = _storyMetadata.annotation.yazmin.storyBookmarkData;
  if (bookmarkData) {
    BOOL isStale = NO;
    NSError *error;
    NSURL *url = [NSURL URLByResolvingBookmarkData:bookmarkData
                                           options:NSURLBookmarkResolutionWithSecurityScope
                                     relativeToURL:nil
                               bookmarkDataIsStale:&isStale
                                             error:&error];
    if (isStale) {
      NSData *data = [url bookmarkDataWithOptions:
                      NSURLBookmarkCreationWithSecurityScope |
                      NSURLBookmarkCreationSecurityScopeAllowOnlyReadAccess
                   includingResourceValuesForKeys:nil
                                    relativeToURL:nil
                                            error:&error];
      _storyMetadata.annotation.yazmin.storyBookmarkData = data;
    }
    if (url)
      return url;
  }
  return nil;
}

@end
