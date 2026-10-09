#pragma once

class IPDF_Font;
class IPDF_Document;
class IPDF_Page;
class IPDF_Progress;
class IPDF_DIBitmap;
struct PDSDK_FloatRect;


/**
 * @name Art element types.
 */
 /*@{*/

/** @brief Unknow element type. */
#define PAGEART_ELEMENT_TYPE_UNKNOW				-1
/** @brief Background element of page. */
#define PAGEART_ELEMENT_TYPE_BACKGROUND			0
/** @brief Watermark element of page. */
#define PAGEART_ELEMENT_TYPE_WATERMARK			1
/** @brief Header and footer element of page. */
#define PAGEART_ELEMENT_TYPE_HEADERANDFOOTER	2
/** @brief Bates numbering element of page. */
#define PAGEART_ELEMENT_TYPE_BATES				3

/*@}*/

/**
 * @name Element source types.
 */
 /*@{*/

/** @brief Unknow source type. */
#define PAGEARTS_SOURCETYPE_UNKNOWN -1

/** @brief Text source. */
#define PAGEARTS_SOURCETYPE_TEXT	0
/** @brief Path source. */
#define PAGEARTS_SOURCETYPE_PATH	1
/** @brief PDF source. */
#define PAGEARTS_SOURCETYPE_PDF		2
/** @brief Image source. */
#define PAGEARTS_SOURCETYPE_IMGAGE	3

/*@}*/

/**
 * @name Unit types.
 */
 /*@{*/

/** @brief Inchies. */
#define UNIT_INCHES 		0
/** @brief Percent. */
#define UNIT_PERCENT 		1
/** @brief Centermeters. */
#define UNIT_CENTIMETERS 	2
/** @brief Millimeters. */
#define UNIT_MILLIMETERS 	3
/** @brief Picas. */
#define UNIT_PICAS		 	4
/** @brief Points. */
#define UNIT_POINTS		 	5

/*@}*/

/**
 * @name Alignment of background and watermark
 */
 /*@{*/

/** @brief Align top. */
#define PAGEARTS_ALIGTN_TOP 	0
/** @brief Align center in vertical. */
#define PAGEARTS_ALIGTN_VCENTER	1
/** @brief Align bottom. */
#define PAGEARTS_ALIGTN_BOTTOM	2
/** @brief Align left. */
#define PAGEARTS_ALIGTN_LEFT 	3
/** @brief Align center in horizontal. */
#define PAGEARTS_ALIGTN_HCENTER	4
/** @brief Align right. */
#define PAGEARTS_ALIGTN_RIGHT	5

/*@}*/

/**
 * @name Alignment of Header&Footer and BatesNumbering
 */
 /*@{*/

/** @brief Align left. */
#define PAGEARTS_ALIGTN_HF_LEFT		0
/** @brief Align center. */
#define PAGEARTS_ALIGTN_HF_CENTER	1
/** @brief Align right. */
#define PAGEARTS_ALIGTN_HF_RIGTH	2

/*@}*/

/**
 * @name Date formate
 */
 /*@{*/

#define DATEFORMAT_TYPE_SLASH_MD			0 /* m/d */
#define DATEFORMAT_TYPE_SLASH_MDYY			1 /* m/d/yy */
#define DATEFORMAT_TYPE_SLASH_MDYYYY		2 /* m/d/yyyy */
#define DATEFORMAT_TYPE_SLASH_MMDDYY		3 /* mm/dd/y */
#define DATEFORMAT_TYPE_SLASH_MMDDYYYY		4 /* mm/dd/yyyy */
#define DATEFORMAT_TYPE_SLASH_DMYY			5 /* d/m/yy */
#define DATEFORMAT_TYPE_SLASH_DMYYYY		6 /* d/m/yyyy */
#define DATEFORMAT_TYPE_SLASH_DDMMYY		7 /* dd/mm/yy */
#define DATEFORMAT_TYPE_SLASH_DDMMYYYY		8 /* dd/mm/yyyy */
#define DATEFORMAT_TYPE_SLASH_MMYY			9 /* mm/yy */
#define DATEFORMAT_TYPE_SLASH_MMYYYY		10 /* mm/yyyy */
#define DATEFORMAT_TYPE_DOT_MDYY			11 /* m.d.yy */
#define DATEFORMAT_TYPE_DOT_MDYYYY			12 /* m.d.yyyy */
#define DATEFORMAT_TYPE_DOT_MMDDYY			13 /* mm.dd.yy */
#define DATEFORMAT_TYPE_DOT_MMDDYYYY		14 /* mm.dd.yyyy */
#define DATEFORMAT_TYPE_DOT_MMYY			15 /* mm.yy */
#define DATEFORMAT_TYPE_DOT_DMYYYY			16 /* d.m.yyyy */
#define DATEFORMAT_TYPE_DOT_DDMMYY			17 /* dd.mm.yy */
#define DATEFORMAT_TYPE_DOT_DDMMYYYY		18 /* dd.mm.yyyy */
#define DATEFORMAT_TYPE_LINE_YYMMDD			19 /* yy-mm-dd */
#define DATEFORMAT_TYPE_LINE_YYYYMMDD		20 /* yyyy-mm-dd */

