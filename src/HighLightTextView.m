//
//  HighLightTextView.m
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

#import "HighLightTextView.h"
#import "HighLightPlugin.h"
#import "NSTaskAdditions.h"
#import "RNLogging.h"

#define PluginLocalizedString(key, comment) [[HighLightPlugin sharedBundle] localizedStringForKey:(key) value:@"" table:nil]

///////////////////////////////////////////////////////////////////
//
// HighLightTextView
//
///////////////////////////////////////////////////////////////////
@implementation HighLightTextView

/**
 * Remove all formatting from the selected text.
 */
- (void) removeFormattingFromSelection:(id)sender
{
  LOG_ENTRY;
  
  [[self textStorage] removeAttribute:kRWTextViewMarkupDirectivesAttributeName range:[self selectedRange]];
  
  [super removeFormattingFromSelection:sender];
}

/**
 * Apply a background color for the selected range. 
 */
- (void) drawBackgroundForCharactersInRange:(NSRange)range withColour:(NSColor*)colour
{
  LOG_ENTRY;
  
  NSDictionary *attributeValue = [[self textStorage] attribute:kRWTextViewMarkupDirectivesAttributeName
                                                       atIndex:range.location
                                                effectiveRange:NULL];
  
  // Look four our tag and if it is found apply our color
  if ([[attributeValue objectForKey:@"name"] isEqualTo:@"highlight"]) {
    NSColor *highLightColor = [NSColor colorWithCalibratedRed:(255/255.0f)
                                                        green:(255/255.0f)
                                                         blue:(153/255.0f)
                                                        alpha:1.0];
    [super drawBackgroundForCharactersInRange:range withColour:highLightColor];
  }
  else {
    // Not our tag so we pass it on
    [super drawBackgroundForCharactersInRange:range withColour:colour];
  }
}

/*
 * Apply the selceted markup to the current selection
 */
- (IBAction) applyMarkupAttributeToSelection:(id)sender
{
  LOG_ENTRY;
  
  // Check if it is our tag
  if ([sender tag] == kHighLightTextMenuItemTag) {
    Log(@"High-Light tag detected");
    NSRange range = [self selectedRange];
    // Apply attribute only if a range is selected
    if (range.length > 0) {
      // Get the current attributes, if any
      id maybeAttribute = [[self textStorage] attribute:kRWTextViewMarkupDirectivesAttributeName
                                                atIndex:range.location
                                         effectiveRange:NULL];
      // Check if the style to be applied is the same as the one who is already applied
      if ([[maybeAttribute objectForKey:@"style"] isEqualTo:[sender title]]) {
        Log(@"Removing attribute: %@", [sender title]);
        [[self textStorage] removeAttribute:kRWTextViewMarkupDirectivesAttributeName range:range];
        [[self textStorage] removeAttribute:NSFontAttributeName range:range];
        [[self textStorage] removeAttribute:NSToolTipAttributeName range:range];
      }
      else {
        // New attributes to apply
        Log(@"Adding attribute: %@", [sender title]);
        BOOL linenumber = [[[HighLightPlugin sharedPlugin] valueForKeyPath:kHLSUseLineNumbers] boolValue];
        [[self textStorage] removeAttribute:kRWTextViewMarkupDirectivesAttributeName range:range];
        NSString *markupStyle = [[sender title] lowercaseString];
        NSDictionary *markupFilterAttribute = [NSDictionary dictionaryWithObjectsAndKeys:
          @"highlight", @"name",
          markupStyle, @"style",
          [NSNumber numberWithBool:linenumber], @"linenumber",
          //[NSNumber numberWithBool:[[[HighLightPlugin sharedPlugin] valueForKeyPath:kHLSGenerateAnchors] boolValue]], @"anchor",
          [NSNumber numberWithBool:NO], @"anchor",
          nil];
        Log(@"OK");
        NSString *toolTip = [NSString stringWithString:markupStyle];
        if (linenumber) {
          Log(@"Linenumbers detected");
          toolTip = [toolTip stringByAppendingFormat:@" %@", PluginLocalizedString(@"ToolTipWithLineNumbers", nil)];
        }
        NSDictionary *markupFilterAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
          markupFilterAttribute, kRWTextViewMarkupDirectivesAttributeName,
          [NSFont fontWithName:@"Courier" size:10.0], NSFontAttributeName,
          toolTip, NSToolTipAttributeName,
          nil];
        [[self textStorage] addAttributes:markupFilterAttributes range:range];
        
        [[self textStorage] removeAttribute:kRWTextViewIgnoreFormattingAttributeName range:range];
        [[self textStorage] removeAttribute:NSParagraphStyleAttributeName range:range];
        [[self textStorage] removeAttribute:NSForegroundColorAttributeName range:range];
        [[self textStorage] removeAttribute:NSBackgroundColorAttributeName range:range];
        
        // Remove any attributes for attachments
        NSRange textAttachmentRange;
        unsigned int textAttachmentLocation;
        for ( textAttachmentLocation = range.location;
              textAttachmentLocation < range.location + range.length;
              textAttachmentLocation = textAttachmentRange.location + textAttachmentRange.length) {
          NSDictionary* maybeTextAttachment = [[self textStorage] attribute:NSAttachmentAttributeName
                                                                    atIndex:textAttachmentLocation
                                                      longestEffectiveRange:&textAttachmentRange
                                                                    inRange:range];
          
          if (maybeTextAttachment != nil) {
            [[self textStorage] removeAttribute:kRWTextViewMarkupDirectivesAttributeName 
                                          range:textAttachmentRange];                    
          }
        }
      }
    }
    // We have changed the content so we tell the world about it
    [self didChangeText];
  }
  else {
    // Not our tag so we pass it on
    [super applyMarkupAttributeToSelection:sender];
  }
}

