//
//  HighLightPlugin.h
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
#import <RWPluginUtilities/RWPluginUtilities.h>
#import "RNDropTextView.h"
#import "HighLightSettings.h"

@interface HighLightPlugin : RWAbstractPlugin
{
  @protected
  // Outlets
  IBOutlet NSWindow *settingsWindow;
  IBOutlet NSTextField *versionText;
  IBOutlet NSTextField *licenseText;
  IBOutlet NSTextField *sourceHighLightText;
  IBOutlet NSTextField *sourceHighLightPath;
  IBOutlet NSButton *useStaticMenuBtn;
  IBOutlet NSTextField *tabsText;
  // Custom field editor
  RNDropTextView *fileDropView;
  // Default settings
  NSMutableDictionary *settings;
  // Available tags
  NSMutableArray *wrapTags;
  // Path to binary
  NSString *pathToSourceHighlightBinary;
  // Version tracker for source-highlight
  int sourceHighlightVersion;
  BOOL sourceHighlightCanChangePadding;
}

// Set and Get methods
- (BOOL) sourceHighlightCanChangePadding;
- (void) setSourceHighlightCanChangePadding:(BOOL)value;

// Actions
- (IBAction) theSheetOK:(id)sender;
- (IBAction) theSheetCancel:(id)sender;
- (IBAction) theSheetBrowse:(id)sender;
- (IBAction) goVisitMyWebsite:(id)sender;

// Helper methods
- (void) menuNeedsUpdate:(NSMenu *)menu;
- (void) myMenuIsEmpty:(NSWindow *)window;
- (void) alertDidEnd:(NSWindow *)sheet
          returnCode:(int)returnCode
         contextInfo:(void *)contextInfo;
- (void) highLightHelp:(NSWindow *)window;
- (void) highLightSettings:(NSWindow *)window;
- (void) filePanelDidEnd:(NSOpenPanel *)openPanel
              returnCode:(int)returnCode
             contextInfo:(void *)contextInfo;
- (BOOL) validateSourceHighlightBinary:(NSString *)pathToBinary
                          displayError:(BOOL)displayError;
- (void) displayError:(NSString *)errorText;
- (NSString *) wrapTagStart;
- (NSString *) wrapTagEnd;
- (void) setupWrapTags;

// Class methods
+ (HighLightPlugin *) sharedPlugin;
+ (NSBundle *) sharedBundle;
+ (void) createHighLightMenu;
+ (void) addHighLightMenuItem;
+ (NSArray *) highLightStyles;
+ (NSNumber *) highlightEnabledForFilterStyleInSelectedRange:(NSString *)highlightStyleName;
+ (NSNumber *) highlightOptionEnabledForFilterStyleInSelectedRange:(int)highlightOptionTag;

// Delegates
- (id) windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)anObject;

// Notifications
+ (void) applicationDidFinishLaunching:(NSNotification*)aNotification;

@end

///////////////////////////////////////////////////////////////////
//
// Constants
//
///////////////////////////////////////////////////////////////////

// URL to my homepage
extern const NSString* const kHLDonateLink;
extern const NSString* const kNPDownloadHLPage;

// .plist items
extern const NSString* const kHighLightCommand;
extern const NSString* const kHighLightName;

// Tag for our highlight style items
extern const int kHighLightTextMenuItemTag;
// Master tag for our highlight option items
extern const int kHighLightOptionMenuItemTag;
// Minor tag for our highlight option items
extern const int kLineNumberTag;
extern const int kGenerateAnchorTag;
// Link to the user manual
extern const NSString* const kHLHelpLink;

