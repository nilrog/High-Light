//
//  HighLightSettings.m
//  High-Light Plugin for RapidWeaver
//
//  Created by Roger Nilsson on 2007-01-07.
//  Copyright 2007 Roger Nilsson.
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

#import "HighLightSettings.h";

// Constants

// Settings stored in our .plist
NSString *kHLSHighLightDomain = @"se.nilrogsplace.high-light";
NSString *kHLSUseLineNumbers = @"settings.linenumbers";
NSString *kHLSGenerateAnchors = @"settings.generateanchors";
NSString *kHLSApplyInlineColorCSS = @"settings.applyinlinecolorcss";
NSString *kHLSWrapTag = @"settings.wraptag";
NSString *kHLSUseDynamicMenu = @"settings.usedynamicmenu";
NSString *kHLSPathToSourceHighlight = @"settings.pathtosourcehighlight";
NSString *kHLSUseExternalBinary = @"settings.useexternalbinary";
NSString *kHLSNumberOfTabs = @"settings.numberoftabs";
NSString *kHLSLineNumberPadding = @"settings.linenumberpadding";

// Default path to 'source-highlight'
NSString *kHLSDefaultPath = @"~/Library/Application Support/RapidWeaver/High-Light Support/source-highlight";
