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

Type IrcPrefix
	Dim Nick As WString Ptr
	Dim User As WString Ptr
	Dim Host As WString Ptr
End Type

Type SendedRawMessageEvent As Sub(ByVal ClientData As Any Ptr, ByVal MessageText As WString Ptr)
Type ReceivedRawMessageEvent As Sub(ByVal ClientData As Any Ptr, ByVal MessageText As WString Ptr)
Type ServerErrorEvent As Sub(ByVal ClientData As Any Ptr, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal Message As WString Ptr)
Type ServerMessageEvent As Sub(ByVal ClientData As Any Ptr, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal IrcCommand As WString Ptr, ByVal MessageText As WString Ptr)
Type NoticeEvent As Sub(ByVal ClientData As Any Ptr, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal NoticeText As WString Ptr)
Type ChannelNoticeEvent As Sub(ByVal ClientData As Any Ptr, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal Channel As WString Ptr, ByVal NoticeText As WString Ptr)
Type ChannelMessageEvent As Sub(ByVal ClientData As Any Ptr, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal Channel As WString Ptr, ByVal MessageText As WString Ptr)
Type PrivateMessageEvent As Sub(ByVal ClientData As Any Ptr, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal MessageText As WString Ptr)
Type UserJoinedEvent As Sub(ByVal ClientData As Any Ptr, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal Channel As WString Ptr)
Type UserLeavedEvent As Sub(ByVal ClientData As Any Ptr, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal Channel As WString Ptr, ByVal MessageText As WString Ptr)
Type NickChangedEvent As Sub(ByVal ClientData As Any Ptr, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal NewNick As WString Ptr)
Type TopicEvent As Sub(ByVal ClientData As Any Ptr, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal Channel As WString Ptr, ByVal TopicText As WString Ptr)
Type QuitEvent As Sub(ByVal ClientData As Any Ptr, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal MessageText As WString Ptr)
Type KickEvent As Sub(ByVal ClientData As Any Ptr, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal Channel As WString Ptr, ByVal KickedUser As WString Ptr)
Type InviteEvent As Sub(ByVal ClientData As Any Ptr, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal ToUser As WString Ptr, ByVal Channel As WString Ptr)
Type PingEvent As Sub(ByVal ClientData As Any Ptr, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal Server As WString Ptr)
Type PongEvent As Sub(ByVal ClientData As Any Ptr, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal Server As WString Ptr)
Type ModeEvent As Sub(ByVal ClientData As Any Ptr, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal Channel As WString Ptr, ByVal Mode As WString Ptr, ByVal UserName As WString Ptr)
Type CtcpPingRequestEvent As Sub(ByVal ClientData As Any Ptr, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal ToUser As WString Ptr, ByVal TimeValue As WString Ptr)
Type CtcpTimeRequestEvent As Sub(ByVal ClientData As Any Ptr, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal ToUser As WString Ptr)
Type CtcpUserInfoRequestEvent As Sub(ByVal ClientData As Any Ptr, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal ToUser As WString Ptr)
Type CtcpVersionRequestEvent As Sub(ByVal ClientData As Any Ptr, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal ToUser As WString Ptr)
Type CtcpActionEvent As Sub(ByVal ClientData As Any Ptr, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal ToUser As WString Ptr, ByVal ActionText As WString Ptr)
Type CtcpPingResponseEvent As Sub(ByVal ClientData As Any Ptr, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal ToUser As WString Ptr, ByVal TimeValue As WString Ptr)
Type CtcpTimeResponseEvent As Sub(ByVal ClientData As Any Ptr, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal ToUser As WString Ptr, ByVal TimeValue As WString Ptr)
Type CtcpUserInfoResponseEvent As Sub(ByVal ClientData As Any Ptr, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal ToUser As WString Ptr, ByVal UserInfo As WString Ptr)
Type CtcpVersionResponseEvent As Sub(ByVal ClientData As Any Ptr, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal ToUser As WString Ptr, ByVal Version As WString Ptr)

