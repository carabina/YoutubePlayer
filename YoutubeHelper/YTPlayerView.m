// Copyright 2014 Google Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "YTPlayerView.h"
#import "AppDelegate.h"

#define IS_OS_6_OR_LATER    ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0)
#define IS_OS_8_OR_LATER    ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

// These are instances of NSString because we get them from parsing a URL. It would be silly to
// convert these into an integer just to have to convert the URL query string value into an integer
// as well for the sake of doing a value comparison. A full list of response error codes can be
// found here:
//      https://developers.google.com/youtube/iframe_api_reference
NSString static *const kYTPlayerStateUnstartedCode = @"-1";
NSString static *const kYTPlayerStateEndedCode = @"0";
NSString static *const kYTPlayerStatePlayingCode = @"1";
NSString static *const kYTPlayerStatePausedCode = @"2";
NSString static *const kYTPlayerStateBufferingCode = @"3";
NSString static *const kYTPlayerStateCuedCode = @"5";
NSString static *const kYTPlayerStateUnknownCode = @"unknown";

// Constants representing playback quality.
NSString static *const kYTPlaybackQualitySmallQuality = @"small";
NSString static *const kYTPlaybackQualityMediumQuality = @"medium";
NSString static *const kYTPlaybackQualityLargeQuality = @"large";
NSString static *const kYTPlaybackQualityHD720Quality = @"hd720";
NSString static *const kYTPlaybackQualityHD1080Quality = @"hd1080";
NSString static *const kYTPlaybackQualityHighResQuality = @"highres";
NSString static *const kYTPlaybackQualityUnknownQuality = @"unknown";

// Constants representing YouTube player errors.
NSString static *const kYTPlayerErrorInvalidParamErrorCode = @"2";
NSString static *const kYTPlayerErrorHTML5ErrorCode = @"5";
NSString static *const kYTPlayerErrorVideoNotFoundErrorCode = @"100";
NSString static *const kYTPlayerErrorNotEmbeddableErrorCode = @"101";
NSString static *const kYTPlayerErrorCannotFindVideoErrorCode = @"105";

// Constants representing player callbacks.
NSString static *const kYTPlayerCallbackOnReady = @"onReady";
NSString static *const kYTPlayerCallbackOnStateChange = @"onStateChange";
NSString static *const kYTPlayerCallbackOnPlaybackQualityChange = @"onPlaybackQualityChange";
NSString static *const kYTPlayerCallbackOnError = @"onError";
NSString static *const kYTPlayerCallbackOnYouTubeIframeAPIReady = @"onYouTubeIframeAPIReady";

NSString static *const kYTPlayerEmbedUrlRegexPattern = @"^http(s)://(www.)youtube.com/embed/(.*)$";

@interface YTPlayerView()

// for screen sizes
@property (nonatomic) CGSize screenRect;
@property (nonatomic) CGFloat screenWidth;
@property (nonatomic) CGFloat screenHeight;

@property (nonatomic) CGRect prevFrame;

@property (nonatomic, strong) NSMutableDictionary *dicParameters;

@end

@implementation YTPlayerView

@synthesize allowLandscapeMode = _allowLandscapeMode;
@synthesize forceBackToPortraitMode = _forceBackToPortraitMode;
@synthesize allowAutoResizingPlayerFrame = _allowAutoResizingPlayerFrame;
@synthesize autohide = _autohide;
@synthesize autoplay = _autoplay;
@synthesize cc_load_policy = _cc_load_policy;
@synthesize color = _color;
@synthesize controls = _controls;
@synthesize disablekb = _disablekb;
@synthesize enablejsapi = _enablejsapi;
@synthesize end = _end;
@synthesize fullscreen = _fullscreen;
@synthesize iv_load_policy = _iv_load_policy;
@synthesize list = _list;
@synthesize listType = _listType;
@synthesize loops = _loops;
@synthesize modestbranding = _modestbranding;
@synthesize playerapiid = _playerapiid;
@synthesize playList = _playList;
@synthesize playsinline = _playsinline;
@synthesize rel = _rel;
@synthesize showinfo = _showinfo;
@synthesize start = _start;
@synthesize theme = _theme;

- (BOOL)loadWithVideoId:(NSString *)videoId
{
    return [self loadWithVideoId:videoId playerVars:nil];
}

- (BOOL)loadWithPlaylistId:(NSString *)playlistId
{
    return [self loadWithPlaylistId:playlistId playerVars:nil];
}

- (BOOL)loadWithVideoId:(NSString *)videoId playerVars:(NSDictionary *)playerVars
{
    if (!playerVars) {
        playerVars = @{};
    }
    
    if(self.dicParameters || self.dicParameters.count > 0)
    {
        NSDictionary *playerParams = @{ @"videoId" : videoId, @"playerVars" : self.dicParameters };
        return [self loadWithPlayerParams:playerParams];
    }
    
    NSDictionary *playerParams = @{ @"videoId" : videoId, @"playerVars" : playerVars };

    return [self loadWithPlayerParams:playerParams];
}

- (BOOL)loadWithPlaylistId:(NSString *)playlistId playerVars:(NSDictionary *)playerVars
{
    // Mutable copy because we may have been passed an immutable config dictionary.
    NSMutableDictionary *tempPlayerVars = [[NSMutableDictionary alloc] init];
    [tempPlayerVars setValue:@"playlist" forKey:@"listType"];
    [tempPlayerVars setValue:playlistId forKey:@"list"];
    [tempPlayerVars addEntriesFromDictionary:playerVars];  // No-op if playerVars is null
    [tempPlayerVars addEntriesFromDictionary:self.dicParameters];
    
    if(self.dicParameters || self.dicParameters.count > 0)
    {
        NSDictionary *playerParams = @{ @"playerVars" : tempPlayerVars };
        return [self loadWithPlayerParams:playerParams];
    }

    NSDictionary *playerParams = @{ @"playerVars" : tempPlayerVars };
    
    return [self loadWithPlayerParams:playerParams];
}

