//
//  ViewController.m
//  YoutubePlayer
//
//  Created by Jorge Valbuena on 2014-10-24.
//  Copyright (c) 2014 com.jorgedeveloper. All rights reserved.
//

#import "ViewController.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.player = [[YTPlayerView alloc] initWithFrame:CGRectMake(0, 50, self.view.bounds.size.width, 220)];
    
    [self.player allowLandscapeMode];
    
    [self.player allowAutoResizingPlayerFrame];
    
    [self.player loadWithPlaylistId:@"PLEE58C6029A8A6ADE"];
    
    // adding to subview
    [self.view addSubview:self.player];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
