//
//  ViewController.m
//  YoutubePlayer
//
//  Created by Jorge Valbuena on 2014-10-24.
//  Copyright (c) 2014 com.jorgedeveloper. All rights reserved.
//

#import "ViewController.h"
#import "SphereMenu.h"
#import "ChameleonFramework/Chameleon.h"

@interface ViewController () <SphereMenuDelegate>
@property (nonatomic) int counter;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.player = [[YTPlayerView alloc] initWithFrame:CGRectMake(0, 50, self.view.bounds.size.width, 220)];
    self.player.autoplay = YES;
    self.player.modestbranding = YES;
    self.player.allowLandscapeMode = YES;
    self.player.forceBackToPortraitMode = YES;
    self.player.allowAutoResizingPlayerFrame = YES;
    self.player.playsinline = YES;
    
    [self.player loadWithPlaylistId:@"PLEE58C6029A8A6ADE"];
    
    // adding to subview
    [self.view addSubview:self.player];
        
    NSArray *colors = [[NSArray alloc] initWithObjects:FlatGreen, FlatMint, nil];
    
    self.view.backgroundColor = [UIColor colorWithGradientStyle:UIGradientStyleTopToBottom withFrame:self.view.frame andColors:colors];
    
    UIImage *startImage = [UIImage imageNamed:@"start"];
    UIImage *image1 = [UIImage imageNamed:@"Arrow-left"];
    UIImage *image2 = [UIImage imageNamed:@"play"];
    UIImage *image3 = [UIImage imageNamed:@"Arrow-right"];
    NSArray *images = @[image1, image2, image3];
    SphereMenu *sphereMenu = [[SphereMenu alloc] initWithStartPoint:CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height-120)
                                                         startImage:startImage
                                                      submenuImages:images];
    sphereMenu.delegate = self;
    [self.view addSubview:sphereMenu];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)sphereDidSelected:(int)index
{
    NSLog(@"sphere %d selected", index);
    
    if(index == 1) {
        if(self.counter == 0) {
            [self.player playVideo];
            self.counter = 1;
        }
        else {
            [self.player pauseVideo];
            self.counter = 0;
        }
    }
    else if(index == 0) {
        [self.player previousVideo];
    }
    else {
        [self.player nextVideo];
    }
    
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
