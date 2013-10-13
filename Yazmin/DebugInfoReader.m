//
//  DebugInfoReader.m
//  Yazmin
//
//  Created by David Schweinsberg on 22/12/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "DebugInfoReader.h"
#import "DebugInfo.h"
#import "RoutineDebugRecord.h"

#define EOF_DBR          0
#define FILE_DBR         1
#define CLASS_DBR        2
#define OBJECT_DBR       3
#define GLOBAL_DBR       4
#define ARRAY_DBR       12
#define ATTR_DBR         5
#define PROP_DBR         6
#define FAKE_ACTION_DBR  7
#define ACTION_DBR       8
#define HEADER_DBR       9
#define ROUTINE_DBR     11
#define LINEREF_DBR     10
#define ROUTINE_END_DBR 14
#define MAP_DBR         13

@interface DebugInfoReader (Private)

- (void)readDebugData;
- (unsigned char)readByte;
- (unsigned int)readWord;
- (NSString *)readString;
- (NSString *)readLine;
- (unsigned int)readAddress;
- (void)readFileDBR;
- (void)readClassDBR;
- (void)readObjectDBR;
- (void)readGlobalDBR;
- (void)readArrayDBR;
- (void)readAttributeDBR;
- (void)readPropertyDBR;
- (void)readFakeActionDBR;
- (void)readActionDBR;
- (void)readHeaderDBR;
- (void)readRoutineDBR;
- (void)readLineRefDBR;
- (void)readRoutineEndDBR;
- (void)readMapDBR;

@end

@implementation DebugInfoReader

- (id)initWithData:(NSData *)data
{
    self = [super init];
    if (self)
    {
        debugData = data;
        
        currentRoutine = nil;
    }
    return self;
}


- (DebugInfo *)debugInfo
{
    debugInfo = [[DebugInfo alloc] init];

    // Check that the data is good
    ptr = (unsigned char *)[debugData bytes];
    if (ptr[0] == 0xde && ptr[1] == 0xbf)
    {
        ptr += 6;
        [self readDebugData];
    }
    return debugInfo;
}

- (unsigned char)readByte
{
    return *ptr++;
}

- (unsigned int)readWord
{
    unsigned int word = *ptr++ << 8;
    word |= *ptr++;
    return word;
}

- (NSString *)readString
{
    NSString *str = [NSString stringWithCString:(char *)ptr
                                       encoding:[NSString defaultCStringEncoding]];
    ptr += [str length] + 1;
    return str;
}

- (NSString *)readLine
{
    unsigned int fileNumber = [self readByte];
    unsigned int lineNumber = [self readWord];
    unsigned int charNumber = [self readByte];
    return [NSString stringWithFormat:@"%d:%d:%d", fileNumber, lineNumber, charNumber];
}

- (unsigned int)readAddress
{
    unsigned int addr = 0;
    addr = *ptr++ << 16;
    addr |= *ptr++ << 8;
    addr |= *ptr++;
    return addr;
}

- (void)readDebugData
{
    unsigned char recordType = ptr[0];
    ++ptr;
    while (recordType != EOF_DBR)
    {
        switch (recordType)
        {
            case EOF_DBR:
                break;
            case FILE_DBR:
                [self readFileDBR];
                break;
            case CLASS_DBR:
                [self readClassDBR];
                break;
            case OBJECT_DBR:
                [self readObjectDBR];
                break;
            case GLOBAL_DBR:
                [self readGlobalDBR];
                break;
            case ARRAY_DBR:
                [self readArrayDBR];
                break;
            case ATTR_DBR:
                [self readAttributeDBR];
                break;
            case PROP_DBR:
                [self readPropertyDBR];
                break;
            case FAKE_ACTION_DBR:
                [self readFakeActionDBR];
                break;
            case ACTION_DBR:
                [self readActionDBR];
                break;
            case HEADER_DBR:
                [self readHeaderDBR];
                break;
            case ROUTINE_DBR:
                [self readRoutineDBR];
                break;
            case LINEREF_DBR:
                [self readLineRefDBR];
                break;
            case ROUTINE_END_DBR:
                [self readRoutineEndDBR];
                break;
            case MAP_DBR:
                [self readMapDBR];
                break;
        }

        // Next record
        recordType = *ptr++;
    }
}

