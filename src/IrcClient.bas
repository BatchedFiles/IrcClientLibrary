#include "IrcClient.bi"
#include "NetworkClient.bi"
#include "SendData.bi"
#include "ReceiveData.bi"

Const TenMinutesInMilliSeconds As DWORD = 10 * 60 * 1000

Const EmptyString = ""

Const PingString = "PING"
Const PongString = "PONG"
Const TopicString = "TOPIC"
Const SQuitString = "SQUIT"
Const QuitString = "QUIT"
Const NickString = "NICK"
Const ErrorString = "ERROR"
Const PartString = "PART"
Const PrivateMessage = "PRIVMSG"
Const InviteString = "INVITE"
Const JoinString = "JOIN"
Const KickString = "KICK"
Const ModeString = "MODE"
Const NoticeString = "NOTICE"
Const WhoString = "WHO"
Const WhoIsString = "WHOIS"

Const NickStringWithSpace = "NICK "
Const PingStringWithSpace = "PING "
Const PongStringWithSpace = "PONG "
Const SpaceWithCommaString = " :"

Const UserInfoString = "USERINFO"
Const UserInfoStringWithSpace = "USERINFO "
Const TimeString = "TIME"
Const TimeStringWithSpace = "TIME "
Const VersionString = "VERSION"
Const VersionStringWithSpace = "VERSION "
Const ActionString = "ACTION"
Const ActionStringWithSpace = "ACTION "
Const DccSendWithSpace = "DCC SEND "

Const DefaultBotNameSepVisible = " 0 * :"
Const DefaultBotNameSepInvisible = " 8 * :"
Const PassStringWithSpace = "PASS "
Const UserStringWithSpace = "USER "

Const TopicStringWithSpace = "TOPIC "
Const NoticeStringWithSpace = "NOTICE "
Const JoinStringWithSpace = "JOIN "
Const PrivateMessageWithSpace = "PRIVMSG "
Const PartStringWithSpace = "PART "
Const QuitStringWithSpaceComma = "QUIT :"
Const WhoStringWithSpace = "WHO "
Const WhoIsStringWithSpace = "WHOIS "

Const JoinStringWithSpaceLength As Integer = 5
Const PartStringWithSpaceLength As Integer = 5
Const QuitStringLength As Integer = 4
Const QuitStringWithSpaceCommaLength As Integer = 6
Const PrivateMessageWithSpaceLength As Integer = 8
Const TopicStringWithSpaceLength As Integer = 6
Const NoticeStringWithSpaceLength As Integer = 7
Const PongStringWithSpaceLength As Integer = 5
Const PingStringWithSpaceLength As Integer = 5
Const PingStringLength As Integer = 4
Const SpaceWithCommaStringLength As Integer = 2
Const PassStringWithSpaceLength As Integer = 5
Const NickStringWithSpaceLength As Integer = 5
Const UserStringWithSpaceLength As Integer = 5
Const WhoStringWithSpaceLength As Integer = 4
Const WhoIsStringWithSpaceLength As Integer = 6
Const DefaultBotNameSepVisibleLength As Integer = 6
Const DefaultBotNameSepInvisibleLength As Integer = 6
Const ActionStringWithSpaceLength As Integer = 7
Const UserInfoStringLength As Integer = 8
Const UserInfoStringWithSpaceLength As Integer = 9
Const TimeStringLength As Integer = 4
Const TimeStringWithSpaceLength As Integer = 5
Const VersionStringLength As Integer = 7
Const VersionStringWithSpaceLength As Integer = 8
Const DccSendWithSpaceLength As Integer = 9

Const NewLineString = !"\r\n"
Const NewLineStringLength As Integer = 2

'IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM - Len(CrLf)
Const SENDOVERLAPPEDDATA_BUFFERLENGTHMAXIMUM As Integer = IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM - 2

Const SendBuffersCount As DWORD = 2

Const CrLfALength As ULONG = 2

Enum IrcCommand
	Ping
	PrivateMessage
	Join
	Quit
	Part
	Notice
	Nick
	Error
	Kick
	Mode
	Topic
	Invite
	Pong
	SQuit
End Enum

Enum CtcpMessageKind
	Ping
	Action
	Time
	UserInfo
	Version
	ClientInfo
	Echo
	Finger
	Utc
	None
End Enum

Type _IrcEvents
	lpfnSendedRawMessageEvent As OnSendedRawMessageEvent
	lpfnReceivedRawMessageEvent As OnReceivedRawMessageEvent
	lpfnServerErrorEvent As OnServerErrorEvent
	lpfnNumericMessageEvent As OnNumericMessageEvent
	lpfnServerMessageEvent As OnServerMessageEvent
	lpfnNoticeEvent As OnNoticeEvent
	lpfnChannelNoticeEvent As OnChannelNoticeEvent
	lpfnChannelMessageEvent As OnChannelMessageEvent
	lpfnPrivateMessageEvent As OnPrivateMessageEvent
	lpfnUserJoinedEvent As OnUserJoinedEvent
	lpfnUserLeavedEvent As OnUserLeavedEvent
	lpfnNickChangedEvent As OnNickChangedEvent
	lpfnTopicEvent As OnTopicEvent
	lpfnQuitEvent As OnQuitEvent
	lpfnKickEvent As OnKickEvent
	lpfnInviteEvent As OnInviteEvent
	lpfnPingEvent As OnPingEvent
	lpfnPongEvent As OnPongEvent
	lpfnModeEvent As OnModeEvent
	lpfnCtcpPingRequestEvent As OnCtcpPingRequestEvent
	lpfnCtcpTimeRequestEvent As OnCtcpTimeRequestEvent
	lpfnCtcpUserInfoRequestEvent As OnCtcpUserInfoRequestEvent
	lpfnCtcpVersionRequestEvent As OnCtcpVersionRequestEvent
	lpfnCtcpActionEvent As OnCtcpActionEvent
	lpfnCtcpPingResponseEvent As OnCtcpPingResponseEvent
	lpfnCtcpTimeResponseEvent As OnCtcpTimeResponseEvent
	lpfnCtcpUserInfoResponseEvent As OnCtcpUserInfoResponseEvent
	lpfnCtcpVersionResponseEvent As OnCtcpVersionResponseEvent
End Type

Type IrcEvents As _IrcEvents

Type LPIRCEVENTS As _IrcEvents Ptr

Type _RawBuffer
	Dim Length As Integer
	' Без завершающего нулевого символа
	Dim Buffer As ZString * IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM
End Type

Type RawBuffer As _RawBuffer

Type LPRAWBUFFER As _RawBuffer Ptr

Type IrcCommandProcessor As Function(ByVal pIrcClient As IrcClient Ptr, ByVal pPrefix As IrcPrefix Ptr, ByVal pwszIrcParam1 As WString Ptr, ByRef bstrIrcMessage As ValueBSTR)As HRESULT

Type IrcPrefixInternal
	Dim Nick As ValueBSTR
	Dim User As ValueBSTR
	Dim Host As ValueBSTR
End Type

Type _IrcClient
	Dim RecvOverlapped As WSAOVERLAPPED
	Dim lpParameter As LPCLIENTDATA
	Dim hEvent As HANDLE
	Dim hHeap As HANDLE
	Dim ClientSocket As SOCKET
	Dim Events As IrcEvents
	Dim CodePage As Integer
	Dim ClientNick As ValueBSTR
	Dim ClientVersion As ValueBSTR
	Dim ClientUserInfo As ValueBSTR
	Dim ReceiveBuffer As RawBuffer
	Dim ErrorCode As HRESULT
	Dim IsInitialized As Boolean
End Type

Type SendOverlappedData
	Dim SendOverlapped As WSAOVERLAPPED
	Dim pIrcClient As IrcClient Ptr
	Dim BufferLength As Long
	' Без завершающего нулевого символа
	Dim Buffer As ZString * SENDOVERLAPPEDDATA_BUFFERLENGTHMAXIMUM
End Type

Type CrLfA
	Dim Cr As Byte
	Dim Lf As Byte
End Type

Type SendBuffers
	Dim Bytes As WSABUF
	Dim CrLf As WSABUF
End Type

Declare Function FindCrLfA( _
		ByVal Buffer As ZString Ptr, _
		ByVal BufferLength As Integer, _
		ByVal pIndex As Integer Ptr _
)As Boolean

Declare Sub ReceiveCompletionROUTINE( _
	ByVal dwError As DWORD, _
	ByVal cbTransferred As DWORD, _
	ByVal lpOverlapped As LPWSAOVERLAPPED, _
	ByVal dwFlags As DWORD _
)

Declare Function IrcClientSendAdmin( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Server As BSTR _
)As HRESULT

Declare Function IrcClientSendInfo( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Server As BSTR _
)As HRESULT

Declare Function IrcClientSendAway( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal MessageText As BSTR _
)As HRESULT

Declare Function IrcClientSendIsON( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal NickList As BSTR _
)As HRESULT

Declare Function IrcClientSendKick( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal Channel As BSTR, _
	ByVal UserName As BSTR, _
	ByVal MessageText As BSTR _
)As HRESULT

Declare Function IrcClientSendInvite( _
	ByVal pIrcClient As IrcClient Ptr, _
	ByVal UserName As BSTR, _
	ByVal Channel As BSTR _
)As HRESULT

