#include "SendMessages.bi"
#include "SendData.bi"
#include "StringConstants.bi"

Declare Function i64tow cdecl Alias "_i64tow"( _
	ByVal Value As Integer, _
	ByVal src As WString Ptr, _
	ByVal radix As Integer _
)As WString Ptr

Const MaxNickLength As Integer = 50
Const MaxChannelNameLength As Integer = 50

Function ChangeNick( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Nick As WString Ptr _
	)As Boolean
	
	Dim strSend As WString * (IrcClient.MaxBytesCount + 1) = Any
	lstrcpy(@strSend, @NickStringWithSpace)
	lstrcpyn(@pIrcClient->ClientNick, Nick, MaxNickLength)
	lstrcat(@strSend, @pIrcClient->ClientNick)
	Return SendData(pIrcClient, @strSend)
End Function

Function JoinChannel( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal strChannel As WString Ptr _
	)As Boolean
	
	Dim strSend As WString * (IrcClient.MaxBytesCount + 1) = Any
	lstrcpy(@strSend, @JoinStringWithSpace)
	lstrcpyn(@strSend + JoinStringWithSpaceLength, strChannel, MaxChannelNameLength)
	Return SendData(pIrcClient, @strSend)
End Function

Function PartChannel( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal strChannel As WString Ptr _
	)As Boolean
	
	Dim strTemp As WString * (IrcClient.MaxBytesCount + 1) = Any
	lstrcpy(@strTemp, @PartStringWithSpace)
	lstrcpyn(@strTemp + PartStringWithSpaceLength, strChannel, MaxChannelNameLength)
	Return SendData(pIrcClient, @strTemp)
End Function

Function PartChannel( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal strChannel As WString Ptr, _
		ByVal strMessageText As WString Ptr _
	)As Boolean
	
	Dim strTemp As WString * (IrcClient.MaxBytesCount + 1) = Any
	lstrcpy(@strTemp, @PartStringWithSpace)
	lstrcpyn(@strTemp + PartStringWithSpaceLength, strChannel, MaxChannelNameLength)
	If lstrlen(strMessageText) <> 0 Then
		lstrcat(@strTemp, @SpaceWithCommaString)
		Dim strTempLength As Integer = lstrlen(@strTemp)
		lstrcpyn(@strTemp + strTempLength, strMessageText, IrcClient.MaxBytesCount - 2 - strTempLength)
	End If
	Return SendData(pIrcClient, @strTemp)
End Function

Function QuitFromServer( _
		ByVal pIrcClient As IrcClient Ptr _
	)As Boolean
	
	Return SendData(pIrcClient, @QuitString)
End Function

Function QuitFromServer( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal strMessageText As WString Ptr _
	)As Boolean
	
	If lstrlen(strMessageText) = 0 Then
		Return SendData(pIrcClient, @QuitString)
	Else
		Dim strTemp As WString * (IrcClient.MaxBytesCount + 1) = Any
		lstrcpy(@strTemp, @QuitStringWithSpace)
		lstrcpyn(@strTemp + QuitStringWithSpaceLength, strMessageText, IrcClient.MaxBytesCount - 2 - QuitStringWithSpaceLength)
		Return SendData(pIrcClient, @strTemp)
	End If
End Function

Function SendPong( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal strServer As WString Ptr _
	)As Boolean
	
	Dim strPong As WString * (IrcClient.MaxBytesCount + 1) = Any
	lstrcpy(@strPong, @PongStringWithSpace)
	lstrcpyn(@strPong + PongStringWithSpaceLength, strServer, IrcClient.MaxBytesCount - 2 - lstrlen(strServer) - PongStringWithSpaceLength)
	Return SendData(pIrcClient, @strPong)
End Function

Function SendPing( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal strServer As WString Ptr _
	)As Boolean
	
	Dim strPing As WString * (IrcClient.MaxBytesCount + 1) = Any
	lstrcpy(@strPing, @PingString)
	lstrcat(@strPing, @SpaceWithCommaString)
	lstrcpyn(@strPing + PingStringLength + SpaceWithCommaStringLength, strServer, IrcClient.MaxBytesCount - 2 - lstrlen(strServer) - PingStringLength - SpaceWithCommaStringLength)
	Return SendData(pIrcClient, @strPing)
