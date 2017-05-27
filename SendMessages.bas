#include once "Irc.bi"
#include once "StringConstants.bi"

' Максимальная длина ника в чате
Const MaxNickLength As Integer = 50
' Максимальная длина канала в чате
Const MaxChannelNameLength As Integer = 50
' Максимальная длина параметра в CTCP запросах
Const MaxCtcpMessageParamLength As Integer = 50

' Смена ника
Public Function IrcClient.ChangeNick(ByVal Nick As WString Ptr)As ResultType
	Dim strSend As WString * (MaxBytesCount + 1) = Any
	lstrcpy(@strSend, @NickStringWithSpace)
	lstrcpyn(@m_Nick, Nick, MaxNickLength)
	lstrcat(@strSend, @m_Nick)
	Return SendData(@strSend)
End Function

' Присоединение к каналу
Public Function IrcClient.JoinChannel(ByVal strChannel As WString Ptr)As ResultType
	Dim strSend As WString * (MaxBytesCount + 1) = Any
	lstrcpy(@strSend, @JoinStringWithSpace)
	lstrcpyn(@strSend + JoinStringWithSpaceLength, strChannel, MaxChannelNameLength)
	Return SendData(@strSend)
End Function

' Выход с канала
Public Function IrcClient.PartChannel(ByVal strChannel As WString Ptr, ByVal strMessageText As WString Ptr)As ResultType
	Dim strTemp As WString * (MaxBytesCount + 1) = Any
	lstrcpy(@strTemp, @PartStringWithSpace)
	lstrcpyn(@strTemp + PartStringWithSpaceLength, strChannel, MaxChannelNameLength)
	If lstrlen(strMessageText) <> 0 Then
		lstrcat(@strTemp, @SpaceWithCommaString)
		Dim strTempLength As Integer = lstrlen(@strTemp)
		lstrcpyn(@strTemp + strTempLength, strMessageText, MaxBytesCount - 2 - strTempLength)
	End If
	Return SendData(@strTemp)
End Function

' Выход из сети
Public Function IrcClient.QuitFromServer(ByVal strMessageText As WString Ptr)As ResultType
	Dim strTemp As WString * (MaxBytesCount + 1) = Any
	If lstrlen(strMessageText) = 0 Then
		lstrcpy(@strTemp, @QuitString)
	Else
		lstrcpy(@strTemp, @QuitStringWithSpace)
		lstrcpyn(@strTemp + QuitStringWithSpaceLength, strMessageText, MaxBytesCount - 2 - QuitStringWithSpaceLength)
	End If
	Return SendData(@strTemp)
End Function

' Отправка сообщения PONG
Public Function IrcClient.SendPong(ByVal strServer As WString Ptr)As ResultType
	Dim strPong As WString * (MaxBytesCount + 1) = Any
	lstrcpy(@strPong, @PongStringWithSpace)
	lstrcpyn(@strPong + PongStringWithSpaceLength, strServer, MaxBytesCount - 2 - lstrlen(strServer) - PongStringWithSpaceLength)
	Return SendData(@strPong)
End Function

' Отправка сообщения PING
Public Function IrcClient.SendPing(ByVal strServer As WString Ptr)As ResultType
	Dim strPing As WString * (MaxBytesCount + 1) = Any
	lstrcpy(@strPing, @PingString)
	lstrcat(@strPing, @SpaceWithCommaString)
	lstrcpyn(@strPing + PingStringLength + SpaceWithCommaStringLength, strServer, MaxBytesCount - 2 - lstrlen(strServer) - PingStringLength - SpaceWithCommaStringLength)
	Return SendData(@strPing)
End Function

' Отправка сырого сообщения
Public Function IrcClient.SendRawMessage(ByVal strRawText As WString Ptr)As ResultType
	Return SendData(strRawText)
End Function

' Отправка сообщения
Public Function IrcClient.SendIrcMessage(ByVal strChannel As WString Ptr, ByVal strMessageText As WString Ptr)As ResultType
	Dim strTemp As WString * (MaxBytesCount + 1) = Any
	lstrcpy(@strTemp, @PrivateMessageWithSpace)
	lstrcpyn(@strTemp + PrivateMessageWithSpaceLength, strChannel, MaxChannelNameLength)
	lstrcat(@strTemp, @SpaceWithCommaString)
	Dim strTempLength As Integer = lstrlen(@strTemp)
	lstrcpyn(@strTemp + strTempLength, strMessageText, MaxBytesCount - 2 - strTempLength)
	Return SendData(@strTemp)