Declare Sub SendCompletionROUTINE( _
	ByVal dwError As DWORD, _
	ByVal cbTransferred As DWORD, _
	ByVal lpOverlapped As LPWSAOVERLAPPED, _
	ByVal dwFlags As DWORD _
)

Function ResolveHostA( _
		ByVal Host As PCSTR, _
		ByVal Port As PCSTR, _
		ByVal ppAddressList As addrinfo Ptr Ptr _
	)As HRESULT
	
	Dim hints As addrinfo
	With hints
		.ai_family = AF_UNSPEC ' AF_INET или AF_INET6
		.ai_socktype = SOCK_STREAM
		.ai_protocol = IPPROTO_TCP
	End With
	
	*ppAddressList = NULL
	
	If getaddrinfo(Host, Port, @hints, ppAddressList) = 0 Then
		
		Return S_OK
		
	End If
	
	Return HRESULT_FROM_WIN32(WSAGetLastError())
	
End Function

Function ResolveHostW( _
		ByVal Host As PCWSTR, _
		ByVal Port As PCWSTR, _
		ByVal ppAddressList As addrinfoW Ptr Ptr _
	)As HRESULT
	
	Dim hints As addrinfoW
	With hints
		.ai_family = AF_UNSPEC ' AF_INET или AF_INET6
		.ai_socktype = SOCK_STREAM
		.ai_protocol = IPPROTO_TCP
	End With
	
	*ppAddressList = NULL
	
	If GetAddrInfoW(Host, Port, @hints, ppAddressList) = 0 Then
		
		Return S_OK
		
	End If
	
	Return HRESULT_FROM_WIN32(WSAGetLastError())
	
End Function

Function CreateSocketAndBindA( _
		ByVal LocalAddress As PCSTR, _
		ByVal LocalPort As PCSTR, _
		ByVal pSocket As SOCKET Ptr _
	)As HRESULT
	
	Dim ClientSocket As SOCKET = WSASocket(AF_UNSPEC, SOCK_STREAM, IPPROTO_TCP, NULL, 0, WSA_FLAG_OVERLAPPED)
	
	If ClientSocket = INVALID_SOCKET Then
		
		Return HRESULT_FROM_WIN32(WSAGetLastError())
		
	End If
	
	Dim pAddressList As addrinfo Ptr = NULL
	Dim hr As HRESULT = ResolveHostA(LocalAddress, LocalPort, @pAddressList)
	
	If FAILED(hr) Then
		
		Return HRESULT_FROM_WIN32(WSAGetLastError())
		
	End If
	
	Dim pAddress As addrinfo Ptr = pAddressList
	Dim BindResult As Integer = Any
	
	Dim e As Long = 0
	Do
		BindResult = bind(ClientSocket, Cast(LPSOCKADDR, pAddress->ai_addr), pAddress->ai_addrlen)
		e = WSAGetLastError()
		
		If BindResult = 0 Then
			Exit Do
		End If
		
		pAddress = pAddress->ai_next
		
	Loop Until pAddress = 0
	
	FreeAddrInfo(pAddressList)
	
	If BindResult <> 0 Then
		
		Return HRESULT_FROM_WIN32(e)
		
	End If
	
	*pSocket = ClientSocket
	Return S_OK
	
End Function

Function CreateSocketAndBindW( _
		ByVal LocalAddress As PCWSTR, _
		ByVal LocalPort As PCWSTR, _
		ByVal pSocket As SOCKET Ptr _
	)As HRESULT
	
	Dim ClientSocket As SOCKET = WSASocket(AF_UNSPEC, SOCK_STREAM, IPPROTO_TCP, NULL, 0, WSA_FLAG_OVERLAPPED)
	
	If ClientSocket = INVALID_SOCKET Then
		
		Return HRESULT_FROM_WIN32(WSAGetLastError())
		
	End If
	
	Dim pAddressList As addrinfoW Ptr = NULL
	Dim hr As HRESULT = ResolveHostW(LocalAddress, LocalPort, @pAddressList)
	
	If FAILED(hr) Then
		
		closesocket(ClientSocket)
		Return hr
		
	End If
	
	Dim pAddress As addrinfoW Ptr = pAddressList
	Dim BindResult As Long = Any
	
	Dim e As Long = 0
	Do
		BindResult = bind(ClientSocket, Cast(LPSOCKADDR, pAddress->ai_addr), pAddress->ai_addrlen)
		e = WSAGetLastError()
		
		If BindResult = 0 Then
			Exit Do
		End If
		
		pAddress = pAddress->ai_next
		
	Loop Until pAddress = 0
	
	FreeAddrInfoW(pAddressList)
	
	If BindResult <> 0 Then
		
		Return HRESULT_FROM_WIN32(e)
		
	End If
	
	*pSocket = ClientSocket
	Return S_OK
	
End Function

Function CloseSocketConnection( _
		ByVal ClientSocket As SOCKET _
	)As HRESULT
	
	Dim res As Integer = shutdown(ClientSocket, SD_BOTH)
	
	If res <> 0 Then
		
		Dim e As ULONG = WSAGetLastError()
		Dim hr As HRESULT = HRESULT_FROM_WIN32(e)
		
		Return hr
		
	End If
	
	res = closesocket(ClientSocket)
	
	If res <> 0 Then
		
		Dim e As ULONG = WSAGetLastError()
		Dim hr As HRESULT = HRESULT_FROM_WIN32(e)
		
		Return hr
		
	End If
	
	Return S_OK
	
End Function

Function SetReceiveTimeout( _
		ByVal ClientSocket As SOCKET, _
		ByVal dwMilliseconds As DWORD _
	)As HRESULT
	
	Dim res As Integer = setsockopt( _
		ClientSocket, _
		SOL_SOCKET, _
		SO_RCVTIMEO, _
		CPtr(ZString Ptr, @dwMilliseconds), _
		SizeOf(DWORD) _
	)
	
	If res <> 0 Then
		
		Dim e As Integer = WSAGetLastError()
		Dim hr As HRESULT = HRESULT_FROM_WIN32(e)
		
		Return hr
		
	End If
	
	Return S_OK
	
End Function

Function ConnectToServerA( _
		ByVal LocalAddress As PCSTR, _
		ByVal LocalPort As PCSTR, _
		ByVal RemoteAddress As PCSTR, _
		ByVal RemotePort As PCSTR, _
		ByVal pSocket As SOCKET Ptr _
	)As HRESULT
	
	Dim ClientSocket As SOCKET = Any
	Dim hr As HRESULT = CreateSocketAndBindA(LocalAddress, LocalPort, @ClientSocket)
	
	If FAILED(hr) Then
		
		Return hr
		
	End If
	
	Dim pAddressList As addrinfo Ptr = NULL
	hr = ResolveHostA(RemoteAddress, RemotePort, @pAddressList)
	
	If FAILED(hr) Then
		
		closesocket(ClientSocket)
		Return HRESULT_FROM_WIN32(WSAGetLastError())
		
	End If
	
	Dim pAddress As addrinfo Ptr = pAddressList
	Dim ConnectResult As Integer = Any
	
	Dim e As Long = 0
	Do
		ConnectResult = connect(ClientSocket, Cast(LPSOCKADDR, pAddress->ai_addr), pAddress->ai_addrlen)
		e = WSAGetLastError()
		
		If ConnectResult = 0 Then
			Exit Do
		End If
		
		pAddress = pAddress->ai_next
		
	Loop Until pAddress = 0
	
	FreeAddrInfo(pAddressList)
	
	If ConnectResult <> 0 Then
		
		closesocket(ClientSocket)
		Return HRESULT_FROM_WIN32(e)
		
	End If
	
	*pSocket = ClientSocket
	Return S_OK
	
End Function

Function ConnectToServerW( _
		ByVal LocalAddress As PCWSTR, _
		ByVal LocalPort As PCWSTR, _
		ByVal RemoteAddress As PCWSTR, _
		ByVal RemotePort As PCWSTR, _
		ByVal pSocket As SOCKET Ptr _
	)As HRESULT
	
	Dim ClientSocket As SOCKET = Any
	Dim hr As HRESULT = CreateSocketAndBindW(LocalAddress, LocalPort, @ClientSocket)
	
	If FAILED(hr) Then
		
		Return hr
		
	End If
	
	Dim pAddressList As addrinfoW Ptr = NULL
	hr = ResolveHostW(RemoteAddress, RemotePort, @pAddressList)
	
	If FAILED(hr) Then
		
		closesocket(ClientSocket)
		Return HRESULT_FROM_WIN32(WSAGetLastError())
		
	End If
	
	Dim pAddress As addrinfoW Ptr = pAddressList
	Dim ConnectResult As Integer = Any
	
	Dim e As Long = 0
	Do
		ConnectResult = connect(ClientSocket, Cast(LPSOCKADDR, pAddress->ai_addr), pAddress->ai_addrlen)
		e = WSAGetLastError()
		
		If ConnectResult = 0 Then
			Exit Do
		End If
		
		pAddress = pAddress->ai_next
		
	Loop Until pAddress = 0
	
	FreeAddrInfoW(pAddressList)
	
	If ConnectResult <> 0 Then
		
		closesocket(ClientSocket)
		Return HRESULT_FROM_WIN32(e)
		
	End If
	
	*pSocket = ClientSocket
	Return S_OK
	
