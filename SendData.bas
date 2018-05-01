#include "SendData.bi"
#include "StringConstants.bi"

Function SendData( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal strData As WString Ptr _
	)As Boolean
	
	Dim SafeBuffer As WString * (IrcClient.MaxBytesCount + 1) = Any
	lstrcpyn(@SafeBuffer, strData, IrcClient.MaxBytesCount - 2)
	
	Dim SendBuffer As ZString * (IrcClient.MaxBytesCount * 3 + 1) = Any
	Dim SendBufferLength As Integer = WideCharToMultiByte(pIrcClient->CodePage, 0, @SafeBuffer, -1, @SendBuffer, (IrcClient.MaxBytesCount + 1), 0, 0) - 1
	
	SendBuffer[SendBufferLength] = 13
	SendBuffer[SendBufferLength + 1] = 10
	
	If send(pIrcClient->ClientSocket, @SendBuffer, SendBufferLength + 1, 0) = SOCKET_ERROR Then
		Return False
	End If
	
	If CInt(pIrcClient->SendedRawMessageEvent) Then
		pIrcClient->SendedRawMessageEvent(pIrcClient->AdvancedClientData, strData)
	End If
	
	Return True
	
End Function