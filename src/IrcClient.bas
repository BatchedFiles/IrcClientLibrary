#include once "IrcClient.bi"
#include once "win\shlwapi.bi"
#include once "win\winsock2.bi"
#include once "win\ws2tcpip.bi"
#include once "CharacterConstants.bi"

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

Const NewLineString = !"\r\n"

Const SENDOVERLAPPEDDATA_BUFFERLENGTHMAXIMUM = IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM - Len(NewLineString)

Const SendBuffersCount = 2

Const CrLfALength = 2

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

#ifndef __FB_64BIT__
#define WStringPtrToValueBstrPtr(pWString) Cast(ValueBSTR Ptr, Cast(Byte Ptr, (pWString)) - SizeOf(UINT))
#else
#define WStringPtrToValueBstrPtr(pWString) Cast(ValueBSTR Ptr, Cast(Byte Ptr, (pWString)) - SizeOf(UINT) - SizeOf(DWORD))
#endif

'IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM - Len(CrLf)
Const VALUEBSTR_BUFFER_CAPACITY As Integer = 510

Type ValueBSTR
	
	#ifdef __FB_64BIT__
		Padding As DWORD
	#endif
	BytesCount As UINT
	WChars(0 To (VALUEBSTR_BUFFER_CAPACITY + 1) - 1) As OLECHAR
	
	Declare Constructor()
	Declare Constructor(ByRef rhs As Const WString)
	Declare Constructor(ByRef rhs As Const WString, ByVal NewLength As Const Integer)
	Declare Constructor(ByRef rhs As Const ValueBSTR)
	Declare Constructor(ByRef rhs As Const BSTR)
	
	'Declare Destructor()
	
	Declare Operator Let(ByRef rhs As Const WString)
	Declare Operator Let(ByRef rhs As Const ValueBSTR)
	Declare Operator Let(ByRef rhs As Const BSTR)
	
	Declare Operator Cast()ByRef As Const WString
	Declare Operator Cast()As Const BSTR
	Declare Operator Cast()As Const Any Ptr
	
	Declare Operator &=(ByRef rhs As Const WString)
	Declare Operator &=(ByRef rhs As Const ValueBSTR)
	Declare Operator &=(ByRef rhs As Const BSTR)
	
	Declare Operator +=(ByRef rhs As Const WString)
	Declare Operator +=(ByRef rhs As Const ValueBSTR)
	Declare Operator +=(ByRef rhs As Const BSTR)
	
	Declare Sub Append(ByVal Ch As Const OLECHAR)
	Declare Sub Append(ByRef rhs As Const WString, ByVal rhsLength As Const Integer)
	
	Declare Function GetTrailingNullChar()As WString Ptr
	
	Declare Property Length(ByVal NewLength As Const Integer)
	Declare Property Length()As Const Integer
	
End Type

Declare Operator Len(ByRef lhs As Const ValueBSTR)As Integer

Type IrcCommandProcessor As Function(ByVal pIrcClient As IrcClient Ptr, ByVal pPrefix As IrcPrefix Ptr, ByVal pwszIrcParam1 As WString Ptr, ByRef bstrIrcMessage As ValueBSTR)As HRESULT

Type IrcPrefixInternal
	Nick As ValueBSTR
	User As ValueBSTR
	Host As ValueBSTR
End Type

Type SendClientContext
	Overlap As WSAOVERLAPPED
	pIrcClient As IrcClient Ptr
	cbLength As Integer
	Buffer As ZString * (SENDOVERLAPPEDDATA_BUFFERLENGTHMAXIMUM + 1)
End Type

Type RecvClientContext
	Overlap As WSAOVERLAPPED
	pIrcClient As IrcClient Ptr
	cbLength As Integer
	Buffer As ZString * (IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM + 1)
End Type

Type CrLfA
	Cr As Byte
	Lf As Byte
End Type

Type SendBuffers
	Bytes As WSABUF
	CrLf As WSABUF
End Type

Type _IrcClient
	hEvent As HANDLE
	ClientSocket As SOCKET
	pEvents As IrcEvents Ptr
	lpParameter As LPCLIENTDATA
	pRecvContext As RecvClientContext Ptr
	CodePage As Integer
	ClientNick As ValueBSTR
	ClientVersion As ValueBSTR
	ClientUserInfo As ValueBSTR
	ZeroEvents As IrcEvents
	ErrorCode As HRESULT
	IsInitialized As Boolean
End Type

Declare Function StartRecvOverlapped( _
	ByVal pIrcClient As IrcClient Ptr _
)As HRESULT

Private Constructor ValueBSTR()
	
	'Padding = 0
	BytesCount = 0
	WChars(0) = 0
	
End Constructor

Private Constructor ValueBSTR(ByRef lhs As Const WString)
	
	'Padding = 0
	Dim lhsLength As Integer = lstrlenW(lhs)
	Dim Chars As Integer = min(VALUEBSTR_BUFFER_CAPACITY, lhsLength)
	
	BytesCount = Chars * SizeOf(OLECHAR)
	CopyMemory(@WChars(0), @lhs, BytesCount)
	WChars(Chars) = 0
	
End Constructor

Private Constructor ValueBSTR(ByRef lhs As Const WString, ByVal NewLength As Const Integer)
	
	'Padding = 0
	Dim Chars As Integer = min(VALUEBSTR_BUFFER_CAPACITY, NewLength)
	
	BytesCount = Chars * SizeOf(OLECHAR)
	CopyMemory(@WChars(0), @lhs, BytesCount)
	WChars(Chars) = 0
	
End Constructor

Private Constructor ValueBSTR(ByRef lhs As Const ValueBSTR)
	
	'Padding = 0
	BytesCount = lhs.BytesCount
	CopyMemory(@WChars(0), @lhs.WChars(0), BytesCount + SizeOf(OLECHAR))
	
End Constructor

Private Constructor ValueBSTR(ByRef lhs As Const BSTR)
	
	'Padding = 0
	Dim lhsLength As Integer = CInt(SysStringLen(lhs))
	Dim Chars As Integer = min(VALUEBSTR_BUFFER_CAPACITY, lhsLength)
	
	BytesCount = Chars * SizeOf(OLECHAR)
	CopyMemory(@WChars(0), lhs, BytesCount)
	WChars(Chars) = 0
	
End Constructor

Private Operator ValueBSTR.Let(ByRef lhs As Const WString)
	
	'Padding = 0
	Dim lhsLength As Integer = lstrlenW(lhs)
	Dim Chars As Integer = min(VALUEBSTR_BUFFER_CAPACITY, lhsLength)
	
	BytesCount = Chars * SizeOf(OLECHAR)
	CopyMemory(@WChars(0), @lhs, BytesCount)
	WChars(Chars) = 0
	
End Operator

Private Operator ValueBSTR.Let(ByRef lhs As Const ValueBSTR)
	
	'Padding = 0
	BytesCount = lhs.BytesCount
	CopyMemory(@WChars(0), @lhs.WChars(0), BytesCount + SizeOf(OLECHAR))
	
End Operator

Private Operator ValueBSTR.Let(ByRef lhs As Const BSTR)
	
	'Padding = 0
	Dim lhsLength As Integer = CInt(SysStringLen(lhs))
	Dim Chars As Integer = min(VALUEBSTR_BUFFER_CAPACITY, lhsLength)
	
	BytesCount = Chars * SizeOf(OLECHAR)
	CopyMemory(@WChars(0), lhs, BytesCount)
	WChars(Chars) = 0
	
End Operator

Private Operator ValueBSTR.Cast()ByRef As Const WString
	
	Return WChars(0)
	
End Operator

Private Operator ValueBSTR.Cast()As Const BSTR
	
	Return @WChars(0)
	
End Operator

Private Operator ValueBSTR.Cast()As Const Any Ptr
	
	Return CPtr(Any Ptr, @WChars(0))
	
End Operator

Private Operator ValueBSTR.&=(ByRef rhs As Const WString)
	
	Append(rhs, lstrlenW(rhs))
	
End Operator

' Declare Operator &=(ByRef rhs As Const ValueBSTR)

Private Operator ValueBSTR.&=(ByRef rhs As Const BSTR)
	Append(*CPtr(WString Ptr, rhs), SysStringLen(rhs))
End Operator

Private Operator ValueBSTR.+=(ByRef rhs As Const WString)
	
	Append(rhs, lstrlenW(rhs))
	
End Operator

' Declare Operator +=(ByRef rhs As Const ValueBSTR)
' Declare Operator +=(ByRef rhs As Const BSTR)

Private Sub ValueBSTR.Append(ByVal Ch As Const OLECHAR)
	Dim meLength As Integer = Len(this)
	Dim UnusedChars As Integer = VALUEBSTR_BUFFER_CAPACITY - meLength
	
	If UnusedChars > 0 Then
		BytesCount += SizeOf(OLECHAR)
		WChars(meLength) = Ch
		WChars(meLength + 1) = 0
	End If
	
End Sub

