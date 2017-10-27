#ifndef unicode
	#define unicode
#endif
#include once "windows.bi"
#include once "win\shellapi.bi"
#include once "win\shlwapi.bi"

#include once "Network.bi"

Type IrcClient
	
	Const MaxBytesCount As Integer = 512
	Const DefaultServerPort As Integer = 6667
	
	
	Dim AdvancedClientData As Any Ptr
	Dim CodePage As Integer
	Dim ClientVersion As WString Ptr
	Dim ClientUserInfo As WString Ptr
	
	
	Declare Function OpenIrc( _
		ByVal Server As WString Ptr, _
		ByVal Nick As WString Ptr _
	) As Boolean
	
	Declare Function OpenIrc( _
		ByVal Server As WString Ptr, _
		ByVal Port As WString Ptr, _
		ByVal Nick As WString Ptr, _
		ByVal User As WString Ptr, _
		ByVal Description As WString Ptr _
	) As Boolean
	
	Declare Function OpenIrc( _
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
	
	Declare Sub Run()
	
	Declare Sub CloseIrc()
	
	Declare Function SendIrcMessage( _
		ByVal Channel As WString Ptr, _
		ByVal MessageText As WString Ptr _
	) As Boolean
	
	Declare Function SendNotice( _
		ByVal Channel As WString Ptr, _
		ByVal NoticeText As WString Ptr _
	) As Boolean
	
	Declare Function ChangeTopic( _
		ByVal Channel As WString Ptr, _
		ByVal TopicText As WString Ptr _
	) As Boolean
	
	Declare Function QuitFromServer( _
	) As Boolean
	
	Declare Function QuitFromServer( _
		ByVal MessageText As WString Ptr _
	) As Boolean
	
	Declare Function ChangeNick( _
		ByVal Nick As WString Ptr _
	) As Boolean
	
	Declare Function JoinChannel( _
		ByVal Channel As WString Ptr _
	) As Boolean
	
	Declare Function PartChannel( _
		ByVal Channel As WString Ptr _
	) As Boolean
	
	Declare Function PartChannel( _
		ByVal Channel As WString Ptr, _
		ByVal MessageText As WString Ptr _
	) As Boolean
	
	Declare Function SendCtcpPingRequest( _
		ByVal UserName As WString Ptr, _
		ByVal TimeValue As WString Ptr _
	) As Boolean
	
	Declare Function SendCtcpTimeRequest( _
		ByVal UserName As WString Ptr _
	) As Boolean
	
	Declare Function SendCtcpUserInfoRequest( _
		ByVal UserName As WString Ptr _
	) As Boolean
	
	Declare Function SendCtcpVersionRequest( _
		ByVal UserName As WString Ptr _
	) As Boolean
	
	Declare Function SendCtcpAction( _
		ByVal UserName As WString Ptr, _
		ByVal MessageText As WString Ptr _
	) As Boolean
	
	Declare Function SendCtcpPingResponse( _
		ByVal UserName As WString Ptr, _
		ByVal TimeValue As WString Ptr _
	) As Boolean
	
	Declare Function SendCtcpTimeResponse( _
		ByVal UserName As WString Ptr, _
		ByVal TimeValue As WString Ptr _
	) As Boolean
	
	Declare Function SendCtcpUserInfoResponse( _
		ByVal UserName As WString Ptr, _
		ByVal UserInfo As WString Ptr _
	) As Boolean
	
	Declare Function SendCtcpVersionResponse( _
		ByVal UserName As WString Ptr, _
		ByVal Version As WString Ptr _
	) As Boolean
	
	Declare Function SendPing( _
		ByVal Server As WString Ptr _
	) As Boolean
	
	Declare Function SendPong( _
		ByVal Server As WString Ptr _
	) As Boolean
	
	Declare Function SendRawMessage( _
		ByVal RawText As WString Ptr _
	) As Boolean
	
	
	Dim SendedRawMessageEvent As Sub( _
		ByVal ClientData As Any Ptr, _
		ByVal MessageText As WString Ptr)
	
	Dim ReceivedRawMessageEvent As Sub( _
		ByVal ClientData As Any Ptr, _
		ByVal MessageText As WString Ptr)
	
	Dim ServerErrorEvent As Sub( _
		ByVal ClientData As Any Ptr, _
		ByVal Message As WString Ptr)
	
	Dim ServerMessageEvent As Sub( _
		ByVal ClientData As Any Ptr, _
		ByVal ServerCode As WString Ptr, _
		ByVal MessageText As WString Ptr)
	
	Dim NoticeEvent As Sub( _
		ByVal ClientData As Any Ptr, _
		ByVal Channel As WString Ptr, _
		ByVal NoticeText As WString Ptr)
	
	Dim ChannelMessageEvent As Sub( _
		ByVal ClientData As Any Ptr, _
		ByVal Channel As WString Ptr, _
		ByVal UserName As WString Ptr, _
		ByVal MessageText As WString Ptr)
	
	Dim PrivateMessageEvent As Sub( _
		ByVal ClientData As Any Ptr, _
		ByVal UserName As WString Ptr, _
		ByVal MessageText As WString Ptr)
	
	Dim UserJoinedEvent As Sub( _
		ByVal ClientData As Any Ptr, _
		ByVal Channel As WString Ptr, _
		ByVal UserName As WString Ptr)
	
	Dim UserLeavedEvent As Sub( _
		ByVal ClientData As Any Ptr, _
		ByVal Channel As WString Ptr, _
		ByVal UserName As WString Ptr, _
		ByVal MessageText As WString Ptr)
	
	Dim NickChangedEvent As Sub( _
		ByVal ClientData As Any Ptr, _
		ByVal OldNick As WString Ptr, _
		ByVal NewNick As WString Ptr)
	
	Dim TopicEvent As Sub( _
		ByVal ClientData As Any Ptr, _
		ByVal Channel As WString Ptr, _
		ByVal UserName As WString Ptr, _
		ByVal TopicText As WString Ptr)
	
	Dim QuitEvent As Sub( _
		ByVal ClientData As Any Ptr, _
		ByVal UserName As WString Ptr, _
		ByVal MessageText As WString Ptr)
	
	Dim KickEvent As Sub( _
		ByVal ClientData As Any Ptr, _
		ByVal AdminName As WString Ptr, _
		ByVal Channel As WString Ptr, _
		ByVal KickedUser As WString Ptr)
	
	Dim InviteEvent As Sub( _
		ByVal ClientData As Any Ptr, _
		ByVal FromUser As WString Ptr, _
		ByVal Channel As WString Ptr)
	
	Dim PingEvent As Sub( _
		ByVal ClientData As Any Ptr, _
		ByVal Server As WString Ptr)
	
	Dim PongEvent As Sub( _
		ByVal ClientData As Any Ptr, _
		ByVal Server As WString Ptr)
	
	Dim ModeEvent As Sub( _
		ByVal ClientData As Any Ptr, _
		ByVal AdminName As WString Ptr, _
		ByVal Channel As WString Ptr, _
		ByVal UserName As WString Ptr, _
		ByVal Mode As WString Ptr)
	
	Dim CtcpPingRequestEvent As Sub( _
		ByVal ClientData As Any Ptr, _
		ByVal FromUser As WString Ptr, _
		ByVal ToUser As WString Ptr, _
		ByVal TimeValue As WString Ptr)
	
	Dim CtcpTimeRequestEvent As Sub( _
		ByVal ClientData As Any Ptr, _
		ByVal FromUser As WString Ptr, _
		ByVal ToUser As WString Ptr)
	
	Dim CtcpUserInfoRequestEvent As Sub( _
		ByVal ClientData As Any Ptr, _
		ByVal FromUser As WString Ptr, _
		ByVal ToUser As WString Ptr)
	
	Dim CtcpVersionRequestEvent As Sub( _
		ByVal ClientData As Any Ptr, _
		ByVal FromUser As WString Ptr, _
		ByVal ToUser As WString Ptr)
	
	Dim CtcpActionEvent As Sub( _
		ByVal ClientData As Any Ptr, _
		ByVal FromUser As WString Ptr, _
		ByVal ToUser As WString Ptr, _
		ByVal ActionText As WString Ptr)
	
	Dim CtcpPingResponseEvent As Sub( _
		ByVal ClientData As Any Ptr, _
		ByVal FromUser As WString Ptr, _
		ByVal ToUser As WString Ptr, _
		ByVal TimeValue As WString Ptr)
	
	Dim CtcpTimeResponseEvent As Sub( _
		ByVal ClientData As Any Ptr, _
		ByVal FromUser As WString Ptr, _
		ByVal ToUser As WString Ptr, _
		ByVal TimeValue As WString Ptr)
	
	Dim CtcpUserInfoResponseEvent As Sub( _
		ByVal ClientData As Any Ptr, _
		ByVal FromUser As WString Ptr, _
		ByVal ToUser As WString Ptr, _
		ByVal UserInfo As WString Ptr)
	
	Dim CtcpVersionResponseEvent As Sub( _
		ByVal ClientData As Any Ptr, _
		ByVal FromUser As WString Ptr, _
		ByVal ToUser As WString Ptr, _
		ByVal Version As WString Ptr)
	
Private:
	
	Declare Sub ProcessMessage( _
		ByVal Receiver As WString Ptr, _
		ByVal Sender As WString Ptr, _
		ByVal MessageText As WString Ptr)
	
	Declare Sub ProcessNotice( _
		ByVal Receiver As WString Ptr, _
		ByVal Sender As WString Ptr, _
		ByVal MessageText As WString Ptr)
	
	Declare Function ReceiveData( _
		ByVal ReceivedData As WString Ptr _
	) As Boolean
	
	Declare Function ParseData( _
		ByVal ReceivedData As WString Ptr _
	) As Boolean
	
	Declare Function SendData( _
		ByVal strData As WString Ptr _
	) As Boolean
	
	Declare Function FindCrLfA( _
	) As Integer
	
	Dim ClientNick As WString * (MaxBytesCount + 1)
	
	Dim ClientRawBuffer As ZString * (MaxBytesCount + 1)
	Dim ClientRawBufferLength As Integer
	
	Dim ClientSocket As SOCKET
	
End Type
