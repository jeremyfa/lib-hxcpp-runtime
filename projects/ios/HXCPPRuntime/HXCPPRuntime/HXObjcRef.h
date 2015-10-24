//
//  HXObjcRef.h
//  HXCPPRuntime
//
//  Created by Jeremy FAIVRE on 19/10/2015.
//  Copyright © 2015 Jeremy Faivre. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Utilities to keep track of Objective-C objects from Haxe/CPP code.
 This class is thread-safe
 */
@interface HXObjcRef : NSObject

+ (id)objectAtIndex:(NSInteger)index;

+ (NSInteger)retainObject:(id)objcObject;

+ (void)releaseObjectAtIndex:(NSInteger)objectIndex;

@end