- (void)readFileDBR
{
    unsigned char fileNumber = [self readByte];
    NSString *includeName = [self readString];
    NSString *actualFileName = [self readString];
    NSLog(@"FILE_DBR fileNumber: %d, includeName: %@, actualFileName: %@", fileNumber, includeName, actualFileName);
}

- (void)readClassDBR
{
    NSString *name = [self readString];
    NSString *defnStart = [self readLine];
    NSString *defnEnd = [self readLine];
    NSLog(@"CLASS_DBR name: %@, defnStart: %@, defnEnd: %@", name, defnStart, defnEnd);
}

- (void)readObjectDBR
{
    unsigned int number = [self readWord];
    NSString *name = [self readString];
    NSString *defnStart = [self readLine];
    NSString *defnEnd = [self readLine];
    [debugInfo objectNames][@(number)] = name;
    NSLog(@"OBJECT_DBR number: %d, name: %@, defnStart: %@, defnEnd: %@", number, name, defnStart, defnEnd);
}

- (void)readGlobalDBR
{
    unsigned int number = [self readByte];
    NSString *name = [self readString];
    NSLog(@"GLOBAL_DBR number: %d, name: %@", number, name);
}

- (void)readArrayDBR
{
    unsigned int byteAddress = [self readWord];
    NSString *name = [self readString];
    NSLog(@"ARRAY_DBR byteAddress: %d, name: %@", byteAddress, name);
}

- (void)readAttributeDBR
{
    unsigned int number = [self readWord];
    NSString *name = [self readString];
    NSLog(@"ATTR_DBR number: %d, name: %@", number, name);
}

- (void)readPropertyDBR
{
    unsigned int number = [self readWord];
    NSString *name = [self readString];
    [debugInfo propertyNames][@(number)] = name;
    NSLog(@"PROP_DBR number: %d, name: %@", number, name);
}

- (void)readFakeActionDBR
{
    unsigned int number = [self readWord];
    NSString *name = [self readString];
    NSLog(@"FACE_ACTION_DBR number: %d, name: %@", number, name);
}

- (void)readActionDBR
{
    unsigned int number = [self readWord];
    NSString *name = [self readString];
    NSLog(@"ACTION_DBR number: %d, name: %@", number, name);
}

- (void)readHeaderDBR
{
    int i;
    for (i = 0; i < 64; ++i)
        [self readByte];
    NSLog(@"HEADER_DBR");
}

- (void)readRoutineDBR
{
    unsigned int routineNumber = [self readWord];
    NSString *defnStart = [self readLine];
    unsigned int pcStart = [self readAddress];
    NSString *name = [self readString];
    //NSLog(@"ROUTINE_DBR routineNumber: %d, defnStart: %@, pcStart: 0x%x, name: %@", routineNumber, defnStart, pcStart, name);
    
    currentRoutine = [[RoutineDebugRecord alloc] initWithNumber:routineNumber
                                                          start:defnStart
                                                        pcStart:pcStart
                                                           name:name];
    [debugInfo routines][@(pcStart)] = currentRoutine;
    while (*ptr)
    {
        NSString *localName = [self readString];
        [[currentRoutine localNames] addObject:localName];
    }
    ++ptr;
}

- (void)readLineRefDBR
{
    unsigned int routineNumber = [self readWord];
    unsigned int numberOfSequencePoints = [self readWord];
    //NSLog(@"LINE_REF_DBR routineNumber: %d, numberOfSequencePoints: %d", routineNumber, numberOfSequencePoints);
    unsigned int i;
    for (i = 0; i < numberOfSequencePoints; ++i)
    {
        NSString *sourceCodePosition = [self readLine];
        unsigned int pcOffset = [self readWord];
        //NSLog(@"    %@, pcOffset: 0x%x", sourceCodePosition, pcOffset);
    }
}

- (void)readRoutineEndDBR
{
    unsigned int routineNumber = [self readWord];
    NSString *defnEnd = [self readLine];
    unsigned int nextPCValue = [self readAddress];
    //NSLog(@"ROUTINE_END_DBR routineNumber: %d, defnEnd: %@, nextPCValue: 0x%x", routineNumber, defnEnd, nextPCValue);
}

- (void)readMapDBR
{
    NSLog(@"MAP_DBR");
    while (*ptr)
    {
        NSString *name = [self readString];
        unsigned int address = [self readAddress];
        NSLog(@"    %@: 0x%x", name, address);
    }
    ++ptr;
}

@end
