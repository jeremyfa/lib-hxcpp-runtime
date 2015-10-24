//
//  HXObject.m
//  HXCPPRuntime
//
//  Created by Jeremy FAIVRE on 19/10/2015.
//  Copyright © 2015 Jeremy Faivre. All rights reserved.
//

//  Note: this file is built with HXCPP instead of Xcode HXCPPRuntime target

#import "HXObject.h"

#include <hxcpp.h>
#include <hx/CFFI.h>

@interface HXObject ()

@property AutoGCRoot *haxeInstance;

- (instancetype)initWithHaxeInstance:(AutoGCRoot *)haxeInstance;

@end

@implementation HXObject

- (instancetype)init {
    self = [super init];
    if (self) {
        self.haxeInstance = NULL;
    }
    return self;
}

- (instancetype)initWithHaxeInstance:(AutoGCRoot *)haxeInstance {
    self = [super init];
    if (self) {
        self.haxeInstance = haxeInstance;
    }
    return self;
}

- (void)dealloc {
    if (self.haxeInstance != NULL) {
        delete self.haxeInstance;
    }
}

@end
