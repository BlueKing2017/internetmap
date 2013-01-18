//
//  ViewController.h
//  InternetMap
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "NodeSearchViewController.h"
#import "SCTracerouteUtility.h"
#import "WEPopoverController.h"

@interface ViewController : GLKViewController <NodeSearchDelegate, SCTracerouteUtilityDelegate, UIGestureRecognizerDelegate, WEPopoverControllerDelegate>


@end
