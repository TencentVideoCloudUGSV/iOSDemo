//
//  ViewController.m
//  UGCDemo
//
//  Created by shengcui on 2018/9/30.
//  Copyright © 2018 Tencent. All rights reserved.
//

#import "ViewController.h"
#import "QBImagePickerController.h"
#import "VideoRecordConfigViewController.h"
#import "VideoRecordViewController.h"
#import "VideoEditViewController.h"
#import "VideoJoinerController.h"
#import "VideoPreviewViewController.h"
#import "VideoLoadingController.h"

@import TXLiteAVSDK_UGC;

@interface ViewController () <QBImagePickerControllerDelegate>
{
    ComposeMode _composeMode;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor grayColor];
    
    UIButton *recordButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [recordButton setTitle:@"录制" forState:UIControlStateNormal];
    [recordButton addTarget:self action:@selector(onRecord:) forControlEvents:UIControlEventTouchUpInside];
    [recordButton sizeToFit];
    
    UIButton *editButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [editButton setTitle:@"编辑" forState:UIControlStateNormal];
    [editButton addTarget:self action:@selector(onEdit:) forControlEvents:UIControlEventTouchUpInside];
    [editButton sizeToFit];
    
    UIButton *joinButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [joinButton setTitle:@"拼接" forState:UIControlStateNormal];
    [joinButton addTarget:self action:@selector(onJoin:) forControlEvents:UIControlEventTouchUpInside];
    [joinButton sizeToFit];
    
    CGPoint center = CGPointMake(CGRectGetMidX(self.view.bounds), 150);
    recordButton.center = center;
    
    center.y += 80;
    editButton.center = center;
    
    center.y += 80;
    joinButton.center = center;
    
    for (UIButton *button in @[recordButton, editButton, joinButton]) {
        [self.view addSubview:button];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = NO;
}

// 选则视频并进入编辑
- (void)onEdit:(id)sender {
    QBImagePickerController *videoPicker = [[QBImagePickerController alloc] init];
    videoPicker.delegate = self;
    videoPicker.mediaType = QBImagePickerMediaTypeVideo;
    _composeMode = ComposeMode_Edit;
    [self presentViewController:videoPicker animated:YES completion:nil];
}

- (void)onRecord:(id)sender {
    // 实例化录制设置界面
    VideoRecordConfigViewController *configViewController = [[VideoRecordConfigViewController alloc] init];
    
    __weak VideoRecordConfigViewController *weakConfigVC = configViewController;
    // 设置界面中点击开始录制的回调
    configViewController.onTapStart = ^(VideoRecordConfig *configure) {
        VideoRecordViewController *recordVC = [[VideoRecordViewController alloc] initWithConfigure:configure];
        
        // 设置录制完成回调
        recordVC.onRecordCompleted = ^(TXUGCRecordResult *result) {
            
            // 实例化预览视图控制器
            VideoPreviewViewController* previewController = [[VideoPreviewViewController alloc] initWithCoverImage:result.coverImage videoPath:result.videoPath renderMode:RENDER_MODE_FILL_EDGE showEditButton:YES];
            
            // 设置预览界面点击编辑回调
            previewController.onTapEdit = ^(VideoPreviewViewController *previewVC){
                // 实例化编辑视图控制器
                VideoEditViewController *editVC = [[VideoEditViewController alloc] init];
                // 设置要编辑的视频路径
                [editVC setVideoPath:result.videoPath];
                
                // 推入界面
                [previewVC.navigationController pushViewController:editVC animated:YES];
            };
            
            UINavigationController* nav = [[UINavigationController alloc] initWithRootViewController:previewController];
            [weakConfigVC.navigationController presentViewController:nav animated:YES completion:nil];
        };
        [weakConfigVC.navigationController pushViewController:recordVC animated:YES];
    };
    self.navigationController.navigationBar.hidden = YES;
    [self.navigationController pushViewController:configViewController animated:YES];
}

// 选则视频并进入拼接
- (void)onJoin:(id)sender {
    QBImagePickerController *videoPicker = [[QBImagePickerController alloc] init];
    videoPicker.delegate = self;
    videoPicker.allowsMultipleSelection = YES;
    videoPicker.mediaType = QBImagePickerMediaTypeVideo;
    _composeMode = ComposeMode_Join;
    [self presentViewController:videoPicker animated:YES completion:nil];        
}

- (void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didFinishPickingAssets:(NSArray *)assets {
    VideoLoadingController *loadvc = [[VideoLoadingController alloc] init];
    loadvc.composeMode = _composeMode;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:loadvc];
    [self dismissViewControllerAnimated:YES completion:^{
        [self presentViewController:nav animated:YES completion:nil];        
        [loadvc exportAssetList:assets assetType: AssetType_Video];
    }];
}
@end
