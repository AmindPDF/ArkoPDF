//  ArkoDigitalSign.mm
//  数字签名桥接：用 macOS Security framework（CMSEncoder）实现 IPDF_DigitalSignCallback。

#import "ArkoDigitalSign.h"
#import "ArkoDocument.h"
#import "ArkoPage.h"
#include "ipdf_sign.h"
#include "ipdf_document.h"
#include "ipdf_page.h"
#include <string>

// NSString → std::wstring（macOS wchar_t 为 32 位，BMP 字符直接取 UTF-16 码元）
static std::wstring _NSStringToWide(NSString *s) {
    if (!s) return std::wstring();
    NSUInteger len = s.length;
    std::wstring w(len, 0);
    for (NSUInteger i = 0; i < len; i++) {
        w[i] = (wchar_t)[s characterAtIndex:i];
    }
    return w;
}

// ============ macOS CMS 签名回调（实现 IPDF_DigitalSignCallback） ============

class ArkoCMSDigitalSignCallback : public IPDF_DigitalSignCallback {
public:
    SecIdentityRef identity;

    ArkoCMSDigitalSignCallback(SecIdentityRef id) : identity(id) {
        if (identity) CFRetain(identity);
    }
    ~ArkoCMSDigitalSignCallback() {
        if (identity) CFRelease(identity);
    }

    /// 估算 PKCS#7 签名长度（字节）。这里给一个宽松的固定值；实际长度通常更小。
    unsigned int EstimateSignedMessageLength(unsigned char* buf_data, unsigned long data_size) override {
        return 4096;
    }

    /// 用 SecIdentity 对数据做 RSA PKCS#7（detached）签名。
    int EncodeSignedData(int nDigestAlg, unsigned char *pData2BSigned, unsigned long ulData2BSignedLen,
                         unsigned char **ppSignedData, unsigned long *pSignedDataLen,
                         bool bIsContentDetached) override {
        if (identity == NULL || ppSignedData == NULL || pSignedDataLen == NULL) return 1;

        CMSEncoderRef encoder = NULL;
        if (CMSEncoderCreate(&encoder) != noErr) return 1;

        CFStringRef digest = (nDigestAlg == 7) ? kCMSEncoderDigestAlgorithmSHA256 : kCMSEncoderDigestAlgorithmSHA1;
        CMSEncoderSetSignerAlgorithm(encoder, digest);
        CMSEncoderSetHasDetachedContent(encoder, bIsContentDetached);
        CMSEncoderAddSigners(encoder, identity);

        if (CMSEncoderUpdateContent(encoder, pData2BSigned, ulData2BSignedLen) != noErr) {
            CFRelease(encoder);
            return 1;
        }

        CFDataRef encoded = NULL;
        if (CMSEncoderCopyEncodedContent(encoder, &encoded) != noErr || encoded == NULL) {
            CFRelease(encoder);
            return 1;
        }
        CFRelease(encoder);

        unsigned long len = (unsigned long)CFDataGetLength(encoded);
        *ppSignedData = (unsigned char *)malloc(len);
        if (*ppSignedData == NULL) {
            CFRelease(encoded);
            return 1;
        }
        memcpy(*ppSignedData, CFDataGetBytePtr(encoded), len);
        *pSignedDataLen = len;
        CFRelease(encoded);
        return 0;
    }
};

// ============ 桥接实现 ============

@implementation ArkoDigitalSign

- (BOOL)signDocument:(ArkoDocument *)document
            pageIndex:(NSInteger)pageIndex
                 rect:(CGRect)rect
             identity:(SecIdentityRef)identity
                 name:(NSString *)name
               reason:(NSString *)reason
             location:(NSString *)location
             logoPath:(NSString *)logoPath
                   mdp:(int)mdp
              opacity:(float)opacity
                 toURL:(NSURL *)url
                error:(NSError **)error {
    ArkoPage *page = [document pageAtIndex:pageIndex];
    if (!page) {
        if (error) *error = [NSError errorWithDomain:@"ArkoPDF.Sign" code:-1
                                            userInfo:@{NSLocalizedDescriptionKey: @"页面不存在"}];
        return NO;
    }

    IPDF_Signer *signer = PDSDK_CreateSigner();
    if (!signer) {
        if (error) *error = [NSError errorWithDomain:@"ArkoPDF.Sign" code:-2
                                            userInfo:@{NSLocalizedDescriptionKey: @"PDSDK_CreateSigner 失败"}];
        return NO;
    }

    std::wstring wsName = _NSStringToWide(name);
    std::wstring wsReason = _NSStringToWide(reason);
    std::wstring wsLocation = _NSStringToWide(location);
    std::wstring wsLogo = _NSStringToWide(logoPath);
    std::wstring wsPath = _NSStringToWide([url path]);

    signer->SetDigtialSignInfo(wsName.c_str(), wsLocation.c_str(), L"",
                               wsLogo.c_str(), L"", wsReason.c_str(), L"");

    // 外观：不透明度 / 名称样式（带 Logo 图片）
    signer->SetSignerImageOpacity(opacity);
    if (logoPath.length > 0) {
        signer->SetDigitalSignNameStyle(SIGN_NAME_SHOW_IMAGE);
    } else {
        signer->SetDigitalSignNameStyle(SIGN_NAME_SHOW_COMMONNAME);
    }
    signer->SetDigitalSignShowDetailLabel(TRUE);

    // MDP：锁定文档
    signer->SetDigitalSignMDP(mdp);

    ArkoCMSDigitalSignCallback callback(identity);
    signer->SetDigitalSignCallback(&callback);

    PDSDK_FloatRect rc;
    rc.left = (float)CGRectGetMinX(rect);
    rc.bottom = (float)CGRectGetMinY(rect);
    rc.right = (float)CGRectGetMaxX(rect);
    rc.top = (float)CGRectGetMaxY(rect);

    int ret = signer->DoDigitaSign((IPDF_Page *)[page sdkPage], rc, wsPath.c_str());
    signer->Release();

    if (ret != 0) {
        if (error) *error = [NSError errorWithDomain:@"ArkoPDF.Sign" code:ret
                                            userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"签名失败（code=%d）", ret]}];
        return NO;
    }
    return YES;
}

@end
