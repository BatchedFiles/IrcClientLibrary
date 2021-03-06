#include "SendMessages.bi"
#include "CharacterConstants.bi"
#include "IrcClient.bi"
#include "SendData.bi"
#include "StringConstants.bi"

Function IrcClientChangeNick( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Nick As BSTR _
	)As HRESULT
	
	'NICK space <nickname>
	
	Dim NickLength As Integer = SysStringLen(Nick)
	If NickLength <> 0 Then
		Dim SendString As ValueBSTR = Type<ValueBSTR>(NickStringWithSpace, NickStringWithSpaceLength)
		SendString &= Nick
		
		pIrcClient->ClientNick = Nick
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Function IrcClientQuitFromServer( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal QuitText As BSTR _
	)As HRESULT
	
	'QUIT [space :<QuitText>]
	
	Dim SendString As ValueBSTR = Any
	
	If SysStringLen(QuitText) <> 0 Then
		SendString = Type<ValueBSTR>(QuitStringWithSpaceComma, QuitStringWithSpaceCommaLength)
		SendString &= QuitText
	Else
		SendString = Type<ValueBSTR>(QuitString, QuitStringLength)
	End If
	
	Return StartSendOverlapped(pIrcClient, SendString)
	
End Function

Function IrcClientSendPong( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Server As BSTR _
	)As HRESULT
	
	'PONG space <Server>
	If SysStringLen(Server) <> 0 Then
		Dim SendString As ValueBSTR = Type<ValueBSTR>(PongStringWithSpace, PongStringWithSpaceLength)
		SendString &= Server
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Function IrcClientSendPing( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Server As BSTR _
	)As HRESULT
	
	' От сервера:
	'PING space :<Server>
	
	' От клиента:
	'PING space <Server>
	
	If SysStringLen(Server) <> 0 Then
		Dim SendString As ValueBSTR = Type<ValueBSTR>(PingStringWithSpace, PingStringWithSpaceLength)
		SendString &= Server
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Function IrcClientJoinChannel( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Channel As BSTR _
	)As HRESULT
	
	'JOIN space <channel>
	If SysStringLen(Channel) <> 0 Then
		Dim SendString As ValueBSTR = Type<ValueBSTR>(JoinStringWithSpace, JoinStringWithSpaceLength)
		SendString &= Channel
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Function IrcClientPartChannel( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Channel As BSTR, _
		ByVal PartText As BSTR _
	)As HRESULT
	
	'PART space <channel> [space :<partmessage>]
	If SysStringLen(Channel) <> 0 Then
		Dim SendString As ValueBSTR = Type<ValueBSTR>(PartStringWithSpace, PartStringWithSpaceLength)
		SendString &= Channel
		
		If SysStringLen(PartText) <> 0 Then
			SendString.Append(SpaceWithCommaString, SpaceWithCommaStringLength)
			SendString &= PartText
		End If
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Function IrcClientRetrieveTopic( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Channel As BSTR _
	)As HRESULT
	
	'TOPIC space <Channel>
	If SysStringLen(Channel) <> 0 Then
		Dim SendString As ValueBSTR = Type<ValueBSTR>(TopicStringWithSpace, TopicStringWithSpaceLength)
		SendString &= Channel
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Function IrcClientSetTopic( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Channel As BSTR, _
		ByVal Topic As BSTR _
	)As HRESULT
	
	'TOPIC <Channel> :<Topic>
	
	If SysStringLen(Channel) <> 0 Then
		Dim SendString As ValueBSTR = Type<ValueBSTR>(TopicStringWithSpace, TopicStringWithSpaceLength)
		SendString &= Channel
		SendString.Append(SpaceWithCommaString, SpaceWithCommaStringLength)
		SendString &= Topic
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Function IrcClientSendPrivateMessage( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal MessageTarget As BSTR, _
		ByVal MessageText As BSTR _
	)As HRESULT
	
	'PRIVMSG space <msgtarget> space : <text to be sent>
	
	If SysStringLen(MessageTarget) <> 0 AndAlso SysStringLen(MessageText) <> 0 Then
		
		Dim SendString As ValueBSTR = Type<ValueBSTR>(PrivateMessageWithSpace, PrivateMessageWithSpaceLength)
		SendString &= MessageTarget
		SendString.Append(SpaceWithCommaString, SpaceWithCommaStringLength)
		SendString &= MessageText
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Function IrcClientSendNotice( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal NoticeTarget As BSTR, _
		ByVal NoticeText As BSTR _
	)As HRESULT
	
	'NOTICE space <msgtarget> space : <text to be sent>
	
	If SysStringLen(NoticeTarget) <> 0 AndAlso SysStringLen(NoticeText) <> 0 Then
		Dim SendString As ValueBSTR = Type<ValueBSTR>(NoticeStringWithSpace, NoticeStringWithSpaceLength)
		SendString &= NoticeTarget
		SendString.Append(SpaceWithCommaString, SpaceWithCommaStringLength)
		SendString &= NoticeText
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Function IrcClientSendWho( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Nick As BSTR _
	)As HRESULT
	
	'WHO <nick>
	If SysStringLen(Nick) <> 0 Then
		Dim SendString As ValueBSTR = Type<ValueBSTR>(WhoStringWithSpace, WhoStringWithSpaceLength)
		SendString &= Nick
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Function IrcClientSendWhoIs( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Nick As BSTR _
	)As HRESULT
	
	'WHOIS <nick>
	If SysStringLen(Nick) <> 0 Then
		Dim SendString As ValueBSTR = Type<ValueBSTR>(WhoIsStringWithSpace, WhoIsStringWithSpaceLength)
		SendString &= Nick
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

