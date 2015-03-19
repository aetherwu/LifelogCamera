
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "AVFoundation/AVCaptureSession.h"

@interface ViewController : UIViewController
{
    AVCaptureSession *photoSession;
}
- (IBAction)shotAction:(id)sender;

@end