#pragma mark - Player methods

- (void)playVideo
{
    [self stringFromEvaluatingJavaScript:@"player.playVideo();"];
}

- (void)pauseVideo
{
    [self stringFromEvaluatingJavaScript:@"player.pauseVideo();"];
}

- (void)stopVideo
{
    [self stringFromEvaluatingJavaScript:@"player.stopVideo();"];
}

- (void)seekToSeconds:(float)seekToSeconds allowSeekAhead:(BOOL)allowSeekAhead
{
    NSNumber *secondsValue = [NSNumber numberWithFloat:seekToSeconds];
    NSString *allowSeekAheadValue = [self stringForJSBoolean:allowSeekAhead];
    NSString *command = [NSString stringWithFormat:@"player.seekTo(%@, %@);", secondsValue, allowSeekAheadValue];
    [self stringFromEvaluatingJavaScript:command];
}

- (void)clearVideo
{
    [self stringFromEvaluatingJavaScript:@"player.clearVideo();"];
}

#pragma mark - Cueing methods

- (void)cueVideoById:(NSString *)videoId startSeconds:(float)startSeconds suggestedQuality:(YTPlaybackQuality)suggestedQuality
{
    NSNumber *startSecondsValue = [NSNumber numberWithFloat:startSeconds];
    NSString *qualityValue = [YTPlayerView stringForPlaybackQuality:suggestedQuality];
    NSString *command = [NSString stringWithFormat:@"player.cueVideoById('%@', %@, '%@');", videoId, startSecondsValue, qualityValue];
    [self stringFromEvaluatingJavaScript:command];
}

- (void)cueVideoById:(NSString *)videoId startSeconds:(float)startSeconds endSeconds:(float)endSeconds suggestedQuality:(YTPlaybackQuality)suggestedQuality
{
    NSNumber *startSecondsValue = [NSNumber numberWithFloat:startSeconds];
    NSNumber *endSecondsValue = [NSNumber numberWithFloat:endSeconds];
    NSString *qualityValue = [YTPlayerView stringForPlaybackQuality:suggestedQuality];
    NSString *command = [NSString stringWithFormat:@"player.cueVideoById('%@', %@, %@, '%@');", videoId, startSecondsValue, endSecondsValue, qualityValue];
    [self stringFromEvaluatingJavaScript:command];
}

- (void)loadVideoById:(NSString *)videoId startSeconds:(float)startSeconds suggestedQuality:(YTPlaybackQuality)suggestedQuality
{
    NSNumber *startSecondsValue = [NSNumber numberWithFloat:startSeconds];
    NSString *qualityValue = [YTPlayerView stringForPlaybackQuality:suggestedQuality];
    NSString *command = [NSString stringWithFormat:@"player.loadVideoById('%@', %@, '%@');", videoId, startSecondsValue, qualityValue];
    [self stringFromEvaluatingJavaScript:command];
}

- (void)loadVideoById:(NSString *)videoId startSeconds:(float)startSeconds endSeconds:(float)endSeconds suggestedQuality:(YTPlaybackQuality)suggestedQuality
{
    NSNumber *startSecondsValue = [NSNumber numberWithFloat:startSeconds];
    NSNumber *endSecondsValue = [NSNumber numberWithFloat:endSeconds];
    NSString *qualityValue = [YTPlayerView stringForPlaybackQuality:suggestedQuality];
    NSString *command = [NSString stringWithFormat:@"player.loadVideoById('%@', %@, %@, '%@');", videoId, startSecondsValue, endSecondsValue, qualityValue];
    [self stringFromEvaluatingJavaScript:command];
}

- (void)cueVideoByURL:(NSString *)videoURL startSeconds:(float)startSeconds suggestedQuality:(YTPlaybackQuality)suggestedQuality
{
    NSNumber *startSecondsValue = [NSNumber numberWithFloat:startSeconds];
    NSString *qualityValue = [YTPlayerView stringForPlaybackQuality:suggestedQuality];
    NSString *command = [NSString stringWithFormat:@"player.cueVideoByUrl('%@', %@, '%@');", videoURL, startSecondsValue, qualityValue];
    [self stringFromEvaluatingJavaScript:command];
}

- (void)cueVideoByURL:(NSString *)videoURL startSeconds:(float)startSeconds endSeconds:(float)endSeconds suggestedQuality:(YTPlaybackQuality)suggestedQuality
{
    NSNumber *startSecondsValue = [NSNumber numberWithFloat:startSeconds];
    NSNumber *endSecondsValue = [NSNumber numberWithFloat:endSeconds];
    NSString *qualityValue = [YTPlayerView stringForPlaybackQuality:suggestedQuality];
    NSString *command = [NSString stringWithFormat:@"player.cueVideoByUrl('%@', %@, %@, '%@');", videoURL, startSecondsValue, endSecondsValue, qualityValue];
    [self stringFromEvaluatingJavaScript:command];
}

- (void)loadVideoByURL:(NSString *)videoURL startSeconds:(float)startSeconds suggestedQuality:(YTPlaybackQuality)suggestedQuality
{
    NSNumber *startSecondsValue = [NSNumber numberWithFloat:startSeconds];
    NSString *qualityValue = [YTPlayerView stringForPlaybackQuality:suggestedQuality];
    NSString *command = [NSString stringWithFormat:@"player.loadVideoByUrl('%@', %@, '%@');", videoURL, startSecondsValue, qualityValue];
    [self stringFromEvaluatingJavaScript:command];
}

