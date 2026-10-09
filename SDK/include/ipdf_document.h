#pragma once

#define _FX_WIN32_DESKTOP_		1
#define _FX_LINUX_DESKTOP_		4
#define _FX_MACOSX_				7
#define _FX_ANDROID_			12
#define _FXM_PLATFORM_WINDOWS_		1
#define _FXM_PLATFORM_LINUX_		2
#define _FXM_PLATFORM_APPLE_		3
#define _FXM_PLATFORM_ANDROID_		4

#if defined(__ANDROID__)
#define _FX_OS_ _FX_ANDROID_
#define _FXM_PLATFORM_ _FXM_PLATFORM_ANDROID_
#elif defined(_WIN32) || defined(_WIN64)
#define _FX_OS_ _FX_WIN32_DESKTOP_
#define _FXM_PLATFORM_ _FXM_PLATFORM_WINDOWS_
#elif defined(__linux__)
#define _FX_OS_ _FX_LINUX_DESKTOP_
#define _FXM_PLATFORM_ _FXM_PLATFORM_LINUX_
#elif defined(__APPLE__)
#include "TargetConditionals.h"
#if (defined(TARGET_OS_IPHONE) && TARGET_OS_IPHONE == 1) || (defined(TARGET_IPHONE_SIMULATOR) && TARGET_IPHONE_SIMULATOR == 1)
#define _FX_OS_ _FX_IOS_
#else
#define _FX_OS_ _FX_MACOSX_
#endif
#define _FXM_PLATFORM_ _FXM_PLATFORM_APPLE_
#endif

#if _FXM_PLATFORM_ == _FXM_PLATFORM_WINDOWS_
#define _CRT_SECURE_NO_WARNINGS
#include <windows.h>
#endif
#if _FXM_PLATFORM_ == _FXM_PLATFORM_APPLE_
#include <libkern/OSAtomic.h>
#if _FX_OS_ == _FX_MACOSX_
#include <Carbon/Carbon.h>
#elif _FX_OS_ == _FX_IOS_
#include <CoreText/CoreText.h>
#include <CoreGraphics/CoreGraphics.h>
#endif
#endif


/**
 * @name Reasons for PDF opening failure: returned by IPDF_Document::Open() method..
 */
 /*@{*/
/** @brief no error. */
#define PDF_OPEN_ERROR_SUCCESS		0 //success
/** @brief file error: not found or could not be opened. */
#define PDF_OPEN_ERROR_FILE			1 
/** @brief format error: not a PDF or corrupted. */
#define PDF_OPEN_ERROR_FORMAT		2 
/** @brief Invalid password. Need input again. */
#define PDF_OPEN_ERROR_PASSWORD		3 
/** @brief This document is encrypted by some unsupported security handler. */
#define PDF_OPEN_ERROR_HANDLER		4 
/** @brief This document is encrypted by digital certificate and current user doesn't have correct certificate. */
#define PDF_OPEN_ERROR_CERT			5 
/*@}*/

//User Permission
#define USER_PERM_PRINT			0x0004
#define USER_PERM_MODIFY		0x0008
#define USER_PERM_EXTRACT		0x0010
#define USER_PERM_ANNOT_FORM	0x0020
#define USER_PERM_FILL_FORM		0x0100
#define USER_PERM_EXTRACT_ACCESS	0x0200
#define USER_PERM_ASSEMBLE			0x0400
#define USER_PERM_PRINT_HIGH		0x0800

//Enrypt Cipher
#define ENCRYPT_CIPHER_NONE	0
#define ENCRYPT_CIPHER_RC4	1
#define ENCRYPT_CIPHER_AES	2
#define ENCRYPT_CIPHER_AES2 3

/**
 * @name Predefined font encoding.
 */
 /*@{*/

/** @brief Built-in encoding. */
#define PDF_ENCODING_BUILTIN		0
/** @brief WinAnsiEncoding. */
#define PDF_ENCODING_WINANSI		1
/** @brief MacRomanEncoding. */
#define PDF_ENCODING_MACROMAN		2
/** @brief MacExpertEncoding. */
#define PDF_ENCODING_MACEXPERT		3
/** @brief StandardEncoding. Adobe standard encoding. */
#define PDF_ENCODING_STANDARD		4
/** @brief Adobe symbol encoding. */
#define PDF_ENCODING_ADOBE_SYMBOL	5
/** @brief ZapfDingbats encoding. */
#define PDF_ENCODING_ZAPFDINGBATS	6
/** @brief PDFDocEncoding. */
#define PDF_ENCODING_PDFDOC			7
/** @brief Microsoft symbol encoding. */
#define PDF_ENCODING_MS_SYMBOL		8
/** @brief Unicode. */
#define PDF_ENCODING_UNICODE		9
/*@}*/

