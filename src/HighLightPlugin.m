//
//  HighLightPlugin.m
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

#import "HighLightPlugin.h"
#import "HighLightTextView.h"
#import "HighLightSettings.h"
#import "NSTaskAdditions.h"
#import "CSRegex.h"
#import "RNLogging.h"

#define PluginLocalizedString(key, comment) [[HighLightPlugin sharedBundle] localizedStringForKey:(key) value:@"" table:nil]

static NSBundle *pluginBundle = nil;
static HighLightPlugin *sharedPlugin = nil;
static BOOL addedHighLightMenuItem = NO;
static NSMenu *highLightMenu = nil;
static BOOL foundSourceHighlight = NO;
static NSMutableArray *cachedHighLightStyles = nil;

@implementation HighLightPlugin

///////////////////////////////////////////////////////////////////
//
// High-Light Plugin
//
// These are the basic object life-cycle methods.
//
///////////////////////////////////////////////////////////////////

+ (void)initialize
{
  LOG_ENTRY;
  
  // Add a notification so we are informed when RapidWeaver has finished launching
  [[NSNotificationCenter defaultCenter] addObserver:self 
                                           selector:@selector(applicationDidFinishLaunching:) 
                                               name:NSApplicationDidFinishLaunchingNotification 
                                             object:nil];
}

+ (BOOL)initializeClass:(NSBundle *)theBundle
{
  LOG_ENTRY;
  
  pluginBundle = theBundle;
  [pluginBundle retain];
  
  // Make our classes appear as RapidWeaver classes
  [HighLightTextView poseAsClass:[RWTextView class]];
  [HighLightHTML poseAsClass:[RMHTML class]];
  
  return YES;
}

+ (NSEnumerator *)pluginsAvailable;
{
  LOG_ENTRY;
  
  return nil;
}

- (id)init
{
  LOG_ENTRY;
  
  if (sharedPlugin != nil) {
    [self autorelease];
    self = [sharedPlugin retain];
  }
  else {
    if ((self = [super init]) != nil) {
      // Load default settings from disk
      Log(@"Loading default settings");
      NSUserDefaults *highLightDefaults = [NSUserDefaults standardUserDefaults];
      NSDictionary *tmpDict = [highLightDefaults persistentDomainForName:kHLSHighLightDomain];
      // Check if the domain was found
      if (tmpDict == nil) {
        Log(@"No defaults found");
        // Init new defaults
        NSArray *keys = [NSArray arrayWithObjects:@"linenumbers", @"generateanchors",
          @"applyinlinecolorcss", @"wraptag", @"usedynamicmenu", @"pathtosourcehighlight",
          @"useexternalbinary", @"numberoftabs", @"linenumberpadding", nil];
        NSArray *values = [NSArray arrayWithObjects:[NSNumber numberWithBool:NO], [NSNumber numberWithBool:NO],
          [NSNumber numberWithBool:YES], [NSNumber numberWithInt:0], [NSNumber numberWithBool:NO], kHLSDefaultPath,
          [NSNumber numberWithBool:NO], [NSNumber numberWithInt:4], @" ", nil];
        tmpDict = [NSDictionary dictionaryWithObjects:values forKeys:keys];
        Log(@"New settings: %@", tmpDict);
        NSUserDefaults *highLightDefaults = [NSUserDefaults standardUserDefaults];
        [highLightDefaults setPersistentDomain:tmpDict forName:kHLSHighLightDomain];
        [highLightDefaults synchronize];
      }
      settings = [[NSMutableDictionary alloc] initWithDictionary:tmpDict];
      // Check if "numberoftabs" exists in the dictionary
      if ([settings objectForKey:@"numberoftabs"] == nil) {
        [settings setObject:[NSNumber numberWithInt:4] forKey:@"numberoftabs"];
      }
      // Check if "linenumberpadding" exists in the dictionary
      if ([settings objectForKey:@"linenumberpadding"] == nil) {
        [settings setObject:@" " forKey:@"linenumberpadding"];
      }
      
      // Register KVO observers for some of our settings
      [self addObserver:self forKeyPath:kHLSUseExternalBinary options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:NULL];
      [self addObserver:self forKeyPath:kHLSPathToSourceHighlight options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:NULL];
      [self addObserver:self forKeyPath:kHLSUseDynamicMenu options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:NULL];
      [self addObserver:self forKeyPath:kHLSLineNumberPadding options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew) context:NULL];
      
      // Initialize the tags
      [self setupWrapTags];
      
      // Load our nib-file
      Log(@"Loading nib-file");
      [NSBundle loadNibNamed:@"High-Light" owner:self];
      sharedPlugin = self;
      
      // Check which binary to use
      if ( ! [[self valueForKeyPath:kHLSUseExternalBinary] boolValue]) {
        // Get the path to our bundled binary
        NSString* pathToBundledBinary = [pluginBundle pathForResource:@"source-highlight"
                                                               ofType:nil
                                                          inDirectory:@"source-highlight/bin"];
        pathToSourceHighlightBinary = pathToBundledBinary;
      }
      else {
        pathToSourceHighlightBinary = [self valueForKeyPath:kHLSPathToSourceHighlight];
      }
      [pathToSourceHighlightBinary retain];
      
      // Check if the 'source-highlight' binary exists
      foundSourceHighlight = [self validateSourceHighlightBinary:pathToSourceHighlightBinary
                                                    displayError:NO];
      
      // Set the version information in our settings window
      [versionText setStringValue:[NSString stringWithFormat:@"%@ v%@",
        [pluginBundle objectForInfoDictionaryKey:@"CFBundleName"],
        [pluginBundle objectForInfoDictionaryKey:@"CFBundleGetInfoString"]]];
      Log([versionText stringValue]);
      
      // Set the license in our settings window
      NSString* path = [pluginBundle pathForResource:@"LICENSE"
                                              ofType:nil];
      if (path == nil) {
        NSLog(@"File: LICENSE not found in bundle!");
        [licenseText setStringValue:PluginLocalizedString(@"LicenseFileNotFound", nil)];
      }
      else {
        // Legacy code used to support OSX 10.3.9 (>= 10.4 can use NSString stringWithContentsOfFile)
        NSFileHandle *tmpFileReader = [NSFileHandle fileHandleForReadingAtPath:path];
        if (tmpFileReader == nil) {
          // An error ocurred, log the error
          NSLog(@"File LICENSE was not found inside the plugin!");
          [licenseText setStringValue:PluginLocalizedString(@"LicenseFileCorrupt", nil)];
        }
        else {
          NSData *fileData = [[tmpFileReader readDataToEndOfFile] retain];
          [licenseText setStringValue:[[[NSString alloc] initWithData:fileData encoding:NSUTF8StringEncoding] autorelease]];
          [fileData release];
        }
      }
    }
  }
  
  return self;
}

