#ifndef BATCHEDFILES_IRCCLIENT_IRCCLIENT_BI
#define BATCHEDFILES_IRCCLIENT_IRCCLIENT_BI

#ifndef unicode
#define unicode
#endif
#include "windows.bi"
#include "win\shellapi.bi"
#include "win\shlwapi.bi"
#include "win\winsock2.bi"
#include "win\ws2tcpip.bi"

Type LPCLIENTDATA As Any Ptr

Type LPWSTRING As WString Ptr

Type _IrcPrefix
	Dim Nick As LPWSTRING
	Dim User As LPWSTRING
	Dim Host As LPWSTRING
End Type

Type IrcPrefix As _IrcPrefix

Type LPIRCPREFIX As _IrcPrefix Ptr

Type OnSendedRawMessageEvent As Sub(ByVal ClientData As LPCLIENTDATA, ByVal MessageText As LPWSTRING)
Type OnReceivedRawMessageEvent As Sub(ByVal ClientData As LPCLIENTDATA, ByVal MessageText As LPWSTRING)
Type OnServerErrorEvent As Sub(ByVal ClientData As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal Message As LPWSTRING)
Type OnServerMessageEvent As Sub(ByVal ClientData As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal IrcCommand As LPWSTRING, ByVal MessageText As LPWSTRING)
Type OnNoticeEvent As Sub(ByVal ClientData As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal NoticeText As LPWSTRING)
Type OnChannelNoticeEvent As Sub(ByVal ClientData As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal Channel As LPWSTRING, ByVal NoticeText As LPWSTRING)
Type OnChannelMessageEvent As Sub(ByVal ClientData As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal Channel As LPWSTRING, ByVal MessageText As LPWSTRING)
Type OnPrivateMessageEvent As Sub(ByVal ClientData As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal MessageText As LPWSTRING)
Type OnUserJoinedEvent As Sub(ByVal ClientData As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal Channel As LPWSTRING)
Type OnUserLeavedEvent As Sub(ByVal ClientData As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal Channel As LPWSTRING, ByVal MessageText As LPWSTRING)
Type OnNickChangedEvent As Sub(ByVal ClientData As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal NewNick As LPWSTRING)
Type OnTopicEvent As Sub(ByVal ClientData As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal Channel As LPWSTRING, ByVal TopicText As LPWSTRING)
Type OnQuitEvent As Sub(ByVal ClientData As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal MessageText As LPWSTRING)
Type OnKickEvent As Sub(ByVal ClientData As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal Channel As LPWSTRING, ByVal KickedUser As LPWSTRING)
Type OnInviteEvent As Sub(ByVal ClientData As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal ToUser As LPWSTRING, ByVal Channel As LPWSTRING)
Type OnPingEvent As Sub(ByVal ClientData As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal Server As LPWSTRING)
Type OnPongEvent As Sub(ByVal ClientData As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal Server As LPWSTRING)
Type OnModeEvent As Sub(ByVal ClientData As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal Channel As LPWSTRING, ByVal Mode As LPWSTRING, ByVal UserName As LPWSTRING)
Type OnCtcpPingRequestEvent As Sub(ByVal ClientData As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal ToUser As LPWSTRING, ByVal TimeValue As LPWSTRING)
Type OnCtcpTimeRequestEvent As Sub(ByVal ClientData As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal ToUser As LPWSTRING)
Type OnCtcpUserInfoRequestEvent As Sub(ByVal ClientData As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal ToUser As LPWSTRING)
Type OnCtcpVersionRequestEvent As Sub(ByVal ClientData As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal ToUser As LPWSTRING)
Type OnCtcpActionEvent As Sub(ByVal ClientData As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal ToUser As LPWSTRING, ByVal ActionText As LPWSTRING)
Type OnCtcpPingResponseEvent As Sub(ByVal ClientData As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal ToUser As LPWSTRING, ByVal TimeValue As LPWSTRING)
Type OnCtcpTimeResponseEvent As Sub(ByVal ClientData As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal ToUser As LPWSTRING, ByVal TimeValue As LPWSTRING)
Type OnCtcpUserInfoResponseEvent As Sub(ByVal ClientData As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal ToUser As LPWSTRING, ByVal UserInfo As LPWSTRING)
Type OnCtcpVersionResponseEvent As Sub(ByVal ClientData As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal ToUser As LPWSTRING, ByVal Version As LPWSTRING)