End Function

Function FindCrLfA( _
		ByVal Buffer As ZString Ptr, _
		ByVal BufferLength As Integer, _
		ByVal pIndex As Integer Ptr _
	)As Boolean
	
	For i As Integer = 0 To BufferLength - NewLineStringLength
		If Buffer[i] = Characters.CarriageReturn AndAlso Buffer[i + 1] = Characters.LineFeed Then
			*pIndex = i
			Return True
		End If
	Next
	
	*pIndex = 0
	Return False
	
End Function

Function StartRecvOverlapped( _
		ByVal pIrcClient As IrcClient Ptr _
	)As HRESULT
	
	Const WsaBufBuffersCount As DWORD = 1
	Dim RecvBuf As WSABUF = Any
	RecvBuf.len = Cast(ULONG, IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM - pIrcClient->ReceiveBuffer.Length)
	RecvBuf.buf = @pIrcClient->ReceiveBuffer.Buffer[pIrcClient->ReceiveBuffer.Length]
	
	ZeroMemory(@pIrcClient->RecvOverlapped, SizeOf(WSAOVERLAPPED))
	
	Dim Flags As DWORD = 0
	Dim res As Long = WSARecv( _
		pIrcClient->ClientSocket, _
		@RecvBuf, _
		WsaBufBuffersCount, _
		NULL, _
		@Flags, _
		@pIrcClient->RecvOverlapped, _
		@ReceiveCompletionROUTINE _
	)
	If res <> 0 Then
		
		res = WSAGetLastError()
		If res <> WSA_IO_PENDING Then
			Return HRESULT_FROM_WIN32(res)
		End If
		
	End If
	
	Return S_OK
	
End Function

Sub ReceiveCompletionROUTINE( _
		ByVal dwError As DWORD, _
		ByVal cbTransferred As DWORD, _
		ByVal lpOverlapped As LPWSAOVERLAPPED, _
		ByVal dwFlags As DWORD _
	)
	
	Dim pIrcClient As IrcClient Ptr = CPtr(IrcClient Ptr, lpOverlapped)
	
	If dwError <> 0 Then
		pIrcClient->ErrorCode = HRESULT_FROM_WIN32(dwError)
		SetEvent(pIrcClient->hEvent)
		Exit Sub
	End If
	
	pIrcClient->ReceiveBuffer.Length += CInt(cbTransferred)
	
	Dim CrLfIndex As Integer = Any
	Dim FindCrLfResult As Boolean = FindCrLfA( _
		@pIrcClient->ReceiveBuffer.Buffer, _
		pIrcClient->ReceiveBuffer.Length, _
		@CrLfIndex _
	)
	
	If FindCrLfResult = False Then
		
		If pIrcClient->ReceiveBuffer.Length >= IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM Then
			FindCrLfResult = True
			CrLfIndex = IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM - 2
			pIrcClient->ReceiveBuffer.Length = IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM
		End If
		
	End If
	
	Do While FindCrLfResult
		
		Scope
			Dim bstrServerResponse As ValueBSTR = Any
			' bstrServerResponse.PlaceHolder
			' bstrServerResponse.BytesCount
			' bstrServerResponse.WChars
			Dim ServerResponseLength As Long = MultiByteToWideChar( _
				pIrcClient->CodePage, _
				0, _
				@pIrcClient->ReceiveBuffer.Buffer, _
				CrLfIndex, _
				@bstrServerResponse.WChars(0), _
				MAX_VALUEBSTR_BUFFER_LENGTH _
			)
			
			If ServerResponseLength <> 0 Then
				bstrServerResponse.BytesCount = ServerResponseLength * SizeOf(OLECHAR)
				bstrServerResponse.WChars(ServerResponseLength) = Characters.NullChar
				
				Scope
					If CUInt(pIrcClient->Events.lpfnReceivedRawMessageEvent) Then
						pIrcClient->Events.lpfnReceivedRawMessageEvent(pIrcClient->lpParameter, @pIrcClient->ReceiveBuffer.Buffer, CrLfIndex + 1)
					End If
				End Scope
				
				Scope
					Dim hr As HRESULT = ParseData(pIrcClient, bstrServerResponse)
					If FAILED(hr) Then
						pIrcClient->ErrorCode = hr
						SetEvent(pIrcClient->hEvent)
						Exit Sub
					End If
				End Scope
				
			End If
		End Scope
		
		Scope
			Dim NewStartingIndex As Integer = CrLfIndex + 2
			
			If NewStartingIndex = pIrcClient->ReceiveBuffer.Length Then
				pIrcClient->ReceiveBuffer.Length = 0
			Else
				memmove( _
					@pIrcClient->ReceiveBuffer.Buffer, _
					@pIrcClient->ReceiveBuffer.Buffer[NewStartingIndex], _
					IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM - NewStartingIndex + 1 _
				)
				pIrcClient->ReceiveBuffer.Length -= NewStartingIndex
			End If
		End Scope
		
		FindCrLfResult = FindCrLfA( _
			@pIrcClient->ReceiveBuffer.Buffer, _
			pIrcClient->ReceiveBuffer.Length, _
			@CrLfIndex _
		)
	Loop
	
	Dim hr As HRESULT = StartRecvOverlapped(pIrcClient)
	If FAILED(hr) Then
		pIrcClient->ErrorCode = hr
		SetEvent(pIrcClient->hEvent)
	End If
	
End Sub

Function IrcClientChangeNick( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Nick As BSTR _
	)As HRESULT
	
	'NICK space <nickname>
	
	Dim NickLength As Integer = SysStringLen(Nick)
	If NickLength <> 0 Then
		Dim SendString As ValueBSTR = Type<ValueBSTR>(NickStringWithSpace, NickStringWithSpaceLength)
		SendString &= Nick
		
		pIrcClient->ClientNick = Nick
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Function IrcClientQuitFromServer( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal QuitText As BSTR _
	)As HRESULT
	
	'QUIT [space :<QuitText>]
	
	Dim SendString As ValueBSTR = Any
	
	If SysStringLen(QuitText) <> 0 Then
		SendString = Type<ValueBSTR>(QuitStringWithSpaceComma, QuitStringWithSpaceCommaLength)
		SendString &= QuitText
	Else
		SendString = Type<ValueBSTR>(QuitString, QuitStringLength)
	End If
	
	Return StartSendOverlapped(pIrcClient, SendString)
	
End Function

