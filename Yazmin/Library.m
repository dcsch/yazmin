//
//  Library.m
//  Yazmin
//
//  Created by David Schweinsberg on 26/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "Library.h"
#import "AppController.h"
#import "Blorb.h"
#import "IFAnnotation.h"
#import "IFBibliographic.h"
#import "IFIdentification.h"
#import "IFStory.h"
#import "IFYazmin.h"
#import "IFictionMetadata.h"
#import "LibraryEntry.h"
#import "Story.h"

@interface Library ()
@property(readonly) NSURL *libraryMetadataURL;
@property IFictionMetadata *defaultMetadata;

@end

@implementation Library

- (instancetype)init {
  self = [super init];
  if (self) {
    _entries = [[NSMutableArray alloc] init];

    NSData *data = [NSData dataWithContentsOfURL:self.libraryMetadataURL];
    IFictionMetadata *metadata = nil;
    if (data) {
      metadata = [[IFictionMetadata alloc] initWithData:data];
      for (IFStory *storyMetadata in metadata.stories) {
        LibraryEntry *entry =
            [[LibraryEntry alloc] initWithStoryMetadata:storyMetadata];
        [_entries addObject:entry];
      }
    }

    NSBundle *mainBundle = NSBundle.mainBundle;
    NSURL *url = [mainBundle URLForResource:@"babel" withExtension:@"ifiction"];
    data = [NSData dataWithContentsOfURL:url];
    _defaultMetadata = [[IFictionMetadata alloc] initWithData:data];
  }
  return self;
}

- (NSURL *)libraryMetadataURL {
  NSUserDefaults *userDefaults =
      [[NSUserDefaults alloc] initWithSuiteName:NSArgumentDomain];
  NSString *libraryURLStr = [userDefaults stringForKey:@"LibraryURL"];
  if (libraryURLStr) {
    return [NSURL URLWithString:libraryURLStr];
  }

  NSURL *url = [AppController URLForResource:@"stories.iFiction"
                                subdirectory:nil
                  createNonexistentDirectory:YES];
  return url;
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
    return nil;
}

- (IFStory *)defaultMetadataForIFID:(NSString *)ifid {
  return [_defaultMetadata storyWithIFID:ifid];
}

- (NSImage *)imageForIFID:(NSString *)ifid {

  // First look for a JPEG
  NSString *filename = [NSString stringWithFormat:@"%@.jpg", ifid];
  NSURL *url = [AppController URLForResource:filename
                                subdirectory:@"Cover Art"
                  createNonexistentDirectory:NO];
  NSData *data = [NSData dataWithContentsOfURL:url];

  if (!data) {

    // Try loading a PNG
    filename = [NSString stringWithFormat:@"%@.png", ifid];
    url = [AppController URLForResource:filename
                           subdirectory:@"Cover Art"
             createNonexistentDirectory:NO];
    data = [NSData dataWithContentsOfURL:url];
  }

  if (!data) {

    // Try loading a GIF (yes, this is not standard, but at least
    // one image from IFDB is a GIF - Suveh Nux)
    filename = [NSString stringWithFormat:@"%@.gif", ifid];
    url = [AppController URLForResource:filename
                           subdirectory:@"Cover Art"
             createNonexistentDirectory:NO];
    data = [NSData dataWithContentsOfURL:url];
  }

  if (data)
    return [[NSImage alloc] initWithData:data];
  else
    return nil;
}

- (void)fetchImageForIFID:(NSString *)ifid URL:(NSURL *)url {
  NSURLSession *session = NSURLSession.sharedSession;
  NSURLSessionDataTask *dataTask =
      [session dataTaskWithURL:url
             completionHandler:^(NSData *data, NSURLResponse *response,
                                 NSError *error) {
               NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
               NSLog(@"Image response: %ld (%@)", (long)httpResponse.statusCode,
                     httpResponse.MIMEType);
               if (httpResponse.statusCode == 200) {
                 NSString *ext = nil;
                 if ([httpResponse.MIMEType isEqualToString:@"image/jpeg"])
                   ext = @"jpg";
                 else if ([httpResponse.MIMEType isEqualToString:@"image/png"])
                   ext = @"png";
                 else if ([httpResponse.MIMEType isEqualToString:@"image/gif"])
                   ext = @"gif";
                 if (ext) {
                   NSString *filename =
                       [NSString stringWithFormat:@"%@.%@", ifid, ext];
                   NSURL *url = [AppController URLForResource:filename
                                                 subdirectory:@"Cover Art"
                                   createNonexistentDirectory:YES];
                   [data writeToURL:url atomically:YES];
                   dispatch_async(dispatch_get_main_queue(), ^{
                                  });
                 }
               }
             }];
  [dataTask resume];
}

- (void)deleteImageForIFID:(NSString *)ifid {
  NSURL *artworkURL = [[AppController applicationSupportDirectoryURL]
      URLByAppendingPathComponent:@"Cover Art"
                      isDirectory:YES];
  NSFileManager *fm = NSFileManager.defaultManager;
  NSArray<NSURL *> *urls = [fm contentsOfDirectoryAtURL:artworkURL
                             includingPropertiesForKeys:nil
                                                options:0
                                                  error:nil];
  for (NSURL *url in urls) {
    if ([url.lastPathComponent hasPrefix:ifid]) {
      [fm removeItemAtURL:url error:nil];
    }
  }
}

- (BOOL)containsStory:(Story *)story {
  NSUInteger index = [self.entries
      indexOfObjectPassingTest:^BOOL(LibraryEntry *_Nonnull entry,
                                     NSUInteger idx, BOOL *_Nonnull stop) {
        return [entry.ifid isEqualTo:story.ifid];
      }];
  return index != NSNotFound;
}

- (void)save {

  // Save the iFiction metadata
  NSMutableArray<IFStory *> *stories = [NSMutableArray array];
  for (LibraryEntry *entry in _entries)
    if (entry.storyMetadata)
      [stories addObject:entry.storyMetadata];
  IFictionMetadata *metadata =
      [[IFictionMetadata alloc] initWithStories:stories];
  NSData *data = [metadata.xmlString dataUsingEncoding:NSUTF8StringEncoding];
  if (data)
    [data writeToURL:self.libraryMetadataURL atomically:YES];
}

- (void)migrateToLatestFormat {
  for (LibraryEntry *entry in _entries) {
    [entry migrateBookmarkDataFromStoryURLIfNeeded];
  }
}

@end
