//
//  StyledFont.h
//  Yazmin
//
//  Created by David Schweinsberg on 14/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface StyledFont : NSFont {
  int style;
}

/*!
 @method style
 @abstract Returns the style value associated with the font.
*/
@property int style;

/*!
 @method setStyle
 @abstract Sets the style value associated with the font.
 @param aStyle The style value.
*/

@end
