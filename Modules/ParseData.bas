#include "ParseData.bi"
#include "CharacterConstants.bi"
#include "GetIrcData.bi"
#include "IntegerToWString.bi"
#include "IrcPrefixInternal.bi"
#include "StringConstants.bi"

#define WStringPtrToValueBstrPtr(pWString) Cast(ValueBSTR Ptr, Cast(Byte Ptr, (pWString)) - SizeOf(UINT))

Type IrcCommandProcessor As Function(ByVal pIrcClient As IrcClient Ptr, ByVal pPrefix As IrcPrefix Ptr, ByVal pwszIrcParam1 As WString Ptr, ByRef bstrIrcMessage As ValueBSTR)As HRESULT

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
		Dim ServerNameLength As Integer = bstrIrcMessage.GetTrailingNullChar() - ServerName
		
		Dim pMessageText As ValueBSTR Ptr = WStringPtrToValueBstrPtr(ServerName)
		pMessageText->Length = ServerNameLength
		
		If CUInt(pIrcClient->lpfnPingEvent) Then
			pIrcClient->lpfnPingEvent(pIrcClient->AdvancedClientData, pPrefix, *pMessageText)
		Else
			Return IrcClientSendPong(pIrcClient, *pMessageText)
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
	':Angel!wings@irc.org PRIVMSG Qubick :PING 1402355972
	':Angel!wings@irc.org PRIVMSG Qubick :VERSION
	':Angel!wings@irc.org PRIVMSG Qubick :TIME
	':Angel!wings@irc.org PRIVMSG Qubick :USERINFO
	
	Dim pwszMsgTarget As WString Ptr = pwszIrcParam1
	Dim pwszStartIrcParam2 As WString Ptr = GetNextWord(pwszIrcParam1)
	
	Dim bstrMsgTarget As ValueBSTR = Type<ValueBSTR>(*pwszMsgTarget, pwszStartIrcParam2 - pwszMsgTarget - 1)
	
	Dim pwszMessageText As WString Ptr = GetIrcMessageText(pwszStartIrcParam2)
	
	If pwszMessageText <> 0 Then
		Dim MessageTextLength As Integer = bstrIrcMessage.GetTrailingNullChar() - pwszMessageText
		
		If IsCtcpMessage(pwszMessageText, MessageTextLength) Then
			pwszMessageText[MessageTextLength - 1] = 0
			Dim wStartCtcpParam As WString Ptr = GetNextWord(@pwszMessageText[1])
			
			Select Case GetCtcpCommand(@pwszMessageText[1])
				
				Case CtcpMessageKind.Ping
					
					Dim pMessageText As ValueBSTR = Type<ValueBSTR>(*wStartCtcpParam)
					If CUInt(pIrcClient->lpfnCtcpPingRequestEvent) = 0 Then
						IrcClientSendCtcpPingResponse(pIrcClient, pPrefix->Nick, pMessageText)
					Else
						pIrcClient->lpfnCtcpPingRequestEvent(pIrcClient->AdvancedClientData, pPrefix, bstrMsgTarget, pMessageText)
					End If
					
				Case CtcpMessageKind.UserInfo
					If CUInt(pIrcClient->lpfnCtcpUserInfoRequestEvent) = 0 Then
						If pIrcClient->ClientUserInfoLength <> 0 Then
							IrcClientSendCtcpUserInfoResponse(pIrcClient, pPrefix->Nick, @pIrcClient->ClientUserInfo)
						End If
					Else
						pIrcClient->lpfnCtcpUserInfoRequestEvent(pIrcClient->AdvancedClientData, pPrefix, bstrMsgTarget)
					End If
					
				Case CtcpMessageKind.Time
					If CUInt(pIrcClient->lpfnCtcpTimeRequestEvent) = 0 Then
						' Tue, 15 Nov 1994 12:45:26 GMT
						Const DateFormatString = "ddd, dd MMM yyyy "
						Const TimeFormatString = "HH:mm:ss GMT"
						Dim TimeValue As WString * 64 = Any
						Dim dtNow As SYSTEMTIME = Any
						
						GetSystemTime(@dtNow)
						
						Dim dtBufferLength As Integer = GetDateFormat(LOCALE_INVARIANT, 0, @dtNow, @DateFormatString, @TimeValue, 31) - 1
						GetTimeFormat(LOCALE_INVARIANT, 0, @dtNow, @TimeFormatString, @TimeValue[dtBufferLength], 31 - dtBufferLength)
						
						Return IrcClientSendCtcpTimeResponse(pIrcClient, pPrefix->Nick, @TimeValue)
					Else
						pIrcClient->lpfnCtcpTimeRequestEvent(pIrcClient->AdvancedClientData, pPrefix, bstrMsgTarget)
					End If
					
				Case CtcpMessageKind.Version
					If CUInt(pIrcClient->lpfnCtcpVersionRequestEvent) = 0 Then
						If pIrcClient->ClientVersionLength <> 0 Then
							Return IrcClientSendCtcpVersionResponse(pIrcClient, pPrefix->Nick, @pIrcClient->ClientVersion)
						End If
					Else
						pIrcClient->lpfnCtcpVersionRequestEvent(pIrcClient->AdvancedClientData, pPrefix, bstrMsgTarget)
					End If
					
				Case CtcpMessageKind.Action
					If CUInt(pIrcClient->lpfnCtcpActionEvent) Then
						Dim pMessageText As ValueBSTR = Type<ValueBSTR>(*wStartCtcpParam)
						pIrcClient->lpfnCtcpActionEvent(pIrcClient->AdvancedClientData, pPrefix, bstrMsgTarget, pMessageText)
					End If
					
			End Select
		Else
			Dim pMessageText As ValueBSTR Ptr = WStringPtrToValueBstrPtr(pwszMessageText)
			pMessageText->Length = MessageTextLength
			
			If lstrcmp(bstrMsgTarget, @pIrcClient->ClientNick) = 0 Then
				If CUInt(pIrcClient->lpfnPrivateMessageEvent) Then
					pIrcClient->lpfnPrivateMessageEvent(pIrcClient->AdvancedClientData, pPrefix, *pMessageText)
				End If
			Else
				If CUInt(pIrcClient->lpfnChannelMessageEvent) Then
					pIrcClient->lpfnChannelMessageEvent(pIrcClient->AdvancedClientData, pPrefix, bstrMsgTarget, *pMessageText)
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
	Dim pwszStartIrcParam2 As WString Ptr = GetNextWord(pwszIrcParam1)
	
	Dim bstrMsgTarget As ValueBSTR = Type<ValueBSTR>(*pwszMsgTarget, pwszStartIrcParam2 - pwszMsgTarget - 1)
	
	Dim pwszNoticeText As WString Ptr = GetIrcMessageText(pwszStartIrcParam2)
	
	If pwszNoticeText <> 0 Then
		Dim NoticeTextLength As Integer = bstrIrcMessage.GetTrailingNullChar() - pwszNoticeText
		
		If IsCtcpMessage(pwszNoticeText, NoticeTextLength) Then
			pwszNoticeText[NoticeTextLength - 1] = 0
			Dim wStartCtcpParam As WString Ptr = GetNextWord(@pwszNoticeText[1])
			
			Dim pMessageText As ValueBSTR = Type<ValueBSTR>(*wStartCtcpParam)
			
			Select Case GetCtcpCommand(@pwszNoticeText[1])
				
				Case CtcpMessageKind.Ping
					If CUInt(pIrcClient->lpfnCtcpPingResponseEvent) Then
						pIrcClient->lpfnCtcpPingResponseEvent(pIrcClient->AdvancedClientData, pPrefix, bstrMsgTarget, pMessageText)
					End If
					
				Case CtcpMessageKind.UserInfo
					If CUInt(pIrcClient->lpfnCtcpUserInfoResponseEvent) Then
						pIrcClient->lpfnCtcpUserInfoResponseEvent(pIrcClient->AdvancedClientData, pPrefix, bstrMsgTarget, pMessageText)
					End If
					
				Case CtcpMessageKind.Time
					If CUInt(pIrcClient->lpfnCtcpTimeResponseEvent) Then
						pIrcClient->lpfnCtcpTimeResponseEvent(pIrcClient->AdvancedClientData, pPrefix, bstrMsgTarget, pMessageText)
					End If
					
				Case CtcpMessageKind.Version
					If CUInt(pIrcClient->lpfnCtcpVersionResponseEvent) Then
						pIrcClient->lpfnCtcpVersionResponseEvent(pIrcClient->AdvancedClientData, pPrefix, bstrMsgTarget, pMessageText)
					End If
					
			End Select
			
		Else
			Dim pMessageText As ValueBSTR Ptr = WStringPtrToValueBstrPtr(pwszNoticeText)
			pMessageText->Length = NoticeTextLength
			
			If lstrcmp(bstrMsgTarget, @pIrcClient->ClientNick) = 0 Then
				If CUInt(pIrcClient->lpfnNoticeEvent) Then
					pIrcClient->lpfnNoticeEvent(pIrcClient->AdvancedClientData, pPrefix, *pMessageText)
				End If
			Else
				If CUInt(pIrcClient->lpfnChannelNoticeEvent) Then
					pIrcClient->lpfnChannelNoticeEvent(pIrcClient->AdvancedClientData, pPrefix, bstrMsgTarget, *pMessageText)
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
	If CUInt(pIrcClient->lpfnUserJoinedEvent) Then
		Dim MessageTextLength As Integer = bstrIrcMessage.GetTrailingNullChar() - pwszIrcParam1
		
		Dim pMessageText As ValueBSTR Ptr = WStringPtrToValueBstrPtr(pwszIrcParam1)
		pMessageText->Length = MessageTextLength
			
		pIrcClient->lpfnUserJoinedEvent(pIrcClient->AdvancedClientData, pPrefix, *pMessageText)
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
	If CUInt(pIrcClient->lpfnQuitEvent) Then
		Dim QuitText As WString Ptr = GetIrcMessageText(pwszIrcParam1)
		
		If QuitText = 0 Then
			Dim MessageText As ValueBSTR = Type<ValueBSTR>(EmptyString)
			pIrcClient->lpfnQuitEvent(pIrcClient->AdvancedClientData, pPrefix, MessageText)
		Else
			Dim MessageTextLength As Integer = bstrIrcMessage.GetTrailingNullChar() - QuitText
			
			Dim pMessageText As ValueBSTR Ptr = WStringPtrToValueBstrPtr(QuitText)
			pMessageText->Length = MessageTextLength
			
			pIrcClient->lpfnQuitEvent(pIrcClient->AdvancedClientData, pPrefix, *pMessageText)
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
	If CUInt(pIrcClient->lpfnUserLeavedEvent) Then
		Dim pwszStartIrcParam2 As WString Ptr = GetNextWord(pwszIrcParam1)
		Dim PartText As WString Ptr = GetIrcMessageText(pwszStartIrcParam2)
		Dim bstrChannel As ValueBSTR = Type<ValueBSTR>(*pwszIrcParam1)
		If PartText = 0 Then
			Dim bstrPartText As ValueBSTR = Type<ValueBSTR>(EmptyString)
			pIrcClient->lpfnUserLeavedEvent(pIrcClient->AdvancedClientData, pPrefix, bstrChannel, bstrPartText)
		Else
			Dim bstrPartText As ValueBSTR = Type<ValueBSTR>(*PartText)
			pIrcClient->lpfnUserLeavedEvent(pIrcClient->AdvancedClientData, pPrefix, bstrChannel, bstrPartText)
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
		If CUInt(pIrcClient->lpfnServerErrorEvent) Then
			Dim MessageTextLength As Integer = bstrIrcMessage.GetTrailingNullChar() - pwszMessageText
			
			Dim pMessageText As ValueBSTR Ptr = WStringPtrToValueBstrPtr(pwszMessageText)
			pMessageText->Length = MessageTextLength
			
			pIrcClient->lpfnServerErrorEvent(pIrcClient->AdvancedClientData, pPrefix, *pMessageText)
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
	If CUInt(pIrcClient->lpfnNickChangedEvent) Then
		Dim MessageTextLength As Integer = bstrIrcMessage.GetTrailingNullChar() - pwszIrcParam1
		
		Dim pMessageText As ValueBSTR Ptr = WStringPtrToValueBstrPtr(pwszIrcParam1)
		pMessageText->Length = MessageTextLength
		
		pIrcClient->lpfnNickChangedEvent(pIrcClient->AdvancedClientData, pPrefix, *pMessageText)
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
	If CUInt(pIrcClient->lpfnKickEvent) Then
		Dim pwszStartIrcParam2 As WString Ptr = GetNextWord(pwszIrcParam1)
		Dim bstrChannel As ValueBSTR = Type<ValueBSTR>(*pwszIrcParam1)
		Dim bstrKickedNick As ValueBSTR = Type<ValueBSTR>(*pwszStartIrcParam2)
		pIrcClient->lpfnKickEvent(pIrcClient->AdvancedClientData, pPrefix, bstrChannel, bstrKickedNick)
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
	If CUInt(pIrcClient->lpfnModeEvent) Then
		' Dim pwszStartIrcParam2 As WString Ptr = GetNextWord(pwszIrcParam1)
		' Dim wStartIrcParam3 As WString Ptr = GetNextWord(pwszStartIrcParam2)
		' TODO Событие MODE
		' pIrcClient->lpfnModeEvent(pIrcClient->AdvancedClientData, pPrefix, pwszIrcParam1, pwszStartIrcParam2, wStartIrcParam3)
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
	If CUInt(pIrcClient->lpfnTopicEvent) Then
		Dim pwszStartIrcParam2 As WString Ptr = GetNextWord(pwszIrcParam1)
		Dim TopicText As WString Ptr = GetIrcMessageText(pwszStartIrcParam2)
		Dim bstrChannel As ValueBSTR = Type<ValueBSTR>(*pwszIrcParam1)
		If TopicText = 0 Then
			Dim bstrTopicText As ValueBSTR = Type<ValueBSTR>(EmptyString)
			pIrcClient->lpfnTopicEvent(pIrcClient->AdvancedClientData, pPrefix, bstrChannel, bstrTopicText)
		Else
			Dim bstrTopicText As ValueBSTR = Type<ValueBSTR>(*TopicText)
			pIrcClient->lpfnTopicEvent(pIrcClient->AdvancedClientData, pPrefix, bstrChannel, bstrTopicText)
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
	If CUInt(pIrcClient->lpfnInviteEvent) Then
		Dim pwszStartIrcParam2 As WString Ptr = GetNextWord(pwszIrcParam1)
		
		Dim Target As ValueBSTR = Type<ValueBSTR>(*pwszIrcParam1)
		Dim Channel As ValueBSTR = Type<ValueBSTR>(pwszStartIrcParam2)
		pIrcClient->lpfnInviteEvent(pIrcClient->AdvancedClientData, pPrefix, Target, Channel)
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
		If CUInt(pIrcClient->lpfnPongEvent) Then
			Dim MessageTextLength As Integer = bstrIrcMessage.GetTrailingNullChar() - ServerName
			
			Dim pMessageText As ValueBSTR Ptr = WStringPtrToValueBstrPtr(ServerName)
			pMessageText->Length = MessageTextLength
			
			pIrcClient->lpfnPongEvent(pIrcClient->AdvancedClientData, pPrefix, *pMessageText)
		End If
	End If
	
	Return S_OK
	
