//
//  ViewController.m
//  Demo
//
//  Created by zz on 2018/7/13.
//  Copyright © 2018年 Company. All rights reserved.
//

#import "ViewController.h"
#import "VideoPreviewController.h"
@import TXLiteAVSDK_UGC;

@interface ViewController () <TXVideoPreviewListener, TXUGCRecordListener, TXVideoJoinerListener>
{
    TXVideoEditer *_editor;
    TXUGCRecord   *_recorder;
    TXVideoJoiner *_joiner;
    
    TXVideoInfo    *_videoInfo;
    
    NSString       *_recordPath;
    NSString       *_resultPath;
    NSString       *_mp4Path;
}

@property (weak, nonatomic) IBOutlet UIView *cameraView;
@property (weak, nonatomic) IBOutlet UIView *movieView;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

- (IBAction)onTapButton:(UIButton *)sender;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // 这里找一段mp4视频放到了工程里，或者用手机录制的mov格式视频也可以
    NSString *mp4Path = [[NSBundle mainBundle] pathForResource:@"demo" ofType:@"mp4"];
    _videoInfo = [TXVideoInfoReader getVideoInfo:mp4Path];
    TXAudioSampleRate audioSampleRate = AUDIO_SAMPLERATE_48000;
    if (_videoInfo.audioSampleRate == 8000) {
        audioSampleRate = AUDIO_SAMPLERATE_8000;
    }else if (_videoInfo.audioSampleRate == 16000){
        audioSampleRate = AUDIO_SAMPLERATE_16000;
    }else if (_videoInfo.audioSampleRate == 32000){
        audioSampleRate = AUDIO_SAMPLERATE_32000;
    }else if (_videoInfo.audioSampleRate == 44100){
        audioSampleRate = AUDIO_SAMPLERATE_44100;
    }else if (_videoInfo.audioSampleRate == 48000){
        audioSampleRate = AUDIO_SAMPLERATE_48000;
    }
    
    // 设置录像的保存路径
    _recordPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"record.mp4"];
    _resultPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"result.mp4"];
    
    // 播放器初始化
    TXPreviewParam *param = [[TXPreviewParam alloc] init];
    param.videoView = self.movieView;
    param.renderMode = RENDER_MODE_FILL_EDGE;
    _editor = [[TXVideoEditer alloc] initWithPreview:param];
    [_editor setVideoPath:mp4Path];
    _editor.previewDelegate = self;
    
    // 录像参数初始化
    _recorder = [TXUGCRecord shareInstance];
    TXUGCCustomConfig *recordConfig = [[TXUGCCustomConfig alloc] init];
    recordConfig.videoResolution = VIDEO_RESOLUTION_720_1280;
    //这里保证录制视频的帧率和合唱视频的帧率一致，否则可能出现音画不同步的现象
    //注意：这里获取的合唱视频的帧率是平均帧率，有可能为小数，做一下四舍五入操作
    recordConfig.videoFPS = (int)(_videoInfo.fps + 0.5);
    //这里保证录制视频的音频采样率和合唱视频的音频采样率一致，否则可能出现音画不同步的现象
    recordConfig.audioSampleRate = audioSampleRate;
    recordConfig.videoBitratePIN = 9600;
    recordConfig.maxDuration = _videoInfo.duration;
    _recorder.recordDelegate = self;
    
    // 启动相机预览
    [_recorder startCameraCustom:recordConfig preview:self.cameraView];
    
    // 视频拼接
    _joiner = [[TXVideoJoiner alloc] initWithPreview:nil];
    _joiner.joinerDelegate = self;
    [_joiner setVideoPathList:@[_recordPath, mp4Path]];
}

- (IBAction)onTapButton:(UIButton *)sender {
    int ret = [_recorder startRecord:_recordPath coverPath:[_recordPath stringByAppendingString:@".png"]];
    if (ret != 0) {
        NSLog(@"相机启动失败, 错误码: %d", ret);
    } else {
        [_editor startPlayFromTime:0 toTime:_videoInfo.duration];
        [sender setTitle:@"录像中" forState:UIControlStateNormal];
        sender.enabled = NO;
    }
}

#pragma mark TXVideoPreviewListener
-(void) onPreviewProgress:(CGFloat)time
{
    self.progressView.progress = time / _videoInfo.duration;    
}

#pragma mark TXUGCRecordListener
-(void)onRecordComplete:(TXUGCRecordResult*)result;
{
    NSLog(@"录制完成，开始合成");
    [self.recordButton setTitle:@"合成中..." forState:UIControlStateNormal];
    
    //获取录制视频的宽高
    TXVideoInfo *videoInfo = [TXVideoInfoReader getVideoInfo:_recordPath];
    CGFloat width = videoInfo.width;
    CGFloat height = videoInfo.height;
    
    //录制视频和原视频左右排列
    CGRect recordScreen = CGRectMake(0, 0, width, height);
    CGRect playScreen = CGRectMake(width, 0, width, height);
    [_joiner setSplitScreenList:@[[NSValue valueWithCGRect:recordScreen],[NSValue valueWithCGRect:playScreen]] canvasWidth:width * 2 canvasHeight:height];
    [_joiner splitJoinVideo:VIDEO_COMPRESSED_720P videoOutputPath:_resultPath];
}

#pragma mark TXVideoJoinerListener
-(void) onJoinProgress:(float)progress
{
    NSLog(@"视频合成中%d%%",(int)(progress * 100));
    self.progressView.progress = progress;
}

-(void) onJoinComplete:(TXJoinerResult *)result
{
    NSLog(@"视频合成完毕");
    [_recorder stopCameraPreview];
    VideoPreviewController *controller = [[VideoPreviewController alloc] initWithVideoPath:_resultPath];
    [self.navigationController pushViewController:controller animated:YES];
}

@end
