#include "ReceiveData.bi"
#include "ParseData.bi"
#include "Network.bi"

Function StartRecvOverlapped( _
		ByVal pIrcClient As IrcClient Ptr _
	)As Boolean
	
	memset(@pIrcClient->RecvOverlapped, 0, SizeOf(WSAOVERLAPPED))
	pIrcClient->RecvOverlapped.hEvent = pIrcClient
	pIrcClient->RecvBuf.len = IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM - pIrcClient->ClientRawBufferLength
	pIrcClient->RecvBuf.buf = @pIrcClient->ClientRawBuffer[pIrcClient->ClientRawBufferLength]
	
	Dim Flags As DWORD = 0
	
	If WSARecv(pIrcClient->ClientSocket, @pIrcClient->RecvBuf, 1, NULL, @Flags, @pIrcClient->RecvOverlapped, @ReceiveCompletionROUTINE) <> 0 Then
		
		If WSAGetLastError() <> WSA_IO_PENDING Then
			IrcClientCloseConnection(pIrcClient)
			Return False
		End If
		
	End If
	
	Return True
	
End Function

Function FindCrLfA( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pFindIndex As Integer Ptr _
	)As Boolean
	
	' Минус 2 потому что один байт под Lf и один, чтобы не выйти за границу
	For i As Integer = 0 To pIrcClient->ClientRawBufferLength - 2
		
		If pIrcClient->ClientRawBuffer[i] = 13 AndAlso pIrcClient->ClientRawBuffer[i + 1] = 10 Then
			*pFindIndex = i
			Return True
		End If
		
	Next
	
	*pFindIndex = 0
	Return False
	
End Function

Sub ReceiveCompletionROUTINE( _
		ByVal dwError As DWORD, _
		ByVal cbTransferred As DWORD, _
		ByVal lpOverlapped As LPWSAOVERLAPPED, _
		ByVal dwFlags As DWORD _
	)
	
	Dim pIrcClient As IrcClient Ptr = lpOverlapped->hEvent
	
	If dwError <> 0 Then
		IrcClientCloseConnection(pIrcClient)
		Exit Sub
	End If
	
	pIrcClient->ClientRawBufferLength += CInt(cbTransferred)
	pIrcClient->ClientRawBuffer[pIrcClient->ClientRawBufferLength] = 0
	
	Dim CrLfIndex As Integer = 0
	Dim FindCrLfResult As Boolean = FindCrLfA(pIrcClient, @CrLfIndex)
	
	If FindCrLfResult = False Then
		
		If pIrcClient->ClientRawBufferLength >= IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM Then
			FindCrLfResult = True
			CrLfIndex = IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM - 2
			pIrcClient->ClientRawBufferLength = IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM
		End If
		
	End If
	
	Do While FindCrLfResult
		pIrcClient->ClientRawBuffer[CrLfIndex] = 0
		
		Dim ServerResponse As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
		MultiByteToWideChar(pIrcClient->CodePage, 0, @pIrcClient->ClientRawBuffer, -1, @ServerResponse, IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1)
		
		Dim NewBufferStartingIndex As Integer = CrLfIndex + 2
		
		If NewBufferStartingIndex = pIrcClient->ClientRawBufferLength Then
			pIrcClient->ClientRawBuffer[0] = 0
			pIrcClient->ClientRawBufferLength = 0
		Else
			memmove(@pIrcClient->ClientRawBuffer, @pIrcClient->ClientRawBuffer[NewBufferStartingIndex], IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM - NewBufferStartingIndex + 1)
			pIrcClient->ClientRawBufferLength -= NewBufferStartingIndex
		End If
		
		If CUInt(pIrcClient->lpfnReceivedRawMessageEvent) Then
			pIrcClient->lpfnReceivedRawMessageEvent(pIrcClient->AdvancedClientData, @ServerResponse)
		End If
		
		If ParseData(pIrcClient, @ServerResponse) = False Then
			IrcClientCloseConnection(pIrcClient)
			Exit Sub
		End If
		
		FindCrLfResult = FindCrLfA(pIrcClient, @CrLfIndex)
	Loop
	
	StartRecvOverlapped(pIrcClient)
	
End Sub
