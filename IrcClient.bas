#include "IrcClient.bi"
#include "StringConstants.bi"
#include "AppendingBuffer.bi"
#include "Network.bi"
#include "SendData.bi"
#include "ReceiveData.bi"

Sub MakeConnectionString( _
		ByVal ConnectionString As WString Ptr, _
		ByVal Password As WString Ptr, _
		ByVal Nick As WString Ptr, _
		ByVal User As WString Ptr, _
		ByVal Description As WString Ptr, _
		ByVal Visible As Boolean _
	)
		
	'PASS password
	'NICK Paul
	'USER paul 8 * :Paul Mutton
	
	Dim StringBuilder As AppendingBuffer = Type<AppendingBuffer>(ConnectionString, 0)
	
	If lstrlen(Password) <> 0 Then
		StringBuilder.AppendWString(@PassStringWithSpace, PassStringWithSpaceLength)
		StringBuilder.AppendWLine(Password)
	End If
	
	StringBuilder.AppendWString(@NickStringWithSpace, NickStringWithSpaceLength)
	StringBuilder.AppendWLine(Nick)
	
	StringBuilder.AppendWString(@UserStringWithSpace, UserStringWithSpaceLength)
	StringBuilder.AppendWString(User)
	
	If Visible Then
		StringBuilder.AppendWString(@DefaultBotNameSepVisible, DefaultBotNameSepVisibleLength)
	Else
		StringBuilder.AppendWString(@DefaultBotNameSepInvisible, DefaultBotNameSepInvisibleLength)
	End If
	
	If lstrlen(Description) = 0 Then
		StringBuilder.AppendWString(Nick)
	Else
		StringBuilder.AppendWString(Description)
	End If
End Sub

Function OpenIrc( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Server As WString Ptr, _
		ByVal Nick As WString Ptr) As Boolean
	
	Return OpenIrc(pIrcClient, Server, "6667", "0.0.0.0", "", "", Nick, Nick, Nick, False)
End Function

Function OpenIrc( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Server As WString Ptr, _
		ByVal Port As WString Ptr, _
		ByVal Nick As WString Ptr, _
		ByVal User As WString Ptr, _
		ByVal Description As WString Ptr) As Boolean
	
	Return OpenIrc(pIrcClient, Server, Port, "0.0.0.0", "", "", Nick, User, Description, False)

End Function

Function OpenIrc( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Server As WString Ptr, _
		ByVal Port As WString Ptr, _
		ByVal LocalServer As WString Ptr, _
		ByVal LocalPort As WString Ptr, _
		ByVal Password As WString Ptr, _
		ByVal Nick As WString Ptr, _
		ByVal User As WString Ptr, _
		ByVal Description As WString Ptr, _
		ByVal Visible As Boolean)As Boolean
	
	If pIrcClient->CodePage = 0 Then
		pIrcClient->CodePage = CP_UTF8
	End If
	
	pIrcClient->ClientRawBuffer[0] = 0
	pIrcClient->ClientRawBufferLength = 0
	lstrcpy(@pIrcClient->ClientNick, Nick)
	
	Dim ConnectionString As WString * ((IrcClient.MaxBytesCount + 1) * 3) = Any
	MakeConnectionString(@ConnectionString, Password, Nick, User, Description, Visible)
	
	Dim objWsaData As WSAData = Any
	If WSAStartup(MAKEWORD(2, 2), @objWsaData) <> 0 Then
		Return False
	End If
	
	pIrcClient->ClientSocket = ConnectToServer(Server, Port, LocalServer, LocalPort)
	
	If pIrcClient->ClientSocket = INVALID_SOCKET Then
		Return False
	End If
	
	If SendData(pIrcClient, @ConnectionString) = False Then
		CloseSocketConnection(pIrcClient->ClientSocket)
		Return False
	End If
	
	pIrcClient->ClientConnected = True
	
	memset(@pIrcClient->RecvOverlapped, 0, SizeOf(WSAOVERLAPPED))
	pIrcClient->RecvOverlapped.hEvent = pIrcClient
	pIrcClient->RecvBuf(0).len = IrcClient.MaxBytesCount
	pIrcClient->RecvBuf(0).buf = @pIrcClient->ClientRawBuffer
	
	Dim Flags As DWORD = 0
	If WSARecv(pIrcClient->ClientSocket, @pIrcClient->RecvBuf(0), 1, NULL, @Flags, @pIrcClient->RecvOverlapped, @ReceiveCompletionROUTINE) <> 0 Then
		If WSAGetLastError() <> WSA_IO_PENDING Then
			pIrcClient->ClientConnected = False
			CloseSocketConnection(pIrcClient->ClientSocket)
			Return False
		End If
	End If
	
	Return True
	
End Function

Sub CloseIrcClient( _
		ByVal pIrcClient As IrcClient Ptr _
	)
	CloseSocketConnection(pIrcClient->ClientSocket)
	pIrcClient->ClientSocket = INVALID_SOCKET
	pIrcClient->ClientConnected = False
	WSACleanup()
End Sub
