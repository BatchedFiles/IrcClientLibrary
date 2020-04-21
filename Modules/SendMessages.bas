#include "SendMessages.bi"
#include "SendData.bi"
#include "StringConstants.bi"

Declare Function i64tow cdecl Alias "_i64tow"( _
	ByVal Value As Integer, _
	ByVal src As WString Ptr, _
	ByVal radix As Integer _
)As WString Ptr

Function IrcClientChangeNick( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Nick As WString Ptr _
	)As Boolean
	
	Dim strSend As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
	lstrcpy(@strSend, @NickStringWithSpace)
	lstrcpyn(@pIrcClient->ClientNick, Nick, IRCPROTOCOL_NICKLENGTHMAXIMUM)
	lstrcat(@strSend, @pIrcClient->ClientNick)
	
	Return SendData(pIrcClient, @strSend)
	
End Function

Function IrcClientJoinChannel( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal strChannel As WString Ptr _
	)As Boolean
	
	Dim strSend As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
	lstrcpy(@strSend, @JoinStringWithSpace)
	lstrcpyn(@strSend + JoinStringWithSpaceLength, strChannel, IRCPROTOCOL_CHANNELNAMELENGTHMAXIMUM)
	
	Return SendData(pIrcClient, @strSend)
	
End Function

Function IrcClientPartChannel( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal strChannel As WString Ptr _
	)As Boolean
	
	Dim strTemp As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
	lstrcpy(@strTemp, @PartStringWithSpace)
	lstrcpyn(@strTemp + PartStringWithSpaceLength, strChannel, IRCPROTOCOL_CHANNELNAMELENGTHMAXIMUM)
	
	Return SendData(pIrcClient, @strTemp)
	
End Function

Function IrcClientPartChannel( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal strChannel As WString Ptr, _
		ByVal strMessageText As WString Ptr _
	)As Boolean
	
	Dim strTemp As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
	lstrcpy(@strTemp, @PartStringWithSpace)
	lstrcpyn(@strTemp + PartStringWithSpaceLength, strChannel, IRCPROTOCOL_CHANNELNAMELENGTHMAXIMUM)
	
	If lstrlen(strMessageText) <> 0 Then
		lstrcat(@strTemp, @SpaceWithCommaString)
		Dim strTempLength As Integer = lstrlen(@strTemp)
		lstrcpyn(@strTemp + strTempLength, strMessageText, IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM - 2 - strTempLength)
	End If
	
	Return SendData(pIrcClient, @strTemp)
	
End Function

Function IrcClientQuitFromServer( _
		ByVal pIrcClient As IrcClient Ptr _
	)As Boolean
	
	Return SendData(pIrcClient, @QuitString)
	
End Function

Function IrcClientQuitFromServer( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal strMessageText As WString Ptr _
	)As Boolean
	
	If lstrlen(strMessageText) = 0 Then
		Return SendData(pIrcClient, @QuitString)
	Else
		Dim strTemp As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
		lstrcpy(@strTemp, @QuitStringWithSpace)
		lstrcpyn(@strTemp + QuitStringWithSpaceLength, strMessageText, IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM - 2 - QuitStringWithSpaceLength)
		Return SendData(pIrcClient, @strTemp)
	End If
	
End Function

Function IrcClientSendPong( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal strServer As WString Ptr _
	)As Boolean
	
	Dim strPong As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
	lstrcpy(@strPong, @PongStringWithSpace)
	lstrcpyn(@strPong + PongStringWithSpaceLength, strServer, IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM - 2 - lstrlen(strServer) - PongStringWithSpaceLength)
	
	Return SendData(pIrcClient, @strPong)
	
End Function

Function IrcClientSendPing( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal strServer As WString Ptr _
	)As Boolean
	
	Dim strPing As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
	lstrcpy(@strPing, @PingString)
	lstrcat(@strPing, @SpaceWithCommaString)
	lstrcpyn(@strPing + PingStringLength + SpaceWithCommaStringLength, strServer, IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM - 2 - lstrlen(strServer) - PingStringLength - SpaceWithCommaStringLength)
	
	Return SendData(pIrcClient, @strPing)
	
End Function

