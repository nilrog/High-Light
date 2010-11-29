//
//  RNDropTextView.m
//
//  Created by Roger Nilsson on 2007-03-15.
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

#import "RNDropTextView.h"
#import "RNLogging.h"


@implementation RNDropTextView

- (void)awakeFromNib
{
  LOG_ENTRY;
  
  // Register for correct types
	[self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
}

- (NSDragOperation) draggingEntered:(id <NSDraggingInfo>)sender
{
  LOG_ENTRY;
  
  NSDragOperation sourceMask = [sender draggingSourceOperationMask];
  NSPasteboard *pboard = [sender draggingPasteboard];
  if ([[pboard types] containsObject:NSFilenamesPboardType]) {
    if (sourceMask & NSDragOperationLink)
      return NSDragOperationLink;
  }
  
  return NSDragOperationNone;
}

- (BOOL) performDragOperation:(id <NSDraggingInfo>)sender
{
  LOG_ENTRY;
  
  NSPasteboard *pboard = [sender draggingPasteboard];
  if ([[pboard types] containsObject:NSFilenamesPboardType]) {
    NSArray *fileNames = [pboard propertyListForType:NSFilenamesPboardType];
    [self setString:[fileNames objectAtIndex:0]];
    // We have changed the content so we tell the world about it
    [self didChangeText];
    
    return YES;
  }
  
  return NO;
}

@end