/*@}*/

/**
 * @name Page number format
 */
 /*@{*/

#define PAGENUMBERFORMAT_TYPE_NUMBER				0 /* 1 */
#define PAGENUMBERFORMAT_TYPE_NUMBER_OF_COUNT		1 /* 1 of n*/
#define PAGENUMBERFORMAT_TYPE_NUMBER_SLASH_COUNT	2 /* 1/n */
#define PAGENUMBERFORMAT_TYPE_PAGE_NUMBER			3 /* Page 1*/
#define PAGENUMBERFORMAT_TYPE_PAGE_NUMBER_OF_COUNT	4 /* Page 1 of n*/

/*@}*/

/** @brief PDF Page Orgnizer interface. */
class IPDF_PageOrganizer
{
public:
	/** Release page orgaizer. */
	virtual void Release() = 0;

	/**
	 * @brief Insert a blank page into document.
	 *
	 * @param[in] index		The zero-based page index, range is zero to page count.
	 * @param[in] width		Width of new blank page.
	 * @param[in] height	Height of new blank page.
	 *
	 */
	virtual void InsertBlankAt(int page_index, float width, float height) = 0;

	/**
	 * @brief Copy PDF pages from another PDF document and insert into document.
	 *
	 * @param[in] insert_at				The page index the pages start to insert.
	 * @param[in] doc_from				The document which pages will be copied.
	 * @param[in] pages_from_array		An array used to spcified page indexies whitch to by copied form source PDF.
	 * @param[in] array_len				Length of pages_from_array.
	 *
	 */
	virtual void InsertPagesFrom(int insert_at, const IPDF_Document* doc_from, int* pages_from_array, int array_len) = 0;

	/**
	 * @brief Delete PDF pages from the document.
	 *
	 * @param[in] start					The index which start to delete.
	 * @param[in] page_count			The page numbers to delete.
	 *
	 */
	virtual void DeletePages(int start, int page_count) = 0;

	/**
	 * @brief Replace PDF pages with another PDF document.
	 *
	 * @param[in] start				The page index the pages start to replace.
	 * @param[in] page_count		The page numbers will be replaced.
	 * @param[in] doc_from				The source document which pages will be copied.
	 * @param[in] pages_from_array		An array used to spcified page indexies whitch to by copied form source PDF.
	 * @param[in] array_len				Length of pages_from_array.
	 *
	 */
	virtual void RepalcePages(int start, int page_count, const IPDF_Document* doc_from, int* pages_from_array, int array_len) = 0;

	/**
	 * @brief Swap PDF pages .
	 *
	 * @param[in] page1		The page index.
	 * @param[in] page2		The other page index.
	 *
	 */
	virtual void SwapPages(int page1, int page2) = 0;

	/**
	 * @brief Extract PDF pages.
	 *
	 * @param[in] to_extract_pages_array		An array specified the page indexies to be extract.
	 * @param[in] array_len		Length of 'to_extract_pages_array'.
	 * @param[in] doc_dest		The destination PDF document to receive the extracted pages.
	 *
	 */
	virtual void ExtractPages(int* to_extarct_pages_array, int array_len, IPDF_Document* doc_dest) = 0;