Function IrcClientSendRawMessage( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal strRawText As WString Ptr _
	)As Boolean
	
	Return SendData(pIrcClient, strRawText)
	
End Function

Function IrcClientSendIrcMessage( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal strChannel As WString Ptr, _
		ByVal strMessageText As WString Ptr _
	)As Boolean
	
	Dim strTemp As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
	lstrcpy(@strTemp, @PrivateMessageWithSpace)
	lstrcpyn(@strTemp + PrivateMessageWithSpaceLength, strChannel, IRCPROTOCOL_CHANNELNAMELENGTHMAXIMUM)
	lstrcat(@strTemp, @SpaceWithCommaString)
	Dim strTempLength As Integer = lstrlen(@strTemp)
	lstrcpyn(@strTemp + strTempLength, strMessageText, IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM - 2 - strTempLength)
	
	Return SendData(pIrcClient, @strTemp)
	
End Function

Function IrcClientChangeTopic( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal strChannel As WString Ptr, _
		ByVal strTopic As WString Ptr _
	)As Boolean
	
	Dim strTemp As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
	lstrcpy(@strTemp, @TopicStringWithSpace)
	lstrcpyn(@strTemp + TopicStringWithSpaceLength, strChannel, IRCPROTOCOL_CHANNELNAMELENGTHMAXIMUM)
	
	If strTopic <> 0 Then
		lstrcat(@strTemp, @SpaceWithCommaString)
		Dim strTempLength As Integer = lstrlen(@strTemp)
		lstrcpyn(@strTemp + strTempLength, strTopic, IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM - 2 - strTempLength)
	End If
	
	Return SendData(pIrcClient, @strTemp)
	
End Function

Function IrcClientSendNotice( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal strChannel As WString Ptr, _
		ByVal strNoticeText As WString Ptr _
	)As Boolean
	
	Dim strTemp As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
	lstrcpy(@strTemp, @NoticeStringWithSpace)
	lstrcpyn(@strTemp + NoticeStringWithSpaceLength, strChannel, IRCPROTOCOL_CHANNELNAMELENGTHMAXIMUM)
	lstrcat(@strTemp, @SpaceWithCommaString)
	Dim strTempLength As Integer = lstrlen(@strTemp)
	lstrcpyn(@strTemp + strTempLength, strNoticeText, IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM - 2 - strTempLength)
	
	Return SendData(pIrcClient, @strTemp)
	
End Function

Function IrcClientSendCtcpPingRequest( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal UserName As WString Ptr, _
		ByVal TimeValue As WString Ptr _
	)As Boolean
	
	Dim strTemp As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
	lstrcpy(@strTemp, @PrivateMessageWithSpace)
	lstrcpyn(@strTemp + PrivateMessageWithSpaceLength, UserName, IRCPROTOCOL_NICKLENGTHMAXIMUM)
	lstrcat(@strTemp, @SpaceWithCommaString)
	lstrcat(@strTemp, @SohString)
	
	lstrcat(@strTemp, @PingStringWithSpace)
	Dim intLen As Integer = lstrlen(@strTemp)
	lstrcpyn(@strTemp + intLen, TimeValue, IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM - intLen - 3)
	
	lstrcat(@strTemp, @SohString)
	
	Return SendData(pIrcClient, @strTemp)
	
End Function

Function IrcClientSendCtcpTimeRequest( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal UserName As WString Ptr _
	)As Boolean
	
	Dim strTemp As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
	lstrcpy(@strTemp, @PrivateMessageWithSpace)
	lstrcpyn(@strTemp + PrivateMessageWithSpaceLength, UserName, IRCPROTOCOL_NICKLENGTHMAXIMUM)
	lstrcat(@strTemp, @SpaceWithCommaString)
	lstrcat(@strTemp, @SohString)
	
	lstrcat(@strTemp, @TimeString)
	
	lstrcat(@strTemp, @SohString)
	
	Return SendData(pIrcClient, @strTemp)
	
End Function

