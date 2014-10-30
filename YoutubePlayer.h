//
//  YoutubePlayer.h
//  YoutubePlayerDemo
//
//  Created by Jorge Valbuena on 2014-10-28.
//  Copyright (c) 2014 com.jorgedeveloper. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YTPlayerView.h"

//@class YoutubePlayer;

@interface YoutubePlayer : UIView <YTPlayerViewDelegate>

@property (nonatomic, strong, readonly) YTPlayerView *ytPlayer;

// custom initializer
//- (id) init __attribute__((objc_designated_initializer));

// custom initializer with frame
//- (id) initWithFrame:(CGRect)frame __attribute__((objc_designated_initializer));

// creates ytPlayer if it hasn't never created before
-(BOOL)loadWithPlayList:(NSString*)playlist;

// use to force landscape mode
- (void)playerStarted:(NSNotification*)notification;

// use to force back to portrait mode
- (void)playerEnded:(NSNotification*)notification;

// use to update the frame of player when rotates
- (void)orientationChanged:(NSNotification*)notification;


@end