/*
 * Returns the highlight style state for the current selection
 */
- (NSNumber *) highlightEnabledForFilterStyleInSelectedRange:(NSString *)highlightStyleName
{
  LOG_ENTRY;
  
  NSRange range = [self selectedRange];
  
  NSLog(@"Selected range is %u/%u", range.location, range.length);
  
  NSDictionary *highLightStyleAttribute = nil;
  if(range.length == 0) {
    highLightStyleAttribute = [[self typingAttributes] objectForKey:kRWTextViewMarkupDirectivesAttributeName];
  }
  else {
    NSRange longestRange;
    
    highLightStyleAttribute = [[self textStorage] attribute:kRWTextViewMarkupDirectivesAttributeName
                                                    atIndex:range.location
                                      longestEffectiveRange:&longestRange
                                                    inRange:range];
    
    if(longestRange.location > range.location
       || (longestRange.location + longestRange.length) < (range.location + range.length)) {
      return [NSNumber numberWithBool:NO];
    }
  }
  
  if (highLightStyleAttribute == nil)
    return [NSNumber numberWithBool:NO];
  
  NSString *styleAttribute = [highLightStyleAttribute objectForKey:@"style"];
  if (styleAttribute == nil)
    return [NSNumber numberWithBool:NO];
  else if ([styleAttribute caseInsensitiveCompare:highlightStyleName] == NSOrderedSame)
    return [NSNumber numberWithBool:YES];
  
  return [NSNumber numberWithBool:NO];
}

/*
 * Returns the options state for the current selection
 */
- (NSNumber *) highlightOptionEnabledForFilterStyleInSelectedRange:(NSNumber *)highlightOptionTag
{
  LOG_ENTRY;
  
  NSRange range = [self selectedRange];
  Log(@"Option is: %@", highlightOptionTag);
  Log(@"Selected range is %u/%u", range.location, range.length);
  
  NSDictionary *highLightStyleAttribute = nil;
  if (range.length == 0) {
    highLightStyleAttribute = [[self typingAttributes] objectForKey:kRWTextViewMarkupDirectivesAttributeName];
  }
  else {
    NSRange longestRange;
    
    highLightStyleAttribute = [[self textStorage] attribute:kRWTextViewMarkupDirectivesAttributeName
                                                    atIndex:range.location
                                      longestEffectiveRange:&longestRange
                                                    inRange:range];
    
    if(longestRange.location > range.location
       || (longestRange.location + longestRange.length) < (range.location + range.length)) {
      return [NSNumber numberWithBool:NO];
    }
  }
  
  if (highLightStyleAttribute == nil)
    return [NSNumber numberWithBool:NO];
  
  // Validate the correct option
  NSNumber *result;
  int tag = [highlightOptionTag intValue];
  if ((tag & kGenerateAnchorTag) == kGenerateAnchorTag)
    //result = [highLightStyleAttribute objectForKey:@"anchor"];
    result = nil;
  else if ((tag & kLineNumberTag) == kLineNumberTag)
    result = [highLightStyleAttribute objectForKey:@"linenumber"];
  else
    result = nil;
  Log(@"Result: %@", result);
  
  return result;
}