Function IrcClientSendPong( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Server As BSTR _
	)As HRESULT
	
	'PONG space <Server>
	If SysStringLen(Server) <> 0 Then
		Dim SendString As ValueBSTR = Type<ValueBSTR>(PongStringWithSpace, PongStringWithSpaceLength)
		SendString &= Server
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Function IrcClientSendPing( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Server As BSTR _
	)As HRESULT
	
	' От сервера:
	'PING space :<Server>
	
	' От клиента:
	'PING space <Server>
	
	If SysStringLen(Server) <> 0 Then
		Dim SendString As ValueBSTR = Type<ValueBSTR>(PingStringWithSpace, PingStringWithSpaceLength)
		SendString &= Server
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Function IrcClientJoinChannel( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Channel As BSTR _
	)As HRESULT
	
	'JOIN space <channel>
	If SysStringLen(Channel) <> 0 Then
		Dim SendString As ValueBSTR = Type<ValueBSTR>(JoinStringWithSpace, JoinStringWithSpaceLength)
		SendString &= Channel
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Function IrcClientPartChannel( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Channel As BSTR, _
		ByVal PartText As BSTR _
	)As HRESULT
	
	'PART space <channel> [space :<partmessage>]
	If SysStringLen(Channel) <> 0 Then
		Dim SendString As ValueBSTR = Type<ValueBSTR>(PartStringWithSpace, PartStringWithSpaceLength)
		SendString &= Channel
		
		If SysStringLen(PartText) <> 0 Then
			SendString.Append(SpaceWithCommaString, SpaceWithCommaStringLength)
			SendString &= PartText
		End If
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Function IrcClientRetrieveTopic( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Channel As BSTR _
	)As HRESULT
	
	'TOPIC space <Channel>
	If SysStringLen(Channel) <> 0 Then
		Dim SendString As ValueBSTR = Type<ValueBSTR>(TopicStringWithSpace, TopicStringWithSpaceLength)
		SendString &= Channel
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Function IrcClientSetTopic( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Channel As BSTR, _
		ByVal Topic As BSTR _
	)As HRESULT
	
	'TOPIC <Channel> :<Topic>
	
	If SysStringLen(Channel) <> 0 Then
		Dim SendString As ValueBSTR = Type<ValueBSTR>(TopicStringWithSpace, TopicStringWithSpaceLength)
		SendString &= Channel
		SendString.Append(SpaceWithCommaString, SpaceWithCommaStringLength)
		SendString &= Topic
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Function IrcClientSendPrivateMessage( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal MessageTarget As BSTR, _
		ByVal MessageText As BSTR _
	)As HRESULT
	
	'PRIVMSG space <msgtarget> space : <text to be sent>
	
	If SysStringLen(MessageTarget) <> 0 AndAlso SysStringLen(MessageText) <> 0 Then
		
		Dim SendString As ValueBSTR = Type<ValueBSTR>(PrivateMessageWithSpace, PrivateMessageWithSpaceLength)
		SendString &= MessageTarget
		SendString.Append(SpaceWithCommaString, SpaceWithCommaStringLength)
		SendString &= MessageText
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Function IrcClientSendNotice( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal NoticeTarget As BSTR, _
		ByVal NoticeText As BSTR _
	)As HRESULT
	
	'NOTICE space <msgtarget> space : <text to be sent>
	
	If SysStringLen(NoticeTarget) <> 0 AndAlso SysStringLen(NoticeText) <> 0 Then
		Dim SendString As ValueBSTR = Type<ValueBSTR>(NoticeStringWithSpace, NoticeStringWithSpaceLength)
		SendString &= NoticeTarget
		SendString.Append(SpaceWithCommaString, SpaceWithCommaStringLength)
		SendString &= NoticeText
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Function IrcClientSendWho( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Nick As BSTR _
	)As HRESULT
	
	'WHO <nick>
	If SysStringLen(Nick) <> 0 Then
		Dim SendString As ValueBSTR = Type<ValueBSTR>(WhoStringWithSpace, WhoStringWithSpaceLength)
		SendString &= Nick
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Function IrcClientSendWhoIs( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Nick As BSTR _
	)As HRESULT
	
	'WHOIS <nick>
	If SysStringLen(Nick) <> 0 Then
		Dim SendString As ValueBSTR = Type<ValueBSTR>(WhoIsStringWithSpace, WhoIsStringWithSpaceLength)
		SendString &= Nick
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Function IrcClientSendCtcpPingRequest( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Nick As BSTR, _
		ByVal TimeStamp As BSTR _
	)As HRESULT
	
	'PRIVMSG space <Nick> space : SOH PING space<TimeStamp>SOH
	
	If SysStringLen(Nick) <> 0 AndAlso SysStringLen(TimeStamp) <> 0 Then
		
		Dim SendString As ValueBSTR = Type<ValueBSTR>(PrivateMessageWithSpace, PrivateMessageWithSpaceLength)
		SendString &= Nick
		SendString.Append(SpaceWithCommaString, SpaceWithCommaStringLength)
		SendString.Append(Characters.StartOfHeading)
		SendString.Append(PingStringWithSpace, PingStringWithSpaceLength)
		SendString &= TimeStamp
		SendString.Append(Characters.StartOfHeading)
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Function IrcClientSendCtcpTimeRequest( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Nick As BSTR _
	)As HRESULT
	
	'PRIVMSG space <Nick> space : SOH TIME SOH
	
	If SysStringLen(Nick) <> 0 Then
		
		Dim SendString As ValueBSTR = Type<ValueBSTR>(PrivateMessageWithSpace, PrivateMessageWithSpaceLength)
		SendString &= Nick
		SendString.Append(SpaceWithCommaString, SpaceWithCommaStringLength)
		SendString.Append(Characters.StartOfHeading)
		SendString.Append(TimeString, TimeStringLength)
		SendString.Append(Characters.StartOfHeading)
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Function IrcClientSendCtcpUserInfoRequest( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Nick As BSTR _
	)As HRESULT
	
	'PRIVMSG space <Nick> space : SOH USERINFO SOH
	
	If SysStringLen(Nick) <> 0 Then
		
		Dim SendString As ValueBSTR = Type<ValueBSTR>(PrivateMessageWithSpace, PrivateMessageWithSpaceLength)
		SendString &= Nick
		SendString.Append(SpaceWithCommaString, SpaceWithCommaStringLength)
		SendString.Append(Characters.StartOfHeading)
		SendString.Append(UserInfoString, UserInfoStringLength)
		SendString.Append(Characters.StartOfHeading)
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Function IrcClientSendCtcpVersionRequest( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Nick As BSTR _
	)As HRESULT
	
	'PRIVMSG space <Nick> space : SOH VERSION SOH
	
	If SysStringLen(Nick) <> 0 Then
		
		Dim SendString As ValueBSTR = Type<ValueBSTR>(PrivateMessageWithSpace, PrivateMessageWithSpaceLength)
		SendString &= Nick
		SendString.Append(SpaceWithCommaString, SpaceWithCommaStringLength)
		SendString.Append(Characters.StartOfHeading)
		SendString.Append(VersionString, VersionStringLength)
		SendString.Append(Characters.StartOfHeading)
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Function IrcClientSendCtcpAction( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Channel As BSTR, _
		ByVal MessageText As BSTR _
	)As HRESULT
	
	'PRIVMSG space <Channel> space : SOH ACTION space <MessageText>SOH
	
	If SysStringLen(Channel) <> 0 AndAlso SysStringLen(MessageText) <> 0 Then
		
		Dim SendString As ValueBSTR = Type<ValueBSTR>(PrivateMessageWithSpace, PrivateMessageWithSpaceLength)
		SendString &= Channel
		SendString.Append(SpaceWithCommaString, SpaceWithCommaStringLength)
		SendString.Append(Characters.StartOfHeading)
		SendString.Append(ActionStringWithSpace, ActionStringWithSpaceLength)
		SendString &= MessageText
		SendString.Append(Characters.StartOfHeading)
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Function IrcClientSendCtcpPingResponse( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Nick As BSTR, _
		ByVal TimeStamp As BSTR _
	)As HRESULT
	
	'NOTICE space <Nick> space : SOH PING space <TimeStamp>SOH
	
	If SysStringLen(Nick) <> 0 AndAlso SysStringLen(TimeStamp) <> 0 Then
		
		Dim SendString As ValueBSTR = Type<ValueBSTR>(NoticeStringWithSpace, NoticeStringWithSpaceLength)
		SendString &= Nick
		SendString.Append(SpaceWithCommaString, SpaceWithCommaStringLength)
		SendString.Append(Characters.StartOfHeading)
		SendString.Append(PingStringWithSpace, PingStringWithSpaceLength)
		SendString &= TimeStamp
		SendString.Append(Characters.StartOfHeading)
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Function IrcClientSendCtcpTimeResponse( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Nick As BSTR, _
		ByVal TimeValue As BSTR _
	)As HRESULT
	
	'NOTICE space <Nick> space : SOH TIME space <TimeValue>SOH
	
	If SysStringLen(Nick) <> 0 AndAlso SysStringLen(TimeValue) <> 0 Then
		
		Dim SendString As ValueBSTR = Type<ValueBSTR>(NoticeStringWithSpace, NoticeStringWithSpaceLength)
		SendString &= Nick
		SendString.Append(SpaceWithCommaString, SpaceWithCommaStringLength)
		SendString.Append(Characters.StartOfHeading)
		SendString.Append(TimeStringWithSpace, TimeStringWithSpaceLength)
		SendString &= TimeValue
		SendString.Append(Characters.StartOfHeading)
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Function IrcClientSendCtcpUserInfoResponse( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Nick As BSTR, _
		ByVal UserInfo As BSTR _
	)As HRESULT
	
	'NOTICE space <Nick> space : SOH USERINFO space <UserInfo>SOH
	
	If SysStringLen(Nick) <> 0 AndAlso SysStringLen(UserInfo) <> 0 Then
		
		Dim SendString As ValueBSTR = Type<ValueBSTR>(NoticeStringWithSpace, NoticeStringWithSpaceLength)
		SendString &= Nick
		SendString.Append(SpaceWithCommaString, SpaceWithCommaStringLength)
		SendString.Append(Characters.StartOfHeading)
		SendString.Append(UserInfoStringWithSpace, UserInfoStringWithSpaceLength)
		SendString &= UserInfo
		SendString.Append(Characters.StartOfHeading)
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Function IrcClientSendCtcpVersionResponse( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Nick As BSTR, _
		ByVal Version As BSTR _
	)As HRESULT
	
	'NOTICE space <Nick> space : SOH VERSION space <Version>SOH
	
	If SysStringLen(Nick) <> 0 AndAlso SysStringLen(Version) <> 0 Then
		
		Dim SendString As ValueBSTR = Type<ValueBSTR>(NoticeStringWithSpace, NoticeStringWithSpaceLength)
		SendString &= Nick
		SendString.Append(SpaceWithCommaString, SpaceWithCommaStringLength)
		SendString.Append(Characters.StartOfHeading)
		SendString.Append(VersionStringWithSpace, VersionStringWithSpaceLength)
		SendString &= Version
		SendString.Append(Characters.StartOfHeading)
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Function IrcClientSendDccSend( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Nick As BSTR, _
		ByVal FileName As BSTR, _
		ByVal IPAddress As BSTR, _
		ByVal Port As Integer, _
		ByVal FileLength As ULongInt _
	)As HRESULT
	
	'PRIVMSG space <Nick> space : SOH DCC SEND space <FileName> space <IPAddress> space <Port> [space <FileLength>]SOH
	
	If SysStringLen(Nick) <> 0 AndAlso SysStringLen(FileName) <> 0 AndAlso SysStringLen(IPAddress) <> 0 Then
		
		Dim wszPort As WString * 100 = Any
		_ltow(CLng(Port), @wszPort, 10)
		
		Dim SendString As ValueBSTR = Type<ValueBSTR>(PrivateMessageWithSpace, PrivateMessageWithSpaceLength)
		SendString &= Nick
		SendString.Append(SpaceWithCommaString, SpaceWithCommaStringLength)
		SendString.Append(Characters.StartOfHeading)
		SendString.Append(DccSendWithSpace, DccSendWithSpaceLength)
		SendString &= FileName
		SendString.Append(Characters.WhiteSpace)
		SendString &= IPAddress
		SendString.Append(Characters.WhiteSpace)
		SendString &= wszPort
		
		If FileLength > 0 Then
			Dim wszFileLength As WString * 64 = Any
			_i64tow(FileLength, @wszFileLength, 10)
			
			SendString.Append(Characters.WhiteSpace)
			SendString &= wszFileLength
		End If
		
		SendString.Append(Characters.StartOfHeading)
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Function IrcClientSendRawMessage( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal RawText As BSTR _
	)As HRESULT
	
	Dim SendString As ValueBSTR = Type<ValueBSTR>(RawText)
	
	Return StartSendOverlapped(pIrcClient, SendString)
	
