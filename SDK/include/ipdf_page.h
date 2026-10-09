#pragma once
#include "ipdf_base.h"
class IPDF_Document;
class IPDF_Matrix;
class IPDF_PageObject;
class IPDF_Paragraph;
class IPDF_Table;
class IPDF_AnnotList;
class IPDF_PageText;
class IPDF_PageOrgnaizer;
class IPDF_PageDesigner;
class IPDF_Caret;
class IPDF_Font;

/** The page handler indentity a page */
typedef void* PDF_PageHandler;

/** @brief PDF page Interface. */
class IPDF_Page
{
public:
	/** Release a page object */
	virtual void Release() = 0;
	
	/**
	 * @brief Get the page handler.
	 *
	 * @return The page handler.
	 */
	virtual PDF_PageHandler GetHandler() = 0;

	/** Parse all page contents */
	virtual void ParseContent() = 0;
	/** 
	 * @brief Check whether all contents has been parsed. 
	 * @return 0 for not parsed, 1 for parsed.
	 */
	virtual int IsParsed() = 0;
	
	/** Get the page width in user space. */
	virtual float GetWidth() = 0;
	/** Get the page height in user space. */
	virtual float GetHeight() = 0;

	/**
	 * Get page media box.
	 *
	 * @param[out] box			Received the media box data.
	 * 
	 */
	virtual void GetMediaBox(PDSDK_FloatRect* box) = 0;

	/**
	 * Set page media box.
	 *
	 * @param[in] box			The new media box.
	 *
	 */
	virtual void SetMediaBox(const PDSDK_FloatRect* box) = 0;

	/**
	 * Get page crop box.
	 *
	 * @param[out] box			Received the crop box data.
	 *
	 */
	virtual void GetCropBox(PDSDK_FloatRect* box) = 0;

	/**
	 * Set page crop box.
	 *
	 * @param[in] box			The new crop box data.
	 *
	 */
	virtual void SetCropBox(const PDSDK_FloatRect* box) = 0;

	/**
	 * Crop PDF page.
	 *
	 * @param[in] left			The left component of crop box.
	 * @param[in] bottom		The bottom component of crop box.
	 * @param[in] width			The width of crop box.
	 * @param[in] height		The height of crop box.
	 *
	 */
	virtual void Crop(float left, float bottom, float width, float height) = 0;

	/**
	 * Rotate PDF page.
	 *
	 * @param[in] rotate		The rotation factor:<br>.
	 *	0: No rotation.
	 *	1: 90 degree.
	 *	2: 180 degree.
	 *	3: 270 degree.
	 *
	 */
	virtual void Rotate(int rotate) = 0;

	/**
	 * @brief Get rotate degree.
	 *
	 * @return 0, 1, 2, 3.
	 */
	virtual int GetRotate() = 0;

	/**
	 * @brief Build a matrix from PDF user space to targeted device space.
	 *
	 * @param[out] out_matrix		Receives the transform matrix.
	 * @param[in] x					The x-coordinate in the device space.
	 * @param[in] y					The y-coordinate in the device space.
	 * @param[in] size_x			The x-direction size in the device space.
	 * @param[in] size_y			The y-direction size in the device space.
	 * @param[in] rotate			The rotation degrees.
	 *
	 */
	virtual void GetDisplayMatrix(IPDF_Matrix* out_matrix, int x, int y, int size_x, int size_y, int rotate) = 0;

	/** Build the content stream. */
	virtual void GenerateContent() = 0;

	/**
	 * @brief Whether the alpha is need when paint background.
	 *
	 * @return 0 for not need alpha, 2 for need alpha.
	 */
	virtual int BackgroundAlphaNeeded() = 0;

	/**
	 * @brief Get the unit of user space.
	 *
	 * @return A positive number giving the size of default user space units, in multiples of 1⁄72 inch. 
	 *
	 */
	virtual float GetUnit() = 0;

	/** Get page bounding box in user space.*/
	virtual PDSDK_FloatRect GetPageBBox() = 0;
	
	/**
	 * @brief Get number of page objects in this page.
	 *
	 * @return The number of page objects.
	 *
	 */
	virtual int CountPageObjects() = 0;

	/**
	 * @brief Get specificed page object by index.
	 *
	 * @param[in] index		The zero-based index, must less than CountPageObjects().
	 * 
	 * @return The page object specificed by index.
	 */
	virtual IPDF_PageObject* GetPageObject(int index) = 0;

	/**
	 * @brief Get the top layer page object by spcificed position.
	 *
	 * @param[in] point		The (x, y) point in PDF user space.
	 *
	 * @return The page object specificed by position.
	 */
	virtual IPDF_PageObject* GetPageObject(const PDSDK_FloatPoint* point) = 0;

	/**
	 * @brief Get the z-order of page objects in page.
	 *
	 * @param[in] pPageObj		The page object.
	 *
	 * @return A positive number giving the z-order.
	 */
	virtual int GetZOrder(IPDF_PageObject* pPageObj) = 0;

