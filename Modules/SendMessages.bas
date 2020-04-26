#include "SendMessages.bi"
#include "IntegerToWString.bi"
#include "SendData.bi"
#include "StringConstants.bi"

' Sub JoinArray( _
		' ByVal lpwszBuffer WString Ptr, _
		' ByVal Params As LPCWSTRLength, _
		' ByVal ParamsLength As Integer _
	' )
	
	' Dim StartIndex As Integer = 0
	' For i As Integer = 0 To ParamsLength - 1
		' lstrcpyn( _
			' lpwszBuffer[StartIndex], _
			' Params[i]->
	' Next
	
' End Sub

Function IrcClientSendPrivateMessage( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal MessageTarget As LPCWSTR, _
		ByVal strMessageText As LPCWSTR _
	)As HRESULT
	
	'PRIVMSG
	'<msgtarget> :<text to be sent>
	Dim mTarget As CWSTRLength = Any
	mTarget.Length = lstrlen(MessageTarget)
	mTarget.lpCData = MessageTarget
	
	Dim mText As CWSTRLength = Any
	mText.Length = lstrlen(strMessageText)
	mText.lpCData = strMessageText
	
	Return IrcClientSendPrivateMessage(pIrcClient, @mTarget, @mText)
	
End Function

Function IrcClientSendPrivateMessage Overload( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal MessageTarget As LPCWSTRLength, _
		ByVal MessageText As LPCWSTRLength _
	)As HRESULT
	
	Dim wszBuffer As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
	Dim BufferLength As Integer = 0
	
	'PRIVMSG <msgtarget> :<text to be sent>
	'PrivateMessageWithSpaceLength <TargetLength>SpaceWithCommaStringLength<MessageText->Length>
	
	Scope
		lstrcpyn( _
			@wszBuffer[BufferLength], _
			@PrivateMessageWithSpace, _
			PrivateMessageWithSpaceLength + 1 _
		)
		BufferLength += PrivateMessageWithSpaceLength
	End Scope
	
	Scope
		Dim TargetLength As Integer = min(IRCPROTOCOL_CHANNELNAMELENGTHMAXIMUM, MessageTarget->Length)
		lstrcpyn( _
			@wszBuffer[BufferLength], _
			MessageTarget->lpCData, _
			TargetLength + 1 _
		)
		BufferLength += TargetLength
	End Scope
	
	Scope
		lstrcpyn( _
			@wszBuffer[BufferLength], _
			@SpaceWithCommaString, _
			SpaceWithCommaStringLength + 1 _
		)
		BufferLength += SpaceWithCommaStringLength
	End Scope
	
	Scope
		Dim MessageTextLength As Integer = min(IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM - BufferLength - 2, MessageText->Length)
		lstrcpyn( _
			@wszBuffer[BufferLength], _
			MessageText->lpCData, _
			MessageTextLength + 1 _
		)
	End Scope
		
	Return StartSendOverlapped(pIrcClient, @wszBuffer)
	
End Function

Function IrcClientSendNotice( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal strChannel As LPCWSTR, _
		ByVal strNoticeText As LPCWSTR _
	)As HRESULT
	
	Dim strTemp As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
	lstrcpy(@strTemp, @NoticeStringWithSpace)
	lstrcpyn(@strTemp + NoticeStringWithSpaceLength, strChannel, IRCPROTOCOL_CHANNELNAMELENGTHMAXIMUM)
	lstrcat(@strTemp, @SpaceWithCommaString)
	Dim strTempLength As Integer = lstrlen(@strTemp)
	lstrcpyn(@strTemp + strTempLength, strNoticeText, IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM - 2 - strTempLength)
	
	Return StartSendOverlapped(pIrcClient, @strTemp)
	
End Function

Function IrcClientChangeTopic( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal strChannel As LPCWSTR, _
		ByVal strTopic As LPCWSTR _
	)As HRESULT
	
	Dim strTemp As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
	lstrcpy(@strTemp, @TopicStringWithSpace)
	lstrcpyn(@strTemp + TopicStringWithSpaceLength, strChannel, IRCPROTOCOL_CHANNELNAMELENGTHMAXIMUM)
	
	If strTopic <> 0 Then
		lstrcat(@strTemp, @SpaceWithCommaString)
		Dim strTempLength As Integer = lstrlen(@strTemp)
		lstrcpyn(@strTemp + strTempLength, strTopic, IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM - 2 - strTempLength)
	End If
	
	Return StartSendOverlapped(pIrcClient, @strTemp)
	
