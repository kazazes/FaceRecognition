//
//  RecognitionResult.h
//  FaceRecognition
//
//  Created by Justin Van Winkle on 9/7/13.
//
//

#import <Foundation/Foundation.h>

@interface RecognitionResult : NSObject

- (id)initWithPersonID:(int)personID confidence:(float)confidence method:(NSString*)method;

@property (nonatomic) int personID;
@property (nonatomic) float confidence;
@property (nonatomic, strong) NSString* method;


@end