- (void)loadVideoByURL:(NSString *)videoURL startSeconds:(float)startSeconds endSeconds:(float)endSeconds suggestedQuality:(YTPlaybackQuality)suggestedQuality
{
    NSNumber *startSecondsValue = [NSNumber numberWithFloat:startSeconds];
    NSNumber *endSecondsValue = [NSNumber numberWithFloat:endSeconds];
    NSString *qualityValue = [YTPlayerView stringForPlaybackQuality:suggestedQuality];
    NSString *command = [NSString stringWithFormat:@"player.loadVideoByUrl('%@', %@, %@, '%@');", videoURL, startSecondsValue, endSecondsValue, qualityValue];
    [self stringFromEvaluatingJavaScript:command];
}

#pragma mark - Cueing methods for lists

- (void)cuePlaylistByPlaylistId:(NSString *)playlistId index:(int)index startSeconds:(float)startSeconds suggestedQuality:(YTPlaybackQuality)suggestedQuality
{
    NSString *playlistIdString = [NSString stringWithFormat:@"'%@'", playlistId];
    [self cuePlaylist:playlistIdString index:index startSeconds:startSeconds suggestedQuality:suggestedQuality];
}

- (void)cuePlaylistByVideos:(NSArray *)videoIds index:(int)index startSeconds:(float)startSeconds suggestedQuality:(YTPlaybackQuality)suggestedQuality
{
    [self cuePlaylist:[self stringFromVideoIdArray:videoIds] index:index startSeconds:startSeconds suggestedQuality:suggestedQuality];
}

- (void)loadPlaylistByPlaylistId:(NSString *)playlistId index:(int)index startSeconds:(float)startSeconds suggestedQuality:(YTPlaybackQuality)suggestedQuality
{
    NSString *playlistIdString = [NSString stringWithFormat:@"'%@'", playlistId];
    [self loadPlaylist:playlistIdString index:index startSeconds:startSeconds suggestedQuality:suggestedQuality];
}

- (void)loadPlaylistByVideos:(NSArray *)videoIds index:(int)index startSeconds:(float)startSeconds suggestedQuality:(YTPlaybackQuality)suggestedQuality
{
    [self loadPlaylist:[self stringFromVideoIdArray:videoIds] index:index startSeconds:startSeconds suggestedQuality:suggestedQuality];
}

#pragma mark - Setting the playback rate

- (float)playbackRate
{
    NSString *returnValue = [self stringFromEvaluatingJavaScript:@"player.getPlaybackRate();"];
    return [returnValue floatValue];
}

- (void)setPlaybackRate:(float)suggestedRate
{
    NSString *command = [NSString stringWithFormat:@"player.setPlaybackRate(%f);", suggestedRate];
    [self stringFromEvaluatingJavaScript:command];
}

- (NSArray *)availablePlaybackRates
{
    NSString *returnValue = [self stringFromEvaluatingJavaScript:@"player.getAvailablePlaybackRates();"];

    NSData *playbackRateData = [returnValue dataUsingEncoding:NSUTF8StringEncoding];
    NSError *jsonDeserializationError;
    NSArray *playbackRates = [NSJSONSerialization JSONObjectWithData:playbackRateData
                                                             options:kNilOptions
                                                               error:&jsonDeserializationError];
    
    if (jsonDeserializationError)
    {
        return nil;
    }

    return playbackRates;
}

#pragma mark - Setting playback behavior for playlists

- (void)setLoop:(BOOL)loop
{
    NSString *loopPlayListValue = [self stringForJSBoolean:loop];
    NSString *command = [NSString stringWithFormat:@"player.setLoop(%@);", loopPlayListValue];
    [self stringFromEvaluatingJavaScript:command];
}

- (void)setShuffle:(BOOL)shuffle
{
    NSString *shufflePlayListValue = [self stringForJSBoolean:shuffle];
    NSString *command = [NSString stringWithFormat:@"player.setShuffle(%@);", shufflePlayListValue];
    [self stringFromEvaluatingJavaScript:command];
}

#pragma mark - Playback status

- (float)videoLoadedFraction
{
    return [[self stringFromEvaluatingJavaScript:@"player.getVideoLoadedFraction();"] floatValue];
}

- (YTPlayerState)playerState
{
    NSString *returnValue = [self stringFromEvaluatingJavaScript:@"player.getPlayerState();"];
    return [YTPlayerView playerStateForString:returnValue];
}

- (float)currentTime
{
    return [[self stringFromEvaluatingJavaScript:@"player.getCurrentTime();"] floatValue];
}

// Playback quality
- (YTPlaybackQuality)playbackQuality
{
    NSString *qualityValue = [self stringFromEvaluatingJavaScript:@"player.getPlaybackQuality();"];
    return [YTPlayerView playbackQualityForString:qualityValue];
}

- (void)setPlaybackQuality:(YTPlaybackQuality)suggestedQuality
{
    NSString *qualityValue = [YTPlayerView stringForPlaybackQuality:suggestedQuality];
    NSString *command = [NSString stringWithFormat:@"player.setPlaybackQuality('%@');", qualityValue];
    [self stringFromEvaluatingJavaScript:command];
}

#pragma mark - Video information methods

- (int)duration
{
    return [[self stringFromEvaluatingJavaScript:@"player.getDuration();"] intValue];
}

- (NSURL *)videoUrl
{
    return [NSURL URLWithString:[self stringFromEvaluatingJavaScript:@"player.getVideoUrl();"]];
}

- (NSString *)videoEmbedCode
{
    return [self stringFromEvaluatingJavaScript:@"player.getVideoEmbedCode();"];
}

#pragma mark - Playlist methods

- (NSArray *)playlist
{
    NSString *returnValue = [self stringFromEvaluatingJavaScript:@"player.getPlaylist();"];

    NSData *playlistData = [returnValue dataUsingEncoding:NSUTF8StringEncoding];
    NSError *jsonDeserializationError;
    NSArray *videoIds = [NSJSONSerialization JSONObjectWithData:playlistData
                                                        options:kNilOptions
                                                          error:&jsonDeserializationError];
    
    if (jsonDeserializationError) {
      return nil;
    }

    return videoIds;
}

