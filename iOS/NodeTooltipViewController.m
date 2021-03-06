//
//  NodeTooltipViewController.m
//  InternetMap
//
//  Created by Alexander on 21.12.12.
//  Copyright (c) 2012 Peer1. All rights reserved.
//

#import "NodeTooltipViewController.h"
#import "NodeWrapper.h"


@interface NodeTooltipViewController ()
@end

@implementation NodeTooltipViewController

- (id)initWithNode:(NodeWrapper*)node
{
    self = [super init];
    if (self) {
        self.node = node;
        self.preferredContentSize = CGSizeMake(320, 44);
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(5, 0, self.preferredContentSize.width-10, 26)];
    label.centerY = self.preferredContentSize.height/2;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont fontWithName:@"HelveticaNeue" size:22];
    
    if(self.text) {
        label.text = self.text;
    }
    else {
        if ([HelperMethods isStringEmptyOrNil:self.node.rawTextDescription]) {
            label.text = [NSString stringWithFormat:@"AS%@", self.node.asn];
        }else {
            label.text = self.node.friendlyDescription;
        }
    }
    [self.view addSubview:label];
}

@end
