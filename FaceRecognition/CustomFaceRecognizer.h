//
//  CustomFaceRecognizer.h
//  FaceRecognition
//
//  Created by Michael Peterson on 2012-11-16.
//
//

#import <Foundation/Foundation.h>
#import <opencv2/highgui/cap_ios.h>
#import "RecognitionResult.h"

@interface CustomFaceRecognizer : NSObject
{
    cv::Ptr<cv::FaceRecognizer> _model;
}

@property (nonatomic, strong) NSString* method;
@property (nonatomic) BOOL trained;

- (void)saveModel;
- (BOOL)loadModel;
- (id)initWithMethod:(NSString*)method;
- (BOOL)trainModel:(std::vector<cv::Mat>)images withLabels:(std::vector<int>)labels;
- (RecognitionResult *)recognizeFace:(cv::Rect)face inImage:(cv::Mat&)image;

@end