Function IrcClientSendCtcpUserInfoRequest( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal UserName As WString Ptr _
	)As Boolean
	
	Dim strTemp As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
	lstrcpy(@strTemp, @PrivateMessageWithSpace)
	lstrcpyn(@strTemp + PrivateMessageWithSpaceLength, UserName, IRCPROTOCOL_NICKLENGTHMAXIMUM)
	lstrcat(@strTemp, @SpaceWithCommaString)
	lstrcat(@strTemp, @SohString)
	
	lstrcat(@strTemp, @UserInfoString)
	
	lstrcat(@strTemp, @SohString)
	
	Return SendData(pIrcClient, @strTemp)
	
End Function

Function IrcClientSendCtcpVersionRequest( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal UserName As WString Ptr _
	)As Boolean
	
	Dim strTemp As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
	lstrcpy(@strTemp, @PrivateMessageWithSpace)
	lstrcpyn(@strTemp + PrivateMessageWithSpaceLength, UserName, IRCPROTOCOL_NICKLENGTHMAXIMUM)
	lstrcat(@strTemp, @SpaceWithCommaString)
	lstrcat(@strTemp, @SohString)
	
	lstrcat(@strTemp, @VersionString)
	
	lstrcat(@strTemp, @SohString)
	
	Return SendData(pIrcClient, @strTemp)
	
End Function

Function IrcClientSendCtcpAction( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal UserName As WString Ptr, _
		ByVal MessageText As WString Ptr _
	)As Boolean
	
	Dim strTemp As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
	lstrcpy(@strTemp, @PrivateMessageWithSpace)
	lstrcpyn(@strTemp + PrivateMessageWithSpaceLength, UserName, IRCPROTOCOL_NICKLENGTHMAXIMUM)
	lstrcat(@strTemp, @SpaceWithCommaString)
	lstrcat(@strTemp, @SohString)
	
	lstrcat(@strTemp, @ActionStringWithSpace)
	Dim intLen As Integer = lstrlen(@strTemp)
	lstrcpyn(@strTemp + intLen, MessageText, IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM - intLen - 3)
	
	lstrcat(@strTemp, @SohString)
	
	Return SendData(pIrcClient, @strTemp)
	
End Function

Function IrcClientSendCtcpPingResponse( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal UserName As WString Ptr, _
		ByVal TimeValue As WString Ptr _
	)As Boolean
	
	Dim strTemp As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
	lstrcpy(@strTemp, @NoticeStringWithSpace)
	' TODO возможно переполнение буфера
	lstrcpyn(@strTemp + NoticeStringWithSpaceLength, UserName, IRCPROTOCOL_CHANNELNAMELENGTHMAXIMUM)
	lstrcat(@strTemp, @SpaceWithCommaString)
	lstrcat(@strTemp, @SohString)
	
	lstrcat(@strTemp, @PingStringWithSpace)
	
	Dim strTempLength As Integer = lstrlen(@strTemp)
	lstrcpyn(@strTemp + strTempLength, TimeValue, IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM - 2 - 1 - strTempLength)
	lstrcat(@strTemp, @SohString)
	
	Return SendData(pIrcClient, @strTemp)
	
End Function

Function IrcClientSendCtcpTimeResponse( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal UserName As WString Ptr, _
		ByVal TimeValue As WString Ptr _
	)As Boolean
	
	Dim strTemp As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
	lstrcpy(@strTemp, @NoticeStringWithSpace)
	' TODO возможно переполнение буфера
	lstrcpyn(@strTemp + NoticeStringWithSpaceLength, UserName, IRCPROTOCOL_CHANNELNAMELENGTHMAXIMUM)
	lstrcat(@strTemp, @SpaceWithCommaString)
	lstrcat(@strTemp, @SohString)
	
	lstrcat(@strTemp, @TimeStringWithSpace)
	
	Dim strTempLength As Integer = lstrlen(@strTemp)
	lstrcpyn(@strTemp + strTempLength, TimeValue, IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM - 2 - 1 - strTempLength)
	lstrcat(@strTemp, @SohString)
	
	Return SendData(pIrcClient, @strTemp)
	
End Function