' Declare Function IrcClientSendAdmin( _
	' ByVal pIrcClient As IrcClient Ptr, _
	' ByVal Server As BSTR _
' )As HRESULT

' Declare Function IrcClientSendInfo( _
	' ByVal pIrcClient As IrcClient Ptr, _
	' ByVal Server As BSTR _
' )As HRESULT

' Declare Function IrcClientSendAway( _
	' ByVal pIrcClient As IrcClient Ptr, _
	' ByVal MessageText As BSTR _
' )As HRESULT

' Declare Function IrcClientSendIsON( _
	' ByVal pIrcClient As IrcClient Ptr, _
	' ByVal NickList As BSTR _
' )As HRESULT

' Declare Function IrcClientSendKick( _
	' ByVal pIrcClient As IrcClient Ptr, _
	' ByVal Channel As BSTR, _
	' ByVal UserName As BSTR, _
	' ByVal MessageText As BSTR _
' )As HRESULT

' Declare Function IrcClientSendInvite( _
	' ByVal pIrcClient As IrcClient Ptr, _
	' ByVal UserName As BSTR, _
	' ByVal Channel As BSTR _
' )As HRESULT

' CTCP

Function IrcClientSendCtcpPingRequest( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Nick As BSTR, _
		ByVal TimeStamp As BSTR _
	)As HRESULT
	
	'PRIVMSG space <Nick> space : SOH PING space<TimeStamp>SOH
	
	If SysStringLen(Nick) <> 0 AndAlso SysStringLen(TimeStamp) <> 0 Then
		
		Dim SendString As ValueBSTR = Type<ValueBSTR>(PrivateMessageWithSpace, PrivateMessageWithSpaceLength)
		SendString &= Nick
		SendString.Append(SpaceWithCommaString, SpaceWithCommaStringLength)
		SendString.Append(Characters.StartOfHeading)
		SendString.Append(PingStringWithSpace, PingStringWithSpaceLength)
		SendString &= TimeStamp
		SendString.Append(Characters.StartOfHeading)
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Function IrcClientSendCtcpTimeRequest( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Nick As BSTR _
	)As HRESULT
	
	'PRIVMSG space <Nick> space : SOH TIME SOH
	
	If SysStringLen(Nick) <> 0 Then
		
		Dim SendString As ValueBSTR = Type<ValueBSTR>(PrivateMessageWithSpace, PrivateMessageWithSpaceLength)
		SendString &= Nick
		SendString.Append(SpaceWithCommaString, SpaceWithCommaStringLength)
		SendString.Append(Characters.StartOfHeading)
		SendString.Append(TimeString, TimeStringLength)
		SendString.Append(Characters.StartOfHeading)
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Function IrcClientSendCtcpUserInfoRequest( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Nick As BSTR _
	)As HRESULT
	
	'PRIVMSG space <Nick> space : SOH USERINFO SOH
	
	If SysStringLen(Nick) <> 0 Then
		
		Dim SendString As ValueBSTR = Type<ValueBSTR>(PrivateMessageWithSpace, PrivateMessageWithSpaceLength)
		SendString &= Nick
		SendString.Append(SpaceWithCommaString, SpaceWithCommaStringLength)
		SendString.Append(Characters.StartOfHeading)
		SendString.Append(UserInfoString, UserInfoStringLength)
		SendString.Append(Characters.StartOfHeading)
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Function IrcClientSendCtcpVersionRequest( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Nick As BSTR _
	)As HRESULT
	
	'PRIVMSG space <Nick> space : SOH VERSION SOH
	
	If SysStringLen(Nick) <> 0 Then
		
		Dim SendString As ValueBSTR = Type<ValueBSTR>(PrivateMessageWithSpace, PrivateMessageWithSpaceLength)
		SendString &= Nick
		SendString.Append(SpaceWithCommaString, SpaceWithCommaStringLength)
		SendString.Append(Characters.StartOfHeading)
		SendString.Append(VersionString, VersionStringLength)
		SendString.Append(Characters.StartOfHeading)
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Function IrcClientSendCtcpAction( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Channel As BSTR, _
		ByVal MessageText As BSTR _
	)As HRESULT
	
	'PRIVMSG space <Channel> space : SOH ACTION space <MessageText>SOH
	
	If SysStringLen(Channel) <> 0 AndAlso SysStringLen(MessageText) <> 0 Then
		
		Dim SendString As ValueBSTR = Type<ValueBSTR>(PrivateMessageWithSpace, PrivateMessageWithSpaceLength)
		SendString &= Channel
		SendString.Append(SpaceWithCommaString, SpaceWithCommaStringLength)
		SendString.Append(Characters.StartOfHeading)
		SendString.Append(ActionStringWithSpace, ActionStringWithSpaceLength)
		SendString &= MessageText
		SendString.Append(Characters.StartOfHeading)
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Function IrcClientSendCtcpPingResponse( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Nick As BSTR, _
		ByVal TimeStamp As BSTR _
	)As HRESULT
	
	'NOTICE space <Nick> space : SOH PING space <TimeStamp>SOH
	
	If SysStringLen(Nick) <> 0 AndAlso SysStringLen(TimeStamp) <> 0 Then
		
		Dim SendString As ValueBSTR = Type<ValueBSTR>(NoticeStringWithSpace, NoticeStringWithSpaceLength)
		SendString &= Nick
		SendString.Append(SpaceWithCommaString, SpaceWithCommaStringLength)
		SendString.Append(Characters.StartOfHeading)
		SendString.Append(PingStringWithSpace, PingStringWithSpaceLength)
		SendString &= TimeStamp
		SendString.Append(Characters.StartOfHeading)
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Function IrcClientSendCtcpTimeResponse( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Nick As BSTR, _
		ByVal TimeValue As BSTR _
	)As HRESULT
	
	'NOTICE space <Nick> space : SOH TIME space <TimeValue>SOH
	
	If SysStringLen(Nick) <> 0 AndAlso SysStringLen(TimeValue) <> 0 Then
		
		Dim SendString As ValueBSTR = Type<ValueBSTR>(NoticeStringWithSpace, NoticeStringWithSpaceLength)
		SendString &= Nick
		SendString.Append(SpaceWithCommaString, SpaceWithCommaStringLength)
		SendString.Append(Characters.StartOfHeading)
		SendString.Append(TimeStringWithSpace, TimeStringWithSpaceLength)
		SendString &= TimeValue
		SendString.Append(Characters.StartOfHeading)
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Function IrcClientSendCtcpUserInfoResponse( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Nick As BSTR, _
		ByVal UserInfo As BSTR _
	)As HRESULT
	
	'NOTICE space <Nick> space : SOH USERINFO space <UserInfo>SOH
	
	If SysStringLen(Nick) <> 0 AndAlso SysStringLen(UserInfo) <> 0 Then
		
		Dim SendString As ValueBSTR = Type<ValueBSTR>(NoticeStringWithSpace, NoticeStringWithSpaceLength)
		SendString &= Nick
		SendString.Append(SpaceWithCommaString, SpaceWithCommaStringLength)
		SendString.Append(Characters.StartOfHeading)
		SendString.Append(UserInfoStringWithSpace, UserInfoStringWithSpaceLength)
		SendString &= UserInfo
		SendString.Append(Characters.StartOfHeading)
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Function IrcClientSendCtcpVersionResponse( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Nick As BSTR, _
		ByVal Version As BSTR _
	)As HRESULT
	
	'NOTICE space <Nick> space : SOH VERSION space <Version>SOH
	
	If SysStringLen(Nick) <> 0 AndAlso SysStringLen(Version) <> 0 Then
		
		Dim SendString As ValueBSTR = Type<ValueBSTR>(NoticeStringWithSpace, NoticeStringWithSpaceLength)
		SendString &= Nick
		SendString.Append(SpaceWithCommaString, SpaceWithCommaStringLength)
		SendString.Append(Characters.StartOfHeading)
		SendString.Append(VersionStringWithSpace, VersionStringWithSpaceLength)
		SendString &= Version
		SendString.Append(Characters.StartOfHeading)
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Function IrcClientSendDccSend( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Nick As BSTR, _
		ByVal FileName As BSTR, _
		ByVal IPAddress As BSTR, _
		ByVal Port As Integer, _
		ByVal FileLength As ULongInt _
	)As HRESULT
	
	'PRIVMSG space <Nick> space : SOH DCC SEND space <FileName> space <IPAddress> space <Port> [space <FileLength>]SOH
	
	If SysStringLen(Nick) <> 0 AndAlso SysStringLen(FileName) <> 0 AndAlso SysStringLen(IPAddress) <> 0 Then
		
		Dim wszPort As WString * 100 = Any
		_ltow(CLng(Port), @wszPort, 10)
		
		Dim SendString As ValueBSTR = Type<ValueBSTR>(PrivateMessageWithSpace, PrivateMessageWithSpaceLength)
		SendString &= Nick
		SendString.Append(SpaceWithCommaString, SpaceWithCommaStringLength)
		SendString.Append(Characters.StartOfHeading)
		SendString.Append(DccSendWithSpace, DccSendWithSpaceLength)
		SendString &= FileName
		SendString.Append(Characters.WhiteSpace)
		SendString &= IPAddress
		SendString.Append(Characters.WhiteSpace)
		SendString &= wszPort
		
		If FileLength > 0 Then
			Dim wszFileLength As WString * 64 = Any
			_i64tow(FileLength, @wszFileLength, 10)
			
			SendString.Append(Characters.WhiteSpace)
			SendString &= wszFileLength
		End If
		
		SendString.Append(Characters.StartOfHeading)
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Function IrcClientSendRawMessage( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal RawText As BSTR _
	)As HRESULT
	
	Dim SendString As ValueBSTR = Type<ValueBSTR>(RawText)
	
	Return StartSendOverlapped(pIrcClient, SendString)
	
End Function
