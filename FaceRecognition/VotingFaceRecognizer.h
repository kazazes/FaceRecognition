//
//  VotingFaceRecognizer.h
//  FaceRecognition
//
//  Created by Justin Van Winkle on 9/6/13.
//
//

#import <Foundation/Foundation.h>
#import <opencv2/highgui/cap_ios.h>
#import <sqlite3.h>

#import "CustomFaceRecognizer.h"
#import "MultiResult.h"

@interface VotingFaceRecognizer : NSObject
{
    sqlite3 *_db;
}

@property (nonatomic, strong) NSMutableArray *faceRecognizers;
@property (nonatomic) BOOL loaded;
@property (nonatomic) int lastID;

- (int)newPersonWithName:(NSString *)name;
- (NSMutableArray *)getAllPeople;
- (BOOL)trainModel;
- (void)forgetAllFacesForPersonID:(int)personID;
- (void)learnFace:(cv::Rect)face ofPersonID:(int)personID fromImage:(cv::Mat&)image;
- (cv::Mat)pullStandardizedFace:(cv::Rect)face fromImage:(cv::Mat&)image;
- (MultiResult*)recognizeFace:(cv::Rect)face inImage:(cv::Mat&)image;
@end