	/**
	 * @brief Move PDF pages.
	 *
	 * @param[in] nMoveAt					The page index where the pages will move at.	
	 * @param[in] to_moved_pages_array		An array specified the page indexies to be movied.
	 * @param[in] len_pages_array			Length of 'to_moved_pages_array'.
	 *
	 */
	virtual void MovePages(int nMoveAt, const unsigned int* to_moved_pages_array, int len_pages_array) = 0;

	/**
	 * @brief Rotate PDF page.
	 *
	 * @param[in] iPage				The page index specified the page to be rotated.
	 * @param[in] nRotateFlag		Rotate flag. 0 for no rotate, 1 for  90 degree clockwise, 2 for 180 degree clockwise, 3 for 270 degree clockwise.
	 *
	 */
	virtual void RotatePage(int iPage, int nRotateFlag) = 0;

	/**
	 * @brief Reset page media box.
	 *
	 * @param[in] iPage		The page index specified the page to be setted the media box.
	 * @param[in] rect		The new media box.
	 *
	 */
	virtual void ResetMediaBox(int iPage, const PDSDK_FloatRect* rect) = 0;

	/**
	 * @brief Reset page crop box.
	 *
	 * @param[in] iPage		The page index specified the page to be setted the crop box.
	 * @param[in] rect		The new crop box.
	 *
	 */
	virtual void ResetCropBox(int iPage, const PDSDK_FloatRect* rect) = 0;

};

/** @brief PDF Page Designer interface. */
class IPDF_PageDesigner
{
public:
	/** @brief Release page designer. */
	virtual void Release() = 0;

	/** @brief Set preview mode. */
	virtual void SetPreviewMode(int bPrevViewOnly) = 0;
	/** @brief Get PDF document. */
	virtual IPDF_Document* GetDocument() = 0;
	
	virtual void ResetDoc(IPDF_Document* pDoc) = 0;
	/**
	 * @name Common settings for all art element types.
	 */
	 /*@{*/

	/**
	 * @brief Set font information to art elements.
	 *
	 * @param[in] element_type		The type of art elements. @see Art element types
	 * @param[in] font				The PDF font.
	 * @param[in] font_face_name	Font face name.
	 * @param[in] font_size			Font size.
	 * @param[in] charset			Charset ID. @see Font charsets 
	 * @param[in] underline			A flag indicate whether text is need underline.1 for underline, 0 for normal.
	 *
	 */
	virtual void SetFontInfo(int element_type, IPDF_Font* font, const wchar_t* font_face_name, float font_size, int charset, int underline) = 0;

	/**
	 * @brief Get font information from art elements.
	 *
	 * @param[in] element_type		The type of art elements. @see Art element types
	 * @param[out] font_size		Font size.
	 * @param[out] charset			Charset ID. @see Font charsets
	 * @param[out] underline		A flag indicate whether text is need underline. 1 for underline, 0 for normal.
	 *
	 */
	virtual IPDF_Font* GetFontInfo(int element_type, float* font_size, int* charset, int* underline) = 0;

	/**
	 * @brief Get font name.
	 *
	 * @param[in] element_type		The type of art elements. @see Art element types
	 * @return The font name.
	 */
	virtual const wchar_t* GetFontName(int element_type) = 0;

	/**
	 * @brief Set fixed-printing flag.
	 *
	 * @param[in] element_type		The type of art elements. @see Art element types
	 * @param[in] fixed_printin		The new fix-printing flag. 1 for fixed-printing, 0 for not.
	 *
	 */
	virtual void SetFixedPrint(int element_type, int fixed_printin) = 0;

	/** Test whether the element is fiexed-printing. */
	virtual int IsFixedPrint(int element_type) = 0;

	/**
	 * @brief Set color for background or watermark text.
	 *
	 * @param[in] element_type		The type of art elements. @see Art element types
	 * @param[in] color				The RGB color.Use the macro COLOR_MAKERGB to make a RGB format color.
	 *
	 */
	virtual void SetBackgroundOrTextColor(int element_type, unsigned int color) = 0;

	/**
	 * @brief Get background color or text color for other typed element.
	 *
	 * @param[in] element_type		The type of art elements. @see Art element types
	 * @return The RGB color. if equal ((DWORD)-1), means no stroke color be used.
	 */
	virtual unsigned int GetColor(int element_type) = 0;