Private Sub ValueBSTR.Append(ByRef rhs As Const WString, ByVal rhsLength As Const Integer)
	
	Dim meLength As Integer = Len(this)
	Dim UnusedChars As Integer = VALUEBSTR_BUFFER_CAPACITY - meLength
	
	If UnusedChars > 0 Then
		
		Dim Chars As Integer = min(UnusedChars, rhsLength)
		
		BytesCount = (meLength + Chars) * SizeOf(OLECHAR)
		CopyMemory(@WChars(meLength), @rhs, Chars * SizeOf(OLECHAR))
		WChars(meLength + Chars) = 0
		
	End If

End Sub

Private Operator Len(ByRef b As Const ValueBSTR)As Integer
	
	' Return SysStringLen(b)
	Return b.BytesCount \ SizeOf(OLECHAR)
	
End Operator

Private Property ValueBSTR.Length(ByVal NewLength As Const Integer)
	Dim Chars As Integer = min(VALUEBSTR_BUFFER_CAPACITY, NewLength)
	BytesCount = Chars * SizeOf(OLECHAR)
	WChars(Chars) = 0
End Property

Private Property ValueBSTR.Length()As Const Integer
	Return BytesCount \ SizeOf(OLECHAR)
End Property

Private Function ValueBSTR.GetTrailingNullChar()As WString Ptr
	Return CPtr(WString Ptr, @WChars(Len(this)))
End Function

Private Function GetIrcCommand( _
		ByVal w As WString Ptr, _
		ByVal pIrcCommand As IrcCommand Ptr _
	)As Boolean
	
	If lstrcmpW(w, @WStr(PingString)) = 0 Then
		*pIrcCommand = IrcCommand.Ping
		Return True
	End If
	
	If lstrcmpW(w, @WStr(PrivateMessage)) = 0 Then
		*pIrcCommand = IrcCommand.PrivateMessage
		Return True
	End If
	
	If lstrcmpW(w, @WStr(JoinString)) = 0 Then
		*pIrcCommand = IrcCommand.Join
		Return True
	End If
	
	If lstrcmpW(w, @WStr(QuitString)) = 0 Then
		*pIrcCommand = IrcCommand.Quit
		Return True
	End If
	
	If lstrcmpW(w, @WStr(PartString)) = 0 Then
		*pIrcCommand = IrcCommand.Part
		Return True
	End If
	
	If lstrcmpW(w, @WStr(NoticeString)) = 0 Then
		*pIrcCommand = IrcCommand.Notice
		Return True
	End If
	
	If lstrcmpW(w, @WStr(NickString)) = 0 Then
		*pIrcCommand = IrcCommand.Nick
		Return True
	End If
	
	If lstrcmpW(w, @WStr(ErrorString)) = 0 Then
		*pIrcCommand = IrcCommand.Error
		Return True
	End If
	
	If lstrcmpW(w, @WStr(KickString)) = 0 Then
		*pIrcCommand = IrcCommand.Kick
		Return True
	End If
	
	If lstrcmpW(w, @WStr(ModeString)) = 0 Then
		*pIrcCommand = IrcCommand.Mode
		Return True
	End If
	
	If lstrcmpW(w, @WStr(TopicString)) = 0 Then
		*pIrcCommand = IrcCommand.Topic
		Return True
	End If
	
	If lstrcmpW(w, @WStr(InviteString)) = 0 Then
		*pIrcCommand = IrcCommand.Invite
		Return True
	End If
	
	If lstrcmpW(w, @WStr(PongString)) = 0 Then
		*pIrcCommand = IrcCommand.Pong
		Return True
	End If
	
	If lstrcmpW(w, @WStr(SQuitString)) = 0 Then
		*pIrcCommand = IrcCommand.SQuit
		Return True
	End If
	
	Return False
	
End Function

