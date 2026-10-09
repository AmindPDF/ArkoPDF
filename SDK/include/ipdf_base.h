#pragma once
/**
 * @file
 * @brief Basic data structure definitions, such as matrix, bitmap and font.
 */

 /** @brief The PDSDK hanlder. Returned by PDF_LoadSDK().*/
typedef void* IPDF_SDK;

/** @brief The PDF page hanlder. Indicates the PDF page dictionary.*/
typedef void* PDF_PageHandler;

class IPDF_FileStream;
class IPDF_Document;
class IPDF_Matrix;
class IPDF_DIBitmap;
class IPDF_Combinner;
class IPDF_RenderContext;
class IPDF_ProgressiveRenderer;
class IPDF_Viewer;
class IPDF_FxgeDevice;
class IPDF_WindowsDevice;
class IPDF_Creator;
class IPDF_LogicalStructAnalyser;
class IPDF_AndroidFontEnum;
class IPDF_ParaUndoItem;
class iAmd_XmlElement;
class IPDF_PathData;
class IPDF_Paragraph;
class IPDF_PageObject;
class IPDF_Page;
class IPDF_Annot;
class IPDF_SystemCallbacks;
class IPDF_Signer;
class IPDF_AttachmentMgr;
class IPDF_FapiaoRecgnizer;
class IPDF_PhotoBookCreator;
/**
 * @name DIBitmap formats.
 */
 /*@{*/

/** @brief 24bpp RGB bitmap. Byte order: BGR. */
#define DIB_RGB	 	0
/** @brief24bpp RGB bitmap with extra alpha channel. Byte order: BGR + 8bppMask. */
#define DIB_RGBA 	1
/** @brief 32bpp ARGB bitmap. Byte order: BGRA. */
#define DIB_ARGB 	2
/** @brief 32bpp RGB bitmap. Byte order: BGR, 4th byte not used. */
#define DIB_RGB32 	3

/*@}*/

#ifdef _WIN32
#define PDSDKEXPORT __declspec(dllexport)
/**
 * @brief Load the PDF SDK instance.
 * @param[in] license		The license string which received from AmindPDF team.
 * @return The sdk handler. NULL for failure, means need a valid license string.
 * @see IPDF_SDK PDF_UnLoadSDK
 * @note Must call PDF_UnLoadSDK() to free the sdk handler.
 */
extern "C" PDSDKEXPORT int _stdcall PDF_LoadSDK(const char* license);

/**
 * @brief Free the PDF SDK instance.
 * @see IPDF_SDK PDF_LoadSDK
 */
extern "C" PDSDKEXPORT void PDF_UnLoadSDK();

/**
 * @brief Set the external font file folder.
 * @param[in] font_folder		The folder whitch contain font files(ttf, otf).
 * @note Not Necessarily to set the external font file, until the font file is not exist in your device.
 */
extern "C" PDSDKEXPORT void PDSDK_SetExtFontMapper(const char* font_folder);

/**
 * @brief Set the system callbacks.
 * @param[in] pSysCallbacks		The pointer of callbacks.
 * @note 
 */
extern "C" PDSDKEXPORT void PDSDK_SetSysCallbacks(IPDF_SystemCallbacks* pSysCallbacks);


/**
 * @brief Set the logfile path.
 * @param[in] logfile		file path of logfile.
 * @note
 */
extern "C" PDSDKEXPORT void PDSDK_SetLogPath(const char* logfile);

/**
 * @brief Add log to the logfile.
 * @param[in] log		The log infomation whitch you want add to the logfile.
 * @note
 */
extern "C" PDSDKEXPORT void PDSDK_Log(const char* log);

/**
 * @brief New a PDF document instance.
 * @return A PDF document instance. NULL for failure.
 * @see IPDF_Document PDSDK_ReleaseDocument
 * @note After new a PDF document instance, you should call IPDF_Document::Open() to open a pdf or IPDF_Document::NewBlankDoc() to create a blank document.
 * Finally call PDSDK_ReleaseDocument() to free the instance.
 * @see PDSDK_ReleaseDocument()
 */
extern "C" PDSDKEXPORT IPDF_Document* PDSDK_NewDocument();

/**
 * @brief Release a spcificed document instance.
 * @param[in] doc		A document instance.
 * @note After a document instance released, do not call any method in IPDF_Document interface.
 * @see PDSDK_NewDocument()
 */
extern "C" PDSDKEXPORT void PDSDK_ReleaseDocument(IPDF_Document* doc);

/**
 * @brief New a affine (linear) transformation matrix.
 *
 * A matrix defines six coefficients: a, b, c, d, e, f.
 * The transformation equations are:
 * dest_x = a * src_x + c * src_y + e;
 * dest_y = b * src_x + d * src_y + f;
 *
 * @param[in] a		The input coefficient a.
 * @param[in] b		The input coefficient b.
 * @param[in] c		The input coefficient c.
 * @param[in] d		The input coefficient d.
 * @param[in] e		The input coefficient e.
 * @param[in] f		The input coefficient f.
 * @return A matrix instance. NULL for failure.
 * @note Call IPDF_Matrix::Release() for free.
 */
extern "C" PDSDKEXPORT IPDF_Matrix* PDSDK_NewMatrix(float a = 1.f, float b = 0.f, float c = 0.f, float d = 1.f, float e = 0.f, float f = 0.f);

/**
 * @brief New a Device Independent Bitmap object with specificed bitmap format and size.
 * @param[in] format		The format of the bitmap.such as DIB_XXXX.
 * @param[in] width			The width of the bitmap.
 * @param[in] height		The height of the bitmap.
 * @return A DI bitmap object.NULL for failure.
 * @note Call IPDF_DIBitmap::Release() for free.
 */
