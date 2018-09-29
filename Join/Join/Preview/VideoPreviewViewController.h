#import <UIKit/UIKit.h>
@import TXLiteAVSDK_UGC;

/**
 *  短视频预览VC
 */
@interface VideoPreviewViewController : UIViewController
@property (copy, nonatomic) void(^onTapEdit)(VideoPreviewViewController *previewController);
@property (readonly, nonatomic) NSString *videoPath;

- (instancetype)initWithCoverImage:(UIImage *)coverImage
                         videoPath:(NSString*)videoPath
                        renderMode:(TX_Enum_Type_RenderMode)renderMode
                    showEditButton:(BOOL)showEditButton;
@end
