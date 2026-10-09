#pragma once

class IPDF_Document;
class IPDF_Page;
class IPDF_Progress;

class IPDF_PhotoBookCreator 
{
public:
	virtual void Release() = 0;
	virtual void Init(float paper_width, float paper_height, int cols, int rows, 
		float margin_h, float margin_v, float space_photos_h, float space_photos_v, float photo_ratio) = 0;
	virtual void AddImage(const wchar_t* img_file, int org_pix_width, int org_pix_height) = 0;
	virtual void AddImage(const char* img_file_utf8, int org_pix_width, int org_pix_height) = 0;
	virtual void BuildPhotoBook(IPDF_Progress* pProgress=0) = 0;
	virtual IPDF_Document* GetPDDoc(int bTake) = 0;
};