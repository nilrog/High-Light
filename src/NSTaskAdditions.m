//
//  NSTaskAdditions.m
//
//  Copyright 2006 Andre Pang
//  Copyright 2007 Roger Nilsson
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

#import "NSTaskAdditions.h"
#include <unistd.h>

//---------------------------------------------------------------------------

@interface NSFileManager (TemporaryFileCreating)

+ (NSString *) pathToEmptyTemporaryFile;

@end

//---------------------------------------------------------------------------

@implementation NSFileManager (TemporaryFileCreating)

+ (NSString *) pathToEmptyTemporaryFile
{
  char* const pathTemplate = strdup("/tmp/temp.XXXXXXXXXX");
  char* const cPath = mktemp(pathTemplate);
  
  NSString* path = [NSString stringWithUTF8String:cPath];
  
  const int fileDescriptor = open(cPath, O_WRONLY|O_CREAT|O_EXCL, S_IRUSR|S_IWUSR);
  if(fileDescriptor == -1) {
    perror("open failed");
    
    return nil;
  }
  
  const int closeReturnValue = close(fileDescriptor);
  if (closeReturnValue != 0)
    NSLog(@"fclose() returned %d instead of 0?", closeReturnValue);
  
  free(pathTemplate);
  
  return path;
}

@end

//***************************************************************************

@interface NSString (ShellQuoting)

- (NSString*) stringByShellQuoting;

@end

//---------------------------------------------------------------------------

@implementation NSString (ShellQuoting)

- (NSString*) stringByShellQuoting
{
  NSMutableString* shellQuotedString = [NSMutableString stringWithString:self];
  
  [shellQuotedString replaceOccurrencesOfString:@"'" withString:@"'\\''" options:0 range:NSMakeRange(0, [shellQuotedString length])];
  
  [shellQuotedString insertString:@"'" atIndex:0];
  [shellQuotedString insertString:@"'" atIndex:[shellQuotedString length]];
  
  return shellQuotedString;
}

@end

//***************************************************************************

@implementation NSTask (StringPipeAdditions)

+ (NSData*) launchedTaskWithLaunchPath:(NSString*)path
                             arguments:(NSArray*)arguments
                         standardInput:(NSData*)stdinData
                                 error:(NSError **)error
{
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  
  NSString* stdinTemporaryFilePath = [NSFileManager pathToEmptyTemporaryFile];
  [stdinData writeToFile:stdinTemporaryFilePath atomically:NO];
  
  NSString* stdoutTemporaryFilePath = [NSFileManager pathToEmptyTemporaryFile];
  NSString* stderrTemporaryFilePath = [NSFileManager pathToEmptyTemporaryFile];
  
  NSMutableArray* quotedArguments = [[[NSMutableArray alloc] init] autorelease];
  NSEnumerator* e = [arguments objectEnumerator];
  NSString* argument;
  while(argument = [e nextObject]) [quotedArguments addObject:[argument stringByShellQuoting]];
  
  NSString* commandLineString = [NSString stringWithFormat:@"%@ %@ < %@ > %@ 2> %@",
    [path stringByShellQuoting],
    [quotedArguments componentsJoinedByString:@" "],
    [stdinTemporaryFilePath stringByShellQuoting],
    [stdoutTemporaryFilePath stringByShellQuoting],
    [stderrTemporaryFilePath stringByShellQuoting]];
  
  const int systemReturnValue = system([commandLineString UTF8String]);
  assert(systemReturnValue != -1 && systemReturnValue != 127);
  
  NSFileHandle* temporaryFileReader = [NSFileHandle fileHandleForReadingAtPath:stdoutTemporaryFilePath];
  NSData* stdoutData = [[temporaryFileReader readDataToEndOfFile] retain];
  
  if (systemReturnValue != 0) {
    // Get the error from stderr
    temporaryFileReader = [NSFileHandle fileHandleForReadingAtPath:stderrTemporaryFilePath];
    NSData* stderrData = [[temporaryFileReader readDataToEndOfFile] retain];
    // The application wrote something to stderr so we take that as a failure
    NSString *description = [[[NSString alloc] initWithData:stderrData encoding:NSUTF8StringEncoding] autorelease];
    NSLog(@"Description: %@", description);
    NSArray *objectArray = [NSArray arrayWithObjects:description, nil];
    NSArray *keyArray = [NSArray arrayWithObjects:NSLocalizedDescriptionKey, nil];
    NSDictionary *errorDict = [NSDictionary dictionaryWithObjects:objectArray
                                                          forKeys:keyArray];
    // Initialize the error object if it is nil
    if (error != nil)
      *error = [[[NSError alloc] initWithDomain:NSPOSIXErrorDomain 
                                           code:0 userInfo:errorDict] retain];
  }
  
  // Delete the temporary files
  [[NSFileManager defaultManager] removeFileAtPath:stdinTemporaryFilePath handler:nil];
  [[NSFileManager defaultManager] removeFileAtPath:stdoutTemporaryFilePath handler:nil];
  [[NSFileManager defaultManager] removeFileAtPath:stderrTemporaryFilePath handler:nil];
  
  [pool release];
  
  return [stdoutData autorelease];
}

@end

//---------------------------------------------------------------------------
