#include "ParseData.bi"
#include "CharacterConstants.bi"
#include "GetIrcData.bi"
#include "StringConstants.bi"
#include "win\shlwapi.bi"

Type IrcCommandProcessor As Function(ByVal pIrcClient As IrcClient Ptr, ByVal pPrefix As IrcPrefix Ptr, ByVal pwszIrcParam1 As WString Ptr, ByRef bstrIrcMessage As ValueBSTR)As HRESULT

Type IrcPrefixInternal
	Dim Nick As ValueBSTR
	Dim User As ValueBSTR
	Dim Host As ValueBSTR
End Type

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
		' TODO Событие MODE
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
