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
    
    // Re-train the model in case more pictures were added
    self.modelAvailable = [self.faceRecognizer trainModel];
    
    if (!self.modelAvailable) {
        self.instructionLabel.text = @"Add people in the database first";
    }
    
    [self.videoCamera start];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.videoCamera stop];
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
    // Only process every CAPTURE_FPS'th frame (every 1s)
    if (self.frameNum == 5) {
        [self parseFaces:[self.faceDetector facesFromImage:image] forImage:image];
        self.frameNum = 0;
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
    
    // We only care about the first face
    cv::Rect face = faces[0];
    
    // By default highlight the face in red, no match found
    CGColor *highlightColor = [[UIColor redColor] CGColor];
    NSString *message = @"No match found";
    NSString *confidence = @"";
    
    // Unless the database is empty, try a match
    if (self.modelAvailable) {
        NSDictionary *match = [self.faceRecognizer recognizeFace:face inImage:image];
        
        // Match found
        if ([match objectForKey:@"personID"] != [NSNumber numberWithInt:-1]) {
            message = [match objectForKey:@"personName"];
            confidence = [match objectForKey:@"confidence"];
            highlightColor = [[UIColor greenColor] CGColor];
            
            NSNumberFormatter *confidenceFormatter = [[NSNumberFormatter alloc] init];
            [confidenceFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
            confidenceFormatter.maximumFractionDigits = 2;
            
            //confidence = [NSString stringWithFormat:@"%@ Confidence: %@", message,
                        //[confidenceFormatter stringFromNumber:[match objectForKey:@"confidence"]]];
            confidence = [NSString stringWithFormat:@"%@ %@", message, confidence];
        }
    }
    
    // All changes to the UI have to happen on the main thread
    dispatch_sync(dispatch_get_main_queue(), ^{
        self.instructionLabel.text = message;
        self.confidenceLabel.text = confidence;
        [self highlightFace:[OpenCVData faceToCGRect:face] withColor:highlightColor];
    });
}

- (void)noFaceToDisplay
{
    dispatch_sync(dispatch_get_main_queue(), ^{
        self.instructionLabel.text = @"No face in image";
        self.confidenceLabel.text = @"";
        self.featureLayer.hidden = YES;
    });
}

- (void)highlightFace:(CGRect)faceRect withColor:(CGColor *)color
{
    if (self.featureLayer == nil) {
        self.featureLayer = [[CALayer alloc] init];
        self.featureLayer.borderWidth = 4.0;
    }
    
    [self.imageView.layer addSublayer:self.featureLayer];
    CGRect scaledRect = [self scaleRect:faceRect];
    
    self.featureLayer.hidden = NO;
    self.featureLayer.borderColor = color;
    self.featureLayer.frame = scaledRect;
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
- (IBAction)switchCamera:(UIBarButtonItem *)sender {
}
@end