End Function

Function IrcClientQuitFromServer( _
		ByVal pIrcClient As IrcClient Ptr _
	)As HRESULT
	
	Return StartSendOverlapped(pIrcClient, @QuitString)
	
End Function

Function IrcClientQuitFromServer( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal strMessageText As LPCWSTR _
	)As HRESULT
	
	If lstrlen(strMessageText) = 0 Then
		Return StartSendOverlapped(pIrcClient, @QuitString)
	Else
		Dim strTemp As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
		lstrcpy(@strTemp, @QuitStringWithSpace)
		lstrcpyn(@strTemp + QuitStringWithSpaceLength, strMessageText, IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM - 2 - QuitStringWithSpaceLength)
		Return StartSendOverlapped(pIrcClient, @strTemp)
	End If
	
End Function

Function IrcClientChangeNick( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Nick As LPCWSTR _
	)As HRESULT
	
	Dim strSend As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
	lstrcpy(@strSend, @NickStringWithSpace)
	lstrcpyn(@pIrcClient->ClientNick, Nick, IRCPROTOCOL_NICKLENGTHMAXIMUM)
	lstrcat(@strSend, @pIrcClient->ClientNick)
	
	Return StartSendOverlapped(pIrcClient, @strSend)
	
End Function

Function IrcClientJoinChannel( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal strChannel As LPCWSTR _
	)As HRESULT
	
	Dim strSend As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
	lstrcpy(@strSend, @JoinStringWithSpace)
	lstrcpyn(@strSend + JoinStringWithSpaceLength, strChannel, IRCPROTOCOL_CHANNELNAMELENGTHMAXIMUM)
	
	Return StartSendOverlapped(pIrcClient, @strSend)
	
End Function

Function IrcClientPartChannel( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal strChannel As LPCWSTR _
	)As HRESULT
	
	Dim strTemp As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
	lstrcpy(@strTemp, @PartStringWithSpace)
	lstrcpyn(@strTemp + PartStringWithSpaceLength, strChannel, IRCPROTOCOL_CHANNELNAMELENGTHMAXIMUM)
	
	Return StartSendOverlapped(pIrcClient, @strTemp)
	
End Function

Function IrcClientPartChannel( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal strChannel As LPCWSTR, _
		ByVal strMessageText As LPCWSTR _
	)As HRESULT
	
	Dim strTemp As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
	lstrcpy(@strTemp, @PartStringWithSpace)
	lstrcpyn(@strTemp + PartStringWithSpaceLength, strChannel, IRCPROTOCOL_CHANNELNAMELENGTHMAXIMUM)
	
	If lstrlen(strMessageText) <> 0 Then
		lstrcat(@strTemp, @SpaceWithCommaString)
		Dim strTempLength As Integer = lstrlen(@strTemp)
		lstrcpyn(@strTemp + strTempLength, strMessageText, IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM - 2 - strTempLength)
	End If
	
	Return StartSendOverlapped(pIrcClient, @strTemp)
	
End Function

Function IrcClientSendWho( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal UserName As LPCWSTR _
	)As HRESULT
	
	Dim strSend As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
	lstrcpy(@strSend, @WhoStringWithSpace)
	lstrcpyn(@strSend + WhoStringWithSpaceLength, UserName, IRCPROTOCOL_NICKLENGTHMAXIMUM)
	
	Return StartSendOverlapped(pIrcClient, @strSend)
	
End Function

Function IrcClientSendWhoIs( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal UserName As LPCWSTR _
	)As HRESULT
	
	Dim strSend As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
	lstrcpy(@strSend, @WhoIsStringWithSpace)
	lstrcpyn(@strSend + WhoIsStringWithSpaceLength, UserName, IRCPROTOCOL_NICKLENGTHMAXIMUM)
	
	Return StartSendOverlapped(pIrcClient, @strSend)
	
End Function

' Declare Function IrcClientSendAdmin Overload( _
	' ByVal pIrcClient As IrcClient Ptr _
' )As HRESULT

' Declare Function IrcClientSendAdmin Overload( _
	' ByVal pIrcClient As IrcClient Ptr, _
	' ByVal Server As LPCWSTR _
' )As HRESULT

' Declare Function IrcClientSendInfo Overload( _
	' ByVal pIrcClient As IrcClient Ptr _
