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
#import "PeopleViewController.h"

@interface RecognizeViewController : UIViewController <CvVideoCameraDelegate>

- (void)setupCamera;
- (void)highlightFace:(CGRect)faceRect withColor:(CGColor *)color;
- (void)noFaceToDisplay;
- (IBAction)switchCameraClicked:(id)sender;
- (void) learnFace:(int)personID;
- (IBAction)learnFaceClick:(id)sender;
- (IBAction)editList:(id)sender;
- (void)pvc:(PeopleViewController*)pvc;
- (IBAction)newPerson:(id)sender;
- (void)removeUser:(int)personID;
- (IBAction)retrainModel:(id)sender;

@property (strong, nonatomic) IBOutlet UITextField* nameField;
@property (strong, nonatomic) PeopleViewController* pvc;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *learnFaceButton;
@property (strong, nonatomic) IBOutlet UIView *nameListViewContainer;
@property (nonatomic) CGRect lastFace;

@property (retain, nonatomic) IBOutlet UILabel *personName;
@property (retain, nonatomic) IBOutlet UIView *personLabel;
@property (nonatomic) BOOL learningMode;
@property (nonatomic) int learningPersonID;

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
