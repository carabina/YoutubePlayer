//
//  ViewController.h
//  YoutubePlayer
//
//  Created by Jorge Valbuena on 2014-10-24.
//  Copyright (c) 2014 com.jorgedeveloper. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YTPlayerView.h"

@interface ViewController : UIViewController <YTPlayerViewDelegate>

@property (nonatomic, strong) YTPlayerView *player;

@end

