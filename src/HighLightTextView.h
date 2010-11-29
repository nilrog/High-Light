//
//  HighLightTextView.h
//  High-Light Plugin for RapidWeaver
//
//  Created by Roger Nilsson on 2006-12-25.
//  Copyright 2006 Roger Nilsson.
//  All rights reserved.
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy of this
// software and associated documentation files (the "Software"), to deal in the Software
// without restriction, including without limitation the rights to use, copy, modify,
// merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to the following
// conditions:
// 
// The above copyright notice and this permission notice shall be included in all copies
// or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
// PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
// CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
// OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import <Cocoa/Cocoa.h>
#import <RWPluginUtilities/RMHTML.h>
#import <RWPluginUtilities/RWTextView.h>

@class RMHTML;

@interface HighLightTextView : RWTextView
{
}

// Menu item helpers
- (NSNumber *) highlightEnabledForFilterStyleInSelectedRange:(NSString *)highlightStyleName;
- (NSNumber *) highlightOptionEnabledForFilterStyleInSelectedRange:(NSNumber *)highlightOptionTag;

@end

@interface HighLightHTML : RMHTML
{
}

- (NSAttributedString *) exportHighLightAttributedString:(NSAttributedString*)str
                                                  toPath:(NSString*)path
                                            imagesFolder:(NSString*)imagesFolder
                                             imagePrefix:(NSString*)imagePrefix
                                            HTMLTemplate:(NSMutableString*)theTemplate
                                              contentTag:(NSString*)contentTag
                                                fromPage:(id)thePage
                                         depthCorrection:(int)depthCorrection;

@end

// RW4.0 typedef
typedef enum
{
	RWExportModeExport,
	RWExportModePublish,
	RWExportModePreview,
	RWExportModeViewSourceCode,
	RWExportModeConvertingForWebViewDOM,
}
RWExportMode;

@interface RMHTML (RW4Methods)

- (NSString *) exportAttributedString:(NSAttributedString *)str
                               toPath:(NSString *)path
                         imagesFolder:(NSString *)imagesFolder
                          imagePrefix:(NSString *)imagePrefix
                         HTMLTemplate:(NSString *)theTemplate
                           contentTag:(NSString *)contentTag
                             fromPage:(id)thePage
                      depthCorrection:(int)depthCorrection
                           exportMode:(RWExportMode)exportMode;

@end