- (void) dealloc
{
  LOG_ENTRY;
  
  // Save the defaults and release the objects
  // NOTE: This doesn't seem to be called, maybe RW doesn't call dealloc in this case
  Log(@"Saving defaults");
  NSUserDefaults *highLightDefaults = [NSUserDefaults standardUserDefaults];
  [highLightDefaults removePersistentDomainForName:kHLSHighLightDomain];
  [highLightDefaults setPersistentDomain:settings forName:kHLSHighLightDomain];
  [highLightDefaults synchronize];
  
  //[sourceHighlightCmd release];
  [settings release];
  
  // Remove our registered observer
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:NSApplicationDidFinishLaunchingNotification
                                                object:nil];
  [super dealloc];
}

///////////////////////////////////////////////////////////////////
//
// Adittional helper methods for accessing the plugin from our
// other classes.
//
///////////////////////////////////////////////////////////////////

+ (NSBundle*) sharedBundle
{
  return pluginBundle;
}

+ (HighLightPlugin *) sharedPlugin
{
  if (sharedPlugin == nil) {
    sharedPlugin = [[self alloc] init];
  }
  
  return sharedPlugin;
}

///////////////////////////////////////////////////////////////////
//
// Save and restore plugin settings.
//
// This is where you can save and restore your plugin's data to 
// and from the .rw3 file.
//
///////////////////////////////////////////////////////////////////

/*
 * Load data
 */
- (id)initWithCoder:(NSCoder *)aDecoder
{
  LOG_ENTRY;
  
  self = [super initWithCoder:aDecoder];
  self = [self init];

  return self;
}

/*
 * Save data
 */
- (void)encodeWithCoder:(NSCoder *)aCoder 
{
  LOG_ENTRY;
  
  [super encodeWithCoder:aCoder];
}


///////////////////////////////////////////////////////////////////
//
// Plugin Output
//
// This is where you return your plugin's content to RapidWeaver. 
// 
// Note: These methods will probably be called on a thread other than
// the main one so beware of calling APIs which are not background
// thread safe e.g. AppleScript, some parts of QuickTime, etc
//
///////////////////////////////////////////////////////////////////

- (id)contentHTML:(NSDictionary*)params
{
  LOG_ENTRY;
  
  id content = nil;
  
  return content;
}

- (id)pageFromPageID:(NSString*)pageID
{
  LOG_ENTRY;
  
  return nil;
}

- (NSString *)sidebarHTML:(NSDictionary*)params
{
  LOG_ENTRY;
  
  return nil;
}

- (NSArray *)extraFilesNeededInExportFolder:(NSDictionary*)params
{
  LOG_ENTRY;
  
  return nil;
}

+ (NSArray *)extraFilesNeededInExportFolder:(NSDictionary*)params
{
  LOG_ENTRY;
  
  return nil;
}

///////////////////////////////////////////////////////////////////
//
// Plugin boilerplate
//
// This is the basic machinery required of a plugin by RapidWeaver 
// to supply information like the plugin's name and icon.
//
///////////////////////////////////////////////////////////////////

+ (NSString *)pluginName
{
  LOG_ENTRY;
  NSBundle *mainBundle = [NSBundle bundleForClass:[self class]];
  
  return NSLocalizedStringFromTableInBundle(@"PluginName", nil, mainBundle, @"Localizable");
}

+ (NSString *)pluginType
{
  LOG_ENTRY;
  
  NSBundle *mainBundle = [NSBundle bundleForClass:[self class]];
  
  return NSLocalizedStringFromTableInBundle(@"PluginName", nil, mainBundle, @"Localizable");
}

+ (NSString *)pluginAuthor
{
  LOG_ENTRY;
  
  return @"Roger Nilsson"; 
}

+ (NSImage *)pluginIcon
{
  LOG_ENTRY;
  
  return nil;
}

