#include "IrcClient.bi"
#include "NetworkClient.bi"
#include "SendData.bi"
#include "ReceiveData.bi"

Const TenMinutesInMilliSeconds As DWORD = 10 * 60 * 1000

Private Sub MakeConnectionString( _
		ByRef ConnectionString As ValueBSTR, _
		ByVal Password As BSTR, _
		ByVal Nick As BSTR, _
		ByVal User As BSTR, _
		ByVal ModeFlags As Long, _
		ByVal RealName As BSTR _
	)
	
	'PASS password
	'<password>
	
	'NICK Paul
	'<nickname>
	
	'USER paul 8 * :Paul Mutton
	'<user> <mode> <unused> :<realname>
	
	'USER paul 0 * :Paul Mutton
	'<user> <mode> <unused> :<realname>
	
	If SysStringLen(Password) <> 0 Then
		ConnectionString.Append(PassStringWithSpace, PassStringWithSpaceLength)
		ConnectionString &= Password
		ConnectionString.Append(NewLineString, NewLineStringLength)
	End If
	
	ConnectionString.Append(NickStringWithSpace, NickStringWithSpaceLength)
	ConnectionString &= Nick
	ConnectionString.Append(NewLineString, NewLineStringLength)
	
	ConnectionString.Append(UserStringWithSpace, UserStringWithSpaceLength)
	ConnectionString &= User
	
	If ModeFlags And IRCPROTOCOL_MODEFLAG_INVISIBLE Then
		ConnectionString.Append(DefaultBotNameSepInvisible, DefaultBotNameSepInvisibleLength)
	Else
		ConnectionString.Append(DefaultBotNameSepVisible, DefaultBotNameSepVisibleLength)
	End If
	
	If SysStringLen(RealName) = 0 Then
		ConnectionString &= Nick
	Else
		ConnectionString &= RealName
	End If
	
End Sub

Function IrcClientOpenConnection( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Server As BSTR, _
		ByVal Port As Integer, _
		ByVal LocalServer As BSTR, _
		ByVal LocalPort As Integer, _
		ByVal Password As BSTR, _
		ByVal Nick As BSTR, _
		ByVal User As BSTR, _
		ByVal ModeFlags As Long, _
		ByVal RealName As BSTR _
	)As HRESULT
	
	If pIrcClient->IsInitialized = False Then
		Dim hr As HRESULT = IrcClientStartup(pIrcClient)
		If FAILED(hr) Then
			Return hr
		End If
	End If
	
	pIrcClient->ErrorCode = S_OK
	pIrcClient->hHeap = GetProcessHeap()
	
	pIrcClient->hEvent = CreateEventW(NULL, True, False, NULL)
	If pIrcClient->hEvent = NULL Then
		Return HRESULT_FROM_WIN32(GetLastError())
	End If
	
	If pIrcClient->CodePage = 0 Then
		pIrcClient->CodePage = CP_UTF8
	End If
	
	pIrcClient->ReceiveBuffer.Length = 0
	pIrcClient->ClientNick = Nick
	
	Dim ConnectionString As ValueBSTR
	MakeConnectionString(ConnectionString, Password, Nick, User, ModeFlags, RealName)
	
	Dim wszPort As WString * 100 = Any
	_ltow(CLng(Port), @wszPort, 10)
	
	Dim wszLocalPort As WString * 100 = Any
	_ltow(CLng(LocalPort), @wszLocalPort, 10)
	
	Dim hr As HRESULT = ConnectToServerW( _
		LocalServer, _
		@wszLocalPort, _
		Server, _
		@wszPort, _
		@pIrcClient->ClientSocket _
	)
	If FAILED(hr) Then
		Return hr
	End If
	
	hr = StartSendOverlapped(pIrcClient, ConnectionString)
	If FAILED(hr) Then
		Return hr
	End If
	
	Return StartRecvOverlapped(pIrcClient)
	
End Function

Sub IrcClientCloseConnection( _
		ByVal pIrcClient As IrcClient Ptr _
	)
	
	CloseSocketConnection(pIrcClient->ClientSocket)
	pIrcClient->ClientSocket = INVALID_SOCKET
	pIrcClient->ErrorCode = S_OK
	SetEvent(pIrcClient->hEvent)
	CloseHandle(pIrcClient->hEvent)
	
End Sub

Function IrcClientStartup( _
		ByVal pIrcClient As IrcClient Ptr _
	)As HRESULT
	
	Dim objWsaData As WSAData = Any
	Dim dwError As Long = WSAStartup(MAKEWORD(2, 2), @objWsaData)
	If dwError <> NO_ERROR Then
		Return HRESULT_FROM_WIN32(dwError)
	End If
	
	pIrcClient->IsInitialized = True
	
	Return S_OK
	
End Function

Function IrcClientCleanup( _
		ByVal pIIrcClient As IrcClient Ptr _
	)As HRESULT
	
	Dim dwError As Long = WSACleanup()
	If dwError <> NO_ERROR Then
		Return HRESULT_FROM_WIN32(dwError)
	End If
	
	Return S_OK
	
End Function

Function IrcClientStartReceiveDataLoop( _
		ByVal pIrcClient As IrcClient Ptr _
	)As HRESULT
	
	Do
		
		Dim dwWaitResult As DWORD = WaitForSingleObjectEx( _
			pIrcClient->hEvent, _
			TenMinutesInMilliSeconds, _
			TRUE _
		)
		Select Case dwWaitResult
			
			Case WAIT_OBJECT_0
				Return S_FALSE
				
			Case WAIT_ABANDONED
				Return E_FAIL
				
			Case WAIT_IO_COMPLETION
				' Завершилась асинхронная процедура, продолжаем ждать
				
			Case WAIT_TIMEOUT
				Return S_FALSE
				
			Case WAIT_FAILED
				Return HRESULT_FROM_WIN32(GetLastError())
				
			Case Else
				Return E_UNEXPECTED
				
		End Select
		
	Loop
	
End Function

Function IrcClientMsgStartReceiveDataLoop( _
		ByVal pIrcClient As IrcClient Ptr _
	)As HRESULT
	
	Do
		
		Dim dwWaitResult As DWORD = MsgWaitForMultipleObjectsEx( _
			1, _
			@pIrcClient->hEvent, _
			TenMinutesInMilliSeconds, _
			QS_ALLEVENTS Or QS_ALLINPUT Or QS_ALLPOSTMESSAGE, _
			MWMO_ALERTABLE Or MWMO_INPUTAVAILABLE _
		)
		Select Case dwWaitResult
			
			Case WAIT_OBJECT_0
				' Событие стало сигнальным
				Return S_FALSE
				
			Case WAIT_OBJECT_0 + 1
				' Сообщения добавлены в очередь сообщений
				Return pIrcClient->ErrorCode
				
			Case WAIT_ABANDONED
				Return E_FAIL
				
			Case WAIT_IO_COMPLETION
				' Завершилась асинхронная процедура, продолжаем ждать
				
			Case WAIT_TIMEOUT
				' Время ожидания события истекло = не выполнилась асинхронная процедура = нет ответа от сервера
				Return S_FALSE
				
			Case WAIT_FAILED
				' Событие уничтожено
				Return HRESULT_FROM_WIN32(GetLastError())
				
			Case Else
				Return E_UNEXPECTED
				
		End Select
		
	Loop
	
End Function
