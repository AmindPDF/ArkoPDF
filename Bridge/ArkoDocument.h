//  ArkoDocument.h
//  封装 IPDF_Document：打开 / 关闭 / 页数 / 取页 / 保存。

#import <Foundation/Foundation.h>

@class ArkoPage;
@class ArkoDocument;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ArkoPPOOperation) {
    ArkoPPOOperationInsertBlank,
    ArkoPPOOperationDeletePages,
    ArkoPPOOperationSwapPages,
    ArkoPPOOperationRotatePage,
};

/// PPO 操作通知：在页面操作前后回调，供其它模块释放/重建页引用、同步索引。
@protocol ArkoDocumentPPODelegate <NSObject>
@optional
/// 操作前：`pages` 为即将操作的页（操作前的索引）。
- (void)document:(ArkoDocument *)document willChangePages:(ArkoPPOOperation)operation pages:(NSArray<NSNumber *> *)pages;
/// 操作后：页索引已重排，调用方需重新读取 pageCount / 页面。
- (void)document:(ArkoDocument *)document didChangePages:(ArkoPPOOperation)operation;
@end

@interface ArkoDocument : NSObject

@property (nonatomic, weak, nullable) id<ArkoDocumentPPODelegate> ppoDelegate;

- (nullable instancetype)initWithURL:(NSURL *)url error:(NSError **)error;
@property (nonatomic, readonly) NSInteger pageCount;
- (nullable ArkoPage *)pageAtIndex:(NSInteger)index;
- (BOOL)saveToURL:(NSURL *)url error:(NSError **)error;
- (void)close;

// 页面组织（PPO）：每次操作前后会通过 ppoDelegate 发通知，内部重建页缓存
- (void)insertBlankPageAt:(NSInteger)index width:(CGFloat)width height:(CGFloat)height;
- (void)deletePagesFrom:(NSInteger)start count:(NSInteger)count;
- (void)swapPage:(NSInteger)page1 with:(NSInteger)page2;
- (void)rotatePageClockwise90:(NSInteger)index;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
