#[Embedded Youtube Video Player - (Objective-C).](http://jv17.github.io/YoutubePlayer/)
This a simple youtube player which includes the Youtube helper api to get the most of it. The intention is to help some developers in the use of their framework:
Also, to share some of my school and personal work. 

##Usage
**1)** Download the zip file and extract it to add the YoutubeHelper folder to your project.

**2)** After these folder is added to the project (remember to select copy file if necessary when adding to the project) you can start using this helper library really simple as:

**3)** Create a player property
```objc
    @property (nonatomic, strong) YTPlayerView *player;
```

**4)** Then, set the player
```objc
    // setting up the player
    self.player = [[YTPlayerView alloc] initWithFrame:CGRectMake(0, 50, 320, 350)];
```

**5)** Then, you can load a playlist or just a simple video with the youtube videoId or playlistId
```objc
    // loading videoId 
    [self.player loadWithVideoId:@"O8TiugM6Jg"];

    // loading playlist
    [self.player loadWithPlaylistId:@"PLEE58C6029A8A6ADE"];
```

**6)** Optional, you can also load the video/playlist with some parameters to customize the player
```objc
    // first create your dictionary to set the different parameters
    @property (nonatomic, strong) NSDictionary *dictionary;

    // setting up player parameters
    self.dictionary = @{@"listType" : @"playlist",
                        @"autoplay" : @"1",
                        @"loop" : @"1",
                        @"playsinline" : @"0",
                        @"controls" : @"2",
                        @"cc_load_policy" : @"0",};
    
    // loading playlist with player paramaters
    [self.player loadWithPlaylistId:@"PLEE58C6029A8A6ADE" playerVars:self.dictionary];

    // ******** OR **********

    // use some customs parameters which will be load to the video like this.. (just for simplicity)
    self.player.autoplay = YES;
    self.player.modestbranding = YES;
 
    // and then just call load the playlist/video
    [self.player loadWithPlaylistId:@"PLEE58C6029A8A6ADE"];
```

**7)** Finally, add the player to your view and Done!
```objc
    // adding to subview
    [self.view addSubview:self.player];
```

**8)** Extra, Some fun functions were added to the project that you might want to use (just set the variable before loading the video) as
```objc
    // allows landscape mode 
    self.player.allowLandscapeMode = YES;

    // force to go back to portrait when exit fullscreen (this requires extra settings)
    self.player.forceBackToPortraitMode = YES; 

    // for forcing the portrait mode and allowing landscape you need to do this in your AppDelegate

    // this in your AppDelegate.h
    @property (nonatomic) BOOL videoIsInFullscreen;

    // and this in your AppDelegate.m
    - (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window{
        if(self.videoIsInFullscreen == YES) {
            return UIInterfaceOrientationMaskAllButUpsideDown;
        }
        else {
            return UIInterfaceOrientationMaskPortrait;
        }
    }
```
**DONE!**

I hope it is helpful to others and, you find it interesting. Cheers!

Don't forget to visit **[My Website!](http://jorgedeveloper.com)** and **[My Blog!](http://jorgedeveloper.com/blog/)**

####Thanks for visiting this repo and for more info on this repo [visit the repo website](http://jv17.github.io/YoutubePlayer/)...
