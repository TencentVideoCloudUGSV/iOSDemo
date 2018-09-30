//
//  VideoPreviewController.m
//  Demo
//
//  Created by shengcui on 2018/7/13.
//  Copyright © 2018年 Company. All rights reserved.
//

#import "VideoPreviewController.h"
@import TXLiteAVSDK_UGC;

@interface VideoPreviewController () <TXVideoPreviewListener>
{
    TXVideoEditer *_editor;
}
@property (strong, nonatomic) NSString *videoPath;
@end

@implementation VideoPreviewController

- (instancetype)initWithVideoPath:(NSString *)path {
    if (self = [super initWithNibName:nil bundle:nil]) {
        self.videoPath = path;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    TXPreviewParam *param = [[TXPreviewParam alloc] init];
    param.videoView = self.view;
    param.renderMode = RENDER_MODE_FILL_EDGE;

    _editor = [[TXVideoEditer alloc] initWithPreview:param];
    _editor.previewDelegate = self;
    [_editor setVideoPath:self.videoPath];
    [_editor startPlayFromTime:0 toTime:[TXVideoInfoReader getVideoInfo:self.videoPath].duration];
}

-(void) onPreviewFinished
{
    [_editor startPlayFromTime:0 toTime:[TXVideoInfoReader getVideoInfo:self.videoPath].duration];
}


@end