Type IrcClient
	
	Const TenMinutesInMilliSeconds As DWORD = 10 * 60 * 1000
	Const MaxBytesCount As Integer = 512
	Const DefaultServerPort As Integer = 6667
	Const MaxReceivedBuffersCount As Integer = 1
	
	Dim AdvancedClientData As Any Ptr
	Dim CodePage As Integer
	Dim ClientVersion As WString Ptr
	Dim ClientUserInfo As WString Ptr
	
	Dim ClientNick As WString * (MaxBytesCount + 1)
	Dim ClientSocket As SOCKET
	
	Dim ClientRawBuffer As ZString * (MaxBytesCount + 1)
	Dim ClientRawBufferLength As Integer
	
	Dim RecvOverlapped As WSAOVERLAPPED
	Dim RecvBuf(MaxReceivedBuffersCount - 1) As WSABUF
	
	Dim hEvent As HANDLE
	
	Dim lpfnSendedRawMessageEvent As SendedRawMessageEvent
	Dim lpfnReceivedRawMessageEvent As ReceivedRawMessageEvent
	Dim lpfnServerErrorEvent As ServerErrorEvent
	Dim lpfnServerMessageEvent As ServerMessageEvent
	Dim lpfnNoticeEvent As NoticeEvent
	Dim lpfnChannelNoticeEvent As ChannelNoticeEvent
	Dim lpfnChannelMessageEvent As ChannelMessageEvent
	Dim lpfnPrivateMessageEvent As PrivateMessageEvent
	Dim lpfnUserJoinedEvent As UserJoinedEvent
	Dim lpfnUserLeavedEvent As UserLeavedEvent
	Dim lpfnNickChangedEvent As NickChangedEvent
	Dim lpfnTopicEvent As TopicEvent
	Dim lpfnQuitEvent As QuitEvent
	Dim lpfnKickEvent As KickEvent
	Dim lpfnInviteEvent As InviteEvent
	Dim lpfnPingEvent As PingEvent
	Dim lpfnPongEvent As PongEvent
	Dim lpfnModeEvent As ModeEvent
	Dim lpfnCtcpPingRequestEvent As CtcpPingRequestEvent
	Dim lpfnCtcpTimeRequestEvent As CtcpTimeRequestEvent
	Dim lpfnCtcpUserInfoRequestEvent As CtcpUserInfoRequestEvent
	Dim lpfnCtcpVersionRequestEvent As CtcpVersionRequestEvent
	Dim lpfnCtcpActionEvent As CtcpActionEvent
	Dim lpfnCtcpPingResponseEvent As CtcpPingResponseEvent
	Dim lpfnCtcpTimeResponseEvent As CtcpTimeResponseEvent
	Dim lpfnCtcpUserInfoResponseEvent As CtcpUserInfoResponseEvent
	Dim lpfnCtcpVersionResponseEvent As CtcpVersionResponseEvent
	
End Type

Declare Function IrcClientStartup( _
	ByVal pIrcClient As IrcClient Ptr _
)As HRESULT

Declare Function IrcClientCleanup( _
	ByVal pIIrcClient As IrcClient Ptr _
)As HRESULT

Declare Function OpenIrcClient Overload( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Server As WString Ptr, _
	ByVal Nick As WString Ptr _
) As Boolean

Declare Function OpenIrcClient Overload( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Server As WString Ptr, _
	ByVal Port As WString Ptr, _
	ByVal Nick As WString Ptr, _
	ByVal User As WString Ptr, _
	ByVal Description As WString Ptr _
) As Boolean