	/**
	 * @brief Set page range to apply art element.
	 *
	 * @param[in] element_type		The type of art elements. @see Art element types
	 * @param[in] start_page		The start page index.
	 * @param[in] end_page			The end page index.
	 * @param[in] bOddPagesOnly		Odd pages only flag. 1 for odd pages only, 0 for not.
	 * @param[in] bEvenPagesOnly	Even pages only flag. 1 for even pages only, 0 for not.
	 *
	 */
	virtual void SetPageRange(int element_type, int start_page, int end_page, int bOddPagesOnly, int bEvenPagesOnly) = 0;

	/**
	 * @brief Get page range which will be apply art element.
	 *
	 * @param[in] element_type		The type of art elements. @see Art element types
	 * @param[out] start_page		Receiv start page index.
	 * @param[out] end_page			Receiv end page index.
	 * @param[out] bOddPagesOnly	Receiv odd pages only flag. 1 for odd pages only, 0 for not.
	 * @param[out] bEvenPagesOnly	Receiv even pages only flag. 1 for even pages only, 0 for not.
	 *
	 */
	virtual void GetPageRange(int element_type, int* start_page, int* end_page, int* bOddPagesOnly, int* bEvenPagesOnly) = 0;
	
	/*@}*/


	/**
	 * @name Settings for background and watermark element types.
	 */
	 /*@{*/

	/**
	 * @brief Set source for background or watermark.
	 *
	 * @param[in] element_type		The type of art elements. @see Art element types
	 * @param[in] type				The source type. @see Element source types.
	 * @param[in] text_watermark	The text of wartermark, not useful for background element.
	 * @param[in] file_source		The pdf or image file path.
	 * @param[in] pwd				The password for encrypted pdf.
	 * @param[in] page_index		The page index specificed which source page will be use as wartermark or backgound.
	 *
	 */
	virtual void SetSource(int element_type, int type, const wchar_t* text_watermark, const wchar_t* file_source, const char* pwd, int page_index) = 0;

	/** Get watermark text. */
	virtual const wchar_t* GetWatermarkText() = 0;

	/** Get source type. */
	virtual int GetSourceType(int element_type) = 0;
	/** Get source file path. */
	virtual const wchar_t* GetSourceFilePath(int element_type) = 0;
	/** Get source pdf page index.*/
	virtual int GetSourceIndex(int element_type) = 0;
	/** Get password of source pdf.*/
	virtual const char* GetPassword(int element_type) = 0;
	/**
	 * @brief Set source page index for background or watermark.
	 *
	 * @param[in] element_type		The type of art elements. @see Art element types
	 * @param[in] index		The page index specificed which source page will be use as wartermark or backgound.
	 *
	 */
	virtual void SetSourceIndex(int element_type, int index) = 0;

	/**
	 * @brief Set the position of element.
	 *
	 * @param[in] element_type		The type of art elements. @see Art element types
	 * @param[in] is_showontop		A flag indicate whether the art element is show on top or background. .
	 * @param[in] unit_type		Unit type. @see Unit types
	 * @param[in] align_h		Horizontal alignment. @see Alignment of background and watermark
	 * @param[in] space_h		The space on horizontal.
	 * @param[in] align_v		Vertical alignment. @see Alignment of background and watermark
	 * @param[in] space_v		The space on vertical.
	 *
	 */
	virtual void SetElementPosition(int element_type, int is_showontop, int unit_type, int align_h, float space_h, int align_v, float space_v) = 0;

	/**
	 * @brief Get the position of element.
	 *
	 * @param[in] element_type		The type of art elements. @see Art element types
	 * @param[out] is_showontop		A flag indicate whether the art element is show on top or background. .
	 * @param[out] unit_type		Unit type. @see Unit types
	 * @param[out] align_h		Horizontal alignment. @see Alignment of background and watermark
	 * @param[out] space_h		The space on horizontal.
	 * @param[out] align_v		Vertical alignment. @see Alignment of background and watermark
	 * @param[out] space_v		The space on vertical.
	 *
	 */
	virtual void GetElementPosition(int element_type, int* is_showontop, int* unit_type, int* align_h, float* space_h, int* align_v, float* space_v) = 0;

