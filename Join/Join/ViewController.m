//
//  ViewController.m
//  Join
//
//  Created by shengcui on 2018/9/29.
//  Copyright © 2018 Tencent. All rights reserved.
//

#import "ViewController.h"
#import "VideoPreviewViewController.h"
@import TXLiteAVSDK_UGC;

@interface ViewController () <TXVideoJoinerListener>
{
    TXVideoJoiner *_joiner;
    NSString *_output;
}
@property (weak, nonatomic) IBOutlet UIView *previewView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIButton *generateButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 输入视频
    NSString *path0 = [[NSBundle mainBundle] pathForResource:@"sample" ofType:@"mp4"];
    NSString *path1 = [[NSBundle mainBundle] pathForResource:@"cloud_ad" ofType:@"mp4"];
    AVAsset *asset0 = [AVAsset assetWithURL:[NSURL fileURLWithPath:path0]];
    AVAsset *asset1 = [AVAsset assetWithURL:[NSURL fileURLWithPath:path1]];
    
    // 输出路径
    _output = [NSTemporaryDirectory() stringByAppendingPathComponent:@"temp.mp4"];
    
    // 预览参数
    TXPreviewParam *param = [[TXPreviewParam alloc] init];
    param.videoView = self.previewView;
    param.renderMode = RENDER_MODE_FILL_SCREEN;
    
    // 创建视频拼接对象
    _joiner = [[TXVideoJoiner alloc] initWithPreview:param];

    // 传入待合成视频
    [_joiner setVideoAssetList:@[asset0, asset1]];

    // 开始预览
    [_joiner startPlay];    
}

- (IBAction)onJoin:(UIButton *)sender {
    // 点击生成
    self.generateButton.enabled = NO;
    
    [_joiner pausePlay];
    _joiner.joinerDelegate = self;
    [_joiner joinVideo:VIDEO_COMPRESSED_720P videoOutputPath:_output];
}

- (void)onJoinProgress:(float)progress
{
    // 生成进度
    self.progressView.progress = progress;
}

- (void)onJoinComplete:(TXJoinerResult *)result
{
    // 生成完毕
    self.generateButton.enabled = YES;
    if (result.retCode == 0) {
        VideoPreviewViewController *preview = [[VideoPreviewViewController alloc]
                                               initWithCoverImage:nil 
                                               videoPath:_output
                                               renderMode:RENDER_MODE_FILL_SCREEN 
                                               showEditButton:NO];
        [self presentViewController:preview animated:YES completion:nil];
    } else {
        NSLog(@"合成失败: %d %@", (int) result.retCode, result.descMsg);
    }
}
@end
