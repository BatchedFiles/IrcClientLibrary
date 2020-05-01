#include "ParseData.bi"
#include "CharacterConstants.bi"
#include "GetIrcData.bi"
#include "StringConstants.bi"

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
		ByVal pwszIrcParam1 As WString Ptr _
	)As HRESULT
	
	'PING :barjavel.freenode.net
	Dim ServerName As WString Ptr = GetIrcServerName(pwszIrcParam1)
	If ServerName <> 0 Then
		If CUInt(pIrcClient->lpfnPingEvent) Then
			pIrcClient->lpfnPingEvent(pIrcClient->AdvancedClientData, pPrefix, ServerName)
		Else
			Return IrcClientSendPong(pIrcClient, ServerName)
		End If
	End If
	
	Return S_OK
	
End Function

Function ProcessPrivateMessageCommand( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pPrefix As IrcPrefix Ptr, _
		ByVal pwszIrcParam1 As WString Ptr, _
		ByVal bstrIrcMessage As BSTR _
	)As HRESULT
	
	':Angel!wings@irc.org PRIVMSG Wiz :Are you receiving this message ?
	':Angel!wings@irc.org PRIVMSG Qubick :PING 1402355972
	':Angel!wings@irc.org PRIVMSG Qubick :VERSION
	':Angel!wings@irc.org PRIVMSG Qubick :TIME
	':Angel!wings@irc.org PRIVMSG Qubick :USERINFO
	
	Dim pwszMsgTarget As WString Ptr = pwszIrcParam1
	Dim pwszStartIrcParam2 As WString Ptr = GetNextWord(pwszIrcParam1)

	Dim pwszMessageText As WString Ptr = GetIrcMessageText(pwszStartIrcParam2)
	
	If pwszMessageText <> 0 Then
		Dim MessageTextLength As Integer = CPtr(WString Ptr, @bstrIrcMessage[CInt(SysStringLen(bstrIrcMessage))]) - pwszMessageText
		
		If IsCtcpMessage(pwszMessageText, MessageTextLength) Then
			pwszMessageText[MessageTextLength - 1] = 0
			Dim wStartCtcpParam As WString Ptr = GetNextWord(@pwszMessageText[1])
			
			Select Case GetCtcpCommand(@pwszMessageText[1])
				
				Case CtcpMessageKind.Ping
					
					If CUInt(pIrcClient->lpfnCtcpPingRequestEvent) = 0 Then
						IrcClientSendCtcpPingResponse(pIrcClient, pPrefix->Nick, wStartCtcpParam)
					Else
						pIrcClient->lpfnCtcpPingRequestEvent(pIrcClient->AdvancedClientData, pPrefix, pwszMsgTarget, wStartCtcpParam)
					End If
					
				Case CtcpMessageKind.UserInfo
					If CUInt(pIrcClient->lpfnCtcpUserInfoRequestEvent) = 0 Then
						If pIrcClient->ClientUserInfoLength <> 0 Then
							IrcClientSendCtcpUserInfoResponse(pIrcClient, pPrefix->Nick, @pIrcClient->ClientUserInfo)
						End If
					Else
						pIrcClient->lpfnCtcpUserInfoRequestEvent(pIrcClient->AdvancedClientData, pPrefix, pwszMsgTarget)
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
						pIrcClient->lpfnCtcpTimeRequestEvent(pIrcClient->AdvancedClientData, pPrefix, pwszMsgTarget)
					End If
					
				Case CtcpMessageKind.Version
					If CUInt(pIrcClient->lpfnCtcpVersionRequestEvent) = 0 Then
						If pIrcClient->ClientVersionLength <> 0 Then
							Return IrcClientSendCtcpVersionResponse(pIrcClient, pPrefix->Nick, @pIrcClient->ClientVersion)
						End If
					Else
						pIrcClient->lpfnCtcpVersionRequestEvent(pIrcClient->AdvancedClientData, pPrefix, pwszMsgTarget)
					End If
					
				Case CtcpMessageKind.Action
					If CUInt(pIrcClient->lpfnCtcpActionEvent) Then
						pIrcClient->lpfnCtcpActionEvent(pIrcClient->AdvancedClientData, pPrefix, pwszMsgTarget, wStartCtcpParam)
					End If
					
			End Select
		Else
			If lstrcmp(pwszMsgTarget, @pIrcClient->ClientNick) = 0 Then
				If CUInt(pIrcClient->lpfnPrivateMessageEvent) Then
					pIrcClient->lpfnPrivateMessageEvent(pIrcClient->AdvancedClientData, pPrefix, pwszMessageText)
				End If
			Else
				If CUInt(pIrcClient->lpfnChannelMessageEvent) Then
					pIrcClient->lpfnChannelMessageEvent(pIrcClient->AdvancedClientData, pPrefix, pwszMsgTarget, pwszMessageText)
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
		ByVal bstrIrcMessage As BSTR _
	)As HRESULT
	':Angel!wings@irc.org NOTICE Wiz :Are you receiving this message ?
	':Angel!wings@irc.org NOTICE Qubick :PING 1402355972
	
	Dim pwszMsgTarget As WString Ptr = pwszIrcParam1
	Dim pwszStartIrcParam2 As WString Ptr = GetNextWord(pwszIrcParam1)
	
	Dim pwszNoticeText As WString Ptr = GetIrcMessageText(pwszStartIrcParam2)
	
	If pwszNoticeText <> 0 Then
		Dim NoticeTextLength As Integer = CPtr(WString Ptr, @bstrIrcMessage[CInt(SysStringLen(bstrIrcMessage))]) - pwszNoticeText
		
		If IsCtcpMessage(pwszNoticeText, NoticeTextLength) Then
			pwszNoticeText[NoticeTextLength - 1] = 0
			Dim wStartCtcpParam As WString Ptr = GetNextWord(@pwszNoticeText[1])
			
			Select Case GetCtcpCommand(@pwszNoticeText[1])
				
				Case CtcpMessageKind.Ping
					If CUInt(pIrcClient->lpfnCtcpPingResponseEvent) Then
						pIrcClient->lpfnCtcpPingResponseEvent(pIrcClient->AdvancedClientData, pPrefix, pwszMsgTarget, wStartCtcpParam)
					End If
					
				Case CtcpMessageKind.UserInfo
					If CUInt(pIrcClient->lpfnCtcpUserInfoResponseEvent) Then
						pIrcClient->lpfnCtcpUserInfoResponseEvent(pIrcClient->AdvancedClientData, pPrefix, pwszMsgTarget, wStartCtcpParam)
					End If
					
				Case CtcpMessageKind.Time
					If CUInt(pIrcClient->lpfnCtcpTimeResponseEvent) Then
						pIrcClient->lpfnCtcpTimeResponseEvent(pIrcClient->AdvancedClientData, pPrefix, pwszMsgTarget, wStartCtcpParam)
					End If
					
				Case CtcpMessageKind.Version
					If CUInt(pIrcClient->lpfnCtcpVersionResponseEvent) Then
						pIrcClient->lpfnCtcpVersionResponseEvent(pIrcClient->AdvancedClientData, pPrefix, pwszMsgTarget, wStartCtcpParam)
					End If
					
			End Select
			
		Else
			If lstrcmp(pwszMsgTarget, @pIrcClient->ClientNick) = 0 Then
				If CUInt(pIrcClient->lpfnNoticeEvent) Then
					pIrcClient->lpfnNoticeEvent(pIrcClient->AdvancedClientData, pPrefix, pwszNoticeText)
				End If
			Else
				If CUInt(pIrcClient->lpfnChannelNoticeEvent) Then
					pIrcClient->lpfnChannelNoticeEvent(pIrcClient->AdvancedClientData, pPrefix, pwszMsgTarget, pwszNoticeText)
				End If
			End If
		End If
	End If
	Return S_OK
	