' )As HRESULT

' Declare Function IrcClientSendInfo Overload( _
	' ByVal pIrcClient As IrcClient Ptr, _
	' ByVal Server As LPCWSTR _
' )As HRESULT

' Declare Function IrcClientSendAway Overload( _
	' ByVal pIrcClient As IrcClient Ptr _
' )As HRESULT

' Declare Function IrcClientSendAway Overload( _
	' ByVal pIrcClient As IrcClient Ptr, _
	' ByVal MessageText As LPCWSTR _
' )As HRESULT

' Declare Function IrcClientSendIsON( _
	' ByVal pIrcClient As IrcClient Ptr, _
	' ByVal NickList As LPCWSTR _
' )As HRESULT

' Declare Function IrcClientSendKick Overload( _
	' ByVal pIrcClient As IrcClient Ptr, _
	' ByVal Channel As LPCWSTR, _
	' ByVal UserName As LPCWSTR _
' )As HRESULT

' Declare Function IrcClientSendKick Overload( _
	' ByVal pIrcClient As IrcClient Ptr, _
	' ByVal Channel As LPCWSTR, _
	' ByVal UserName As LPCWSTR, _
	' ByVal MessageText As LPCWSTR _
' )As HRESULT

' Declare Function IrcClientSendInvite( _
	' ByVal pIrcClient As IrcClient Ptr, _
	' ByVal UserName As LPCWSTR, _
	' ByVal Channel As LPCWSTR _
' )As HRESULT

Function IrcClientSendCtcpPingRequest( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal UserName As LPCWSTR, _
		ByVal TimeValue As LPCWSTR _
	)As HRESULT
	
	Dim strTemp As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
	lstrcpy(@strTemp, @PrivateMessageWithSpace)
	lstrcpyn(@strTemp + PrivateMessageWithSpaceLength, UserName, IRCPROTOCOL_NICKLENGTHMAXIMUM)
	lstrcat(@strTemp, @SpaceWithCommaString)
	lstrcat(@strTemp, @SohString)
	
	lstrcat(@strTemp, @PingStringWithSpace)
	Dim intLen As Integer = lstrlen(@strTemp)
	lstrcpyn(@strTemp + intLen, TimeValue, IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM - intLen - 3)
	
	lstrcat(@strTemp, @SohString)
	
	Return StartSendOverlapped(pIrcClient, @strTemp)
	
End Function

Function IrcClientSendCtcpTimeRequest( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal UserName As LPCWSTR _
	)As HRESULT
	
	Dim strTemp As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
	lstrcpy(@strTemp, @PrivateMessageWithSpace)
	lstrcpyn(@strTemp + PrivateMessageWithSpaceLength, UserName, IRCPROTOCOL_NICKLENGTHMAXIMUM)
	lstrcat(@strTemp, @SpaceWithCommaString)
	lstrcat(@strTemp, @SohString)
	
	lstrcat(@strTemp, @TimeString)
	
	lstrcat(@strTemp, @SohString)
	
	Return StartSendOverlapped(pIrcClient, @strTemp)
	
End Function

Function IrcClientSendCtcpUserInfoRequest( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal UserName As LPCWSTR _
	)As HRESULT
	
	Dim strTemp As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
	lstrcpy(@strTemp, @PrivateMessageWithSpace)
	lstrcpyn(@strTemp + PrivateMessageWithSpaceLength, UserName, IRCPROTOCOL_NICKLENGTHMAXIMUM)
	lstrcat(@strTemp, @SpaceWithCommaString)
	lstrcat(@strTemp, @SohString)
	
	lstrcat(@strTemp, @UserInfoString)
	
	lstrcat(@strTemp, @SohString)
	
	Return StartSendOverlapped(pIrcClient, @strTemp)
	
End Function

Function IrcClientSendCtcpVersionRequest( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal UserName As LPCWSTR _
	)As HRESULT
	
	Dim strTemp As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
	lstrcpy(@strTemp, @PrivateMessageWithSpace)
	lstrcpyn(@strTemp + PrivateMessageWithSpaceLength, UserName, IRCPROTOCOL_NICKLENGTHMAXIMUM)
	lstrcat(@strTemp, @SpaceWithCommaString)
	lstrcat(@strTemp, @SohString)
	
	lstrcat(@strTemp, @VersionString)
	
	lstrcat(@strTemp, @SohString)
	
	Return StartSendOverlapped(pIrcClient, @strTemp)
	