End Function

Function SendRawMessage( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal strRawText As WString Ptr _
	)As Boolean
	
	Return SendData(pIrcClient, strRawText)
End Function

Function SendIrcMessage( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal strChannel As WString Ptr, _
		ByVal strMessageText As WString Ptr _
	)As Boolean
	
	Dim strTemp As WString * (IrcClient.MaxBytesCount + 1) = Any
	lstrcpy(@strTemp, @PrivateMessageWithSpace)
	lstrcpyn(@strTemp + PrivateMessageWithSpaceLength, strChannel, MaxChannelNameLength)
	lstrcat(@strTemp, @SpaceWithCommaString)
	Dim strTempLength As Integer = lstrlen(@strTemp)
	lstrcpyn(@strTemp + strTempLength, strMessageText, IrcClient.MaxBytesCount - 2 - strTempLength)
	Return SendData(pIrcClient, @strTemp)
End Function

Function ChangeTopic( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal strChannel As WString Ptr, _
		ByVal strTopic As WString Ptr _
	)As Boolean
	
	Dim strTemp As WString * (IrcClient.MaxBytesCount + 1) = Any
	lstrcpy(@strTemp, @TopicStringWithSpace)
	lstrcpyn(@strTemp + TopicStringWithSpaceLength, strChannel, MaxChannelNameLength)
	If strTopic <> 0 Then
		lstrcat(@strTemp, @SpaceWithCommaString)
		Dim strTempLength As Integer = lstrlen(@strTemp)
		lstrcpyn(@strTemp + strTempLength, strTopic, IrcClient.MaxBytesCount - 2 - strTempLength)
	End If
	Return SendData(pIrcClient, @strTemp)
End Function

Function SendNotice( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal strChannel As WString Ptr, _
		ByVal strNoticeText As WString Ptr _
	)As Boolean
	
	Dim strTemp As WString * (IrcClient.MaxBytesCount + 1) = Any
	lstrcpy(@strTemp, @NoticeStringWithSpace)
	lstrcpyn(@strTemp + NoticeStringWithSpaceLength, strChannel, MaxChannelNameLength)
	lstrcat(@strTemp, @SpaceWithCommaString)
	Dim strTempLength As Integer = lstrlen(@strTemp)
	lstrcpyn(@strTemp + strTempLength, strNoticeText, IrcClient.MaxBytesCount - 2 - strTempLength)
	Return SendData(pIrcClient, @strTemp)
End Function

Function SendCtcpPingRequest( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal UserName As WString Ptr, _
		ByVal TimeValue As WString Ptr _
	)As Boolean
	
	Dim strTemp As WString * (IrcClient.MaxBytesCount + 1) = Any
	lstrcpy(@strTemp, @PrivateMessageWithSpace)
	lstrcpyn(@strTemp + PrivateMessageWithSpaceLength, UserName, MaxNickLength)
	lstrcat(@strTemp, @SpaceWithCommaString)
	lstrcat(@strTemp, @SohString)
	
	lstrcat(@strTemp, @PingStringWithSpace)
	Dim intLen As Integer = lstrlen(@strTemp)
	lstrcpyn(@strTemp + intLen, TimeValue, IrcClient.MaxBytesCount - intLen - 3)
	
	lstrcat(@strTemp, @SohString)
	Return SendData(pIrcClient, @strTemp)
End Function

Function SendCtcpTimeRequest( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal UserName As WString Ptr _
	)As Boolean
	
	Dim strTemp As WString * (IrcClient.MaxBytesCount + 1) = Any
	lstrcpy(@strTemp, @PrivateMessageWithSpace)
	lstrcpyn(@strTemp + PrivateMessageWithSpaceLength, UserName, MaxNickLength)
	lstrcat(@strTemp, @SpaceWithCommaString)
	lstrcat(@strTemp, @SohString)
	
	lstrcat(@strTemp, @TimeString)
	
	lstrcat(@strTemp, @SohString)
	Return SendData(pIrcClient, @strTemp)
