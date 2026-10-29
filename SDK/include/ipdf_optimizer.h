#pragma once
#include "ipdf_base.h"

#ifndef PDSDKEXPORT
#define PDSDKEXPORT
#endif

class IPDF_Document;

/* 图片压缩类型。 */
#define PDSDK_IMG_COMPRESS_RETAIN		0	/* 不重压缩 */
#define PDSDK_IMG_COMPRESS_JPEG			1	/* JPEG（彩色/灰度） */
#define PDSDK_IMG_COMPRESS_CCITT3		2	/* 单色 CCITT Group 3 */
#define PDSDK_IMG_COMPRESS_CCITT4		3	/* 单色 CCITT Group 4 */
/* Phase 3 预留（需外部 imgseg，当前不支持） */
#define PDSDK_IMG_COMPRESS_JBIG2		4
#define PDSDK_IMG_COMPRESS_JPEG2000		5

/**
 * 图片优化参数。
 * 彩色/灰度走 JPEG；单色走 CCITT G3/G4。
 * 压缩链路：CPDF_ImageObject 解码（LoadDIBSource，可降采样）→ 编码
 * → 写回流数据与字典（JPEG=DCTDecode，单色=CCITTFaxDecode）。
 */
typedef struct _PDSDK_ImageOptimizeParam {
	int		compressionType;		/* 彩色/灰度：RETAIN/JPEG（+JBIG2/JPEG2000 预留） */
	int		monoCompressionType;	/* 单色(1bit)：RETAIN/CCITT3/CCITT4（+JBIG2 预留） */
	int		quality;				/* JPEG 质量 0-100；CCITT 无意义 */
	int		downsampleDPI;			/* 降采样目标 DPI（0 = 不降采样） */
	int		downsampleAbove;		/* 仅当图片有效 DPI 高于此值才降采样（0 = 全部降） */
	int		bMustReduceSize;		/* 1 = 仅当重压缩后更小才替换 */
} PDSDK_ImageOptimizeParam;

/** 优化选项。 */
typedef struct _PDSDK_OptimizeOptions {
	PDSDK_ImageOptimizeParam	image;

	/* —— 流压缩 —— */
	int		bFlateStreams;			/* 1 = 无 Filter 流 → FlateDecode */
	int		bLZWToFlate;			/* 1 = LZW 流解码后 → FlateDecode */

	/* —— 无效对象 —— */
	int		bRemoveInvalidObjs;		/* 1 = 删除未引用对象 */

	/* —— 字体 —— */
	int		bUnembedFonts;			/* 1 = 取消嵌入非符号字体（去 FontFile 流） */

	/* —— 丢弃对象 —— */
	int		bDiscardJavaScript;		/* 1 = 删除 JS 动作（文档级 / 页面 / 标注 / 书签） */
	int		bDiscardPageThumbnails;	/* 1 = 删除页面缩略图 */
	int		bDiscardPrintSettings;	/* 1 = 删除嵌入打印设置 */
	int		bDiscardBookmarks;		/* 1 = 删除书签（Outline） */
	int		bDiscardFileAttachments;/* 1 = 删除文件附件（EmbeddedFiles） */
	int		bDiscardPrivateData;	/* 1 = 删除其它应用私有数据（PieceInfo） */
	int		bDiscardMetadata;		/* 1 = 删除文档信息 + XMP 元数据 */
	int		bDiscardFormFields;		/* 1 = 删除表单字段（AcroForm） */
	int		bDiscardExternalCrossRefs;	/* 1 = 删除外部交叉引用 */

	/* —— 扁平化 —— */
	int		bFlattenFormFields;		/* 1 = 把表单字段外观写进页面内容流 */
	int		bFlattenAnnotations;	/* 1 = 把标注外观写进页面内容流 */

	/* —— 清理 —— */
	int		bRemoveInvalidBookmarks;		/* 1 = 删除指向无效目标的书签 */
	int		bRemoveInvalidLinks;			/* 1 = 删除指向无效目标的链接 */
	int		bRemoveUnreferencedNamedDests;	/* 1 = 删除未引用的命名目的地 */

	/* —— Phase 3 预留（外部 imgseg / Callas，当前返回不支持） —— */
	int		bMRC;					/* MRC 高压缩 */
	int		bPDFA;					/* PDF/A 转换 */
} PDSDK_OptimizeOptions;

/** 审计结果（估算可省空间，字节）。 */
typedef struct _PDSDK_OptimizeAudit {
	long long	imageSaving;		/* 图片优化可省 */
	long long	streamSaving;		/* 流压缩可省（Flate + LZW→Flate） */
	long long	invalidObjSaving;	/* 无效对象可省 */
	long long	fontSaving;			/* 字体取消嵌入可省 */
	long long	discardSaving;		/* 丢弃对象可省 */
	long long	flattenSaving;		/* 扁平化（预留，通常 0） */
	long long	totalSaving;		/* 合计 */
} PDSDK_OptimizeAudit;

/**
 * 进度回调。OnProgress 返回 0=继续，非 0=取消。
 * percent 为 0~100；pCancel 为输出，置非 0 请求取消。
 */
typedef struct _PDSDK_OptimizeProgress {
	void*	pUserData;
	int		(*OnProgress)(void* pUserData, int percent, int* pCancel);
} PDSDK_OptimizeProgress;

/**
 * PDF 优化器。
 * 通过 PDSDK_NewOptimizer 创建，用 Release 释放；单文档场景，可重复用于多个文档。
 */
class IPDF_Optimizer {
public:
	virtual void Release() = 0;

	/**
	 * 审计：扫描文档，估算各优化项可省空间（不修改文档）。
	 * @return 0=成功，-1=用户取消，其它=失败（含 Phase 3 未实现项返回非 0）。
	 */
	virtual int Audit(IPDF_Document* doc, const PDSDK_OptimizeOptions* options,
					  PDSDK_OptimizeAudit* out, const PDSDK_OptimizeProgress* progress) = 0;

	/**
	 * 执行优化（就地修改文档，保存时才写回文件）。
	 * @return 0=成功，-1=用户取消，其它=失败（含 Phase 3 未实现项返回非 0）。
	 */
	virtual int Optimize(IPDF_Document* doc, const PDSDK_OptimizeOptions* options,
						 PDSDK_OptimizeAudit* out, const PDSDK_OptimizeProgress* progress) = 0;
};

/** 创建优化器。 */
extern "C" PDSDKEXPORT IPDF_Optimizer* PDSDK_NewOptimizer();