End Function

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

Function GetIrcCommand( _
		ByVal w As WString Ptr, _
		ByVal pIrcCommand As IrcCommand Ptr _
	)As Boolean
	
	If lstrcmpW(w, @PingString) = 0 Then
		*pIrcCommand = IrcCommand.Ping
		Return True
	End If
	
	If lstrcmpW(w, @PrivateMessage) = 0 Then
		*pIrcCommand = IrcCommand.PrivateMessage
		Return True
	End If
	
	If lstrcmpW(w, @JoinString) = 0 Then
		*pIrcCommand = IrcCommand.Join
		Return True
	End If
	
	If lstrcmpW(w, @QuitString) = 0 Then
		*pIrcCommand = IrcCommand.Quit
		Return True
	End If
	
	If lstrcmpW(w, @PartString) = 0 Then
		*pIrcCommand = IrcCommand.Part
		Return True
	End If
	
	If lstrcmpW(w, @NoticeString) = 0 Then
		*pIrcCommand = IrcCommand.Notice
		Return True
	End If
	
	If lstrcmpW(w, @NickString) = 0 Then
		*pIrcCommand = IrcCommand.Nick
		Return True
	End If
	
	If lstrcmpW(w, @ErrorString) = 0 Then
		*pIrcCommand = IrcCommand.Error
		Return True
	End If
	
	If lstrcmpW(w, @KickString) = 0 Then
		*pIrcCommand = IrcCommand.Kick
		Return True
	End If
	
	If lstrcmpW(w, @ModeString) = 0 Then
		*pIrcCommand = IrcCommand.Mode
		Return True
	End If
	
	If lstrcmpW(w, @TopicString) = 0 Then
		*pIrcCommand = IrcCommand.Topic
		Return True
	End If
	
	If lstrcmpW(w, @InviteString) = 0 Then
		*pIrcCommand = IrcCommand.Invite
		Return True
	End If
	
	If lstrcmpW(w, @PongString) = 0 Then
		*pIrcCommand = IrcCommand.Pong
		Return True
	End If
	
	If lstrcmpW(w, @SQuitString) = 0 Then
		*pIrcCommand = IrcCommand.SQuit
		Return True
	End If
	
	Return False
	
End Function

Function IsNumericIrcCommand( _
		ByVal w As WString Ptr, _
		ByVal Length As Integer _
	)As Boolean
	
	If Length <> 3 Then
		Return False
	End If
	
	For i As Integer = 0 To 2
		If w[i] < Characters.DigitZero OrElse w[i] > Characters.DigitNine Then
			Return False
		End If
	Next
	
	Return True
	
End Function

Function GetIrcServerName( _
		ByVal strData As WString Ptr _
	)As WString Ptr
	
	Dim w As WString Ptr = StrChrW(strData, Characters.Colon)
	If w = NULL Then
		Return NULL
	End If
	
	Return w + 1
	
End Function

Function SeparateWordBySpace( _
		ByVal wStart As WString Ptr _
	)As WString Ptr
	
	Dim ws As WString Ptr = StrChrW(wStart, Characters.WhiteSpace)
	If ws = NULL Then
		Return NULL
	End If
	
	ws[0] = Characters.NullChar
	
	Return ws + 1
	
End Function

Function GetIrcMessageText( _
		ByVal strData As WString Ptr _
	)As WString Ptr
	
	':Qubick!~miranda@192.168.1.1 PRIVMSG ##freebasic :Hello World
	Dim w As WString Ptr = StrChrW(strData, Characters.Colon)
	If w = NULL Then
		Return NULL
	End If
	
	Return w + 1
	
End Function

Function GetCtcpCommand( _
		ByVal w As WString Ptr _
	)As CtcpMessageKind
	
	If lstrcmpW(w, @PingString) = 0 Then
		Return CtcpMessageKind.Ping
	End If
	
	If lstrcmpW(w, @ActionString) = 0 Then
		Return CtcpMessageKind.Action
	End If
	
	If lstrcmpW(w, @UserInfoString) = 0 Then
		Return CtcpMessageKind.UserInfo
	End If
	
	If lstrcmpW(w, @TimeString) = 0 Then
		Return CtcpMessageKind.Time
	End If
	
	If lstrcmpW(w, @VersionString) = 0 Then
		Return CtcpMessageKind.Version
	End If
	
	Return CtcpMessageKind.None
	
End Function

Function GetIrcPrefixInternal( _
		ByVal pIrcPrefixInternal As IrcPrefixInternal Ptr, _
		ByRef bstrIrcMessage As ValueBSTR _
	)As Integer
	
	'prefix     =  servername / ( nickname [ [ "!" user ] "@" host ] )
	':Qubick!~miranda@192.168.1.1 JOIN ##freebasic
	
	Dim IrcPrefixLength As Integer = Any
	Dim pNick As WString Ptr = Any
	Dim NickLength As Integer = Any
	Dim pUser As WString Ptr = Any
	Dim UserLength As Integer = Any
	Dim pHost As WString Ptr = Any
	Dim HostLength As Integer = Any
	
	If bstrIrcMessage.WChars(0) = Characters.Colon Then
		
		Dim pwszIrcMessage As WString Ptr = Cast(WString Ptr, @bstrIrcMessage.WChars(0))
		Dim pPrefixStart As WString Ptr = @bstrIrcMessage.WChars(1)
		Dim wWhiteSpaceChar As WString Ptr = StrChrW(pPrefixStart, Characters.WhiteSpace)
		
		If wWhiteSpaceChar <> NULL Then
			IrcPrefixLength = wWhiteSpaceChar - pwszIrcMessage - 1
			
			wWhiteSpaceChar[0] = Characters.NullChar
			
			pNick = pPrefixStart
			
			Dim wExclamationChar As WString Ptr = StrChrW(pPrefixStart, Characters.ExclamationMark)
			If wExclamationChar = NULL Then
				NickLength = wWhiteSpaceChar - pwszIrcMessage - 1
				pUser = @EmptyString
				UserLength = 0
				pHost = @EmptyString
				HostLength = 0
			Else
				NickLength = wExclamationChar - pwszIrcMessage - 1
				wExclamationChar[0] = Characters.NullChar
				
				pUser = @wExclamationChar[1]
				
				Dim wCommercialAtChar As WString Ptr = StrChrW(@wExclamationChar[1], Characters.CommercialAt)
				If wCommercialAtChar = NULL Then
					UserLength = wWhiteSpaceChar - wExclamationChar - 1
					
					pHost = @EmptyString
					HostLength = 0
				Else
					UserLength = wCommercialAtChar - wExclamationChar - 1
					wCommercialAtChar[0] = Characters.NullChar
					
					pHost = @wCommercialAtChar[1]
					HostLength = wWhiteSpaceChar - wCommercialAtChar - 1
				End If
			End If
			
		Else
			IrcPrefixLength = 0
			pNick = @EmptyString
			NickLength = 0
			pUser = @EmptyString
			UserLength = 0
			pHost = @EmptyString
			HostLength = 0
		End If
	Else
		IrcPrefixLength = 0
		pNick = @EmptyString
		NickLength = 0
		pUser = @EmptyString
		UserLength = 0
		pHost = @EmptyString
		HostLength = 0
	End If
	
	pIrcPrefixInternal->Nick = Type<ValueBSTR>(*pNick, NickLength)
	pIrcPrefixInternal->User = Type<ValueBSTR>(*pUser, UserLength)
	pIrcPrefixInternal->Host = Type<ValueBSTR>(*pHost, HostLength)
	
	Return IrcPrefixLength
	
End Function

Function IsCtcpMessage( _
		ByVal pwszMessageText As WString Ptr, _
		ByVal MessageTextLength As Integer _
	)As Boolean
	
	If MessageTextLength > 2 Then
		If pwszMessageText[0] = Characters.StartOfHeading Then
			If pwszMessageText[MessageTextLength - 1] = Characters.StartOfHeading Then
				Return True
			End If
		End If
	End If
	
	Return False
	
End Function

