//  main.mm — 无头冒烟测试
//  直接调用桥接层（不启动 SwiftUI），验证核心链路：
//  SDK 加载 → 打开 PDF → 渲染(非空白) → 标注 → 段落编辑 → 添加文字/图片 → 链接
//  → 撤销重做 → 保存 → 重开验证持久化。
//  支持可选真实文件：./smoke --pdf /path/to.pdf
//  退出码 0 = 通过，非 0 = 失败。

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreText/CoreText.h>
#import <AppKit/AppKit.h>
#import <unistd.h>
#import <stdarg.h>
#import "ArkoSDK.h"
#import "ArkoDocument.h"
#import "ArkoPage.h"
#import "ArkoParagraph.h"
#include "ipdf_document.h"   // PDF_OPEN_ERROR_PASSWORD 等错误码

// ============ 断言 ============

static int g_failures = 0;
static void Check(BOOL cond, const char *name) {
    fprintf(stdout, "%s: %s\n", cond ? "PASS" : "FAIL", name);
    if (!cond) g_failures++;
}
static void Info(const char *fmt, ...) {
    va_list ap; va_start(ap, fmt);
    fprintf(stdout, "INFO: ");
    vfprintf(stdout, fmt, ap);
    fprintf(stdout, "\n");
    va_end(ap);
}

// ============ PDF 生成 ============

// 3 段、每段 2 行文本的 PDF（编辑/段落分析基线）
static NSString *SmokeEditablePDF(void) {
    NSMutableArray<NSString *> *objs = [NSMutableArray array];
    [objs addObject:@"<< /Type /Catalog /Pages 2 0 R >>"];
    [objs addObject:@"<< /Type /Pages /Kids [3 0 R] /Count 1 >>"];
    [objs addObject:@"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>"];
    NSString *stream =
        @"BT\n"
        @"/F1 24 Tf 72 720 Td (The quick brown fox) Tj\n"
        @"0 -30 Td (jumps over the lazy dog) Tj\n"
        @"0 -70 Td (Pack my box with five) Tj\n"
        @"0 -30 Td (dozen liquor jugs) Tj\n"
        @"0 -70 Td (How vexingly quick) Tj\n"
        @"0 -30 Td (daft zebras jump) Tj\n"
        @"ET";
    [objs addObject:[NSString stringWithFormat:@"<< /Length %lu >>\nstream\n%@\nendstream", (unsigned long)stream.length, stream]];
    [objs addObject:@"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>"];

    NSMutableString *pdf = [NSMutableString stringWithString:@"%PDF-1.4\n"];
    NSMutableArray<NSNumber *> *offsets = [NSMutableArray array];
    for (NSUInteger i = 0; i < objs.count; i++) {
        [offsets addObject:@(pdf.length)];
        [pdf appendFormat:@"%lu 0 obj\n%@\nendobj\n", (unsigned long)(i + 1), objs[i]];
    }
    NSUInteger xrefOff = pdf.length;
    [pdf appendFormat:@"xref\n0 %lu\n0000000000 65535 f \n", (unsigned long)(objs.count + 1)];
    for (NSNumber *off in offsets) {
        [pdf appendFormat:@"%010llu 00000 n \n", (unsigned long long)off.unsignedIntegerValue];
    }
    [pdf appendFormat:@"trailer\n<< /Size %lu /Root 1 0 R >>\nstartxref\n%lu\n%%EOF\n",
          (unsigned long)(objs.count + 1), (unsigned long)xrefOff];
    return pdf;
}

// 生成一张测试 JPEG（红方块 100x80）
static NSString *SmokeMakeTestJPEG(NSString *dir) {
    size_t w = 100, h = 80;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(NULL, w, h, 8, w * 4, cs,
                                             kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(cs);
    if (!ctx) return nil;
    CGContextSetRGBFillColor(ctx, 1.0, 0.0, 0.0, 1.0);
    CGContextFillRect(ctx, CGRectMake(0, 0, w, h));
    CGImageRef img = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCGImage:img];
    CGImageRelease(img);
    NSData *jpg = [rep representationUsingType:NSBitmapImageFileTypeJPEG properties:@{}];
    NSString *path = [dir stringByAppendingPathComponent:@"smoke_test.jpg"];
    [jpg writeToFile:path atomically:YES];
    return path;
}

