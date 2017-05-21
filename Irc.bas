#include once "Irc.bi"

' Инициализация
Function IrcClient.OpenIrc(ByVal Server As WString Ptr, _
				ByVal Port As WString Ptr, _
				ByVal LocalServer As WString Ptr, _
				ByVal LocalPort As WString Ptr, _
				ByVal Password As WString Ptr, _
				ByVal Nick As WString Ptr, _
				ByVal User As WString Ptr, _
				ByVal Description As WString Ptr, _
				ByVal Visible As Boolean)As ResultType
	
	m_Buffer[0] = 0
	m_BufferLength = 0
	lstrcpy(@m_Nick, Nick)
	
	' init winsock
	Dim objWsaData As WSAData = Any
	If WSAStartup(MAKEWORD(2, 2), @objWsaData) <> 0 Then
		Return ResultType.WSAError
	End If
	' Создание строки подключения
	Dim strSendString As WString * (3 * MaxBytesCount + 1) = Any
	
	' Пароль
	' Проверка строки на нулевую длину
	If lstrlen(Password) = 0 Then
		' нужно установить нулевую длину, чтобы lstrcat работала правильно
		strSendString[0] = 0
	Else
		lstrcat(lstrcat(lstrcpy(@strSendString, @PassStringWithSpace), Password), @NewLineString)
	End If
	
	' Строка поделючения:
	' PASS password
	' NICK Paul
	' USER paul 8 *  : Paul Mutton
	lstrcat(lstrcat(lstrcat(lstrcat(lstrcat(lstrcat(lstrcat(@strSendString, @NickStringWithSpace), Nick), @NewLineString), @UserStringWithSpace), User), Iif(Visible, @DefaultBotNameSepVisible, @DefaultBotNameSepInvisible)), Iif(lstrlen(Description) = 0, Nick, Description))
	
	' Открыть сокет
	m_Socket = ConnectToServer(Server, Port, LocalServer, LocalPort)
	
	' Отправить строку подключения
	If m_Socket <> INVALID_SOCKET Then
		' Ожидать чтения данных с клиента 10 минут
		Dim ReceiveTimeOut As DWORD = 10 * 60 * 1000
		If setsockopt(m_Socket, SOL_SOCKET, SO_RCVTIMEO, CPtr(ZString Ptr, @ReceiveTimeOut), SizeOf(DWORD)) <> 0 Then
			CloseSocketConnection(m_Socket)
			Return ResultType.SocketError
		End If
		
		Dim lResuit As ResultType = SendData(@strSendString)
		If lResuit <> ResultType.None Then
			CloseSocketConnection(m_Socket)
		End If
		Return lResuit
	End If
	
	Return ResultType.None
End Function

' Закрытие соединения с сервером
Sub IrcClient.CloseIrc()
	CloseSocketConnection(m_Socket)
	m_Socket = INVALID_SOCKET
	WSACleanup()
End Sub
