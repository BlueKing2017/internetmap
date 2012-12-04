//
//  ViewController.m
//  InternetMap
//

#import "ViewController.h"
#import "MapDisplay.h"
#import "MapData.h"
#import "Camera.h"
#import "Node.h"
#import "DefaultVisualization.h"
#import "VisualizationsTableViewController.h"
#import "NodeSearchViewController.h"

@interface ViewController ()

@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) MapDisplay* display;
@property (strong, nonatomic) MapData* data;

@property (strong, nonatomic) UITapGestureRecognizer* tapRecognizer;
@property (strong, nonatomic) UITapGestureRecognizer* twoFingerTapRecognizer;
@property (strong, nonatomic) UITapGestureRecognizer* doubleTapRecognizer;
@property (strong, nonatomic) UIPanGestureRecognizer* panRecognizer;
@property (strong, nonatomic) UIPinchGestureRecognizer* pinchRecognizer;

@property (nonatomic) CGPoint lastPanPosition;
@property (nonatomic) float lastScale;

@property (nonatomic) NSUInteger targetNode;


/* UIKit Overlay */
@property (weak, nonatomic) IBOutlet UIButton* searchButton;
@property (weak, nonatomic) IBOutlet UIButton* youAreHereButton;
@property (weak, nonatomic) IBOutlet UIButton* visualizationsButton;
@property (weak, nonatomic) IBOutlet UIButton* timelineButton;
@property (weak, nonatomic) IBOutlet UISlider* timelineSlider;
@property (strong, nonatomic) UIPopoverController* visualizationSelectionPopover;
@property (strong, nonatomic) UIPopoverController* nodeSearchPopover;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    self.preferredFramesPerSecond = 60.0f;

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;

    [EAGLContext setCurrentContext:self.context];
    
    self.display = [MapDisplay new];
    self.data = [MapData new];
    self.data.visualization = [DefaultVisualization new];
    
    [self.data loadFromFile:[[NSBundle mainBundle] pathForResource:@"data" ofType:@"txt"]];
    [self.data loadFromAttrFile:[[NSBundle mainBundle] pathForResource:@"as2attr" ofType:@"txt"]];
    [self.data updateDisplay:self.display];
    
    self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    self.twoFingerTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTwoFingerTap:)];
    self.twoFingerTapRecognizer.numberOfTouchesRequired = 2;
    
    self.doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    self.doubleTapRecognizer.numberOfTapsRequired = 2;
    [self.tapRecognizer requireGestureRecognizerToFail:self.doubleTapRecognizer];
    
    self.panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    self.pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    
    [self.view addGestureRecognizer:self.tapRecognizer];
    [self.view addGestureRecognizer:self.doubleTapRecognizer];
    [self.view addGestureRecognizer:self.twoFingerTapRecognizer];
    [self.view addGestureRecognizer:self.panRecognizer];
    [self.view addGestureRecognizer:self.pinchRecognizer];
    
    self.targetNode = NSNotFound;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

- (void)dealloc
{    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    self.display.camera.displaySize = self.view.bounds.size;
    [self.display update];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    /*
    static int count = 0;
    count++;
    if(count == 30) {
        count = 0;
        NSLog(@"render: %.2fms", self.timeSinceLastDraw * 1000);
    }
     */
    
    [self.display draw];
}

-(void)handlePan:(UIPanGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan) {
        CGPoint translation = [gestureRecognizer translationInView:self.view];
        self.lastPanPosition = translation;
    }
    
    if([gestureRecognizer state] == UIGestureRecognizerStateChanged)
    {
        
        CGPoint translation = [gestureRecognizer translationInView:self.view];
        CGPoint delta = CGPointMake(translation.x - self.lastPanPosition.x, translation.y - self.lastPanPosition.y);
        self.lastPanPosition = translation;
        
        [self.display.camera rotateRadiansX:delta.x * 0.01];
        [self.display.camera rotateRadiansY:delta.y * 0.01];
    }
}

-(void)handlePinch:(UIPinchGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan) {
        self.lastScale = gestureRecognizer.scale;
    }
    
    if([gestureRecognizer state] == UIGestureRecognizerStateChanged)
    {
        float deltaZoom = gestureRecognizer.scale - self.lastScale;
        self.lastScale = gestureRecognizer.scale;
        [self.display.camera zoom:deltaZoom];
    }


}

