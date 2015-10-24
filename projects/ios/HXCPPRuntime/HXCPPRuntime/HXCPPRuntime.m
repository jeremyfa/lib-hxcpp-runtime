//
//  HXCPPRuntime.m
//  HXCPPRuntime
//
//  Created by Jeremy FAIVRE on 19/10/2015.
//  Copyright © 2015 Jeremy Faivre. All rights reserved.
//

#import "HXCPPRuntime.h"
#import "HXCPPRuntimeObjcInterface.h"

const char *hxRunLibrary();
void hxcpp_set_top_of_stack();

@implementation HXCPPRuntime

+ (HXCPPRuntime * __nonnull)sharedRuntime {
    static dispatch_once_t onceToken;
    static HXCPPRuntime *sharedRuntime;
    
    dispatch_once(&onceToken, ^{
        // Init HXCPP
        hxcpp_set_top_of_stack();
        const char *err = NULL;
        err = hxRunLibrary();
        
        // Init ObjC runtime instance
        sharedRuntime = [[self.class alloc] init];
    });
    
    return sharedRuntime;
}

- (void)sayHello:(NSString * __nonnull)name {
    [HXHello sayHello:name];
}

- (void)runCPPIAFileAtPath:(NSString * __nonnull)path {
    [HXCPPIA run:path];
}

@end