- (int)playlistIndex
{
    NSString *returnValue = [self stringFromEvaluatingJavaScript:@"player.getPlaylistIndex();"];
    return [returnValue intValue];
}

#pragma mark - Playing a video in a playlist

- (void)nextVideo {
    [self stringFromEvaluatingJavaScript:@"player.nextVideo();"];
}

- (void)previousVideo
{
    [self stringFromEvaluatingJavaScript:@"player.previousVideo();"];
}

- (void)playVideoAt:(int)index
{
    NSString *command = [NSString stringWithFormat:@"player.playVideoAt(%@);", [NSNumber numberWithInt:index]];
    [self stringFromEvaluatingJavaScript:command];
}

#pragma mark - Helper methods

- (NSArray *)availableQualityLevels
{
    NSString *returnValue = [self stringFromEvaluatingJavaScript:@"player.getAvailableQualityLevels();"];

    NSData *availableQualityLevelsData = [returnValue dataUsingEncoding:NSUTF8StringEncoding];
    NSError *jsonDeserializationError;

    NSArray *rawQualityValues = [NSJSONSerialization JSONObjectWithData:availableQualityLevelsData
                                                                options:kNilOptions
                                                                  error:&jsonDeserializationError];
    
    if (jsonDeserializationError)
    {
        return nil;
    }

    NSMutableArray *levels = [[NSMutableArray alloc] init];
    for (NSString *rawQualityValue in rawQualityValues) {
        YTPlaybackQuality quality = [YTPlayerView playbackQualityForString:rawQualityValue];
        [levels addObject:[NSNumber numberWithInt:quality]];
    }
    
    return levels;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
//    NSLog(@"***** Checking ERROR -> %@", request.URL.absoluteString);

    if ([request.URL.absoluteString isEqualToString:@"ytplayer://onStateChange?data=2"])
    {
        [self playVideo]; // play video if goes into background
    }
    else if ([request.URL.absoluteString isEqualToString:@"ytplayer://onError?data=150"] || [request.URL.absoluteString isEqualToString:@"ytplayer://onStateChange?data=0"])
    {
        [self nextVideo]; // play next video if current can't be played
    }
    
    if (self.allowLandscapeMode) {
        // allows youtube player in landscape mode
        if ([request.URL.absoluteString isEqualToString:@"ytplayer://onStateChange?data=3"])
        {
            [self playerStarted];
            
            return NO;
        }
        if ([request.URL.absoluteString isEqualToString:@"ytplayer://onStateChange?data=2"])
        {
            [self playerEnded];
            
            return NO;
        }
    }
    
    if ([request.URL.scheme isEqual:@"ytplayer"])
    {
        [self notifyDelegateOfYouTubeCallbackUrl:request.URL];
        return NO;
    }
    else if ([request.URL.scheme isEqual: @"http"] || [request.URL.scheme isEqual:@"https"])
    {
        return [self handleHttpNavigationToUrl:request.URL];
    }
    
    return YES;
}

/**
 * Convert a quality value from NSString to the typed enum value.
 *
 * @param qualityString A string representing playback quality. Ex: "small", "medium", "hd1080".
 * @return An enum value representing the playback quality.
 */
+ (YTPlaybackQuality)playbackQualityForString:(NSString *)qualityString
{
    YTPlaybackQuality quality = kYTPlaybackQualityUnknown;

    if ([qualityString isEqualToString:kYTPlaybackQualitySmallQuality])
    {
        quality = kYTPlaybackQualitySmall;
    }
    else if ([qualityString isEqualToString:kYTPlaybackQualityMediumQuality])
    {
        quality = kYTPlaybackQualityMedium;
    }
    else if ([qualityString isEqualToString:kYTPlaybackQualityLargeQuality])
    {
        quality = kYTPlaybackQualityLarge;
    }
    else if ([qualityString isEqualToString:kYTPlaybackQualityHD720Quality])
    {
        quality = kYTPlaybackQualityHD720;
    }
    else if ([qualityString isEqualToString:kYTPlaybackQualityHD1080Quality])
    {
        quality = kYTPlaybackQualityHD1080;
    }
    else if ([qualityString isEqualToString:kYTPlaybackQualityHighResQuality])
    {
        quality = kYTPlaybackQualityHighRes;
    }

    return quality;
}

/**
 * Convert a |YTPlaybackQuality| value from the typed value to NSString.
 *
 * @param quality A |YTPlaybackQuality| parameter.
 * @return An |NSString| value to be used in the JavaScript bridge.
 */
+ (NSString *)stringForPlaybackQuality:(YTPlaybackQuality)quality
{
    switch (quality) {
        case kYTPlaybackQualitySmall:
            return kYTPlaybackQualitySmallQuality;
        case kYTPlaybackQualityMedium:
            return kYTPlaybackQualityMediumQuality;
        case kYTPlaybackQualityLarge:
            return kYTPlaybackQualityLargeQuality;
        case kYTPlaybackQualityHD720:
            return kYTPlaybackQualityHD720Quality;
        case kYTPlaybackQualityHD1080:
            return kYTPlaybackQualityHD1080Quality;
        case kYTPlaybackQualityHighRes:
            return kYTPlaybackQualityHighResQuality;
        default:
            return kYTPlaybackQualityUnknownQuality;
    }
}

/**
 * Convert a state value from NSString to the typed enum value.
 *
 * @param stateString A string representing player state. Ex: "-1", "0", "1".
 * @return An enum value representing the player state.
 */
