//  ArkoDigitalSign.h
//  数字签名桥接：用 macOS Security framework（CMS）实现 IPDF_DigitalSignCallback，
//  调用 ArkoPDFCore 的 DoDigitaSign 完成 PDF 数字签名。

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Security/Security.h>

@class ArkoDocument;

NS_ASSUME_NONNULL_BEGIN

@interface ArkoDigitalSign : NSObject

/// 用签名身份对文档某页的矩形区域做数字签名（adbe.pkcs7.detached），输出到 url。
/// identity 为 SecIdentityRef（Keychain 身份 / 导入的 .p12 / 自签名证书）。
- (BOOL)signDocument:(ArkoDocument *)document
            pageIndex:(NSInteger)pageIndex
                 rect:(CGRect)rect
             identity:(SecIdentityRef)identity
                 name:(NSString *)name
               reason:(NSString *)reason
             location:(NSString *)location
                 toURL:(NSURL *)url
                error:(NSError **)error
    NS_SWIFT_NAME(sign(document:pageIndex:rect:identity:name:reason:location:to:));

@end

NS_ASSUME_NONNULL_END