/*
 * Validate our menu items
 */
- (BOOL)validateMenuItem:(NSMenuItem *)item
{
  LOG_ENTRY;
  
  // Check if the menu item is one of our options
  if (([item tag] & kHighLightOptionMenuItemTag) == kHighLightOptionMenuItemTag) {
    Log(@"Validating high-light option, %u. Text length is %u", kHighLightOptionMenuItemTag, [[self textStorage] length]);
    // Get the current position
    NSRange range = [self selectedRange];
    // Get the attributes
    id maybeAttribute = nil;
    if(range.length == 0) {
      maybeAttribute = [[self typingAttributes] objectForKey:kRWTextViewMarkupDirectivesAttributeName];
    }
    else {
      maybeAttribute = [[self textStorage] attribute:kRWTextViewMarkupDirectivesAttributeName
                                             atIndex:range.location
                                      effectiveRange:NULL];
    }
    // Enable the menu item only if the selection is marked with our tag
    if ([[maybeAttribute objectForKey:@"name"] isEqualTo:@"highlight"]) {
      return YES;
#if 0
      // The anchor option can only be selected if linenumbers are applied
      if ([[item title] isEqualTo:PluginLocalizedString(@"MenuItemGenerateAnchor", nil)]) {
        if ([[maybeAttribute valueForKey:@"linenumber"] boolValue])
          return YES;
        else
          return NO;
      }
#endif
    }
    else
      return NO;
  }
  else if ([item tag] == kHighLightTextMenuItemTag) {
    // We have no special needs here
    return YES;
  }
  
  // Not our menu item so pass it on
  return [super validateMenuItem:item];
}

/*
 * Display an alert why the menu is empty
 */
- (void) onMenuEmpty:(id)sender
{
  LOG_ENTRY;
  
  [[HighLightPlugin sharedPlugin] myMenuIsEmpty:[self window]];
}

/*
 * Display an alert why the menu is empty
 */
- (void) onMenuError:(id)sender
{
  LOG_ENTRY;
  
  LogErr(@"High-Light has failed to create a menu!");
}

/*
 * Display help for our plugin.
 */
- (void) onHighLightHelp:(id)sender
{
  LOG_ENTRY;
  
  [[HighLightPlugin sharedPlugin] highLightHelp:[self window]];
}

/*
 * Display settings for our plugin.
 */
- (void) onHighLightSettings:(id)sender
{
  LOG_ENTRY;
  
  [[HighLightPlugin sharedPlugin] highLightSettings:[self window]];
}

/*
 * User toggled one of the formatting options.
 */