End Function

Function ProcessJoinCommand( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pPrefix As IrcPrefix Ptr, _
		ByVal pwszIrcParam1 As WString Ptr _
	)As HRESULT
	
	':Qubick!~Qubick@irc.org JOIN ##freebasic
	If CUInt(pIrcClient->lpfnUserJoinedEvent) Then
		pIrcClient->lpfnUserJoinedEvent(pIrcClient->AdvancedClientData, pPrefix, pwszIrcParam1)
	End If
	
	Return S_OK
	
End Function

Function ProcessQuitCommand( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pPrefix As IrcPrefix Ptr, _
		ByVal pwszIrcParam1 As WString Ptr _
	)As HRESULT
	
	' :syrk!kalt@millennium.stealth.net QUIT :Gone to have lunch
	If CUInt(pIrcClient->lpfnQuitEvent) Then
		Dim QuitText As WString Ptr = GetIrcMessageText(pwszIrcParam1)
		If QuitText = 0 Then
			pIrcClient->lpfnQuitEvent(pIrcClient->AdvancedClientData, pPrefix, @EmptyString)
		Else
			pIrcClient->lpfnQuitEvent(pIrcClient->AdvancedClientData, pPrefix, QuitText)
		End If
	End If
	
	Return S_OK
	
End Function