End Function

Function IrcClientSendCtcpAction( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal UserName As LPCWSTR, _
		ByVal MessageText As LPCWSTR _
	)As HRESULT
	
	Dim strTemp As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
	lstrcpy(@strTemp, @PrivateMessageWithSpace)
	lstrcpyn(@strTemp + PrivateMessageWithSpaceLength, UserName, IRCPROTOCOL_NICKLENGTHMAXIMUM)
	lstrcat(@strTemp, @SpaceWithCommaString)
	lstrcat(@strTemp, @SohString)
	
	lstrcat(@strTemp, @ActionStringWithSpace)
	Dim intLen As Integer = lstrlen(@strTemp)
	lstrcpyn(@strTemp + intLen, MessageText, IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM - intLen - 3)
	
	lstrcat(@strTemp, @SohString)
	
	Return StartSendOverlapped(pIrcClient, @strTemp)
	
End Function

Function IrcClientSendCtcpPingResponse( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal UserName As LPCWSTR, _
		ByVal TimeValue As LPCWSTR _
	)As HRESULT
	
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
	
	Return StartSendOverlapped(pIrcClient, @strTemp)
	
End Function

Function IrcClientSendCtcpTimeResponse( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal UserName As LPCWSTR, _
		ByVal TimeValue As LPCWSTR _
	)As HRESULT
	
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
	
	Return StartSendOverlapped(pIrcClient, @strTemp)
	
End Function

Function IrcClientSendCtcpUserInfoResponse( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal UserName As LPCWSTR, _
		ByVal UserInfo As LPCWSTR _
	)As HRESULT
	
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
	
	Return StartSendOverlapped(pIrcClient, @strTemp)
	
End Function

Function IrcClientSendCtcpVersionResponse( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal UserName As LPCWSTR, _
		ByVal Version As LPCWSTR _
	)As HRESULT
	
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
	
	Return StartSendOverlapped(pIrcClient, @strTemp)
	
End Function

Function IrcClientSendDccSend Overload( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal UserName As LPCWSTR, _
		ByVal FileName As LPCWSTR, _
		ByVal IPAddress As LPCWSTR, _
		ByVal Port As Integer _
	)As HRESULT
	
	Return IrcClientSendDccSend(pIrcClient, UserName, FileName, IPAddress, Port, 0)
	
End Function

Function IrcClientSendDccSend Overload( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal UserName As LPCWSTR, _
		ByVal FileName As LPCWSTR, _
		ByVal IPAddress As LPCWSTR, _
		ByVal Port As Integer, _
		ByVal FileLength As ULongInt _
	)As HRESULT
	
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
	
	Dim wszPort As WString * 100 = Any
	ltow(CLng(Port), @wszPort, 10)
	
	lstrcat(@strTemp, wszPort)
	
	If FileLength > 0 Then
		lstrcat(@strTemp, @WhiteSpaceString)
		
		Dim strFileLength As WString * 64 = Any
		i64tow(FileLength, @strFileLength, 10)
	
		lstrcat(@strTemp, @strFileLength)
	End If
	
	lstrcat(@strTemp, @SohString)
	
	Return StartSendOverlapped(pIrcClient, @strTemp)
	
End Function

Function IrcClientSendPing( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal strServer As LPCWSTR _
	)As HRESULT
	
	Dim strPing As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
	lstrcpy(@strPing, @PingString)
	lstrcat(@strPing, @SpaceWithCommaString)
	lstrcpyn(@strPing + PingStringLength + SpaceWithCommaStringLength, strServer, IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM - 2 - lstrlen(strServer) - PingStringLength - SpaceWithCommaStringLength)
	
	Return StartSendOverlapped(pIrcClient, @strPing)
	
End Function

Function IrcClientSendPong( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal strServer As LPCWSTR _
	)As HRESULT
	
	Dim strPong As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
	lstrcpy(@strPong, @PongStringWithSpace)
	lstrcpyn(@strPong + PongStringWithSpaceLength, strServer, IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM - 2 - lstrlen(strServer) - PongStringWithSpaceLength)
	
	Return StartSendOverlapped(pIrcClient, @strPong)
	
End Function

Function IrcClientSendRawMessage( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal strRawText As LPCWSTR _
	)As HRESULT
	
	Return StartSendOverlapped(pIrcClient, strRawText)
	
End Function