extern "C" PDSDKEXPORT IPDF_DIBitmap* PDSDK_NewDIBitmap(int format, int width, int height);

/**
 * @brief Load a image file. Just for windows device.
 * @param[in] img_file		The image file path.
 * @return A DI bitmap object.NULL for failure.
 * @note Call IPDF_DIBitmap::Release() for free.
 */
extern "C" PDSDKEXPORT IPDF_DIBitmap* PDSDK_LoadDIBitmap(const wchar_t* img_file);

/**
 * @brief New a PDF file combiner instance.
 * @return A PDF file combiner instance. NULL for failure.
 * @note Call IPDF_Combinner::Release for free.
 */
extern "C" PDSDKEXPORT IPDF_Combinner* PDSDK_NewPDFCombinner();

/**
 * @brief New a PDF page rendering context.
 * @return A PDF page rendering context instance. NULL for failure.
 * @note Call IPDF_RenderContext::Release() for free.
 */
extern "C" PDSDKEXPORT IPDF_RenderContext* PDSDK_NewRenderContext();

/**
 * @brief New a PDF progressive renderer.
 * @return A PDF progressive renderer instance. NULL for failure.
 * @note Call IPDF_ProgressiveRenderer::Release() for free.
 */
extern "C" PDSDKEXPORT IPDF_ProgressiveRenderer* PDSDK_NewProgressiveRenderer();

/**
 * @brief New a PDF file creator.
 * @return A PDF file creator instance. NULL for failure.
 * @note Call IPDF_Creator::Release() for free.
 */
extern "C" PDSDKEXPORT IPDF_Creator* PDSDK_NewCreator();

/**
 * @brief New a PDF page viewer.
 * @return A PDF page viewer instance. NULL for failure.
 * @note Call IPDF_Viewer::Release() for free.
 */
extern "C" PDSDKEXPORT IPDF_Viewer* PDSDK_NewViewer();

/**
 * @brief New a Foxit 2-D Graphic Engine rendering device.
 * @return A Foxit 2-D Graphic Engine instance. NULL for failure.
 * @note Call IPDF_FxgeDevice::Release() for free.
 */
extern "C" PDSDKEXPORT IPDF_FxgeDevice* PDSDK_CreateFxgeDevice();

/**
 * @brief New a PDF windows device.
 * @return A PDF windows device instance. NULL for failure.
 * @note Call IPDF_WindowsDevice::Release() for free.
 */
extern "C" PDSDKEXPORT IPDF_WindowsDevice* PDSDK_CreateWindowsDevice();

/**
 * @brief Create a paragraph recognizer.
 * @return A paragraph recognizer instance. NULL for failure.
 * @note Call IPDF_LogicalStructAnalyser::Release() for free.
 */
extern "C" PDSDKEXPORT IPDF_LogicalStructAnalyser* PDSDK_CreateLogicalStructAnalyser();

/**
 * @brief New a paragraph undoitem.
 * @param[in] type		The paragraph editing operate typ: PDSDK_PARA_UNDOTYPE_XXXX.@see Paragraph undo types.
 * @return A paragraph undoitem. NULL for failure.
 * @note Call IPDF_ParaUndoItem::Release() for free.
 */
extern "C" PDSDKEXPORT IPDF_ParaUndoItem* PDSDK_CreateParaUndoItem(int type);


/**
* @brief  Build an XML element using specified memory data.
*
* @param[in] pBuffer			The input buffer.
* @param[in] size				The size in bytes of the input buffer.
* @return An XML element.
* @note The buffer can be discarded immediately after construction finished, because at this time,
* all data have been loaded into the element (and its descendant element).
*/
extern "C" PDSDKEXPORT iAmd_XmlElement* PDSDK_ParseXmlFromBuf(const void* pBuffer, unsigned int size);

/**
* @brief New an empty element, with a qualified namespace and tag name.
*
* @param[in] space			Qualified namespace, or empty if no namespace or default namespace is used.
* @param[in] tag_name		The tag name.
* @return An XML element.
*/
extern "C" PDSDKEXPORT iAmd_XmlElement* PDSDK_NewXmlElement(const char* space, const char* tag_name);


/**
 * @brief Create a font enumer for android platform.
 * @return A font enumer. NULL for failure.
 * @note Call IPDF_AndroidFontEnum::Release() for free.
 */
extern "C" PDSDKEXPORT IPDF_AndroidFontEnum* PDSDK_NewAndroidFontEnum();

/**
 * @brief Construct a PDF page object(Text, Path, Image) from XML.
 *
 * @param[in] pElement		The XML element.
 * @param[in] pPage			The PDF page to receive the constructed page object.
 * @param[in] xPos			The x component of position.
 * @param[in] yPos			The y component of position.
 * @return A page object. NULL for failure.
*/
extern "C" PDSDKEXPORT IPDF_PageObject* PDSDK_NewPageObjectFromXML(iAmd_XmlElement* pElement, IPDF_Page* pPage, float xPos, float yPos);

/**
 * @brief Construct a PDF annotation from XML.
 *
 * @param[in] pElement		The XML element.
 * @param[in] doc			The PDF document to receive the constructed annotation.
 * @return An PDF annotation. NULL for failure.
*/
extern "C" PDSDKEXPORT IPDF_Annot* PDSDK_NewAnnotFromXML(iAmd_XmlElement* pElement, IPDF_Document* doc);

/**
 * @brief Clone a PDF page dictionary.
 *
 * @param[in] page_handler		The source page dictionary.
 * @return An Cloned PDF page dictionary. NULL for failure.
*/
extern "C" PDSDKEXPORT PDF_PageHandler PDSDK_ClonePageHandler(PDF_PageHandler page_handler);

