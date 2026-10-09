#pragma once
class IPDF_AttachmentMgr
{
public:
	virtual void Release() = 0;
	virtual int BuildAttachmentList(int bBuildAnnotAttachment) = 0;
	virtual const wchar_t* GetName(int iFile) = 0;
	virtual const wchar_t* GetDescription(int iFile) = 0;
	//virtual const wchar_t* GetPath(int iFile) = 0;
	virtual const wchar_t* GetCreationDate(int iFile) = 0;
	virtual const wchar_t* GetModeDate(int iFile) = 0;
	virtual unsigned long long GetFileSize(int iFile) = 0;
	virtual int GetFileData(int iFile, unsigned char* buf_data, int data_size) = 0;
	virtual int IsDocLevel(int iFile) = 0;
	virtual int GetPageLocate(int iFile) = 0;//attachment annotation
	virtual int RemoveAttachment(int iFile) = 0;
	virtual int AddAttatchment(const wchar_t* file_path, const wchar_t* descript, const char* pdf_date_creation, const char* pdf_date_mod) = 0;
	virtual int SetDescription(int iFile, const wchar_t* description) = 0;
};