+ (NSString *)pluginDescription;
{
  LOG_ENTRY;
  
  return nil;
}

- (BOOL) sourceHighlightCanChangePadding
{
  return sourceHighlightCanChangePadding;
}

- (void) setSourceHighlightCanChangePadding:(BOOL)value
{
  sourceHighlightCanChangePadding = value;
}

- (NSWindow *)documentWindow
{
  LOG_ENTRY;
  
  return _documentWindow;
}

- (void)setDocumentWindow:(NSWindow *)documentWindow
{
  LOG_ENTRY;
  
  _documentWindow = documentWindow;
  [_documentWindow retain];
}

- (NSString *)uniqueID
{
  LOG_ENTRY;
  
  return _uniqueID;
}

- (void)setUniqueID:(NSString *)aUniqueID
{
  LOG_ENTRY;
  
  _uniqueID = aUniqueID;
  [_uniqueID retain];
}

- (NSView *)userInteractionAndEditingView
{
  LOG_ENTRY;
  
  return nil;
}

///////////////////////////////////////////////////////////////////
//
// High-Light class methods.
//
///////////////////////////////////////////////////////////////////

/*
 * Create or regenerate our submenu.
 */
+ (void) createHighLightMenu
{
  LOG_ENTRY;
  
  // Create our menu if we haven't done so before
  if (highLightMenu == nil) {
    Log(@"Allocating a new menu");
    highLightMenu = [[NSMenu alloc] initWithTitle:PluginLocalizedString(@"MenuName", nil)];
    [highLightMenu setDelegate:[self sharedPlugin]];
    [highLightMenu setAutoenablesItems:YES];
  }
  else {
    Log(@"Removing all our menu items (%u)", [highLightMenu numberOfItems]);
    while ([highLightMenu numberOfItems])
      [highLightMenu removeItemAtIndex:0];
    // Clear the style cache
    [cachedHighLightStyles release];
    cachedHighLightStyles = nil;
  }
  
  // Populate our menu
  
  // Add menuitems for settings and help
  [highLightMenu addItemWithTitle:PluginLocalizedString(@"MenuItemSettings", nil)
                           action:@selector(onHighLightSettings:)
                    keyEquivalent:@""];
  [highLightMenu addItemWithTitle:PluginLocalizedString(@"MenuItemHelp", nil)
                           action:@selector(onHighLightHelp:)
                    keyEquivalent:@""];
  [highLightMenu addItem:[NSMenuItem separatorItem]];
  // Add the styles
  if (foundSourceHighlight) {
    // 'source-highlight' is available
    Log(@"Populating menu with languages");
    // Add menuitem for linenumbering
    NSObject<NSMenuItem> *useLineNumbersMenuItem =
      [highLightMenu addItemWithTitle:PluginLocalizedString(@"MenuItemLineNumber", nil)
                               action:@selector(onToggleHighLightSetting:)
                        keyEquivalent:@""];
    [useLineNumbersMenuItem setTag:(kHighLightOptionMenuItemTag | kLineNumberTag)];
#if 0
    // Add menuitem for generate anchor
    NSObject<NSMenuItem> *generateAnchorMenuItem =
      [highLightMenu addItemWithTitle:PluginLocalizedString(@"MenuItemGenerateAnchor", nil)
                               action:@selector(onToggleHighLightSetting:)
                        keyEquivalent:@""];
    [generateAnchorMenuItem setTag:(kHighLightOptionMenuItemTag | kGenerateAnchorTag)];
#endif
    // Add a separator
    [highLightMenu addItem:[NSMenuItem separatorItem]];
    NSArray *stylesArray = [HighLightPlugin highLightStyles];
    if (stylesArray == nil) {
      // We did not get any array to parse
      [highLightMenu addItemWithTitle:PluginLocalizedString(@"MenuEmptyError", nil)
                               action:@selector(onMenuError:)
                        keyEquivalent:@""];
    }
    else {
      NSEnumerator *e = [stylesArray objectEnumerator];
      NSDictionary *markupStyleDefinition;
      while (markupStyleDefinition = [e nextObject])
      {
        NSString *highlightName = [markupStyleDefinition objectForKey:kHighLightName];
        
        NSObject<NSMenuItem> *menuItem =
          [highLightMenu addItemWithTitle:highlightName
                                   action:@selector(applyMarkupAttributeToSelection:)
                            keyEquivalent:@""];
        
        [menuItem setTag:kHighLightTextMenuItemTag];
      }
    }
  }
  else {
    // 'source-highlight' was not found so we just put a small menu in place
    [highLightMenu addItemWithTitle:PluginLocalizedString(@"MenuEmptyWhy", nil)
                             action:@selector(onMenuEmpty:)
                      keyEquivalent:@""];
  }
}

/*
 * Add a new submenu to RapidWeavers "Edit" menu
 */