Private Function IsNumericIrcCommand( _
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

Private Function GetIrcServerName( _
		ByVal strData As WString Ptr _
	)As WString Ptr
	
	Dim w As WString Ptr = StrChrW(strData, Characters.Colon)
	If w = NULL Then
		Return NULL
	End If
	
	Return w + 1
	
End Function

Private Function SeparateWordBySpace( _
		ByVal wStart As WString Ptr _
	)As WString Ptr
	
	Dim ws As WString Ptr = StrChrW(wStart, Characters.WhiteSpace)
	If ws = NULL Then
		Return NULL
	End If
	
	ws[0] = Characters.NullChar
	
	Return ws + 1
	
End Function

Private Function GetIrcMessageText( _
		ByVal strData As WString Ptr _
	)As WString Ptr
	
	':Qubick!~miranda@192.168.1.1 PRIVMSG ##freebasic :Hello World
	Dim w As WString Ptr = StrChrW(strData, Characters.Colon)
	If w = NULL Then
		Return NULL
	End If
	
	Return w + 1
	
End Function

Private Function GetCtcpCommand( _
		ByVal w As WString Ptr _
	)As CtcpMessageKind
	
	If lstrcmpW(w, @WStr(PingString)) = 0 Then
		Return CtcpMessageKind.Ping
	End If
	
	If lstrcmpW(w, @WStr(ActionString)) = 0 Then
		Return CtcpMessageKind.Action
	End If
	
	If lstrcmpW(w, @WStr(UserInfoString)) = 0 Then
		Return CtcpMessageKind.UserInfo
	End If
	
	If lstrcmpW(w, @WStr(TimeString)) = 0 Then
		Return CtcpMessageKind.Time
	End If
	
	If lstrcmpW(w, @WStr(VersionString)) = 0 Then
		Return CtcpMessageKind.Version
	End If
	
	Return CtcpMessageKind.None
	
End Function

Private Function GetIrcPrefixInternal( _
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
				pUser = @WStr(EmptyString)
				UserLength = 0
				pHost = @WStr(EmptyString)
				HostLength = 0
			Else
				NickLength = wExclamationChar - pwszIrcMessage - 1
				wExclamationChar[0] = Characters.NullChar
				
				pUser = @wExclamationChar[1]
				
				Dim wCommercialAtChar As WString Ptr = StrChrW(@wExclamationChar[1], Characters.CommercialAt)
				If wCommercialAtChar = NULL Then
					UserLength = wWhiteSpaceChar - wExclamationChar - 1
					
					pHost = @WStr(EmptyString)
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
			pNick = @WStr(EmptyString)
			NickLength = 0
			pUser = @WStr(EmptyString)
			UserLength = 0
			pHost = @WStr(EmptyString)
			HostLength = 0
		End If
	Else
		IrcPrefixLength = 0
		pNick = @WStr(EmptyString)
		NickLength = 0
		pUser = @WStr(EmptyString)
		UserLength = 0
		pHost = @WStr(EmptyString)
		HostLength = 0
	End If
	
	pIrcPrefixInternal->Nick = Type<ValueBSTR>(*pNick, NickLength)
	pIrcPrefixInternal->User = Type<ValueBSTR>(*pUser, UserLength)
	pIrcPrefixInternal->Host = Type<ValueBSTR>(*pHost, HostLength)
	
	Return IrcPrefixLength
	
End Function

Private Function IsCtcpMessage( _
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

Private Function ProcessPingCommand( _
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
		
		If CUInt(pIrcClient->pEvents->lpfnPingEvent) Then
			pIrcClient->pEvents->lpfnPingEvent(pIrcClient->lpParameter, pPrefix, *pServerName)
		Else
			Return IrcClientSendPong(pIrcClient, *pServerName)
		End If
	End If
	
	Return S_OK
	
End Function

Private Function ProcessPrivateMessageCommand( _
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
						pCtcpParam->Length = MessageTextLength - Len(PingStringWithSpace)
						
						If CUInt(pIrcClient->pEvents->lpfnCtcpPingRequestEvent) = 0 Then
							IrcClientSendCtcpPingResponse(pIrcClient, pPrefix->Nick, *pCtcpParam)
						Else
							pIrcClient->pEvents->lpfnCtcpPingRequestEvent(pIrcClient->lpParameter, pPrefix, bstrMsgTarget, *pCtcpParam)
						End If
					End If
					
				Case CtcpMessageKind.Action
					':Angel!wings@irc.org PRIVMSG Qubick :ACTION Any Text
					If pwszStartCtcpParam <> NULL Then
						If CUInt(pIrcClient->pEvents->lpfnCtcpActionEvent) Then
							
							Dim pCtcpParam As ValueBSTR Ptr = WStringPtrToValueBstrPtr(pwszStartCtcpParam)
							pCtcpParam->Length = MessageTextLength - Len(ActionStringWithSpace)
							
							pIrcClient->pEvents->lpfnCtcpActionEvent(pIrcClient->lpParameter, pPrefix, bstrMsgTarget, *pCtcpParam)
						End If
					End If
					
				Case CtcpMessageKind.UserInfo
					':Angel!wings@irc.org PRIVMSG Qubick :USERINFO
					If CUInt(pIrcClient->pEvents->lpfnCtcpUserInfoRequestEvent) = 0 Then
						If Len(pIrcClient->ClientUserInfo) <> 0 Then
							IrcClientSendCtcpUserInfoResponse(pIrcClient, pPrefix->Nick, pIrcClient->ClientUserInfo)
						End If
					Else
						pIrcClient->pEvents->lpfnCtcpUserInfoRequestEvent(pIrcClient->lpParameter, pPrefix, bstrMsgTarget)
					End If
					
				Case CtcpMessageKind.Time
					':Angel!wings@irc.org PRIVMSG Qubick :TIME
					If CUInt(pIrcClient->pEvents->lpfnCtcpTimeRequestEvent) = 0 Then
						' Tue, 15 Nov 1994 12:45:26 GMT
						Const DateFormatString = "ddd, dd MMM yyyy "
						Const TimeFormatString = "HH:mm:ss GMT"
						Dim TimeValue As WString * 64 = Any
						Dim dtNow As SYSTEMTIME = Any
						
						GetSystemTime(@dtNow)
						
						Dim dtBufferLength As Integer = GetDateFormatW(LOCALE_INVARIANT, 0, @dtNow, @WStr(DateFormatString), @TimeValue, 31) - 1
						GetTimeFormatW(LOCALE_INVARIANT, 0, @dtNow, @WStr(TimeFormatString), @TimeValue[dtBufferLength], 31 - dtBufferLength)
						
						Return IrcClientSendCtcpTimeResponse(pIrcClient, pPrefix->Nick, @TimeValue)
					Else
						pIrcClient->pEvents->lpfnCtcpTimeRequestEvent(pIrcClient->lpParameter, pPrefix, bstrMsgTarget)
					End If
					
				Case CtcpMessageKind.Version
					':Angel!wings@irc.org PRIVMSG Qubick :VERSION
					If CUInt(pIrcClient->pEvents->lpfnCtcpVersionRequestEvent) = 0 Then
						If Len(pIrcClient->ClientVersion) <> 0 Then
							Return IrcClientSendCtcpVersionResponse(pIrcClient, pPrefix->Nick, pIrcClient->ClientVersion)
						End If
					Else
						pIrcClient->pEvents->lpfnCtcpVersionRequestEvent(pIrcClient->lpParameter, pPrefix, bstrMsgTarget)
					End If
					
			End Select
		Else
			Dim pMessageText As ValueBSTR Ptr = WStringPtrToValueBstrPtr(pwszMessageText)
			pMessageText->Length = MessageTextLength
			
			If lstrcmp(bstrMsgTarget, pIrcClient->ClientNick) = 0 Then
				If CUInt(pIrcClient->pEvents->lpfnPrivateMessageEvent) Then
					pIrcClient->pEvents->lpfnPrivateMessageEvent(pIrcClient->lpParameter, pPrefix, *pMessageText)
				End If
			Else
				If CUInt(pIrcClient->pEvents->lpfnChannelMessageEvent) Then
					pIrcClient->pEvents->lpfnChannelMessageEvent(pIrcClient->lpParameter, pPrefix, bstrMsgTarget, *pMessageText)
				End If
			End If
		End If
	End If
	
	Return S_OK
	
End Function

Private Function ProcessNoticeCommand( _
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
						If CUInt(pIrcClient->pEvents->lpfnCtcpPingResponseEvent) Then
							pCtcpParam->Length = NoticeTextLength - Len(PingStringWithSpace)
							pIrcClient->pEvents->lpfnCtcpPingResponseEvent(pIrcClient->lpParameter, pPrefix, bstrMsgTarget, *pCtcpParam)
						End If
						
					Case CtcpMessageKind.UserInfo
						If CUInt(pIrcClient->pEvents->lpfnCtcpUserInfoResponseEvent) Then
							pCtcpParam->Length = NoticeTextLength - Len(UserInfoStringWithSpace)
							pIrcClient->pEvents->lpfnCtcpUserInfoResponseEvent(pIrcClient->lpParameter, pPrefix, bstrMsgTarget, *pCtcpParam)
						End If
						
					Case CtcpMessageKind.Time
						If CUInt(pIrcClient->pEvents->lpfnCtcpTimeResponseEvent) Then
							pCtcpParam->Length = NoticeTextLength - Len(TimeStringWithSpace)
							pIrcClient->pEvents->lpfnCtcpTimeResponseEvent(pIrcClient->lpParameter, pPrefix, bstrMsgTarget, *pCtcpParam)
						End If
						
					Case CtcpMessageKind.Version
						If CUInt(pIrcClient->pEvents->lpfnCtcpVersionResponseEvent) Then
							pCtcpParam->Length = NoticeTextLength - Len(VersionStringWithSpace)
							pIrcClient->pEvents->lpfnCtcpVersionResponseEvent(pIrcClient->lpParameter, pPrefix, bstrMsgTarget, *pCtcpParam)
						End If
						
				End Select
			End If
			
		Else
			Dim pNoticeText As ValueBSTR Ptr = WStringPtrToValueBstrPtr(pwszNoticeText)
			pNoticeText->Length = NoticeTextLength
			
			If lstrcmp(bstrMsgTarget, pIrcClient->ClientNick) = 0 Then
				If CUInt(pIrcClient->pEvents->lpfnNoticeEvent) Then
					pIrcClient->pEvents->lpfnNoticeEvent(pIrcClient->lpParameter, pPrefix, *pNoticeText)
				End If
			Else
				If CUInt(pIrcClient->pEvents->lpfnChannelNoticeEvent) Then
					pIrcClient->pEvents->lpfnChannelNoticeEvent(pIrcClient->lpParameter, pPrefix, bstrMsgTarget, *pNoticeText)
				End If
			End If
		End If
	End If
	Return S_OK
	
End Function

Private Function ProcessJoinCommand( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pPrefix As IrcPrefix Ptr, _
		ByVal pwszIrcParam1 As WString Ptr, _
		ByRef bstrIrcMessage As ValueBSTR _
	)As HRESULT
	
	':Qubick!~Qubick@irc.org JOIN ##freebasic
	If CUInt(pIrcClient->pEvents->lpfnUserJoinedEvent) Then
		Dim pChannel As ValueBSTR Ptr = WStringPtrToValueBstrPtr(pwszIrcParam1)
		pChannel->Length = bstrIrcMessage.GetTrailingNullChar() - pwszIrcParam1
			
		pIrcClient->pEvents->lpfnUserJoinedEvent(pIrcClient->lpParameter, pPrefix, *pChannel)
	End If
	
	Return S_OK
	
End Function

Private Function ProcessQuitCommand( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pPrefix As IrcPrefix Ptr, _
		ByVal pwszIrcParam1 As WString Ptr, _
		ByRef bstrIrcMessage As ValueBSTR _
	)As HRESULT
	
	' :syrk!kalt@millennium.stealth.net QUIT :Gone to have lunch
	If CUInt(pIrcClient->pEvents->lpfnQuitEvent) Then
		Dim QuitText As WString Ptr = GetIrcMessageText(pwszIrcParam1)
		
		If QuitText = 0 Then
			Dim MessageText As ValueBSTR = Type<ValueBSTR>(EmptyString, 0)
			pIrcClient->pEvents->lpfnQuitEvent(pIrcClient->lpParameter, pPrefix, MessageText)
		Else
			Dim pMessageText As ValueBSTR Ptr = WStringPtrToValueBstrPtr(QuitText)
			pMessageText->Length = bstrIrcMessage.GetTrailingNullChar() - QuitText
			
			pIrcClient->pEvents->lpfnQuitEvent(pIrcClient->lpParameter, pPrefix, *pMessageText)
		End If
	End If
	
	Return S_OK
	
End Function

Private Function ProcessPartCommand( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pPrefix As IrcPrefix Ptr, _
		ByVal pwszIrcParam1 As WString Ptr, _
		ByRef bstrIrcMessage As ValueBSTR _
	)As HRESULT
	
	':WiZ!jto@tolsun.oulu.fi PART #playzone :I lost
	If CUInt(pIrcClient->pEvents->lpfnUserLeavedEvent) Then
		Dim pwszStartIrcParam2 As WString Ptr = SeparateWordBySpace(pwszIrcParam1)
		
		Dim PartText As WString Ptr = GetIrcMessageText(pwszStartIrcParam2)
		
		If PartText = 0 Then
			Dim bstrChannel As ValueBSTR = Type<ValueBSTR>(*pwszIrcParam1, bstrIrcMessage.GetTrailingNullChar() - pwszIrcParam1)
			
			Dim bstrPartText As ValueBSTR = Type<ValueBSTR>(EmptyString, 0)
			pIrcClient->pEvents->lpfnUserLeavedEvent(pIrcClient->lpParameter, pPrefix, bstrChannel, bstrPartText)
		Else
			Dim bstrChannel As ValueBSTR = Type<ValueBSTR>(*pwszIrcParam1, pwszStartIrcParam2 - pwszIrcParam1 - 1)
			
			Dim pMessageText As ValueBSTR Ptr = WStringPtrToValueBstrPtr(PartText)
			pMessageText->Length = bstrIrcMessage.GetTrailingNullChar() - PartText
			
			pIrcClient->pEvents->lpfnUserLeavedEvent(pIrcClient->lpParameter, pPrefix, bstrChannel, *pMessageText)
		End If
	End If
	
	Return S_OK
	
End Function

Private Function ProcessErrorCommand( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pPrefix As IrcPrefix Ptr, _
		ByVal pwszIrcParam1 As WString Ptr, _
		ByRef bstrIrcMessage As ValueBSTR _
	)As HRESULT
	
	'ERROR :Closing Link: 89.22.170.64 (Client Quit)
	
	Dim pwszMessageText As WString Ptr = GetIrcMessageText(pwszIrcParam1)
	
	If pwszMessageText <> 0 Then
		If CUInt(pIrcClient->pEvents->lpfnServerErrorEvent) Then
			Dim MessageTextLength As Integer = bstrIrcMessage.GetTrailingNullChar() - pwszMessageText
			
			Dim pMessageText As ValueBSTR Ptr = WStringPtrToValueBstrPtr(pwszMessageText)
			pMessageText->Length = MessageTextLength
			
			pIrcClient->pEvents->lpfnServerErrorEvent(pIrcClient->lpParameter, pPrefix, *pMessageText)
		End If
	End If
	
	Return E_FAIL
	
End Function

Private Function ProcessNickCommand( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pPrefix As IrcPrefix Ptr, _
		ByVal pwszIrcParam1 As WString Ptr, _
		ByRef bstrIrcMessage As ValueBSTR _
	)As HRESULT
	
	':WiZ!jto@tolsun.oulu.fi NICK Kilroy
	If CUInt(pIrcClient->pEvents->lpfnNickChangedEvent) Then
		Dim MessageTextLength As Integer = bstrIrcMessage.GetTrailingNullChar() - pwszIrcParam1
		
		Dim pMessageText As ValueBSTR Ptr = WStringPtrToValueBstrPtr(pwszIrcParam1)
		pMessageText->Length = MessageTextLength
		
		pIrcClient->pEvents->lpfnNickChangedEvent(pIrcClient->lpParameter, pPrefix, *pMessageText)
	End If
	
	Return S_OK
	
End Function

Private Function ProcessKickCommand( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pPrefix As IrcPrefix Ptr, _
		ByVal pwszIrcParam1 As WString Ptr, _
		ByRef bstrIrcMessage As ValueBSTR _
	)As HRESULT
	
	':WiZ!jto@tolsun.oulu.fi KICK #Finnish John
	If CUInt(pIrcClient->pEvents->lpfnKickEvent) Then
		Dim pwszIrcParam2 As WString Ptr = SeparateWordBySpace(pwszIrcParam1)
		
		If pwszIrcParam2 <> NULL Then
			
			Dim bstrChannel As ValueBSTR = Type<ValueBSTR>(*pwszIrcParam1, pwszIrcParam2 - pwszIrcParam1 - 1)
			
			Dim pKickedNick As ValueBSTR Ptr = WStringPtrToValueBstrPtr(pwszIrcParam1)
			pKickedNick->Length = bstrIrcMessage.GetTrailingNullChar() - pwszIrcParam2
			
			pIrcClient->pEvents->lpfnKickEvent(pIrcClient->lpParameter, pPrefix, bstrChannel, *pKickedNick)
		End If
	End If
	
	Return S_OK
	
End Function

Private Function ProcessModeCommand( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pPrefix As IrcPrefix Ptr, _
		ByVal pwszIrcParam1 As WString Ptr, _
		ByRef bstrIrcMessage As ValueBSTR _
	)As HRESULT
	
	':ChanServ!ChanServ@services. MODE #freebasic +v ssteiner
	':FreeBasicCompile MODE FreeBasicCompile :+i
	If CUInt(pIrcClient->pEvents->lpfnModeEvent) Then
		' Dim pwszStartIrcParam2 As WString Ptr = SeparateWordBySpace(pwszIrcParam1)
		' Dim wStartIrcParam3 As WString Ptr = SeparateWordBySpace(pwszStartIrcParam2)
		' pIrcClient->Events.lpfnModeEvent(pIrcClient->lpParameter, pPrefix, pwszIrcParam1, pwszStartIrcParam2, wStartIrcParam3)
	End If
	
	Return S_OK
	
End Function

Private Function ProcessTopicCommand( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pPrefix As IrcPrefix Ptr, _
		ByVal pwszIrcParam1 As WString Ptr, _
		ByRef bstrIrcMessage As ValueBSTR _
	)As HRESULT
	
	':WiZ!jto@tolsun.oulu.fi TOPIC #test :New topic
	If CUInt(pIrcClient->pEvents->lpfnTopicEvent) Then
		Dim pwszStartIrcParam2 As WString Ptr = SeparateWordBySpace(pwszIrcParam1)
		Dim TopicText As WString Ptr = GetIrcMessageText(pwszStartIrcParam2)
		
		If TopicText = 0 Then
			Dim bstrChannel As ValueBSTR = Type<ValueBSTR>(*pwszIrcParam1, bstrIrcMessage.GetTrailingNullChar() - pwszIrcParam1)
			
			Dim bstrTopicText As ValueBSTR = Type<ValueBSTR>(EmptyString, 0)
			pIrcClient->pEvents->lpfnTopicEvent(pIrcClient->lpParameter, pPrefix, bstrChannel, bstrTopicText)
		Else
			Dim bstrChannel As ValueBSTR = Type<ValueBSTR>(*pwszIrcParam1, pwszStartIrcParam2 - pwszIrcParam1 - 1)
			
			Dim pMessageText As ValueBSTR Ptr = WStringPtrToValueBstrPtr(TopicText)
			pMessageText->Length = bstrIrcMessage.GetTrailingNullChar() - TopicText
			
			pIrcClient->pEvents->lpfnTopicEvent(pIrcClient->lpParameter, pPrefix, bstrChannel, *pMessageText)
		End If
	End If
	
	Return S_OK
	
End Function

Private Function ProcessInviteCommand( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pPrefix As IrcPrefix Ptr, _
		ByVal pwszIrcParam1 As WString Ptr, _
		ByRef bstrIrcMessage As ValueBSTR _
	)As HRESULT
	
	':Angel!wings@irc.org INVITE Wiz #Dust
	If CUInt(pIrcClient->pEvents->lpfnInviteEvent) Then
		Dim pwszStartIrcParam2 As WString Ptr = SeparateWordBySpace(pwszIrcParam1)
		
		If pwszStartIrcParam2 <> NULL Then
			Dim Target As ValueBSTR = Type<ValueBSTR>(*pwszIrcParam1)
			
			Dim pMessageText As ValueBSTR Ptr = WStringPtrToValueBstrPtr(pwszStartIrcParam2)
			pMessageText->Length = bstrIrcMessage.GetTrailingNullChar() - pwszStartIrcParam2
			
			pIrcClient->pEvents->lpfnInviteEvent(pIrcClient->lpParameter, pPrefix, Target, *pMessageText)
		End If
	End If
	
	Return S_OK
	
End Function

Private Function ProcessPongCommand( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pPrefix As IrcPrefix Ptr, _
		ByVal pwszIrcParam1 As WString Ptr, _
		ByRef bstrIrcMessage As ValueBSTR _
	)As HRESULT
	
	'PONG :barjavel.freenode.net
	Dim ServerName As WString Ptr = GetIrcServerName(pwszIrcParam1)
	If ServerName <> 0 Then
		If CUInt(pIrcClient->pEvents->lpfnPongEvent) Then
			Dim pMessageText As ValueBSTR Ptr = WStringPtrToValueBstrPtr(ServerName)
			pMessageText->Length = bstrIrcMessage.GetTrailingNullChar() - ServerName
			
			pIrcClient->pEvents->lpfnPongEvent(pIrcClient->lpParameter, pPrefix, *pMessageText)
		End If
	End If
	
	Return S_OK
	
End Function

Private Function ProcessNumericCommand( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pPrefix As IrcPrefix Ptr, _
		ByVal IrcNumericCommand As Integer, _
		ByVal pwszIrcParam1 As WString Ptr, _
		ByRef bstrIrcMessage As ValueBSTR _
	)As HRESULT
	
	':orwell.freenode.net 376 FreeBasicCompile :End of /MOTD command.
	If CUInt(pIrcClient->pEvents->lpfnNumericMessageEvent) Then
		Dim pMessageText As ValueBSTR Ptr = WStringPtrToValueBstrPtr(pwszIrcParam1)
		pMessageText->Length = bstrIrcMessage.GetTrailingNullChar() - pwszIrcParam1
		
		pIrcClient->pEvents->lpfnNumericMessageEvent(pIrcClient->lpParameter, pPrefix, IrcNumericCommand, *pMessageText)
	End If
	
	Return S_OK
	
End Function

Private Function ProcessServerCommand( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pPrefix As IrcPrefix Ptr, _
		ByVal pwszIrcCommand As WString Ptr, _
		ByVal pwszIrcParam1 As WString Ptr, _
		ByRef bstrIrcMessage As ValueBSTR _
	)As HRESULT
	
	':orwell.freenode.net 376 FreeBasicCompile :End of /MOTD command.
	If CUInt(pIrcClient->pEvents->lpfnServerMessageEvent) Then
		Dim bstrIrcCommand As ValueBSTR = Type<ValueBSTR>(*pwszIrcCommand)
		
		Dim pMessageText As ValueBSTR Ptr = WStringPtrToValueBstrPtr(pwszIrcParam1)
		pMessageText->Length = bstrIrcMessage.GetTrailingNullChar() - pwszIrcParam1
		
		pIrcClient->pEvents->lpfnServerMessageEvent(pIrcClient->lpParameter, pPrefix, bstrIrcCommand, *pMessageText)
	End If
	
	Return S_OK
	
End Function

Private Function ParseData( _
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

Private Function ResolveHostA( _
		ByVal Host As PCSTR, _
		ByVal Port As PCSTR, _
		ByVal ppAddressList As addrinfo Ptr Ptr _
	)As HRESULT
	
	Dim hints As addrinfo
	With hints
		.ai_family = AF_UNSPEC ' AF_INET ��� AF_INET6
		.ai_socktype = SOCK_STREAM
		.ai_protocol = IPPROTO_TCP
	End With
	
	*ppAddressList = NULL
	
	If getaddrinfo(Host, Port, @hints, ppAddressList) = 0 Then
		
		Return S_OK
		
	End If
	
	Dim dwError As Long = WSAGetLastError()
	Return HRESULT_FROM_WIN32(dwError)
	
End Function

Public Function ResolveHostW Alias "ResolveHostW"( _
		ByVal Host As PCWSTR, _
		ByVal Port As PCWSTR, _
		ByVal ppAddressList As ADDRINFOW Ptr Ptr _
	)As HRESULT
	
	Dim hints As ADDRINFOW = Any
	ZeroMemory(@hints, SizeOf(ADDRINFOW))
	
	With hints
		.ai_family = AF_UNSPEC ' AF_INET, AF_INET6
		.ai_socktype = SOCK_STREAM
		.ai_protocol = IPPROTO_TCP
	End With
	
	*ppAddressList = NULL
	
	Dim resAddrInfo As INT_ = GetAddrInfoW( _
		Host, _
		Port, _
		@hints, _
		ppAddressList _
	)
	If resAddrInfo Then
		Return HRESULT_FROM_WIN32(resAddrInfo)
	End If
	
	Return S_OK
	
End Function

Private Function IrcClientStartup( _
		ByVal pIrcClient As IrcClient Ptr _
	)As HRESULT
	
	Dim objWsaData As WSAData = Any
	Dim dwError As Long = WSAStartup(MAKEWORD(2, 2), @objWsaData)
	If dwError <> NO_ERROR Then
		Return HRESULT_FROM_WIN32(dwError)
	End If
	
	Return S_OK
	
End Function

Private Function IrcClientCleanup( _
		ByVal pIIrcClient As IrcClient Ptr _
	)As HRESULT
	
	Dim dwError As Long = WSACleanup()
	If dwError <> NO_ERROR Then
		Return HRESULT_FROM_WIN32(dwError)
	End If
	
	Return S_OK
	
End Function

Private Function CreateSocketAndBindA( _
		ByVal LocalAddress As PCSTR, _
		ByVal LocalPort As PCSTR, _
		ByVal pSocket As SOCKET Ptr _
	)As HRESULT
	
	Dim ClientSocket As SOCKET = WSASocketA( _
		AF_UNSPEC, _
		SOCK_STREAM, _
		IPPROTO_TCP, _
		NULL, _
		0, _
		WSA_FLAG_OVERLAPPED _
	)
	If ClientSocket = INVALID_SOCKET Then
		Dim dwError As Long = WSAGetLastError()
		*pSocket = INVALID_SOCKET
		Return HRESULT_FROM_WIN32(dwError)
	End If
	
	Dim pAddressList As addrinfo Ptr = NULL
	Dim hr As HRESULT = ResolveHostA(LocalAddress, LocalPort, @pAddressList)
	If FAILED(hr) Then
		Dim dwError As Long = WSAGetLastError()
		*pSocket = INVALID_SOCKET
		Return HRESULT_FROM_WIN32(dwError)
	End If
	
	Dim pAddress As addrinfo Ptr = pAddressList
	Dim BindResult As Long = 0
	
	Dim e As Long = 0
	
	If LocalAddress Then
		Do
			BindResult = bind( _
				ClientSocket, _
				Cast(LPSOCKADDR, pAddress->ai_addr), _
				pAddress->ai_addrlen _
			)
			e = WSAGetLastError()
			
			If BindResult = 0 Then
				Exit Do
			End If
			
			pAddress = pAddress->ai_next
			
		Loop Until pAddress = 0
	End If
	
	FreeAddrInfo(pAddressList)
	
	If BindResult <> 0 Then
		*pSocket = INVALID_SOCKET
		Return HRESULT_FROM_WIN32(e)
	End If
	
	*pSocket = ClientSocket
	Return S_OK
	
End Function

Private Function CreateSocketAndBindW( _
		ByVal LocalAddress As PCWSTR, _
		ByVal LocalPort As PCWSTR, _
		ByVal pSocket As SOCKET Ptr _
	)As HRESULT
	
	Dim pAddressList As addrinfoW Ptr = NULL
	Dim hrResolve As HRESULT = ResolveHostW( _
		LocalAddress, _
		LocalPort, _
		@pAddressList _
	)
	If FAILED(hrResolve) Then
		*pSocket = INVALID_SOCKET
		Return hrResolve
	End If
	
	Dim ClientSocket As SOCKET = WSASocketW( _
		AF_UNSPEC, _
		SOCK_STREAM, _
		IPPROTO_TCP, _
		NULL, _
		0, _
		WSA_FLAG_OVERLAPPED _
	)
	If ClientSocket = INVALID_SOCKET Then
		Dim dwError As Long = WSAGetLastError()
		*pSocket = INVALID_SOCKET
		Return HRESULT_FROM_WIN32(dwError)
	End If
	
	Dim pAddress As addrinfoW Ptr = pAddressList
	Dim BindResult As Long = 0
	
	Dim e As Long = 0
	
	If LocalAddress Then
		Do
			BindResult = bind( _
				ClientSocket, _
				Cast(LPSOCKADDR, pAddress->ai_addr), _
				pAddress->ai_addrlen _
			)
			e = WSAGetLastError()
			
			If BindResult = 0 Then
				Exit Do
			End If
			
			pAddress = pAddress->ai_next
			
		Loop Until pAddress = 0
	End If
	
	FreeAddrInfoW(pAddressList)
	
	If BindResult <> 0 Then
		*pSocket = INVALID_SOCKET
		Return HRESULT_FROM_WIN32(e)
	End If
	
	*pSocket = ClientSocket
	Return S_OK
	
End Function

Private Function CloseSocketConnection( _
		ByVal ClientSocket As SOCKET _
	)As HRESULT
	
	Dim res As Integer = shutdown(ClientSocket, SD_BOTH)
	If res <> 0 Then
		Dim dwError As Long = WSAGetLastError()
		Return HRESULT_FROM_WIN32(dwError)
	End If
	
	res = closesocket(ClientSocket)
	If res <> 0 Then
		Dim dwError As Long = WSAGetLastError()
		Return HRESULT_FROM_WIN32(dwError)
	End If
	
	Return S_OK
	
End Function

Private Function SetReceiveTimeout( _
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
		Dim dwError As Long = WSAGetLastError()
		Return HRESULT_FROM_WIN32(dwError)
	End If
	
	Return S_OK
	
End Function

Private Function ConnectToServerA( _
		ByVal LocalAddress As PCSTR, _
		ByVal LocalPort As PCSTR, _
		ByVal RemoteAddress As PCSTR, _
		ByVal RemotePort As PCSTR, _
		ByVal pSocket As SOCKET Ptr _
	)As HRESULT
	
	Dim ClientSocket As SOCKET = Any
	Dim hrBind As HRESULT = CreateSocketAndBindA(LocalAddress, LocalPort, @ClientSocket)
	If FAILED(hrBind) Then
		*pSocket = INVALID_SOCKET
		Return hrBind
	End If
	
	Dim pAddressList As addrinfo Ptr = NULL
	Dim hrResolve As HRESULT = ResolveHostA(RemoteAddress, RemotePort, @pAddressList)
	If FAILED(hrResolve) Then
		closesocket(ClientSocket)
		*pSocket = INVALID_SOCKET
		Return hrResolve
	End If
	
	Dim pAddress As addrinfo Ptr = pAddressList
	Dim ConnectResult As Long = 0
	
	Dim e As Long = 0
	Do
		ConnectResult = connect( _
			ClientSocket, _
			Cast(LPSOCKADDR, pAddress->ai_addr), _
			pAddress->ai_addrlen _
		)
		e = WSAGetLastError()
		
		If ConnectResult = 0 Then
			Exit Do
		End If
		
		pAddress = pAddress->ai_next
		
	Loop Until pAddress = 0
	
	FreeAddrInfo(pAddressList)
	
	If ConnectResult <> 0 Then
		closesocket(ClientSocket)
		*pSocket = INVALID_SOCKET
		Return HRESULT_FROM_WIN32(e)
	End If
	
	*pSocket = ClientSocket
	Return S_OK
	
End Function

Private Function ConnectToServerW( _
		ByVal LocalAddress As PCWSTR, _
		ByVal LocalPort As PCWSTR, _
		ByVal RemoteAddress As PCWSTR, _
		ByVal RemotePort As PCWSTR, _
		ByVal pSocket As SOCKET Ptr _
	)As HRESULT
	
	Dim ClientSocket As SOCKET = Any
	Dim hrBind As HRESULT = CreateSocketAndBindW(LocalAddress, LocalPort, @ClientSocket)
	If FAILED(hrBind) Then
		*pSocket = INVALID_SOCKET
		Return hrBind
	End If
	
	Dim pAddressList As addrinfoW Ptr = NULL
	Dim hrResolve As HRESULT = ResolveHostW(RemoteAddress, RemotePort, @pAddressList)
	If FAILED(hrResolve) Then
		closesocket(ClientSocket)
		*pSocket = INVALID_SOCKET
		Return hrResolve
	End If
	
	Dim pAddress As addrinfoW Ptr = pAddressList
	Dim ConnectResult As Long = 0
	
	Dim e As Long = 0
	Do
		ConnectResult = connect( _
			ClientSocket, _
			Cast(LPSOCKADDR, pAddress->ai_addr), _
			pAddress->ai_addrlen _
		)
		e = WSAGetLastError()
		
		If ConnectResult = 0 Then
			Exit Do
		End If
		
		pAddress = pAddress->ai_next
		
	Loop Until pAddress = 0
	
	FreeAddrInfoW(pAddressList)
	
	If ConnectResult <> 0 Then
		closesocket(ClientSocket)
		*pSocket = INVALID_SOCKET
		Return HRESULT_FROM_WIN32(e)
	End If
	
	*pSocket = ClientSocket
	Return S_OK
	
End Function

Private Function FindCrLfA( _
		ByVal Buffer As ZString Ptr, _
		ByVal BufferLength As Integer, _
		ByVal pIndex As Integer Ptr _
	)As Boolean
	
	For i As Integer = 0 To BufferLength - Len(NewLineString)
		If Buffer[i] = Characters.CarriageReturn AndAlso Buffer[i + 1] = Characters.LineFeed Then
			*pIndex = i
			Return True
		End If
	Next
	
	*pIndex = 0
	Return False
	
End Function

Private Sub ReceiveCompletionRoutine( _
		ByVal dwError As DWORD, _
		ByVal cbTransferred As DWORD, _
		ByVal lpOverlapped As LPWSAOVERLAPPED, _
		ByVal dwFlags As DWORD _
	)
	
	Dim pContext As RecvClientContext Ptr = CPtr(RecvClientContext Ptr, lpOverlapped)
	Dim pIrcClient As IrcClient Ptr = pContext->pIrcClient
	
	If dwError <> 0 Then
		pIrcClient->ErrorCode = HRESULT_FROM_WIN32(dwError)
		SetEvent(pIrcClient->hEvent)
		Exit Sub
	End If
	
	pContext->cbLength += CInt(cbTransferred)
	
	Dim CrLfIndex As Integer = Any
	Dim FindCrLfResult As Boolean = FindCrLfA( _
		@pContext->Buffer, _
		pContext->cbLength, _
		@CrLfIndex _
	)
	
	If FindCrLfResult = False Then
		
		If pContext->cbLength >= IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM Then
			FindCrLfResult = True
			CrLfIndex = IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM - 2
			pContext->cbLength = IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM
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
				@pContext->Buffer, _
				CrLfIndex, _
				@bstrServerResponse.WChars(0), _
				VALUEBSTR_BUFFER_CAPACITY _
			)
			
			If ServerResponseLength <> 0 Then
				bstrServerResponse.BytesCount = ServerResponseLength * SizeOf(OLECHAR)
				bstrServerResponse.WChars(ServerResponseLength) = Characters.NullChar
				
				Scope
					If CUInt(pIrcClient->pEvents->lpfnReceivedRawMessageEvent) Then
						pContext->Buffer[CrLfIndex + 1] = Characters.NullChar
						pIrcClient->pEvents->lpfnReceivedRawMessageEvent( _
							pIrcClient->lpParameter, _
							@pContext->Buffer, _
							CrLfIndex + 1 _
						)
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
			
			If NewStartingIndex = pContext->cbLength Then
				pContext->cbLength = 0
			Else
				memmove( _
					@pContext->Buffer, _
					@pContext->Buffer[NewStartingIndex], _
					IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM - NewStartingIndex + 1 _
				)
				pContext->cbLength -= NewStartingIndex
			End If
		End Scope
		
		FindCrLfResult = FindCrLfA( _
			@pContext->Buffer, _
			pContext->cbLength, _
			@CrLfIndex _
		)
	Loop
	
	Dim hr As HRESULT = StartRecvOverlapped(pIrcClient)
	If FAILED(hr) Then
		pIrcClient->ErrorCode = hr
		SetEvent(pIrcClient->hEvent)
	End If
	
End Sub

Private Function StartRecvOverlapped( _
		ByVal pIrcClient As IrcClient Ptr _
	)As HRESULT
	
	Const WsaBufBuffersCount As DWORD = 1
	Dim RecvBuf As WSABUF = Any
	RecvBuf.len = Cast(ULONG, IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM - pIrcClient->pRecvContext->cbLength)
	RecvBuf.buf = @pIrcClient->pRecvContext->Buffer[pIrcClient->pRecvContext->cbLength]
	
	ZeroMemory(@pIrcClient->pRecvContext->Overlap, SizeOf(WSAOVERLAPPED))
	
	Dim Flags As DWORD = 0
	Dim res As Long = WSARecv( _
		pIrcClient->ClientSocket, _
		@RecvBuf, _
		WsaBufBuffersCount, _
		NULL, _
		@Flags, _
		@pIrcClient->pRecvContext->Overlap, _
		@ReceiveCompletionRoutine _
	)
	If res <> 0 Then
		
		res = WSAGetLastError()
		If res <> WSA_IO_PENDING Then
			Return HRESULT_FROM_WIN32(res)
		End If
		
	End If
	
	Return S_OK
	
End Function

Private Sub SendCompletionRoutine( _
		ByVal dwError As DWORD, _
		ByVal cbTransferred As DWORD, _
		ByVal lpOverlapped As LPWSAOVERLAPPED, _
		ByVal dwFlags As DWORD _
	)
	
	Dim pContext As SendClientContext Ptr = CPtr(SendClientContext Ptr, lpOverlapped)
	Dim pIrcClient As IrcClient Ptr = pContext->pIrcClient
	
	If dwError Then
		pIrcClient->ErrorCode = HRESULT_FROM_WIN32(dwError)
		SetEvent(pIrcClient->hEvent)
	Else
		If CUInt(pIrcClient->pEvents->lpfnSendedRawMessageEvent) Then
			pContext->Buffer[pContext->cbLength] = Characters.NullChar
			pIrcClient->pEvents->lpfnSendedRawMessageEvent( _
				pIrcClient->lpParameter, _
				@pContext->Buffer, _
				pContext->cbLength _
			)
		End If
	End If
	
	Deallocate(pContext)
	
End Sub

Private Function StartSendOverlapped( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByRef strData As ValueBSTR _
	)As HRESULT
	
	Dim hr As HRESULT = E_OUTOFMEMORY
	Dim pContext As SendClientContext Ptr = Allocate(SizeOf(SendClientContext))
	
	If pContext Then
		
		pContext->cbLength = WideCharToMultiByte( _
			pIrcClient->CodePage, _
			0, _
			@strData.WChars(0), _
			Len(strData), _
			@pContext->Buffer, _
			SENDOVERLAPPEDDATA_BUFFERLENGTHMAXIMUM, _
			NULL, _
			NULL _
		)
		
		If pContext->cbLength Then
			
			ZeroMemory(@pContext->Overlap, SizeOf(WSAOVERLAPPED))
			
			pContext->pIrcClient = pIrcClient
			
			Dim CrLf As CrLfA = Any
			CrLf.Cr = Characters.CarriageReturn
			CrLf.Lf = Characters.LineFeed
			
			Dim SendBuf As SendBuffers = Any
			SendBuf.Bytes.len = Cast(ULONG, min(pContext->cbLength, SENDOVERLAPPEDDATA_BUFFERLENGTHMAXIMUM))
			SendBuf.Bytes.buf = @pContext->Buffer
			
			SendBuf.CrLf.len = CrLfALength
			SendBuf.CrLf.buf = Cast(CHAR Ptr, @CrLf)
			
			Const dwSendFlags As DWORD = 0
			Dim res As Long = WSASend( _
				pIrcClient->ClientSocket, _
				CPtr(WSABUF Ptr, @SendBuf), _
				SendBuffersCount, _
				NULL, _
				dwSendFlags, _
				@pContext->Overlap, _
				@SendCompletionRoutine _
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
		
		Dim dwError As DWORD = GetLastError()
		hr = HRESULT_FROM_WIN32(dwError)
		
		Deallocate(pContext)
		
	End If
	
	Return hr
	
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
		ConnectionString.Append(PassStringWithSpace, Len(PassStringWithSpace))
		ConnectionString &= Password
		ConnectionString.Append(NewLineString, Len(NewLineString))
	End If
	
	ConnectionString.Append(NickStringWithSpace, Len(NickStringWithSpace))
	ConnectionString &= Nick
	ConnectionString.Append(NewLineString, Len(NewLineString))
	
	ConnectionString.Append(UserStringWithSpace, Len(UserStringWithSpace))
	ConnectionString &= User
	
	If ModeFlags And IRCPROTOCOL_MODEFLAG_INVISIBLE Then
		ConnectionString.Append(DefaultBotNameSepInvisible, Len(DefaultBotNameSepInvisible))
	Else
		ConnectionString.Append(DefaultBotNameSepVisible, Len(DefaultBotNameSepVisible))
	End If
	
	If SysStringLen(RealName) = 0 Then
		ConnectionString &= Nick
	Else
		ConnectionString &= RealName
	End If
	
End Sub

Public Function IrcClientChangeNick( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Nick As BSTR _
	)As HRESULT
	
	'NICK space <nickname>
	
	Dim NickLength As Integer = SysStringLen(Nick)
	If NickLength <> 0 Then
		Dim SendString As ValueBSTR = Type<ValueBSTR>(NickStringWithSpace, Len(NickStringWithSpace))
		SendString &= Nick
		
		pIrcClient->ClientNick = Nick
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Public Function IrcClientQuitFromServer( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal QuitText As BSTR _
	)As HRESULT
	
	'QUIT [space :<QuitText>]
	
	Dim SendString As ValueBSTR = Any
	
	If SysStringLen(QuitText) <> 0 Then
		SendString = Type<ValueBSTR>(QuitStringWithSpaceComma, Len(QuitStringWithSpaceComma))
		SendString &= QuitText
	Else
		SendString = Type<ValueBSTR>(QuitString, Len(QuitString))
	End If
	
	Return StartSendOverlapped(pIrcClient, SendString)
	
End Function

Public Function IrcClientSendPong( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Server As BSTR _
	)As HRESULT
	
	'PONG space <Server>
	If SysStringLen(Server) <> 0 Then
		Dim SendString As ValueBSTR = Type<ValueBSTR>(PongStringWithSpace, Len(PongStringWithSpace))
		SendString &= Server
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Public Function IrcClientSendPing( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Server As BSTR _
	)As HRESULT
	
	' �� �������:
	'PING space :<Server>
	
	' �� �������:
	'PING space <Server>
	
	If SysStringLen(Server) <> 0 Then
		Dim SendString As ValueBSTR = Type<ValueBSTR>(PingStringWithSpace, Len(PingStringWithSpace))
		SendString &= Server
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Public Function IrcClientJoinChannel( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Channel As BSTR _
	)As HRESULT
	
	'JOIN space <channel>
	If SysStringLen(Channel) <> 0 Then
		Dim SendString As ValueBSTR = Type<ValueBSTR>(JoinStringWithSpace, Len(JoinStringWithSpace))
		SendString &= Channel
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Public Function IrcClientPartChannel( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Channel As BSTR, _
		ByVal PartText As BSTR _
	)As HRESULT
	
	'PART space <channel> [space :<partmessage>]
	If SysStringLen(Channel) <> 0 Then
		Dim SendString As ValueBSTR = Type<ValueBSTR>(PartStringWithSpace, Len(PartStringWithSpace))
		SendString &= Channel
		
		If SysStringLen(PartText) <> 0 Then
			SendString.Append(SpaceWithCommaString, Len(SpaceWithCommaString))
			SendString &= PartText
		End If
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Public Function IrcClientRetrieveTopic( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Channel As BSTR _
	)As HRESULT
	
	'TOPIC space <Channel>
	If SysStringLen(Channel) <> 0 Then
		Dim SendString As ValueBSTR = Type<ValueBSTR>(TopicStringWithSpace, Len(TopicStringWithSpace))
		SendString &= Channel
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Public Function IrcClientSetTopic( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Channel As BSTR, _
		ByVal Topic As BSTR _
	)As HRESULT
	
	'TOPIC <Channel> :<Topic>
	
	If SysStringLen(Channel) <> 0 Then
		Dim SendString As ValueBSTR = Type<ValueBSTR>(TopicStringWithSpace, Len(TopicStringWithSpace))
		SendString &= Channel
		SendString.Append(SpaceWithCommaString, Len(SpaceWithCommaString))
		SendString &= Topic
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Public Function IrcClientSendPrivateMessage( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal MessageTarget As BSTR, _
		ByVal MessageText As BSTR _
	)As HRESULT
	
	'PRIVMSG space <msgtarget> space : <text to be sent>
	
	If SysStringLen(MessageTarget) <> 0 AndAlso SysStringLen(MessageText) <> 0 Then
		
		Dim SendString As ValueBSTR = Type<ValueBSTR>(PrivateMessageWithSpace, Len(PrivateMessageWithSpace))
		SendString &= MessageTarget
		SendString.Append(SpaceWithCommaString, Len(SpaceWithCommaString))
		SendString &= MessageText
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Public Function IrcClientSendNotice( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal NoticeTarget As BSTR, _
		ByVal NoticeText As BSTR _
	)As HRESULT
	
	'NOTICE space <msgtarget> space : <text to be sent>
	
	If SysStringLen(NoticeTarget) <> 0 AndAlso SysStringLen(NoticeText) <> 0 Then
		Dim SendString As ValueBSTR = Type<ValueBSTR>(NoticeStringWithSpace, Len(NoticeStringWithSpace))
		SendString &= NoticeTarget
		SendString.Append(SpaceWithCommaString, Len(SpaceWithCommaString))
		SendString &= NoticeText
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Public Function IrcClientSendWho( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Nick As BSTR _
	)As HRESULT
	
	'WHO <nick>
	If SysStringLen(Nick) <> 0 Then
		Dim SendString As ValueBSTR = Type<ValueBSTR>(WhoStringWithSpace, Len(WhoStringWithSpace))
		SendString &= Nick
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Public Function IrcClientSendWhoIs( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Nick As BSTR _
	)As HRESULT
	
	'WHOIS <nick>
	If SysStringLen(Nick) <> 0 Then
		Dim SendString As ValueBSTR = Type<ValueBSTR>(WhoIsStringWithSpace, Len(WhoIsStringWithSpace))
		SendString &= Nick
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Public Function IrcClientSendCtcpPingRequest( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Nick As BSTR, _
		ByVal TimeStamp As BSTR _
	)As HRESULT
	
	'PRIVMSG space <Nick> space : SOH PING space<TimeStamp>SOH
	
	If SysStringLen(Nick) <> 0 AndAlso SysStringLen(TimeStamp) <> 0 Then
		
		Dim SendString As ValueBSTR = Type<ValueBSTR>(PrivateMessageWithSpace, Len(PrivateMessageWithSpace))
		SendString &= Nick
		SendString.Append(SpaceWithCommaString, Len(SpaceWithCommaString))
		SendString.Append(Characters.StartOfHeading)
		SendString.Append(PingStringWithSpace, Len(PingStringWithSpace))
		SendString &= TimeStamp
		SendString.Append(Characters.StartOfHeading)
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Public Function IrcClientSendCtcpTimeRequest( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Nick As BSTR _
	)As HRESULT
	
	'PRIVMSG space <Nick> space : SOH TIME SOH
	
	If SysStringLen(Nick) <> 0 Then
		
		Dim SendString As ValueBSTR = Type<ValueBSTR>(PrivateMessageWithSpace, Len(PrivateMessageWithSpace))
		SendString &= Nick
		SendString.Append(SpaceWithCommaString, Len(SpaceWithCommaString))
		SendString.Append(Characters.StartOfHeading)
		SendString.Append(TimeString, Len(TimeString))
		SendString.Append(Characters.StartOfHeading)
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Public Function IrcClientSendCtcpUserInfoRequest( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Nick As BSTR _
	)As HRESULT
	
	'PRIVMSG space <Nick> space : SOH USERINFO SOH
	
	If SysStringLen(Nick) <> 0 Then
		
		Dim SendString As ValueBSTR = Type<ValueBSTR>(PrivateMessageWithSpace, Len(PrivateMessageWithSpace))
		SendString &= Nick
		SendString.Append(SpaceWithCommaString, Len(SpaceWithCommaString))
		SendString.Append(Characters.StartOfHeading)
		SendString.Append(UserInfoString, Len(UserInfoString))
		SendString.Append(Characters.StartOfHeading)
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Public Function IrcClientSendCtcpVersionRequest( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Nick As BSTR _
	)As HRESULT
	
	'PRIVMSG space <Nick> space : SOH VERSION SOH
	
	If SysStringLen(Nick) <> 0 Then
		
		Dim SendString As ValueBSTR = Type<ValueBSTR>(PrivateMessageWithSpace, Len(PrivateMessageWithSpace))
		SendString &= Nick
		SendString.Append(SpaceWithCommaString, Len(SpaceWithCommaString))
		SendString.Append(Characters.StartOfHeading)
		SendString.Append(VersionString, Len(VersionString))
		SendString.Append(Characters.StartOfHeading)
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Public Function IrcClientSendCtcpAction( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Channel As BSTR, _
		ByVal MessageText As BSTR _
	)As HRESULT
	
	'PRIVMSG space <Channel> space : SOH ACTION space <MessageText>SOH
	
	If SysStringLen(Channel) <> 0 AndAlso SysStringLen(MessageText) <> 0 Then
		
		Dim SendString As ValueBSTR = Type<ValueBSTR>(PrivateMessageWithSpace, Len(PrivateMessageWithSpace))
		SendString &= Channel
		SendString.Append(SpaceWithCommaString, Len(SpaceWithCommaString))
		SendString.Append(Characters.StartOfHeading)
		SendString.Append(ActionStringWithSpace, Len(ActionStringWithSpace))
		SendString &= MessageText
		SendString.Append(Characters.StartOfHeading)
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Public Function IrcClientSendCtcpPingResponse( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Nick As BSTR, _
		ByVal TimeStamp As BSTR _
	)As HRESULT
	
	'NOTICE space <Nick> space : SOH PING space <TimeStamp>SOH
	
	If SysStringLen(Nick) <> 0 AndAlso SysStringLen(TimeStamp) <> 0 Then
		
		Dim SendString As ValueBSTR = Type<ValueBSTR>(NoticeStringWithSpace, Len(NoticeStringWithSpace))
		SendString &= Nick
		SendString.Append(SpaceWithCommaString, Len(SpaceWithCommaString))
		SendString.Append(Characters.StartOfHeading)
		SendString.Append(PingStringWithSpace, Len(PingStringWithSpace))
		SendString &= TimeStamp
		SendString.Append(Characters.StartOfHeading)
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Public Function IrcClientSendCtcpTimeResponse( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Nick As BSTR, _
		ByVal TimeValue As BSTR _
	)As HRESULT
	
	'NOTICE space <Nick> space : SOH TIME space <TimeValue>SOH
	
	If SysStringLen(Nick) <> 0 AndAlso SysStringLen(TimeValue) <> 0 Then
		
		Dim SendString As ValueBSTR = Type<ValueBSTR>(NoticeStringWithSpace, Len(NoticeStringWithSpace))
		SendString &= Nick
		SendString.Append(SpaceWithCommaString, Len(SpaceWithCommaString))
		SendString.Append(Characters.StartOfHeading)
		SendString.Append(TimeStringWithSpace, Len(TimeStringWithSpace))
		SendString &= TimeValue
		SendString.Append(Characters.StartOfHeading)
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Public Function IrcClientSendCtcpUserInfoResponse( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Nick As BSTR, _
		ByVal UserInfo As BSTR _
	)As HRESULT
	
	'NOTICE space <Nick> space : SOH USERINFO space <UserInfo>SOH
	
	If SysStringLen(Nick) <> 0 AndAlso SysStringLen(UserInfo) <> 0 Then
		
		Dim SendString As ValueBSTR = Type<ValueBSTR>(NoticeStringWithSpace, Len(NoticeStringWithSpace))
		SendString &= Nick
		SendString.Append(SpaceWithCommaString, Len(SpaceWithCommaString))
		SendString.Append(Characters.StartOfHeading)
		SendString.Append(UserInfoStringWithSpace, Len(UserInfoStringWithSpace))
		SendString &= UserInfo
		SendString.Append(Characters.StartOfHeading)
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Public Function IrcClientSendCtcpVersionResponse( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal Nick As BSTR, _
		ByVal Version As BSTR _
	)As HRESULT
	
	'NOTICE space <Nick> space : SOH VERSION space <Version>SOH
	
	If SysStringLen(Nick) <> 0 AndAlso SysStringLen(Version) <> 0 Then
		
		Dim SendString As ValueBSTR = Type<ValueBSTR>(NoticeStringWithSpace, Len(NoticeStringWithSpace))
		SendString &= Nick
		SendString.Append(SpaceWithCommaString, Len(SpaceWithCommaString))
		SendString.Append(Characters.StartOfHeading)
		SendString.Append(VersionStringWithSpace, Len(VersionStringWithSpace))
		SendString &= Version
		SendString.Append(Characters.StartOfHeading)
		
		Return StartSendOverlapped(pIrcClient, SendString)
	End If
	
	Return S_FALSE
	
End Function

Public Function IrcClientSendDccSend( _
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
		
		Dim SendString As ValueBSTR = Type<ValueBSTR>(PrivateMessageWithSpace, Len(PrivateMessageWithSpace))
		SendString &= Nick
		SendString.Append(SpaceWithCommaString, Len(SpaceWithCommaString))
		SendString.Append(Characters.StartOfHeading)
		SendString.Append(DccSendWithSpace, Len(DccSendWithSpace))
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

Public Function IrcClientSendRawMessage( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal RawText As BSTR _
	)As HRESULT
	
	Dim SendString As ValueBSTR = Type<ValueBSTR>(RawText)
	
	Return StartSendOverlapped(pIrcClient, SendString)
	
End Function

Public Function CreateIrcClient() As IrcClient Ptr
	
	Dim pIrcClient As IrcClient Ptr = Allocate(SizeOf(IrcClient))
	If pIrcClient = 0 Then
		Return 0
	End If
	
	pIrcClient->hEvent = CreateEventW(NULL, True, False, NULL)
	If pIrcClient->hEvent = NULL Then
		Return 0
	End If
	
	pIrcClient->ClientSocket = INVALID_SOCKET
	
	ZeroMemory(@pIrcClient->ZeroEvents, SizeOf(IrcEvents))
	pIrcClient->pEvents = @pIrcClient->ZeroEvents
	pIrcClient->lpParameter = 0
	
	pIrcClient->pRecvContext = Allocate(SizeOf(RecvClientContext))
	If pIrcClient->pRecvContext = 0 Then
		Return 0
	End If
	pIrcClient->pRecvContext->pIrcClient = pIrcClient
	pIrcClient->pRecvContext->cbLength = 0
	
	pIrcClient->CodePage = CP_UTF8
	pIrcClient->ClientNick = Type<ValueBSTR>()
	pIrcClient->ClientVersion = Type<ValueBSTR>()
	pIrcClient->ClientUserInfo = Type<ValueBSTR>()
	pIrcClient->ErrorCode = S_OK
	pIrcClient->IsInitialized = False
	
	Dim hr As HRESULT = IrcClientStartup(pIrcClient)
	If FAILED(hr) Then
		Return 0
	End If
	
	Return pIrcClient
	
End Function

Public Sub DestroyIrcClient( _
		ByVal pIrcClient As IrcClient Ptr _
	)
	
	If pIrcClient->ClientSocket <> INVALID_SOCKET Then
		closesocket(pIrcClient->ClientSocket)
	End If
	
	IrcClientCleanup(pIrcClient)
	Deallocate(pIrcClient->pRecvContext)
	CloseHandle(pIrcClient->hEvent)
	Deallocate(pIrcClient)
	
End Sub

Public Sub IrcClientSetCallback( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pEvents As IrcEvents Ptr, _
		ByVal lpParameter As LPCLIENTDATA _
	)
	
	pIrcClient->pEvents = pEvents
	pIrcClient->lpParameter = lpParameter
	
End Sub

Public Function IrcClientOpenConnection( _
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
	
	pIrcClient->ErrorCode = S_OK
	
	pIrcClient->pRecvContext->cbLength = 0
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

Public Sub IrcClientCloseConnection( _
		ByVal pIrcClient As IrcClient Ptr _
	)
	
	CloseSocketConnection(pIrcClient->ClientSocket)
	pIrcClient->ClientSocket = INVALID_SOCKET
	pIrcClient->ErrorCode = S_OK
	SetEvent(pIrcClient->hEvent)
	
End Sub

Public Function IrcClientMainLoop( _
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
				' ����������� ����������� ���������, ���������� �����
				
			Case WAIT_TIMEOUT
				Return S_FALSE
				
			Case WAIT_FAILED
				Dim dwError As DWORD = GetLastError()
				Return HRESULT_FROM_WIN32(dwError)
				
			Case Else
				Return E_UNEXPECTED
				
		End Select
		
	Loop
	
End Function

Public Function IrcClientMsgMainLoop( _
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
				' ������� ����� ����������
				Return S_FALSE
				
			Case WAIT_OBJECT_0 + 1
				' ��������� ��������� � ������� ���������
				Return pIrcClient->ErrorCode
				
			Case WAIT_ABANDONED
				Return E_FAIL
				
			Case WAIT_IO_COMPLETION
				' ����������� ����������� ���������, ���������� �����
				
			Case WAIT_TIMEOUT
				' ����� �������� ������� ������� = �� ����������� ����������� ��������� = ��� ������ �� �������
				Return S_FALSE
				
			Case WAIT_FAILED
				' ������� ����������
				Dim dwError As DWORD = GetLastError()
				Return HRESULT_FROM_WIN32(dwError)
				
			Case Else
				Return E_UNEXPECTED
				
		End Select
		
	Loop
	
End Function
