//
//  MultiResult.m
//  FaceRecognition
//
//  Created by Justin Van Winkle on 9/7/13.
//  Updated by Patrick Reilly on 2014-05-13.
//

#import "MultiResult.h"

@implementation MultiResult

-(id)init {
    self = [super init];
    if (self) {
        self.results = [[NSMutableArray alloc] init];
        self.personName = @"Unknown";
        
    }
    return self;
}

-(void)addResult:(RecognitionResult *)result {
    [self.results addObject:result];
}

-(int)personID {
    //NSMutableDictionary *counts = [[NSMutableDictionary alloc] init];
    for (RecognitionResult* result in self.results) {
        return result.personID;
//        if (counts[@(result.personID)] == nil)
//            counts[@(result.personID)] = @0;
//        counts[@(result.personID)] = @(INT(counts[@(result.personID)]) + 1);
//    }
//    for (id key in counts) {
//        int times_seen = INT(counts[key]);
//        if (times_seen > 1) {
//            return INT(key);
//        }
    }
    return -1;
}


@end
