//
//  ViewController.m
//  MergeAbundantVideos
//
//  Created by changcai on 17/4/26.
//  Copyright © 2017年 changcai. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "PlayViewController.h"
#import "MBProgressHUD.h"
#define VIDEO_URL_1 [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"video1" ofType:@"mp4"]]
#define VIDEO_URL_2 [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"video2" ofType:@"mp4"]]
@interface ViewController ()

/**   */
@property (nonatomic, strong) NSURL *outputUrl;

@property (weak, nonatomic) IBOutlet UIButton *mergeBtn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}


- (void)mergeAndExportVideos:(NSArray*)videosPathArray  withOutPath:(NSString*)outpath
{
    
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    //音频轨道
    AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
    //视频轨道
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
    CMTime totalDuration = kCMTimeZero;
    for (int i = 0; i < videosPathArray.count; i++) {
        //AVURLAsset：AVAsset的子类，此类主要用于获取多媒体的信息，包括视频、音频的类型、时长、每秒帧数，其实还可以用来获取视频的指定位置的缩略图。
        AVURLAsset *asset = [AVURLAsset assetWithURL:videosPathArray[i]];
        NSError *erroraudio = nil;
        //获取AVAsset中的音频
        AVAssetTrack *assetAudioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
        //向通道内加入音频
        BOOL ba = [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                                      ofTrack:assetAudioTrack
                                       atTime:totalDuration
                                        error:&erroraudio];
        
        NSLog(@"erroraudio:%@%d",erroraudio,ba);
        NSError *errorVideo = nil;
        //获取AVAsset中的视频
        AVAssetTrack *assetVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo]firstObject];
        //向通道内加入视频
        BOOL bl = [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                                      ofTrack:assetVideoTrack
                                       atTime:totalDuration
                                        error:&errorVideo];
        NSLog(@"errorVideo:%@%d",errorVideo,bl);
        totalDuration = CMTimeAdd(totalDuration, asset.duration);
    }
    NSLog(@"%@",NSHomeDirectory());
    NSURL *mergeFileURL = [NSURL fileURLWithPath:outpath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:outpath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:outpath error:nil];
    }
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                                      presetName:AVAssetExportPreset640x480];
    exporter.outputURL = mergeFileURL;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.shouldOptimizeForNetworkUse = YES;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        switch (exporter.status) {
            case AVAssetExportSessionStatusUnknown:
                NSLog(@"exporter Unknow");
                break;
            case AVAssetExportSessionStatusCancelled:
                NSLog(@"exporter Canceled");
                break;
            case AVAssetExportSessionStatusFailed:
                NSLog(@"exporter Failed");
                break;
            case AVAssetExportSessionStatusWaiting:
                NSLog(@"exporter Waiting");
                break;
            case AVAssetExportSessionStatusExporting:
                NSLog(@"exporter Exporting");
                break;
            case AVAssetExportSessionStatusCompleted:
                NSLog(@"exporter Completed");
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.outputUrl = mergeFileURL;
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                    [self playVideo];
                });
                break;
        }
    }];
}
- (void)playVideo
{
    PlayViewController *pvc = [[PlayViewController alloc]init];
    pvc.videoUrl = self.outputUrl;
    [self.navigationController pushViewController:pvc animated:YES];
}

- (IBAction)mergebtnClick:(UIButton *)sender {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    NSString* videoName = @"MixVideo.mp4";
    NSString *exportPath = [NSTemporaryDirectory() stringByAppendingPathComponent:videoName];
    [self mergeAndExportVideos:@[VIDEO_URL_1,VIDEO_URL_2,VIDEO_URL_1] withOutPath:exportPath];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