Function IrcClientSendCtcpUserInfoResponse( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal UserName As WString Ptr, _
		ByVal UserInfo As WString Ptr _
	)As Boolean
	
	Dim strTemp As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
	lstrcpy(@strTemp, @NoticeStringWithSpace)
	' TODO возможно переполнение буфера
	lstrcpyn(@strTemp + NoticeStringWithSpaceLength, UserName, IRCPROTOCOL_CHANNELNAMELENGTHMAXIMUM)
	lstrcat(@strTemp, @SpaceWithCommaString)
	lstrcat(@strTemp, @SohString)
	
	lstrcat(@strTemp, @UserInfoStringWithSpace)
	
	Dim strTempLength As Integer = lstrlen(@strTemp)
	lstrcpyn(@strTemp + strTempLength, UserInfo, IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM - 2 - 1 - strTempLength)
	lstrcat(@strTemp, @SohString)
	
	Return SendData(pIrcClient, @strTemp)
	
End Function

Function IrcClientSendCtcpVersionResponse( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal UserName As WString Ptr, _
		ByVal Version As WString Ptr _
	)As Boolean
	
	Dim strTemp As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
	lstrcpy(@strTemp, @NoticeStringWithSpace)
	' TODO возможно переполнение буфера
	lstrcpyn(@strTemp + NoticeStringWithSpaceLength, UserName, IRCPROTOCOL_CHANNELNAMELENGTHMAXIMUM)
	lstrcat(@strTemp, @SpaceWithCommaString)
	lstrcat(@strTemp, @SohString)
	
	lstrcat(@strTemp, @VersionStringWithSpace)
	
	Dim strTempLength As Integer = lstrlen(@strTemp)
	lstrcpyn(@strTemp + strTempLength, Version, IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM - 2 - 1 - strTempLength)
	lstrcat(@strTemp, @SohString)
	
	Return SendData(pIrcClient, @strTemp)
	
End Function

Function IrcClientSendDccSend Overload( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal UserName As WString Ptr, _
		ByVal FileName As WString Ptr, _
		ByVal IPAddress As WString Ptr, _
		ByVal Port As WString Ptr _
	) As Boolean
	
	Return IrcClientSendDccSend(pIrcClient, UserName, FileName, IPAddress, Port, 0)
	
End Function

Function IrcClientSendDccSend Overload( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal UserName As WString Ptr, _
		ByVal FileName As WString Ptr, _
		ByVal IPAddress As WString Ptr, _
		ByVal Port As WString Ptr, _
		ByVal FileLength As ULongInt _
	) As Boolean
	
	' TODO возможно переполнение буфера
	Dim strTemp As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
	lstrcpy(@strTemp, @PrivateMessageWithSpace)
	lstrcpyn(@strTemp + PrivateMessageWithSpaceLength, UserName, IRCPROTOCOL_NICKLENGTHMAXIMUM)
	lstrcat(@strTemp, @SpaceWithCommaString)
	lstrcat(@strTemp, @SohString)
	
	lstrcat(@strTemp, @DccSendWithSpace)
	lstrcat(@strTemp, FileName)
	lstrcat(@strTemp, @WhiteSpaceString)
	lstrcat(@strTemp, IPAddress)
	lstrcat(@strTemp, @WhiteSpaceString)
	lstrcat(@strTemp, Port)
	
	If FileLength > 0 Then
		lstrcat(@strTemp, @WhiteSpaceString)
		
		Dim strFileLength As WString * 64 = Any
		i64tow(FileLength, @strFileLength, 10)
	
		lstrcat(@strTemp, @strFileLength)
	End If
	
	lstrcat(@strTemp, @SohString)
	
	Return SendData(pIrcClient, @strTemp)
	
End Function

Function IrcClientSendWho( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal UserName As WString Ptr _
	) As Boolean
	
	Dim strSend As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
	lstrcpy(@strSend, @WhoStringWithSpace)
	lstrcpyn(@strSend + WhoStringWithSpaceLength, UserName, IRCPROTOCOL_NICKLENGTHMAXIMUM)
	
	Return SendData(pIrcClient, @strSend)
	
End Function

Function IrcClientSendWhoIs( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal UserName As WString Ptr _
	) As Boolean
	
	Dim strSend As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
	lstrcpy(@strSend, @WhoIsStringWithSpace)
	lstrcpyn(@strSend + WhoIsStringWithSpaceLength, UserName, IRCPROTOCOL_NICKLENGTHMAXIMUM)
	
	Return SendData(pIrcClient, @strSend)
	
End Function
