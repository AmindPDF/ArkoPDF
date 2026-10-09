//  ArkoSDK.h
//  封装 PDSDK 的加载 / 卸载。App 启动时加载一次。

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ArkoSDK : NSObject

/// 加载 SDK（对应 C++ 的 PDF_LoadSDK）。幂等。
+ (BOOL)loadWithLicense:(NSString *)license error:(NSError **)error;

/// 卸载 SDK（对应 PDF_UnLoadSDK）。
+ (void)unload;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