Function ProcessPartCommand( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pPrefix As IrcPrefix Ptr, _
		ByVal pwszIrcParam1 As WString Ptr _
	)As HRESULT
	
	':WiZ!jto@tolsun.oulu.fi PART #playzone :I lost
	If CUInt(pIrcClient->lpfnUserLeavedEvent) Then
		Dim pwszStartIrcParam2 As WString Ptr = GetNextWord(pwszIrcParam1)
		Dim PartText As WString Ptr = GetIrcMessageText(pwszStartIrcParam2)
		If PartText = 0 Then
			pIrcClient->lpfnUserLeavedEvent(pIrcClient->AdvancedClientData, pPrefix, pwszIrcParam1, @EmptyString)
		Else
			pIrcClient->lpfnUserLeavedEvent(pIrcClient->AdvancedClientData, pPrefix, pwszIrcParam1, PartText)
		End If
	End If
	
	Return S_OK
	
End Function

Function ProcessErrorCommand( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pPrefix As IrcPrefix Ptr, _
		ByVal pwszIrcParam1 As WString Ptr _
	)As HRESULT
	
	'ERROR :Closing Link: 89.22.170.64 (Client Quit)
	Dim MessageText As WString Ptr = GetIrcMessageText(pwszIrcParam1)
	If MessageText <> 0 Then
		If CUInt(pIrcClient->lpfnServerErrorEvent) Then
			pIrcClient->lpfnServerErrorEvent(pIrcClient->AdvancedClientData, pPrefix, MessageText)
		End If
	End If
	
	Return E_FAIL
	
End Function

Function ProcessNickCommand( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pPrefix As IrcPrefix Ptr, _
		ByVal pwszIrcParam1 As WString Ptr _
	)As HRESULT
	
	':WiZ!jto@tolsun.oulu.fi NICK Kilroy
	If CUInt(pIrcClient->lpfnNickChangedEvent) Then
		pIrcClient->lpfnNickChangedEvent(pIrcClient->AdvancedClientData, pPrefix, pwszIrcParam1)
	End If
	
	Return S_OK
	
End Function

Function ProcessKickCommand( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pPrefix As IrcPrefix Ptr, _
		ByVal pwszIrcParam1 As WString Ptr _
	)As HRESULT
	
	':WiZ!jto@tolsun.oulu.fi KICK #Finnish John
	If CUInt(pIrcClient->lpfnKickEvent) Then
		Dim pwszStartIrcParam2 As WString Ptr = GetNextWord(pwszIrcParam1)
		pIrcClient->lpfnKickEvent(pIrcClient->AdvancedClientData, pPrefix, pwszIrcParam1, pwszStartIrcParam2)
	End If
	
	Return S_OK
	
End Function

Function ProcessModeCommand( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pPrefix As IrcPrefix Ptr, _
		ByVal pwszIrcParam1 As WString Ptr _
	)As HRESULT
	
	':ChanServ!ChanServ@services. MODE #freebasic +v ssteiner
	':FreeBasicCompile MODE FreeBasicCompile :+i
	If CUInt(pIrcClient->lpfnModeEvent) Then
		Dim pwszStartIrcParam2 As WString Ptr = GetNextWord(pwszIrcParam1)
		Dim wStartIrcParam3 As WString Ptr = GetNextWord(pwszStartIrcParam2)
		pIrcClient->lpfnModeEvent(pIrcClient->AdvancedClientData, pPrefix, pwszIrcParam1, pwszStartIrcParam2, wStartIrcParam3)
	End If
	
	Return S_OK
	
End Function

Function ProcessTopicCommand( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pPrefix As IrcPrefix Ptr, _
		ByVal pwszIrcParam1 As WString Ptr _
	)As HRESULT
	
	':WiZ!jto@tolsun.oulu.fi TOPIC #test :New topic
	If CUInt(pIrcClient->lpfnTopicEvent) Then
		Dim pwszStartIrcParam2 As WString Ptr = GetNextWord(pwszIrcParam1)
		Dim TopicText As WString Ptr = GetIrcMessageText(pwszStartIrcParam2)
		If TopicText = 0 Then
			pIrcClient->lpfnTopicEvent(pIrcClient->AdvancedClientData, pPrefix, pwszIrcParam1, @EmptyString)
		Else
			pIrcClient->lpfnTopicEvent(pIrcClient->AdvancedClientData, pPrefix, pwszIrcParam1, TopicText)
		End If
	End If
	
	Return S_OK
	
End Function