Declare Function OpenIrcClient Overload( _
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

Declare Sub CloseIrcClient( _
	ByVal pIrcClient As IrcClient Ptr _
)

Declare Function IrcClientStartReceiveDataLoop( _
	ByVal pIrcClient As IrcClient Ptr _
)As HRESULT

Declare Function IrcClientMsgStartReceiveDataLoop( _
	ByVal pIrcClient As IrcClient Ptr _
)As HRESULT

Declare Function SendIrcMessage( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Channel As WString Ptr, _
	ByVal MessageText As WString Ptr _
) As Boolean

Declare Function SendNotice( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Channel As WString Ptr, _
	ByVal NoticeText As WString Ptr _
) As Boolean

Declare Function ChangeTopic( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Channel As WString Ptr, _
	ByVal TopicText As WString Ptr _
) As Boolean

Declare Function QuitFromServer Overload( _
	ByVal pIrcClient As IrcClient Ptr _
) As Boolean

Declare Function QuitFromServer Overload( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal MessageText As WString Ptr _
) As Boolean

Declare Function ChangeNick( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Nick As WString Ptr _
) As Boolean

Declare Function JoinChannel( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Channel As WString Ptr _
) As Boolean

Declare Function PartChannel Overload( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Channel As WString Ptr _
) As Boolean

Declare Function PartChannel Overload( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Channel As WString Ptr, _
	ByVal MessageText As WString Ptr _
) As Boolean

Declare Function SendWho( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As WString Ptr _
) As Boolean

Declare Function SendWhoIs( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As WString Ptr _
) As Boolean

Declare Function SendAdmin Overload( _
	ByVal pIrcClient As IrcClient Ptr _
) As Boolean

Declare Function SendAdmin Overload( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Server As WString Ptr _
) As Boolean

Declare Function SendInfo Overload( _
	ByVal pIrcClient As IrcClient Ptr _
) As Boolean

Declare Function SendInfo Overload( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Server As WString Ptr _
) As Boolean

Declare Function SendAway Overload( _
	ByVal pIrcClient As IrcClient Ptr _
) As Boolean

Declare Function SendAway Overload( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal MessageText As WString Ptr _
) As Boolean

Declare Function SendIsON( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal NickList As WString Ptr _
) As Boolean

Declare Function SendKick Overload( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Channel As WString Ptr, _
	ByVal UserName As WString Ptr _
) As Boolean

Declare Function SendKick Overload( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Channel As WString Ptr, _
	ByVal UserName As WString Ptr, _
	ByVal MessageText As WString Ptr _
) As Boolean

Declare Function SendInvite( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As WString Ptr, _
	ByVal Channel As WString Ptr _
) As Boolean

Declare Function SendCtcpPingRequest( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As WString Ptr, _
	ByVal TimeValue As WString Ptr _
) As Boolean

Declare Function SendCtcpTimeRequest( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As WString Ptr _
) As Boolean

Declare Function SendCtcpUserInfoRequest( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As WString Ptr _
) As Boolean

Declare Function SendCtcpVersionRequest( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As WString Ptr _
) As Boolean

Declare Function SendCtcpAction( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As WString Ptr, _
	ByVal MessageText As WString Ptr _
) As Boolean

Declare Function SendCtcpPingResponse( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As WString Ptr, _
	ByVal TimeValue As WString Ptr _
) As Boolean

Declare Function SendCtcpTimeResponse( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As WString Ptr, _
	ByVal TimeValue As WString Ptr _
) As Boolean

Declare Function SendCtcpUserInfoResponse( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As WString Ptr, _
	ByVal UserInfo As WString Ptr _
) As Boolean

Declare Function SendCtcpVersionResponse( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As WString Ptr, _
	ByVal Version As WString Ptr _
) As Boolean

Declare Function SendDccSend Overload( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As WString Ptr, _
	ByVal FileName As WString Ptr, _
	ByVal IPAddress As WString Ptr, _
	ByVal Port As WString Ptr _
) As Boolean

Declare Function SendDccSend Overload( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As WString Ptr, _
	ByVal FileName As WString Ptr, _
	ByVal IPAddress As WString Ptr, _
	ByVal Port As WString Ptr, _
	ByVal FileLength As ULongInt _
) As Boolean

Declare Function SendPing( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Server As WString Ptr _
) As Boolean

Declare Function SendPong( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Server As WString Ptr _
) As Boolean

Declare Function SendRawMessage( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal RawText As WString Ptr _
) As Boolean

#endif
