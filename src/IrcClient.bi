#ifndef BATCHEDFILES_IRCCLIENT_IRCCLIENT_BI
#define BATCHEDFILES_IRCCLIENT_IRCCLIENT_BI

#include "windows.bi"
#include "win\shlwapi.bi"
#include "win\winsock2.bi"
#include "win\ws2tcpip.bi"
#include "ValueBSTR.bi"

Const IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM As Integer = 512
Const IRCPROTOCOL_NICKLENGTHMAXIMUM As Integer = 16
Const IRCPROTOCOL_CHANNELNAMELENGTHMAXIMUM As Integer = 50
Const IRCPROTOCOL_DEFAULTPORT As Integer = 6667
Const DefaultLocalServer = "0.0.0.0"
Const DefaultLocalPort = 0

Const IRCPROTOCOL_MODEFLAG_WALLOPS As Long =       &b0000000000000100 ' w
Const IRCPROTOCOL_MODEFLAG_INVISIBLE As Long =     &b0000000000001000 ' i
Const IRCPROTOCOL_MODEFLAG_AWAY As Long =          &b0000000000010000 ' a
Const IRCPROTOCOL_MODEFLAG_RESTRICTED As Long =    &b0000000000100000 ' r
Const IRCPROTOCOL_MODEFLAG_OPERATOR As Long =      &b0000000001000000 ' o
Const IRCPROTOCOL_MODEFLAG_LOCALOPERATOR As Long = &b0000000010000000 ' O
Const IRCPROTOCOL_MODEFLAG_SERVERNOTICES As Long = &b0000000100000000 ' s

Type _IrcPrefix
	Dim Nick As BSTR
	Dim User As BSTR
	Dim Host As BSTR
End Type

Type IrcPrefix As _IrcPrefix

Type LPIRCPREFIX As _IrcPrefix Ptr

Type LPCLIENTDATA As Any Ptr

Type OnSendedRawMessageEvent As Sub    (ByVal lpParameter As LPCLIENTDATA, ByVal pBytes As Const UByte Ptr, ByVal Count As Integer)
Type OnReceivedRawMessageEvent As Sub  (ByVal lpParameter As LPCLIENTDATA, ByVal pBytes As Const UByte Ptr, ByVal Count As Integer)

Type OnServerErrorEvent As Sub         (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal IrcMessage As BSTR)
Type OnNumericMessageEvent As Sub      (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal IrcNumericCommand As Integer, ByVal MessageText As BSTR)
Type OnServerMessageEvent As Sub       (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal IrcCommand As BSTR, ByVal MessageText As BSTR)

Type OnNoticeEvent As Sub              (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal NoticeText As BSTR)
Type OnChannelNoticeEvent As Sub       (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal Channel As BSTR, ByVal NoticeText As BSTR)
Type OnChannelMessageEvent As Sub      (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal Channel As BSTR, ByVal MessageText As BSTR)
Type OnPrivateMessageEvent As Sub      (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal MessageText As BSTR)

Type OnUserJoinedEvent As Sub          (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal Channel As BSTR)
Type OnUserLeavedEvent As Sub          (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal Channel As BSTR, ByVal MessageText As BSTR)
Type OnNickChangedEvent As Sub         (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal NewNick As BSTR)
Type OnTopicEvent As Sub               (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal Channel As BSTR, ByVal TopicText As BSTR)
Type OnQuitEvent As Sub                (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal MessageText As BSTR)
Type OnKickEvent As Sub                (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal Channel As BSTR, ByVal KickedUser As BSTR)
Type OnInviteEvent As Sub              (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal ToUser As BSTR, ByVal Channel As BSTR)
Type OnPingEvent As Sub                (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal Server As BSTR)
Type OnPongEvent As Sub                (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal Server As BSTR)
Type OnModeEvent As Sub                (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal Channel As BSTR, ByVal Mode As BSTR, ByVal UserName As BSTR)

