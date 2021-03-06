#ifndef BATCHEDFILES_IRCCLIENT_IBATCHEDFILESIRCCLIENT_BI
#define BATCHEDFILES_IRCCLIENT_IBATCHEDFILESIRCCLIENT_BI

#ifndef unicode
#define unicode
#endif
#include "windows.bi"
#include "win\ole2.bi"

Extern IID_IBatchedFilesIrcClient Alias "IID_IBatchedFilesIrcClient" As Const IID

Type IBatchedFilesIrcClient As IBatchedFilesIrcClient_

Type PBATCHEDFILESIRCCLIENT As IBatchedFilesIrcClient Ptr

Type IBatchedFilesIrcClientVtbl
	
	Dim QueryInterface As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal riid As const IID const Ptr, _
		ByVal ppvObject As Any Ptr Ptr _
	)As HRESULT
	
	Dim AddRef As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr _
	)As ULONG
	
	Dim Release As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr _
	)As ULONG
	
	Dim GetTypeInfoCount As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal pctinfo As UINT Ptr _
	)As HRESULT
	
	Dim GetTypeInfo As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal iTInfo As UINT, _
		ByVal lcid As LCID, _
		ByVal ppTInfo As ITypeInfo Ptr Ptr _
	)As HRESULT
	
	Dim GetIDsOfNames As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal riid As Const IID Const Ptr, _
		ByVal rgszNames As LPOLESTR Ptr, _
		ByVal cNames As UINT, _
		ByVal lcid As LCID, _
		ByVal rgDispId As DISPID Ptr _
	)As HRESULT
	
	Dim Invoke As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal dispIdMember As DISPID, _
		ByVal riid As Const IID Const Ptr, _
		ByVal lcid As LCID, _
		ByVal wFlags As WORD, _
		ByVal pDispParams As DISPPARAMS Ptr, _
		ByVal pVarResult As VARIANT Ptr, _
		ByVal pExcepInfo As EXCEPINFO Ptr, _
		ByVal puArgErr As UINT Ptr _
	)As HRESULT
	
	Dim GetClientVersion As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal pClientVersion As BSTR Ptr _
	)As HRESULT
	
	Dim SetClientVersion As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal ClientVersion As BSTR _
	)As HRESULT
	
	Dim GetClientUserInfo As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal pClientUserInfo As BSTR Ptr _
	)As HRESULT
	
	Dim SetClientUserInfo As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal ClientUserInfo As BSTR _
	)As HRESULT
	
	Dim GetCodePage As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal pCodePage As Long Ptr _
	)As HRESULT
	
	Dim SetCodePage As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal CodePage As Long _
	)As HRESULT
	
	Dim Startup As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr _
	)As HRESULT
	
	Dim Cleanup As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr _
	)As HRESULT
	
	Dim OpenConnection As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal Server As BSTR, _
		ByVal Port As Integer, _
		ByVal LocalAddress As BSTR, _
		ByVal LocalPort As Integer, _
		ByVal Password As BSTR, _
		ByVal Nick As BSTR, _
		ByVal User As BSTR, _
		ByVal ModeFlags As Long, _
		ByVal RealName As BSTR _
	)As HRESULT
	
	Dim CloseConnection As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr _
	)
	
	Dim MsgStartReceiveDataLoop As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr _
	)As HRESULT
	
	Dim ChangeNick As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal Nick As BSTR _
	)As HRESULT
	
	Dim QuitFromServer As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal QuitText As BSTR _
	)As HRESULT
	
	Dim JoinChannel As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal Channel As BSTR _
	)As HRESULT
	
	Dim PartChannel As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal Channel As BSTR, _
		ByVal MessageText As BSTR _
	)As HRESULT
	
	Dim RetrieveTopic As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal Channel As BSTR _
	)As HRESULT
	
	Dim SetTopic As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal Channel As BSTR, _
		ByVal TopicText As BSTR _
	)As HRESULT
	
	Dim SendKick As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal Channel As BSTR, _
		ByVal UserName As BSTR, _
		ByVal MessageText As BSTR _
	)As HRESULT
	
	Dim SendInvite As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal UserName As BSTR, _
		ByVal Channel As BSTR _
	)As HRESULT
	
	Dim SendPrivateMessage As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal MessageTarget As BSTR, _
		ByVal MessageText As BSTR _
	)As HRESULT
	
	Dim SendNotice As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal NoticeTarget As BSTR, _
		ByVal NoticeText As BSTR _
	)As HRESULT
	
	Dim SendWho As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal UserName As BSTR _
	)As HRESULT
	
	Dim SendWhoIs As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal UserName As BSTR _
	)As HRESULT
	
	Dim SendAdmin As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal Server As BSTR _
	)As HRESULT
	
	Dim SendInfo As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal Server As BSTR _
	)As HRESULT
	
	Dim SendAway As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal MessageText As BSTR _
	)As HRESULT
	
	Dim SendIsON As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal NickList As BSTR _
	)As HRESULT
	
	Dim SendPing As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal Server As BSTR _
	)As HRESULT
	
	Dim SendPong As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal Server As BSTR _
	)As HRESULT
	
	Dim SendCtcpPingRequest As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal UserName As BSTR, _
		ByVal TimeStamp As BSTR _
	)As HRESULT
	
	Dim SendCtcpTimeRequest As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal UserName As BSTR _
	)As HRESULT
	
	Dim SendCtcpUserInfoRequest As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal UserName As BSTR _
	)As HRESULT
	
	Dim SendCtcpVersionRequest As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal UserName As BSTR _
	)As HRESULT
	
	Dim SendCtcpAction As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal UserName As BSTR, _
		ByVal MessageText As BSTR _
	)As HRESULT
	
	Dim SendCtcpPingResponse As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal UserName As BSTR, _
		ByVal TimeStamp As BSTR _
	)As HRESULT
	
	Dim SendCtcpTimeResponse As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal UserName As BSTR, _
		ByVal TimeValue As BSTR _
	)As HRESULT
	
	Dim SendCtcpUserInfoResponse As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal UserName As BSTR, _
		ByVal UserInfo As BSTR _
	)As HRESULT
	
	Dim SendCtcpVersionResponse As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal UserName As BSTR, _
		ByVal Version As BSTR _
	)As HRESULT
	
	Dim SendDccSend As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal UserName As BSTR, _
		ByVal FileName As BSTR, _
		ByVal IPAddress As BSTR, _
		ByVal Port As Integer, _
		ByVal FileLength As ULongInt _
	)As HRESULT
	
	Dim SendRawMessage As Function( _
		ByVal this As IBatchedFilesIrcClient Ptr, _
		ByVal RawText As BSTR _
	)As HRESULT
	