class IPDF_Page;
class IPDF_PageOrganizer;
class IPDF_PageDesigner;
class IPDF_Progress;
class IPDF_Pause;
class IPDF_Font;
class IPDF_BookmarkTree;
class IPDF_FolderFontInfo;
/** The page handler indentity a page*/
typedef void* PDF_PageHandler;

/**
 * @brief Interfac for a PDF document. 
 */
class IPDF_Document
{
public:
	/**
	 * Create a new document with a blank page. 
	 *
	 * @param[in] page_width		The blank page width.
	 * @param[in] page_height		The blank page height.
	 * @param[in] nBlankPages		The total number of new black pages.
	 * @return 1 for success, 0 for failur.
	 */
	virtual int NewBlankDoc(float page_width, float page_height, int nBlankPages = 1) = 0;

	/**
	 * Open a PDF document.
	 *
	 * @param[in] pdf_file		The PDF file path(unicode).
	 * @param[in] bReParse		Whether we will do reparsing.
	 * @return The status of PDF parsing.@see Reasons for PDF opening failure
	 */
	virtual int Open(const wchar_t* pdf_file, int bReParse = 0) = 0;//PDF_OPEN_ERROR_XXXX

	/**
	 * Open a PDF document.
	 *
	 * @param[in] pdf_file_utf8		The PDF file path(utf8).
	 * @param[in] bReParse			Whether we will do reparsing.
	 * @return The status of PDF parsing.@see Reasons for PDF opening failure
	 */
	virtual int Open(const char* pdf_file_utf8, int bReParse = 0) = 0;

	/**
	 * Open a PDF document in memeroy.
	 *
	 * @param[in] data			The PDF memeroy data.
	 * @param[in] data_len		The length of data.
	 * @return The status of PDF parsing.@see Reasons for PDF opening failure
	 */
	virtual int Open(void* data, unsigned int data_len) = 0;

	/**
	 * Close the documet, as well as the file. If reparsing is used, the document will be kept.
	 *
	 * @param[in] bReParse		Whether reparsing is used.
	 */
	virtual void Close(int bReParse = 0) = 0;

	/**
	 * Set the password of standard encryption for opennig document.
	 *
	 * @param[in] password		The input password.
	 */
	virtual void InputPassword(const char* password) = 0;

	/** Get number of pages in this document. */
	virtual int GetPageCount() = 0;

	/**
	 * Get page object of a specified page index. Page index starts from zero for the first page.
	 *
	 * @param[in] page_index		Specifies the zero-based index of the page in the document.
	 * @return The specified page object.
	 */
	virtual IPDF_Page* GetPage(int page_index) = 0;

	/**
	 * Enumerate  page size in the document.
	 *
	 * @param[in] page_count			The page count.
	 * @param[out] page_width_array		Page width array to receiv the page width.
	 * @param[out] page_height_array	Page height array to receiv the page heigt..
	 */
	virtual void GetPageSizeQuickly(int page_count, float* page_width_array, float* page_height_array) = 0;

	/**
	 * Get page object of a specified page handler. Page handler is a pointer which point to a page dictionary.
	 *
	 * @param[in] page_handler			The page handler.
	 */
	virtual IPDF_Page* GetPageByHandler(PDF_PageHandler page_handler) = 0;
	
	/**
	 * Count the font number in the document.
	 *
	 * @return The total font number.
	 */
	virtual int CountExistFonts() = 0;

	/**
	 * Get a exist font information.
	 *
	 * @param[in] index			The font index (0 to CountExistFonts()).
	 * @param[out] facename		A buffer to receiv the font face name.
	 * @param[out] isEmbbed		A flag indicate whether font is embbedded in the doucument.
	 * @param[out] type			Font type flag.@see Font type IDs
	 * @param[out] code_type	Encodding type.
	 * @param[out] basefont		Base font name.
	 * @param[out] base type	Base font type.@see Font type IDs
	 * 
	 */
	virtual void GetExistFontInfo(int index, wchar_t facename[32], int* isEmbbed, int* type, int* code_type, wchar_t basefont[32], int* base_type) = 0;

	/**
	 * Add a Type1 base-14 font.
	 *
	 * @param[in] face_name				The font name.
	 * @param[in] encoding				Predefined font encoding.@see Predefined font encoding
	 * @return A PDF font.
	 */
	virtual IPDF_Font* AddStdFont(const char* face_name, int encoding) = 0; 

