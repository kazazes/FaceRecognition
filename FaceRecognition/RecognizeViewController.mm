//
//  RecognizeViewController.mm
//  FaceRecognition
//
//  Created by Michael Peterson on 2012-11-16.
//
//

#import "RecognizeViewController.h"
#import "OpenCVData.h"


#define CAPTURE_FPS 30

float weighted_average(float a, float b, float weight) {
    if (weight < .8) {
        return b;
    } else if (weight > .9) {
        weight = .9;
    }
    float avg = b * (1 - weight) + a * weight;
    return avg;
    
}

float CGRectArea(CGRect a) {
    return a.size.height * a.size.width;
}

CGRect CGRectAverage(CGRect a, CGRect b) {
    CGRect intersect = CGRectIntersection(a, b);
    CGRect union_rect = CGRectUnion(a, b);
    float w = CGRectArea(intersect) / CGRectArea(union_rect);
    return CGRectMake(weighted_average(a.origin.x, b.origin.x, w),
                      weighted_average(a.origin.y, b.origin.y, w),
                      weighted_average(a.size.width, b.size.width, w),
                      weighted_average(a.size.height, b.size.height, w));
}



@interface RecognizeViewController ()
- (IBAction)switchCameraClicked:(id)sender;

@end

@implementation RecognizeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.faceDetector = [[FaceDetector alloc] init];
    self.faceRecognizer = [[VotingFaceRecognizer alloc] init];
    
    [self setupCamera];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.nameListViewContainer.layer.cornerRadius = 50.0f;
    [self.faceRecognizer trainModel];
    [self.videoCamera start];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.videoCamera stop];
}

- (void) learnFace:(int)personID {
    self.learningPersonID = personID;
    self.learningMode = YES;
    self.learnFaceButton.title = @"Stop Learning!";
    self.nameListViewContainer.hidden = YES;
}

- (IBAction)learnFaceClick:(id)sender {
    if (self.learningMode) {
        self.learnFaceButton.title = @"Learn Face";
        self.learningMode = NO;
        self.learningPersonID = nil;
    } else {
        self.nameListViewContainer.hidden = self.nameListViewContainer.hidden ? NO : YES;
    }

}

- (void)setupCamera
{
    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:self.imageView];
    self.videoCamera.delegate = self;
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset352x288;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultFPS = CAPTURE_FPS;
    self.videoCamera.grayscaleMode = NO;
}

- (void)processImage:(cv::Mat&)image
{
    if (self.frameNum % 5 == 0) {
        std::vector<cv::Rect> faces = [self.faceDetector facesFromImage:image];
        if (faces.size() == 0) {
            [self noFaceToDisplay];
            return;
        }
        [self moveDetectionBox:[OpenCVData faceToCGRect:faces[0]]];
        if (self.frameNum == 5 || [self.personName.text isEqual:@"Unknown"]) {
            [self parseFaces:faces forImage:image];
        }
        if (self.frameNum == CAPTURE_FPS) {
            self.frameNum = 0;
        }
    }
    self.frameNum++;
}

- (void)parseFaces:(const std::vector<cv::Rect> &)faces forImage:(cv::Mat&)image
{
    // No faces found
    if (faces.size() != 1) {
        [self noFaceToDisplay];
        return;
    }
    self.featureLayer.hidden = NO;
    // We only care about the first face
    cv::Rect face = faces[0];
    
    // By default highlight the face in red, no match found
    CGColor *highlightColor = [[UIColor redColor] CGColor];
    
    if (self.learningMode)
        [self learnFace:faces forImage:image];
    MultiResult *match = [self.faceRecognizer recognizeFace:face inImage:image];

    if (match.personID != -1) {
        highlightColor = [[UIColor greenColor] CGColor];
    }

    // All changes to the UI have to happen on the main thread
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self highlightFace:[OpenCVData faceToCGRect:face] withColor:highlightColor];
        [self.personName setText: match.personName];
        if (match.personID != -1)
            self.personLabel.hidden = NO;
        else
            self.personLabel.hidden = YES;
    });
}

- (void)noFaceToDisplay
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        self.featureLayer.hidden = YES;
        self.personLabel.hidden = YES;
        self.personName.text = @"Unknown";
        
    });
}

- (void)moveDetectionBox:(CGRect)faceRect {
    if (self.featureLayer == nil) {
        self.featureLayer = [[UIView alloc] init];
        self.featureLayer.layer.cornerRadius = 10.0f;
        self.featureLayer.layer.borderWidth = 1.5f;
        self.featureLayer.layer.borderColor = [[UIColor redColor] CGColor];
        
    }
    
    if (self.personLabel == nil) {
        self.personLabel = [[[NSBundle mainBundle]
                             loadNibNamed:@"PersonLabel"
                             owner:self options:nil] objectAtIndex:0];
        self.personLabel.layer.cornerRadius = 10.0f;
        [self.imageView addSubview:self.personLabel];
        
    }
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        CGRect scaledRect = [self scaleRect:faceRect];
        [self.imageView addSubview:self.featureLayer];
        [self.imageView addSubview:self.personLabel];
        
        [UIView animateWithDuration:0.05f
                         animations:^{
                             CGRect newPosition = CGRectAverage(self.featureLayer.frame,
                                                                scaledRect);
                             
                             self.featureLayer.frame = newPosition;
                             self.personLabel.frame = CGRectMake(newPosition.origin.x + newPosition.size.width/12,
                                                                 newPosition.origin.y + newPosition.size.height + 10,
                                                                 200,
                                                                 30);
                         }];
        self.lastFace = scaledRect;
    });
}

- (void)highlightFace:(CGRect)faceRect withColor:(CGColor *)color
{
    self.featureLayer.layer.borderColor = color;
}

- (IBAction)switchCameraClicked:(id)sender {
    [self.videoCamera stop];
    
    if (self.videoCamera.defaultAVCaptureDevicePosition == AVCaptureDevicePositionFront) {
        self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    } else {
        self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
    }
    
    [self.videoCamera start];
}

-(CGRect)scaleRect:(CGRect)rect
{
    CGSize sizeMultiple = [self imageSizeAfterAspectFit];

    return CGRectMake(rect.origin.x * sizeMultiple.width,
                      rect.origin.y * sizeMultiple.height,
                      rect.size.width * sizeMultiple.width,
                      rect.size.height * sizeMultiple.height);
}

-(CGSize)imageSizeAfterAspectFit {
    float newwidth;
    float newheight;
    UIImageView *imageView = self.imageView;
    CGSize imageSize = CGSizeMake(288, 352);
    
    if (imageSize.height>=imageSize.width){
        newheight = imageView.frame.size.height;
        newwidth = (imageSize.width/imageSize.height) * newheight;
        
        if(newwidth>imageView.frame.size.width){
            float diff=imageView.frame.size.width-newwidth;
            newheight=newheight+diff/newheight*newheight;
            newwidth=imageView.frame.size.width;
        }
        
    }
    else{
        newwidth=imageView.frame.size.width;
        newheight=(imageSize.height/imageSize.width)*newwidth;
        
        if(newheight>imageView.frame.size.height){
            float diff=imageView.frame.size.height-newheight;
            newwidth=newwidth+diff/newwidth*newwidth;
            newheight=imageView.frame.size.height;
        }
    }
    
    return CGSizeMake(newwidth/288, newheight/352);
    
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
    [self.faceRecognizer learnFace:face ofPersonID:self.learningPersonID fromImage:image];
    return YES;
}

- (IBAction)addSomebody:(id)sender {
    self.nameListViewContainer.hidden = NO;
    //[self.nameListViewContainer
    
}
    
@end
