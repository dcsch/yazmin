//
//  Preferences.h
//  Yazmin
//
//  Created by David Schweinsberg on 14/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//
/*!
 @header Preferences
 @copyright David Schweinsberg
 @updated 2007-11-14
 @discussion This is a of the HeaderDoc documentation tool.
*/
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *SMAppearanceKey;
extern NSString *SMBackgroundColorKey;
extern NSString *SMForegroundColorKey;
extern NSString *SMMonospacedFontKey;
extern NSString *SMProportionalFontKey;
extern NSString *SMCharacterGraphicsFontKey;
extern NSString *SMFontSizeKey;
extern NSString *SMShowLibraryOnStartupKey;
extern NSString *SMInterpreterNumberKey;
extern NSString *SMInterpreterVersionKey;
extern NSString *SMSpeakTextKey;
extern NSString *SMTextBoxFadeCount;

extern NSString *SMBackgroundColorChangedNotification;
extern NSString *SMForegroundColorChangedNotification;
extern NSString *SMProportionalFontFamilyChangedNotification;
extern NSString *SMMonospacedFontFamilyChangedNotification;
extern NSString *SMCharacterGraphicsFontChangedNotification;
extern NSString *SMFontSizeChangedNotification;

@interface Preferences : NSObject

+ (Preferences *)sharedPreferences;

@property NSColor *backgroundColor;
@property NSColor *foregroundColor;
@property NSString *proportionalFontFamily;
@property NSString *monospacedFontFamily;
@property NSString *characterGraphicsFontFamily;
@property float fontSize;
@property BOOL showsLibraryOnStartup;
@property(readonly) int interpreterNumber;
@property(readonly) char interpreterVersion;
@property(readonly) BOOL speakText;
@property int textBoxFadeCount;

+ (void)registerDefaults;
- (void)applyAppPreferences;

@end

NS_ASSUME_NONNULL_END
