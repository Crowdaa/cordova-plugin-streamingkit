/********* cordova-plugin-streamingkit.m Cordova Plugin Implementation *******/

#import "CDVStreamingKitPlugin.h"
#import <AVFoundation/AVFoundation.h>

@interface CDVStreamingKitPlugin()
{
    STKAudioPlayer* audioPlayer;
}
@end

@implementation CDVStreamingKitPlugin
@synthesize audioPlayer, delegate;

- (void)pluginInitialize {
    NSLog(@"Starting CDV StreamingKit plugin");

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidFinishLaunching:)
                                                 name:UIApplicationDidFinishLaunchingNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];
}



- (void)dealloc {
    NSLog(@"dealloc CDV StreamingKit plugin");
    if (audioPlayer) {
        [audioPlayer dispose];
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidFinishLaunchingNotification
                                                  object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:nil];
}


- (void) applicationDidFinishLaunching:(NSNotification *) notification {
    NSDictionary* launchOptions = notification.userInfo;
    if (launchOptions == nil) {
        //launchOptions is nil when not start because of notification or url open
        launchOptions = [NSDictionary dictionary];
    }

    //
}

- (void) applicationDidBecomeActive:(NSNotification *) notification {
    //
}

#pragma mark - player


-(void) setAudioPlayer:(STKAudioPlayer*)value
{
    NSLog(@"setAudioPlayer");
    if (audioPlayer)
    {
        audioPlayer.delegate = nil;
    }

    audioPlayer = value;
    audioPlayer.delegate = self;
}

-(STKAudioPlayer*) audioPlayer
{
    return audioPlayer;
}

- (BOOL) startPlayer {
    NSError *error;

    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:&error];
    [session setActive:YES error:&error];

    NSTimeInterval bufferLength = 0.1;
    [session setPreferredIOBufferDuration:bufferLength error:&error];

    if (![session setCategory:AVAudioSessionCategoryPlayback
                  withOptions:AVAudioSessionCategoryOptionMixWithOthers
                        error:&error]) {
        // handle error
    }

    if (error) {
        return NO;
    }

    STKAudioPlayer *player = [[STKAudioPlayer alloc] initWithOptions:(STKAudioPlayerOptions){
        .flushQueueOnSeek = NO,
        .enableVolumeMixer = NO,
        .equalizerBandFrequencies = {50, 100, 200, 400, 800, 1600, 2600, 16000}
    }];
    player.volume = 1;

    [self setAudioPlayer:player];

    return YES;
}

#pragma mark - Cordova commands

- (void)respondWithStatus:(CDVCommandStatus)status commandId:(NSString*)callbackId {
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:status];
    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
}

- (void)play:(CDVInvokedUrlCommand*)command
{
    NSString* resource = [command.arguments objectAtIndex:0];
    NSURL* url = [NSURL URLWithString:resource];

    if (url == nil) {
        return [self respondWithStatus:CDVCommandStatus_ERROR commandId:command.callbackId];
    }

    // STKDataSource* dataSource = [STKAudioPlayer dataSourceFromURL:url];

    // [[self getPlayer] setDataSource:dataSource withQueueItemId:[[SampleQueueId alloc] initWithUrl:url andCount:0]];
    if (audioPlayer == nil && ![self startPlayer]) {
        return [self respondWithStatus:CDVCommandStatus_IO_EXCEPTION commandId:command.callbackId];
    } else {
        [audioPlayer playURL:url];

        return [self respondWithStatus:CDVCommandStatus_OK commandId:command.callbackId];
    }
}

- (void)pause:(CDVInvokedUrlCommand*)command
{
    if (audioPlayer == nil || audioPlayer.currentlyPlayingQueueItemId == nil) {
        return [self respondWithStatus:CDVCommandStatus_ERROR commandId:command.callbackId];
    }

    [audioPlayer pause];

    return [self respondWithStatus:CDVCommandStatus_OK commandId:command.callbackId];
}


- (void)resume:(CDVInvokedUrlCommand*)command
{
    if (audioPlayer == nil || audioPlayer.currentlyPlayingQueueItemId == nil) {
        return [self respondWithStatus:CDVCommandStatus_ERROR commandId:command.callbackId];
    }

    [audioPlayer resume];

    return [self respondWithStatus:CDVCommandStatus_OK commandId:command.callbackId];
}