- (void) onToggleHighLightSetting:(id)sender
{
  LOG_ENTRY;
  
  Log(@"Sender: %@", sender);
  
  // NOTE: We can only be called if we have already confirmed that we are inside
  //       one of our tags so it should be safe to skip checking again
  
  // TODO: Change the 'linenumbers' attribute for the selected text.
  NSRange range = [self selectedRange];
  Log(@"Selected range is %u/%u", range.location, range.length);
  // If we are at the end of the string location == length which will cause
  // an out-of-bounds exception
  if (range.location == [[self textStorage] length])
    range.location = [[self textStorage] length] - 1;
  // TODO: Remove this check for correct attribute according to the note above
  id maybeAttribute = [[self textStorage] attribute:kRWTextViewMarkupDirectivesAttributeName
                                            atIndex:range.location
                                     effectiveRange:NULL];
  Log(@"Current attribute: %@", [maybeAttribute objectForKey:@"style"]);
  // If no style attribute is found skip the rest
  if ([maybeAttribute objectForKey:@"style"] == nil)
    return;
  // End TODO
  
  // Get the range of the current selection
  NSRange markupRange;
  NSRange rangeLimit;
  rangeLimit.location = 0;
  rangeLimit.length = [[self textStorage] length];
  NSMutableDictionary *markupAttribute = [[NSMutableDictionary alloc] init];
  [markupAttribute addEntriesFromDictionary:[[self textStorage] attribute:kRWTextViewMarkupDirectivesAttributeName
                                                                  atIndex:range.location
                                                    longestEffectiveRange:&markupRange
                                                                  inRange:rangeLimit]];
  Log(@"Highlight range is %u/%u", markupRange.location, markupRange.length);
  
  // Toggle the value of the attributes
  BOOL linenumber = [[markupAttribute valueForKey:@"linenumber"] boolValue];
  if (([sender tag] & kLineNumberTag) == kLineNumberTag) {
    // linenumber
    Log(@"Flipping the linenumber");
    linenumber = ! linenumber;
    [markupAttribute setValue:[NSNumber numberWithBool:linenumber] forKey:@"linenumber"];
  }
#if 0
  else if (([sender tag] & kGenerateAnchorTag) == kGenerateAnchorTag) {
    // anchor
    Log(@"Flipping the anchor");
    BOOL anchor = ! [[markupAttribute valueForKey:@"anchor"] boolValue];
    [markupAttribute setValue:[NSNumber numberWithBool:anchor] forKey:@"anchor"];
  }
#endif
  // Change the tooltip
  NSString *newTooltip = nil;
  if (linenumber)
    newTooltip = [NSString stringWithFormat:@"%@ %@", [markupAttribute objectForKey:@"style"],
      PluginLocalizedString(@"ToolTipWithLineNumbers", nil)];
  else
    newTooltip = [NSString stringWithString:[markupAttribute objectForKey:@"style"]];
  Log(@"newTooltip: %@", newTooltip);
  
  // Remove the current attributes and add our modified attributes
  [[self textStorage] removeAttribute:kRWTextViewMarkupDirectivesAttributeName range:markupRange];
  [[self textStorage] removeAttribute:NSToolTipAttributeName range:range];
  NSDictionary *markupAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
    markupAttribute, kRWTextViewMarkupDirectivesAttributeName,
    newTooltip, NSToolTipAttributeName,
    nil];
  [[self textStorage] addAttributes:markupAttributes range:markupRange];
  [markupAttribute release];
  
  // We have changed the content so we tell the world about it
  [self didChangeText];
}

@end


///////////////////////////////////////////////////////////////////
//
// HighLightHTML
//
///////////////////////////////////////////////////////////////////
@implementation HighLightHTML

/*
 * Return the 'source-highlight' command argument for the given style.
 */
- (NSString *) highlightStyleArgument:(NSString *)styleName
{
  LOG_ENTRY;
  
  NSEnumerator *e = [[HighLightPlugin highLightStyles] objectEnumerator];
  NSDictionary *styleDefinition;
  while (styleDefinition = [e nextObject]) {
    if ([[styleDefinition objectForKey:kHighLightName] caseInsensitiveCompare:styleName] == NSOrderedSame) {
      return [NSString stringWithFormat:@"--src-lang=%@", [styleDefinition objectForKey:kHighLightCommand]];
    }
  }
  
  return nil;
}

/*
 * The 'exportAttributedString' method is overridden so that we can apply our special
 * formatting. We copy the attributed string and replace the part which is formatted
 * with our tags. When we are done with our part we pass our copy of the string with
 * the replaced text to the super method that will continue to apply correct formatting.
 */
- (NSString *) exportAttributedString:(NSAttributedString*)str
                              toPath:(NSString*)path
                        imagesFolder:(NSString*)imagesFolder
                         imagePrefix:(NSString*)imagePrefix
                        HTMLTemplate:(NSMutableString*)theTemplate
                          contentTag:(NSString*)contentTag
                            fromPage:(id)thePage
                     depthCorrection:(int)depthCorrection
{
  LOG_ENTRY;
  
  // Convert all High-Light attributes first
  NSAttributedString *myString = [self exportHighLightAttributedString:str
                                                                toPath:path
                                                          imagesFolder:imagesFolder
                                                           imagePrefix:imagePrefix
                                                          HTMLTemplate:theTemplate
                                                            contentTag:contentTag
                                                              fromPage:thePage
                                                       depthCorrection:depthCorrection];
  
  // Return the result of the super method
  return [super exportAttributedString:myString
                                toPath:path
                          imagesFolder:imagesFolder
                           imagePrefix:imagePrefix
                          HTMLTemplate:theTemplate
                            contentTag:contentTag
                              fromPage:thePage
                       depthCorrection:depthCorrection];
}

