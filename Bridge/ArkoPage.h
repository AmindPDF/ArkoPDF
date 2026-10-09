//  ArkoPage.h
//  每页适配器：封装 IPDF_Page，提供渲染（含标注叠加）、文本选择命中、
//  选区矩形、标注创建。对应 Windows 版的 CAmdEdt_PageViewImpl。

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@interface ArkoPage : NSObject

@property (nonatomic, readonly) NSInteger pageIndex;
@property (nonatomic, readonly) CGFloat widthInPoints;
@property (nonatomic, readonly) CGFloat heightInPoints;

/// 渲染整页（含标注叠加）到位图并转 CGImage。scale 为相对 72dpi 的倍率。
- (nullable CGImageRef)renderImageAtScale:(CGFloat)scale CF_RETURNS_RETAINED;

/// 命中测试：PDF 用户坐标点 → 文本 caret 下标（<0 表示该点无字符）。
- (NSInteger)caretAtUserPointX:(CGFloat)ux y:(CGFloat)uy tolerance:(CGFloat)tol;

/// 选区的所有字符矩形（PDF 用户坐标；NSValue 用 valueWithRect:，y 为 bottom）。
- (NSArray<NSValue *> *)charBoxesFromCaret:(NSInteger)start toCaret:(NSInteger)end;

/// 选区文本（UTF-8）。
- (nullable NSString *)selectedTextFromCaret:(NSInteger)start toCaret:(NSInteger)end;

/// 新建文本标记标注（高亮/下划线/删除线）。
/// @param annotType ANNOT_TYPE_HIGHLIGHT / ANNOT_TYPE_UNDERLINE / ANNOT_TYPE_STRIKEOUT
/// @param lineBoxes 每行一个 CGRect（PDF 用户坐标），内部展开为 QuadPoints。
/// @param color  COLOR_MAKERGB 格式（用 +makeRGBColorWithRed:green:blue: 构造）。
/// @param opacity 不透明度 0.0–1.0。
- (void)addTextMarkupOfType:(NSInteger)annotType
                  lineBoxes:(NSArray<NSValue *> *)lineBoxes
                      color:(unsigned int)color
                    opacity:(float)opacity;

// 标注管理（枚举 / 删除 / 修改）
@property (nonatomic, readonly) NSInteger annotCount;
/// 返回 @{@"type":@(ANNOT_TYPE), @"color":@(COLOR_MAKERGB), @"opacity":@(float), @"rect":NSValue(CGRect)}。
- (nullable NSDictionary *)annotInfoAtIndex:(NSInteger)index;
- (void)removeAnnotAtIndex:(NSInteger)index;
- (void)setAnnotColor:(unsigned int)color atIndex:(NSInteger)index;
- (void)setAnnotOpacity:(float)opacity atIndex:(NSInteger)index;

// 标注句柄（撤销/重做用：void* 以 64 位整数传递，删除后可 AddAnnotByHandler 重插入）
- (unsigned long long)annotHandlerAtIndex:(NSInteger)index;
- (void)removeAnnotByHandler:(unsigned long long)handler;
- (void)addAnnotByHandler:(unsigned long long)handler atIndex:(NSInteger)index;

/// 保存前调用：重新序列化页内容（含新增标注）。
- (void)generateContent;

/// 由 RGB 构造 SDK 颜色（BGR 字节序）。
+ (unsigned int)makeRGBColorWithRed:(uint8_t)r green:(uint8_t)g blue:(uint8_t)b;

- (instancetype)init NS_UNAVAILABLE;

// 内部（ArkoDocument 专用，勿从 Swift 调用）
- (nullable instancetype)initWithSDKPage:(void *)page index:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