End Function

Function ProcessNumericCommand( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pPrefix As IrcPrefix Ptr, _
		ByVal IrcNumericCommand As Integer, _
		ByVal pwszIrcParam1 As WString Ptr _
	)As HRESULT
	
	':orwell.freenode.net 376 FreeBasicCompile :End of /MOTD command.
	If CUInt(pIrcClient->lpfnNumericMessageEvent) Then
		Dim bstrIrcParam1 As ValueBSTR = Type<ValueBSTR>(*pwszIrcParam1)
		pIrcClient->lpfnNumericMessageEvent(pIrcClient->AdvancedClientData, pPrefix, IrcNumericCommand, pwszIrcParam1)
	End If
	
	Return S_OK
	
End Function

Function ProcessServerCommand( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pPrefix As IrcPrefix Ptr, _
		ByVal pwszIrcCommand As WString Ptr, _
		ByVal pwszIrcParam1 As WString Ptr _
	)As HRESULT
	
	':orwell.freenode.net 376 FreeBasicCompile :End of /MOTD command.
	If CUInt(pIrcClient->lpfnServerMessageEvent) Then
		Dim bstrIrcCommand As ValueBSTR = Type<ValueBSTR>(*pwszIrcCommand)
		Dim bstrIrcParam1 As ValueBSTR = Type<ValueBSTR>(*pwszIrcParam1)
		pIrcClient->lpfnServerMessageEvent(pIrcClient->AdvancedClientData, pPrefix, bstrIrcCommand, bstrIrcParam1)
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
	
	Dim pwszIrcParam1 As WString Ptr = GetNextWord(pwszIrcCommand)
	
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
			Dim IrcCommandLength As Integer = pwszIrcParam1 - pwszIrcCommand - 1
			If IsNumericIrcCommand(pwszIrcCommand, IrcCommandLength) Then
				Dim IrcNumericCommand As Integer = CInt(wtoi(pwszIrcCommand))
				Return ProcessNumericCommand(pIrcClient, @Prefix, IrcNumericCommand, pwszIrcParam1)
			Else
				Return ProcessServerCommand(pIrcClient, @Prefix, pwszIrcCommand, pwszIrcParam1)
			End If
		End If
	End If
	
	Return S_OK
	
End Function
