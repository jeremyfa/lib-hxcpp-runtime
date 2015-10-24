//
//  HXObjcRef.m
//  HXCPPRuntime
//
//  Created by Jeremy FAIVRE on 19/10/2015.
//  Copyright © 2015 Jeremy Faivre. All rights reserved.
//

#import "HXObjcRef.h"

// See http://perpendiculo.us/2009/09/synchronized-nslock-pthread-osspinlock-showdown-done-right/comment-page-1/
// for thread lock performance. In this case, OSSpinLock seems quite relevant.
#import <libkern/OSAtomic.h>
OSSpinLock sHXObjcRefSpinLock = OS_SPINLOCK_INIT;

/**
 Pure C function that will be called by haxe's IDHolder instances
 */
void _hx_objc_release_id(int instance_id) {
    [HXObjcRef releaseObjectAtIndex:(NSInteger)instance_id];
}

@implementation HXObjcRef

+ (id)objectAtIndex:(NSInteger)index {
    OSSpinLockLock(&sHXObjcRefSpinLock);
    id result = [[self refsDictionary] objectForKey:@(index)];
    OSSpinLockUnlock(&sHXObjcRefSpinLock);
    return result;
}

+ (NSInteger)nextObjectIndex {
    static NSInteger sCurrentIndex = 0;
    OSSpinLockLock(&sHXObjcRefSpinLock);
    NSInteger next = sCurrentIndex++;
    OSSpinLockUnlock(&sHXObjcRefSpinLock);
    return next;
}

+ (NSInteger)retainObject:(id)objcObject {
    NSInteger index = [self nextObjectIndex];
    if (!objcObject) return index;
    OSSpinLockLock(&sHXObjcRefSpinLock);
    [[self refsDictionary] setObject:objcObject forKey:@(index)];
    OSSpinLockUnlock(&sHXObjcRefSpinLock);
    return index;
}

+ (void)releaseObjectAtIndex:(NSInteger)objectIndex {
    OSSpinLockLock(&sHXObjcRefSpinLock);
    [[self refsDictionary] removeObjectForKey:@(objectIndex)];
    OSSpinLockUnlock(&sHXObjcRefSpinLock);
}

+ (NSMutableDictionary *)refsDictionary {
    static dispatch_once_t onceToken;
    static NSMutableDictionary *sDict;
    dispatch_once(&onceToken, ^{
        sDict = [NSMutableDictionary dictionary];
    });
    return sDict;
}

@end