	/*@}*/

	/**
	 * @brief Set scale, rotate, opacity to art element.
	 *
	 * @param[in] element_type		The type of art elements. @see Art element types
	 * @param[in] scale			The zoom factor.
	 * @param[in] rotate		The rotation radian.
	 * @param[in] opacity		The opacity.(0-1.0)
	 *
	 */
	virtual void SetBasicSettings(int element_type, float scale, float rotate, float opacity) = 0;

	/**
	 * @brief Get scale, rotate, opacity setting from art element.
	 *
	 * @param[in] element_type		The type of art elements. @see Art element types
	 * @param[out] scale		Receiv zoom factor.
	 * @param[out] rotate		Receiv rotation radian.
	 * @param[out] opacity		Receiv opacity.(0-1.0)
	 *
	 */
	virtual void GetBasicSettings(int element_type, float* scale, float* rotate, float* opacity) = 0;

	/**
	 * @brief Set apperance setting to art element.
	 *
	 * @param[in] element_type		The type of art elements. @see Art element types
	 * @param[in] display_screen	A flag indicate whether the element can be display when PDF pages show in screen.
	 * @param[in] display_printing	A flag indicate whether the element can be display when print.
	 *
	 */
	virtual void SetApperanceSettings(int element_type, int display_screen, int display_printing) = 0;

	/**
	 * @brief Get apperance setting to art element.
	 *
	 * @param[in] element_type		 The type of art elements. @see Art element types
	 * @param[out] display_screen	 Receiv the display screen flag.
	 * @param[out] display_printing	 Receiv the display printing flag.
	 *
	 */
	virtual void GetApperanceSettings(int element_type, int* display_screen, int* display_printing) = 0;

	/**
	 * @brief Set current date to Header&Footer element.
	 *
	 * @param[in] nYear		The year.
	 * @param[in] nMonth	The month.
	 * @param[in] nDay		The day.
	 *
	 */
	virtual void SetCurDate(int nYear, int nMonth, int nDay) = 0;
	
	/**
	 * @name Settings for header&footer and batesNumbering element types.
	 */
	 /*@{*/

	/**
	 * @brief Set text margin to Header&Footer and bateNumbering element.
	 *
	 * @param[in] element_type			The type of art elements. @see Art element types
	 * @param[in] left_margin			Left margin of text.
	 * @param[in] right_margin			Right margin of text.
	 * @param[in] top_margin			Top margin of text.
	 * @param[in] bottom_margin			Bottom margin of text.
	 *
	 */
	virtual void SetTextMargins(int element_type, float left_margin, float right_margin, float top_margin, float bottom_margin) = 0;

	/**
	 * @brief Get text margins from Header&Footer and bateNumbering element.
	 *
	 * @param[in] element_type			The type of art elements. @see Art element types
	 * @param[out] left_margin			Receiv left margin of text.
	 * @param[out] right_margin			Receiv right margin of text.
	 * @param[out] top_margin			Receiv top margin of text.
	 * @param[out] bottom_margin		Receiv bottom margin of text.
	 *
	 */
	virtual void GetTextMargins(int element_type, float* left_margin, float* right_margin, float* top_margin, float* bottom_margin) = 0;

	/**
	 * @brief Set shrink flag to Header&Footer and bateNumbering element.
	 *
	 * @param[in] element_type			The type of art elements. @see Art element types
	 * @param[in] shrink				Shrink flag. 1 for shrink, 0 for not.
	 *
	 */
	virtual void SetShrink(int element_type, int shrink) = 0;

	/**
	 * @brief Get shrink flag from Header&Footer and bateNumbering element.
	 *
	 * @param[in] element_type			The type of art elements. @see Art element types
	 * @param[out] shrink				Receiv shrink flag. 1 for shrink, 0 for not.
	 *
	 */
	virtual void GetShrink(int element_type, int* shrink) = 0;

	/**
	 * @brief Set page number format to Header&Footer and bateNumbering element.
	 *
	 * @param[in] start_page_index			The start page index.
	 * @param[in] type_pagenumber			Specificate the format of page number. @see Page number format
	 *
	 */
	virtual void SetPageNumberSetting(int start_page_index, int type_pagenumber) = 0;

