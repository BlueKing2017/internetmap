//
//  MapController.m
//  InternetMap
//
//  Created by Alexander on 07.01.13.
//  Copyright (c) 2013 Peer1. All rights reserved.
//

#import "MapController.h"
#import "MapDisplay.h"
#import "MapData.h"
#import "DefaultVisualization.h"
#import "Nodes.h"
#import "Camera.h"
#import "Node.h"
#import "Lines.h"
#import "Connection.h"
#import "IndexBox.h"

@implementation MapController


- (id)init{
    
    if (self = [super init]) {
        self.display = [MapDisplay new];
        self.data = [MapData new];
        
        
        self.data.visualization = [DefaultVisualization new];
        
        [self.data loadFromFile:[[NSBundle mainBundle] pathForResource:@"data" ofType:@"txt"]];
        [self.data loadFromAttrFile:[[NSBundle mainBundle] pathForResource:@"as2attr" ofType:@"txt"]];
        [self.data loadAsInfo:[[NSBundle mainBundle] pathForResource:@"asinfo" ofType:@"json"]];
        [self.data updateDisplay:self.display];
        
        self.targetNode = NSNotFound;
        self.hoveredNodeIndex = NSNotFound;

    }
    
    return self;
}


#pragma mark - Event Handling

- (void)handleTouchDownAtPoint:(CGPoint)point {
    
    if (!self.display.camera.isMovingToTarget) {
        //cancel panning/zooming momentum
        [self.display.camera stopMomentumPan];
        [self.display.camera stopMomentumZoom];
        [self.display.camera stopMomentumRotation];
        
        int i = [self indexForNodeAtPoint:point];
        if (i != NSNotFound) {
            self.hoveredNodeIndex = i;
            [self.display.nodes beginUpdate];
            [self.display.nodes updateNode:i color:SELECTED_NODE_COLOR];
            [self.display.nodes endUpdate];
        }
    }
}

#pragma mark - Selected Node handling

- (void)selectHoveredNode {
    if (self.hoveredNodeIndex != NSNotFound) {
        self.lastSearchIP = nil;
        [self updateTargetForIndex:self.hoveredNodeIndex];
        self.hoveredNodeIndex = NSNotFound;
    }
}

- (void)unhoverNode {
    
    if (self.hoveredNodeIndex != NSNotFound && self.hoveredNodeIndex != self.targetNode) {
        Node* node = [self.data nodeAtIndex:self.hoveredNodeIndex];
        
        [self.data.visualization updateDisplay:self.display forNodes:@[node]];
        self.hoveredNodeIndex = NSNotFound;
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
        
        [self.display.nodes beginUpdate];
        [self.display.nodes updateNode:node.index color:[UIColor clearColor]];
        [self.display.nodes endUpdate];
        
        [self.data.visualization resetDisplay:self.display forSelectedNodes:@[node]];
        
        [self highlightConnections:node];
        
    } else {
        target = GLKVector3Make(0, 0, 0);
    }
    
    self.display.camera.target = target;
}

#pragma mark - Connection Highlighting

-(void)highlightConnections:(Node*)node {
    if(node == nil) {
        [self clearHighlightLines];
        return;
    }
    
    NSMutableArray* filteredConnections = [NSMutableArray new];
    
    for(Connection* connection in self.data.connections) {
        if ((connection.first == node) || (connection.second == node) ) {
            [filteredConnections addObject:connection];
        }
    }
    
    if(filteredConnections.count == 0 || filteredConnections.count > 100) {
        [self clearHighlightLines];
        return;
    }
    
    Lines* lines = [[Lines alloc] initWithLineCount:filteredConnections.count];
    
    [lines beginUpdate];
    
    UIColor* brightColour = SELECTED_CONNECTION_COLOR_BRIGHT;
    UIColor* dimColour = SELECTED_CONNECTION_COLOR_DIM;
    
    for(int i = 0; i < filteredConnections.count; i++) {
        Connection* connection = filteredConnections[i];
        Node* a = connection.first;
        Node* b = connection.second;
        
        if(node == a) {
            [lines updateLine:i withStart:[self.data.visualization nodePosition:a] startColor:brightColour end:[self.data.visualization nodePosition:b] endColor:dimColour];
        }
        else {
            [lines updateLine:i withStart:[self.data.visualization nodePosition:a] startColor:dimColour end:[self.data.visualization nodePosition:b] endColor:brightColour];
        }
    }
    
    [lines endUpdate];
    lines.width = ((filteredConnections.count < 20) ? 2 : 1) * ([HelperMethods deviceIsRetina] ? 2 : 1);
    self.display.highlightLines = lines;
}


- (void)clearHighlightLines {
    [self.highlightedNodes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        NSMutableArray* array = [NSMutableArray arrayWithCapacity:[self.highlightedNodes count]];
        if (idx != self.targetNode) {
            Node* node = [self.data nodeAtIndex:idx];
            [array addObject:node];
        }
        [self.data.visualization updateDisplay:self.display forNodes:array];
    }];
    self.display.highlightLines = nil;
}