End Function

Function SendCtcpUserInfoRequest( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal UserName As WString Ptr _
	)As Boolean
	
	Dim strTemp As WString * (IrcClient.MaxBytesCount + 1) = Any
	lstrcpy(@strTemp, @PrivateMessageWithSpace)
	lstrcpyn(@strTemp + PrivateMessageWithSpaceLength, UserName, MaxNickLength)
	lstrcat(@strTemp, @SpaceWithCommaString)
	lstrcat(@strTemp, @SohString)
	
	lstrcat(@strTemp, @UserInfoString)
	
	lstrcat(@strTemp, @SohString)
	Return SendData(pIrcClient, @strTemp)
End Function

Function SendCtcpVersionRequest( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal UserName As WString Ptr _
	)As Boolean
	
	Dim strTemp As WString * (IrcClient.MaxBytesCount + 1) = Any
	lstrcpy(@strTemp, @PrivateMessageWithSpace)
	lstrcpyn(@strTemp + PrivateMessageWithSpaceLength, UserName, MaxNickLength)
	lstrcat(@strTemp, @SpaceWithCommaString)
	lstrcat(@strTemp, @SohString)
	
	lstrcat(@strTemp, @VersionString)
	
	lstrcat(@strTemp, @SohString)
	Return SendData(pIrcClient, @strTemp)
End Function

Function SendCtcpAction( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal UserName As WString Ptr, _
		ByVal MessageText As WString Ptr _
	)As Boolean
	
	Dim strTemp As WString * (IrcClient.MaxBytesCount + 1) = Any
	lstrcpy(@strTemp, @PrivateMessageWithSpace)
	lstrcpyn(@strTemp + PrivateMessageWithSpaceLength, UserName, MaxNickLength)
	lstrcat(@strTemp, @SpaceWithCommaString)
	lstrcat(@strTemp, @SohString)
	
	lstrcat(@strTemp, @ActionStringWithSpace)
	Dim intLen As Integer = lstrlen(@strTemp)
	lstrcpyn(@strTemp + intLen, MessageText, IrcClient.MaxBytesCount - intLen - 3)
	
	lstrcat(@strTemp, @SohString)
	Return SendData(pIrcClient, @strTemp)
End Function

Function SendCtcpPingResponse( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal UserName As WString Ptr, _
		ByVal TimeValue As WString Ptr _
	)As Boolean
	
	Dim strTemp As WString * (IrcClient.MaxBytesCount + 1) = Any
	lstrcpy(@strTemp, @NoticeStringWithSpace)
	' TODO возможно переполнение буфера
	lstrcpyn(@strTemp + NoticeStringWithSpaceLength, UserName, MaxChannelNameLength)
	lstrcat(@strTemp, @SpaceWithCommaString)
	lstrcat(@strTemp, @SohString)
	
	lstrcat(@strTemp, @PingStringWithSpace)
	
	Dim strTempLength As Integer = lstrlen(@strTemp)
	lstrcpyn(@strTemp + strTempLength, TimeValue, IrcClient.MaxBytesCount - 2 - 1 - strTempLength)
	lstrcat(@strTemp, @SohString)
	Return SendData(pIrcClient, @strTemp)
End Function

Function SendCtcpTimeResponse( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal UserName As WString Ptr, _
		ByVal TimeValue As WString Ptr _
	)As Boolean
	
	Dim strTemp As WString * (IrcClient.MaxBytesCount + 1) = Any
	lstrcpy(@strTemp, @NoticeStringWithSpace)
	' TODO возможно переполнение буфера
	lstrcpyn(@strTemp + NoticeStringWithSpaceLength, UserName, MaxChannelNameLength)
	lstrcat(@strTemp, @SpaceWithCommaString)
	lstrcat(@strTemp, @SohString)
	
	lstrcat(@strTemp, @TimeStringWithSpace)
	
	Dim strTempLength As Integer = lstrlen(@strTemp)
	lstrcpyn(@strTemp + strTempLength, TimeValue, IrcClient.MaxBytesCount - 2 - 1 - strTempLength)
	lstrcat(@strTemp, @SohString)
	Return SendData(pIrcClient, @strTemp)
