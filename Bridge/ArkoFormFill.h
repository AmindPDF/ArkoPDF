//  ArkoFormFill.h
//  表单填充桥接：封装 PDSDK 的 IPDF_FormFill（AcroForm 交互）。

#import <Foundation/Foundation.h>

@class ArkoDocument;
@class ArkoPage;

NS_ASSUME_NONNULL_BEGIN

@interface ArkoFormFill : NSObject

/// 表单变化请求重绘（内部字段变化/焦点变化时回调）。
@property (nonatomic, copy, nullable) void (^onInvalidate)(void);
/// 任一表单字段值改变时回调。
@property (nonatomic, copy, nullable) void (^onChange)(void);

/// 创建表单填充环境（document 打开后调用）。docHandle 为 IPDF_Document*。失败返回 nil。
- (nullable instancetype)initWithSDKDocument:(void *)docHandle;
- (void)close;

/// 页面加载/关闭钩子（由 ArkoDocument 在页面创建/释放时调用）。
- (void)onAfterLoadPage:(ArkoPage *)page;
- (void)onBeforeClosePage:(ArkoPage *)page;

/// 命中测试：返回字段类型（PDSDK_FORMFIELD_*），无字段返回 -1。
- (NSInteger)formFieldTypeAtPage:(ArkoPage *)page x:(CGFloat)x y:(CGFloat)y;

/// 交互事件（返回 YES 表示表单引擎已处理，调用方应停止继续分发）。
- (BOOL)onMouseMoveAtPage:(ArkoPage *)page x:(CGFloat)x y:(CGFloat)y modifier:(int)modifier;
- (BOOL)onLButtonDownAtPage:(ArkoPage *)page x:(CGFloat)x y:(CGFloat)y modifier:(int)modifier;
- (BOOL)onLButtonUpAtPage:(ArkoPage *)page x:(CGFloat)x y:(CGFloat)y modifier:(int)modifier;
- (BOOL)onKeyDownAtPage:(ArkoPage *)page keyCode:(int)keyCode modifier:(int)modifier;
- (BOOL)onKeyUpAtPage:(ArkoPage *)page keyCode:(int)keyCode modifier:(int)modifier;
- (BOOL)onCharAtPage:(ArkoPage *)page nChar:(int)nChar modifier:(int)modifier;
- (BOOL)forceKillFocus;

/// 渲染表单字段到位图（页面内容 + 普通标注之后、转 CGImage 之前调用）。
- (void)drawFieldsForPage:(ArkoPage *)page
                   bitmap:(void *)bitmap
                  startX:(int)startX startY:(int)startY
                   sizeX:(int)sizeX sizeY:(int)sizeY
                  rotate:(int)rotate flags:(int)flags;

- (void)setHighlightColor:(int)fieldType color:(unsigned long)color;
- (void)setHighlightAlpha:(unsigned char)alpha;
- (void)removeHighlight;

@end

/// 内部：当前表单填充环境（ArkoPage 渲染用，单文档场景）。
FOUNDATION_EXPORT void* ArkoGetSDKFormFill(void);
FOUNDATION_EXPORT void ArkoSetSDKFormFill(void* ff);

NS_ASSUME_NONNULL_END
