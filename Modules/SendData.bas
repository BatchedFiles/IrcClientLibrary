#include "SendData.bi"
#include "CharacterConstants.bi"

'IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM - Len(CrLf)
Const SENDOVERLAPPEDDATA_BUFFERLENGTHMAXIMUM As Integer = IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM - 2

Type SendOverlappedData
	Dim SendOverlapped As WSAOVERLAPPED
	Dim pIrcClient As IrcClient Ptr
	Dim BufferLength As Long
	' Без завершающего нулевого символа
	Dim Buffer As ZString * SENDOVERLAPPEDDATA_BUFFERLENGTHMAXIMUM
End Type

Const CrLfALength As ULONG = 2

Type CrLfA
	Dim Cr As Byte
	Dim Lf As Byte
End Type

Const SendBuffersCount As DWORD = 2

Type SendBuffers
	Dim Bytes As WSABUF
	Dim CrLf As WSABUF
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
		
		pSendOverlappedData->BufferLength = WideCharToMultiByte( _
			pIrcClient->CodePage, _
			0, _
			Cast(WString Ptr, strData), _
			Len(strData), _
			@pSendOverlappedData->Buffer, _
			SENDOVERLAPPEDDATA_BUFFERLENGTHMAXIMUM, _
			NULL, _
			NULL _
		)
		
		If pSendOverlappedData->BufferLength <> 0 Then
			
			ZeroMemory(@pSendOverlappedData->SendOverlapped, SizeOf(WSAOVERLAPPED))
			
			pSendOverlappedData->pIrcClient = pIrcClient
			
			Dim CrLf As CrLfA = Any
			CrLf.Cr = Characters.CarriageReturn
			CrLf.Lf = Characters.LineFeed
			
			Dim SendBuf As SendBuffers = Any
			SendBuf.Bytes.len = Cast(ULONG, min(pSendOverlappedData->BufferLength, SENDOVERLAPPEDDATA_BUFFERLENGTHMAXIMUM))
			SendBuf.Bytes.buf = @pSendOverlappedData->Buffer
			
			SendBuf.CrLf.len = CrLfALength
			SendBuf.CrLf.buf = Cast(CHAR Ptr, @CrLf)
			
			Const dwSendFlags As DWORD = 0
			Dim res As Long = WSASend( _
				pIrcClient->ClientSocket, _
				CPtr(WSABUF Ptr, @SendBuf), _
				SendBuffersCount, _
				NULL, _
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
		
		hr = HRESULT_FROM_WIN32(GetLastError())
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
	
	Dim pSendOverlappedData As SendOverlappedData Ptr = CPtr(SendOverlappedData Ptr, lpOverlapped)
	Dim pIrcClient As IrcClient Ptr = pSendOverlappedData->pIrcClient
	
	If dwError <> 0 Then
		pIrcClient->ErrorCode = HRESULT_FROM_WIN32(dwError)
		SetEvent(pIrcClient->hEvent)
		Exit Sub
	End If
	
	If CUInt(pIrcClient->Events.lpfnSendedRawMessageEvent) Then
		pIrcClient->Events.lpfnSendedRawMessageEvent(pIrcClient->lpParameter, @pSendOverlappedData->Buffer, pSendOverlappedData->BufferLength)
	End If
	
	HeapFree(pIrcClient->hHeap, 0, pSendOverlappedData)
	
End Sub