	/**
	 * Add a new font by specificed font file.
	 *
	 * @param[in] font_file				The font file path.
	 * @param[in] charset				Charset ID.@see Font charsets 
	 * @param[in] isVertical			Whether it's a vertical writing font. For CJK charsets only.
	 * @return A PDF font.
	 */
	virtual IPDF_Font* AddFont(const wchar_t* font_file, int charset, int isVertical = 0) = 0;
	/**
	 * Add a new font by specificed font file.
	 *
	 * @param[in] font_file				The font file path (utf8).
	 * @param[in] charset				Charset ID.@see Font charsets
	 * @param[in] isVertical			Whether it's a vertical writing font. For CJK charsets only.
	 * @return A PDF font.
	 */
	virtual IPDF_Font* AddFont(const char* font_file_utf8, int charset, int isVertical = 0) = 0;
#if _FXM_PLATFORM_ == _FXM_PLATFORM_WINDOWS_	

	/**
	 * Import a Windows font.
	 *
	 * @param[in] pLogFont			Points to a LOGFONT(WIN32) structure.
	 * @param[in] bVert				Vertical font or not.
	 * @param[in] bTranslateName	Whether we will do font name translating or not.
	 * @return A PDF font.
	 */
	virtual IPDF_Font* AddWinFont(LOGFONTW* pLogFont, int bVert = 0, int bTranslateName = 0) = 0;
	virtual IPDF_Font* AddWinFont(LOGFONTA* pLogFont, int bVert = 0, int bTranslateName = 0) = 0;
#endif
#if _FXM_PLATFORM_ == _FXM_PLATFORM_APPLE_	
	virtual IPDF_Font* AddMacFont(CTFontRef pFont, int bVert, int bTranslateName = 0, int charset_cjk = 0) = 0;
#endif
	/**
	 * Import a folder font on Android.
	 *
	 * @param[in] pFontInfo			Points to a IPDF_FolderFontInfo handler.
	 * @param[in] charset			Charset ID.@see Font charsets
	 * @return A PDF font.
	 */
	virtual IPDF_Font* AddFolderFont(IPDF_FolderFontInfo* pFontInfo, int charset) = 0;
	
	/**
	 * Import a font by spcificed font information.
	 *
	 * @param[in] face_name			The font face name.
	 * @param[in] charset			Charset ID.@see Font charsets
	 * @param[in] bVert				Vertical font or not.
	 * @return A PDF font.
	 *
	 * NOTE:Face name can be following:
	 * DengXian, DengXian Bold, DengXian Italic, DengXian Light,
	 * Microsoft YaHei, Microsoft YaHei UI,Microsoft YaHei Negreta, Microsoft YaHei UI Negreta,Microsoft YaHei UI Light,
	 * FangSong,SimHei,KaiTi, LiSu,SimSun,NSimSun,YouYuan
	 */
	virtual IPDF_Font* AddFontByFaceName(const char* face_name, int charset, int isVertical = 0) = 0;

	/** Whether the user has the owner permission of the document. */
	virtual int IsOwner() = 0;
	/** Get the user permissions. */
	virtual unsigned int GetPermission() = 0;

	/** Test whether the document is encrypted, 0 for not, 1 for encrypted */
	virtual int IsEncrypted() = 0;
	/** Get encryptor filter type */
	virtual int GetEncryptFilterType() = 0;

	/**
	 * Check whether the password is verified successfully.
	 *
	 * @param[in] password			The input password pointer.
	 * @param[in] pass_len			The length of the password.
	 * @param[in] bOwner			Whether check the owner password
	 * @return 0 for invalid password, 1 for password verified.
	 */
	virtual int CheckPassword(const char* password, int pass_len, int bOwner) = 0;

	virtual int		GetCryptInfo(int& cipher, const unsigned char*& buffer, int& keylen) = 0;
	virtual int		IsMetaDataEncrypted() = 0;
	/** Get the Page Organizer interfance*/
	virtual IPDF_PageOrganizer* GetPageOrganizer() = 0;
	/** Get the Page Designer interfance*/
	virtual IPDF_PageDesigner* GetPageDesigner() = 0;
	/** Get the Bookmark Tree interfance*/
	virtual IPDF_BookmarkTree* GetBookmarks() = 0;
	
	/** Get title */
	virtual const char* GetTitle() = 0;
	/** Get author */
	virtual const char* GetAuthor() = 0;
	/** Get creator */
	virtual const char* GetCreator() = 0;
	/** Get creation date */
	virtual const char* GetCreationDate() = 0;
	/** Gee last modified date */
	virtual const char* GetModifyDate() = 0;
	/** Get subject */
	virtual const char* GetSubject() = 0;
	/** Get productor */
	virtual const char* GetProductor() = 0;