+ (YTPlayerState)playerStateForString:(NSString *)stateString
{
    YTPlayerState state = kYTPlayerStateUnknown;
    
    if ([stateString isEqualToString:kYTPlayerStateUnstartedCode])
    {
        state = kYTPlayerStateUnstarted;
    }
    else if ([stateString isEqualToString:kYTPlayerStateEndedCode])
    {
        state = kYTPlayerStateEnded;
    }
    else if ([stateString isEqualToString:kYTPlayerStatePlayingCode])
    {
        state = kYTPlayerStatePlaying;
    }
    else if ([stateString isEqualToString:kYTPlayerStatePausedCode])
    {
        state = kYTPlayerStatePaused;
    }
    else if ([stateString isEqualToString:kYTPlayerStateBufferingCode])
    {
        state = kYTPlayerStateBuffering;
    }
    else if ([stateString isEqualToString:kYTPlayerStateCuedCode])
    {
        state = kYTPlayerStateQueued;
    }
    
    return state;
}

/**
 * Convert a state value from the typed value to NSString.
 *
 * @param quality A |YTPlayerState| parameter.
 * @return A string value to be used in the JavaScript bridge.
 */
+ (NSString *)stringForPlayerState:(YTPlayerState)state
{
    switch (state) {
        case kYTPlayerStateUnstarted:
            return kYTPlayerStateUnstartedCode;
        case kYTPlayerStateEnded:
            return kYTPlayerStateEndedCode;
        case kYTPlayerStatePlaying:
            return kYTPlayerStatePlayingCode;
        case kYTPlayerStatePaused:
            return kYTPlayerStatePausedCode;
        case kYTPlayerStateBuffering:
            return kYTPlayerStateBufferingCode;
        case kYTPlayerStateQueued:
            return kYTPlayerStateCuedCode;
        default:
            return kYTPlayerStateUnknownCode;
    }
}

#pragma mark - Private methods

/**
 * Private method to handle "navigation" to a callback URL of the format
 * http://ytplayer/action?data=someData
 * This is how the UIWebView communicates with the containing Objective-C code.
 * Side effects of this method are that it calls methods on this class's delegate.
 *
 * @param url A URL of the format http://ytplayer/action.
 */
- (void)notifyDelegateOfYouTubeCallbackUrl: (NSURL *) url
{
    NSString *action = url.host;

    // We know the query can only be of the format http://ytplayer?data=SOMEVALUE,
    // so we parse out the value.
    NSString *query = url.query;
    NSString *data;
    if (query)
    {
        data = [query componentsSeparatedByString:@"="][1];
    }

    if ([action isEqual:kYTPlayerCallbackOnReady])
    {
        if ([self.delegate respondsToSelector:@selector(playerViewDidBecomeReady:)])
        {
            [self.delegate playerViewDidBecomeReady:self];
        }
    }
    else if ([action isEqual:kYTPlayerCallbackOnStateChange])
    {
        if ([self.delegate respondsToSelector:@selector(playerView:didChangeToState:)])
        {
            YTPlayerState state = kYTPlayerStateUnknown;

            if ([data isEqual:kYTPlayerStateEndedCode])
            {
                state = kYTPlayerStateEnded;
            }
            else if ([data isEqual:kYTPlayerStatePlayingCode])
            {
                state = kYTPlayerStatePlaying;
            }
            else if ([data isEqual:kYTPlayerStatePausedCode])
            {
                state = kYTPlayerStatePaused;
            }
            else if ([data isEqual:kYTPlayerStateBufferingCode])
            {
                state = kYTPlayerStateBuffering;
            }
            else if ([data isEqual:kYTPlayerStateCuedCode])
            {
                state = kYTPlayerStateQueued;
            }
            else if ([data isEqual:kYTPlayerStateUnstartedCode])
            {
                state = kYTPlayerStateUnstarted;
            }

            [self.delegate playerView:self didChangeToState:state];
        }
    }
    else if ([action isEqual:kYTPlayerCallbackOnPlaybackQualityChange])
    {
        if ([self.delegate respondsToSelector:@selector(playerView:didChangeToQuality:)])
        {
            YTPlaybackQuality quality = [YTPlayerView playbackQualityForString:data];
            [self.delegate playerView:self didChangeToQuality:quality];
        }
    }
    else if ([action isEqual:kYTPlayerCallbackOnError])
    {
        if ([self.delegate respondsToSelector:@selector(playerView:receivedError:)])
        {
            YTPlayerError error = kYTPlayerErrorUnknown;

            if ([data isEqual:kYTPlayerErrorInvalidParamErrorCode])
            {
                error = kYTPlayerErrorInvalidParam;
            }
            else if ([data isEqual:kYTPlayerErrorHTML5ErrorCode])
            {
                error = kYTPlayerErrorHTML5Error;
            }
            else if ([data isEqual:kYTPlayerErrorNotEmbeddableErrorCode])
            {
                error = kYTPlayerErrorNotEmbeddable;
            }
            else if ([data isEqual:kYTPlayerErrorVideoNotFoundErrorCode] || [data isEqual:kYTPlayerErrorCannotFindVideoErrorCode])
            {
                error = kYTPlayerErrorVideoNotFound;
            }

            [self.delegate playerView:self receivedError:error];
        }
    }
}

- (BOOL)handleHttpNavigationToUrl:(NSURL *) url
{
    // Usually this means the user has clicked on the YouTube logo or an error message in the
    // player. Most URLs should open in the browser. The only http(s) URL that should open in this
    // UIWebView is the URL for the embed, which is of the format:
    //     http(s)://www.youtube.com/embed/[VIDEO ID]?[PARAMETERS]
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:kYTPlayerEmbedUrlRegexPattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    
    NSTextCheckingResult *match = [regex firstMatchInString:url.absoluteString
                                                    options:0
                                                      range:NSMakeRange(0, [url.absoluteString length])];
    if (match)
    {
        return YES;
    }
    else
    {
        [[UIApplication sharedApplication] openURL:url];
        return NO;
    }
}


