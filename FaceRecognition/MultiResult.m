//
//  MultiResult.m
//  FaceRecognition
//
//  Created by Justin Van Winkle on 9/7/13.
//
//

#import "MultiResult.h"

@implementation MultiResult

-(id)init {
    self = [super init];
    if (self) {
        self.results = [[NSMutableArray alloc] init];
        
    }
    return self;
}

-(void)addResult:(RecognitionResult *)result {
    [self.results addObject:result];
    NSLog(@"Added result %@ out of %i", result, [self.results count]);
    
}

-(int)personID {
    NSLog(@"getting personID from %i results", [self.results count]);
    for (RecognitionResult* result in self.results) {
        NSLog(@"Method %@ matched %i", result.method, result.personID);
        return result.personID;
    }
    return -1;
}


@end