Function ProcessPingCommand( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pPrefix As IrcPrefix Ptr, _
		ByVal pwszIrcParam1 As WString Ptr, _
		ByRef bstrIrcMessage As ValueBSTR _
	)As HRESULT
	
	'PING :barjavel.freenode.net
	Dim ServerName As WString Ptr = GetIrcServerName(pwszIrcParam1)
	If ServerName <> 0 Then
		Dim pServerName As ValueBSTR Ptr = WStringPtrToValueBstrPtr(ServerName)
		pServerName->Length = bstrIrcMessage.GetTrailingNullChar() - ServerName
		
		If CUInt(pIrcClient->Events.lpfnPingEvent) Then
			pIrcClient->Events.lpfnPingEvent(pIrcClient->lpParameter, pPrefix, *pServerName)
		Else
			Return IrcClientSendPong(pIrcClient, *pServerName)
		End If
	End If
	
	Return S_OK
	
End Function

Function ProcessPrivateMessageCommand( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pPrefix As IrcPrefix Ptr, _
		ByVal pwszIrcParam1 As WString Ptr, _
		ByRef bstrIrcMessage As ValueBSTR _
	)As HRESULT
	
	':Angel!wings@irc.org PRIVMSG Wiz :Are you receiving this message ?
	
	Dim pwszMsgTarget As WString Ptr = pwszIrcParam1
	Dim pwszStartIrcParam2 As WString Ptr = SeparateWordBySpace(pwszIrcParam1)
	
	Dim pwszMessageText As WString Ptr = GetIrcMessageText(pwszStartIrcParam2)
	
	If pwszMessageText <> 0 Then
		Dim bstrMsgTarget As ValueBSTR = Type<ValueBSTR>(*pwszMsgTarget, pwszStartIrcParam2 - pwszMsgTarget - 1)
		
		Dim MessageTextLength As Integer = bstrIrcMessage.GetTrailingNullChar() - pwszMessageText
		
		If IsCtcpMessage(pwszMessageText, MessageTextLength) Then
			pwszMessageText += 1
			pwszMessageText[MessageTextLength - 1] = Characters.NullChar
			MessageTextLength -= 2
			
			Dim pwszStartCtcpParam As WString Ptr = SeparateWordBySpace(pwszMessageText)
			
			Select Case GetCtcpCommand(pwszMessageText)
				
				Case CtcpMessageKind.Ping
					':Angel!wings@irc.org PRIVMSG Qubick :PING 1402355972
					If pwszStartCtcpParam <> NULL Then
						Dim pCtcpParam As ValueBSTR Ptr = WStringPtrToValueBstrPtr(pwszStartCtcpParam)
						pCtcpParam->Length = MessageTextLength - PingStringWithSpaceLength
						
						If CUInt(pIrcClient->Events.lpfnCtcpPingRequestEvent) = 0 Then
							IrcClientSendCtcpPingResponse(pIrcClient, pPrefix->Nick, *pCtcpParam)
						Else
							pIrcClient->Events.lpfnCtcpPingRequestEvent(pIrcClient->lpParameter, pPrefix, bstrMsgTarget, *pCtcpParam)
						End If
					End If
					
				Case CtcpMessageKind.Action
					':Angel!wings@irc.org PRIVMSG Qubick :ACTION Any Text
					If pwszStartCtcpParam <> NULL Then
						If CUInt(pIrcClient->Events.lpfnCtcpActionEvent) Then
							
							Dim pCtcpParam As ValueBSTR Ptr = WStringPtrToValueBstrPtr(pwszStartCtcpParam)
							pCtcpParam->Length = MessageTextLength - ActionStringWithSpaceLength
							
							pIrcClient->Events.lpfnCtcpActionEvent(pIrcClient->lpParameter, pPrefix, bstrMsgTarget, *pCtcpParam)
						End If
					End If
					
				Case CtcpMessageKind.UserInfo
					':Angel!wings@irc.org PRIVMSG Qubick :USERINFO
					If CUInt(pIrcClient->Events.lpfnCtcpUserInfoRequestEvent) = 0 Then
						If Len(pIrcClient->ClientUserInfo) <> 0 Then
							IrcClientSendCtcpUserInfoResponse(pIrcClient, pPrefix->Nick, pIrcClient->ClientUserInfo)
						End If
					Else
						pIrcClient->Events.lpfnCtcpUserInfoRequestEvent(pIrcClient->lpParameter, pPrefix, bstrMsgTarget)
					End If
					
				Case CtcpMessageKind.Time
					':Angel!wings@irc.org PRIVMSG Qubick :TIME
					If CUInt(pIrcClient->Events.lpfnCtcpTimeRequestEvent) = 0 Then
						' Tue, 15 Nov 1994 12:45:26 GMT
						Const DateFormatString = "ddd, dd MMM yyyy "
						Const TimeFormatString = "HH:mm:ss GMT"
						Dim TimeValue As WString * 64 = Any
						Dim dtNow As SYSTEMTIME = Any
						
						GetSystemTime(@dtNow)
						
						Dim dtBufferLength As Integer = GetDateFormatW(LOCALE_INVARIANT, 0, @dtNow, @DateFormatString, @TimeValue, 31) - 1
						GetTimeFormatW(LOCALE_INVARIANT, 0, @dtNow, @TimeFormatString, @TimeValue[dtBufferLength], 31 - dtBufferLength)
						
						Return IrcClientSendCtcpTimeResponse(pIrcClient, pPrefix->Nick, @TimeValue)
					Else
						pIrcClient->Events.lpfnCtcpTimeRequestEvent(pIrcClient->lpParameter, pPrefix, bstrMsgTarget)
					End If
					
				Case CtcpMessageKind.Version
					':Angel!wings@irc.org PRIVMSG Qubick :VERSION
					If CUInt(pIrcClient->Events.lpfnCtcpVersionRequestEvent) = 0 Then
						If Len(pIrcClient->ClientVersion) <> 0 Then
							Return IrcClientSendCtcpVersionResponse(pIrcClient, pPrefix->Nick, pIrcClient->ClientVersion)
						End If
					Else
						pIrcClient->Events.lpfnCtcpVersionRequestEvent(pIrcClient->lpParameter, pPrefix, bstrMsgTarget)
					End If
					
			End Select
		Else
			Dim pMessageText As ValueBSTR Ptr = WStringPtrToValueBstrPtr(pwszMessageText)
			pMessageText->Length = MessageTextLength
			
			If lstrcmp(bstrMsgTarget, pIrcClient->ClientNick) = 0 Then
				If CUInt(pIrcClient->Events.lpfnPrivateMessageEvent) Then
					pIrcClient->Events.lpfnPrivateMessageEvent(pIrcClient->lpParameter, pPrefix, *pMessageText)
				End If
			Else
				If CUInt(pIrcClient->Events.lpfnChannelMessageEvent) Then
					pIrcClient->Events.lpfnChannelMessageEvent(pIrcClient->lpParameter, pPrefix, bstrMsgTarget, *pMessageText)
				End If
			End If
		End If
	End If
	
	Return S_OK
	
End Function

Function ProcessNoticeCommand( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pPrefix As IrcPrefix Ptr, _
		ByVal pwszIrcParam1 As WString Ptr, _
		ByRef bstrIrcMessage As ValueBSTR _
	)As HRESULT
	':Angel!wings@irc.org NOTICE Wiz :Are you receiving this message ?
	':Angel!wings@irc.org NOTICE Qubick :PING 1402355972
	
	Dim pwszMsgTarget As WString Ptr = pwszIrcParam1
	Dim pwszStartIrcParam2 As WString Ptr = SeparateWordBySpace(pwszIrcParam1)
	
	Dim pwszNoticeText As WString Ptr = GetIrcMessageText(pwszStartIrcParam2)
	
	If pwszNoticeText <> 0 Then
		Dim bstrMsgTarget As ValueBSTR = Type<ValueBSTR>(*pwszMsgTarget, pwszStartIrcParam2 - pwszMsgTarget - 1)
		
		Dim NoticeTextLength As Integer = bstrIrcMessage.GetTrailingNullChar() - pwszNoticeText
		
		If IsCtcpMessage(pwszNoticeText, NoticeTextLength) Then
			pwszNoticeText += 1
			pwszNoticeText[NoticeTextLength - 1] = 0
			NoticeTextLength -= 2
			
			Dim wStartCtcpParam As WString Ptr = SeparateWordBySpace(pwszNoticeText)
			
			If wStartCtcpParam <> NULL Then
				Dim pCtcpParam As ValueBSTR Ptr = WStringPtrToValueBstrPtr(wStartCtcpParam)
				
				Select Case GetCtcpCommand(pwszNoticeText)
					
					Case CtcpMessageKind.Ping
						If CUInt(pIrcClient->Events.lpfnCtcpPingResponseEvent) Then
							pCtcpParam->Length = NoticeTextLength - PingStringWithSpaceLength
							pIrcClient->Events.lpfnCtcpPingResponseEvent(pIrcClient->lpParameter, pPrefix, bstrMsgTarget, *pCtcpParam)
						End If
						
					Case CtcpMessageKind.UserInfo
						If CUInt(pIrcClient->Events.lpfnCtcpUserInfoResponseEvent) Then
							pCtcpParam->Length = NoticeTextLength - UserInfoStringWithSpaceLength
							pIrcClient->Events.lpfnCtcpUserInfoResponseEvent(pIrcClient->lpParameter, pPrefix, bstrMsgTarget, *pCtcpParam)
						End If
						
					Case CtcpMessageKind.Time
						If CUInt(pIrcClient->Events.lpfnCtcpTimeResponseEvent) Then
							pCtcpParam->Length = NoticeTextLength - TimeStringWithSpaceLength
							pIrcClient->Events.lpfnCtcpTimeResponseEvent(pIrcClient->lpParameter, pPrefix, bstrMsgTarget, *pCtcpParam)
						End If
						
					Case CtcpMessageKind.Version
						If CUInt(pIrcClient->Events.lpfnCtcpVersionResponseEvent) Then
							pCtcpParam->Length = NoticeTextLength - VersionStringWithSpaceLength
							pIrcClient->Events.lpfnCtcpVersionResponseEvent(pIrcClient->lpParameter, pPrefix, bstrMsgTarget, *pCtcpParam)
						End If
						
				End Select
			End If
			
		Else
			Dim pNoticeText As ValueBSTR Ptr = WStringPtrToValueBstrPtr(pwszNoticeText)
			pNoticeText->Length = NoticeTextLength
			
			If lstrcmp(bstrMsgTarget, pIrcClient->ClientNick) = 0 Then
				If CUInt(pIrcClient->Events.lpfnNoticeEvent) Then
					pIrcClient->Events.lpfnNoticeEvent(pIrcClient->lpParameter, pPrefix, *pNoticeText)
				End If
			Else
				If CUInt(pIrcClient->Events.lpfnChannelNoticeEvent) Then
					pIrcClient->Events.lpfnChannelNoticeEvent(pIrcClient->lpParameter, pPrefix, bstrMsgTarget, *pNoticeText)
				End If
			End If
		End If
	End If
	Return S_OK
	
