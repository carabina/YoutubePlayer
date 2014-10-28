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
    
    // adding notification center to receive AVPlayer states
    if(IS_OS_6_OR_LATER && !IS_OS_8_OR_LATER)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerStarted:) name:@"UIMoviePlayerControllerDidEnterFullscreenNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerEnded:) name:@"UIMoviePlayerControllerWillExitFullscreenNotification" object:nil];
    }
    else if (IS_OS_8_OR_LATER)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerStarted:) name:UIWindowDidBecomeVisibleNotification object:self.view.window];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerEnded:) name:UIWindowDidBecomeHiddenNotification object:self.view.window];
    }
    
    UIDevice *device = [UIDevice currentDevice];

    //Tell it to start monitoring the accelerometer for orientation
    [device beginGeneratingDeviceOrientationNotifications];
    
    //Get the notification centre for the app
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:device];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.screenHeight = self.view.bounds.size.height;
    self.screenWidth = self.view.bounds.size.width;
    
    // adding to subview
    [self.view addSubview:[self myYTPlayer]];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIMoviePlayerControllerDidEnterFullscreenNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIMoviePlayerControllerWillExitFullscreenNotification" object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIWindowDidBecomeVisibleNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIWindowDidBecomeHiddenNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:[UIDevice currentDevice]];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}


#pragma mark - Youtube Player
/**
 * Creates ytPlayer if it hasn't been created before, else returns previously created
 * @name myYTPlayer
 *
 * @param _ytPlayer
 * @return YTPlayerView class containing the youtube video
 */
-(YTPlayerView*)myYTPlayer
{
    if(!_ytPlayer)
    {
        // setting up the player
        _ytPlayer = [[YTPlayerView alloc] initWithFrame:CGRectMake(0, 50, self.screenWidth, self.screenHeight-480)];
        
        _ytPlayer.backgroundColor = [UIColor blackColor];
        
        // setting up player parameters
        _dictionary = @{@"listType" : @"playlist",
                        @"autoplay" : @"1",
                        @"loop" : @"1",
                        @"playsinline" : @"0",
                        @"controls" : @"2",
                        @"cc_load_policy" : @"0",};
        
        // loading playlist with player paramaters
        [_ytPlayer loadWithPlaylistId:@"PLEE58C6029A8A6ADE" playerVars:self.dictionary];
        
        return _ytPlayer;
    }
    
    return _ytPlayer;
}


#pragma mark - Helper Functions
/**
 * Executes when player starts full screen of video player (good for changing app orientation)
 * @name playerStarted
 *
 * @param ...
 * @return void...
 */
- (void)playerStarted:(NSNotification*)notification
{
    // do something?
}


/**
 * Executes when player exits full screen of video player (good for changing app orientation)
 * @name playerEnded
 *
 * @param ...
 * @return void...
 */
- (void)playerEnded:(NSNotification*)notification
{
    // do something?
}


/**
 * Updates player frame depending on orientation
 * @name orientationChanged
 *
 * @param screenHeight, screenWidth and ytPlayer
 * @return void but updates ytPlayer frame
 */
- (void)orientationChanged:(NSNotification*)notification
{
    UIDevice *device = [UIDevice currentDevice];
    
    if(device.orientation == UIDeviceOrientationLandscapeLeft || device.orientation == UIDeviceOrientationLandscapeRight)
    {
        self.screenHeight = self.view.bounds.size.height;
        self.screenWidth = self.view.bounds.size.width;
        
        self.ytPlayer.frame = CGRectMake(0, 0, self.screenWidth, self.screenHeight);
    }
    else if(device.orientation == UIDeviceOrientationPortrait || device.orientation == UIDeviceOrientationPortraitUpsideDown)
    {
        self.screenHeight = self.view.bounds.size.height;
        self.screenWidth = self.view.bounds.size.width;
        
        self.ytPlayer.frame = CGRectMake(0, 50, self.screenWidth, self.screenHeight-480);
    }
}

@end
