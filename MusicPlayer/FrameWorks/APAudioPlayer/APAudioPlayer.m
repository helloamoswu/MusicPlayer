//
//  APAudioPlayer.m
//  APAudioPlayer
//
//  Created by Sergii Kryvoblotskyi on 5/20/14.
//  Copyright (c) 2014 Alterplay. All rights reserved.
//

#import "APAudioPlayer.h"
#import "bass.h"
#import <AVFoundation/AVFoundation.h>

#define DEFAULT_BANDWIDTH 12

@interface APAudioPlayer () <AVAudioSessionDelegate> {
	HSTREAM _channel;
    HFX _eqFX;
}

@end

// the sync callback
void CALLBACK ChannelEndedCallback(HSYNC handle, DWORD channel, DWORD data, void *user)
{
    APAudioPlayer *player = (__bridge APAudioPlayer *)(user);
    
    //notify delegate
    if ([player.delegate respondsToSelector:@selector(playerDidFinishPlaying:)]) {
        [player.delegate playerDidFinishPlaying:player];
    }
}

@implementation APAudioPlayer

#pragma mark - Initialization

- (id)init
{
    self = [super init];
    if (self) {
        
        //Load flac
        extern void BASSFLACplugin;
        BASS_PluginLoad(&BASSFLACplugin, 0);
        
        //BASS_PluginLoad([apeLib cStringUsingEncoding:NSASCIIStringEncoding], 0);
        
        //BASS init
        BASS_Init(-1, 44100, 0, NULL, NULL);

        //Observe interuptions
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(audioInteruptionOccured:)
                                                     name:AVAudioSessionInterruptionNotification
                                                   object:nil];
        
        //Set volume
        _volume = BASS_GetConfig(BASS_CONFIG_GVOL_STREAM) / 10000.0f;
        
        self.hasPlayItem = NO;
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    BASS_Free();
}

#pragma mark -
#pragma mark - Public API
#pragma mark -

#pragma mark - Controls

- (BOOL)playItemWithURL:(NSURL *)url
{
//    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error: nil];
//	[[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    //Stop channel;
    BASS_ChannelStop(_channel);
    
    //Free memory
    BASS_StreamFree(_channel);
    
    if (url.isFileURL) {
        _channel = BASS_StreamCreateFile(FALSE, [[url path] cStringUsingEncoding:NSUTF8StringEncoding], 0, 0, 0);
    } else {
        _channel = BASS_StreamCreateURL([[url path] cStringUsingEncoding:NSUTF8StringEncoding], 0, 0, NULL, 0);
    }
    
    //Set callback
    BASS_ChannelSetSync(_channel, BASS_SYNC_END, 0, ChannelEndedCallback, (__bridge void *)self);
    
    //Let's Rock!
    BASS_ChannelPlay(_channel, NO);
    
    self.hasPlayItem = YES;
    
    _eqFX = BASS_ChannelSetFX(_channel, BASS_FX_DX8_PARAMEQ, 10000);

    int code = BASS_ErrorGetCode();
    return code == 0;
}

- (void)setGain:(float)value forCenterFrequency:(float)center
{
    BASS_DX8_PARAMEQ eq = {center, DEFAULT_BANDWIDTH, value};
    BASS_FXSetParameters(_eqFX, &eq);
}


- (void)pause
{
    BASS_ChannelPause(_channel);
}

- (void)resume
{
    BASS_ChannelPlay(_channel, NO);
}

- (void)stop
{
    BASS_ChannelStop(_channel);
}

- (BOOL)isPlaying
{
    DWORD isPlaying = BASS_ChannelIsActive(_channel);
    return isPlaying == BASS_ACTIVE_PLAYING;
}

#pragma mark - Values

- (NSTimeInterval)duration
{
    QWORD len = BASS_ChannelGetLength(_channel, BASS_POS_BYTE);
    double time = BASS_ChannelBytes2Seconds(_channel, len);
    return time;
}

- (NSTimeInterval)currentTime
{
    QWORD len = BASS_ChannelGetPosition(_channel, BASS_POS_BYTE);
    double currentTime = BASS_ChannelBytes2Seconds(_channel, len);
    return currentTime;
}

-(void)setCurrentTime:(NSTimeInterval)currentTime
{
    QWORD len = BASS_ChannelSeconds2Bytes(_channel, currentTime);
    BASS_ChannelSetPosition(_channel, len, BASS_POS_BYTE);
}

- (void)setVolume:(CGFloat)volume {
    _volume = volume;
    BASS_SetConfig(BASS_CONFIG_GVOL_STREAM, volume * 10000.0);
}

#pragma mark -
#pragma mark - Private API
#pragma mark - 

- (void)audioInteruptionOccured:(NSNotification *)notification
{
    NSDictionary *interruptionDictionary = [notification userInfo];
    AVAudioSessionInterruptionType interruptionType = [interruptionDictionary[AVAudioSessionInterruptionTypeKey] integerValue];
    
    switch (interruptionType) {
        case AVAudioSessionInterruptionTypeBegan: {
            
            if ([self.delegate respondsToSelector:@selector(playerBeginInterruption:)]) {
                [self.delegate playerBeginInterruption:self];
            }
        }
            
            break;
        case AVAudioSessionInterruptionTypeEnded: {
            AVAudioSessionInterruptionOptions options = [interruptionDictionary[AVAudioSessionInterruptionOptionKey] integerValue];
            
            if ([self.delegate respondsToSelector:@selector(playerEndInterruption:shouldResume:)]) {
                [self.delegate playerEndInterruption:self
                                        shouldResume:options == AVAudioSessionInterruptionOptionShouldResume];
            }
        }
            break;
            
        default:
            break;
    }
}

@end
