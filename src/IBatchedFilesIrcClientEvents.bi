#ifndef BATCHEDFILES_IRCCLIENT_IBATCHEDFILESIRCCLIENTEVENTS_BI
#define BATCHEDFILES_IRCCLIENT_IBATCHEDFILESIRCCLIENTEVENTS_BI

#include once "windows.bi"
#include once "win\ole2.bi"
#include once "win\oaidl.bi"
#include once "win\olectl.bi"
#include once "win\wtypes.bi"

Extern RID_IrcPrefix Alias "RID_IrcPrefix" As Const GUID

Extern IID_IBatchedFilesIrcClientEvents Alias "IID_IBatchedFilesIrcClientEvents" As Const IID

Type _IrcPrefix
	Dim Nick As BSTR
	Dim User As BSTR
	Dim Host As BSTR
End Type

Type IrcPrefix As _IrcPrefix

Type LPIRCPREFIX As _IrcPrefix Ptr

Type IBatchedFilesIrcClientEvents As IBatchedFilesIrcClientEvents_

Type PIBATCHEDFILESIRCCLIENTEVENTS As IBatchedFilesIrcClientEvents Ptr

Type IBatchedFilesIrcClientEventsVtbl
	
	Dim QueryInterface As Function( _
		ByVal this As IBatchedFilesIrcClientEvents Ptr, _
		ByVal riid As const IID const Ptr, _
		ByVal ppvObject As Any Ptr Ptr _
	)As HRESULT
	
	Dim AddRef As Function( _
		ByVal this As IBatchedFilesIrcClientEvents Ptr _
	)As ULONG
	
	Dim Release As Function( _
		ByVal this As IBatchedFilesIrcClientEvents Ptr _
	)As ULONG
	
	Dim GetTypeInfoCount As Function( _
		ByVal this As IBatchedFilesIrcClientEvents Ptr, _
		ByVal pctinfo As UINT Ptr _
	)As HRESULT
	
	Dim GetTypeInfo As Function( _
		ByVal this As IBatchedFilesIrcClientEvents Ptr, _
		ByVal iTInfo As UINT, _
		ByVal lcid As LCID, _
		ByVal ppTInfo As ITypeInfo Ptr Ptr _
	)As HRESULT
	
	Dim GetIDsOfNames As Function( _
		ByVal this As IBatchedFilesIrcClientEvents Ptr, _
		ByVal riid As Const IID Const Ptr, _
		ByVal rgszNames As LPOLESTR Ptr, _
		ByVal cNames As UINT, _
		ByVal lcid As LCID, _
		ByVal rgDispId As DISPID Ptr _
	)As HRESULT
	
	Dim Invoke As Function( _
		ByVal this As IBatchedFilesIrcClientEvents Ptr, _
		ByVal dispIdMember As DISPID, _
		ByVal riid As Const IID Const Ptr, _
		ByVal lcid As LCID, _
		ByVal wFlags As WORD, _
		ByVal pDispParams As DISPPARAMS Ptr, _
		ByVal pVarResult As VARIANT Ptr, _
		ByVal pExcepInfo As EXCEPINFO Ptr, _
		ByVal puArgErr As UINT Ptr _
	)As HRESULT
	
	Dim OnSendedRawMessage As Function( _
		ByVal this As IBatchedFilesIrcClientEvents Ptr, _
		ByVal IrcMessage As BSTR _
	)As HRESULT
	
	Dim OnReceivedRawMessage As Function( _
		ByVal this As IBatchedFilesIrcClientEvents Ptr, _
		ByVal IrcMessage As BSTR _
	)As HRESULT
	
	Dim OnServerError As Function( _
		ByVal this As IBatchedFilesIrcClientEvents Ptr, _
		ByVal pIrcPrefix As LPIRCPREFIX, _
		ByVal IrcMessage As BSTR _
	)As HRESULT
	
	Dim OnNumericMessage As Function( _
		ByVal this As IBatchedFilesIrcClientEvents Ptr, _
		ByVal pIrcPrefix As LPIRCPREFIX, _
		ByVal IrcNumericCommand As Long, _
		ByVal MessageText As BSTR _
	)As HRESULT
	
	Dim OnServerMessage As Function( _
		ByVal this As IBatchedFilesIrcClientEvents Ptr, _
		ByVal pIrcPrefix As LPIRCPREFIX, _
		ByVal IrcCommand As BSTR, _
		ByVal MessageText As BSTR _
	)As HRESULT
	
	Dim OnNotice As Function( _
		ByVal this As IBatchedFilesIrcClientEvents Ptr, _
		ByVal pIrcPrefix As LPIRCPREFIX, _
		ByVal NoticeText As BSTR _
	)As HRESULT
	
	Dim OnChannelNotice As Function( _
		ByVal this As IBatchedFilesIrcClientEvents Ptr, _
		ByVal pIrcPrefix As LPIRCPREFIX, _
		ByVal Channel As BSTR, _
		ByVal NoticeText As BSTR _
	)As HRESULT
	
	Dim OnChannelMessage As Function( _
		ByVal this As IBatchedFilesIrcClientEvents Ptr, _
		ByVal pIrcPrefix As LPIRCPREFIX, _
		ByVal Channel As BSTR, _
		ByVal MessageText As BSTR _
	)As HRESULT
	
	Dim OnPrivateMessage As Function( _
		ByVal this As IBatchedFilesIrcClientEvents Ptr, _
		ByVal pIrcPrefix As LPIRCPREFIX, _
		ByVal MessageText As BSTR _
	)As HRESULT
	
	Dim OnUserJoined As Function( _
		ByVal this As IBatchedFilesIrcClientEvents Ptr, _
		ByVal pIrcPrefix As LPIRCPREFIX, _
		ByVal Channel As BSTR _
	)As HRESULT
	
	Dim OnUserLeaved As Function( _
		ByVal this As IBatchedFilesIrcClientEvents Ptr, _
		ByVal pIrcPrefix As LPIRCPREFIX, _
		ByVal Channel As BSTR, _
		ByVal MessageText As BSTR _
	)As HRESULT
	
	Dim OnNickChanged As Function( _
		ByVal this As IBatchedFilesIrcClientEvents Ptr, _
		ByVal pIrcPrefix As LPIRCPREFIX, _
		ByVal NewNick As BSTR _
	)As HRESULT
	
	Dim OnTopic As Function( _
		ByVal this As IBatchedFilesIrcClientEvents Ptr, _
		ByVal pIrcPrefix As LPIRCPREFIX, _
		ByVal Channel As BSTR, _
		ByVal TopicText As BSTR _
	)As HRESULT
	
	Dim OnQuit As Function( _
		ByVal this As IBatchedFilesIrcClientEvents Ptr, _
		ByVal pIrcPrefix As LPIRCPREFIX, _
		ByVal MessageText As BSTR _
	)As HRESULT
	
	Dim OnKick As Function( _
		ByVal this As IBatchedFilesIrcClientEvents Ptr, _
		ByVal pIrcPrefix As LPIRCPREFIX, _
		ByVal Channel As BSTR, _
		ByVal KickedUser As BSTR _
	)As HRESULT
	
	Dim OnInvite As Function( _
		ByVal this As IBatchedFilesIrcClientEvents Ptr, _
		ByVal pIrcPrefix As LPIRCPREFIX, _
		ByVal ToUser As BSTR, _
		ByVal Channel As BSTR _
	)As HRESULT
	
	Dim OnPing As Function( _
		ByVal this As IBatchedFilesIrcClientEvents Ptr, _
		ByVal pIrcPrefix As LPIRCPREFIX, _
		ByVal Server As BSTR _
	)As HRESULT
	
	Dim OnPong As Function( _
		ByVal this As IBatchedFilesIrcClientEvents Ptr, _
		ByVal pIrcPrefix As LPIRCPREFIX, _
		ByVal Server As BSTR _
	)As HRESULT
	
	Dim OnMode As Function( _
		ByVal this As IBatchedFilesIrcClientEvents Ptr, _
		ByVal pIrcPrefix As LPIRCPREFIX, _
		ByVal Channel As BSTR, _
		ByVal Mode As BSTR, _
		ByVal UserName As BSTR _
	)As HRESULT
	
	Dim OnCtcpPingRequest As Function( _
		ByVal this As IBatchedFilesIrcClientEvents Ptr, _
		ByVal pIrcPrefix As LPIRCPREFIX, _
		ByVal ToUser As BSTR, _
		ByVal TimeValue As BSTR _
	)As HRESULT
	
	Dim OnCtcpTimeRequest As Function( _
		ByVal this As IBatchedFilesIrcClientEvents Ptr, _
		ByVal pIrcPrefix As LPIRCPREFIX, _
		ByVal ToUser As BSTR _
	)As HRESULT
	
	Dim OnCtcpUserInfoRequest As Function( _
		ByVal this As IBatchedFilesIrcClientEvents Ptr, _
		ByVal pIrcPrefix As LPIRCPREFIX, _
		ByVal ToUser As BSTR _
	)As HRESULT
	
	Dim OnCtcpVersionRequest As Function( _
		ByVal this As IBatchedFilesIrcClientEvents Ptr, _
		ByVal pIrcPrefix As LPIRCPREFIX, _
		ByVal ToUser As BSTR _
	)As HRESULT
	
	Dim OnCtcpAction As Function( _
		ByVal this As IBatchedFilesIrcClientEvents Ptr, _
		ByVal pIrcPrefix As LPIRCPREFIX, _
		ByVal ToUser As BSTR, _
		ByVal ActionText As BSTR _
	)As HRESULT
	
	Dim OnCtcpPingResponse As Function( _
		ByVal this As IBatchedFilesIrcClientEvents Ptr, _
		ByVal pIrcPrefix As LPIRCPREFIX, _
		ByVal ToUser As BSTR, _
		ByVal TimeValue As BSTR _
	)As HRESULT
	
	Dim OnCtcpTimeResponse As Function( _
		ByVal this As IBatchedFilesIrcClientEvents Ptr, _
		ByVal pIrcPrefix As LPIRCPREFIX, _
		ByVal ToUser As BSTR, _
		ByVal TimeValue As BSTR _
	)As HRESULT
	
	Dim OnCtcpUserInfoResponse As Function( _
		ByVal this As IBatchedFilesIrcClientEvents Ptr, _
		ByVal pIrcPrefix As LPIRCPREFIX, _
		ByVal ToUser As BSTR, _
		ByVal UserInfo As BSTR _
	)As HRESULT
	
	Dim OnCtcpVersionResponse As Function( _
		ByVal this As IBatchedFilesIrcClientEvents Ptr, _
		ByVal pIrcPrefix As LPIRCPREFIX, _
		ByVal ToUser As BSTR, _
		ByVal Version As BSTR _
	)As Function
	
End Type

Type IBatchedFilesIrcClientEvents_
	Dim lpVtbl As IBatchedFilesIrcClientEventsVtbl Ptr
End Type

#endif
