//
//  ExceptionHandler.h
//  HudHud
//
//  Created by patrick on 19.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

// ExceptionHandler.h

#import <Foundation/Foundation.h>

// Function to install the uncaught exception handler
void InstallUncaughtExceptionHandler(void);

// Interface declaration for the exception handler class
@interface ExceptionHandler : NSObject

// Method to deliberately cause an uncaught exception for testing
+ (void)causeUncaughtException;

@end
