//  main.mm — 无头冒烟测试
//  直接调用桥接层（不启动 SwiftUI），验证核心链路：
//  SDK 加载 → 打开 PDF → 渲染页面(非空白) → 加高亮标注 → 保存 → 输出截图。
//  退出码 0 = 通过，非 0 = 失败。

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <AppKit/AppKit.h>
#import "ArkoSDK.h"
#import "ArkoDocument.h"
#import "ArkoPage.h"

static NSString *SmokeMinimalPDF(void) {
    // 一页、含 "Hello ArkoPDF" 文本的最小合法 PDF（含正确 xref）
    NSMutableArray<NSString *> *objs = [NSMutableArray array];
    [objs addObject:@"<< /Type /Catalog /Pages 2 0 R >>"];
    [objs addObject:@"<< /Type /Pages /Kids [3 0 R] /Count 1 >>"];
    [objs addObject:@"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>"];
    NSString *stream = @"BT /F1 24 Tf 72 720 Td (Hello ArkoPDF) Tj ET";
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

static BOOL ImageHasDarkPixel(CGImageRef img) {
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

static BOOL WritePNG(CGImageRef img, NSString *path) {
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCGImage:img];
    NSData *png = [rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
    return [png writeToFile:path atomically:YES];
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSString *cwd = [NSFileManager defaultManager].currentDirectoryPath;
        NSError *err = nil;
        int failures = 0;

        // 1. 加载 SDK
        if (![ArkoSDK loadWithLicense:@"ED578A089CEB689277D52D37515938AA" error:&err]) {
            fprintf(stderr, "FAIL: SDK load: %s\n", err.localizedDescription.UTF8String);
            return 1;
        }
        fprintf(stdout, "PASS: SDK loaded\n");

        // 2. 写最小 PDF
        NSString *pdfPath = [cwd stringByAppendingPathComponent:@"smoke_input.pdf"];
        if (![SmokeMinimalPDF() writeToFile:pdfPath atomically:YES encoding:NSUTF8StringEncoding error:&err]) {
            fprintf(stderr, "FAIL: write pdf: %s\n", err.localizedDescription.UTF8String);
            return 1;
        }

        // 3. 打开
        ArkoDocument *doc = [[ArkoDocument alloc] initWithURL:[NSURL fileURLWithPath:pdfPath] error:&err];
        if (!doc) {
            fprintf(stderr, "FAIL: open: %s\n", err.localizedDescription.UTF8String);
            return 1;
        }
        fprintf(stdout, "PASS: document opened\n");

        // 4. 页数
        if (doc.pageCount != 1) {
            fprintf(stderr, "FAIL: pageCount=%ld (expected 1)\n", (long)doc.pageCount);
            return 1;
        }
        fprintf(stdout, "PASS: pageCount == 1\n");

        // 5. 渲染
        ArkoPage *page = [doc pageAtIndex:0];
        if (!page) { fprintf(stderr, "FAIL: pageAtIndex(0) returned nil\n"); return 1; }
        CGImageRef img = [page renderImageAtScale:1.0];
        if (!img) { fprintf(stderr, "FAIL: render returned nil\n"); return 1; }
        fprintf(stdout, "PASS: rendered %zux%zu px\n", CGImageGetWidth(img), CGImageGetHeight(img));

        // 6. 非空白检查
        BOOL hasContent = ImageHasDarkPixel(img);
        fprintf(stdout, "%s: page has content (non-blank) = %d\n", hasContent ? "PASS" : "FAIL", hasContent);
        if (!hasContent) failures++;

        // 7. 输出渲染截图
        NSString *pngPath = [cwd stringByAppendingPathComponent:@"smoke_page0.png"];
        if (WritePNG(img, pngPath)) {
            fprintf(stdout, "PASS: wrote %s\n", pngPath.UTF8String);
        } else {
            fprintf(stderr, "FAIL: write png\n");
            failures++;
        }

        // 8. 加高亮标注
        NSValue *box = [NSValue valueWithRect:CGRectMake(70, 715, 220, 30)];
        unsigned int color = [ArkoPage makeRGBColorWithRed:255 green:214 blue:10];
        [page addTextMarkupOfType:10 lineBoxes:@[box] color:color opacity:0.8f];
        fprintf(stdout, "PASS: added highlight annotation\n");

        // 9. 保存
        NSString *savePath = [cwd stringByAppendingPathComponent:@"smoke_output.pdf"];
        if (![doc saveToURL:[NSURL fileURLWithPath:savePath] error:&err]) {
            fprintf(stderr, "FAIL: save: %s\n", err.localizedDescription.UTF8String);
            return 1;
        }
        unsigned long long size = [[[NSFileManager defaultManager] attributesOfItemAtPath:savePath error:&err] fileSize];
        fprintf(stdout, "PASS: saved output (%llu bytes)\n", size);
        if (size == 0) failures++;

        [doc close];

        fprintf(stdout, failures == 0 ? "SMOKE TEST PASSED\n" : "SMOKE TEST FAILED\n");
        return failures == 0 ? 0 : 1;
    }
}
