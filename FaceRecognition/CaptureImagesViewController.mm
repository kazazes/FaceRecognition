//
//  CaptureImagesViewController.m
//  FaceRecognition
//
//  Created by Michael Peterson on 2012-11-16.
//
//

#import "CaptureImagesViewController.h"
#import "OpenCVData.h"

//@interface CaptureImagesViewController ()
//@property (strong, nonatomic) ELCAlbumPickerController *albumController;
//@end

@implementation CaptureImagesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.faceDetector = [[FaceDetector alloc] init];
    self.faceRecognizer = [[VotingFaceRecognizer alloc] init];
    
    [self setupCamera];
}


- (void)parseFaces:(const std::vector<cv::Rect> &)faces forImage:(cv::Mat&)image
{
    NSLog(@"%@", self.personID);
    if (![self learnFace:faces forImage:image]) {
        return;
    };
    
    self.numPicsTaken++;
}

- (bool)learnFace:(const std::vector<cv::Rect> &)faces forImage:(cv::Mat&)image
{
    if (faces.size() != 1) {
        [self noFaceToDisplay];
        return NO;
    }
    
    // We only care about the first face
    cv::Rect face = faces[0];
    
    // Learn it
    [self.faceRecognizer learnFace:face ofPersonID:[self.personID intValue] fromImage:image];
    return YES;
}

@end
