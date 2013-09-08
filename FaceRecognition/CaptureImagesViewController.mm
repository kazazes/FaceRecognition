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


- (void)processImage:(cv::Mat&)image
{
    // Only process every 60th frame (every 2s)
    if (self.frameNum == 10) {
        [self parseFaces:[self.faceDetector facesFromImage:image] forImage:image];
        self.frameNum = 0;
    }
    else {
        self.frameNum++;
    }
}

- (void)parseFaces:(const std::vector<cv::Rect> &)faces forImage:(cv::Mat&)image
{
    if (![self learnFace:faces forImage:image]) {
        return;
    };
    
    self.numPicsTaken++;
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        CGColor *highlightColor = [[UIColor redColor] CGColor];
        [self highlightFace:[OpenCVData faceToCGRect:faces[0]] withColor:highlightColor];

        if (self.numPicsTaken == 100) {
            self.featureLayer.hidden = YES;
            [self.videoCamera stop];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Done"
                                                            message:@"100 pictures have been taken."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            [self.navigationController popViewControllerAnimated:YES];
        }
        
    });
    
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

- (void)noFaceToDisplay
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        self.featureLayer.hidden = YES;
    });
}


- (IBAction)cameraButtonClicked:(id)sender
{
    if (self.videoCamera.running){
        self.libraryButton.hidden = NO;
        [self.cameraButton setTitle:@"Start" forState:UIControlStateNormal];
        self.featureLayer.hidden = YES;
        
        [self.videoCamera stop];
        
    } else {
        self.libraryButton.hidden = YES;
        [self.cameraButton setTitle:@"Stop" forState:UIControlStateNormal];
        // First, forget all previous pictures of this person
        //[self.faceRecognizer forgetAllFacesForPersonID:[self.personID integerValue]];
        
        // Reset the counter, start taking pictures
        self.numPicsTaken = 0;
        [self.videoCamera start];
        
    }
}

- (IBAction)switchCameraButtonClicked:(id)sender
{
    [self.videoCamera stop];
    
    if (self.videoCamera.defaultAVCaptureDevicePosition == AVCaptureDevicePositionFront) {
        self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    } else {
        self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
    }
    
    [self.videoCamera start];
}


@end
