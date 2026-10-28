//  ArkoPage.h
//  每页适配器：封装 IPDF_Page，提供渲染（含标注叠加）、文本选择命中、
//  选区矩形、标注创建。对应 Windows 版的 CAmdEdt_PageViewImpl。

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@class ArkoParagraph;

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

/// 搜索本页所有匹配文字的矩形（PDF 用户坐标，NSValue 包 CGRect，y 为 bottom）。返回空数组表示无匹配。
- (NSArray<NSValue *> *)searchTextRects:(NSString *)text;

/// 文本对比：返回本页所有字符（文本流顺序）。每项 @{@"u":@unicode, @"x":@left, @"y":@bottom, @"w":@width, @"h":@height, @"fs":@fontSize}。
- (NSArray<NSDictionary *> *)charInfoList;

/// 整页文本（UTF-8，供 AI 对比提取）。
- (nullable NSString *)pageText;

/// 指定矩形区域内的文本（UTF-8，供导出报告用）。
- (nullable NSString *)textInRect:(CGRect)rect NS_SWIFT_NAME(text(inRect:));

/// 新建文本标记标注（高亮/下划线/删除线）。
/// @param annotType ANNOT_TYPE_HIGHLIGHT / ANNOT_TYPE_UNDERLINE / ANNOT_TYPE_STRIKEOUT
/// @param lineBoxes 每行一个 CGRect（PDF 用户坐标），内部展开为 QuadPoints。
/// @param color  COLOR_MAKERGB 格式（用 +makeRGBColorWithRed:green:blue: 构造）。
/// @param opacity 不透明度 0.0–1.0。
- (void)addTextMarkupOfType:(NSInteger)annotType
                  lineBoxes:(NSArray<NSValue *> *)lineBoxes
                      color:(unsigned int)color
                    opacity:(float)opacity;

// 图形标注（line/rect/ellipse/polygon/polyline/ink）：points 每个 NSValue 包一个 CGPoint（用户坐标）
- (void)addShapeAnnotOfType:(NSInteger)annotType
                     points:(NSArray<NSValue *> *)points
                      color:(unsigned int)color
                    opacity:(float)opacity
                borderWidth:(int)borderWidth;

// 便签（sticknote）
- (void)addNoteAnnotAtRect:(CGRect)rect
                  contents:(NSString *)contents
                     color:(unsigned int)color
                   opacity:(float)opacity;

// 密文标记（ANNOT_TYPE_SQUARE + 填充色）：rect 为 PDF 用户坐标，contents 为叠加文字（可 nil）。
- (unsigned long long)addRedactionMarkAtRect:(CGRect)rect
                                   fillColor:(unsigned int)fillColor
                                    contents:(nullable NSString *)contents
    NS_SWIFT_NAME(addRedactionMark(at:fillColor:contents:));

/// 删除页面内容中完全落入指定矩形区域的对象（密文应用，调用 ArkoPDFCore 的 DeleteContentObjects）。
- (NSInteger)deleteContentInRects:(NSArray<NSValue *> *)rects
    NS_SWIFT_NAME(deleteContent(inRects:));

/// 返回所有密文标记（/Redact 标注），每项 @{@"rect":NSValue(CGRect), @"contents":NSString?}。
- (NSArray<NSDictionary *> *)redactionMarks;

/// 在矩形上叠加文字（密文叠加文字/豁免码）。fontHandle 取 ArkoDocument.defaultFontHandle。
/// align: 0=左 1=中 2=右。
- (void)addOverlayText:(NSString *)text
                inRect:(CGRect)rect
            fontHandle:(unsigned long long)fontHandle
              fontSize:(float)fontSize
                 color:(unsigned int)color
                 align:(int)align
    NS_SWIFT_NAME(addOverlayText(_:inRect:fontHandle:fontSize:color:align:));

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

#pragma mark - 段落编辑（IPDF_LogicalStructAnalyser）

/// 段落数量（需先 ensureParagraphAnalyser）。
@property (nonatomic, readonly) NSInteger paragraphCount;
/// 第 index 个段落（nil 表示越界/分析器不可用）。
- (nullable ArkoParagraph *)paragraphAtIndex:(NSInteger)index;
/// 命中测试：返回某点处的段落，nil 表示空白处。
- (nullable ArkoParagraph *)paragraphAtPointX:(CGFloat)x y:(CGFloat)y;
/// 在空白处新建段落（对应 Windows「添加文字/段落」），返回新段落。
- (nullable ArkoParagraph *)newParagraphAtX:(CGFloat)x y:(CGFloat)y width:(CGFloat)width height:(CGFloat)height
    NS_SWIFT_NAME(newParagraph(atX:y:width:height:));
/// 删除第 index 个段落（撤销新建段落用，不记录 SDK 撤销项）。
- (void)deleteParagraphAtIndex:(NSInteger)index;
/// 删除第 index 个段落并用 SDK 原生撤销项记录（删除段落的撤销/重做用）。
- (void)deleteParagraphAtIndex:(NSInteger)index undoItem:(unsigned long long)undoItem;
/// 按段落句柄删除（handle 取 ArkoParagraph.paragraphHandle），并用 SDK 撤销项记录。
- (void)deleteParagraphByHandle:(unsigned long long)handle undoItem:(unsigned long long)undoItem;
/// 应用/回滚段落原生撤销项（handle 由 ArkoParagraph 编辑方法返回）。
- (void)paraUndoItem:(unsigned long long)handle;
- (void)paraRedoItem:(unsigned long long)handle;

#pragma mark - 页面对象（图片编辑 / 添加文字图片）