	/**
	 * @brief Set date format to Header&Footer and bateNumbering element.
	 *
	 * @param[in] type_date			Specificate the format of date. @see Date formate
	 *
	 */
	virtual void SetDateType(int type_date) = 0;

	/**
	 * @brief Set header text to Header&Footer and bateNumbering element.
	 *
	 * @param[in] element_type			The type of art elements. @see Art element types
	 * @param[in] left_text				Left header text.
	 * @param[in] center_text			Center header text.
	 * @param[in] right_text			Right header text.
	 *
	 */
	virtual void SetHeaderText(int element_type, const wchar_t* left_text, const wchar_t* center_text, const wchar_t* right_text) = 0;

	/**
	 * @brief Set footer text to Header&Footer and bateNumbering element.
	 *
	 * @param[in] element_type			The type of art elements. @see Art element types
	 * @param[in] left_text				Left footer text.
	 * @param[in] center_text			Center footer text.
	 * @param[in] right_text			Right footer text.
	 *
	 */
	virtual void SetFooterText(int element_type, const wchar_t* left_text, const wchar_t* center_text, const wchar_t* right_text) = 0;

	/** Get the left header text. */
	virtual const wchar_t* GetHeaderText_Left(int element_type) = 0;
	/** Get the center header text. */
	virtual const wchar_t* GetHeaderText_Center(int element_type) = 0;
	/** Get the right header text. */
	virtual const wchar_t* GetHeaderText_Right(int element_type) = 0;

	/** Get the left footer text. */
	virtual const wchar_t* GetFooterText_Left(int element_type) = 0;
	/** Get the center footer text. */
	virtual const wchar_t* GetFooterText_Center(int element_type) = 0;
	/** Get the right footer text. */
	virtual const wchar_t* GetFooterText_Right(int element_type) = 0;

	/*@}*/

	/**
	 * @name Settings for batesNumbering element types only.
	 */
	 /*@{*/

	/**
	 * @brief Set BatesNumbering format.
	 *
	 * @param[in] digits			The digits number of bates numbering.
	 * @param[in] start_number		The start number of bates numbering.
	 * @param[in] prefix			The prefix text of bates numbering.
	 * @param[in] suffix			The suffix text of bates numbering.
	 *
	 */
	virtual void SetBatesNumberingFormat(int digits, long long start_number, const wchar_t* prefix, const wchar_t* suffix) = 0;
	/** Get digits of batesnumbbering. */
	virtual int GetBatesNumberingDigits() = 0;
	/** Get start number of batesnumbbering. */
	virtual long long GetBatesNumberingStartNumber() = 0;
	/** Get prefix text of batesnumbbering. */
	virtual const wchar_t* GetBatesNumberingPrefix() = 0;
	/** Get suffix text of batesnumbbering. */
	virtual const wchar_t* GetBatesNumberingSuffix() = 0;

	/*@}*/

	/**
	 * @brief Test whether the background element is exist.
	 *
	 * @param[in] page_index		The page index specificate the page to be test the background element.
	 * @param[in] bLoadSettings		A flag indicate whether loading the backgound settings or not.
	 *
	 */
	virtual int IsExistBackground(int page_index, int bLoadSettings = 0) = 0;

	/**
	 * @brief Test whether the watermark element is exist.
	 *
	 * @param[in] page_index		The page index specificate the page to be test the watermark element.
	 * @param[in] bLoadSettings		A flag indicate whether loading the watermark settings or not.
	 *
	 */
	virtual int IsExistWatermark(int page_index, int bLoadSettings = 0) = 0;

	/**
	 * @brief Test whether the header&footer element is exist.
	 *
	 * @param[in] page_index		The page index specificate the page to be test the header&footer element.
	 * @param[in] bLoadSettings		A flag indicate whether loading the header&footer settings or not.
	 *
	 */
	virtual int IsExistHeaderAndFooter(int page_index, int bLoadSettings = 0) = 0;