/**
 * Private helper method to load an iframe player with the given player parameters.
 *
 * @param additionalPlayerParams An NSDictionary of parameters in addition to required parameters
 *                               to instantiate the HTML5 player with. This differs depending on
 *                               whether a single video or playlist is being loaded.
 * @return YES if successful, NO if not.
 */
- (BOOL)loadWithPlayerParams:(NSDictionary *)additionalPlayerParams
{
    // Remove the existing webView to reset any state
    [self.webView removeFromSuperview];
    
    // creating webview for youtube player
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        _webView = [self createNewWebView];
        [self addSubview:self.webView];
    });
    
    // preserving users frame
    _prevFrame = self.frame;
    
    NSDictionary *playerCallbacks = @{
        @"onReady" : @"onReady",
        @"onStateChange" : @"onStateChange",
        @"onPlaybackQualityChange" : @"onPlaybackQualityChange",
        @"onError" : @"onPlayerError"
    };
    
    NSMutableDictionary *playerParams = [[NSMutableDictionary alloc] init];
    [playerParams addEntriesFromDictionary:additionalPlayerParams];
    [playerParams setValue:@"100%" forKey:@"height"];
    [playerParams setValue:@"100%" forKey:@"width"];
    [playerParams setValue:playerCallbacks forKey:@"events"];

    // This must not be empty so we can render a '{}' in the output JSON
    if (![playerParams objectForKey:@"playerVars"])
    {
        [playerParams setValue:[[NSDictionary alloc] init] forKey:@"playerVars"];
    }

    NSError *error = nil;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"YTPlayerView-iframe-player"
                                                     ofType:@"html"
                                                inDirectory:@""];

    NSString *embedHTMLTemplate = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];

    if (error)
    {
        NSLog(@"Received error rendering template: %@", error);
        return NO;
    }

    // Render the playerVars as a JSON dictionary.
    NSError *jsonRenderingError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:playerParams
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&jsonRenderingError];
    
    if (jsonRenderingError)
    {
        NSLog(@"Attempted configuration of player with invalid playerVars: %@ \tError: %@", playerParams, jsonRenderingError);
        NSString *errMessage = [NSString stringWithFormat:@"\nAttempted configuration of player with invalid playerVars: %@ \nError: %@", playerParams, jsonRenderingError];
        @throw [NSException exceptionWithName:NSGenericException reason:errMessage userInfo:nil];
        return NO;
    }

    NSString *playerVarsJsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    NSString *embedHTML = [NSString stringWithFormat:embedHTMLTemplate, playerVarsJsonString];
    
    NSLog(@"%@", embedHTML);
    
    [self.webView loadHTMLString:embedHTML baseURL:[NSURL URLWithString:@"about:blank"]];
    [self.webView setDelegate:self];
    self.webView.allowsInlineMediaPlayback = YES;
    self.webView.mediaPlaybackRequiresUserAction = NO;
    
    return YES;
}

/**
 * Private method for cueing both cases of playlist ID and array of video IDs. Cueing
 * a playlist does not start playback.
 *
 * @param cueingString A JavaScript string representing an array, playlist ID or list of
 *                     video IDs to play with the playlist player.
 * @param index 0-index position of video to start playback on.
 * @param startSeconds Seconds after start of video to begin playback.
 * @param suggestedQuality Suggested YTPlaybackQuality to play the videos.
 * @return The result of cueing the playlist.
 */
- (void)cuePlaylist:(NSString *)cueingString index:(int)index startSeconds:(float)startSeconds suggestedQuality:(YTPlaybackQuality)suggestedQuality
{
    NSNumber *indexValue = [NSNumber numberWithInt:index];
    NSNumber *startSecondsValue = [NSNumber numberWithFloat:startSeconds];
    NSString *qualityValue = [YTPlayerView stringForPlaybackQuality:suggestedQuality];
    NSString *command = [NSString stringWithFormat:@"player.cuePlaylist(%@, %@, %@, '%@');", cueingString, indexValue, startSecondsValue, qualityValue];
    [self stringFromEvaluatingJavaScript:command];
}

/**
 * Private method for loading both cases of playlist ID and array of video IDs. Loading
 * a playlist automatically starts playback.
 *
 * @param cueingString A JavaScript string representing an array, playlist ID or list of
 *                     video IDs to play with the playlist player.
 * @param index 0-index position of video to start playback on.
 * @param startSeconds Seconds after start of video to begin playback.
 * @param suggestedQuality Suggested YTPlaybackQuality to play the videos.
 * @return The result of cueing the playlist.
 */
- (void)loadPlaylist:(NSString *)cueingString index:(int)index startSeconds:(float)startSeconds suggestedQuality:(YTPlaybackQuality)suggestedQuality
{
    NSNumber *indexValue = [NSNumber numberWithInt:index];
    NSNumber *startSecondsValue = [NSNumber numberWithFloat:startSeconds];
    NSString *qualityValue = [YTPlayerView stringForPlaybackQuality:suggestedQuality];
    NSString *command = [NSString stringWithFormat:@"player.loadPlaylist(%@, %@, %@, '%@');", cueingString, indexValue, startSecondsValue, qualityValue];
    [self stringFromEvaluatingJavaScript:command];
}

/**
 * Private helper method for converting an NSArray of video IDs into its JavaScript equivalent.
 *
 * @param videoIds An array of video ID strings to convert into JavaScript format.
 * @return A JavaScript array in String format containing video IDs.
 */
- (NSString *)stringFromVideoIdArray:(NSArray *)videoIds
{
    NSMutableArray *formattedVideoIds = [[NSMutableArray alloc] init];

    for (id unformattedId in videoIds)
    {
        [formattedVideoIds addObject:[NSString stringWithFormat:@"'%@'", unformattedId]];
    }

    return [NSString stringWithFormat:@"[%@]", [formattedVideoIds componentsJoinedByString:@", "]];
}