/**
 * @brief Free a PDF page dictionary.
 *
 * @param[in] page_handler		The page dictionary.
 * 
*/
extern "C" PDSDKEXPORT void PDSDK_DestroyPageHandlerClone(PDF_PageHandler page_handler);

/**
 * @brief Copy page dictionary.
 *
 * @param[in] dest_page_handler		The destination page dictionary.
 * @param[in] src					The source page dictionary.
 *
*/
extern "C" PDSDKEXPORT void PDSDK_CopyPageHandler(PDF_PageHandler dest_page_handler, PDF_PageHandler src);

/**
 * @brief Create a PDF signature interface.
 *
 * 
 * @return The signature interface.
 * @note Call IPDF_Signer::Release() for free.
*/
extern "C" PDSDKEXPORT IPDF_Signer* PDSDK_CreateSigner();

/**
 * @brief An one-pass ArcFour Encryption/Decryption.
 *
 * @param[in/out] data		The data buffer. It will be replaced with encrypted/decrypted data.
 * @param[in] size			The size of data in bytes.
 * @param[in] key			The key used to encrypt/decrypt data.
 * @param[in] keylen		Number of bytes in the key.
*/
extern "C" PDSDKEXPORT void PDSDK_ArcFourCryptBlock(unsigned char* data, unsigned int size, unsigned char* const key, unsigned int keylen);

/** A one-pass MD5 hash generation.
 * @param[in] input			The source data buffer.
 * @param[in] input_len		Data size in bytes.
 * @param[out] digest		16-byte buffer receiving the hash value.
 */
extern  "C" PDSDKEXPORT void PDSDK_MD5(const unsigned char* input, unsigned int input_len, unsigned char digest[16]);

/** A one-pass SHA256 hash generation.
 * @param[in] input			The source data buffer.
 * @param[in] size			Data size in bytes.
 * @param[out] digest		32-byte buffer receiving the hash value.
 */
extern  "C" PDSDKEXPORT void PDSDK_SHA256(const unsigned char* input, unsigned int input_len, unsigned char digest[32]);

/**
 * AES encryptor.
 *
 * @param[in] context		A pointer to a memory block provided by the caller.
 *							IMPORTANT: The memory block has to be at least 2048 bytes!!!!
 * @param[in] blocklen		Number of bytes in each data block. Must be 16, 24 or 32
 * @param[in] key			Buffer for key data.
 * @param[in] keylen		Number of bytes in key. Must be 16, 24 or 32
 * @param[in] iv		    Initial vector (IV) for the AES context.Size of this buffer must be same as block size.
 * @param[out] dest			Output buffer. The same of this buffer must be same or larger than input data.
 * @param[in] src			Source data buffer.
 * @param[in] size			Source data size, in bytes. It must be a multiplication of block size.
*/
extern  "C" PDSDKEXPORT void PDSDK_AESEncrypt(void* context,
	unsigned int blocklen, const unsigned char* key, unsigned int keylen, const unsigned char* iv,
	unsigned char* dest, const unsigned char* src, unsigned int size);

/**
 * AES decryptor.
 *
 * @param[in] context		A pointer to a memory block provided by the caller.
 *							IMPORTANT: The memory block has to be at least 2048 bytes!!!!
 * @param[in] blocklen		Number of bytes in each data block. Must be 16, 24 or 32
 * @param[in] key			Buffer for key data.
 * @param[in] keylen		Number of bytes in key. Must be 16, 24 or 32
 * @param[in] iv		    Initial vector (IV) for the AES context.Size of this buffer must be same as block size.
 * @param[out] dest			Output buffer. The same of this buffer must be same or larger than input data.
 * @param[in] src			Source data buffer.
 * @param[in] size			Source data size, in bytes. It must be a multiplication of block size.
*/
extern  "C" PDSDKEXPORT void PDSDK_AESDecrypt(void* context,
	unsigned int blocklen, const unsigned char* key, unsigned int keylen, const unsigned char* iv,
	unsigned char* dest, const unsigned char* src, unsigned int size);


extern "C" PDSDKEXPORT IPDF_AttachmentMgr* PDSDK_CreateAttachmentMgr(IPDF_Document* doc);
extern "C" PDSDKEXPORT IPDF_FapiaoRecgnizer* PDSDK_CreateFapiaoRecg();
extern  "C" PDSDKEXPORT IPDF_PhotoBookCreator* PDSDK_CreatePhotoBookCreator();
#else
extern "C" int PDF_LoadSDK(const char* license);
extern "C" void PDF_UnLoadSDK();
extern "C" void PDSDK_SetExtFontMapper(const char* font_folder);
extern "C" void PDSDK_SetLogPath(const char* logfile);
extern "C" void PDSDK_Log(const char* log);
extern "C" IPDF_Document* PDSDK_NewDocument();
extern "C" void PDSDK_ReleaseDocument(IPDF_Document* doc);
extern "C" IPDF_Matrix* PDSDK_NewMatrix(float a = 1.f, float b = 0.f, float c = 0.f, float d = 1.f, float e = 0.f, float f = 0.f);
extern "C" IPDF_DIBitmap* PDSDK_NewDIBitmap(int format, int width, int height);
extern "C" IPDF_Combinner* PDSDK_NewPDFCombinner();
extern "C" IPDF_RenderContext* PDSDK_NewRenderContext();
extern "C" IPDF_ProgressiveRenderer* PDSDK_NewProgressiveRenderer();
extern "C" IPDF_Creator* PDSDK_NewCreator();
extern "C" IPDF_LogicalStructAnalyser* PDSDK_CreateLogicalStructAnalyser();

