//  ArkoPhotoBook.h
//  PDF 相册排版：把照片按 cols×rows 网格排到纸张上生成 PDF（封装 IPDF_PhotoBookCreator）。

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ArkoPhotoBook : NSObject

/// 纸张尺寸（pt；1mm = 72/25.4 pt）。
- (void)setPaperWidth:(float)w height:(float)h NS_SWIFT_NAME(setPaperWidth(_:height:));
/// 布局（每页 cols 列 × rows 行）。
- (void)setLayoutCols:(int)cols rows:(int)rows NS_SWIFT_NAME(setLayoutCols(_:rows:));
/// 页边距（pt，水平/垂直）。
- (void)setMarginsHorizontal:(float)h vertical:(float)v NS_SWIFT_NAME(setMarginsHorizontal(_:vertical:));
/// 照片间距（pt，水平/垂直）。
- (void)setSpacingHorizontal:(float)h vertical:(float)v NS_SWIFT_NAME(setSpacingHorizontal(_:vertical:));
/// 照片格子宽高比（宽/高），如竖版 5/7。
- (void)setPhotoRatio:(float)ratio NS_SWIFT_NAME(setPhotoRatio(_:));

/// 添加一张照片（org 尺寸为原图像素，SDK 用于缩放到格子）。
- (void)addImageAtPath:(NSString *)path pixelWidth:(int)w pixelHeight:(int)h
    NS_SWIFT_NAME(addImage(atPath:pixelWidth:pixelHeight:));

/// 生成相册并保存到 url（内部 BuildPhotoBook + 保存）。失败填 error。
- (BOOL)buildAndSaveToURL:(NSURL *)url error:(NSError **)error NS_SWIFT_NAME(buildAndSave(to:));

@end

NS_ASSUME_NONNULL_END
