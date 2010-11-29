//
//  RNLogging.h
//
//  Created by Roger Nilsson on 2006-11-19.
//  Copyright 2006 Roger Nilsson. All rights reserved.
//

#if ENABLE_LOGGING
  #define LOG_ENTRY NSLog(@"Entered: %s (%@:%d)", __func__, [[NSString stringWithCString:__FILE__] lastPathComponent], __LINE__);
  #define Log NSLog
#else
  #define LOG_ENTRY
  #define Log(...) do {} while(0);
#endif

#define LogErr NSLog