+ (void) addHighLightMenuItem
{
  LOG_ENTRY;
  
  // If we are called more than once
  if (addedHighLightMenuItem)
    return;
  
  // Create our menu
  [self createHighLightMenu];
  
  // Create our menu item in RapidWeavers main menu
  NSMenuItem *highLightMenuItem = [[NSMenuItem alloc] init];
  [highLightMenuItem setTitle:PluginLocalizedString(@"MenuName", nil)];
  [highLightMenuItem setAction:@selector(applyMarkupAttributeToSelection:)];
  [highLightMenuItem setSubmenu:highLightMenu];
  
  // Add this menu to RapidWeaver at the end of the 'Format' menu
  NSMenu *mainMenu = [[NSApplication sharedApplication] mainMenu];
  NSMenu *formatMenu = [[mainMenu itemWithTitle:PluginLocalizedString(@"RWFormatMenu", nil)] submenu];
  NSMenuItem *htmlMenuItem = [formatMenu itemWithTitle:PluginLocalizedString(@"HTML", nil)];
  int htmlMenuItemIndex = [formatMenu indexOfItem:htmlMenuItem];
  [formatMenu insertItem:highLightMenuItem atIndex:htmlMenuItemIndex+1];
  
  addedHighLightMenuItem = YES;
}


/*
 * An array of supported styles
 */
+ (NSArray *) highLightStyles
{
  LOG_ENTRY;
  
  // The styles are cached
  if (cachedHighLightStyles == nil) {
    // Version 1.x of source-highlight supported a fixed number of languages so
    // we have a static list defined
    if (([[[HighLightPlugin sharedPlugin] valueForKey:@"sourceHighlightVersion"] intValue] == 1)
        || (([[[HighLightPlugin sharedPlugin] valueForKey:@"sourceHighlightVersion"] intValue] == 2)
            && ([[[HighLightPlugin sharedPlugin] valueForKeyPath:kHLSUseDynamicMenu] boolValue] == NO))){
      // Get the path to the .plist that defines our styles
      NSString *highlightStylesPropertyListPath = nil;
      if ([[[HighLightPlugin sharedPlugin] valueForKey:@"sourceHighlightVersion"] intValue] == 1)
        highlightStylesPropertyListPath = [pluginBundle pathForResource:@"styles"
                                                                 ofType:@"plist"
                                                            inDirectory:@""];
      else
        highlightStylesPropertyListPath = [pluginBundle pathForResource:@"styles_v2"
                                                                 ofType:@"plist"
                                                            inDirectory:@""];
      Log(@"filterStylesPropertyListPath: %@", highlightStylesPropertyListPath);
      // Create an array from the .plist
      NSArray *highlightStylesPropertyList = [NSArray arrayWithContentsOfFile:highlightStylesPropertyListPath];
      if (highlightStylesPropertyList == nil) {
        // Something went wrong parsing the plist
        NSString *errorText = [NSString stringWithFormat:PluginLocalizedString(@"ErrorParsingPlist", nil), highlightStylesPropertyListPath];
        LogErr(errorText);
        NSAlert *alert = [NSAlert alertWithMessageText:PluginLocalizedString(@"HighLightError", nil)
                                         defaultButton:PluginLocalizedString(@"OKButton", nil)
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:errorText];
        [alert runModal];
        return nil;
      }
      Log(@"filterStylesPropertyList: %@", highlightStylesPropertyList);
      
      // Create and populate our array of styles
      cachedHighLightStyles = [[NSMutableArray alloc] init];
      NSArray *keys = [NSArray arrayWithObjects:kHighLightName, kHighLightCommand, nil];
      NSEnumerator *e = [highlightStylesPropertyList objectEnumerator];
      NSDictionary *propertyListEntry;
      while (propertyListEntry = [e nextObject]) {
        // Read our two keys
        NSString *name = [propertyListEntry objectForKey:@"Name"];
        Log(@"name: %@", name);
        NSString *styleCmd = [propertyListEntry objectForKey:@"HighLightCommand"];
        Log(@"cmd: %@", styleCmd);
        // Add our strings to an array
        NSArray *values = [NSArray arrayWithObjects:name, styleCmd, nil];
        // Create a dictionary with this entrys keys
        NSDictionary *markupStyle = [NSDictionary dictionaryWithObjects:values forKeys:keys];
        // Add our dictionary to the style array
        [cachedHighLightStyles addObject:markupStyle];
      }
    }
    else {
      // We have source-highlight version 2 or greater that can be extended by the
      // end user with more languages so we ask the application what it supports
      
      // Try to get the lang-list info
      NSError *oops = nil;
      NSData *output = [NSTask launchedTaskWithLaunchPath:[[HighLightPlugin sharedPlugin] valueForKey:@"pathToSourceHighlightBinary"]
                                                arguments:[NSArray arrayWithObject:@"--lang-list"]
                                            standardInput:nil
                                                    error:&oops];
      // Check if there was an error
      if (oops != nil) {
        // Something went wrong when we asked source-highlight
        NSString *errorText = [NSString stringWithFormat:PluginLocalizedString(@"ErrorQueringLangList", nil), [[oops userInfo] valueForKey:NSLocalizedDescriptionKey]];
        LogErr(errorText);
        NSAlert *alert = [NSAlert alertWithMessageText:PluginLocalizedString(@"HighLightError", nil)
                                         defaultButton:PluginLocalizedString(@"OKButton", nil)
                                       alternateButton:nil
                                           otherButton:nil
                             informativeTextWithFormat:errorText];
        [alert runModal];
        return nil;
      }
      // Convert the output into a string
      NSString *out_string = [[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding];
      // And into an array with each line as one entry
      NSArray *tmpArray = [out_string componentsSeparatedByString:@"\n"];
      [out_string release];
      Log(@"Languages: %@", tmpArray);
      
      // Prepare the styles list
      cachedHighLightStyles = [[NSMutableArray alloc] init];
      NSArray *keys = [NSArray arrayWithObjects:kHighLightName, kHighLightCommand, nil];
      NSEnumerator *e = [tmpArray objectEnumerator];
      NSString *entry;
      while (entry = [e nextObject]) {
        //
        Log(@"Entry: %@", entry);
        NSArray *tmpValues = [entry substringsCapturedByPattern:@"(.*) = (.*)(.lang)"];
        Log(@"Values: %@", tmpValues);
        if (tmpValues == nil)
          continue;
        NSAssert([tmpValues count] == 4, @"Unknown content found in output from 'source-highlight'.");
        // tmpValues is now an array containing:
        // [0]: The whole match
        // [1]: The name of the language
        // [2]: The name of the language file (exluding the suffix)
        // [3]: ".lang"
        NSArray *values = [NSMutableArray arrayWithObjects:[[tmpValues objectAtIndex:1] capitalizedString], [tmpValues objectAtIndex:2], nil];
        // Create a dictionary with this entrys keys
        NSDictionary *markupStyle = [NSDictionary dictionaryWithObjects:values forKeys:keys];
        // Add our dictionary to the style array
        [cachedHighLightStyles addObject:markupStyle];
      }
    }
  }
    
  return cachedHighLightStyles;
}

/*
 * Returns the highlight style state for the current selection
 */
+ (NSNumber *) highlightEnabledForFilterStyleInSelectedRange:(NSString *)highlightStyleName
{
  LOG_ENTRY;
  
  NSResponder *firstResponder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
  
  if ([firstResponder respondsToSelector:@selector(highlightEnabledForFilterStyleInSelectedRange:)])
    return [firstResponder performSelector:@selector(highlightEnabledForFilterStyleInSelectedRange:)
                                withObject:highlightStyleName];
  else
    return nil;
}

/*
 * Returns the options state for the current selection
 */
+ (NSNumber *) highlightOptionEnabledForFilterStyleInSelectedRange:(int)highlightOptionTag
{
  LOG_ENTRY;
  
  NSResponder *firstResponder = [[[NSApplication sharedApplication] keyWindow] firstResponder];
  
  if ([firstResponder respondsToSelector:@selector(highlightOptionEnabledForFilterStyleInSelectedRange:)])
    return [firstResponder performSelector:@selector(highlightOptionEnabledForFilterStyleInSelectedRange:)
                                withObject:[NSNumber numberWithInt:highlightOptionTag]];
  else
    return nil;
}

///////////////////////////////////////////////////////////////////
//
// High-Light instance methods.
//
///////////////////////////////////////////////////////////////////

/*
 * Called whenever the menu needs to be updated.
 */
- (void) menuNeedsUpdate:(NSMenu *)menu
{
  LOG_ENTRY;
  
  NSArray *menuItems = [highLightMenu itemArray];
  NSMenuItem *menuItem;
  
  NSEnumerator *e = [menuItems objectEnumerator];
  while (menuItem = [e nextObject]) {
    if([menuItem tag] == kHighLightTextMenuItemTag)
      [menuItem setState:[[HighLightPlugin highlightEnabledForFilterStyleInSelectedRange:[menuItem title]] boolValue]];
    else if (([menuItem tag] & kHighLightOptionMenuItemTag) == kHighLightOptionMenuItemTag)
      [menuItem setState:[[HighLightPlugin highlightOptionEnabledForFilterStyleInSelectedRange:[menuItem tag]] boolValue]];
    else
      continue;
  }
}

/*
 * Open the browser and go to my homepage.
 */
- (IBAction) goVisitMyWebsite:(id)sender
{
  LOG_ENTRY;
  
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:(NSString *)kHLDonateLink]];
}

