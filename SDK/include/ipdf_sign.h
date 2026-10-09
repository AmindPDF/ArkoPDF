#pragma once
#include "ipdf_base.h"
//class IPDF_DIBitmap;
class IPDF_Document;
class IPDF_Page;
class IPDF_PageObject;
class IPDF_DIBitmap;

class IPDF_DigitalSignCallback
{
public:
	virtual unsigned int EstimateSignedMessageLength(unsigned char* buf_data, unsigned long data_size) = 0;

/**
 * Make a RSA PKCS#7 SignedData message by the PCCERT_CONTEXT and corresponding private key from MS CAPI Store.
 * If the Digest Algorithm is not set, SHA1 will be the default one.
 * @param[in]		nDigestAlg			-	Digest algorithm : SHA1	: 0, MD5 : 3, SHA256 : 7.
 * @param[in]		pData2BSigned		-	A pointer to the buffer of data to be signed.
 * @param[in]		ulData2BSignedLen	-	The length of the data to be signed buffer.
 * @param[out]		pSignedData		-	A double pointer to the address of the PKCS#7 SingedData buffer, memory allocated by jrsysMSCryptoDll lib.
 * @param[out]		pSignedDataLen	-	A pointer to the address of the PKCS#7 SignedData buffer length allocated.
 * @param[in]		bIsContentDetached	-	A Boolean value to indicate if the data to be signed is included in the PKCS#7 SignedData message.
 *
 * @retval			0 means success, other for the error reason (Referenced with WinError.h and WinCrypt.h)
 *
 */
	virtual int EncodeSignedData(int nDigestAlg, unsigned char *pData2BSigned, unsigned long ulData2BSignedLen, unsigned char **ppSignedData, unsigned long *pSignedDataLen, bool bIsContentDetached) = 0;
};

// SignName Setting
#define SIGN_NAME_SHOW_NONE				0
#define SIGN_NAME_SHOW_IMAGE			1
#define SIGN_NAME_SHOW_COMMONNAME		2


//TextDirect
#define SIGN_SHOW_DETAIL_LEFT			0
#define SIGN_SHOW_DETAIL_RIGHT			1

/** @brief PDF Signer interface. */
class IPDF_Signer
{
public:
	/** Release PDF signer. */
	virtual void Release() = 0;
	
	/**
	 * @brief Create a signature pdf by jpg pictures.
	 *
	 * @param[in] jpg_file			The jpg file path(Unicode).
	 * @param[in] doc_signature		The PDF document use to save the signature picture.
	 * 
	 * @return 1 for success, 0 for failure
	 * NOTE: This method just create a pdf document that contain the signature pictures.
	 * to add a signature to pdf, use the signature pdf to add to pdf page by calling PlaceSignature().
	 */
	virtual int CreateSignature(const wchar_t* jpg_file, IPDF_Document* doc_signature) = 0;

	/**
	 * @brief Utf8 versiont for CreateSignature().
	 *
	 * @param[in] jpg_file			The jpg file path(UTF8).
	 * @param[in] doc_signature		The PDF document use to save the signature picture.
	 *
	 * @return 1 for success, 0 for failure
	 * NOTE: This method just create a pdf document that contain the signature pictures.
	 * to add a signature to pdf, use the signature pdf to add to pdf page by calling PlaceSignature().
	 */
	virtual int CreateSignature_UTF8(const char* jpg_file, IPDF_Document* doc_signature) = 0;

	/**
	 * @brief Place a signature to PDF page.
	 *
	 * @param[in] dest_page			The PDF page to place the signature.
	 * @param[in] left				Left of left-bottom corner.
	 * @param[in] bottom			bottom of left-bottom corner.
	 * @param[in] width				Specified width for signature.
	 * @param[in] height			Specified height for signature.
	 * @param[in] doc_signature		The PDF document created by CreateSignature();
	 *
	 * @return An image object.
	 *
	 */
	virtual IPDF_PageObject* PlaceSignature(IPDF_Page* dest_page, float left, float bottom, int width, int height, IPDF_Document* doc_signature) = 0;

	//Digital Sign
	virtual void SetDigtialSignInfo(const wchar_t* signer_name, const wchar_t* location, const wchar_t* distingushed_name, 
		const wchar_t* logo_path, const wchar_t* date, const wchar_t* reason, const wchar_t* signer_name_image) = 0;
	virtual void SetSignerImageOpacity(float opacity) = 0;
	virtual void SetDigitalSignTextDirect(int direct) = 0;
	virtual void SetDigitalSignNameStyle(int name_style) = 0;
	virtual void SetDigitalSignShowDetailLabel(int bShow) = 0;
	virtual void SetDigitalSignCallback(IPDF_DigitalSignCallback* callback) = 0;
	virtual IPDF_DIBitmap* GetDigitalSignaturePreview() = 0;

	//return 0 for success
	virtual int DoDigitaSign(IPDF_Page* page_tosigned, PDSDK_FloatRect rect, const wchar_t* signed_file_path) = 0;
};    