End Function

Public Function IrcClient.ChangeTopic(ByVal strChannel As WString Ptr, ByVal strTopic As WString Ptr)As ResultType
	Dim strTemp As WString * (MaxBytesCount + 1) = Any
	lstrcpy(@strTemp, @TopicStringWithSpace)
	lstrcpyn(@strTemp + TopicStringWithSpaceLength, strChannel, MaxChannelNameLength)
	lstrcat(@strTemp, @SpaceWithCommaString)
	Dim strTempLength As Integer = lstrlen(@strTemp)
	lstrcpyn(@strTemp + strTempLength, strTopic, MaxBytesCount - 2 - strTempLength)
	Return SendData(@strTemp)
End Function

' Отправка уведомления
Public Function IrcClient.SendNotice(ByVal strChannel As WString Ptr, ByVal strNoticeText As WString Ptr)As ResultType
	Dim strTemp As WString * (MaxBytesCount + 1) = Any
	lstrcpy(@strTemp, @NoticeStringWithSpace)
	lstrcpyn(@strTemp + NoticeStringWithSpaceLength, strChannel, MaxChannelNameLength)
	lstrcat(@strTemp, @SpaceWithCommaString)
	Dim strTempLength As Integer = lstrlen(@strTemp)
	lstrcpyn(@strTemp + strTempLength, strNoticeText, MaxBytesCount - 2 - strTempLength)
	Return SendData(@strTemp)
End Function

' Отправка CTCP-запроса
Public Function IrcClient.SendCtcpMessage(ByVal strChannel As WString Ptr, ByVal iType As CtcpMessageType, ByVal Param As WString Ptr)As ResultType
	Dim strTemp As WString * (MaxBytesCount + 1) = Any
	lstrcpy(@strTemp, @PrivateMessageWithSpace)
	lstrcpyn(@strTemp + PrivateMessageWithSpaceLength, strChannel, MaxChannelNameLength)
	lstrcat(@strTemp, @SpaceWithCommaString)
	lstrcat(@strTemp, @SohString)
	Select Case iType
		Case CtcpMessageType.Ping
			lstrcat(@strTemp, @PingStringWithSpace)
			lstrcpyn(@strTemp + lstrlen(@strTemp), Param, MaxCtcpMessageParamLength)
		Case CtcpMessageType.Time
			lstrcat(@strTemp, @TimeString)
		Case CtcpMessageType.UserInfo
			lstrcat(@strTemp, @UserInfoString)
		Case CtcpMessageType.Version
			lstrcat(@strTemp, @VersionString)
	End Select
	lstrcat(@strTemp, @SohString)
	Return SendData(@strTemp)
End Function

' Отправка CTCP-ответа
Public Function IrcClient.SendCtcpNotice(ByVal strChannel As WString Ptr, ByVal iType As CtcpMessageType, ByVal NoticeText As WString Ptr)As ResultType
	Dim strTemp As WString * (MaxBytesCount + 1) = Any
	lstrcpy(@strTemp, @NoticeStringWithSpace)
	' TODO возможно переполнение буфера
	lstrcpyn(@strTemp + NoticeStringWithSpaceLength, strChannel, MaxChannelNameLength)
	lstrcat(@strTemp, @SpaceWithCommaString)
	lstrcat(@strTemp, @SohString)
	
	Select Case iType
		Case CtcpMessageType.Ping
			lstrcat(@strTemp, @PingStringWithSpace)
		Case CtcpMessageType.Time
			lstrcat(@strTemp, @TimeStringWithSpace)
		Case CtcpMessageType.UserInfo
			lstrcat(@strTemp, @UserInfoStringWithSpace)
		Case CtcpMessageType.Version
			lstrcat(@strTemp, @VersionStringWithSpace)
	End Select
	
	Dim strTempLength As Integer = lstrlen(@strTemp)
	lstrcpyn(@strTemp + strTempLength, NoticeText, MaxBytesCount - 2 - 1 - strTempLength)
	
	lstrcat(@strTemp, @SohString)
	Return SendData(@strTemp)
End Function