End Function

Function ProcessJoinCommand( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pPrefix As IrcPrefix Ptr, _
		ByVal pwszIrcParam1 As WString Ptr, _
		ByRef bstrIrcMessage As ValueBSTR _
	)As HRESULT
	
	':Qubick!~Qubick@irc.org JOIN ##freebasic
	If CUInt(pIrcClient->Events.lpfnUserJoinedEvent) Then
		Dim pChannel As ValueBSTR Ptr = WStringPtrToValueBstrPtr(pwszIrcParam1)
		pChannel->Length = bstrIrcMessage.GetTrailingNullChar() - pwszIrcParam1
			
		pIrcClient->Events.lpfnUserJoinedEvent(pIrcClient->lpParameter, pPrefix, *pChannel)
	End If
	
	Return S_OK
	
End Function

Function ProcessQuitCommand( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pPrefix As IrcPrefix Ptr, _
		ByVal pwszIrcParam1 As WString Ptr, _
		ByRef bstrIrcMessage As ValueBSTR _
	)As HRESULT
	
	' :syrk!kalt@millennium.stealth.net QUIT :Gone to have lunch
	If CUInt(pIrcClient->Events.lpfnQuitEvent) Then
		Dim QuitText As WString Ptr = GetIrcMessageText(pwszIrcParam1)
		
		If QuitText = 0 Then
			Dim MessageText As ValueBSTR = Type<ValueBSTR>(EmptyString, 0)
			pIrcClient->Events.lpfnQuitEvent(pIrcClient->lpParameter, pPrefix, MessageText)
		Else
			Dim pMessageText As ValueBSTR Ptr = WStringPtrToValueBstrPtr(QuitText)
			pMessageText->Length = bstrIrcMessage.GetTrailingNullChar() - QuitText
			
			pIrcClient->Events.lpfnQuitEvent(pIrcClient->lpParameter, pPrefix, *pMessageText)
		End If
	End If
	
	Return S_OK
	
End Function

Function ProcessPartCommand( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pPrefix As IrcPrefix Ptr, _
		ByVal pwszIrcParam1 As WString Ptr, _
		ByRef bstrIrcMessage As ValueBSTR _
	)As HRESULT
	
	':WiZ!jto@tolsun.oulu.fi PART #playzone :I lost
	If CUInt(pIrcClient->Events.lpfnUserLeavedEvent) Then
		Dim pwszStartIrcParam2 As WString Ptr = SeparateWordBySpace(pwszIrcParam1)
		
		Dim PartText As WString Ptr = GetIrcMessageText(pwszStartIrcParam2)
		
		If PartText = 0 Then
			Dim bstrChannel As ValueBSTR = Type<ValueBSTR>(*pwszIrcParam1, bstrIrcMessage.GetTrailingNullChar() - pwszIrcParam1)
			
			Dim bstrPartText As ValueBSTR = Type<ValueBSTR>(EmptyString, 0)
			pIrcClient->Events.lpfnUserLeavedEvent(pIrcClient->lpParameter, pPrefix, bstrChannel, bstrPartText)
		Else
			Dim bstrChannel As ValueBSTR = Type<ValueBSTR>(*pwszIrcParam1, pwszStartIrcParam2 - pwszIrcParam1 - 1)
			
			Dim pMessageText As ValueBSTR Ptr = WStringPtrToValueBstrPtr(PartText)
			pMessageText->Length = bstrIrcMessage.GetTrailingNullChar() - PartText
			
			pIrcClient->Events.lpfnUserLeavedEvent(pIrcClient->lpParameter, pPrefix, bstrChannel, *pMessageText)
		End If
	End If
	
	Return S_OK
	
End Function

Function ProcessErrorCommand( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pPrefix As IrcPrefix Ptr, _
		ByVal pwszIrcParam1 As WString Ptr, _
		ByRef bstrIrcMessage As ValueBSTR _
	)As HRESULT
	
	'ERROR :Closing Link: 89.22.170.64 (Client Quit)
	
	Dim pwszMessageText As WString Ptr = GetIrcMessageText(pwszIrcParam1)
	
	If pwszMessageText <> 0 Then
		If CUInt(pIrcClient->Events.lpfnServerErrorEvent) Then
			Dim MessageTextLength As Integer = bstrIrcMessage.GetTrailingNullChar() - pwszMessageText
			
			Dim pMessageText As ValueBSTR Ptr = WStringPtrToValueBstrPtr(pwszMessageText)
			pMessageText->Length = MessageTextLength
			
			pIrcClient->Events.lpfnServerErrorEvent(pIrcClient->lpParameter, pPrefix, *pMessageText)
		End If
	End If
	
	Return E_FAIL
	
End Function

Function ProcessNickCommand( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pPrefix As IrcPrefix Ptr, _
		ByVal pwszIrcParam1 As WString Ptr, _
		ByRef bstrIrcMessage As ValueBSTR _
	)As HRESULT
	
	':WiZ!jto@tolsun.oulu.fi NICK Kilroy
	If CUInt(pIrcClient->Events.lpfnNickChangedEvent) Then
		Dim MessageTextLength As Integer = bstrIrcMessage.GetTrailingNullChar() - pwszIrcParam1
		
		Dim pMessageText As ValueBSTR Ptr = WStringPtrToValueBstrPtr(pwszIrcParam1)
		pMessageText->Length = MessageTextLength
		
		pIrcClient->Events.lpfnNickChangedEvent(pIrcClient->lpParameter, pPrefix, *pMessageText)
	End If
	
	Return S_OK
	
End Function

Function ProcessKickCommand( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pPrefix As IrcPrefix Ptr, _
		ByVal pwszIrcParam1 As WString Ptr, _
		ByRef bstrIrcMessage As ValueBSTR _
	)As HRESULT
	
	':WiZ!jto@tolsun.oulu.fi KICK #Finnish John
	If CUInt(pIrcClient->Events.lpfnKickEvent) Then
		Dim pwszIrcParam2 As WString Ptr = SeparateWordBySpace(pwszIrcParam1)
		
		If pwszIrcParam2 <> NULL Then
			
			Dim bstrChannel As ValueBSTR = Type<ValueBSTR>(*pwszIrcParam1, pwszIrcParam2 - pwszIrcParam1 - 1)
			
			Dim pKickedNick As ValueBSTR Ptr = WStringPtrToValueBstrPtr(pwszIrcParam1)
			pKickedNick->Length = bstrIrcMessage.GetTrailingNullChar() - pwszIrcParam2
			
			pIrcClient->Events.lpfnKickEvent(pIrcClient->lpParameter, pPrefix, bstrChannel, *pKickedNick)
		End If
	End If
	
	Return S_OK
	
End Function

Function ProcessModeCommand( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pPrefix As IrcPrefix Ptr, _
		ByVal pwszIrcParam1 As WString Ptr, _
		ByRef bstrIrcMessage As ValueBSTR _
	)As HRESULT
	
	':ChanServ!ChanServ@services. MODE #freebasic +v ssteiner
	':FreeBasicCompile MODE FreeBasicCompile :+i
	If CUInt(pIrcClient->Events.lpfnModeEvent) Then
		' Dim pwszStartIrcParam2 As WString Ptr = SeparateWordBySpace(pwszIrcParam1)
		' Dim wStartIrcParam3 As WString Ptr = SeparateWordBySpace(pwszStartIrcParam2)
		' pIrcClient->Events.lpfnModeEvent(pIrcClient->lpParameter, pPrefix, pwszIrcParam1, pwszStartIrcParam2, wStartIrcParam3)
	End If
	
	Return S_OK
	