/**
 * @brief Create a font enumer for android platform.
 * @return A font enumer. NULL for failure.
 * @note Call IPDF_AndroidFontEnum::Release() for free.
 */
extern "C" IPDF_AndroidFontEnum* PDSDK_NewAndroidFontEnum();
extern "C" IPDF_ParaUndoItem* PDSDK_CreateParaUndoItem(int type);
extern "C" IPDF_PathData* PDSDK_NewPathData();
//extern "C" IPDF_Paragraph* PDSDK_NewParagraphFromXML(iAmd_XmlElement* pElement, int nID, IPDF_Page* page, IPDF_LogicalStructAnalyser* pAnalyser, float xPos, float yPos);
//extern "C" IPDF_PageObject* PDSDK_NewPageObjectFromXML(iAmd_XmlElement* pElement, float xPos, float yPos);

extern "C" IPDF_Signer* PDSDK_CreateSigner();


//extern "C"  IPDF_AttachmentMgr* PDSDK_CreateAttachmentMgr(IPDF_Document* doc);
//extern "C"  IPDF_FapiaoRecgnizer* PDSDK_CreateFapiaoRecg();
extern  "C"  IPDF_PhotoBookCreator* PDSDK_CreatePhotoBookCreator();
#endif

/**
 * @brief An integer point.
 */
struct PDSDK_Point{
	/** The x component. */
	int x;

	/** The y component. */
	int y;
};

/**
 * @brief An float point.
 */
struct PDSDK_FloatPoint{
	/** The x component. */
	float x;

	/** The y component. */
	float y;
};


/**
 * @brief Defined as equivalent of Windows RECT structure, with some convenient function members.
 *
 * @note: This structure use Windows space where Y axis runs from top to bottom.
 */
struct PDSDK_Rect {
	/** The left */
	int			left;
	/** The top */
	int			top;
	/** The right */
	int			right;
	/** The bottom */
	int			bottom;

	/**
	 * Construct a rect.
	 */
	PDSDK_Rect() {
		left = bottom = right = top = 0;
	}

	/**
	 * Construct a rect with left-top and right bottom corners.
	 *
	 * @param[in] l		The left.
	 * @param[in] t		The top.
	 * @param[in] r		The right.
	 * @param[in] b		The bottom.
	 */
	PDSDK_Rect(int l, int t, int r, int b) {
		left = l; bottom = b; right = r; top = t;
	}

	/**
	 * Get the width of the rect.
	 *
	 * @return The width of the rect.
	 */
	int Width() {
		return right - left;
	}
	/**
	 * Get the height of the rect.
	 *
	 * @return the height of the rect.
	 */
	int Height() {
		return bottom - top;
	}
	/**
	 * Normalize the rect. Make sure left <= right, top <= bottom.
	 */
	void Normalize()
	{
		int temp;
		if (left > right) {
			temp = left;
			left = right;
			right = temp;
		}
		if (top > bottom) {
			temp = top;
			top = bottom;
			bottom = temp;
		}
	}
	/**
	 * Test whether the point is inside this rect.
	 *
	 * @param[in] x				The x coordinate.
	 * @param[in] y				The y coordinate.
	 * @return Non-zero means containing, otherwise no containing.
	 */
	int IsPointIn(int x, int y) {
		return (x >= left && x <= right && y >= top && y <= bottom);
	}
};

/**
 * @brief A float-point rectangle.
 *
 * A normalized float-point rectangle always has top larger than bottom.The corner of rectangle is left-bottom, right-top.
*/
struct PDSDK_FloatRect {
	/** The left. */
	float left;
	/** The bottom. */
	float bottom;
	/** The right. */
	float right;
	/** The top. */
	float top;

	/**
	 * Construct an empty rectangle.
	 */
	PDSDK_FloatRect() {
		left = bottom = right = top = 0;
	}

	/**
	 * Construct a rectangle with left-bottom and right-top corners.
	 *
	 * @param[in] l		The x-coordinate of left-bottom corner.
	 * @param[in] b		The y-coordinate of left-bottom corner.
	 * @param[in] r		The x-coordinate of right-top corner.
	 * @param[in] t		The y-coordinate of right-top corner.
	 */
	PDSDK_FloatRect(float l, float b, float r, float t) {
		left = l; bottom = b; right = r; top = t;
	}

	/** Return the width of the rectangle. */
	float Width() {
		return right - left;
	}
	/** Return the height of the rectangle. */
	float Height() {
		return top - bottom;
	}

	/**
	 * Normalize the rect. Make sure left <= right, and bottom <= top.
	 */
	void Normalize()
	{
		float temp;
		if (left > right) {
			temp = left;
			left = right;
			right = temp;
		}
		if (bottom > top) {
			temp = top;
			top = bottom;
			bottom = temp;
		}
	}
	/**
	 * Test whether a point is inside rectangle.
	 *
	 * @param[in] x				The x coordinate of the point.
	 * @param[in] y				The y coordinate of the point.
	 * @return Non-zero means containing, otherwise no containing.
	 */
	int IsPointIn(float x, float y) {
		return (x >= left && x <= right && y >= bottom && y <= top);
	}
};

/**
 * @brief A float-point quadrilateral.
 *
 * A normalized float-point quadrilateral always has top larger than bottom.
 * The corner order is left-bottom, right-bottom, right-top, left-top.
 * A quadrilateral in PDF is always a rotated rectangle.
*/

struct PDSDK_FloatBox {
	/** The x-coordinate of left-bottom corner. */
	float left_bottom_x;
	/** The y-coordinate of left-bottom corner. */
	float left_bottom_y;

	/** The x-coordinate of right-bottom corner. */
	float right_bottom_x;
	/** The y-coordinate of right-bottom corner. */
	float right_bottom_y;

