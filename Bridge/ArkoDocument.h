//  ArkoDocument.h
//  封装 IPDF_Document：打开 / 关闭 / 页数 / 取页 / 保存。

#import <Foundation/Foundation.h>

@class ArkoPage;
@class ArkoDocument;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ArkoPPOOperation) {
    ArkoPPOOperationInsertBlank,
    ArkoPPOOperationDeletePages,
    ArkoPPOOperationSwapPages,
    ArkoPPOOperationRotatePage,
    ArkoPPOOperationInsertPages,
    ArkoPPOOperationReplacePages,
};

/// PPO 操作通知：在页面操作前后回调，供其它模块释放/重建页引用、同步索引。
@protocol ArkoDocumentPPODelegate <NSObject>
@optional
/// 操作前：`pages` 为即将操作的页（操作前的索引）。
- (void)document:(ArkoDocument *)document willChangePages:(ArkoPPOOperation)operation pages:(NSArray<NSNumber *> *)pages;
/// 操作后：页索引已重排，调用方需重新读取 pageCount / 页面。
- (void)document:(ArkoDocument *)document didChangePages:(ArkoPPOOperation)operation;
@end

/// 安全设置（保存时通过 IPDF_Creator 应用）。
@interface ArkoSecurityOptions : NSObject
@property (nonatomic) unsigned int permissions;         // USER_PERM_* 位或
@property (nonatomic, copy, nullable) NSString *ownerPassword;  // 权限密码
@property (nonatomic, copy, nullable) NSString *userPassword;   // 打开密码
@property (nonatomic) int cipher;                        // ENCRYPT_CIPHER_*
@property (nonatomic) int keylen;                        // 128 / 256
@property (nonatomic) BOOL encryptMetadata;
/// YES = 移除安全（不加密）；否则按上面字段设置安全。
@property (nonatomic) BOOL removeSecurity;
@end

@interface ArkoDocument : NSObject

@property (nonatomic, weak, nullable) id<ArkoDocumentPPODelegate> ppoDelegate;

- (nullable instancetype)initWithURL:(NSURL *)url error:(NSError **)error;
/// 带密码打开：加密文档时先 InputPassword 再重新 Open（对齐 Windows agent_ai.cpp 流程）。
- (nullable instancetype)initWithURL:(NSURL *)url password:(nullable NSString *)password error:(NSError **)error;
@property (nonatomic, readonly) NSInteger pageCount;
- (nullable ArkoPage *)pageAtIndex:(NSInteger)index;
- (BOOL)saveToURL:(NSURL *)url
         progress:(nullable void (^)(float))progress
       isCancelled:(nullable BOOL (^)(void))isCancelled
          security:(nullable ArkoSecurityOptions *)security
             error:(NSError **)error NS_SWIFT_NAME(save(to:progress:isCancelled:security:));
- (void)close;

// 页面组织（PPO）：每次操作前后会通过 ppoDelegate 发通知，内部重建页缓存
- (void)insertBlankPageAt:(NSInteger)index width:(CGFloat)width height:(CGFloat)height;
- (void)deletePagesFrom:(NSInteger)start count:(NSInteger)count;
- (void)swapPage:(NSInteger)page1 with:(NSInteger)page2;
- (NSInteger)pageRotationAtIndex:(NSInteger)index;
- (void)setPageRotation:(NSInteger)rotateFlag atIndex:(NSInteger)index;
// 页面句柄克隆/恢复（撤销删除页用：删除前克隆，撤销时插空白页 + 拷回句柄）
- (nullable NSArray<NSNumber *> *)clonePageHandlersFrom:(NSInteger)start count:(NSInteger)count;
- (void)restorePagesWithClones:(NSArray<NSNumber *> *)clones atIndex:(NSInteger)start;
// 释放页面句柄克隆（撤销项被丢弃时调用）
+ (void)destroyPageHandlerClones:(NSArray<NSNumber *> *)clones;

// 提取页面：把 pages（0-based 页号数组）复制为新文档并保存到 url，不改当前文档。
- (BOOL)extractPages:(NSArray<NSNumber *> *)pages toURL:(NSURL *)url error:(NSError **)error
    NS_SWIFT_NAME(extractPages(_:to:));
// 从源 PDF 插入页面：把源文档的 pages 复制插入到 index 处（改变当前文档）。
- (void)insertPagesFromURL:(NSURL *)url pages:(NSArray<NSNumber *> *)pages atIndex:(NSInteger)index
    NS_SWIFT_NAME(insertPages(from:pages:at:));
// 替换页面：用源文档的 pages 替换当前文档从 start 起的 count 页（改变当前文档）。
- (void)replacePagesFromURL:(NSURL *)url pages:(NSArray<NSNumber *> *)pages atIndex:(NSInteger)start count:(NSInteger)count
    NS_SWIFT_NAME(replacePages(from:pages:at:count:));

/// 快速读取某 PDF 的页数（不创建完整文档对象，供插入/替换的源文件选择器用）。
+ (NSInteger)pageCountOfURL:(NSURL *)url NS_SWIFT_NAME(pageCount(of:));

// 安全（查询）
/// 当前权限 flags（USER_PERM_* 位或）。
- (unsigned int)permissionFlags;
/// 文档是否已加密。
- (BOOL)isEncrypted;

// 大纲（书签树）
/// 返回 @[@{@"title":NSString, @"level":@int, @"page":@int, @"path":NSArray<NSNumber*>}]（扁平、按树序）。
- (NSArray<NSDictionary *> *)outlineItems;
- (void)addBookmark:(NSString *)title underPath:(nullable NSArray<NSNumber *> *)path;
- (void)renameBookmarkAtPath:(NSArray<NSNumber *> *)path title:(NSString *)title;
- (void)removeBookmarkAtPath:(NSArray<NSNumber *> *)path;

// 编辑：默认字体（添加文字/段落用，文档持有，勿 Release）。返回 0 表示不可用。
@property (nonatomic, readonly) unsigned long long defaultFontHandle;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
