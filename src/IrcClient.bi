#ifndef BATCHEDFILES_IRCCLIENT_IRCCLIENT_BI
#define BATCHEDFILES_IRCCLIENT_IRCCLIENT_BI

#include once "windows.bi"
#include once "win\ole2.bi"

Const IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM = 512
Const IRCPROTOCOL_NICKLENGTHMAXIMUM = 16
Const IRCPROTOCOL_CHANNELNAMELENGTHMAXIMUM = 50
Const IRCPROTOCOL_DEFAULTPORT = 6667

Const IRCPROTOCOL_MODEFLAG_WALLOPS As Long =       &b0000000000000100 ' w
Const IRCPROTOCOL_MODEFLAG_INVISIBLE As Long =     &b0000000000001000 ' i
Const IRCPROTOCOL_MODEFLAG_AWAY As Long =          &b0000000000010000 ' a
Const IRCPROTOCOL_MODEFLAG_RESTRICTED As Long =    &b0000000000100000 ' r
Const IRCPROTOCOL_MODEFLAG_OPERATOR As Long =      &b0000000001000000 ' o
Const IRCPROTOCOL_MODEFLAG_LOCALOPERATOR As Long = &b0000000010000000 ' O
Const IRCPROTOCOL_MODEFLAG_SERVERNOTICES As Long = &b0000000100000000 ' s

Type IrcPrefix
	Dim Nick As BSTR
	Dim User As BSTR
	Dim Host As BSTR
End Type

Type LPCLIENTDATA As Any Ptr

Type OnSendedRawMessageEvent As Sub    (ByVal lpParameter As LPCLIENTDATA, ByVal pBytes As Const UByte Ptr, ByVal Count As Integer)
Type OnReceivedRawMessageEvent As Sub  (ByVal lpParameter As LPCLIENTDATA, ByVal pBytes As Const UByte Ptr, ByVal Count As Integer)
Type OnServerErrorEvent As Sub         (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal IrcMessage As BSTR)
Type OnNumericMessageEvent As Sub      (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal IrcNumericCommand As Integer, ByVal MessageText As BSTR)
Type OnServerMessageEvent As Sub       (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal IrcCommand As BSTR, ByVal MessageText As BSTR)
Type OnNoticeEvent As Sub              (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal NoticeText As BSTR)
Type OnChannelNoticeEvent As Sub       (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal Channel As BSTR, ByVal NoticeText As BSTR)
Type OnChannelMessageEvent As Sub      (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal Channel As BSTR, ByVal MessageText As BSTR)
Type OnPrivateMessageEvent As Sub      (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal MessageText As BSTR)
Type OnUserJoinedEvent As Sub          (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal Channel As BSTR)
Type OnUserLeavedEvent As Sub          (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal Channel As BSTR, ByVal MessageText As BSTR)
Type OnNickChangedEvent As Sub         (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal NewNick As BSTR)
Type OnTopicEvent As Sub               (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal Channel As BSTR, ByVal TopicText As BSTR)
Type OnQuitEvent As Sub                (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal MessageText As BSTR)
Type OnKickEvent As Sub                (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal Channel As BSTR, ByVal KickedUser As BSTR)
Type OnInviteEvent As Sub              (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal ToUser As BSTR, ByVal Channel As BSTR)
Type OnPingEvent As Sub                (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal Server As BSTR)
Type OnPongEvent As Sub                (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal Server As BSTR)
Type OnModeEvent As Sub                (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal Channel As BSTR, ByVal Mode As BSTR, ByVal UserName As BSTR)
Type OnCtcpPingRequestEvent As Sub     (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal ToUser As BSTR, ByVal TimeValue As BSTR)
Type OnCtcpTimeRequestEvent As Sub     (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal ToUser As BSTR)
Type OnCtcpUserInfoRequestEvent As Sub (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal ToUser As BSTR)
Type OnCtcpVersionRequestEvent As Sub  (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal ToUser As BSTR)
Type OnCtcpActionEvent As Sub          (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal ToUser As BSTR, ByVal ActionText As BSTR)
Type OnCtcpPingResponseEvent As Sub    (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal ToUser As BSTR, ByVal TimeValue As BSTR)
Type OnCtcpTimeResponseEvent As Sub    (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal ToUser As BSTR, ByVal TimeValue As BSTR)
Type OnCtcpUserInfoResponseEvent As Sub(ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal ToUser As BSTR, ByVal UserInfo As BSTR)
Type OnCtcpVersionResponseEvent As Sub (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As IrcPrefix Ptr, ByVal ToUser As BSTR, ByVal Version As BSTR)