/*
 * Open a modal alert box explaining why the menu is empty.
 */
- (void) myMenuIsEmpty:(NSWindow *)window
{
  LOG_ENTRY;
  
  Log(@"Window: %@", window);
  
  // Init an alert
  NSAlert *alert = [[[NSAlert alloc] init] autorelease];
  [alert addButtonWithTitle:PluginLocalizedString(@"OKButton", nil)];
  
  // Set values for the missing binary
  [alert addButtonWithTitle:PluginLocalizedString(@"CancelButton", nil)];
  [alert addButtonWithTitle:PluginLocalizedString(@"DownloadButton", nil)];
  [alert setMessageText:PluginLocalizedString(@"MenuEmptyWhy", nil)];
  [alert setInformativeText:PluginLocalizedString(@"WhyIsTheMenuEmptyText", nil)];
  // Display the alert
  [alert setAlertStyle:NSInformationalAlertStyle];
  [alert beginSheetModalForWindow:window
                    modalDelegate:[HighLightPlugin sharedPlugin]
                   didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                      contextInfo:nil];
}

/*
 * Open our modal settings dialog.
 */
- (void) highLightHelp:(NSWindow *)window
{
  [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:(NSString *)kHLHelpLink]];
}

/*
 * Called when the alert box above returns.
 */
- (void) alertDidEnd:(NSWindow *)sheet
          returnCode:(int)returnCode
         contextInfo:(void *)contextInfo
{
  LOG_ENTRY;
  if (returnCode == NSAlertThirdButtonReturn) {
    // Download was requested, compose the url and send it to the browser
    // TODO: Should I convert spaces to '_' ??
    NSString *downloadURL = [(NSString *)kNPDownloadHLPage stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    Log(@"Download: %@", downloadURL);
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:downloadURL]];
  }
}

