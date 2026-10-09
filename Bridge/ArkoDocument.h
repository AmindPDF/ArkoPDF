//  ArkoDocument.h
//  封装 IPDF_Document：打开 / 关闭 / 页数 / 取页 / 保存。

#import <Foundation/Foundation.h>

@class ArkoPage;

NS_ASSUME_NONNULL_BEGIN

@interface ArkoDocument : NSObject

- (nullable instancetype)initWithURL:(NSURL *)url error:(NSError **)error;
- (NSInteger)pageCount;
- (nullable ArkoPage *)pageAtIndex:(NSInteger)index;
- (BOOL)saveToURL:(NSURL *)url error:(NSError **)error;
- (void)close;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