	/**
	 * @brief Set new document title.
	 *
	 * @param[in] title		The new title.
	 *
	 */
	virtual void SetTitle(const char* title) = 0;

	/**
	 * @brief Set new document author.
	 *
	 * @param[in] author		The new author.
	 *
	 */
	virtual void SetAuthor(const char* author) = 0;

	/**
	 * @brief Set new document creator.
	 *
	 * @param[in] creator		The new creator.
	 *
	 */
	virtual void SetCreator(const char* creator) = 0;

	/**
	 * @brief Set creation date.
	 *
	 * @param[in] date		The new date.
	 *
	 */
	virtual void SetCreationDate(const char* date) = 0;

	/**
	 * @brief Set last modified date.
	 *
	 * @param[in] date		The new date.
	 *
	 */
	virtual void SetModifyDate(const char* date) = 0;

	/**
	 * @brief Set new document subject.
	 *
	 * @param[in] subject		The new subject.
	 *
	 */
	virtual void SetSubject(const char* subject) = 0;
	
	/**
	 * @brief Whether cross reference stream is used.
	 *
	 * @return 0 for no XRef stream used, 1 for XRef stream used.
	 */
	virtual int IsXRefStream() = 0;
	
	/**
	 * @brief Count the total number of named destination in the document.
	 *
	 * @return The number of named destination.
	 */
	virtual int CountNamedDests() = 0;

	/**
	 * @brief Get name of spcificed named destination.
	 *
	 * @param[in] index		Zero based index, range is 0 to CountNamedDests().
	 *
	 * @return The destination name.
	 */
	virtual const char* GetNamedDestName(int index) = 0;
};

/**
 * @name Creating flags for PDF creator.
 */
 /*@{*/

/** @brief Incremental. */
#define PDF_CREATE_INCREMENTAL		1
/** @brief No original. */
#define PDF_CREATE_NO_ORIGINAL		2
/** @brief Use progressive creator. */
#define PDF_CREATE_PROGRESSIVE		4
/** @brief Use object stream creator. */
#define PDF_CREATE_OBJECTSTREAM		8
/*@}*/
/** @brief PDF Creator Interface */
class IPDF_Creator
{
public:
	/** Release a creator */
	virtual void Release() = 0;

	/**
	 * @brief Initial a crator.
	 *
	 * @param[in] doc		The PDF document.
	 * @param[in] flags		The creating flags.@see Creating flags for PDF creator
	 * 
	 */
	virtual void Init(IPDF_Document* doc, int flags) = 0;

	/**
	 * Write the whole document into a new file (using local file name).
	 *
	 * @param[in] dest_file	The output filename(The length must less than 256).
	 * @param[in] pause			Pause object, optional.
	 * @param[in] pProgress		Progress object, optional.	
	 * @return Non-zero means success, otherwise failed.
	 */
	virtual int Create(const wchar_t* dest_file, IPDF_Pause* pause, IPDF_Progress* pProgress) = 0;
	virtual int Create(const char* dest_file_utf8, IPDF_Pause* pause, IPDF_Progress* pProgress) = 0;
	
	/**
	 * Set security settings using standard security handler only.
	 * Can't be used with incremental update.
	 *
	 * @param[in] permissions			The user permissions.
	 * @param[in] owner_pwd			The owner password.
	 * @param[in] user_pwd				The user password.
	 * @param[in] cipher				The cipher type, RC4 or AES.
	 * @param[in] keylen				The length of the document key.
	 * @param[in] isEncryptMetaData		Whether to encrypt the metadata.
	 */
	virtual int SetSecurity(unsigned int permissions, const char* owner_pwd, const char* user_pwd, int cipher, int keylen, int isEncryptMetaData) = 0;

	/**
	 * Update security permissions for Revision 5 and 6 handler (AES 256)
	 * @param[in] permissions		New permissions value.
	 * @param[in] owner_pwd			The owner password pointer.
	 * @param[in] user_pwd			The user password pointer.
	 * @param[in] cipher			The cipher type, RC4 or AES.
	 * @param[in] keylen			The length of the document key.
	 * @param[in] bEncryptMetadata	New EncryptMetadata value.
	 *
	 *	@return 1 for success, 0 for failur.
	 */
	virtual int UpdateSecurity(unsigned int permissions, const char* owner_pwd, const char* user_pwd, int cipher, int keylen, int isEncryptMetaData) = 0;

	/**
	 * Remove security settings with document. The output file will not be encrypted.
	 * Can't be used with incremental update.
	 *	@return 1 for success, 0 for failur.
	 */
	virtual int RemoveSecurity() = 0;
};