/*
 * Open our modal settings dialog.
 */
- (void) highLightSettings:(NSWindow *)window
{
  LOG_ENTRY;
  
#if ENABLE_LOGGING
  // For debugging purposes I will print all params that are sent to
  // to this function.
  NSEnumerator *aEnum = [settings keyEnumerator];
  id aKey;
  while ((aKey = [aEnum nextObject])) {
    Log(@"Key: %@ Value: %@", aKey, [settings objectForKey:aKey]);
  }
#endif
  
  // Display the modal sheet
  [NSApp beginSheet:settingsWindow
     modalForWindow:window
      modalDelegate:[HighLightPlugin sharedPlugin]
     didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
        contextInfo:NULL];
   
}

/*
 * Called when the user clicked the OK button.
 */
- (IBAction)theSheetOK:(id)sender
{
  LOG_ENTRY;
  
#if ENABLE_LOGGING
  // For debugging purposes I will print all params that are sent to
  // to this function.
  NSEnumerator *aEnum = [settings keyEnumerator];
  id aKey;
  while ((aKey = [aEnum nextObject])) {
    Log(@"Key: %@ Value: %@", aKey, [settings objectForKey:aKey]);
  }
#endif
  
  // Close the sheet window
  [NSApp endSheet:settingsWindow returnCode:NSOKButton];
  [settingsWindow orderOut:nil];
  
  // TODO: Possible target for improvement
  // If the user edited the path but didn't press enter we store the setting which will force validation
  if ( ! [[sourceHighLightPath stringValue] isEqualTo:[self valueForKeyPath:kHLSPathToSourceHighlight]]) {
    [self setValue:[sourceHighLightPath stringValue] forKeyPath:kHLSPathToSourceHighlight];
  }
  
  // Save the changed defaults
  NSUserDefaults *highLightDefaults = [NSUserDefaults standardUserDefaults];
  [highLightDefaults removePersistentDomainForName:kHLSHighLightDomain];
  [highLightDefaults setPersistentDomain:settings forName:kHLSHighLightDomain];
  [highLightDefaults synchronize];
  Log(@"Wraptag: %@", [self valueForKeyPath:@"settings.wraptag"]);
}

/*
 * Called when the user clicked the Cancel button.
 */
- (IBAction)theSheetCancel:(id)sender
{
  LOG_ENTRY;
  
  // Close the sheet window
	[NSApp endSheet:settingsWindow returnCode:NSCancelButton];
	[settingsWindow orderOut:nil];
}

/*
 * Called when one of our sheets closes.
 */
- (void) sheetDidEnd:(NSWindow *)sheet
          returnCode:(int)returnCode
         contextInfo:(void *)contextInfo
{
  LOG_ENTRY;
  
  // Check which sheet that finished
  if (sheet == settingsWindow) {
    Log(@"Calling window: settingsWindow");
  }
}


/*
 * Called when the user wants to browse after 'source-highlight'.
 */
- (IBAction) theSheetBrowse:(id)sender
{
  LOG_ENTRY;
  
  NSOpenPanel *openPanel = [NSOpenPanel openPanel];
  [openPanel beginSheetForDirectory:nil
                               file:nil
                              types:nil
                     modalForWindow:[sender window]
                      modalDelegate:[HighLightPlugin sharedPlugin]
                     didEndSelector:@selector(filePanelDidEnd:
                                              returnCode:
                                              contextInfo:)
                        contextInfo:nil];
}

/*
 * Called when the user is finished with the NSOpenPanel.
 */
- (void) filePanelDidEnd:(NSOpenPanel *)openPanel
              returnCode:(int)returnCode
             contextInfo:(void *)contextInfo {
  LOG_ENTRY;
  
  // Close the panel
  [openPanel close];
  
  if (returnCode == NSOKButton) {
    Log(@"OK pressed");
    // Store the new path
    [self setValue:[openPanel filename] forKeyPath:kHLSPathToSourceHighlight];
  }
  else {
    Log(@"Cancel pressed");
  }
}

/*
 * Checks if the given path is a valid 'source-highlight' binary. It will either
 * display a modal error dialog or just log to the console.
 */
