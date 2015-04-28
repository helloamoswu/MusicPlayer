//
//  EqualizerView.m
//  MusicPlayer
//
//  Created by amos on 15-4-8.
//  Copyright (c) 2015年 amos. All rights reserved.
//

#import "EqualizerView.h"
#import "MPManager.h"

@interface EqualizerView ()

@property (nonatomic, weak)MPManager *playerManager;
@property (nonatomic, strong)NSMutableArray *sliders;

@end

@implementation EqualizerView

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self createEqualizer];
        self.backgroundColor = [UIColor blackColor];
        self.alpha = 0.7;
        self.playerManager = [MPManager shareManager];
    }
    
    return self;
}

- (void)createEqualizer
{
    long equalizerFreqs[10] = {60,170,370,600,1000,3000,6000,12000, 14000, 15000};
    
    self.sliders = [NSMutableArray array];
    for (int i = 0; i < 10; i++) {
        UISlider *slider = [[UISlider alloc]initWithFrame:CGRectMake(10, 10, 200, 25)];
        slider.transform=CGAffineTransformRotate(slider.transform,90.0/180*M_PI);
        [slider setThumbImage:[UIImage imageNamed:@"thumb_white"] forState:UIControlStateNormal];
        CGRect frame = slider.frame;
        frame.origin.x = 5+i*25;
        frame.origin.y = 40;
        slider.frame = frame;
        
        
        slider.maximumValue = 15;
        slider.minimumValue = -15;
        slider.value = 0;
        slider.tag = equalizerFreqs[i];
        
        [slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        
        [self addSubview:slider];
        [self.sliders addObject:slider];
        
        UILabel *topFreqLabel = [[UILabel alloc]initWithFrame:CGRectMake(frame.origin.x, 0, 25, 20)];
        topFreqLabel.backgroundColor = [UIColor clearColor];
        NSString *formateStr = equalizerFreqs[i]>1000 ? @"%.fK" : @"%.f";
        topFreqLabel.text = [NSString stringWithFormat:formateStr, equalizerFreqs[i]>1000?equalizerFreqs[i]/1000.0:equalizerFreqs[i]];
        topFreqLabel.textAlignment = NSTextAlignmentCenter;
        topFreqLabel.textColor = [UIColor whiteColor];
        topFreqLabel.font = [UIFont systemFontOfSize:10];
        
        UILabel *topGainLabel = [[UILabel alloc]initWithFrame:CGRectMake(frame.origin.x + 2, 20, 20, 20)];
        topGainLabel.backgroundColor = [UIColor clearColor];
        topGainLabel.text = @"15";
        topGainLabel.textColor = [UIColor whiteColor];
        topGainLabel.textAlignment = NSTextAlignmentCenter;
        topGainLabel.font = [UIFont systemFontOfSize:12];
        
        UILabel *bottomGainLabel = [[UILabel alloc]initWithFrame:CGRectMake(frame.origin.x + 2, 240, 20, 20)];
        bottomGainLabel.backgroundColor = [UIColor clearColor];
        bottomGainLabel.text = @"-15";
        bottomGainLabel.textColor = [UIColor whiteColor];
        bottomGainLabel.textAlignment = NSTextAlignmentCenter;
        bottomGainLabel.font = [UIFont systemFontOfSize:12];
        
        [self addSubview:topFreqLabel];
        [self addSubview:topGainLabel];
        [self addSubview:bottomGainLabel];
        
        UIButton *restoreBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        restoreBtn.frame = CGRectMake(0, 260, 260, 20);
        [restoreBtn setTitle:@"恢复预设" forState:UIControlStateNormal];
        [restoreBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [restoreBtn setBackgroundColor:[UIColor blackColor]];
        restoreBtn.alpha = 0.8;
        
        [restoreBtn addTarget:self action:@selector(restoreEqualizerValue) forControlEvents:UIControlEventTouchUpInside];
        
        [self addSubview:restoreBtn];
    }
}

- (void)sliderValueChanged:(UISlider *)sender
{
    [self.playerManager setGain:sender.value forCenterFrequency:sender.tag];
}

- (void)restoreEqualizerValue
{
    for (int i = 0; i < 10; i++) {
        UISlider *slider = self.sliders[i];
        [self.playerManager setGain:0 forCenterFrequency:slider.tag];
        [UIView animateWithDuration:1.5 animations:^{
            slider.value = 0;
        }];
        
    }
}

@end
