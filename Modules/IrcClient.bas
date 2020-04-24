#include "IrcClient.bi"
#include "IntegerToWString.bi"
#include "MakeConnectionString.bi"
#include "NetworkClient.bi"
#include "SendData.bi"
#include "ReceiveData.bi"

Const TenMinutesInMilliSeconds As DWORD = 10 * 60 * 1000
Const DefaultLocalServer = "0.0.0.0"
Const DefaultLocalPort = 0

Function IrcClientOpenConnection( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Server As LPCWSTR, _
		ByVal Nick As LPCWSTR _
	)As HRESULT
	Return IrcClientOpenConnection( _
		pIrcClient, _
		Server, _
		IRCPROTOCOL_DEFAULTPORT, _
		@DefaultLocalServer, _
		DefaultLocalPort, _
		NULL, _
		Nick, _
		Nick, _
		Nick, _
		False _
	)
End Function

Function IrcClientOpenConnection( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Server As LPCWSTR, _
		ByVal Port As Integer, _
		ByVal Nick As LPCWSTR, _
		ByVal User As LPCWSTR, _
		ByVal Description As LPCWSTR _
	)As HRESULT
	Return IrcClientOpenConnection( _
		pIrcClient, _
		Server, _
		Port, _
		@DefaultLocalServer, _
		DefaultLocalPort, _
		NULL, _
		Nick, _
		User, _
		Description, _
		False _
	)
End Function

Function IrcClientOpenConnection( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Server As LPCWSTR, _
		ByVal Port As Integer, _
		ByVal LocalServer As LPCWSTR, _
		ByVal LocalPort As Integer, _
		ByVal Password As LPCWSTR, _
		ByVal Nick As LPCWSTR, _
		ByVal User As LPCWSTR, _
		ByVal Description As LPCWSTR, _
		ByVal Visible As Boolean _
	)As HRESULT
	
	pIrcClient->ErrorCode = S_OK
	pIrcClient->hHeap = GetProcessHeap()
	
	pIrcClient->hEvent = CreateEventW(NULL, True, False, NULL)
	If pIrcClient->hEvent = NULL Then
		Return HRESULT_FROM_WIN32(GetLastError())
	End If
	
	If pIrcClient->CodePage = 0 Then
		pIrcClient->CodePage = CP_UTF8
	End If
	
	pIrcClient->ReceiveBuffer.Buffer[0] = 0
	pIrcClient->ReceiveBuffer.Length = 0
	lstrcpy(@pIrcClient->ClientNick, Nick)
	
	Dim ConnectionString As WString * ((IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) * 3) = Any
	MakeConnectionString(@ConnectionString, Password, Nick, User, Description, Visible)
	
	Dim wszPort As WString * 100 = Any
	ltow(CLng(Port), @wszPort, 10)
	
	Dim wszLocalPort As WString * 100 = Any
	ltow(CLng(LocalPort), @wszLocalPort, 10)
	
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
	
	hr = StartSendOverlapped(pIrcClient, @ConnectionString)
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
				Return pIrcClient->ErrorCode
				
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

' Declare Function IrcClientMsgStartReceiveDataLoop( _
	' ByVal pIrcClient As IrcClient Ptr _
' )As HRESULT
