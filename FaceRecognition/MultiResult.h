//
//  MultiResult.h
//  FaceRecognition
//
//  Created by Justin Van Winkle on 9/7/13.
//
//

#import <Foundation/Foundation.h>
#import "RecognitionResult.h"

@interface MultiResult : NSObject

-(void)addResult:(RecognitionResult*)result;

@property (nonatomic, strong) NSMutableArray* results;
@property (nonatomic, readonly) int personID;
@property (nonatomic, strong) NSString* personName;

@end
