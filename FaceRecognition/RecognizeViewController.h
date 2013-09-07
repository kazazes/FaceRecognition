//
//  RecognizeViewController.h
//  FaceRecognition
//
//  Created by Michael Peterson on 2012-11-16.
//
//

#import <UIKit/UIKit.h>
#import <opencv2/highgui/cap_ios.h>
#import "FaceDetector.h"
#import "VotingFaceRecognizer.h"

@interface RecognizeViewController : UIViewController <CvVideoCameraDelegate>

@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) IBOutlet UILabel *instructionLabel;
@property (nonatomic, strong) IBOutlet UILabel *confidenceLabel;
@property (nonatomic, strong) FaceDetector *faceDetector;
@property (nonatomic, strong) VotingFaceRecognizer *faceRecognizer;
@property (nonatomic, strong) CvVideoCamera* videoCamera;
@property (nonatomic, strong) CALayer *featureLayer;
@property (nonatomic) NSInteger frameNum;
@property (nonatomic) BOOL modelAvailable;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *switchCameraButton;

@end