- (BOOL) validateSourceHighlightBinary:(NSString *)pathToBinary
                          displayError:(BOOL)displayError
{
  LOG_ENTRY;
  
  BOOL errorFound = NO;
  
  // Check if there is any file at all
  NSString *pathToCmd = [pathToBinary stringByExpandingTildeInPath];
  Log(@"Path to cmd: %@", pathToCmd);
  if (![[NSFileManager defaultManager] fileExistsAtPath:pathToCmd]) {
    LogErr(@"File not found: %@", pathToCmd);
    errorFound = YES;
    goto displayerror;
  }
  
  // Try to get the version info
  NSError *oops = nil;
  NSData *output = [NSTask launchedTaskWithLaunchPath:pathToCmd
                                            arguments:[NSArray arrayWithObject:@"--version"]
                                        standardInput:nil
                                                error:&oops];
  // Check if there was an error
  // NOTE: We are currently treating the failure to accept the argument '--version'
  //       as if the binary is not 'source-highlight' since it has always accepted
  //       that argument
  errorFound = NO;
  if (oops != nil) {
    LogErr(@"Error was: %@", [[oops userInfo] valueForKey:NSLocalizedDescriptionKey]);
    errorFound = YES;
    goto displayerror;
  }
  // Convert the output into a string
  NSString *out_string = [[[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding] autorelease];
  
  // Check if it actually is 'source-highlight' that the user selected
  NSRange checkRange = [out_string rangeOfString:@"source-highlight"];
  if (checkRange.location == NSNotFound) {
    LogErr(@"Error was: Not a valid 'source-highlight' binary");
    errorFound = YES;
    goto displayerror;
  }
  
  // Try to find out which version it is
  Log(@"Version: %@", [out_string substringMatchedByPattern:@"[0-9]\\.[0-9]*"]);
  float version = [[out_string substringMatchedByPattern:@"[0-9]\\.[0-9]*"] floatValue];
  if (version >= 2.0f) {
    // NOTE: To be strict we should check for v2.1 since v2.0 does not support custom
    //       output format language. But since I doubt that anyone is using v2.0 this
    //       will be "good enough"
    Log(@"Version 2");
    [self setValue:[NSNumber numberWithInt:2] forKey:@"sourceHighlightVersion"];
    [useStaticMenuBtn setEnabled:YES];
    // Check if we have a binary that supports changing the linenumberpadding
    if (version >= 2.8f) {
      [self setSourceHighlightCanChangePadding:YES];
    }
    else {
      [self setSourceHighlightCanChangePadding:NO];
    }
  }
  else {
    Log(@"Version 1");
    [self setValue:[NSNumber numberWithInt:1] forKey:@"sourceHighlightVersion"];
    [self setSourceHighlightCanChangePadding:NO];
    [useStaticMenuBtn setEnabled:NO];
  }
  
displayerror:
  // If an error was detected display the error
  if (errorFound) {
    // Put a 'n/a' string in the gui
    [sourceHighLightText setStringValue:PluginLocalizedString(@"NotApplicable", nil)];
    if (displayError) {
      // Display a modal alertbox with our error
      [self displayError:[NSString stringWithFormat:PluginLocalizedString(@"NotAValidSourceHighLight", nil), pathToCmd]];
    }
    [useStaticMenuBtn setEnabled:NO];
    return NO;
  }
  
  // Put the version text into the gui
  [sourceHighLightText setStringValue:out_string];
  Log(@"Source-Highlight version: %@", out_string);
  
  return YES;
}

/*
 * Displays a modal dialogue with the given error text.
 */
- (void) displayError:(NSString *)errorText
{
  LOG_ENTRY;
  
  NSAlert *alert = [NSAlert alertWithMessageText:PluginLocalizedString(@"HighLightError", nil)
                                   defaultButton:PluginLocalizedString(@"OKButton", nil)
                                 alternateButton:nil
                                     otherButton:nil
                       informativeTextWithFormat:errorText];
  [alert runModal];
}

/*
 * Return the start tag.
 */
- (NSString *) wrapTagStart
{
  LOG_ENTRY;
  
  if (wrapTags == nil)
    return @"<p>";
  NSDictionary *tagDict = [wrapTags objectAtIndex:[[self valueForKeyPath:@"settings.wraptag"] intValue]];
  
  return [tagDict valueForKey:@"start"];
}

/*
 * Return the end tag.
 */
- (NSString *) wrapTagEnd
{
  LOG_ENTRY;
  
  if (wrapTags == nil)
    return @"</p>";
  NSDictionary *tagDict = [wrapTags objectAtIndex:[[self valueForKeyPath:@"settings.wraptag"] intValue]];
  
  return [tagDict valueForKey:@"end"];
}

/*
 * Read the 'tags.plist' file and populate the array.
 */
- (void) setupWrapTags
{
  LOG_ENTRY;
  
  // Get the path to the .plist that defines our tags
  NSString *wrapTagsPropertyListPath = [pluginBundle pathForResource:@"tags"
                                                              ofType:@"plist"
                                                         inDirectory:@""];
  Log(@"wrapTagsPropertyListPath: %@", wrapTagsPropertyListPath);
  // Create an array from the .plist
  NSArray *tmpArray = [NSArray arrayWithContentsOfFile:wrapTagsPropertyListPath];
  if (tmpArray == nil) {
    // Something went wrong parsing the plist
    NSString *errorText = [NSString stringWithFormat:PluginLocalizedString(@"ErrorParsingPlist", nil), wrapTagsPropertyListPath];
    NSLog(errorText);
    NSAlert *alert = [NSAlert alertWithMessageText:PluginLocalizedString(@"HighLightError", nil)
                                     defaultButton:PluginLocalizedString(@"OKButton", nil)
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:errorText];
    [alert runModal];
    return;
  }
  Log(@"tags: %@", tmpArray);
  
  // Prepare the styles list
  NSMutableArray *tags = [[NSMutableArray alloc] init];
  NSArray *keys = [NSArray arrayWithObjects:@"name", @"start", @"end", nil];
  NSEnumerator *e = [tmpArray objectEnumerator];
  NSDictionary *entry;
  while (entry = [e nextObject]) {
    // Read the name...
    NSString *tagname = [entry objectForKey:@"tag"];
    // ...and the tags
    NSString *start = [entry objectForKey:@"start"];
    Log(@"start: %@", start);
    NSString *end = [entry objectForKey:@"end"];
    Log(@"end: %@", end);
    // Add our strings to an array
    NSArray *values = [NSArray arrayWithObjects:tagname, start, end, nil];
    // Create a dictionary with this entrys keys
    NSDictionary *theTag = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    // Add our dictionary to the style array
    [tags addObject:theTag];
  }
  wrapTags = [NSArray arrayWithArray:tags];
  [tags release];
  Log(@"Tagnames: %@", wrapTags);
  
  // Check that the save index for the wrapped tag is within the boundaries of the array
  if ([[self valueForKeyPath:kHLSWrapTag] intValue] >= [wrapTags count])
    [self setValue:[NSNumber numberWithInt:0] forKeyPath:kHLSWrapTag];
}

///////////////////////////////////////////////////////////////////
//
// KVO methods
//
///////////////////////////////////////////////////////////////////

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object 
                        change:(NSDictionary *)change
                       context:(void *)context
{
  LOG_ENTRY;
  
#if ENABLE_LOGGING
  // For debugging purposes I will print all params that are sent to this function.
  NSEnumerator *aEnum = [change keyEnumerator];
  id aKey;
  while ((aKey = [aEnum nextObject])) {
    Log(@"Key: %@ Value: %@", aKey, [change objectForKey:aKey]);
  }
#endif
  
  Log(@"Key: %@", keyPath);
  BOOL validateBinary = NO;
  if ([keyPath isEqualTo:kHLSUseDynamicMenu]) {
    // User changed the dynamic menu option
    Log(@"Dynamic menu option changed");
  }
  else if ([keyPath isEqualTo:kHLSUseExternalBinary]) {
    // User changed the external binary option
    Log(@"External binary option changed");
    // Get the path to our bundled binary
    [pathToSourceHighlightBinary release];
    if ([[change objectForKey:NSKeyValueChangeNewKey] boolValue] == NO)
    pathToSourceHighlightBinary = [pluginBundle pathForResource:@"source-highlight"
                                                         ofType:nil
                                                    inDirectory:@"source-highlight/bin"];
    else
      pathToSourceHighlightBinary = [self valueForKeyPath:kHLSPathToSourceHighlight];
    [pathToSourceHighlightBinary retain];
    validateBinary = YES;
  }
  else if ([keyPath isEqualTo:kHLSPathToSourceHighlight]) {
    // User changed the path to source-highlight
    Log(@"Path to binary changed");
    [pathToSourceHighlightBinary release];
    pathToSourceHighlightBinary = [change objectForKey:NSKeyValueChangeNewKey];
    [pathToSourceHighlightBinary retain];
    validateBinary = YES;
  }
  else if([keyPath isEqualToString:kHLSLineNumberPadding]) {
    // User changed the linenumber padding
    validateBinary = YES;
  }
  
  // Validate the binary incase it was changed manually by the user
  if (validateBinary == YES) {
    Log(@"New path: %@", pathToSourceHighlightBinary);
    foundSourceHighlight = [self validateSourceHighlightBinary:pathToSourceHighlightBinary
                                                  displayError:YES];
  }
  // Regenerate our menu
  Log(@"Regenerate our menu");
  [HighLightPlugin createHighLightMenu];
}

///////////////////////////////////////////////////////////////////
//
// Delegates
//
///////////////////////////////////////////////////////////////////

/*
 * Return a custom fieldeditor if applicable.
 */
- (id) windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)anObject
{
  // Check if it is the correct textfield
  if (anObject == sourceHighLightPath) {
    LOG_ENTRY;
    // Allocate a new fieldeditor if we haven't done that before
    if (fileDropView == nil)
      fileDropView = [[RNDropTextView alloc] init];
    [fileDropView setFieldEditor:YES];
    
    return fileDropView;
  }
  
  return nil;
}