	/**
	 * @brief Test whether the batesNumbering element is exist.
	 *
	 * @param[in] page_index		The page index specificate the page to be test the batesNumbering element.
	 * @param[in] bLoadSettings		A flag indicate whether loading the batesNumbering settings or not.
	 *
	 */
	virtual int IsExistBates(int page_index, int bLoadSettings = 0) = 0;

	/**
	 * @brief Insert art element to PDF page.
	 *
	 * @param[in] page				The page which will insert the art element.
	 * @param[in] page_index		The page index of page parameter.
	 * @param[in] element_type		The type of art elements. @see Art element types
	 *
	 */
	virtual int DoInsert(IPDF_Page* page, int page_index, int element_type) = 0;

	/**
	 * @brief Update art element to PDF page.
	 *
	 * @param[in] page				The page which will insert the art element.
	 * @param[in] page_index		The page index of page parameter.
	 * @param[in] element_type		The type of art elements. @see Art element types
	 *
	 */
	virtual int DoUpdate(IPDF_Page* page, int page_index, int element_type) = 0;

	/**
	 * @brief Remove art element from PDF page.
	 *
	 * @param[in] page				The page which will insert the art element.
	 * @param[in] element_type		The type of art elements. @see Art element types
	 *
	 */
	virtual int DoRemove(IPDF_Page* page, int element_type) = 0;

};

/** @brief PDF Combinner interface. */
class IPDF_Combinner
{
public:
	/** Release the PDF combinner. */
	virtual void Release() = 0;

	/**
	 * @brief Set the logical dpi with device.
	 *	The dpi will be used to convert image file to pdf page.
	 *
	 * @param[in] logx		The x-direction logical width.
	 * @param[in] logy		The y-direction logical height.
	 *
	 */
	virtual void SetDeviceDPI(int logx, int logy) = 0;

	/**
	 * @brief Add files to combinner and do combin.
	 *	
	 *
	 * @param[in] imgfile_or_pdffile		The image file path or pdf path (unicode).
	 * @param[in] bookmark_title			The bookmark title associate with image file or pdf file. 0 for no bookmark title.
	 * @param[in] password					The password for encrypted pdf.
	 *
	 * @return 1 for success, 0 for failure.
	 */
	virtual int StartCombin(const wchar_t* imgfile_or_pdffile, 
		const wchar_t* bookmark_title, const char* password = 0) = 0;

	/**
	 * @brief Add files to combinner and do combin.
	 *
	 *
	 * @param[in] imgfile_or_pdffile		The image file path or pdf path (utf8).
	 * @param[in] bookmark_title			The bookmark title associate with image file or pdf file. 0 for no bookmark title.
	 * @param[in] password					The password for encrypted pdf.
	 *
	 * @return 1 for success, 0 for failure.
	 */
	virtual int StartCombin(const char* imgfile_or_pdffile_utf8, 
		const char* bookmark_title_utf8, const char* password = 0) = 0;

	/**
	 * @brief Add files to combinner and do combin.
	 *
	 *
	 * @param[in] imgfile_or_pdffile		The image file path or pdf path (utf16).
	 * @param[in] bookmark_title			The bookmark title associate with image file or pdf file. 0 for no bookmark title.
	 * @param[in] password					The password for encrypted pdf.
	 *
	 * @return 1 for success, 0 for failure.
	 */
	virtual int StartCombin(const unsigned short* imgfile_or_pdffile_utf16,
		const unsigned short* bookmark_title_utf16, const char* password = 0) = 0;

	/**
	 * @brief End combin and build bookmark tree.
	 *
	 *
	 * @param[in] bBookmark		A flag indicate whether build the bookmark tree. 1 for building bookmark tree, 0 for not.
	 *
	 * @return 1 for success, 0 for failure.
	 */
	virtual int EndCombin(int bBookmark = 1) = 0;

	/**
	 * @brief Get the combinned PDF document.
	 *
	 * @return The combinned PDF document.
	 *
	 * NOTE: Do not release the returned document, the combinner will free it.
	 */
	virtual IPDF_Document* GetDestDoc() = 0;

	/**
	 * @brief Take the combinned PDF document out.
	 *
	 * @return The combinned PDF document.
	 *
	 * NOTE: Must release the returned document, the combinner doesn't handle it now.
	 */
	virtual IPDF_Document* TakeDestDoc() = 0;
};