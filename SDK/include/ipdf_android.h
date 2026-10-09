#pragma once
#include "ipdf_base.h"

class IPDF_FolderFontInfo
{
public:
	virtual int GetCharsetCount() = 0;
	virtual int GetCharset(int index) = 0;
	virtual int IsItalic() = 0; // 0 for normal, 1 for italic.
	virtual int IsBold() = 0; // 0 for normal, 1 for bold.
	virtual int IsFixedWidth() = 0; // 0 for normal, 1 for fiexed width.
	virtual int IsVertical() = 0; //0 for normal, 1 for vertical
	virtual const wchar_t* GetFamilyName() = 0; //get family name.
	virtual const wchar_t* GetFaceName() = 0; //get face name.

	virtual const wchar_t* GetPath() = 0;
};

class IPDF_AndroidFontEnum
{
public:
	virtual void Release() = 0;
	virtual void AddFontFolder(const char* font_folder) = 0;//"/system/fonts"
	virtual int EnumFonts() = 0;
	virtual int GetFontCount() = 0;
	virtual IPDF_FolderFontInfo* GetFontInfo(int index) = 0;
};