-(void)handleTap:(UITapGestureRecognizer*)gestureRecognizer {    
    NSDate* date = [NSDate date];
    CGPoint pointInView = [gestureRecognizer locationInView:self.view];
    float xOld = pointInView.x;
    CGFloat xLoOld = 0;
    CGFloat xHiOld = self.display.camera.displaySize.width;
    CGFloat xLoNew = -1;
    CGFloat xHiNew = 1;

    pointInView.x = (xOld-xLoOld) / (xHiOld-xLoOld) * (xHiNew-xLoNew) + xLoNew;
    
    float yOld = pointInView.y;
    CGFloat yLoOld = 0;
    CGFloat yHiOld = self.display.camera.displaySize.height;
    CGFloat yLoNew = 1;
    CGFloat yHiNew = -1;
    
    pointInView.y = (yOld-yLoOld) / (yHiOld-yLoOld) * (yHiNew-yLoNew) + yLoNew;
    GLKVector3 cameraInObjectSpace = [self.display.camera cameraInObjectSpace]; //A
    GLKVector3 pointOnClipPlaneInObjectSpace = [self.display.camera applyModelViewToPoint:pointInView]; //B
    float xA, yA, zA;
    float xB, yB, zB;
    float xC, yC, zC;
    float r;
    float maxDelta = -1;
    int foundI = NSNotFound;

    xA = cameraInObjectSpace.x;
    yA = cameraInObjectSpace.y;
    zA = cameraInObjectSpace.z;
    
    xB = pointOnClipPlaneInObjectSpace.x;
    yB = pointOnClipPlaneInObjectSpace.y;
    zB = pointOnClipPlaneInObjectSpace.z;
    
    for (int i = 0; i < [self.data.nodes count]; i++) {
        Node* node = [self.data nodeAtIndex:i];
        
        GLKVector3 nodePosition = [self.data.visualization nodePosition:node];
        xC = nodePosition.x;
        yC = nodePosition.y;
        zC = nodePosition.z;
        
        r = [self.data.visualization nodeSize:node]/2;
        
        float a = powf((xB-xA), 2)+powf((yB-yA), 2)+powf((zB-zA), 2);
        float b = 2*((xB-xA)*(xA-xC)+(yB-yA)*(yA-yC)+(zB-zA)*(zA-zC));
        float c = powf((xA-xC), 2)+powf((yA-yC), 2)+powf((zA-zC), 2)-powf(r, 2);
        float delta = powf(b, 2)-4*a*c;
        if (delta >= 0) {
            NSLog(@"intersected node %i: %@, delta: %f", i, NSStringFromGLKVector3(nodePosition), delta);
            if (delta > maxDelta) {
                maxDelta = delta;
                foundI = i;
            }
        }
    }
    
    if (foundI != NSNotFound) {
        NSLog(@"selected node %i", foundI);
        [self updateTargetForIndex:foundI];
    }else {
        NSLog(@"No node found, will bring up onscreen controls");
    }
    
    NSLog(@"time for intersection calculation: %f", [date timeIntervalSinceNow]);
    
}

- (void)handleTwoFingerTap:(UIGestureRecognizer*)gestureRecognizer {
    NSLog(@"Zoomed out");
    if (gestureRecognizer.numberOfTouches == 2) {
        float deltaZoom = -0.3;
        self.lastScale = self.lastScale+deltaZoom;
        
        [self.display.camera zoom:deltaZoom];
    }
}

- (void)handleDoubleTap:(UIGestureRecognizer*)gestureRecongizer {
    NSLog(@"Zoomed in");
    float deltaZoom = 0.3;
    self.lastScale = self.lastScale+deltaZoom;
    
    [self.display.camera zoom:deltaZoom];
}

-(IBAction)nextTarget:(id)sender {
    if(self.targetNode == NSNotFound) {
        [self updateTargetForIndex:0];
    }
    else {
        [self updateTargetForIndex:+1];
    }
}

- (void)updateTargetForIndex:(int)index {
    GLKVector3 target;

    // update current node to default state
    if (self.targetNode != NSNotFound) {
        Node* node = [self.data nodeAtIndex:self.targetNode];
        
        [self.data.visualization updateDisplay:self.display forNodes:@[node]];
    }
    
    //set new node as targeted and change camera anchor point
    if (index != NSNotFound) {
        
        self.targetNode = index;
        Node* node = [self.data nodeAtIndex:self.targetNode];
        target = [self.data.visualization nodePosition:node];
        [[self.display displayNodeAtIndex:node.index] setColor:[UIColor redColor]];

        
    }else {
        target = GLKVector3Make(0, 0, 0);
    }
    

    self.display.camera.target = target;

}

#pragma mark - UIKit Controls Overlay

-(IBAction)selectVisualization:(id)sender {
    if (!self.visualizationSelectionPopover) {
        VisualizationsTableViewController *tableforPopover = [[VisualizationsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:tableforPopover];
        self.visualizationSelectionPopover.delegate = self;
        self.visualizationSelectionPopover = [[UIPopoverController alloc] initWithContentViewController:navController];
        [self.visualizationSelectionPopover setPopoverContentSize:tableforPopover.contentSizeForViewInPopover];
    }
    [self.visualizationSelectionPopover presentPopoverFromRect:self.visualizationsButton.bounds inView:self.visualizationsButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

-(IBAction)searchNodes:(id)sender {
    if (!self.nodeSearchPopover) {
        NodeSearchViewController *tableforPopover = [[NodeSearchViewController alloc] initWithStyle:UITableViewStylePlain];
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:tableforPopover];
        self.nodeSearchPopover.delegate = self;
        self.nodeSearchPopover = [[UIPopoverController alloc] initWithContentViewController:navController];
        [self.nodeSearchPopover setPopoverContentSize:tableforPopover.contentSizeForViewInPopover];
    }
    [self.nodeSearchPopover presentPopoverFromRect:self.searchButton.bounds inView:self.searchButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

-(IBAction)toggleTimelineMode:(id)sender {
    if (self.timelineSlider.hidden) {
        self.timelineSlider.hidden = NO;
        
        self.searchButton.enabled = NO;
        self.youAreHereButton.enabled = NO;
        self.visualizationsButton.enabled = NO;
    } else {
        self.timelineSlider.hidden = YES;
        
        self.searchButton.enabled = YES;
        self.youAreHereButton.enabled = YES;
        self.visualizationsButton.enabled = YES;
    }
}



#pragma mark - UIPopoverController Delegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController{
    
}

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController{
    return YES;
}

@end
