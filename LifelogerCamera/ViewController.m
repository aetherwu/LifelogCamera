#import "ViewController.h"
#import "Reachability.h"

@interface ViewController ()<AVAudioPlayerDelegate>

@property (strong, nonatomic) AVCaptureSession *photoSession;
@property (nonatomic, strong) dispatch_source_t timerSource;
@property (strong, nonatomic) AVCaptureStillImageOutput *output;
@property (strong, nonatomic) AVCaptureConnection *videoConnection;



@end


@implementation ViewController

@synthesize photoSession;
@synthesize output;
@synthesize videoConnection;


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    [self startCamera];
    [self startTimer];
    
}

-(void) startCamera {
    //init camera
    NSLog(@"camera init");
    AVCaptureDevice *frontalCamera;
    NSArray *allCameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for ( int i = 0; i < allCameras.count; i++ )
    {
        AVCaptureDevice *camera = [allCameras objectAtIndex:i];
        if ( camera.position == AVCaptureDevicePositionBack )
            frontalCamera = camera;
    }
    
    if ( frontalCamera != nil )
    {
        photoSession = [[AVCaptureSession alloc] init];
        
        NSError *error;
        AVCaptureDeviceInput *input =
        [AVCaptureDeviceInput deviceInputWithDevice:frontalCamera error:&error];
        
        if ( !error && [photoSession canAddInput:input] )
        {
            [photoSession addInput:input];
            output = [[AVCaptureStillImageOutput alloc] init];
            [output setOutputSettings: [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey,nil]];
            
            if ( [photoSession canAddOutput:output] )
            {
                [photoSession addOutput:output];
                videoConnection = nil;
                for (AVCaptureConnection *connection in output.connections)
                {
                    for (AVCaptureInputPort *port in [connection inputPorts])
                    {
                        if ([[port mediaType] isEqual:AVMediaTypeVideo] )
                        {
                            videoConnection = connection;
                            break;
                        }
                    }
                    if (videoConnection) { break; }
                }
                
                NSLog(@"found videoConnection");
                if ( videoConnection )
                {
                    [videoConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
                    
                    [photoSession startRunning];
                    
                }
            }
        }
    }
    //end init
}


-(void) startTimer {
    
    //[self takePhoto];
    NSLog(@"set camera timer ");
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    self.timerSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_source_set_timer(self.timerSource, dispatch_walltime(NULL, 1ull * NSEC_PER_SEC), 20ull * NSEC_PER_SEC, 2ull * NSEC_PER_SEC);
    dispatch_source_set_event_handler(self.timerSource, ^{
            [self takePhoto];
    });
    dispatch_resume(self.timerSource);
    
}

-(void) takePhoto {
    [self.output captureStillImageAsynchronouslyFromConnection:self.videoConnection
                                             completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
                                                 
                                                 NSLog(@"ready to shot");
                                                 if(error) NSLog(@"%@", error);
                                                 if (imageDataSampleBuffer != NULL)
                                                 {
                                                     NSLog(@"ready to save");
                                                     NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                                                     UIImage *photo = [[UIImage alloc] initWithData:imageData];
                                                     
                                                     //compress
                                                     NSData *compressedImg = UIImageJPEGRepresentation(photo, 1 /*compressionQuality*/);
                                                     UIImage *compressedPhoto =[UIImage imageWithData:compressedImg];
                                                     
                                                     //scale
                                                     UIImage *scaledImage = [UIImage imageWithCGImage:[compressedPhoto CGImage]
                                                                                                scale:(compressedPhoto.scale * 0.3)
                                                                                          orientation:(compressedPhoto.imageOrientation)];
                                                     
                                                     //write to album
                                                     UIImageWriteToSavedPhotosAlbum(scaledImage, nil, nil, nil);
                                                     NSLog(@"photo saved");
                                                     
                                                     //*
                                                     //send photo to server
                                                     //IF WI-FI
                                                     Reachability *reachability = [Reachability reachabilityForInternetConnection];
                                                     [reachability startNotifier];
                                                     
                                                     NetworkStatus status = [reachability currentReachabilityStatus];
                                                     if(status == NotReachable)
                                                     {
                                                         //No internet
                                                     }
                                                     else if (status == ReachableViaWiFi)
                                                     {
                                                         //WiFi
                                                         [self sendPhoto:scaledImage];
                                                     }
                                                     else if (status == ReachableViaWWAN)
                                                     {
                                                         //3G
                                                     }
                                                     //*/
                                                     
                                                     //analyize QR code
                                                     
                                                 }
                                             }];
    
    [[UIScreen mainScreen] setBrightness: 0];
}


- (void)sendPhoto: (UIImage *) scaledImage {
    
    //send to the sever directly when wifi availible
    
    UIImage *imgToPost = scaledImage;
    //UIImageWriteToSavedPhotosAlbum(imgToPost, nil, nil, nil);
    
    NSData *imageData = UIImageJPEGRepresentation(imgToPost, 0.8);
    // we only need the first (most recent) photo -- stop the enumeration
    
    // create request
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    
    //send photo to server
    NSString *urlString = [NSString stringWithFormat:@"http://YOURDOMAN.com/camera.php"];
    [request setURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:@"POST"];
    
    // set Content-Type in HTTP header
    NSString *boundary = @"---------------------------14737809831466499882746641449";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    // post body
    NSMutableData *body = [NSMutableData data];
    
    // add image data
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Disposition: attachment; name=\"userfile\"; filename=\"img.jpg\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[NSData dataWithData:imageData]];
    [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    // setting the body of the post to the reqeust
    [request setHTTPBody:body];
    
    
    // make the connection to the web
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    NSString *returnString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
    
    NSLog(@"Image post: %@", returnString);
    
    //save photos to album when wifi is not avaiable
    
}


- (IBAction)shotAction:(id)sender {
    [self takePhoto];
}


@end
