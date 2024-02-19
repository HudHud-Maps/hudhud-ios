//
//  ExceptionHandler.m
//  HudHud
//
//  Created by patrick on 19.02.24.
//  Copyright © 2024 HudHud. All rights reserved.
//

// ExceptionHandler.m

#import "ExceptionHandler.h"
#include <libkern/OSAtomic.h>
#include <execinfo.h>

void postNSStringSynchronouslyWithNSURLConnection(NSString *dataString, NSURL *url) {
	// Convert NSString to NSData
	NSData *postData = [dataString dataUsingEncoding:NSUTF8StringEncoding];
	
	// Create a request
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
														   cachePolicy:NSURLRequestUseProtocolCachePolicy
													   timeoutInterval:60.0];
	[request setHTTPMethod:@"POST"];
	[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	[request setHTTPBody:postData];
	
	// Declare a variable to hold the response
	NSURLResponse *response = nil;
	NSError *error = nil;
	
	// Send the request synchronously
	NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	
	// Check for an error
	if (error) {
		NSLog(@"Error: %@", error);
	} else {
		// No error, process the response
		NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
		NSLog(@"Response: %@", responseString);
	}
}

// Function that handles an uncaught exception
void HandleException(NSException *exception) {
	NSLog(@"PAT Uncaught exception: %@", exception);
	postNSStringSynchronouslyWithNSURLConnection([exception description], [NSURL URLWithString:@"https://httpdebugging.subzero.eu/debug"]);
	// NSLog(@"PAT Stack trace: %@", [exception callStackSymbols]);
	// Here, you can add code to log the exception details to a file,
	// send them to a server, or perform other custom error handling.
}

// Function to install the uncaught exception handler
void InstallUncaughtExceptionHandler(void) {
	NSSetUncaughtExceptionHandler(&HandleException);
}

// Implementation of the ExceptionHandler class
@implementation ExceptionHandler

// Method to deliberately cause an uncaught exception for testing
+ (void)causeUncaughtException {
	NSArray *array = @[@"This will", @"cause", @"an exception"];
	NSString *element = array[5]; // Accessing out of bounds will cause an exception
	NSLog(@"%@", element); // This line is just to suppress unused variable warnings
}

@end