/**
 * Private method for evaluating JavaScript in the WebView.
 *
 * @param jsToExecute The JavaScript code in string format that we want to execute.
 * @return JavaScript response from evaluating code.
 */
- (NSString *)stringFromEvaluatingJavaScript:(NSString *)jsToExecute
{
    return [self.webView stringByEvaluatingJavaScriptFromString:jsToExecute];
}

/**
 * Private method to convert a Objective-C BOOL value to JS boolean value.
 *
 * @param boolValue Objective-C BOOL value.
 * @return JavaScript Boolean value, i.e. "true" or "false".
 */
- (NSString *)stringForJSBoolean:(BOOL)boolValue
{
    return boolValue ? @"true" : @"false";
}


#pragma mark - Helper Functions

/**
 * Removes customs notifications
 * @name dealloc
 *
 * @param ...
 * @return void...
 */
- (void)dealloc
{
    // removing notification center
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:[UIDevice currentDevice]];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

- (void)webViewDidFinishLoad:(UIWebView*)webView
{
    if(self.allowLandscapeMode)
    {
        // adding listener to webView
        [_webView stringByEvaluatingJavaScriptFromString:@" for (var i = 0, videos = document.getElementsByTagName('video'); i < videos.length; i++) {"
                                                         @"      videos[i].addEventListener('webkitbeginfullscreen', function(){ "
                                                         @"           window.location = 'ytplayer://begin-fullscreen';"
                                                         @"      }, false);"
                                                         @""
                                                         @"      videos[i].addEventListener('webkitendfullscreen', function(){ "
                                                         @"           window.location = 'ytplayer://end-fullscreen';"
                                                         @"      }, false);"
                                                         @" }"
                                                         ];
    }
}


/**
 * Executes when player starts full screen of video player (good for changing app orientation)
 * @name playerStarted
 *
 * @param ...
 * @return void...
 */
- (void)playerStarted//:(NSNotification*)notification
{
    ((AppDelegate*)[[UIApplication sharedApplication] delegate]).videoIsInFullscreen = YES;
    
    [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait animated:NO];
}


/**
 * Executes when player exits full screen of video player (good for changing app orientation)
 * @name playerEnded
 *
 * @param ...
 * @return void...
 */
- (void)playerEnded//:(NSNotification*)notification
{
    if(self.forceBackToPortraitMode == YES)
    {
        [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIInterfaceOrientationPortrait] forKey:@"orientation"];
        
        ((AppDelegate*)[[UIApplication sharedApplication] delegate]).videoIsInFullscreen = NO;
        
        [self supportedInterfaceOrientations];
        
        [self shouldAutorotate:UIInterfaceOrientationPortrait];
        
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait animated:NO];
    }
}

- (NSInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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
        _screenRect = [[UIScreen mainScreen] bounds].size;
        _screenHeight = _screenRect.height;
        _screenWidth = _screenRect.width;
        
        self.frame = CGRectMake(0, 0, self.screenWidth, self.screenHeight);
    }
    else if(device.orientation == UIDeviceOrientationPortrait || device.orientation == UIDeviceOrientationPortraitUpsideDown)
    {
        self.frame = self.prevFrame;
    }
}


#pragma mark - Exposed for Testing
- (void)setWebView:(UIWebView *)webView
{
    _webView = webView;
}

- (UIWebView *)createNewWebView
{
    if(!_webView)
    {
        _webView = [[UIWebView alloc] initWithFrame:self.bounds];
        _webView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        _webView.scrollView.scrollEnabled = NO;
        _webView.scrollView.bounces = NO;
        _webView.delegate = self;
        
        return _webView;
    }
    
    return _webView;
}

- (NSMutableDictionary*)setDicParameters
{
    if(!_dicParameters)
    {
        _dicParameters = [[NSMutableDictionary alloc] init];
        return _dicParameters;
    }
    return _dicParameters;
}

#pragma mark - Customs Setters and Getters

// Custom setters and getters for youtube player parameters
// to be loaded when player loads video.
// These parameters can be set by the user, if they are not
// they won't be loaded to the player because, youtube api
// will use defaults parameters when player created.

-(BOOL)allowLandscapeMode {
    return _allowLandscapeMode;
}

-(void)setAllowLandscapeMode:(BOOL)allowLandscapeMode {
    _allowLandscapeMode = allowLandscapeMode;
}

-(BOOL)forceBackToPortraitMode {
    return _forceBackToPortraitMode;
}

-(void)setForceBackToPortraitMode:(BOOL)forceBackToPortraitMode {
    _forceBackToPortraitMode = forceBackToPortraitMode;
}

-(BOOL)allowAutoResizingPlayerFrame {
    return _allowAutoResizingPlayerFrame;
}

-(void)setAllowAutoResizingPlayerFrame:(BOOL)allowAutoResizingPlayerFrame {
    
    if(allowAutoResizingPlayerFrame == YES) {
        // current device
        UIDevice *device = [UIDevice currentDevice];
        
        //Tell it to start monitoring the accelerometer for orientation
        [device beginGeneratingDeviceOrientationNotifications];
        //Get the notification centre for the app
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:device];
    }
    _allowAutoResizingPlayerFrame = allowAutoResizingPlayerFrame;
}

-(BOOL)autohide {
    return _autohide;
}

-(void)setAutohide:(BOOL)autohide {

    if(autohide == YES) {
        _dicParameters = [self setDicParameters];
        [self.dicParameters setObject:@(1) forKey:@"autohide"];
    }
    _autohide = autohide;
}

-(BOOL)autoplay {
    return _autoplay;
}

-(void)setAutoplay:(BOOL)autoplay {
    
    if(autoplay == YES) {
        _dicParameters = [self setDicParameters];
        [self.dicParameters setObject:@(1) forKey:@"autoplay"];
    }
    _autoplay = autoplay;
}