	/** The x-coordinate of right-top corner. */
	float right_top_x;
	/** The y-coordinate of right-top corner. */
	float right_top_y;

	/** The x-coordinate of left-bottom corner. */
	float left_top_x;

	/** The y-coordinate of left-bottom corner. */
	float left_top_y;
};

/////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Destinations
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * @name Zoom mode for PDF destination.
 */
 /*@{*/

/**
 * @brief [left, top, zoom]. Spcificed the coordinates (left, top) as
 * the upper-left corner of the window and zoom factor whitch used to magnify
 * the contents of the page.
 * 
 */
#define PDF_ZOOM_XYZ					1

 /**
  * @brief Magnify contents just enough to fit the entire page
  * within the view window both horizontally and vertically.
  * 
  */
#define PDF_ZOOM_FITPAGE				2

/**
* @brief [top]. With the vertical coordinate top positioned at the top edge
* of the window and magnify contents of the page just enough to fit
* the entire width of the page within the window.
*/
#define PDF_ZOOM_FITHORZ				3

/**
 * @brief [left]. With the horizontal coordinate left positioned at the left edge
 * of the window and magnify contents of the page just enough to fit the
 * entire height of the page within the view window.
 */
#define PDF_ZOOM_FITVERT				4

 /**
  * @brief [left, bottom, right, top]. Magnify contents of the page just enough
  * to fit the rectangle specified by the coordinates left, bottom, right, and top
  * entirely within the view window both horizontally and vertically.
  */
#define PDF_ZOOM_FITRECT				5

/**
* @brief Mangify the contents of the page just enough to fit its bounding box entirely
* within the view window both horizontally and vertically.
*/
#define PDF_ZOOM_FITBBOX				6

/**
 * @brief With the vertical coordinate top positioned at the top edge of the window 
 * and magnify contents of the page just enough to fit the entire width 
 * of its bounding box within the window
 */
#define PDF_ZOOM_FITBHORZ				7

/**
* @brief With the horizontal coordinate left positioned at the left edge of the window
* and magnify contents of the page just enough to fit the entire height of its 
* bounding box within the view window.
*/
#define PDF_ZOOM_FITBVERT				8
/*@}*/

/** @brief PDF destination structure. */
struct PDSDK_Dest {
	/**The zero-based index of the page referred to.*/
	int page_index;
	/** The zoom mode of the destination. */
	int zoom_mode;
	/**The parameter of the destination*/
	float dest[4];
};

//*****************************************************************************
//* Matrix
//*****************************************************************************
/**
 * @brief The interface of affine transformation matrix.
 *
 * A matrix defines six coefficients: a, b, c, d, e, f.
 * The transformation equations are:
 * dest_x = a * src_x + c * src_y + e;
 * dest_y = b * src_x + d * src_y + f;
 */
class IPDF_Matrix
{
public:
	/** Release a matrix. */
	virtual void Release() = 0;
	
	/**
	 * Set the six input coefficients .
	 *
	 * @param[in] a	The input coefficient a.
	 * @param[in] b	The input coefficient b.
	 * @param[in] c	The input coefficient c.
	 * @param[in] d	The input coefficient d.
	 * @param[in] e	The input coefficient e.
	 * @param[in] f	The input coefficient f.
	 */
	virtual void Set(float a, float b, float c, float d, float e, float f) = 0;

	/** Get a coefficient. */
	virtual float GetA() = 0;
	/** Get b coefficient. */
	virtual float GetB() = 0;
	/** Get e coefficient. */
	virtual float GetC() = 0;
	/** Get d coefficient. */
	virtual float GetD() = 0;
	/** Get e coefficient. */
	virtual float GetE() = 0;
	/** Get f coefficient. */
	virtual float GetF() = 0;
	
	/**
	 * Scale the matrix.
	 *
	 * @param[in] sx			The x-direction scale coefficient.
	 * @param[in] sy			The y-direction scale coefficient.
	 * @param[in] bPrepended	If it's none-zero, a scaling matrix is concat at left side, otherwise concat at right side.
	 */
	virtual void Scale(float sx, float sy, int bPrepended = 0) = 0;

	/**
	 * Rotate the matrix.
	 *
	 * @param[in] radian		Rotation angle in radian.
	 * @param[in] bPrepended	If it's none-zero, a scaling matrix is concat at left side, otherwise concat at right side.
	 */
	virtual void Rotate(float radian, int bPrepended) = 0;

	/**
	 * Rotate the matrix at a specificed position.
	 *
	 * @param[in] radian		Rotation angle in radian.
	 * @param[in] x				The x coordinate of rotation point.
	 * @param[in] y				The y coordinate of rotation point.
	 * @param[in] bPrepended	If it's none-zero, a scaling matrix is concat at left side, otherwise concat at right side.
	 */
	virtual void RotateAt(float radian, float dx, float dy, int bPrepended) = 0;

	/**
	 * Transform a point.
	 *
	 * @param[in,out] point	The input point, and It receives the output transformed point.
	 */
	virtual void TransformPoint(PDSDK_FloatPoint* point) = 0;

	/**
	 * Transform a point.
	 *
	 * @param[in,out] point	The input point, and It receives the output transformed point.
	 */
	virtual void TransformPoint(PDSDK_Point* point) = 0;

	/**
	 * Transform a rectangle. 
	 *
	 * @param[in,out] rect		The input rectangle, and it receives the output transformed and normalized rectangle.
	 *
	 */
	virtual void TransformRect(PDSDK_FloatRect* rect) = 0;

	/**
	 * Transform a rectangle.
	 *
	 * @param[in,out] rect		The input rectangle, and it receives the output transformed and normalized rectangle.
	 *
	 */
	virtual void TransformRect(PDSDK_Rect* rect) = 0;