Type IrcEvents
	lpfnSendedRawMessageEvent As OnSendedRawMessageEvent
	lpfnReceivedRawMessageEvent As OnReceivedRawMessageEvent
	lpfnServerErrorEvent As OnServerErrorEvent
	lpfnNumericMessageEvent As OnNumericMessageEvent
	lpfnServerMessageEvent As OnServerMessageEvent
	lpfnNoticeEvent As OnNoticeEvent
	lpfnChannelNoticeEvent As OnChannelNoticeEvent
	lpfnChannelMessageEvent As OnChannelMessageEvent
	lpfnPrivateMessageEvent As OnPrivateMessageEvent
	lpfnUserJoinedEvent As OnUserJoinedEvent
	lpfnUserLeavedEvent As OnUserLeavedEvent
	lpfnNickChangedEvent As OnNickChangedEvent
	lpfnTopicEvent As OnTopicEvent
	lpfnQuitEvent As OnQuitEvent
	lpfnKickEvent As OnKickEvent
	lpfnInviteEvent As OnInviteEvent
	lpfnPingEvent As OnPingEvent
	lpfnPongEvent As OnPongEvent
	lpfnModeEvent As OnModeEvent
	lpfnCtcpPingRequestEvent As OnCtcpPingRequestEvent
	lpfnCtcpTimeRequestEvent As OnCtcpTimeRequestEvent
	lpfnCtcpUserInfoRequestEvent As OnCtcpUserInfoRequestEvent
	lpfnCtcpVersionRequestEvent As OnCtcpVersionRequestEvent
	lpfnCtcpActionEvent As OnCtcpActionEvent
	lpfnCtcpPingResponseEvent As OnCtcpPingResponseEvent
	lpfnCtcpTimeResponseEvent As OnCtcpTimeResponseEvent
	lpfnCtcpUserInfoResponseEvent As OnCtcpUserInfoResponseEvent
	lpfnCtcpVersionResponseEvent As OnCtcpVersionResponseEvent
End Type

Type IrcClient As _IrcClient

#define IrcClientOpenConnectionSimple1(pIrcClient, Server, Nick) IrcClientOpenConnection((pIrcClient), (Server), NULL, NULL, NULL, NULL, (Nick), (Nick), IRCPROTOCOL_MODEFLAG_INVISIBLE, (Nick))
#define IrcClientOpenConnectionSimple2(pIrcClient, Server, Port, Nick) IrcClientOpenConnection((pIrcClient), (Server), (Port), NULL, NULL, NULL, (Nick), (Nick), IRCPROTOCOL_MODEFLAG_INVISIBLE, (Nick))
#define IrcClientOpenConnectionSimple3(pIrcClient, Server, Port, Nick, User, RealName) IrcClientOpenConnection((pIrcClient), (Server), (Port), NULL, NULL, NULL, (Nick), (User), IRCPROTOCOL_MODEFLAG_INVISIBLE, (RealName))
#define IrcClientQuitFromServerSimple(pIrcClient) IrcClientQuitFromServer((pIrcClient), NULL)
#define IrcClientPartChannelSimple(pIrcClient) IrcClientPartChannel((pIrcClient), NULL)
#define IrcClientSendKickSimple(pIrcClient, Channel, UserName) IrcClientSendKick((pIrcClient), (Channel), (UserName), NULL)
#define IrcClientSendAdminSimple(pIrcClient) IrcClientSendAdmin((pIrcClient), NULL)
#define IrcClientSendInfoSimple(pIrcClient) IrcClientSendInfo((pIrcClient), NULL)
#define IrcClientSendAwaySimple(pIrcClient) IrcClientSendAway((pIrcClient), NULL)
#define IrcClientSendDccSendSimple(pIrcClient, UserName, FileName, IPAddress, Port) IrcClientSendDccSend((pIrcClient), (UserName), (FileName), (IPAddress), (Port), 0)

' Create / destroy

Declare Function CreateIrcClient() As IrcClient Ptr

Declare Sub DestroyIrcClient( _
	ByVal pIrcClient As IrcClient Ptr _
)

' Callbacks

Declare Function IrcClientSetCallback( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal pEvents As IrcEvents Ptr, _
	ByVal lpParameter As LPCLIENTDATA _
)As HRESULT

' Properties

Declare Function IrcClientGetCodePage( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal pCodePage As Integer Ptr _
)As HRESULT

Declare Function IrcClientSetCodePage( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal CodePage As Integer _
)As HRESULT

Declare Function IrcClientGetClientVersion( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal ppVersion As BSTR Ptr _
)As HRESULT

Declare Function IrcClientSetClientVersion( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal pVersion As BSTR _
)As HRESULT

Declare Function IrcClientGetUserInfo( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal ppUserInfo As BSTR Ptr _
)As HRESULT

Declare Function IrcClientSetUserInfo( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal pUserInfo As BSTR _
)As HRESULT

