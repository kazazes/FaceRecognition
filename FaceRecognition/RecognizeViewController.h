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

- (void)setupCamera;
- (void)highlightFace:(CGRect)faceRect withColor:(CGColor *)color;
- (void)noFaceToDisplay;
- (IBAction)switchCameraClicked:(id)sender;

@property (nonatomic) CGRect lastFace;

@property (retain, nonatomic) IBOutlet UILabel *personName;
@property (retain, nonatomic) IBOutlet UIView *personLabel;

@property (nonatomic, retain) IBOutlet UIView *labelView;
@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) IBOutlet UILabel *instructionLabel;
@property (nonatomic, strong) IBOutlet UILabel *confidenceLabel;
@property (nonatomic, strong) FaceDetector *faceDetector;
@property (nonatomic, strong) VotingFaceRecognizer *faceRecognizer;
@property (nonatomic, strong) CvVideoCamera* videoCamera;
@property (nonatomic, strong) UIView *featureLayer;
//@property (nonatomic, strong) CALayer *userInfoLayer;
@property (nonatomic) NSInteger frameNum;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *switchCameraButton;

@end