	/**
	 * Transform a quadrilateral.
	 *
	 * @param[in,out] box		The input quadrilateral, and it receives the output transformed and normalized quadrilateral.
	 *
	 */
	virtual void TransformBox(PDSDK_FloatBox* box) = 0;

	/**
	 * Get a matrix that transforms a source rectangle to dest rectangle.
	 *
	 * @param[in] dest_rect		The dest rectangle.
	 * @param[in] src_rect		The source rectangle.
	 */
	virtual void MatchRect(const PDSDK_FloatRect* dest_rect, const PDSDK_FloatRect* src_rect) = 0;
	
	/**
	 * Concatenate with another matrix.
	 *
	 * @param[in] matrix		The input matrix.
	 * @param[in] bPrepended	If it's none-zero, a scaling matrix is concat at left side, otherwise concat at right side.
	 */
	virtual void Concat(const IPDF_Matrix* matrix, int bPrepended = 0) = 0;

	/**
	 * Concatenate the inverse of another matrix.
	 *
	 * @param[in] matrix		The input matrix.
	 * @param[in] bPrepended	If it's none-zero, a scaling matrix is concat at left side, otherwise concat at right side.
	 */
	virtual void ConcatInverse(const IPDF_Matrix* matrix, int bPrepended = 0) = 0;

	/**
	 * Set the coefficients of the inverse of another matrix to this matrix.
	 *
	 * @param[in] m	The input matrix.
	 */
	virtual void SetReverse(const IPDF_Matrix* src_matrix) = 0;
	
	/**
	 * Translate the matrix.
	 *
	 * @param[in] x				The x-direction delta value.
	 * @param[in] y				The y-direction delta value.
	 * @param[in] bPrepended	If it's none-zero, a scaling matrix is concat at left side, otherwise concat at right side.
	 */
	virtual void Translate(float x, float y, int bPrepended = 0) = 0;
};

/**
 * @brief The RGB macro selects a red, green, blue color based on the arguments supplied.
 */
#define COLOR_MAKERGB(r, g, b)  ((r) | ((g) << 8) | ((b) << 16))

/** @brief Get the red component. */
#define COLOR_GetRValue(rgb) ((rgb) & 0xff)

/** @brief Get the green component. */
#define COLOR_GetGValue(rgb) (((rgb) >> 8) & 0xff)

/** @brief Get the blue component. */
#define COLOR_GetBValue(rgb) (((rgb) >> 16) & 0xff)


/** @brief Create a ARGB from the alpha, red, green, and blue components. */
#define COLOR_ARGB_MAKE(a,r,g,b) (((unsigned int)(a) << 24) | ((r) << 16) | ((g) << 8) | (b))

/** @brief Get the alpha component. */
#define COLOR_ARGB_A(argb) ((unsigned char)((argb) >> 24))

/** @brief Get the red component. */
#define COLOR_ARGB_R(argb) ((unsigned char)((argb) >> 16))

/** @brief Get the green component. */
#define COLOR_ARGB_G(argb) ((unsigned char)((argb) >> 8))

/** @brief Get the blue component. */
#define COLOR_ARGB_B(argb) ((unsigned char)(argb))


/**
 * @name Blending types.
 *
 */
 /*@{*/
/**
 * @brief Selects the source color, ignoring the backdrop.
 * 
 */
#define DIB_BLEND_NORMAL			0

 /**
  * @brief Multiplies the backdrop and source color values.
  * 
  */
#define DIB_BLEND_MULTIPLY			1

/**
* @brief Multiplies the complements of the backdrop and source color values, then complements the result.
* 
*/
#define DIB_BLEND_SCREEN			2

/**
 * @brief Multiplies or screens the colors, depending on the backdrop color value.
 * 
 */
#define DIB_BLEND_OVERLAY			3

 /**
  * @brief Selects the darker of the backdrop and source colors.
  * 
  */
#define DIB_BLEND_DARKEN			4

/**
* @brief Selects the lighter of the backdrop and source colors.
* 
*/
#define DIB_BLEND_LIGHTEN			5

/**
  * @brief Brightens the backdrop color to reflect the source color. 
  *
  */
#define DIB_BLEND_COLORDODGE		6

/**
* @brief Darkens the backdrop color to reflect the source color.
* 
*/
#define DIB_BLEND_COLORBURN			7

/**
* @brief Unsupport type.
*
*/
#define DIB_BLEND_UNSUPPORTED		-1

/*@}*/

/**
 * @brief Device Independent Bitmap Interface.
 * 
 */
class IPDF_DIBitmap
{
public:
	/** Release a bitmap. */
	virtual void Release() = 0;

	/**
	 * Clone a bitmap.
	 *
	 * @return A cloned bitmap.
	 */
	virtual IPDF_DIBitmap* Clone() = 0;

	/**
	 * Fill bitmap with specified color.
	 *
	 * @param[in] clr			The specified color to fill.
	 */
	virtual void Clear(unsigned int clr) = 0;
	/**
	 * @name Get basic bitmap information
	 */
	 /*@{*/

	 /** Get the width of the bitmap. */
	virtual int GetWidth() = 0;
	/** Get the height of the bitmap. */
	virtual int GetHeight() = 0;

	/**
	 * Get the number of BITS per pixel.
	 *
	 * @return The number of bits per pixel.
	 */
	virtual int GetBpp() = 0;

	/** Get the row pitch of the bitmap. */
	virtual unsigned int GetPitch() = 0;

	/**
	 * Get a pixels buffer.
	 *
	 * @return A pixels buffer for the bitmap.
	 */
	virtual unsigned char* GetPixels() = 0;
	/*@}*/