Function ProcessInviteCommand( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pPrefix As IrcPrefix Ptr, _
		ByVal pwszIrcParam1 As WString Ptr _
	)As HRESULT
	
	':Angel!wings@irc.org INVITE Wiz #Dust
	If CUInt(pIrcClient->lpfnInviteEvent) Then
		Dim pwszStartIrcParam2 As WString Ptr = GetNextWord(pwszIrcParam1)
		pIrcClient->lpfnInviteEvent(pIrcClient->AdvancedClientData, pPrefix, pwszIrcParam1, pwszStartIrcParam2)
	End If
	
	Return S_OK
	
End Function

Function ProcessServerCommand( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pPrefix As IrcPrefix Ptr, _
		ByVal pwszIrcParam1 As WString Ptr, _
		ByVal pwszIrcCommand As WString Ptr _
	)As HRESULT
	
	':orwell.freenode.net 376 FreeBasicCompile :End of /MOTD command.
	If CUInt(pIrcClient->lpfnServerMessageEvent) Then
		pIrcClient->lpfnServerMessageEvent(pIrcClient->AdvancedClientData, pPrefix, pwszIrcCommand, pwszIrcParam1)
	End If
	
	Return S_OK
	
End Function

Function ProcessPongCommand( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pPrefix As IrcPrefix Ptr, _
		ByVal pwszIrcParam1 As WString Ptr _
	)As HRESULT
	
	'PONG :barjavel.freenode.net
	Dim ServerName As WString Ptr = GetIrcServerName(pwszIrcParam1)
	If ServerName <> 0 Then
		If CUInt(pIrcClient->lpfnPongEvent) Then
			pIrcClient->lpfnPongEvent(pIrcClient->AdvancedClientData, pPrefix, ServerName)
		End If
	End If
	
	Return S_OK
	
End Function

Function ParseData( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal bstrIrcMessage As BSTR _
	)As HRESULT
	
	Dim Prefix As IrcPrefix = Any
	Dim PrefixLength As Integer = GetIrcPrefix(@Prefix, bstrIrcMessage)
	
	Dim pwszIrcCommand As WString Ptr = Any
	' Dim IrcCommandLength As Integer = Any
	If PrefixLength = 0 Then
		pwszIrcCommand = bstrIrcMessage
	Else
		pwszIrcCommand = @bstrIrcMessage[PrefixLength + 1 + 1] ' colon + space
	End If
	
	Dim pwszIrcParam1 As WString Ptr = GetNextWord(pwszIrcCommand)
	' Dim pwszIrcParam1Length As Integer = Any
	' IrcCommandLength = pwszIrcParam1 - pwszIrcCommand - 1
	
	Select Case GetIrcCommand(pwszIrcCommand)
		
		Case IrcCommand.Ping
			Return ProcessPingCommand(pIrcClient, @Prefix, pwszIrcParam1)
			
		Case IrcCommand.PrivateMessage
			Return ProcessPrivateMessageCommand(pIrcClient, @Prefix, pwszIrcParam1, bstrIrcMessage)
			
		Case IrcCommand.Join
			Return ProcessJoinCommand(pIrcClient, @Prefix, pwszIrcParam1)
			
		Case IrcCommand.Quit, IrcCommand.SQuit
			Return ProcessQuitCommand(pIrcClient, @Prefix, pwszIrcParam1)
			
		Case IrcCommand.Part
			Return ProcessPartCommand(pIrcClient, @Prefix, pwszIrcParam1)
			
		Case IrcCommand.Notice
			Return ProcessNoticeCommand(pIrcClient, @Prefix, pwszIrcParam1, bstrIrcMessage)
			
		Case IrcCommand.Nick
			Return ProcessNickCommand(pIrcClient, @Prefix, pwszIrcParam1)
			
		Case IrcCommand.Error
			Return ProcessErrorCommand(pIrcClient, @Prefix, pwszIrcParam1)
			
		Case IrcCommand.Kick
			Return ProcessKickCommand(pIrcClient, @Prefix, pwszIrcParam1)
			
		Case IrcCommand.Mode
			Return ProcessModeCommand(pIrcClient, @Prefix, pwszIrcParam1)
			
		Case IrcCommand.Topic
			Return ProcessTopicCommand(pIrcClient, @Prefix, pwszIrcParam1)
			
		Case IrcCommand.Invite
			Return ProcessInviteCommand(pIrcClient, @Prefix, pwszIrcParam1)
			
		Case IrcCommand.Pong
			Return ProcessPongCommand(pIrcClient, @Prefix, pwszIrcParam1)
			
		Case IrcCommand.Server
			Return ProcessServerCommand(pIrcClient, @Prefix, pwszIrcParam1, pwszIrcCommand)
			
	End Select
	
	Return S_OK
	
End Function
