//
//  RecognitionResult.m
//  FaceRecognition
//
//  Created by Justin Van Winkle on 9/7/13.
//
//

#import "RecognitionResult.h"

@implementation RecognitionResult

- (id)initWithPersonID:(int)personID confidence:(float)confidence method:(NSString*)method
{
    self = [super init];
    if (self) {
        self.personID = personID;
        self.confidence = confidence;
        self.method = method;
    }
    
    return self;
}

@end
