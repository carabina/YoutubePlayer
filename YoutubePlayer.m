//
//  YoutubePlayer.m
//  YoutubePlayerDemo
//
//  Created by Jorge Valbuena on 2014-10-28.
//  Copyright (c) 2014 com.jorgedeveloper. All rights reserved.
//

#import "YoutubePlayer.h"

#ifdef __IPHONE_8_0
// suppress these errors until we are ready to handle them
//#pragma message "Ignoring designated initializer warnings"
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
#else
// temporarily define an empty NS_DESIGNATED_INITIALIZER so we can use now,
// will be ready for iOS8 SDK
#define NS_DESIGNATED_INITIALIZER
#endif

#define IS_OS_6_OR_LATER    ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0)
#define IS_OS_8_OR_LATER    ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

@interface YoutubePlayer ()

// for screen sizes
@property (nonatomic) CGRect screenRect;
@property (nonatomic) CGFloat screenWidth;
@property (nonatomic) CGFloat screenHeight;

@property (nonatomic, strong) UIView *topView;

@property (nonatomic, strong) NSString *playlist;

@end

@implementation YoutubePlayer


#pragma mark - Youtube Player
/**
 * Creates ytPlayer if it hasn't been created before, else returns previously created
 * @name init
 *
 * @param ...
 * @return ...
 */
//- (id)init
//{
////    @throw [NSException exceptionWithName:NSGenericException reason:@"Use the `initWithFrame:` method instead." userInfo:nil];
//    
//    // class initializer
//    static YoutubePlayer *player;
//    static dispatch_once_t once;
//    dispatch_once(&once, ^{
//        player = [[YoutubePlayer alloc] init];
//    });
//    return player;
//    
//}


/**
 * Creates ytPlayer if it hasn't been created before, else returns previously created
 * @name initWithFrame
 *
 * @param ...
 * @return ...
 */
//- (id)initWithFrame:(CGRect)frame
//{
//    // class initializer
//    static YoutubePlayer *player;
//    static dispatch_once_t once;
//    dispatch_once(&once, ^{
//        player = [[YoutubePlayer alloc] initWithFrame:self.bounds];
//    });
//    return player;
//}


/**
 * Creates ytPlayer if it hasn't been created before, else returns previously created
 * @name myYTPlayer
 *
 * @param _ytPlayer
 * @return YTPlayerView class containing the youtube video
 */
- (BOOL)loadWithPlayList:(NSString*)playlist
{
    _playlist = playlist;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        [self createNewPlayerForPlayList];
    });
    [self addNotifications];
    [self addSubview:self.ytPlayer];
    return YES;
}


#pragma mark - Helper Functions
/**
 * Adds customs notifications
 * @name addNotifications
 *
 * @param ...
 * @return void...
 */
- (void)addNotifications
{
    UIDevice *device = [UIDevice currentDevice];
    
    //Tell it to start monitoring the accelerometer for orientation
    [device beginGeneratingDeviceOrientationNotifications];
    //Get the notification centre for the app
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:device];
    
    // adding notification center to receive AVPlayer states
    if(IS_OS_6_OR_LATER && !IS_OS_8_OR_LATER)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerStarted:) name:@"UIMoviePlayerControllerDidEnterFullscreenNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerEnded:) name:@"UIMoviePlayerControllerWillExitFullscreenNotification" object:nil];
    }
    else if (IS_OS_8_OR_LATER)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerStarted:) name:UIWindowDidBecomeVisibleNotification object:self.window];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerEnded:) name:UIWindowDidBecomeHiddenNotification object:self.window];
    }
}


/**
 * Removes customs notifications
 * @name dealloc
 *
 * @param ...
 * @return void...
 */
- (void)dealloc
{
    // removing notification center to receive AVPlayer states
    if(IS_OS_6_OR_LATER && !IS_OS_8_OR_LATER)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIMoviePlayerControllerDidEnterFullscreenNotification" object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIMoviePlayerControllerWillExitFullscreenNotification" object:nil];
    }
    else if (IS_OS_8_OR_LATER)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIWindowDidBecomeVisibleNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIWindowDidBecomeHiddenNotification object:nil];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:[UIDevice currentDevice]];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}


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
        _screenRect = [[UIScreen mainScreen] applicationFrame];
        _screenHeight = _screenRect.size.height;
        _screenWidth = _screenRect.size.width;
        
        self.ytPlayer.frame = CGRectMake(0, 0, self.screenWidth, self.screenHeight);
    }
    else if(device.orientation == UIDeviceOrientationPortrait || device.orientation == UIDeviceOrientationPortraitUpsideDown)
    {
        self.ytPlayer.frame = self.bounds;
    }
}

- (YTPlayerView*)createNewPlayerForPlayList
{
    if(!_ytPlayer)
    {
        // setting up the player
        _ytPlayer = [[YTPlayerView alloc] initWithFrame:self.bounds];
        
        _ytPlayer.backgroundColor = [UIColor blackColor];
        
        // setting up player parameters
        NSDictionary *dictionary = @{@"listType" : @"playlist",
                                     @"autoplay" : @"1",
                                     @"loop" : @"1",
                                     @"playsinline" : @"0",
                                     @"controls" : @"2",
                                     @"cc_load_policy" : @"0",};
        
        // loading playlist with player paramaters
        [_ytPlayer loadWithPlaylistId:self.playlist playerVars:dictionary];
        
        return _ytPlayer;
    }
    
    return _ytPlayer;
}



@end