	/**
	 * @brief Add a new page object to page.
	 *
	 * @param[in] z_order		The z_order.
	 * @param[in] pPageObj		The new page object.
	 *
	 */
	virtual void AddPageObject(int z_order, IPDF_PageObject* pPageObj) = 0;

	/**
	 * @brief Add a text to page.
	 *
	 * @param[in] text			The text(unicode encodding).
	 * @param[in] xPos			The x component of text baseline.
	 * @param[in] yPos			The y component of text baseline.
	 * @param[in] font			The font for text.
	 * @param[in] size		The font size for text.
	 *
	 * @return The page object specificed by position.
	 */
	virtual IPDF_PageObject* AddText(const wchar_t* text, float xPos, float yPos, IPDF_Font* font, float font_size, unsigned int color) = 0;

	/**
	 * @brief Add a jpeg picture to page.
	 *
	 * @param[in] jpg_file		The jpeg file path(unicode encodding).
	 * @param[in] left			The x component of left-bottom corner.
	 * @param[in] bottom		The y component of left-bottom corner.
	 * @param[in] size_x		The x-direction size.
	 * @param[in] size_y		The y-direction size.
	 * @param[in] alpah			The opacity form 0 to 1.0.
	 *
	 * @return The page object specificed by position.
	 */
	virtual IPDF_PageObject* AddImage(const wchar_t* jpg_file, float left, float bottom, 
		float size_x, float size_y, float alpha, PDSDK_PathData* pClipPath = 0) = 0;

	/**
	 * @brief Add a jpeg picture to page.
	 *
	 * @param[in] jpg_file		The jpeg file path(utf8 encodding).
	 * @param[in] left			The x component of left-bottom corner.
	 * @param[in] bottom		The y component of left-bottom corner.
	 * @param[in] size_x		The x-direction size.
	 * @param[in] size_y		The y-direction size.
	 * @param[in] alpah			The opacity form 0 to 1.0.
	 *
	 * @return The page object specificed by position.
	 */
	virtual IPDF_PageObject* AddImage(const char* jpg_file_utf8, float left, float bottom, float size_x, float size_y, float alpha, PDSDK_PathData* pClipPath = 0) = 0;

	/**
	 * @brief Replace image.
	 *
	 * @param[in] pImgObj		The image object to be replaced.
	 * @param[in] jpg_file		The jpeg file used to repalce the image ogf pImgObj.
	 *
	 * return A new image object. 
	 */
	virtual IPDF_PageObject* ReplaceImage(IPDF_PageObject* pImgObj, const wchar_t* jpg_file) = 0;

	/**
	 * @brief Add grpahic.
	 *
	 * @param[in] line_width		Line width.
	 * @param[in] stroke_color		Stroke color.
	 * @param[in] fill_color		Fill color.
	 * @param[in] points			The(x,y) pair points array.
	 * @param[in] point_flag		Flag of (x,y)pair point.
	 * @param[in] point_count		Point count.
	 * return A new page object.
	 */
	virtual IPDF_PageObject* AddPath(float line_width, unsigned int stroke_color, unsigned int fill_color, float* points, int* point_flag, int point_count) = 0;

	/** Delete page object. */
	virtual void DeletePageObject(IPDF_PageObject* object) = 0;

	/** Send page object to background. */
	virtual void SendObjToBack(IPDF_PageObject* obj) = 0;

	/** Bring page object to front. */
	virtual void BringObjToFront(IPDF_PageObject* obj) = 0;

	/**
	 * @brief Move page object to specificed z-order.
	 *
	 * @param[in] pPageObj		Page object to be moved.
	 * @param[in] move_to		The destinat z-order.
	 * 
	 */
	virtual void MovePageObject(IPDF_PageObject* pPageObj, int move_to) = 0;

	/** Load the annotaionn list. */
	virtual IPDF_AnnotList* LoadAnnotList() = 0;
	
	/** Load the text page. */
	virtual IPDF_PageText* GetPageText() = 0;


	//Trailmark
	virtual int ExistTrailmark() = 0;
	virtual int AddTrailmark(const wchar_t* trail_tip, IPDF_Font* pFont, float font_size, const char* url, float trail_width, float trail_height) = 0;//url:amdpdf:buylink
	virtual int AddTrailmark(const char* trail_tip_utf8, IPDF_Font* pFont, float font_size, const char* url, float trail_width, float trail_height) = 0;//url:amdpdf:buylink
	virtual int AddTrailmark2(const wchar_t* trail_text, IPDF_Font* pFont, float font_size, const char* url, float scale, unsigned int clrText, float opacity) = 0;//url:amdpdf:buylink,clrText rgb
	virtual int AddTrailmark2(const char* trail_text, IPDF_Font* pFont, float font_size, const char* url, float scale, unsigned int clrText, float opacity) = 0;//url:amdpdf:buylink
	virtual int RemoveTrailmark() = 0;
	virtual int PonitInTrailmark(float x, float y) = 0;


	/** Lock page */
	virtual int LockPage() = 0;

	/** Unlock page */
	virtual int UnlockPage() = 0;


	/** Get the placed signature at the point (x, y). */
	virtual IPDF_PageObject* GetPlaceSignature(float x, float y) = 0;
};