Type OnCtcpPingRequestEvent As Sub     (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal ToUser As BSTR, ByVal TimeValue As BSTR)
Type OnCtcpTimeRequestEvent As Sub     (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal ToUser As BSTR)
Type OnCtcpUserInfoRequestEvent As Sub (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal ToUser As BSTR)
Type OnCtcpVersionRequestEvent As Sub  (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal ToUser As BSTR)
Type OnCtcpActionEvent As Sub          (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal ToUser As BSTR, ByVal ActionText As BSTR)
Type OnCtcpPingResponseEvent As Sub    (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal ToUser As BSTR, ByVal TimeValue As BSTR)
Type OnCtcpTimeResponseEvent As Sub    (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal ToUser As BSTR, ByVal TimeValue As BSTR)
Type OnCtcpUserInfoResponseEvent As Sub(ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal ToUser As BSTR, ByVal UserInfo As BSTR)
Type OnCtcpVersionResponseEvent As Sub (ByVal lpParameter As LPCLIENTDATA, ByVal pIrcPrefix As LPIRCPREFIX, ByVal ToUser As BSTR, ByVal Version As BSTR)

Type IrcClient As _IrcClient

Type LPIRCCLIENT As _IrcClient Ptr

#define IrcClientOpenConnectionSimple1(pIrcClient, Server, Nick) IrcClientOpenConnection((pIrcClient), (Server), IRCPROTOCOL_DEFAULTPORT, @DefaultLocalServer, DefaultLocalPort, NULL, (Nick), (Nick), IRCPROTOCOL_MODEFLAG_INVISIBLE, (Nick))
#define IrcClientOpenConnectionSimple2(pIrcClient, Server, Port, Nick, User, RealName) IrcClientOpenConnection((pIrcClient), (Server), (Port), @DefaultLocalServer, DefaultLocalPort, NULL, (Nick), (User), IRCPROTOCOL_MODEFLAG_INVISIBLE, (RealName))

Declare Function CreateIrcClient() As IrcClient Ptr

Declare Sub DestroyIrcClient()

Declare Function IrcClientStartup( _
	ByVal pIrcClient As IrcClient Ptr _
)As HRESULT

Declare Function IrcClientCleanup( _
	ByVal pIIrcClient As IrcClient Ptr _
)As HRESULT

Declare Function IrcClientOpenConnection( _
	ByVal pIrcClient As IrcClient Ptr, _
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

Declare Sub IrcClientCloseConnection( _
	ByVal pIrcClient As IrcClient Ptr _
)

Declare Function IrcClientStartReceiveDataLoop( _
	ByVal pIrcClient As IrcClient Ptr _
)As HRESULT

Declare Function IrcClientMsgStartReceiveDataLoop( _
	ByVal pIrcClient As IrcClient Ptr _
)As HRESULT

' Connection Registration
' PASS NICK USER OPER MODE SERVICE QUIT SQUIT

Declare Function IrcClientChangeNick( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Nick As BSTR _
)As HRESULT

#define IrcClientQuitFromServerSimple(pIrcClient) IrcClientQuitFromServer((pIrcClient), NULL)

Declare Function IrcClientQuitFromServer( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal QuitText As BSTR _
)As HRESULT

' Channel operations
' JOIN PART MODE TOPIC NAMES LIST INVITE KICK

Declare Function IrcClientJoinChannel( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Channel As BSTR _
)As HRESULT

#define IrcClientPartChannelSimple(pIrcClient) IrcClientPartChannel((pIrcClient), NULL)

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

#define IrcClientSendKickSimple(pIrcClient, Channel, UserName) IrcClientSendKick((pIrcClient), (Channel), (UserName), NULL)

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

#define IrcClientSendAdminSimple(pIrcClient) IrcClientSendAdmin((pIrcClient), NULL)

Declare Function IrcClientSendAdmin( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Server As BSTR _
)As HRESULT

#define IrcClientSendInfoSimple(pIrcClient) IrcClientSendInfo((pIrcClient), NULL)

Declare Function IrcClientSendInfo( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Server As BSTR _
)As HRESULT

#define IrcClientSendAwaySimple(pIrcClient) IrcClientSendAway((pIrcClient), NULL)

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

#define IrcClientSendDccSendSimple(pIrcClient, UserName, FileName, IPAddress, Port) IrcClientSendDccSend((pIrcClient), (UserName), (FileName), (IPAddress), (Port), 0)

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
