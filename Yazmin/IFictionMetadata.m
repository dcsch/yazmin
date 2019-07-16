//
//  IFictionMetadata.m
//  Yazmin
//
//  Created by David Schweinsberg on 22/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "IFictionMetadata.h"
#import "IFIdentification.h"
#import "IFStory.h"

@implementation IFictionMetadata

- (instancetype)initWithData:(NSData *)data {
  self = [super init];
  if (self) {
    NSMutableArray<IFStory *> *stories = [[NSMutableArray alloc] init];

    NSError *error;
    NSXMLDocument *xml =
        [[NSXMLDocument alloc] initWithData:data
                                    options:NSXMLDocumentTidyXML
                                      error:&error];
    NSEnumerator *enumerator =
        [[[xml rootElement] elementsForName:@"story"] objectEnumerator];
    NSXMLElement *child;
    while ((child = [enumerator nextObject])) {
      IFStory *story = [[IFStory alloc] initWithXMLElement:child];
      [stories addObject:story];
    }
    _stories = stories;
  }
  return self;
}

- (nullable IFStory *)storyWithIFID:(NSString *)ifid {
  for (IFStory *story in _stories) {
    if ([story.identification.ifids containsObject:ifid]) {
      return story;
    }
  }
  return nil;
}

@end
