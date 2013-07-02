//
//  CaptureImagesViewController.m
//  FaceRecognition
//
//  Created by Michael Peterson on 2012-11-16.
//
//

#import "CaptureImagesViewController.h"
#import "OpenCVData.h"
#import "ELCImagePickerController.h"
#import "ELCAlbumPickerController.h"

@interface CaptureImagesViewController ()
@property (strong, nonatomic) ELCAlbumPickerController *albumController;
@end

@implementation CaptureImagesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.faceDetector = [[FaceDetector alloc] init];
    self.faceRecognizer = [[CustomFaceRecognizer alloc] init];
    
    NSString *instructions = @"Make sure %@ is holding the phone. "
                                "When you are ready, press start. Or select images from your library.";
    self.instructionsLabel.text = [NSString stringWithFormat:instructions, self.personName];
    
    [self setupCamera];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Instructions"
                                                    message:@"When the camera starts, move it around to show different angles of your face."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)setupCamera
{
    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:self.previewImage];
    self.videoCamera.delegate = self;
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset352x288;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultFPS = 30;
    self.videoCamera.grayscaleMode = NO;
}

- (void)processImage:(cv::Mat&)image
{
    // Only process every 60th frame (every 2s)
    if (self.frameNum == 60) {
        [self parseFaces:[self.faceDetector facesFromImage:image] forImage:image];
        self.frameNum = 1;
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
        [self highlightFace:[OpenCVData faceToCGRect:faces[0]]];
        self.instructionsLabel.text = [NSString stringWithFormat:@"Taken %d of 10", self.numPicsTaken];
        
        if (self.numPicsTaken == 10) {
            self.featureLayer.hidden = YES;
            [self.videoCamera stop];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Done"
                                                            message:@"10 pictures have been taken."
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

- (void)highlightFace:(CGRect)faceRect
{
    if (self.featureLayer == nil) {
        self.featureLayer = [[CALayer alloc] init];
        self.featureLayer.borderColor = [[UIColor redColor] CGColor];
        self.featureLayer.borderWidth = 4.0;
        [self.previewImage.layer addSublayer:self.featureLayer];
    }
    
    self.featureLayer.hidden = NO;
    self.featureLayer.frame = faceRect;
}

- (IBAction)cameraButtonClicked:(id)sender
{
    if (self.videoCamera.running){
        self.switchCameraButton.hidden = YES;
        self.libraryButton.hidden = NO;
        [self.cameraButton setTitle:@"Start" forState:UIControlStateNormal];
        self.featureLayer.hidden = YES;
        
        [self.videoCamera stop];
        
        self.instructionsLabel.text = [NSString stringWithFormat:@"Make sure %@ is holding the phone. When you are ready, press start. Or select images from your library.", self.personName];
        
    } else {
        self.imageScrollView.hidden = YES;
        self.libraryButton.hidden = YES;
        [self.cameraButton setTitle:@"Stop" forState:UIControlStateNormal];
        self.switchCameraButton.hidden = NO;
        // First, forget all previous pictures of this person
        [self.faceRecognizer forgetAllFacesForPersonID:[self.personID integerValue]];
    
        // Reset the counter, start taking pictures
        self.numPicsTaken = 0;
        [self.videoCamera start];

        self.instructionsLabel.text = @"Taking pictures...";
    }
}

- (IBAction)libraryButtonClicked:(id)sender {
    self.albumController = [ELCAlbumPickerController new];
	ELCImagePickerController *elcPicker = [[ELCImagePickerController alloc] initWithRootViewController:self.albumController];
    [self.albumController setParent:elcPicker];
	[elcPicker setDelegate:self];
    
    [self presentViewController:elcPicker animated:YES completion:nil];
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

#pragma mark ELCImagePickerControllerDelegate Methods

- (void)elcImagePickerController:(ELCImagePickerController *)picker didFinishPickingMediaWithInfo:(NSArray *)info
{
    [self dismissViewControllerAnimated:YES
                             completion:^() {
                                 self.instructionsLabel.text = @"Processing pictures...";
                                 
                                 for (UIView *view in [self.imageScrollView subviews]) {
                                     [view removeFromSuperview];
                                 }
                                 
                                 self.imageScrollView.hidden = NO;
                                 
                                 self.imageScrollView.contentOffset = CGPointZero;
                                 
                                 self.numPicsTaken = 0;
                                 
                                 float count = 1.0f;
                                 
                                 for(NSDictionary *dict in info) {
                                     UIImage *image = [dict objectForKey:UIImagePickerControllerOriginalImage];
                                     
                                     UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
                                     
                                     imageView.frame = CGRectMake(self.imageScrollView.frame.size.width * (count - 1), 0, self.imageScrollView.frame.size.width, self.imageScrollView.frame.size.height);
                                     
                                     [self.imageScrollView addSubview:imageView];
                                     
                                     self.imageScrollView.contentSize = CGSizeMake(self.imageScrollView.frame.size.width * count, self.imageScrollView.frame.size.height);
                                     
                                     self.imageScrollView.contentOffset = CGPointMake(self.imageScrollView.frame.size.width * (count - 1), 0);
                                     
                                     cv::Mat cvimage = [OpenCVData cvMatFromUIImage:image usingColorSpace:CV_RGBA2BGRA];
                                     
                                     const std::vector<cv::Rect> faces = [self.faceDetector facesFromImage:cvimage];
                                     
                                     if ([self learnFace:faces forImage:cvimage]) {

                                         self.numPicsTaken++;
                                         
                                         self.instructionsLabel.text = [NSString stringWithFormat:@"Processed %d of %d", self.numPicsTaken, [info count]];
                                     }
                                     
                                     count++;
                                 }
                             }];
}

- (void)elcImagePickerControllerDidCancel:(ELCImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