-(void)highlightRoute:(NSArray*)nodeList {
    if(nodeList.count <= 1) {
        [self clearHighlightLines];
        return;
    }
    Lines* lines = [[Lines alloc] initWithLineCount:nodeList.count - 1];
    
    [lines beginUpdate];
    
    UIColor* lineColor = UIColorFromRGB(0xffa300);
    
    [self.display.nodes beginUpdate];
    for(int i = 0; i < nodeList.count - 1; i++) {
        Node* a = nodeList[i];
        Node* b = nodeList[i+1];
        [self.display.nodes updateNode:a.index color:SELECTED_NODE_COLOR];
        [self.display.nodes updateNode:b.index color:SELECTED_NODE_COLOR];
        [self.highlightedNodes addIndex:a.index];
        [self.highlightedNodes addIndex:b.index];
        [lines updateLine:i withStart:[self.data.visualization nodePosition:a] startColor:lineColor end:[self.data.visualization nodePosition:b] endColor:lineColor];
    }
    
    [self.display.nodes endUpdate];
    
    
    [lines endUpdate];
    
    lines.width = [HelperMethods deviceIsRetina] ? 10.0 : 5.0;
    
    self.display.highlightLines = lines;
    
    //highlight nodes
    
    
}

#pragma mark - Index/Position calculations

- (int)indexForNodeAtPoint:(CGPoint)pointInView {
    NSDate* date = [NSDate date];
    date = date;
    //get point in view and adjust it for viewport
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
    //transform point from screen- to object-space
    GLKVector3 cameraInObjectSpace = [self.display.camera cameraInObjectSpace]; //A
    GLKVector3 pointOnClipPlaneInObjectSpace = [self.display.camera applyModelViewToPoint:pointInView]; //B
    
    //do actual line-sphere intersection
    float xA, yA, zA;
    __block float xC, yC, zC;
    __block float r;
    __block float maxDelta = -1;
    __block int foundI = NSNotFound;
    
    xA = cameraInObjectSpace.x;
    yA = cameraInObjectSpace.y;
    zA = cameraInObjectSpace.z;
    
    GLKVector3 direction = GLKVector3Subtract(pointOnClipPlaneInObjectSpace, cameraInObjectSpace); //direction = B - A
    GLKVector3 invertedDirection = GLKVector3Make(1.0f/direction.x, 1.0f/direction.y, 1.0f/direction.z);
    int sign[3];
    sign[0] = (invertedDirection.x < 0);
    sign[1] = (invertedDirection.y < 0);
    sign[2] = (invertedDirection.z < 0);
    
    float a = powf((direction.x), 2)+powf((direction.y), 2)+powf((direction.z), 2);
    
    IndexBox* box;
    for (int j = 0; j<[self.data.boxesForNodes count]; j++) {
        box = [self.data.boxesForNodes objectAtIndex:j];
        if ([box doesLineIntersectOptimized:cameraInObjectSpace invertedDirection:invertedDirection sign:sign]) {
            //            NSLog(@"intersects box %i at pos %@", j, NSStringFromGLKVector3(box.center));
            [box.indices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                int i = idx;
                Node* node = [self.data nodeAtIndex:i];
                
                GLKVector3 nodePosition = [self.data.visualization nodePosition:node];
                xC = nodePosition.x;
                yC = nodePosition.y;
                zC = nodePosition.z;
                
                r = [self.data.visualization nodeSize:node]/2;
                r = MAX(r, 0.02);
                
                float b = 2*((direction.x)*(xA-xC)+(direction.y)*(yA-yC)+(direction.z)*(zA-zC));
                float c = powf((xA-xC), 2)+powf((yA-yC), 2)+powf((zA-zC), 2)-powf(r, 2);
                float delta = powf(b, 2)-4*a*c;
                if (delta >= 0) {
                    //                    NSLog(@"intersected node %i: %@, delta: %f", i, NSStringFromGLKVector3(nodePosition), delta);
                    GLKVector4 transformedNodePosition = GLKMatrix4MultiplyVector4(self.display.camera.currentModelView, GLKVector4MakeWithVector3(nodePosition, 1));
                    if ((delta > maxDelta) && (transformedNodePosition.z < -0.1)) {
                        maxDelta = delta;
                        foundI = i;
                    }
                }
                
            }];
        }
    }
    
    //    NSLog(@"time for intersect: %f", [date timeIntervalSinceNow]);
    return foundI;
}


-(CGPoint)getCoordinatesForNodeAtIndex:(int)index {
    Node* node = [self.data nodeAtIndex:index];
    
    int viewport[4] = {0, 0, self.display.camera.displaySize.width, self.display.camera.displaySize.height};
    
    GLKVector3 nodePosition = [self.data.visualization nodePosition:node];
    
    GLKMatrix4 model = [self.display.camera currentModelView];
    
    GLKMatrix4 projection = [self.display.camera currentProjection];
    
    GLKVector3 coordinates = GLKMathProject(nodePosition, model, projection, viewport);
    
    CGPoint point = CGPointMake(coordinates.x,self.display.camera.displaySize.height - coordinates.y);
    
    //NSLog(@"%@", NSStringFromCGPoint(point));
    
    return point;
    
}

@end
