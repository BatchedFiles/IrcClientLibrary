#include "SendData.bi"

Function SendData( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal strData As WString Ptr _
	)As Boolean
	
	Dim SafeBuffer As WString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1) = Any
	lstrcpyn(@SafeBuffer, strData, IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM - 2)
	
	Dim SendBuffer As ZString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM * 3 + 1) = Any
	Dim SendBufferLength As Integer = WideCharToMultiByte( _
		pIrcClient->CodePage, _
		0, _
		@SafeBuffer, _
		-1, _
		@SendBuffer, _
		IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1, _
		0, _
		0 _
	) - 1
	
	SendBuffer[SendBufferLength] = 13
	SendBuffer[SendBufferLength + 1] = 10
	
	If send(pIrcClient->ClientSocket, @SendBuffer, SendBufferLength + 1, 0) = SOCKET_ERROR Then
		Return False
	End If
	
	If CUInt(pIrcClient->lpfnSendedRawMessageEvent) Then
		pIrcClient->lpfnSendedRawMessageEvent(pIrcClient->AdvancedClientData, strData)
	End If
	
	Return True
	
End Function