- (void)stop:(CDVInvokedUrlCommand*)command
{
    if (audioPlayer == nil || audioPlayer.currentlyPlayingQueueItemId == nil) {
        return [self respondWithStatus:CDVCommandStatus_ERROR commandId:command.callbackId];
    }

    [audioPlayer stop];

    return [self respondWithStatus:CDVCommandStatus_OK commandId:command.callbackId];
}

- (NSString *)playerCurrentItem: (STKAudioPlayer *)player {
    if (!player.currentlyPlayingQueueItemId) {
        return @"";
    }

    return [player.currentlyPlayingQueueItemId description];
}

- (void)dispatchEvent:(NSString *)event payload:(NSDictionary *)dict {
    NSLog(@"dispatch event<%@> with payload<%@>", event, dict);
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options: 0 error:&error];

    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
    }

    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSString *jsStatement = [NSString stringWithFormat:@"if(window.streamingKit) { streamingKit.%@(%@); }", event, jsonString];

#ifdef __CORDOVA_4_0_0
    [self.webViewEngine evaluateJavaScript:jsStatement completionHandler:nil];
#else
    [self.webView stringByEvaluatingJavaScriptFromString:jsStatement];
#endif
}

- (void)dispatchAudioPlayer:(STKAudioPlayer*)player stateChange:(STKAudioPlayerState)state {
    NSLog(@"stateChange item:%@ with state: %d", player.currentlyPlayingQueueItemId, state);
    NSDictionary *dict = @{
                           @"item": [self playerCurrentItem:player],
                           @"state": @(state)
                           };

    [self dispatchEvent: @"onStateChanged" payload: dict];
}

#pragma mark - STKAudioPlayerDelegate Overrides

/// Raised when an item has started playing
-(void) audioPlayer:(STKAudioPlayer*)player didStartPlayingQueueItemId:(NSObject*)queueItemId {
    NSLog(@"didStartPlayingQueueItemId %@ %@", player.currentlyPlayingQueueItemId, queueItemId);
}

/// Raised when an item has finished buffering (may or may not be the currently playing item)
/// This event may be raised multiple times for the same item if seek is invoked on the player
-(void) audioPlayer:(STKAudioPlayer*)player didFinishBufferingSourceWithQueueItemId:(NSObject*)queueItemId {
    NSLog(@"didFinishBufferingSourceWithQueueItemId %@ %@", player.currentlyPlayingQueueItemId, queueItemId);
}

/// Raised when the state of the player has changed
-(void) audioPlayer:(STKAudioPlayer*)player stateChanged:(STKAudioPlayerState)state previousState:(STKAudioPlayerState)previousState {
    NSLog(@"stateChanged %@ %d %d", player.currentlyPlayingQueueItemId, state, previousState);
    [self dispatchAudioPlayer: player stateChange: state];
}

/// Raised when an item has finished playing
-(void) audioPlayer:(STKAudioPlayer*)player didFinishPlayingQueueItemId:(NSObject*)queueItemId withReason:(STKAudioPlayerStopReason)stopReason andProgress:(double)progress andDuration:(double)duration {
    NSLog(@"didFinishPlayingQueueItemId %@ %f %f", player.currentlyPlayingQueueItemId, progress, duration);
}

/// Raised when an unexpected and possibly unrecoverable error has occured (usually best to recreate the STKAudioPlauyer)
-(void) audioPlayer:(STKAudioPlayer*)player unexpectedError:(STKAudioPlayerErrorCode)errorCode {
    NSLog(@"unexpectedError %@ %d", player.currentlyPlayingQueueItemId, errorCode);
}

/// Optionally implemented to get logging information from the STKAudioPlayer (used internally for debugging)
-(void) audioPlayer:(STKAudioPlayer*)player logInfo:(NSString*)line {

}

/// Raised when items queued items are cleared (usually because of a call to play, setDataSource or stop)
-(void) audioPlayer:(STKAudioPlayer*)audioPlayer didCancelQueuedItems:(NSArray*)queuedItems {
    NSLog(@"didCancelQueuedItems");
}

@end