End Function

Function SendCtcpUserInfoResponse( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal UserName As WString Ptr, _
		ByVal UserInfo As WString Ptr _
	)As Boolean
	
	Dim strTemp As WString * (IrcClient.MaxBytesCount + 1) = Any
	lstrcpy(@strTemp, @NoticeStringWithSpace)
	' TODO возможно переполнение буфера
	lstrcpyn(@strTemp + NoticeStringWithSpaceLength, UserName, MaxChannelNameLength)
	lstrcat(@strTemp, @SpaceWithCommaString)
	lstrcat(@strTemp, @SohString)
	
	lstrcat(@strTemp, @UserInfoStringWithSpace)
	
	Dim strTempLength As Integer = lstrlen(@strTemp)
	lstrcpyn(@strTemp + strTempLength, UserInfo, IrcClient.MaxBytesCount - 2 - 1 - strTempLength)
	lstrcat(@strTemp, @SohString)
	Return SendData(pIrcClient, @strTemp)
End Function

Function SendCtcpVersionResponse( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal UserName As WString Ptr, _
		ByVal Version As WString Ptr _
	)As Boolean
	
	Dim strTemp As WString * (IrcClient.MaxBytesCount + 1) = Any
	lstrcpy(@strTemp, @NoticeStringWithSpace)
	' TODO возможно переполнение буфера
	lstrcpyn(@strTemp + NoticeStringWithSpaceLength, UserName, MaxChannelNameLength)
	lstrcat(@strTemp, @SpaceWithCommaString)
	lstrcat(@strTemp, @SohString)
	
	lstrcat(@strTemp, @VersionStringWithSpace)
	
	Dim strTempLength As Integer = lstrlen(@strTemp)
	lstrcpyn(@strTemp + strTempLength, Version, IrcClient.MaxBytesCount - 2 - 1 - strTempLength)
	lstrcat(@strTemp, @SohString)
	Return SendData(pIrcClient, @strTemp)
End Function

Function SendDccSend Overload( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal UserName As WString Ptr, _
		ByVal FileName As WString Ptr, _
		ByVal IPAddress As WString Ptr, _
		ByVal Port As WString Ptr _
	) As Boolean
	
	Return SendDccSend(pIrcClient, UserName, FileName, IPAddress, Port, 0)
End Function

Function SendDccSend Overload( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal UserName As WString Ptr, _
		ByVal FileName As WString Ptr, _
		ByVal IPAddress As WString Ptr, _
		ByVal Port As WString Ptr, _
		ByVal FileLength As ULongInt _
	) As Boolean
	
	' TODO возможно переполнение буфера
	Dim strTemp As WString * (IrcClient.MaxBytesCount + 1) = Any
	lstrcpy(@strTemp, @PrivateMessageWithSpace)
	lstrcpyn(@strTemp + PrivateMessageWithSpaceLength, UserName, MaxNickLength)
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

Function SendWho( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal UserName As WString Ptr _
	) As Boolean
	
	Dim strSend As WString * (IrcClient.MaxBytesCount + 1) = Any
	lstrcpy(@strSend, @WhoStringWithSpace)
	lstrcpyn(@strSend + WhoStringWithSpaceLength, UserName, MaxNickLength)
	Return SendData(pIrcClient, @strSend)
End Function

Function SendWhoIs( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal UserName As WString Ptr _
	) As Boolean
	
	Dim strSend As WString * (IrcClient.MaxBytesCount + 1) = Any
	lstrcpy(@strSend, @WhoIsStringWithSpace)
	lstrcpyn(@strSend + WhoIsStringWithSpaceLength, UserName, MaxNickLength)
	Return SendData(pIrcClient, @strSend)
End Function
