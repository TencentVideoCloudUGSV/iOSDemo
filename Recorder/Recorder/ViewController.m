//
//  ViewController.m
//  Recorder
//
//  Created by shengcui on 2018/9/28.
//  Copyright © 2018 Tencent. All rights reserved.
//

#import "ViewController.h"
#import "Preview/VideoPreviewViewController.h"

@import TXLiteAVSDK_UGC;

static const float MaxDuration = 15.0f;

@interface ViewController () <TXUGCRecordListener>
{

}
@property (weak, nonatomic) IBOutlet UIView *previewView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
// 在StoryBoard上设置了按钮在`Selected`状态下的title为结束　
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // 界面显示出来时打开相机预览
    TXUGCSimpleConfig *config = [[TXUGCSimpleConfig alloc] init];
    config.videoQuality = VIDEO_QUALITY_HIGH;
    config.maxDuration = MaxDuration;
    [TXUGCRecord.shareInstance startCameraSimple:config preview:self.previewView];
    
    // 设置录制效果, 以美颜和滤镜为例
    // 美颜
    [TXUGCRecord.shareInstance setBeautyStyle:VIDOE_BEAUTY_STYLE_NATURE beautyLevel:0.5 whitenessLevel:0.5 ruddinessLevel:0.5];

    // 关闭美颜
    // [TXUGCRecord.shareInstance setBeautyStyle:VIDOE_BEAUTY_STYLE_NATURE beautyLevel:0 whitenessLevel:0.5 ruddinessLevel:0.5];

    // 滤镜
    NSString *filterPath = [[[NSBundle mainBundle] pathForResource:@"FilterResource" ofType:@"bundle"] stringByAppendingPathComponent:@"normal.png"];
    [TXUGCRecord.shareInstance setFilter:[UIImage imageWithContentsOfFile: filterPath]];    
}

- (BOOL)startRecord {
    // 开始录制，设置self来监听录制事件　
    TXUGCRecord.shareInstance.recordDelegate = self;
    int ret = [TXUGCRecord.shareInstance startRecord];
    if (ret != 0) {
        NSString *errorMessage = nil;
        switch (ret) {
            case -1:
                errorMessage = @"正在录制视频";
                break;
            case -2:
                errorMessage = @"初始化错误，请检查初始化参数";
                break;
            case -3:
                errorMessage = @"开启摄像头失败";
                break;
            case -4:
                errorMessage = @"licence校验失败";
                break;
            default:
                break;
        }
        NSLog(@"启动录制错误 (%d) %@",  ret, errorMessage);
    }
    return ret == 0;
}

- (BOOL)stopRecord {
    // SDK保存好录制文件后会回调 onRecordComplete:　 
    int ret = [TXUGCRecord.shareInstance stopRecord];
    if (ret != 0) {
        NSString *errorMessage = nil;
        if (ret == -1) {
            errorMessage = @"录制未开始";
        } else if (ret == -2) {
            errorMessage = @"初始化错误，请检查初始化参数";
        }
        NSLog(@"停止录制错误 (%d) %@",  ret, errorMessage);
    }
    return ret == 0;
}

- (IBAction)onTapRecord:(UIButton *)button {
    BOOL success = NO;
    if (button.selected) {
        // 已经开始录制，结束录制
        success = [self stopRecord];
    } else {
        // 开始录制
        success = [self startRecord];
    }
    if (success) {
        // 操作成功，切换录制按钮状态
        button.selected = !button.selected;
    }
}

- (IBAction)onDeleteLastPart:(UIButton *)sender {
    [TXUGCRecord.shareInstance.partsManager deleteLastPart];
}

#pragma mark - TXUGCRecordListener
// 进度回调
- (void)onRecordProgress:(NSInteger)milliSecond {

    self.progressView.progress = milliSecond / 1000.0 / MaxDuration;
}

// 录制完成回调
- (void)onRecordComplete:(TXUGCRecordResult *)result {
    // 恢复UI状态
    self.recordButton.selected = NO;
    self.progressView.progress = 0.0;
    
    // 停止相机预览, 也可以根据实际情况在开始上传等确认不再使用相机的场景下关闭，以避免回到录制界面后预览画面会闪一下的情况　　　　　
    [TXUGCRecord.shareInstance stopCameraPreview];
    // 删除片段, 否则相册会之前的录制片段继续录制　　
    [TXUGCRecord.shareInstance.partsManager deleteAllParts];
    // 预览录制的视频　
    VideoPreviewViewController *preview = [[VideoPreviewViewController alloc]
                                           initWithCoverImage:result.coverImage 
                                           videoPath:result.videoPath
                                           renderMode:RENDER_MODE_FILL_SCREEN 
                                           showEditButton:NO];
    [self presentViewController:preview animated:YES completion:nil];
}

@end