End Type

Type IBatchedFilesIrcClient_
	Dim lpVtbl As IBatchedFilesIrcClientVtbl Ptr
End Type

#define IBatchedFilesIrcClient_QueryInterface(this, riid, ppvObject) (this)->lpVtbl->QueryInterface(this, riid, ppvObject)
#define IBatchedFilesIrcClient_AddRef(this) (this)->lpVtbl->AddRef(this)
#define IBatchedFilesIrcClient_Release(this) (this)->lpVtbl->Release(this)
#define IBatchedFilesIrcClient_GetTypeInfoCount(this, pctinfo) (this)->lpVtbl->GetTypeInfoCount(this, pctinfo)
#define IBatchedFilesIrcClient_GetTypeInfo(this, iTInfo, lcid, ppTInfo) (this)->lpVtbl->GetTypeInfo(this, iTInfo, lcid, ppTInfo)
#define IBatchedFilesIrcClient_GetIDsOfNames(this, riid, rgszNames, cNames, lcid, rgDispId) (this)->lpVtbl->GetIDsOfNames(this, riid, rgszNames, cNames, lcid, rgDispId)
#define IBatchedFilesIrcClient_Invoke(this, dispIdMember, riid, lcid, wFlags, pDispParams, pVarResult, pExcepInfo, puArgErr) (this)->lpVtbl->Invoke(this, dispIdMember, riid, lcid, wFlags, pDispParams, pVarResult, pExcepInfo, puArgErr)

#endif