@property (nonatomic, readonly) NSInteger pageObjectCount;
/// 返回 @{@"type":@int, @"bbox":NSValue(CGRect), @"image":@BOOL}；nil 表示越界。
- (nullable NSDictionary *)pageObjectInfoAtIndex:(NSInteger)index;
/// 命中测试：返回某点最上层的页面对象下标，-1 表示无。
- (NSInteger)pageObjectIndexAtPointX:(CGFloat)x y:(CGFloat)y;

// 对象克隆（撤销/重做用；clone 句柄由 +releasePageObjectClone: 释放）
- (unsigned long long)clonePageObjectAtIndex:(NSInteger)index;
+ (void)releasePageObjectClone:(unsigned long long)clone NS_SWIFT_NAME(releasePageObjectClone(_:));
/// 页面对象句柄（IPDF_PageObject*，身份追踪用，不受 z-order 漂移影响）。
- (unsigned long long)pageObjectHandlerAtIndex:(NSInteger)index NS_SWIFT_NAME(pageObjectHandler(at:));
/// 按句柄删除对象（精确删除，避免 index 漂移）。
- (void)deletePageObjectByHandler:(unsigned long long)handler NS_SWIFT_NAME(deletePageObject(byHandler:));
/// 撤销删除/新建：把克隆对象（内部再次 Clone）按 zOrder 加入页。
- (void)addPageObjectClone:(unsigned long long)clone atZOrder:(NSInteger)zOrder
    NS_SWIFT_NAME(addPageObjectClone(_:atZOrder:));
/// 撤销移动/缩放/旋转：用 clone 覆盖当前对象状态。
- (void)copyPageObjectAtIndex:(NSInteger)index fromClone:(unsigned long long)clone
    NS_SWIFT_NAME(copyPageObject(at:fromClone:));
- (void)deletePageObjectAtIndex:(NSInteger)index NS_SWIFT_NAME(deletePageObject(at:));

// 图片编辑
- (void)movePageObjectAtIndex:(NSInteger)index byX:(float)dx y:(float)dy
    NS_SWIFT_NAME(movePageObject(at:byX:y:));
- (void)resizePageObjectAtIndex:(NSInteger)index toWidth:(float)width height:(float)height
    NS_SWIFT_NAME(resizePageObject(at:toWidth:height:));
- (void)rotatePageObjectAtIndex:(NSInteger)index byAngle:(float)radian
    NS_SWIFT_NAME(rotatePageObject(at:byAngle:));
- (void)flipPageObjectAtIndex:(NSInteger)index horizontal:(BOOL)horizontal
    NS_SWIFT_NAME(flipPageObject(at:horizontal:));
- (void)replaceImageAtIndex:(NSInteger)index withJpegPath:(NSString *)path;
- (BOOL)exportImageAtIndex:(NSInteger)index toJpegPath:(NSString *)path;
- (void)sendPageObjectToBackAtIndex:(NSInteger)index NS_SWIFT_NAME(sendPageObjectToBack(at:));
- (void)bringPageObjectToFrontAtIndex:(NSInteger)index NS_SWIFT_NAME(bringPageObjectToFront(at:));

/// 添加 JPEG 图片到页，返回其 z-order 下标（-1 失败）。
- (NSInteger)addImageWithJpegPath:(NSString *)path
                              atX:(float)x y:(float)y
                            width:(float)width height:(float)height
                            alpha:(float)alpha;

/// 放置签名：从 JPEG 创建签名对象并放置到页（IPDF_Signer::CreateSignature + PlaceSignature），返回 z-order 下标（-1 失败）。
- (NSInteger)placeSignatureWithJpegPath:(NSString *)path
                                    atX:(float)x y:(float)y
                                  width:(float)width height:(float)height
    NS_SWIFT_NAME(placeSignature(jpegPath:atX:y:width:height:));

#pragma mark - 链接标注（ANNOT_TYPE_LINK）

/// 新建链接标注，返回标注句柄（0 失败）。rect 为 PDF 用户坐标。
- (unsigned long long)addLinkAnnotInRect:(CGRect)rect;
- (void)setLinkURI:(NSString *)uri forAnnotHandler:(unsigned long long)handler;
/// 链接到文档内某页（zoomMode 用 PDF_ZOOM_*，如 2 = 适合页面）。
- (void)setLinkDestinationPage:(NSInteger)pageIndex
                      zoomMode:(NSInteger)zoomMode
                forAnnotHandler:(unsigned long long)handler
    NS_SWIFT_NAME(setLinkDestinationPage(_:zoomMode:forAnnotHandler:));
- (nullable NSString *)linkURIForAnnotHandler:(unsigned long long)handler;
/// 返回 @{@"page":@int, @"zoomMode":@int}；非页内跳转返回 nil。
- (nullable NSDictionary *)linkDestinationForAnnotHandler:(unsigned long long)handler;

/// 保存前调用：重新序列化页内容（含新增标注）。
- (void)generateContent;

/// 页面是否存在「试用水印」（trailmark），用于验证 license 水印机制。
- (BOOL)hasTrailmark;

/// 由 RGB 构造 SDK 颜色（BGR 字节序）。
+ (unsigned int)makeRGBColorWithRed:(uint8_t)r green:(uint8_t)g blue:(uint8_t)b;

- (instancetype)init NS_UNAVAILABLE;

// 内部（ArkoDocument 专用，勿从 Swift 调用）
- (nullable instancetype)initWithSDKPage:(void *)page index:(NSInteger)index;
/// 内部：底层 IPDF_Page*（数字签名等需要，勿从 Swift 调用）。
- (void *)sdkPage;

@end

NS_ASSUME_NONNULL_END