	/**
	 * Composite and blend source bitmap into this bitmap.
	 *
	 * @param[in] dest_left			The x-coordinate in destination bitmap.
	 * @param[in] dest_top			The y-coordinate in destination bitmap.
	 * @param[in] width				The area width to composite.
	 * @param[in] height			The area height to composite.
	 * @param[in] src_bitmap		The source bitmap.
	 * @param[in] src_left			The x-coordinate in source bitmap.
	 * @param[in] src_top			The y-coordinate in source bitmap.
	 * @param[in] blend_type		Blend type.
	 */
	virtual int	CompositeBitmap(int dest_left, int dest_top, int width, int height,
		const IPDF_DIBitmap* src_bitmap, int src_left, int src_top,
		int blend_type = DIB_BLEND_NORMAL) = 0;

	/**
	 * Stretch this bitmap into a new bitmap with different size.
	 * @param[in] dest_width	The width of the destination bitmap.
	 * @param[in] dest_height	The height of the destination bitmap.
	 * 
	 */
	virtual void StretchTo(int dest_width, int dest_height) = 0;

	/**
	 * Set pixel color.
	 * @param[in] x			The x-coordinate in bitmap.
	 * @param[in] y			The y-coordinate in bitmap.
	 * @param[in] color		The input pixel color.
	 */
	virtual void SetPixel(int x, int y, unsigned int color) = 0;

	/**
	 * Copy pixel data.
	 * @param[in/out] pOtherBuf			The pixel buffer to receive the pixel data.
	 * @param[in] len					Number of bytes for pOtherBuf.
	 * 
	 */
	virtual void CopyBuffer(unsigned char* pOtherBuf, unsigned int len) = 0;
	
};

/**
 * @name Basic font flags
 */
 /*@{*/
#define PDSDK_FONT_FIXED_PITCH				0x01
#define PDSDK_FONT_SERIF					0x02
#define PDSDK_FONT_SYMBOLIC					0x04
#define PDSDK_FONT_SCRIPT					0x08
#define PDSDK_FONT_ITALIC					0x40
#define PDSDK_FONT_BOLD						0x40000

/*@}*/


/**
 * @name Font charsets, same as defined in Win32 font charsets
 */
 /*@{*/
#define PDSDK_FONT_CIDFONT_CHARSET			0x100000
#define PDSDK_FONT_ANSI_CHARSET				0
#define PDSDK_FONT_DEFAULT_CHARSET			1
#define PDSDK_FONT_SYMBOL_CHARSET			2
#define PDSDK_FONT_SHIFTJIS_CHARSET			128 //Jpanese
#define PDSDK_FONT_HANGEUL_CHARSET			129 //Korean
#define PDSDK_FONT_GB2312_CHARSET			134 //Chinese simple
#define PDSDK_FONT_CHINESEBIG5_CHARSET		136 //Chinese trade
#define PDSDK_FONT_THAI_CHARSET				222 //Tailand
#define PDSDK_FONT_EASTEUROPE_CHARSET		238 //East Uropean
#define PDSDK_FONT_RUSSIAN_CHARSET			204 //Russian
#define PDSDK_FONT_GREEK_CHARSET			161 //Greek
#define PDSDK_FONT_TURKISH_CHARSET			162 //Tukish
#define PDSDK_FONT_VIETNAMESE_CHARSET		163 //Vietnamese
#define PDSDK_FONT_HEBREW_CHARSET			177 //Heberew
#define PDSDK_FONT_ARABIC_CHARSET			178 //Arabic
#define PDSDK_FONT_BALTIC_CHARSET			186 //Baltic
/*@}*/

/**
 * @name Font families and weights, same as defined in Win32
 */
 /*@{*/
#define PDSDK_FONT_FF_FIXEDPITCH	1
#define PDSDK_FONT_FF_ROMAN			(1<<4)
#define PDSDK_FONT_FF_SCRIPT		(4<<4)
#define PDSDK_FONT_FW_NORMAL		400
#define PDSDK_FONT_FW_BOLD			700
/*@}*/

/**
 * @name Font type IDs.
 */
 /*@{*/

/** @brief Type1. */
#define PDSDK_FONT_TYPE1			1
/** @brief Truetype. */
#define PDSDK_FONT_TRUETYPE			2
/** @brief Type3. */
#define PDSDK_FONT_TYPE3			3
/** @brief CID font. */
#define PDSDK_FONT_CIDFONT			4
/*@}*/

/**
 * @name CID Font charsets.
 */
 /*@{*/

/** @brief Unknown. */
#define PDSDK_CIDSET_UNKNOWN		0
/** @brief Adobe-GB1. */
#define PDSDK_CIDSET_GB1			1
/** @brief Adobe-CNS1. */
#define PDSDK_CIDSET_CNS1			2
/** @brief Adobe-Japan1. */
#define PDSDK_CIDSET_JAPAN1			3
/** @brief Adobe-Korea1. */
#define PDSDK_CIDSET_KOREA1			4
/** @brief Unicode. */
#define PDSDK_CIDSET_UNICODE		5
/*@}*/

/**
 * @name Font flags.
 */
 /*@{*/

