//
//  HXCPPRuntime.h
//  HXCPPRuntime
//
//  Created by Jeremy FAIVRE on 19/10/2015.
//  Copyright © 2015 Jeremy Faivre. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for HXCPPRuntime.
FOUNDATION_EXPORT double HXCPPRuntimeVersionNumber;

//! Project version string for HXCPPRuntime.
FOUNDATION_EXPORT const unsigned char HXCPPRuntimeVersionString[];

@interface HXCPPRuntime : NSObject

/**
 Get the HXCPPRuntime shared instance.
 This method must be called at least once before interacting
 with any HXCPPRuntime-dependent API
 */
+ (HXCPPRuntime * __nonnull)sharedRuntime;

/**
 Just an example method to `say hello` from HXCPP
 */
- (void)sayHello:(NSString * __nonnull)name;

/**
 Load and run the given CPPIA script file.
 */
- (void)runCPPIAFileAtPath:(NSString * __nonnull)path;

@end

