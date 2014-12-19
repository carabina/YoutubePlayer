//
//  ViewController.m
//  YoutubePlayer
//
//  Created by Jorge Valbuena on 2014-10-24.
//  Copyright (c) 2014 com.jorgedeveloper. All rights reserved.
//

#import "ViewController.h"
#import "SphereMenu.h"
#import "Chameleon.h"

@interface ViewController () <SphereMenuDelegate>
@property (nonatomic) int counter;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic) BOOL isInBackgroundMode;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    // adding to subview
    [self.view addSubview:[self setPlayer]];

    
    NSArray *colors = [[NSArray alloc] initWithObjects:FlatGreen, FlatMint, nil];
    
    self.view.backgroundColor = [UIColor colorWithGradientStyle:UIGradientStyleTopToBottom withFrame:self.view.frame andColors:colors];
    
    UIImage *startImage = [UIImage imageNamed:@"start"];
    UIImage *image1 = [UIImage imageNamed:@"rewind"];
    UIImage *image2 = [UIImage imageNamed:@"player"];
    UIImage *image3 = [UIImage imageNamed:@"forward"];
    NSArray *images = @[image1, image2, image3];
    SphereMenu *sphereMenu = [[SphereMenu alloc] initWithStartPoint:CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height-120)
                                                         startImage:startImage
                                                      submenuImages:images];
    sphereMenu.delegate = self;
    [self.view addSubview:sphereMenu];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appIsInBakcground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillBeInBakcground:) name:UIApplicationWillResignActiveNotification object:nil];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}

#pragma mark - Helper Functions

-(YTPlayerView*)setPlayer{
    if(!_player)
    {
        self.player = [[YTPlayerView alloc] initWithFrame:CGRectMake(0, 50, self.view.bounds.size.width, 220)];
        self.player.delegate = self;
        self.player.autoplay = YES;
        self.player.modestbranding = YES;
        self.player.allowLandscapeMode = YES;
        //    self.player.forceBackToPortraitMode = YES;
        self.player.allowAutoResizingPlayerFrame = YES;
        self.player.playsinline = YES;
        self.player.fullscreen = YES;
        
        [self.player loadWithPlaylistId:@"PLEE58C6029A8A6ADE"];
    }
    return _player;
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
        [self.player nextVideo];    }
    
}

//- (void)playerView:(YTPlayerView *)playerView receivedError:(YTPlayerError)error
//{
//    [self.player nextVideo];
//}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - Notifications

-(void)appIsInBakcground:(NSNotification*)notification{
    [self.player playVideo];
}

-(void)appWillBeInBakcground:(NSNotification*)notification{
//    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(keepPlaying) userInfo:nil repeats:YES];
//    self.isInBackgroundMode = YES;
//    [self.player playVideo];
}

-(void)keepPlaying{
    if(self.isInBackgroundMode){
        [self.player playVideo];
        self.isInBackgroundMode = NO;
    }
    else{
        [self.timer invalidate];
        self.timer = nil;
    }
}
@end
