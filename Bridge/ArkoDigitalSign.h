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
/// identity 为 SecIdentityRef；mdp 为 DocMDP 权限（0=不锁定，1=锁定文档）；
/// opacity 为外观不透明度（0.0~1.0）；logoPath 可为 nil。
- (BOOL)signDocument:(ArkoDocument *)document
            pageIndex:(NSInteger)pageIndex
                 rect:(CGRect)rect
             identity:(SecIdentityRef)identity
                 name:(NSString *)name
               reason:(NSString *)reason
             location:(NSString *)location
             logoPath:(nullable NSString *)logoPath
                   mdp:(int)mdp
              opacity:(float)opacity
                 toURL:(NSURL *)url
                error:(NSError **)error
    NS_SWIFT_NAME(sign(document:pageIndex:rect:identity:name:reason:location:logoPath:mdp:opacity:to:));

@end

NS_ASSUME_NONNULL_END