Type _IrcClient
	
	Const TenMinutesInMilliSeconds As DWORD = 10 * 60 * 1000
	Const MaxBytesCount As Integer = 512
	Const DefaultServerPort As Integer = 6667
	Const MaxReceivedBuffersCount As Integer = 1
	
	Dim AdvancedClientData As LPCLIENTDATA
	Dim CodePage As Integer
	Dim ClientVersion As LPWSTRING
	Dim ClientUserInfo As LPWSTRING
	
	Dim ClientNick As WString * (MaxBytesCount + 1)
	Dim ClientSocket As SOCKET
	
	Dim ClientRawBuffer As ZString * (MaxBytesCount + 1)
	Dim ClientRawBufferLength As Integer
	
	Dim RecvOverlapped As WSAOVERLAPPED
	Dim RecvBuf(MaxReceivedBuffersCount - 1) As WSABUF
	
	Dim hEvent As HANDLE
	
	Dim lpfnSendedRawMessageEvent As OnSendedRawMessageEvent
	Dim lpfnReceivedRawMessageEvent As OnReceivedRawMessageEvent
	Dim lpfnServerErrorEvent As OnServerErrorEvent
	Dim lpfnServerMessageEvent As OnServerMessageEvent
	Dim lpfnNoticeEvent As OnNoticeEvent
	Dim lpfnChannelNoticeEvent As OnChannelNoticeEvent
	Dim lpfnChannelMessageEvent As OnChannelMessageEvent
	Dim lpfnPrivateMessageEvent As OnPrivateMessageEvent
	Dim lpfnUserJoinedEvent As OnUserJoinedEvent
	Dim lpfnUserLeavedEvent As OnUserLeavedEvent
	Dim lpfnNickChangedEvent As OnNickChangedEvent
	Dim lpfnTopicEvent As OnTopicEvent
	Dim lpfnQuitEvent As OnQuitEvent
	Dim lpfnKickEvent As OnKickEvent
	Dim lpfnInviteEvent As OnInviteEvent
	Dim lpfnPingEvent As OnPingEvent
	Dim lpfnPongEvent As OnPongEvent
	Dim lpfnModeEvent As OnModeEvent
	Dim lpfnCtcpPingRequestEvent As OnCtcpPingRequestEvent
	Dim lpfnCtcpTimeRequestEvent As OnCtcpTimeRequestEvent
	Dim lpfnCtcpUserInfoRequestEvent As OnCtcpUserInfoRequestEvent
	Dim lpfnCtcpVersionRequestEvent As OnCtcpVersionRequestEvent
	Dim lpfnCtcpActionEvent As OnCtcpActionEvent
	Dim lpfnCtcpPingResponseEvent As OnCtcpPingResponseEvent
	Dim lpfnCtcpTimeResponseEvent As OnCtcpTimeResponseEvent
	Dim lpfnCtcpUserInfoResponseEvent As OnCtcpUserInfoResponseEvent
	Dim lpfnCtcpVersionResponseEvent As OnCtcpVersionResponseEvent
	
End Type

Type IrcClient As _IrcClient

Type LPIRCCLIENT As _IrcClient Ptr

Declare Function IrcClientStartup( _
	ByVal pIrcClient As IrcClient Ptr _
)As HRESULT

Declare Function IrcClientCleanup( _
	ByVal pIIrcClient As IrcClient Ptr _
)As HRESULT

Declare Function IrcClientOpenConnection Overload( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Server As WString Ptr, _
	ByVal Nick As WString Ptr _
) As Boolean

Declare Function IrcClientOpenConnection Overload( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Server As WString Ptr, _
	ByVal Port As WString Ptr, _
	ByVal Nick As WString Ptr, _
	ByVal User As WString Ptr, _
	ByVal Description As WString Ptr _
) As Boolean

Declare Function IrcClientOpenConnection Overload( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Server As WString Ptr, _
	ByVal Port As WString Ptr, _
	ByVal LocalAddress As WString Ptr, _
	ByVal LocalPort As WString Ptr, _
	ByVal Password As WString Ptr, _
	ByVal Nick As WString Ptr, _
	ByVal User As WString Ptr, _
	ByVal Description As WString Ptr, _
	ByVal Visible As Boolean _
) As Boolean

Declare Sub IrcClientCloseConnection( _
	ByVal pIrcClient As IrcClient Ptr _
)

Declare Function IrcClientStartReceiveDataLoop( _
	ByVal pIrcClient As IrcClient Ptr _
)As HRESULT

Declare Function IrcClientMsgStartReceiveDataLoop( _
	ByVal pIrcClient As IrcClient Ptr _
)As HRESULT

