#include "SendData.bi"
#include "CharacterConstants.bi"

Type SendOverlappedData
	Dim SendOverlapped As WSAOVERLAPPED
	Dim pIrcClient As IrcClient Ptr
	Dim SafeBuffer As ValueBSTR
	Dim SendBuffer As ZString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM * 3 + 1) = Any
End Type

Declare Sub SendCompletionROUTINE( _
	ByVal dwError As DWORD, _
	ByVal cbTransferred As DWORD, _
	ByVal lpOverlapped As LPWSAOVERLAPPED, _
	ByVal dwFlags As DWORD _
)

Function StartSendOverlapped( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByRef strData As ValueBSTR _
	)As HRESULT
	
	Dim hr As HRESULT = E_OUTOFMEMORY
	Dim pSendOverlappedData As SendOverlappedData Ptr = HeapAlloc( _
		pIrcClient->hHeap, _
		0, _
		SizeOf(SendOverlappedData) _
	)
	
	If pSendOverlappedData <> NULL Then
		
		pSendOverlappedData->SafeBuffer = strData
		' lstrcpyn(@pSendOverlappedData->SafeBuffer, strData, IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM - 2)
		
		Dim SendBufferLength As Long = WideCharToMultiByte( _
			pIrcClient->CodePage, _
			0, _
			Cast(WString Ptr, pSendOverlappedData->SafeBuffer), _
			-1, _
			@pSendOverlappedData->SendBuffer, _
			IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1, _
			0, _
			0 _
		)
		hr = HRESULT_FROM_WIN32(GetLastError)
		
		If SendBufferLength <> 0 Then
			' Без учёта нулевого символа
			SendBufferLength -= 1
			
			ZeroMemory(@pSendOverlappedData->SendOverlapped, SizeOf(WSAOVERLAPPED))
			pSendOverlappedData->SendOverlapped.hEvent = pSendOverlappedData
			pSendOverlappedData->pIrcClient = pIrcClient
			
			Const CrLfALength As Integer = 2
			Dim CrLfA(0 To CrLfALength - 1) As Byte = {Characters.CarriageReturn, Characters.LineFeed}
			
			Const SendBufLength As Integer = 2
			Dim SendBuf(0 To SendBufLength - 1) As WSABUF = Any
			SendBuf(0).len = Cast(ULONG, SendBufferLength)
			SendBuf(0).buf = @pSendOverlappedData->SendBuffer
			
			SendBuf(1).len = Cast(ULONG, CrLfALength)
			SendBuf(1).buf = @CrLfA(0)
			
			Const dwSendFlags As DWORD = 0
			Const NumberOfBytesSent As DWORD = NULL
			Dim res As Long = WSASend( _
				pIrcClient->ClientSocket, _
				@SendBuf(0), _
				Cast(DWORD, SendBufLength), _
				NumberOfBytesSent, _
				dwSendFlags, _
				@pSendOverlappedData->SendOverlapped, _
				@SendCompletionROUTINE _
			)
			Dim ErrorCode As Long = WSAGetLastError()
			hr = HRESULT_FROM_WIN32(ErrorCode)
			
			If res = 0 Then
				Return S_OK
			End If
			
			If ErrorCode = WSA_IO_PENDING Then
				Return S_OK
			End If
			
		End If
		
		HeapFree(pIrcClient->hHeap, 0, pSendOverlappedData)
		
	End If
	
	Return hr
	
End Function

Sub SendCompletionROUTINE( _
		ByVal dwError As DWORD, _
		ByVal cbTransferred As DWORD, _
		ByVal lpOverlapped As LPWSAOVERLAPPED, _
		ByVal dwFlags As DWORD _
	)
	
	Dim pSendOverlappedData As SendOverlappedData Ptr = lpOverlapped->hEvent
	Dim pIrcClient As IrcClient Ptr = pSendOverlappedData->pIrcClient
	
	If dwError <> 0 Then
		pIrcClient->ErrorCode = HRESULT_FROM_WIN32(dwError)
		SetEvent(pIrcClient->hEvent)
		Exit Sub
	End If
	
	If CUInt(pIrcClient->lpfnSendedRawMessageEvent) Then
		pIrcClient->lpfnSendedRawMessageEvent(pIrcClient->AdvancedClientData, pSendOverlappedData->SafeBuffer)
	End If
	
	HeapFree(pIrcClient->hHeap, 0, pSendOverlappedData)
	
End Sub