/*
 * The 'exportAttributedString' method is overridden so that we can apply our special
 * formatting. We copy the attributed string and replace the part which is formatted
 * with our tags. When we are done with our part we pass our copy of the string with
 * the replaced text to the super method that will continue to apply correct formatting.
 *
 * This is for RW 4.0.
 */
- (NSString *) exportAttributedString:(NSAttributedString*)str
                               toPath:(NSString*)path
                         imagesFolder:(NSString*)imagesFolder
                          imagePrefix:(NSString*)imagePrefix
                         HTMLTemplate:(NSMutableString*)theTemplate
                           contentTag:(NSString*)contentTag
                             fromPage:(id)thePage
                      depthCorrection:(int)depthCorrection
                           exportMode:(RWExportMode)exportMode
{
  LOG_ENTRY;
  
  // Convert all High-Light attributes first
  NSAttributedString *myString = [self exportHighLightAttributedString:str
                                                                toPath:path
                                                          imagesFolder:imagesFolder
                                                           imagePrefix:imagePrefix
                                                          HTMLTemplate:theTemplate
                                                            contentTag:contentTag
                                                              fromPage:thePage
                                                       depthCorrection:depthCorrection];
  
  // Return the result of the super method
  return [super exportAttributedString:myString
                                toPath:path
                          imagesFolder:imagesFolder
                           imagePrefix:imagePrefix
                          HTMLTemplate:theTemplate
                            contentTag:contentTag
                              fromPage:thePage
                       depthCorrection:depthCorrection
                            exportMode:exportMode];
}

