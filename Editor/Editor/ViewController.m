//
//  ViewController.m
//  Editor
//
//  Created by shengcui on 2018/9/28.
//  Copyright © 2018 Tencent. All rights reserved.
//

#import "ViewController.h"
@import TXLiteAVSDK_UGC;
#import "VideoPreviewViewController.h"

@interface ViewController () <TXVideoGenerateListener, TXVideoPreviewListener>
{
    TXVideoEditer *_editor;
    float _videoDuration;　
    NSString *_resultPath;
}
@property (weak, nonatomic) IBOutlet UIButton *generateButton;
@property (weak, nonatomic) IBOutlet UIView *previewView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // 配置预览参数　
    TXPreviewParam *param = [[TXPreviewParam alloc] init];
    param.renderMode = RENDER_MODE_FILL_SCREEN;
    param.videoView = self.previewView;
    
    // 实例化编辑器
    _editor = [[TXVideoEditer alloc]initWithPreview: param];
    
    // 设置视频路径
    NSString *path = [[NSBundle mainBundle] pathForResource:@"sample" ofType:@"mp4"];
    AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:path]];
    [_editor setVideoAsset:asset];
    
    // 获取视频时长并播放全部
    TXVideoInfo *info = [TXVideoInfoReader getVideoInfoWithAsset:asset];
    _videoDuration = info.duration;
    _editor.previewDelegate = self; // 获取播放回调
    [_editor startPlayFromTime:0 toTime:_videoDuration]; //开始播放
    
    // 增加效果
    
    // 前1/5时间设置镜像特效
    [_editor startEffect:TXEffectType_PHANTOM startTime:0];
    [_editor stopEffect:TXEffectType_PHANTOM endTime:_videoDuration * 0.2];
    
    // 增加贴纸
    TXAnimatedPaster *paster = [[TXAnimatedPaster alloc] init];
    NSString *pasterPath = [[[NSBundle mainBundle] pathForResource:@"AnimatedPaster" ofType:@"bundle"] stringByAppendingPathComponent:@"baiyang"];
    paster.animatedPasterpath = pasterPath;
    paster.frame = CGRectMake(50, 50, 100, 100);
    paster.startTime = _videoDuration * 0.1;
    paster.endTime = _videoDuration * 0.4;
    [_editor setAnimatedPasterList:@[paster]];
}

- (IBAction)onGenerate:(UIButton *)sender {
    [sender setTitle:@"生成中..." forState:UIControlStateNormal];
    sender.enabled = NO;
    [_editor pausePlay]; // 暂停预览, 这里主要目的是复用进度度显示生成进度，继续播放不影响生成　　　

    self.progressView.progress = 0;
    // 调用生成接口前要先设置生成时间的监听对象，也可以放到
    _editor.generateDelegate = self;  
    NSString *output = [NSTemporaryDirectory() stringByAppendingPathComponent:@"result.mp4"];
    _resultPath = output;
    // 开始生成
    [_editor generateVideo:VIDEO_COMPRESSED_720P videoOutputPath:output];
}

#pragma mark - TXVideoPreviewListener
- (void)onPreviewProgress:(CGFloat)time {
    self.progressView.progress = time/_videoDuration;   
}

- (void)onPreviewFinished
{
    // 重复播放
    [_editor startPlayFromTime:0 toTime:_videoDuration];
}
#pragma mark - TXVideoGenerateListener
- (void)onGenerateProgress:(float)progress {
    self.progressView.progress = progress;
}

- (void)onGenerateComplete:(TXGenerateResult *)result {
    // 恢复UI
    self.progressView.progress = 0;
    [self.generateButton setTitle:@"生成" forState:UIControlStateNormal];
    self.generateButton.enabled = YES;
    [_editor resumePlay];
    
    // 预览录制的视频　
    VideoPreviewViewController *preview = [[VideoPreviewViewController alloc]
                                           initWithCoverImage:nil 
                                           videoPath:_resultPath
                                           renderMode:RENDER_MODE_FILL_SCREEN 
                                           showEditButton:NO];
    [self presentViewController:preview animated:YES completion:nil];
}

@end
