#include once "AsmIrc.bi"

' Смена ника
Public Function IrcClient.ChangeNick(ByRef Nick As WString)As ResultType
	Dim strSend As WString * (MaxBytesCount + 1) = Any
	lstrcpy(strSend, NickStringWithSpace)
	lstrcpy(m_Nick, Nick)
	lstrcat(strSend, Nick)
	Return SendData(strSend)
End Function

' Присоединение к каналу
Public Function IrcClient.JoinChannel(ByRef strChannel As WString)As ResultType
	Dim strSend As WString * (MaxBytesCount + 1) = Any
	lstrcpy(strSend, JoinStringWithSpace)
	lstrcat(strSend, strChannel)
	Return SendData(strSend)
End Function

' Выход с канала
Public Function IrcClient.PartChannel(ByRef strChannel As WString, ByRef strMessageText As WString)As ResultType
	Dim strTemp As WString * (MaxBytesCount + 1) = Any
	lstrcpy(strTemp, PartStringWithSpace)
	lstrcat(strTemp, strChannel)
	If strMessageText[0] <> 0 Then
		lstrcat(strTemp, SpaceWithCommaString)
		lstrcat(strTemp, strMessageText)
	End If
	Return SendData(strTemp)
End Function

' Выход из сети
Public Function IrcClient.QuitFromServer(ByRef strMessageText As WString)As ResultType
	Dim strTemp As WString * (MaxBytesCount + 1) = Any
	If strMessageText[0] = 0 Then
		lstrcpy(strTemp, QuitString)
	Else
		lstrcpy(strTemp, QuitStringWithSpace)
		lstrcat(strTemp, strMessageText)
	End If
	Return SendData(strTemp)
End Function

' Отправка сырого сообщения
Public Function IrcClient.SendRawMessage(ByRef strRawText As WString)As ResultType
	Return SendData(strRawText)
End Function

' Отправка сообщения
Public Function IrcClient.SendIrcMessage(ByRef strChannel As WString, ByRef strMessageText As WString)As ResultType
	Dim strTemp As WString * (MaxBytesCount + 1) = Any
	lstrcpy(strTemp, PrivateMessageWithSpace)
	lstrcat(strTemp, strChannel)
	lstrcat(strTemp, SpaceWithCommaString)
	lstrcat(strTemp, strMessageText)
	Return SendData(strTemp)
End Function

Public Function IrcClient.ChangeTopic(ByRef strChannel As WString, ByRef strTopic As WString)As ResultType
	Dim strTemp As WString * (MaxBytesCount + 1) = Any
	lstrcpy(strTemp, TopicStringWithSpace)
	lstrcat(strTemp, strChannel)
	lstrcat(strTemp, SpaceWithCommaString)
	lstrcat(strTemp, strTopic)
	Return SendData(strTemp)
End Function

' Отправка уведомления
Public Function IrcClient.SendNotice(ByRef strChannel As WString, ByRef strNoticeText As WString)As ResultType
	Dim strTemp As WString * (MaxBytesCount + 1) = Any
	lstrcpy(strTemp, NoticeStringWithSpace)
	lstrcat(strTemp, strChannel)
	lstrcat(strTemp, SpaceWithCommaString)
	lstrcat(strTemp, strNoticeText)
	Return SendData(strTemp)
End Function

' Отправка CTCP-запроса
Public Function IrcClient.SendCtcpMessage(ByRef strChannel As WString, ByVal iType As CtcpMessageType, ByRef Param As WString)As ResultType
	Dim strTemp As WString * (MaxBytesCount + 1) = Any
	lstrcpy(strTemp, PrivateMessageWithSpace)
	lstrcat(strTemp, strChannel)
	lstrcat(strTemp, SpaceWithCommaString)
	lstrcat(strTemp, SohString)
	Select Case iType
		Case CtcpMessageType.Ping
			lstrcat(strTemp, PingStringWithSpace)
			lstrcat(strTemp, Param)
		Case CtcpMessageType.Time
			lstrcat(strTemp, TimeString)
		Case CtcpMessageType.UserInfo
			lstrcat(strTemp, UserInfoString)
		Case CtcpMessageType.Version
			lstrcat(strTemp, VersionString)
	End Select
	lstrcat(strTemp, SohString)
	Return SendData(strTemp)
End Function

' Отправка CTCP-ответа
Public Function IrcClient.SendCtcpNotice(ByRef strChannel As WString, ByVal iType As CtcpMessageType, ByRef NoticeText As WString)As ResultType
	Dim strTemp As WString * (MaxBytesCount + 1) = Any
	lstrcpy(strTemp, NoticeStringWithSpace)
	lstrcat(strTemp, strChannel)
	lstrcat(strTemp, SpaceWithCommaString)
	lstrcat(strTemp, SohString)
	Select Case iType
		Case CtcpMessageType.Ping
			lstrcat(strTemp, PingStringWithSpace)
		Case CtcpMessageType.Time
			lstrcat(strTemp, TimeStringWithSpace)
		Case CtcpMessageType.UserInfo
			lstrcat(strTemp, UserInfoStringWithSpace)
		Case CtcpMessageType.Version
			lstrcat(strTemp, VersionStringWithSpace)
	End Select
	lstrcat(strTemp, NoticeText)
	lstrcat(strTemp, SohString)
	Return SendData(strTemp)
End Function

REM ' Отправляет пинг на сервер
REM Public Function SendPing()As Integer
	REM Dim strTemp As WString*MaxBytesCount = Any
	REM lstrcpy(strTemp, PingStringWithSpace)
	REM lstrcat(strTemp, m_Server)
	REM Return SendData(m_Socket, strTemp)
REM End Function
