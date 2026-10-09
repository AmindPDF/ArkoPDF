//  ArkoDocument.h
//  封装 IPDF_Document：打开 / 关闭 / 页数 / 取页 / 保存。

#import <Foundation/Foundation.h>

@class ArkoPage;

NS_ASSUME_NONNULL_BEGIN

@interface ArkoDocument : NSObject

- (nullable instancetype)initWithURL:(NSURL *)url error:(NSError **)error;
@property (nonatomic, readonly) NSInteger pageCount;
- (nullable ArkoPage *)pageAtIndex:(NSInteger)index;
- (BOOL)saveToURL:(NSURL *)url error:(NSError **)error;
- (void)close;

// 页面组织（PPO）：每次操作后内部会重建页缓存，调用方需同步刷新 pageCount/currentPage
- (void)insertBlankPageAt:(NSInteger)index width:(CGFloat)width height:(CGFloat)height;
- (void)deletePagesFrom:(NSInteger)start count:(NSInteger)count;
- (void)swapPage:(NSInteger)page1 with:(NSInteger)page2;
- (void)rotatePageClockwise90:(NSInteger)index;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