End Function

Function ProcessTopicCommand( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pPrefix As IrcPrefix Ptr, _
		ByVal pwszIrcParam1 As WString Ptr, _
		ByRef bstrIrcMessage As ValueBSTR _
	)As HRESULT
	
	':WiZ!jto@tolsun.oulu.fi TOPIC #test :New topic
	If CUInt(pIrcClient->Events.lpfnTopicEvent) Then
		Dim pwszStartIrcParam2 As WString Ptr = SeparateWordBySpace(pwszIrcParam1)
		Dim TopicText As WString Ptr = GetIrcMessageText(pwszStartIrcParam2)
		
		If TopicText = 0 Then
			Dim bstrChannel As ValueBSTR = Type<ValueBSTR>(*pwszIrcParam1, bstrIrcMessage.GetTrailingNullChar() - pwszIrcParam1)
			
			Dim bstrTopicText As ValueBSTR = Type<ValueBSTR>(EmptyString, 0)
			pIrcClient->Events.lpfnTopicEvent(pIrcClient->lpParameter, pPrefix, bstrChannel, bstrTopicText)
		Else
			Dim bstrChannel As ValueBSTR = Type<ValueBSTR>(*pwszIrcParam1, pwszStartIrcParam2 - pwszIrcParam1 - 1)
			
			Dim pMessageText As ValueBSTR Ptr = WStringPtrToValueBstrPtr(TopicText)
			pMessageText->Length = bstrIrcMessage.GetTrailingNullChar() - TopicText
			
			pIrcClient->Events.lpfnTopicEvent(pIrcClient->lpParameter, pPrefix, bstrChannel, *pMessageText)
		End If
	End If
	
	Return S_OK
	
End Function

Function ProcessInviteCommand( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pPrefix As IrcPrefix Ptr, _
		ByVal pwszIrcParam1 As WString Ptr, _
		ByRef bstrIrcMessage As ValueBSTR _
	)As HRESULT
	
	':Angel!wings@irc.org INVITE Wiz #Dust
	If CUInt(pIrcClient->Events.lpfnInviteEvent) Then
		Dim pwszStartIrcParam2 As WString Ptr = SeparateWordBySpace(pwszIrcParam1)
		
		If pwszStartIrcParam2 <> NULL Then
			Dim Target As ValueBSTR = Type<ValueBSTR>(*pwszIrcParam1)
			
			Dim pMessageText As ValueBSTR Ptr = WStringPtrToValueBstrPtr(pwszStartIrcParam2)
			pMessageText->Length = bstrIrcMessage.GetTrailingNullChar() - pwszStartIrcParam2
			
			pIrcClient->Events.lpfnInviteEvent(pIrcClient->lpParameter, pPrefix, Target, *pMessageText)
		End If
	End If
	
	Return S_OK
	
End Function

Function ProcessPongCommand( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pPrefix As IrcPrefix Ptr, _
		ByVal pwszIrcParam1 As WString Ptr, _
		ByRef bstrIrcMessage As ValueBSTR _
	)As HRESULT
	
	'PONG :barjavel.freenode.net
	Dim ServerName As WString Ptr = GetIrcServerName(pwszIrcParam1)
	If ServerName <> 0 Then
		If CUInt(pIrcClient->Events.lpfnPongEvent) Then
			Dim pMessageText As ValueBSTR Ptr = WStringPtrToValueBstrPtr(ServerName)
			pMessageText->Length = bstrIrcMessage.GetTrailingNullChar() - ServerName
			
			pIrcClient->Events.lpfnPongEvent(pIrcClient->lpParameter, pPrefix, *pMessageText)
		End If
	End If
	
	Return S_OK
	
End Function

Function ProcessNumericCommand( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pPrefix As IrcPrefix Ptr, _
		ByVal IrcNumericCommand As Integer, _
		ByVal pwszIrcParam1 As WString Ptr, _
		ByRef bstrIrcMessage As ValueBSTR _
	)As HRESULT
	
	':orwell.freenode.net 376 FreeBasicCompile :End of /MOTD command.
	If CUInt(pIrcClient->Events.lpfnNumericMessageEvent) Then
		Dim pMessageText As ValueBSTR Ptr = WStringPtrToValueBstrPtr(pwszIrcParam1)
		pMessageText->Length = bstrIrcMessage.GetTrailingNullChar() - pwszIrcParam1
		
		pIrcClient->Events.lpfnNumericMessageEvent(pIrcClient->lpParameter, pPrefix, IrcNumericCommand, *pMessageText)
	End If
	
	Return S_OK
	
End Function

Function ProcessServerCommand( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pPrefix As IrcPrefix Ptr, _
		ByVal pwszIrcCommand As WString Ptr, _
		ByVal pwszIrcParam1 As WString Ptr, _
		ByRef bstrIrcMessage As ValueBSTR _
	)As HRESULT
	
	':orwell.freenode.net 376 FreeBasicCompile :End of /MOTD command.
	If CUInt(pIrcClient->Events.lpfnServerMessageEvent) Then
		Dim bstrIrcCommand As ValueBSTR = Type<ValueBSTR>(*pwszIrcCommand)
		
		Dim pMessageText As ValueBSTR Ptr = WStringPtrToValueBstrPtr(pwszIrcParam1)
		pMessageText->Length = bstrIrcMessage.GetTrailingNullChar() - pwszIrcParam1
		
		pIrcClient->Events.lpfnServerMessageEvent(pIrcClient->lpParameter, pPrefix, bstrIrcCommand, *pMessageText)
	End If
	
	Return S_OK
	
End Function

Function ParseData( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByRef bstrIrcMessage As ValueBSTR _
	)As HRESULT
	
	' [<colon> <IrcPrefix> <space>] <IrcCommand> [<ircparam1>]
	
	Dim PrefixInternal As IrcPrefixInternal = Any
	Dim PrefixLength As Integer = GetIrcPrefixInternal(@PrefixInternal, bstrIrcMessage)
	
	Dim Prefix As IrcPrefix = Type<IrcPrefix>(PrefixInternal.Nick, PrefixInternal.User, PrefixInternal.Host)
	
	Dim pwszIrcCommand As WString Ptr = Any
	If PrefixLength = 0 Then
		pwszIrcCommand = @bstrIrcMessage.WChars(0)
	Else
		pwszIrcCommand = @bstrIrcMessage.WChars(PrefixLength + 1 + 1)
	End If
	
	Dim pwszIrcParam1 As WString Ptr = SeparateWordBySpace(pwszIrcCommand)
	
	If pwszIrcParam1 <> NULL Then
		' Dim pwszIrcParam1Length As Integer = Any
		
		Dim comm As IrcCommand = Any
		Dim commResult As Boolean = GetIrcCommand(pwszIrcCommand, @comm)
		
		If commResult Then
			Dim lpCommandProcessor As IrcCommandProcessor = Any
			
			Select Case comm
				
				Case IrcCommand.Ping
					lpCommandProcessor = @ProcessPingCommand
					
				Case IrcCommand.PrivateMessage
					lpCommandProcessor = @ProcessPrivateMessageCommand
					
				Case IrcCommand.Join
					lpCommandProcessor = @ProcessJoinCommand
					
				Case IrcCommand.Quit
					lpCommandProcessor = @ProcessQuitCommand
					
				Case IrcCommand.Part
					lpCommandProcessor = @ProcessPartCommand
					
				Case IrcCommand.Notice
					lpCommandProcessor = @ProcessNoticeCommand
					
				Case IrcCommand.Nick
					lpCommandProcessor = @ProcessNickCommand
					
				Case IrcCommand.Error
					lpCommandProcessor = @ProcessErrorCommand
					
				Case IrcCommand.Kick
					lpCommandProcessor = @ProcessKickCommand
					
				Case IrcCommand.Mode
					lpCommandProcessor = @ProcessModeCommand
					
				Case IrcCommand.Topic
					lpCommandProcessor = @ProcessTopicCommand
					
				Case IrcCommand.Invite
					lpCommandProcessor = @ProcessInviteCommand
					
				Case IrcCommand.Pong
					lpCommandProcessor = @ProcessPongCommand
					
				Case IrcCommand.SQuit
					lpCommandProcessor = @ProcessQuitCommand
					
				Case Else
					lpCommandProcessor = NULL
					
			End Select
			
			If CInt(lpCommandProcessor) <> NULL Then
				Return lpCommandProcessor(pIrcClient, @Prefix, pwszIrcParam1, bstrIrcMessage)
			End If
			
		Else
			If IsNumericIrcCommand(pwszIrcCommand, pwszIrcParam1 - pwszIrcCommand - 1) Then
				Dim IrcNumericCommand As Integer = CInt(_wtoi(pwszIrcCommand))
				Return ProcessNumericCommand(pIrcClient, @Prefix, IrcNumericCommand, pwszIrcParam1, bstrIrcMessage)
			Else
				Return ProcessServerCommand(pIrcClient, @Prefix, pwszIrcCommand, pwszIrcParam1, bstrIrcMessage)
			End If
		End If
	End If
	
	Return S_OK
	
End Function

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