- (NSAttributedString *) exportHighLightAttributedString:(NSAttributedString*)str
                                                  toPath:(NSString*)path
                                            imagesFolder:(NSString*)imagesFolder
                                             imagePrefix:(NSString*)imagePrefix
                                            HTMLTemplate:(NSMutableString*)theTemplate
                                              contentTag:(NSString*)contentTag
                                                fromPage:(id)thePage
                                         depthCorrection:(int)depthCorrection
{
  
  // Make a copy of the string to work with
  NSMutableAttributedString* myString = [[NSMutableAttributedString alloc] initWithAttributedString:str];
  [myString autorelease];
  
  // This range is the full range of the string to be parsed
  NSRange range;
  range.location = 0;
  range.length = [myString length];
  
#if 0
  // Counter for number of anchors applied
  unsigned int numHighLightAnchors = 0;
#endif
  
  // Fetch number of spaces to replace tabs with
  int numspaces = [[[HighLightPlugin sharedPlugin] valueForKeyPath:kHLSNumberOfTabs] intValue];
  NSMutableString *tabReplace = [NSMutableString stringWithCapacity:(numspaces*6)];
  while (numspaces-- > 0) {
    [tabReplace appendString:@"&nbsp;"];
  }
  
  // Loop through the entire string
  unsigned int i;
  for ( i=0; i<[myString length]; i=range.location+range.length ) {
    // This range is the limit of our workarea
    NSRange rangeLimit;
    rangeLimit.location = 0;
    rangeLimit.length = [myString length];
    
    // Look for a 'kRWTextViewMarkupDirectivesAttributeName'
    NSDictionary *attributeValue = [myString attribute:kRWTextViewMarkupDirectivesAttributeName
                                               atIndex:i
                                 longestEffectiveRange:&range
                                               inRange:rangeLimit];
    Log(@"Checking for RWTextViewMarkup attribute");
    if (attributeValue != nil) {
      NSMutableAttributedString *replacedAttributedString = nil;
      unsigned int newRange = 0;
      
      Log(@"Attribute: %@", [attributeValue objectForKey:@"name"]);
      if ([[attributeValue objectForKey:@"name"] isEqualToString:@"highlight"]) {
        // HighLight markup attribute found
        NSString* styleName = [attributeValue objectForKey:@"style"];
        Log(@"HighLight found: %u/%u (%@)", range.location, range.length, styleName);
        
        // Extract the raw string so that we can pass it on to the console
        NSMutableString *string = [NSMutableString stringWithString:[[myString attributedSubstringFromRange:range] string]];
        // Convert CR+LF to LF
        [string replaceOccurrencesOfString:@"\r\n" withString:@"\n" options:0 range:NSMakeRange(0, [string length])];
        // Convert CR to LF
        [string replaceOccurrencesOfString:@"\r" withString:@"\n" options:0 range:NSMakeRange(0, [string length])];
        NSData *stringData = [string dataUsingEncoding:NSUTF8StringEncoding];
        
        // Create the commandline for 'source-highlight'
        NSMutableArray *cmdArguments = [[NSMutableArray alloc] init];
        NSString *styleArgument = [self highlightStyleArgument:styleName];
        BOOL linenumber = [[attributeValue valueForKey:@"linenumber"] boolValue];
        if (styleArgument != nil) {
          // The style is found so we can convert the text
          [cmdArguments addObject:styleArgument];
          // Use html output instead of xhtml. The generated code will still be xhtml valid in most cases
          // but we also avoid having to do a workaround for the generated output
          [cmdArguments addObject:@"--out-format=html"];
          if (linenumber) {
            // Add linenumbers
#if 0
            if ([[attributeValue valueForKey:@"anchor"] boolValue]) {
              // With anchors
              if ([[[HighLightPlugin sharedPlugin] valueForKey:@"sourceHighlightVersion"] intValue] < 2) {
                // source-highlight v1.x
                
                // source-highlight before version 2.0 does not support multiple anchors without manually
                // tweaking the generated output. That might be something to add for the future but for
                // now we will only generate anchors for the first high-light on one page.
                if (numHighLightAnchors < 1)
                  [cmdArguments addObject:@"--line-number-ref"];
                else
                  [cmdArguments addObject:@"--line-number"];
              }
              else {
                // source-highlight >= 2.x
                [cmdArguments addObject:[NSString stringWithFormat:@"--line-number-ref=%02u-", numHighLightAnchors]];
              }
              // Advance the counter
              numHighLightAnchors++;
            }
            else {
#endif
              // Without anchors
              
              // Read the padding if it's supported
              if ([[HighLightPlugin sharedPlugin] sourceHighlightCanChangePadding] == YES) {
                if ([[[HighLightPlugin sharedPlugin] valueForKeyPath:kHLSLineNumberPadding] intValue] == 0)
                  [cmdArguments addObject:@"--line-number= "];
                else
                  [cmdArguments addObject:@"--line-number"];
              }
              else {
                [cmdArguments addObject:@"--line-number"];
              }
#if 0
            }
#endif
          }
          // Inlined CSS for colors
          if (! [[[HighLightPlugin sharedPlugin] valueForKeyPath:kHLSApplyInlineColorCSS] boolValue]) {
            [cmdArguments addObject:@"--css=\"\""];
            [cmdArguments addObject:@"--no-doc"];
          }
          
          // Filter the string through 'source-highlight'
          Log(@"Arguments: %@", cmdArguments);
          NSError *oops = nil;
          //NSData* filteredData = [NSTask launchedTaskWithLaunchPath:[[[HighLightPlugin sharedPlugin] valueForKeyPath:kHLSPathToSourceHighlight] stringByExpandingTildeInPath]
          NSData* filteredData = [NSTask launchedTaskWithLaunchPath:[[[HighLightPlugin sharedPlugin] valueForKey:@"pathToSourceHighlightBinary"] stringByExpandingTildeInPath]
                                                          arguments:cmdArguments
                                                      standardInput:stringData
                                                              error:&oops];
          [cmdArguments release];
          [filteredData retain];
          
          if (oops != nil) {
            // An error ocurred, display the error and return the original attributed string
            LogErr(@"Error was: %@", [[oops userInfo] valueForKey:NSLocalizedDescriptionKey]);
            [[HighLightPlugin sharedPlugin] displayError:[NSString stringWithString:[[oops userInfo] valueForKey:NSLocalizedDescriptionKey]]];
            return str;
          }
          
          // Create a new string with the result
          NSMutableString *replacedString = [[NSMutableString alloc] initWithData:filteredData
                                                                         encoding:NSUTF8StringEncoding];
          [filteredData release];
          
          // Wrap the string inside the user-selected tags instead of the default <pre><tt>...</tt></pre> tags
          [replacedString replaceOccurrencesOfString:@"<pre><tt>" withString:[[HighLightPlugin sharedPlugin] wrapTagStart] options:0
                                               range:NSMakeRange(0, [replacedString length])];
          [replacedString replaceOccurrencesOfString:@"</tt></pre>" withString:[[HighLightPlugin sharedPlugin] wrapTagEnd] options:0
                                               range:NSMakeRange(0, [replacedString length])];
          
          // TODO: This should only be done if the wraptag is not <pre>
          NSRange checkRange = [replacedString rangeOfString:@"<pre>"];
          if (checkRange.location == NSNotFound) {
            Log(@"Replacing all double spaces with double &nbsp;");
            // Replace all double spaces with &nbsp;'s to make sure we preserve indentation
            [replacedString replaceOccurrencesOfString:@"  " withString:@"&nbsp;&nbsp;" options:0
                                                 range:NSMakeRange(0, [replacedString length])];
            // Replace all tabs with a configurable number of &nbsp;'s to make sure we preserve indentation
            [replacedString replaceOccurrencesOfString:@"\t" withString:tabReplace options:0 range:NSMakeRange(0, [replacedString length])];
          }
          
          // TODO: source-highlight likes to generate "empty" spans (aka. <span> </span>) which fails to
          //       validate so we replace the space with one &nbsp;
          [replacedString replaceOccurrencesOfString:@"> </span>" withString:@">&nbsp;</span>" options:0
                                               range:NSMakeRange(0, [replacedString length])];
          
          // TODO: Maybe generate unique anchors for each block on the page. This is supported by
          //       'source-highlight' >= 2.0 but for 1.11 we have to do it manually.
          
          // Assemble a new attributed string 
          replacedAttributedString = [[NSMutableAttributedString alloc] initWithString:replacedString];
          [replacedAttributedString beginEditing];
          
          // Get the range of the surrounding tags
          NSRange openTagRange = [replacedString rangeOfString:[[HighLightPlugin sharedPlugin] wrapTagStart]];
          NSAssert((openTagRange.location != NSNotFound && openTagRange.length != 0), @"Starttag not found!");
          NSRange closeTagRange = [replacedString rangeOfString:[[HighLightPlugin sharedPlugin] wrapTagEnd]];
          NSAssert((closeTagRange.location != NSNotFound && closeTagRange.length != 0), @"Closetag not found!");
          
          // We need to apply some ignore formatting attributes to parts of our string to prevent RW
          // from adding <br /> tags in unwanted places.
          NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],
            kRWTextViewIgnoreFormattingAttributeName,nil];
          Log(@"string length: %u", [replacedString length]);
#if 0
          // Make sure that the opentag range starts from the beginning
          openTagRange.length += openTagRange.location;
          openTagRange.location = 0;
#endif
          Log(@"opentag range: %u, %u", openTagRange.location, openTagRange.length);
          [replacedAttributedString setAttributes:attributes range:openTagRange];
          // Extend the closetag range to the end of the string
          closeTagRange.length = [replacedString length] - closeTagRange.location;
          Log(@"closetag range: %u, %u", closeTagRange.location, closeTagRange.length);
          [replacedAttributedString setAttributes:attributes range:closeTagRange];
          // Delete any text that is present before our wraptag starts
          [replacedAttributedString replaceCharactersInRange:NSMakeRange(0, openTagRange.location) withString:@""];
          [replacedAttributedString endEditing];
          // Release the string
          [replacedString release];
          replacedString = nil;
          // Calculate the new length of the string
          newRange = [replacedAttributedString length];
        }
        else {
          // The style is not supported by the current 'source-highlight' configuration
          NSString *replacedString = [[NSString alloc] initWithFormat:PluginLocalizedString(@"NonSupportedLanguageOutput", nil), styleName];
          newRange = [replacedString length];
          // Add some style to the error message
          NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSFont fontWithName:@"Courier-Bold" size:12.0], NSFontAttributeName,
            nil];
          replacedAttributedString = [[NSMutableAttributedString alloc] initWithString:replacedString attributes:attributes];
          [replacedString release];
          replacedString = nil;
        }
        
        // Replace the tagged string with our new reformatted string
        [myString replaceCharactersInRange:range withAttributedString:replacedAttributedString];
        [replacedAttributedString release];
        replacedAttributedString = nil;
        
        // Advance the counter
        range.length = newRange;
      }
    }
  }
  
  return myString;
}

@end