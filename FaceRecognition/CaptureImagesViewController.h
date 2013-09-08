//
//  CaptureImagesViewController.h
//  FaceRecognition
//
//  Created by Michael Peterson on 2012-11-16.
//
//

#import <UIKit/UIKit.h>
#import <opencv2/highgui/cap_ios.h>
#import "FaceDetector.h"
#import "RecognizeViewController.h"
#import "VotingFaceRecognizer.h"

@interface CaptureImagesViewController : RecognizeViewController <CvVideoCameraDelegate>

- (void)parseFaces:(const std::vector<cv::Rect> &)faces forImage:(cv::Mat&)image;
- (bool)learnFace:(const std::vector<cv::Rect> &)faces forImage:(cv::Mat&)image;

@property (nonatomic, strong) IBOutlet UIButton *cameraButton;
@property (nonatomic, strong) NSNumber *personID;
@property (nonatomic) NSInteger frameNum;
@property (nonatomic) NSInteger numPicsTaken;

@end