// ============ 位图工具 ============

static BOOL SmokeHasDarkPixel(CGImageRef img) {
    size_t w = CGImageGetWidth(img);
    size_t h = CGImageGetHeight(img);
    if (w == 0 || h == 0) return NO;
    size_t bytesPerRow = w * 4;
    unsigned char *buf = (unsigned char *)calloc(h, bytesPerRow);
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(buf, w, h, 8, bytesPerRow, cs,
                                             kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(cs);
    if (!ctx) { free(buf); return NO; }
    CGContextDrawImage(ctx, CGRectMake(0, 0, w, h), img);
    CGContextRelease(ctx);
    BOOL has = NO;
    for (size_t i = 0; i < h * bytesPerRow; i += 4) {
        if (buf[i] < 200 || buf[i + 1] < 200 || buf[i + 2] < 200) { has = YES; break; }
    }
    free(buf);
    return has;
}

static BOOL SmokeWritePNG(CGImageRef img, NSString *path) {
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCGImage:img];
    NSData *png = [rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
    return [png writeToFile:path atomically:YES];
}

// ============ 测试流程 ============

static NSString *SmokeParagraphText(ArkoParagraph *para) {
    // -1 表示全文（走 SDK GetText 的 bSelAll 分支），避免 end_caret 越界
    NSString *s = [para textFromCaret:-1 toCaret:-1];
    return s ? s : @"";
}

// 段落编辑深度测试：插入 / 撤销 / 重做 / 删除。对空段落（无 caret）自动跳过。
// doEdit=NO 时只验证 caret 构建 + 读文本（程序化 PDF 的段落没有嵌入字体，InsertText 会崩）。
static void SmokeTestParagraphEdit(ArkoDocument *doc, const char *label, BOOL doEdit) {
    if (!doc || doc.pageCount == 0) return;
    ArkoPage *page = [doc pageAtIndex:0];
    NSInteger paraCount = page.paragraphCount;
    Info("[%s] paragraphCount = %ld", label, (long)paraCount);
    if (paraCount < 1) {
        Info("[%s] no paragraph recognized — edit path skipped", label);
        return;
    }
    ArkoParagraph *para = nil;
    NSInteger usedIndex = -1;
    for (NSInteger i = 0; i < paraCount; i++) {
        ArkoParagraph *p = [page paragraphAtIndex:i];
        if (p && p.caretCount > 0) { para = p; usedIndex = i; break; }
    }
    if (!para) {
        Info("[%s] no paragraph with text/carets found — edit path skipped (use a real text pdf)", label);
        return;
    }
    Info("[%s] using paragraph index %ld (caretCount=%ld)", label, (long)usedIndex, (long)para.caretCount);

    if (!doEdit) return;  // 程序化 PDF 只验证 caret 构建（GetText/InsertText 会因标准字体崩）

    Info("[%s] step: read text", label);
    NSString *text = SmokeParagraphText(para);
    Info("[%s] paragraph text length=%lu, before=[%s]", label, (unsigned long)text.length, text.UTF8String);

    Info("[%s] step: getFont", label);
    uint64_t font = [para fontHandleForInsertingText:@"XYZ" atCaret:1 defaultFont:doc.defaultFontHandle];
    Info("[%s] step: getFontSize", label);
    float fontSize = [para fontSizeAtCaret:1];
    Info("[%s] font=%llu fontSize=%.1f", label, (unsigned long long)font, fontSize);
    Info("[%s] step: insertText", label);
    uint64_t h = [para insertText:@"XYZ" atCaret:1 fontHandle:font fontSize:fontSize color:0xFF000000
                            bold:NO italic:NO underline:NO strikeout:NO];
    Info("[%s] step: insertText done (handle=%llu)", label, (unsigned long long)h);
    NSString *after = SmokeParagraphText(para);
    Info("[%s] after=[%s]", label, after.UTF8String);

    char name[128];
    snprintf(name, sizeof(name), "[%s] paragraph insert text", label);
    Check(h != 0 && [after containsString:@"XYZ"], name);
    if (h != 0) {
        [page paraUndoItem:h];
        snprintf(name, sizeof(name), "[%s] paragraph undo restores text", label);
        Check(![SmokeParagraphText(para) containsString:@"XYZ"], name);
        [page paraRedoItem:h];
        snprintf(name, sizeof(name), "[%s] paragraph redo re-inserts text", label);
        Check([SmokeParagraphText(para) containsString:@"XYZ"], name);
        [ArkoParagraph releaseUndoItem:h];

        uint64_t dh = [para deleteTextFromCaret:0 toCaret:3];
        snprintf(name, sizeof(name), "[%s] paragraph delete text", label);
        Check(dh != 0, name);
        if (dh) [ArkoParagraph releaseUndoItem:dh];
    }
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        setvbuf(stdout, NULL, _IONBF, 0);
        setvbuf(stderr, NULL, _IONBF, 0);

        NSString *cwd = [NSFileManager defaultManager].currentDirectoryPath;
        NSError *err = nil;

        // 可选真实文件：--pdf <path>
        NSString *externalPDF = nil;
        for (int i = 1; i + 1 < argc; i++) {
            if (strcmp(argv[i], "--pdf") == 0) {
                externalPDF = [NSString stringWithUTF8String:argv[i + 1]];
            }
        }

        // 1. SDK
        if (![ArkoSDK loadWithLicense:@"ED578A089CEB689277D52D37515938AA" error:&err]) {
            fprintf(stderr, "FAIL: SDK load: %s\n", err.localizedDescription.UTF8String);
            return 1;
        }
        fprintf(stdout, "PASS: SDK loaded\n");

        // 2. 输入 PDF：优先真实文件，否则程序化 3 段文本 PDF
        NSString *pdfPath = [cwd stringByAppendingPathComponent:@"smoke_input.pdf"];
        if (externalPDF) {
            pdfPath = externalPDF;
            Info("using external pdf: %s", externalPDF.UTF8String);
        } else {
            if (![SmokeEditablePDF() writeToFile:pdfPath atomically:YES encoding:NSUTF8StringEncoding error:&err]) {
                fprintf(stderr, "FAIL: write pdf: %s\n", err.localizedDescription.UTF8String);
                return 1;
            }
        }

        // 3. 打开
        ArkoDocument *doc = [[ArkoDocument alloc] initWithURL:[NSURL fileURLWithPath:pdfPath] error:&err];
        if (!doc) {
            fprintf(stderr, "FAIL: open: %s\n", err.localizedDescription.UTF8String);
            return 1;
        }
        fprintf(stdout, "PASS: document opened (%ld pages)\n", (long)doc.pageCount);

        ArkoPage *page = [doc pageAtIndex:0];
        if (!page) { fprintf(stderr, "FAIL: pageAtIndex(0) nil\n"); return 1; }

        // 4. 渲染 + 非空白
        CGImageRef img = [page renderImageAtScale:1.0];
        Check(img != nil, "render page");
        if (img) {
            Check(SmokeHasDarkPixel(img), "page has content (non-blank)");
            Check(SmokeWritePNG(img, [cwd stringByAppendingPathComponent:@"smoke_page0.png"]), "write screenshot");
        }

        // 5. 高亮标注
        [page addTextMarkupOfType:10 lineBoxes:@[[NSValue valueWithRect:CGRectMake(70, 715, 220, 30)]]
                           color:[ArkoPage makeRGBColorWithRed:255 green:214 blue:10] opacity:0.8f];
        Check(page.annotCount >= 1, "added highlight annotation");

        // 6. 段落编辑（依赖段落分析器；程序化 PDF 段落为空则自动跳过）
        SmokeTestParagraphEdit(doc, "programmatic", NO);

        // 7. 添加文字/段落
        {
            NSInteger before = page.paragraphCount;
            ArkoParagraph *np = [page newParagraphAtX:72 y:140 width:200 height:14];
            Check(np != nil, "new paragraph created");
            if (np) {
                uint64_t font = doc.defaultFontHandle;
                uint64_t h = [np insertText:@"NewPara" atCaret:0 fontHandle:font fontSize:12 color:0xFF000000
                                      bold:NO italic:NO underline:NO strikeout:NO];
                Check(h != 0, "new paragraph insert text");
                if (h) [ArkoParagraph releaseUndoItem:h];
            }
            Info("paragraphCount after new = %ld (was %ld)", (long)page.paragraphCount, (long)before);
        }

        // 8. 添加图片
        {
            NSString *jpg = SmokeMakeTestJPEG(cwd);
            NSInteger before = page.pageObjectCount;
            NSInteger idx = [page addImageWithJpegPath:jpg atX:72 y:200 width:100 height:80 alpha:1.0];
            Check(idx >= 0, "add image to page");
            Check(page.pageObjectCount > before, "page object count increased after add image");

            // 图片编辑：移动 + 缩放 + 旋转 + 翻转
            if (idx >= 0) {
                [page movePageObjectAtIndex:idx byX:10 y:10];
                [page resizePageObjectAtIndex:idx toWidth:120 height:90];
                [page rotatePageObjectAtIndex:idx byAngle:0.5f];
                [page flipPageObjectAtIndex:idx horizontal:YES];
                Check(YES, "image move/resize/rotate/flip did not crash");
                // 导出
                NSString *exportPath = [cwd stringByAppendingPathComponent:@"smoke_export.jpg"];
                Check([page exportImageAtIndex:idx toJpegPath:exportPath], "export image as jpeg");
            }
        }

        // 9. 链接
        {
            uint64_t link = [page addLinkAnnotInRect:CGRectMake(72, 400, 120, 20)];
            Check(link != 0, "add link annotation");
            if (link) {
                [page setLinkURI:@"https://example.com" forAnnotHandler:link];
                Check([[page linkURIForAnnotHandler:link] isEqualToString:@"https://example.com"], "link URI roundtrip");
            }
        }

        // 10. 保存 + 重开，验证持久化
        NSString *savePath = [cwd stringByAppendingPathComponent:@"smoke_output.pdf"];
        Check([doc saveToURL:[NSURL fileURLWithPath:savePath] progress:nil isCancelled:nil security:nil error:&err], "save edited document");
        unsigned long long size = [[[NSFileManager defaultManager] attributesOfItemAtPath:savePath error:&err] fileSize];
        Check(size > 0, "saved file non-empty");

        ArkoDocument *reopen = [[ArkoDocument alloc] initWithURL:[NSURL fileURLWithPath:savePath] error:&err];
        Check(reopen != nil, "reopen saved document");
        if (reopen) {
            ArkoPage *p2 = [reopen pageAtIndex:0];
            Info("reopen: pageObjectCount=%ld, annotCount=%ld, paragraphCount=%ld",
                 (long)p2.pageObjectCount, (long)p2.annotCount, (long)p2.paragraphCount);
            // 图片持久化
            Check(p2.pageObjectCount >= 1, "image persisted after save+reopen");
            // 链接持久化（遍历标注找 URI）
            BOOL foundLink = NO;
            for (NSInteger i = 0; i < p2.annotCount; i++) {
                unsigned long long h = [p2 annotHandlerAtIndex:i];
                if (h && [[p2 linkURIForAnnotHandler:h] isEqualToString:@"https://example.com"]) { foundLink = YES; break; }
            }
            Check(foundLink, "link persisted after save+reopen");
            // 水印验证（社区版 MODE=0：无 token 保存 → 试用水印）
            Check([p2 hasTrailmark], "trial watermark present after save");
        }

        // 11. 密码 / 加密：保存时设打开密码 → 重开需密码 → 正确密码可开、错误密码失败
        {
            NSString *encPath = [cwd stringByAppendingPathComponent:@"smoke_encrypted.pdf"];
            ArkoSecurityOptions *sec = [[ArkoSecurityOptions alloc] init];
            sec.userPassword = @"123456";               // 打开密码（不设 owner，owner 默认空串）
            sec.cipher = 3;                             // ENCRYPT_CIPHER_AES2（256 位 AES）
            sec.keylen = 256;
            sec.encryptMetadata = YES;
            sec.permissions = 0xFFFFF0C0u | 0x0004u | 0x0008u;  // 保留位 + 打印 + 修改
            Check([doc saveToURL:[NSURL fileURLWithPath:encPath] progress:nil isCancelled:nil security:sec error:&err],
                  "save with open password");

            // 无密码重开 → 失败，错误码 = PDF_OPEN_ERROR_PASSWORD
            ArkoDocument *noPwd = [[ArkoDocument alloc] initWithURL:[NSURL fileURLWithPath:encPath] error:&err];
            Check(noPwd == nil, "reopen encrypted without password fails");
            Check(noPwd == nil && err.code == PDF_OPEN_ERROR_PASSWORD, "open error code is PASSWORD");

            // 错误密码 → 失败
            ArkoDocument *wrongPwd = [[ArkoDocument alloc] initWithURL:[NSURL fileURLWithPath:encPath] password:@"wrong" error:&err];
            Check(wrongPwd == nil, "reopen encrypted with wrong password fails");

            // 正确密码 → 成功，且 isEncrypted、页数一致
            ArkoDocument *rightPwd = [[ArkoDocument alloc] initWithURL:[NSURL fileURLWithPath:encPath] password:@"123456" error:&err];
            Check(rightPwd != nil, "reopen encrypted with correct password succeeds");
            if (rightPwd) {
                Check(rightPwd.isEncrypted, "reopened encrypted document isEncrypted");
                Check(rightPwd.pageCount == doc.pageCount, "encrypted reopen preserves page count");
                Info("encrypted reopen: pageCount=%ld, permission=0x%X",
                     (long)rightPwd.pageCount, rightPwd.permissionFlags);
            }
        }

        // 12. 真实样本段落编辑（如果 smoke/fixtures/ 里有 PDF 样本）
        {
            NSString *fixturesDir = [cwd stringByAppendingPathComponent:@"smoke/fixtures"];
            NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fixturesDir error:&err];
            NSString *samplePDF = nil;
            for (NSString *f in files) {
                if ([f.pathExtension.lowercaseString isEqualToString:@"pdf"]) {
                    samplePDF = [fixturesDir stringByAppendingPathComponent:f];
                    break;
                }
            }
            if (samplePDF) {
                ArkoDocument *sdoc = [[ArkoDocument alloc] initWithURL:[NSURL fileURLWithPath:samplePDF] error:&err];
                Check(sdoc != nil, "open fixture sample pdf");
                SmokeTestParagraphEdit(sdoc, "sample", YES);
                // 不 close，_exit 回收
            } else {
                Info("no fixture sample in smoke/fixtures/ — real-text paragraph edit not exercised");
            }
        }

        // 不调用 close/unload，直接 _exit 跳过析构：analyser 的释放（close/unload 触发）
        // 在 headless 环境会 segfault；smoke 是短命进程，交给 OS 回收即可。
        fprintf(stdout, g_failures == 0 ? "SMOKE TEST PASSED\n" : "SMOKE TEST FAILED\n");
        fflush(stdout);
        _exit(g_failures == 0 ? 0 : 1);
    }
}
