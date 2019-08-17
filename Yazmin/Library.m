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
@property(readonly) NSURL *libraryDataURL;
@property(readonly) NSURL *libraryMetadataURL;
@property(readonly) NSDictionary *ifidURLDictionary;
@property IFictionMetadata *defaultMetadata;

- (NSURL *)URLForResource:(NSString *)name
                  subdirectory:(nullable NSString *)subpath
    createNonexistentDirectory:(BOOL)create;
@end

@implementation Library

- (instancetype)init {
  self = [super init];
  if (self) {
    NSData *data = [NSData dataWithContentsOfURL:self.libraryMetadataURL];
    IFictionMetadata *metadata = [[IFictionMetadata alloc] initWithData:data];

    _entries = [[NSMutableArray alloc] init];
    NSURL *libraryDataURL = self.libraryDataURL;
    NSData *libraryData = [NSData dataWithContentsOfURL:libraryDataURL];
    if (libraryData) {
      NSError *error;
      NSDictionary *stories = [NSPropertyListSerialization
          propertyListWithData:libraryData
                       options:NSPropertyListMutableContainers
                        format:nil
                         error:&error];
      for (NSString *url in stories) {
        NSString *ifid = [stories valueForKey:url];
        IFStory *storyMetadata = [metadata storyWithIFID:ifid];
        LibraryEntry *entry =
            [[LibraryEntry alloc] initWithIFID:ifid
                                           url:[NSURL URLWithString:url]
                                 storyMetadata:storyMetadata];
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

- (NSURL *)URLForResource:(NSString *)name
                  subdirectory:(nullable NSString *)subpath
    createNonexistentDirectory:(BOOL)create {
  NSFileManager *fm = NSFileManager.defaultManager;
  NSArray<NSURL *> *urls = [fm URLsForDirectory:NSApplicationSupportDirectory
                                      inDomains:NSUserDomainMask];
  NSString *appName = NSBundle.mainBundle.infoDictionary[@"CFBundleExecutable"];
  NSURL *supportDirURL =
      [urls.firstObject URLByAppendingPathComponent:appName isDirectory:YES];
  NSURL *subDirURL;
  if (subpath)
    subDirURL =
        [supportDirURL URLByAppendingPathComponent:subpath isDirectory:YES];
  else
    subDirURL = supportDirURL;

  if (create) {
    // Create it if it doesn't exist
    NSError *error;
    [fm createDirectoryAtURL:subDirURL
        withIntermediateDirectories:YES
                         attributes:nil
                              error:&error];
  }
  return [subDirURL URLByAppendingPathComponent:name];
}

- (NSURL *)libraryDataURL {
  NSURL *url = [self URLForResource:@"games.plist"
                       subdirectory:nil
         createNonexistentDirectory:YES];
  return url;
}

- (NSURL *)libraryMetadataURL {
  NSURL *url = [self URLForResource:@"games.iFiction"
                       subdirectory:nil
         createNonexistentDirectory:YES];
  return url;
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
    return nil;
}

- (IFStory *)defaultMetadataForIFID:(NSString *)ifid {
  return [_defaultMetadata storyWithIFID:ifid];
}

- (NSImage *)imageForIFID:(NSString *)ifid {
  NSString *filename = [NSString stringWithFormat:@"%@.jpg", ifid];
  NSURL *url = [self URLForResource:filename
                       subdirectory:@"Cover Art"
         createNonexistentDirectory:NO];
  NSData *data = [NSData dataWithContentsOfURL:url];
  if (data)
    return [[NSImage alloc] initWithData:data];
  else
    return nil;
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
  NSError *error;
  NSData *data = [NSPropertyListSerialization
      dataWithPropertyList:self.ifidURLDictionary
                    format:NSPropertyListXMLFormat_v1_0
                   options:0
                     error:&error];
  if (data)
    [data writeToURL:self.libraryDataURL atomically:YES];

  // Save the iFiction metadata
  NSMutableArray<IFStory *> *stories = [NSMutableArray array];
  for (LibraryEntry *entry in _entries)
    if (entry.storyMetadata)
      [stories addObject:entry.storyMetadata];
  IFictionMetadata *metadata =
      [[IFictionMetadata alloc] initWithStories:stories];
  data = [metadata.xmlString dataUsingEncoding:NSUTF8StringEncoding];
  if (data)
    [data writeToURL:self.libraryMetadataURL atomically:YES];
}

- (void)syncMetadata {
  //  for (LibraryEntry *entry in _entries) {
  //    NSData *data = [NSData dataWithContentsOfURL:entry.fileURL];
  //    if (data && [Blorb isBlorbData:data]) {
  //
  //      // Use metadata as found in blorb
  //      Blorb *blorb = [[Blorb alloc] initWithData:data];
  //      NSData *mddata = blorb.metaData;
  //      if (mddata) {
  //        IFictionMetadata *ifmd = [[IFictionMetadata alloc]
  //        initWithData:mddata];
  //        if (ifmd.stories.count > 0)
  //          entry.storyMetadata = ifmd.stories[0];
  //      }
  //    } else {
  //      // Search for metadata that we have stored
  //      //      IFStory *storyMetadata = [_defaultMetadata
  //      //      storyWithIFID:entry.ifid];
  //      //      if (storyMetadata)
  //      //        entry.storyMetadata = storyMetadata;
  //    }
  //  }
}

@end