/** @brief All glyphs have the same width. */
#define PDSDK_FONT_FIXEDPITCH		1
/** @brief Glyphs have serifs*/
#define PDSDK_FONT_SERIF			2
/** @brief Glyphs outside the Adobe standard Latin character set. */
#define PDSDK_FONT_SYMBOLIC			4
/** @brief Glyphs resemble cursive handwriting. */
#define PDSDK_FONT_SCRIPT			8
/** @brief Adobe standard Latin character set or a subset of it. */
#define PDSDK_FONT_NONSYMBOLIC		32
/** @brief Glyphs have dominant vertical strokes that are slanted. */
#define PDSDK_FONT_ITALIC			64
/** @brief No lowercase letters. */
#define PDSDK_FONT_ALLCAP			0x10000
/** @brief Both uppercase and lowercase letters. */
#define PDSDK_FONT_SMALLCAP			0x20000
/** @brief Force bold even at very small text sizes. */
#define PDSDK_FONT_FORCEBOLD		0x40000
/** @brief Additional font flag */
#define PDSDK_FONT_USEEXTERNATTR	0x80000
/*@}*/

/** @brief PDF font interface. */
class IPDF_Font
{
public:
	/**
	 * Get the font type.
	 *
	 * @return The font type.
	 * @see Font type IDs.
	 */
	virtual int GetType() = 0;
	/** Get the font flags. @see Font flags*/
	virtual int GetFlag() = 0;
	/** 
	 * Check whether the font is an embedded font. 
	 * @return Zero for Non-embbedded, otherwise embbedded.
	 * 
	 */
	virtual int IsEmbbedded() = 0; 

	/**
	 * Get the charset.
	 *
	 * @return The charset.
	 * @see Font charsets.
	 */
	virtual int GetCharset() = 0;

	/**
	 * Check whether the font is italic.
	 * @return Zero for normal, otherwise italic.
	 *
	 */
	virtual int IsItalic() = 0; 

	/**
	 * Check whether the font is bold.
	 * @return Zero for normal, otherwise bold.
	 *
	 */
	virtual int IsBold() = 0; 

	/**
	 * Check whether the font is vertical.
	 * @return Zero for normal, otherwise it is vertical.
	 *
	 */
	virtual int IsVertical() = 0; 

	/**
	 * Check whether the font is equle as other font.
	 * @return Zero for different, otherwise it is same font.
	 * @note same font means the PDF Font is a same one.
	 */
	virtual int Equal(IPDF_Font* other) = 0;

	/**
	 * Check whether the font is contain the specificed character.
	 * @param[in] ch	The unicode charcode.
	 * @return Zero means the font does not contain the character, otherwise contain.
	 */
	virtual int IsCharExist(wchar_t ch) = 0;
	/** Get family name. */
	virtual const wchar_t* GetFamilyName() = 0; 

	/** Get font face name. */
	virtual const wchar_t* GetFaceName() = 0; 

	/** Get base font name. */
	virtual const wchar_t* GetBaseFont() = 0; 

	/** Get base font name. */
	virtual const char* GetBaseFont_UTF8() = 0;
	/** Get font height. */
	virtual float GetFontHeight(float font_size) = 0;

	/**
	 * Get a character's PDF width.
	 *
	 * @param[in] charcode		Input a character code.
	 * @return The PDF width of the character.
	 */
	virtual float GetCharWidthF(unsigned long charcode) = 0;

	/**
	 * Find a subsitiation font.
	 *
	 * @param[in] charset		The input charset.
	 * @return The subsitiation font.
	 */
	virtual IPDF_Font* FindSubstFont(int charset) = 0;
};

#define NEEDTOPAUSE_NO	0
#define NEEDTOPAUSE_YES	1

/**
 * @brief Simple pause interface. Must be implemented by customer.
 */

class IPDF_Pause
{
public:
	/**
	 * Do we need to pause now ?
	 *
	 * @return Non-zero means we need, otherwise we need not.
	 */
    virtual int	NeedToPause() = 0;
};

/**
 * @brief Simple progress interface. Must be implemented by customer.
 */
class IPDF_Progress
{
public:
	/**
	 * Is the progress is canceled by user?
	 *
	 * @return Non-zero means cancel, otherwise not cacel.
	 */
	virtual int IsCancel() = 0;

	/**
	 * Set the range of progress.
	 *
	 * @param[in] min	The minimized value.
	 * @param[in] max	The maximized value.
	 * 
	 */
	virtual void SetRange(float min, float max) = 0;

	/**
	 * Set current position of progress.
	 *
	 * @param[in] pos	Current position.
	 *
	 */
	virtual void SetCurPos(float pos) = 0;
};

class IPDF_SystemCallbacks {
public :
	virtual const wchar_t* GetTempFolder(const wchar_t* szMyFolder) = 0;
	virtual const char* GetTempFolder_UTF8(const char* szMyFolder) = 0;
	virtual const wchar_t* GetTempFile(const wchar_t* szTempPath, const wchar_t* szPrefix, unsigned int nUnique) = 0;
	virtual const char* GetTempFile(const char* szTempPath, const char* szPrefix, unsigned int nUnique) = 0;
};

#define PDSDK_PT_LINETO				0x02
#define PDSDK_PT_BEZIERTO			0x04
#define PDSDK_PT_MOVETO				0x06
#define PDSDK_PT_TYPE				0x06
#define PDSDK_FILL_ALTERNATE		1
#define PDSDK_FILL_WINDING			2
typedef struct {
	float			m_PointX;
	float			m_PointY;
	int				m_Flag;
} PDSK_PATHPOINT;

struct PDSDK_PathData {
	int					m_PointCount;
	PDSK_PATHPOINT*		m_pPoints;
	int					m_FillType;//PDSDK_FILL_
	int					m_bStroke;//0 for no-strok

	IPDF_Matrix*	m_pMatrix;
};


/**
 * @name Caret direction flags.
 */
 /*@{*/

/** The previous caret. */
#define PDF_CARET_LEFT			-1
/** The next caret. */
#define PDF_CARET_RIGHT			1
/** The upon caret. */
#define PDF_CARET_UP			-2
/** The down caret. */
#define PDF_CARET_DOWN			2
/*@}*/