Declare Function IrcClientSendIrcMessage( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Channel As WString Ptr, _
	ByVal MessageText As WString Ptr _
) As Boolean

Declare Function IrcClientSendNotice( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Channel As WString Ptr, _
	ByVal NoticeText As WString Ptr _
) As Boolean

Declare Function IrcClientChangeTopic( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Channel As WString Ptr, _
	ByVal TopicText As WString Ptr _
) As Boolean

Declare Function IrcClientQuitFromServer Overload( _
	ByVal pIrcClient As IrcClient Ptr _
) As Boolean

Declare Function IrcClientQuitFromServer Overload( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal MessageText As WString Ptr _
) As Boolean

Declare Function IrcClientChangeNick( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Nick As WString Ptr _
) As Boolean

Declare Function IrcClientJoinChannel( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Channel As WString Ptr _
) As Boolean

Declare Function IrcClientPartChannel Overload( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Channel As WString Ptr _
) As Boolean

Declare Function IrcClientPartChannel Overload( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Channel As WString Ptr, _
	ByVal MessageText As WString Ptr _
) As Boolean

Declare Function IrcClientSendWho( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As WString Ptr _
) As Boolean

Declare Function IrcClientSendWhoIs( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As WString Ptr _
) As Boolean

Declare Function IrcClientSendAdmin Overload( _
	ByVal pIrcClient As IrcClient Ptr _
) As Boolean

Declare Function IrcClientSendAdmin Overload( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Server As WString Ptr _
) As Boolean

Declare Function IrcClientSendInfo Overload( _
	ByVal pIrcClient As IrcClient Ptr _
) As Boolean

Declare Function IrcClientSendInfo Overload( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Server As WString Ptr _
) As Boolean

Declare Function IrcClientSendAway Overload( _
	ByVal pIrcClient As IrcClient Ptr _
) As Boolean

Declare Function IrcClientSendAway Overload( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal MessageText As WString Ptr _
) As Boolean

Declare Function IrcClientSendIsON( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal NickList As WString Ptr _
) As Boolean

Declare Function IrcClientSendKick Overload( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Channel As WString Ptr, _
	ByVal UserName As WString Ptr _
) As Boolean

Declare Function IrcClientSendKick Overload( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Channel As WString Ptr, _
	ByVal UserName As WString Ptr, _
	ByVal MessageText As WString Ptr _
) As Boolean

Declare Function IrcClientSendInvite( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As WString Ptr, _
	ByVal Channel As WString Ptr _
) As Boolean

Declare Function IrcClientSendCtcpPingRequest( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As WString Ptr, _
	ByVal TimeValue As WString Ptr _
) As Boolean

Declare Function IrcClientSendCtcpTimeRequest( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As WString Ptr _
) As Boolean

Declare Function IrcClientSendCtcpUserInfoRequest( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As WString Ptr _
) As Boolean

Declare Function IrcClientSendCtcpVersionRequest( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As WString Ptr _
) As Boolean

Declare Function IrcClientSendCtcpAction( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As WString Ptr, _
	ByVal MessageText As WString Ptr _
) As Boolean

Declare Function IrcClientSendCtcpPingResponse( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As WString Ptr, _
	ByVal TimeValue As WString Ptr _
) As Boolean

Declare Function IrcClientSendCtcpTimeResponse( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As WString Ptr, _
	ByVal TimeValue As WString Ptr _
) As Boolean

Declare Function IrcClientSendCtcpUserInfoResponse( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As WString Ptr, _
	ByVal UserInfo As WString Ptr _
) As Boolean

Declare Function IrcClientSendCtcpVersionResponse( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As WString Ptr, _
	ByVal Version As WString Ptr _
) As Boolean

Declare Function IrcClientSendDccSend Overload( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As WString Ptr, _
	ByVal FileName As WString Ptr, _
	ByVal IPAddress As WString Ptr, _
	ByVal Port As WString Ptr _
) As Boolean

Declare Function IrcClientSendDccSend Overload( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As WString Ptr, _
	ByVal FileName As WString Ptr, _
	ByVal IPAddress As WString Ptr, _
	ByVal Port As WString Ptr, _
	ByVal FileLength As ULongInt _
) As Boolean

Declare Function IrcClientSendPing( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Server As WString Ptr _
) As Boolean

Declare Function IrcClientSendPong( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Server As WString Ptr _
) As Boolean

Declare Function IrcClientSendRawMessage( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal RawText As WString Ptr _
) As Boolean

#endif