///////////////////////////////////////////////////////////////////
//
// Notifications
//
///////////////////////////////////////////////////////////////////

/*
 * Called when RapidWeaver has finished launching.
 */
+ (void)applicationDidFinishLaunching:(NSNotification*)aNotification
{
  // Add our menu
  [self addHighLightMenuItem];
}

@end

///////////////////////////////////////////////////////////////////
//
// Constants
//
///////////////////////////////////////////////////////////////////

// URL to my homepage
const NSString* const kHLDonateLink = @"https://www.paypal.com/cgi-bin/webscr?cmd=_xclick&business=su%70p%6frt%40ni%6crog%73pl%61ce%2ese&item_name=High%2dLight&item_number=v1%2e2&no_shipping=1&cn=Additional%20information&tax=0&currency_code=EUR&lc=SE&bn=PP%2dDonationsBF&charset=UTF%2d8";
const NSString* const kNPDownloadHLPage = @"http://nilrogsplace.se/webdesign/rapidweaver/plugins/high-light/";

// Tag for our highlight style items
const int kHighLightTextMenuItemTag = 6003;
// Master tag for our highlight option items
const int kHighLightOptionMenuItemTag = 9000;
// Minor tag for our highlight option items
const int kLineNumberTag = 1;
const int kGenerateAnchorTag = 2;

// .plist items
const NSString* const kHighLightCommand = @"highlightCommand";
const NSString* const kHighLightName = @"name";
const NSString* const kHLHelpLink = @"http://docs.google.com/Doc?id=dccrvrfq_3dqfnz5";
