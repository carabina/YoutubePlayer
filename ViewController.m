//
//  ViewController.m
//  YoutubePlayer
//
//  Created by Jorge Valbuena on 2014-10-24.
//  Copyright (c) 2014 com.jorgedeveloper. All rights reserved.
//

#import "ViewController.h"

#define IS_OS_6_OR_LATER    ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0)
#define IS_OS_8_OR_LATER    ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

@interface ViewController ()

@property (nonatomic, strong) NSDictionary *dictionary;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.view.backgroundColor = [UIColor blackColor];
    
    self.screenHeight = self.view.bounds.size.height;
    self.screenWidth = self.view.bounds.size.width;
    
    // setting up the player
    self.ytPlayer = [[YTPlayerView alloc] initWithFrame:CGRectMake(0, 50, self.screenWidth, self.screenHeight-517)];
    
    self.ytPlayer.backgroundColor = [UIColor blackColor];
    
    // setting up player parameters
    self.dictionary = @{@"listType" : @"playlist",
                        @"autoplay" : @"1",
                        @"loop" : @"1",
                        @"playsinline" : @"0",
                        @"controls" : @"2",
                        @"cc_load_policy" : @"0",};
    
    // loading playlist with player paramaters
    [self.ytPlayer loadWithPlaylistId:@"PLEE58C6029A8A6ADE" playerVars:self.dictionary];
    
    // adding to subview
    [self.view addSubview:self.ytPlayer];
    
    // adding notification center to receive AVPlayer states
    if(IS_OS_6_OR_LATER){
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerStarted) name:@"UIMoviePlayerControllerDidEnterFullscreenNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerEnded) name:@"UIMoviePlayerControllerWillExitFullscreenNotification" object:nil];
    }
    
    if (IS_OS_8_OR_LATER) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerStarted) name:UIWindowDidBecomeVisibleNotification object:self.view.window];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerStarted) name:UIWindowDidBecomeHiddenNotification object:self.view.window];
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)playerStarted {
//    self.ytPlayer.frame = CGRectMake(0, 0, self.screenWidth, self.screenWidth);
}

- (void)playerEnded {
    self.ytPlayer.frame = CGRectMake(0, 50, self.screenWidth, self.screenWidth-400);
}

@end