Declare Function IrcClientGetErrorCode( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal pCode As HRESULT Ptr _
)As HRESULT

' Main loop

Declare Function IrcClientMainLoop( _
	ByVal pIrcClient As IrcClient Ptr _
)As HRESULT

Declare Function IrcClientWaitMessage( _
	ByVal pIrcClient As IrcClient Ptr _
)As HRESULT

' Connect to server

Declare Function IrcClientOpenConnection( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Server As BSTR, _
	ByVal Port As BSTR, _
	ByVal LocalAddress As BSTR, _
	ByVal LocalPort As BSTR, _
	ByVal Password As BSTR, _
	ByVal Nick As BSTR, _
	ByVal User As BSTR, _
	ByVal ModeFlags As Long, _
	ByVal RealName As BSTR _
)As HRESULT

Declare Sub IrcClientCloseConnection( _
	ByVal pIrcClient As IrcClient Ptr _
)

' Connection Registration
' PASS NICK USER OPER MODE SERVICE QUIT SQUIT

Declare Function IrcClientChangeNick( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Nick As BSTR _
)As HRESULT

Declare Function IrcClientQuitFromServer( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal MessageText As BSTR _
)As HRESULT

' Channel operations
' JOIN PART MODE TOPIC NAMES LIST INVITE KICK

Declare Function IrcClientJoinChannel( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Channel As BSTR _
)As HRESULT

Declare Function IrcClientPartChannel( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Channel As BSTR, _
	ByVal MessageText As BSTR _
)As HRESULT

Declare Function IrcClientRetrieveTopic( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Channel As BSTR _
)As HRESULT

Declare Function IrcClientSetTopic( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Channel As BSTR, _
	ByVal TopicText As BSTR _
)As HRESULT

Declare Function IrcClientSendKick( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Channel As BSTR, _
	ByVal UserName As BSTR, _
	ByVal MessageText As BSTR _
)As HRESULT

Declare Function IrcClientSendInvite( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As BSTR, _
	ByVal Channel As BSTR _
)As HRESULT

' Sending messages
' PRIVMSG NOTICE

Declare Function IrcClientSendPrivateMessage( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Target As BSTR, _
	ByVal Text As BSTR _
)As HRESULT

Declare Function IrcClientSendNotice( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Target As BSTR, _
	ByVal Text As BSTR _
)As HRESULT

' User based queries
' WHO WHOIS WHOWAS

Declare Function IrcClientSendWho( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As BSTR _
)As HRESULT

Declare Function IrcClientSendWhoIs( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As BSTR _
)As HRESULT

' Server queries and commands
' MOTD LUSERS VERSION STATS LINKS TIME CONNECT TRACE ADMIN INFO

Declare Function IrcClientSendAdmin( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Server As BSTR _
)As HRESULT

Declare Function IrcClientSendInfo( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Server As BSTR _
)As HRESULT

Declare Function IrcClientSendAway( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal MessageText As BSTR _
)As HRESULT

Declare Function IrcClientSendIsON( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal NickList As BSTR _
)As HRESULT

' Miscellaneous messages
' KILL PING PONG ERROR

Declare Function IrcClientSendPing( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Server As BSTR _
)As HRESULT

Declare Function IrcClientSendPong( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Server As BSTR _
)As HRESULT

' CTCP

Declare Function IrcClientSendCtcpPingRequest( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As BSTR, _
	ByVal TimeStamp As BSTR _
)As HRESULT

Declare Function IrcClientSendCtcpTimeRequest( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As BSTR _
)As HRESULT

Declare Function IrcClientSendCtcpUserInfoRequest( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As BSTR _
)As HRESULT

Declare Function IrcClientSendCtcpVersionRequest( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As BSTR _
)As HRESULT

Declare Function IrcClientSendCtcpAction( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As BSTR, _
	ByVal MessageText As BSTR _
)As HRESULT

Declare Function IrcClientSendCtcpPingResponse( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As BSTR, _
	ByVal TimeStamp As BSTR _
)As HRESULT

Declare Function IrcClientSendCtcpTimeResponse( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As BSTR, _
	ByVal TimeValue As BSTR _
)As HRESULT

Declare Function IrcClientSendCtcpUserInfoResponse( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As BSTR, _
	ByVal UserInfo As BSTR _
)As HRESULT

Declare Function IrcClientSendCtcpVersionResponse( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As BSTR, _
	ByVal Version As BSTR _
)As HRESULT

Declare Function IrcClientSendDccSend( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As BSTR, _
	ByVal FileName As BSTR, _
	ByVal IPAddress As BSTR, _
	ByVal Port As Integer, _
	ByVal FileLength As ULongInt _
)As HRESULT

Declare Function IrcClientSendRawMessage( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal RawText As BSTR _
)As HRESULT

#endif