-(BOOL)cc_load_policy {
    return _cc_load_policy;
}

-(void)setCc_load_policy:(BOOL)cc_load_policy {
    
    if(cc_load_policy == YES) {
        _dicParameters = [self setDicParameters];
        [self.dicParameters setObject:@(1) forKey:@"cc_load_policy"];
    }
    _cc_load_policy = cc_load_policy;
}

-(BOOL)color {
    return _color;
}

-(void)setColor:(BOOL)color {
    
    if(color == YES) {
        _dicParameters = [self setDicParameters];
        [self.dicParameters setObject:@"white" forKey:@"color"];
    }
    _color = color;
}

-(BOOL)controls {
    return _controls;
}

-(void)setControls:(BOOL)controls {
    
    if(controls == YES) {
        _dicParameters = [self setDicParameters];
        [self.dicParameters setObject:@(0) forKey:@"controls"];
    }
    _controls = controls;
}

-(BOOL)disablekb {
    return _disablekb;
}

-(void)setDisablekb:(BOOL)disablekb {
    
    if(disablekb == YES) {
        _dicParameters = [self setDicParameters];
        [self.dicParameters setObject:@(1) forKey:@"disablekb"];
    }
    _disablekb = disablekb;
}

-(BOOL)enablejsapi {
    return _enablejsapi;
}

-(void)setEnablejsapi:(BOOL)enablejsapi {
    
    if(enablejsapi == YES) {
        _dicParameters = [self setDicParameters];
        [self.dicParameters setObject:@(1) forKey:@"enablejsapi"];
    }
    _enablejsapi = enablejsapi;
}

-(int)end {
    return _end;
}

-(void)setEnd:(int)end {
    
    if(end > 0) {
        _dicParameters = [self setDicParameters];
        [self.dicParameters setObject:@(end) forKey:@"end"];
    }
    _end = end;
}

-(BOOL)fullscreen {
    return _fullscreen;
}

-(void)setFullscreen:(BOOL)fullscreen {
    
    if(fullscreen == YES) {
        _dicParameters = [self setDicParameters];
        [self.dicParameters setObject:@(0) forKey:@"fs"];
    }
    _fullscreen = fullscreen;
}

-(BOOL)iv_load_policy {
    return _iv_load_policy;
}

-(void)setIv_load_policy:(BOOL)iv_load_policy {
    
    if(iv_load_policy == YES) {
        _dicParameters = [self setDicParameters];
        [self.dicParameters setObject:@(3) forKey:@"iv_load_policy"];
    }
    _iv_load_policy = iv_load_policy;
}

-(NSString*)list {
    return _list;
}

-(void)setList:(NSString *)list {
    
    if(list.length > 0) {
        _dicParameters = [self setDicParameters];
        [self.dicParameters setObject:list forKey:@"list"];
    }
    _list = list;
}

-(NSString*)listType {
    return _listType;
}

-(void)setListType:(NSString *)listType {
    
    if(listType.length > 0) {
        _dicParameters = [self setDicParameters];
        [self.dicParameters setObject:listType forKey:@"listType"];
    }
    _listType = listType;
}

-(BOOL)loops {
    return _loops;
}

-(void)setLoops:(BOOL)loops {
    
    if(loops == YES) {
        _dicParameters = [self setDicParameters];
        [self.dicParameters setObject:@(1) forKey:@"loop"];
    }
    _loops = loops;
}

-(BOOL)modestbranding {
    return _modestbranding;
}

-(void)setModestbranding:(BOOL)modestbranding {
    
    if(modestbranding == YES) {
        _dicParameters = [self setDicParameters];
        [_dicParameters setObject:[NSNumber numberWithInt:1] forKey:@"modestbranding"];
    }
    _modestbranding = modestbranding;
}

-(NSString*)playerapiid {
    return _playerapiid;
}

-(void)setPlayerapiid:(NSString *)playerapiid {
    
    if(playerapiid.length > 0) {
        _dicParameters = [self setDicParameters];
        [self.dicParameters setObject:playerapiid forKey:@"playerapiid"];
    }
    _playerapiid = playerapiid;
}

-(NSString*)playList {
    return _playList;
}

-(void)setPlayList:(NSString*)playList {
    
    if(playList.length > 0) {
        _dicParameters = [self setDicParameters];
        [self.dicParameters setObject:playList forKey:@"playlist"];
    }
    _playList = playList;
}

-(BOOL)playsinline {
    return _playsinline;
}

-(void)setPlaysinline:(BOOL)playsinline {
    
    if(playsinline == YES) {
        _dicParameters = [self setDicParameters];
        [self.dicParameters setObject:@(1) forKey:@"playsinline"];
    }
    _playsinline = playsinline;
}

-(BOOL)rel {
    return _rel;
}

-(void)setRel:(BOOL)rel {
    
    if(rel == YES) {
        _dicParameters = [self setDicParameters];
        [self.dicParameters setObject:@(1) forKey:@"rel"];
    }
    _rel = rel;
}

-(BOOL)showinfo {
    return _fullscreen;
}

-(void)setShowinfo:(BOOL)showinfo {
    
    if(showinfo == YES) {
        _dicParameters = [self setDicParameters];
        [self.dicParameters setObject:@(0) forKey:@"showinfo"];
    }
    _showinfo = showinfo;
}

-(int)start {
    return _start;
}

-(void)setStart:(int)start {
    
    if(start == YES) {
        _dicParameters = [self setDicParameters];
        [self.dicParameters setObject:@(start) forKey:@"start"];
    }
    _start = start;
}

-(BOOL)theme {
    return _theme;
}

-(void)setTheme:(BOOL)theme {
    
    if(theme == YES) {
        _dicParameters = [self setDicParameters];
        [self.dicParameters setObject:@"light" forKey:@"theme"];
    }
    _theme = theme;
}

@end