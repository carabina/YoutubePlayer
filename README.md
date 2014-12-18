### Embedded Youtube Video Player - (Objective-C).
This a simple youtube player which includes the Youtube helper api to get the most of it. The intention is to help some developers in the use of their framework.

### Screenshots in Portrait Mode
![screenshot-1](http://s4.postimg.org/7y62de33x/Photo_2014_12_16_7_07_03_PM.png)  ![screenshot-2](http://s2.postimg.org/mmiospfeh/Photo_2014_12_16_11_31_45_PM.png)  ![screenshot-3](http://s16.postimg.org/5o8xodqtx/Photo_2014_12_16_7_07_37_PM.png)

### Screenshots in Landscape Mode
![screenshot-4](http://s27.postimg.org/noivfcx2r/Photo_2014_12_16_7_07_52_PM.png)
![screenshot-5](http://s12.postimg.org/5cybqnxct/Photo_2014_12_16_7_08_23_PM.png)

### Usage
**1)** Download the zip file and extract it. Then add the YoutubeHelper folder to your project.

**2)** After these folder have been added to the project (remember to select copy file if necessary when adding to the project) you can start using this helper library, it's really simple...

**3)** Create a player property.
```objc
    @property (nonatomic, strong) YTPlayerView *player;
```

**4)** Then, set the player with the preferred frame.
```objc
    // setting up the player
    self.player = [[YTPlayerView alloc] initWithFrame:CGRectMake(0, 50, 320, 350)];
```

**5)** Then, you can load a playlist or just a simple video with the youtube videoId or playlistId (more options available, like loading 5 multiple videos). 
```objc
    // loading videoId 
    [self.player loadWithVideoId:@"O8TiugM6Jg"];

    // loading playlist
    [self.player loadWithPlaylistId:@"PLEE58C6029A8A6ADE"];
```

**6)** Optional, you can also load the video/playlist with some parameters to customize the youtube player.
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

**8)** Extra, Some helper functions were added to the project that you might want to use (just set the variable before loading the video) as...
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

If you wish to help and improve this library, please fee free to create your own brach and submit your improvement. It will go under review and then added to the project if it's accepted. 

### Authors and Contributors
Just myself @jv17, I decided to create a simple youtube player for others who are interested in something simple and easy to use.  

### Support or Contact
Check out my website http://jorgedeveloper.com or contact jv17@github.com and I will be happy to help you.
