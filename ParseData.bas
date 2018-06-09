#include "ParseData.bi"
#include "GetIrcData.bi"
#include "StringConstants.bi"

Function IsCtcpMessage( _
		ByVal strMessageText As WString Ptr, _
		ByVal MessageTextLength As Integer _
	)As Boolean
	If MessageTextLength > 2 Then
		If strMessageText[0] = 1 Then
			If strMessageText[MessageTextLength - 1] = 1 Then
				Return True
			End If
		End If
	End If
	Return False
End Function

Function ParseData( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal ReceivedData As WString Ptr _
	) As Boolean
	
	Dim Prefix As IrcPrefix = Any
	Dim wStartIrcCommand As WString Ptr = GetIrcPrefix(@Prefix, ReceivedData)
	
	Dim wStartIrcParam1 As WString Ptr = GetNextWord(wStartIrcCommand)
	
	Select Case GetIrcCommand(wStartIrcCommand)
		
		Case IrcCommand.PingWord
			'PING :barjavel.freenode.net
			Dim ServerName As WString Ptr = GetIrcServerName(wStartIrcParam1)
			If ServerName <> 0 Then
				If CInt(pIrcClient->PingEvent) Then
					pIrcClient->PingEvent(pIrcClient->AdvancedClientData, @Prefix, ServerName)
				Else
					Return SendPong(pIrcClient, ServerName)
				End If
			End If
			
		Case IrcCommand.PrivateMessage
			':Angel!wings@irc.org PRIVMSG Wiz :Are you receiving this message ?
			':Angel!wings@irc.org PRIVMSG Qubick :PING 1402355972
			':Angel!wings@irc.org PRIVMSG Qubick :VERSION
			':Angel!wings@irc.org PRIVMSG Qubick :TIME
			':Angel!wings@irc.org PRIVMSG Qubick :USERINFO
			
			Dim ircReceiver As WString Ptr = wStartIrcParam1
			Dim wStartIrcParam2 As WString Ptr = GetNextWord(wStartIrcParam1)
	
			Dim strMessageText As WString Ptr = GetIrcMessageText(wStartIrcParam2)
			
			If strMessageText <> 0 Then
				Dim MessageTextLength As Integer = lstrlen(strMessageText)
				
				If IsCtcpMessage(strMessageText, MessageTextLength) Then
					strMessageText[MessageTextLength - 1] = 0
					Dim wStartCtcpParam As WString Ptr = GetNextWord(@strMessageText[1])
					
					Select Case GetCtcpCommand(@strMessageText[1])
						
						Case CtcpMessageKind.Ping
							
							If CInt(pIrcClient->CtcpPingRequestEvent) = 0 Then
								SendCtcpPingResponse(pIrcClient, Prefix.Nick, wStartCtcpParam)
							Else
								pIrcClient->CtcpPingRequestEvent(pIrcClient->AdvancedClientData, @Prefix, ircReceiver, wStartCtcpParam)
							End If
							
						Case CtcpMessageKind.UserInfo
							If CInt(pIrcClient->CtcpUserInfoRequestEvent) = 0 Then
								If pIrcClient->ClientUserInfo <> 0 Then
									SendCtcpUserInfoResponse(pIrcClient, Prefix.Nick, pIrcClient->ClientUserInfo)
								End If
							Else
								pIrcClient->CtcpUserInfoRequestEvent(pIrcClient->AdvancedClientData, @Prefix, ircReceiver)
							End If
							
						Case CtcpMessageKind.Time
							If CInt(pIrcClient->CtcpTimeRequestEvent) = 0 Then
								' Tue, 15 Nov 1994 12:45:26 GMT
								Const DateFormatString = "ddd, dd MMM yyyy "
								Const TimeFormatString = "HH:mm:ss GMT"
								Dim TimeValue As WString * 64 = Any
								Dim dtNow As SYSTEMTIME = Any
								
								GetSystemTime(@dtNow)
								
								Dim dtBufferLength As Integer = GetDateFormat(LOCALE_INVARIANT, 0, @dtNow, @DateFormatString, @TimeValue, 31) - 1
								GetTimeFormat(LOCALE_INVARIANT, 0, @dtNow, @TimeFormatString, @TimeValue[dtBufferLength], 31 - dtBufferLength)
								
								Return SendCtcpTimeResponse(pIrcClient, Prefix.Nick, @TimeValue)
							Else
								pIrcClient->CtcpTimeRequestEvent(pIrcClient->AdvancedClientData, @Prefix, ircReceiver)
							End If
							
						Case CtcpMessageKind.Version
							If CInt(pIrcClient->CtcpVersionRequestEvent) = 0 Then
								If pIrcClient->ClientVersion <> 0 Then
									Return SendCtcpVersionResponse(pIrcClient, Prefix.Nick, pIrcClient->ClientVersion)
								End If
							Else
								pIrcClient->CtcpVersionRequestEvent(pIrcClient->AdvancedClientData, @Prefix, ircReceiver)
							End If
							
						Case CtcpMessageKind.Action
							If CInt(pIrcClient->CtcpActionEvent) Then
								pIrcClient->CtcpActionEvent(pIrcClient->AdvancedClientData, @Prefix, ircReceiver, wStartCtcpParam)
							End If
							
					End Select
				Else
					If lstrcmp(ircReceiver, @pIrcClient->ClientNick) = 0 Then
						If CInt(pIrcClient->PrivateMessageEvent) Then
							pIrcClient->PrivateMessageEvent(pIrcClient->AdvancedClientData, @Prefix, strMessageText)
						End If
					Else
						If CInt(pIrcClient->ChannelMessageEvent) Then
							pIrcClient->ChannelMessageEvent(pIrcClient->AdvancedClientData, @Prefix, ircReceiver, strMessageText)
						End If
					End If
				End If
			End If
			
		Case IrcCommand.Join
			':Qubick!~Qubick@irc.org JOIN ##freebasic
			If CInt(pIrcClient->UserJoinedEvent) Then
				pIrcClient->UserJoinedEvent(pIrcClient->AdvancedClientData, @Prefix, wStartIrcParam1)
			End If
			
		Case IrcCommand.Quit, IrcCommand.SQuit
			' :syrk!kalt@millennium.stealth.net QUIT :Gone to have lunch
			If CInt(pIrcClient->QuitEvent) Then
				Dim QuitText As WString Ptr = GetIrcMessageText(wStartIrcParam1)
				If QuitText = 0 Then
					pIrcClient->QuitEvent(pIrcClient->AdvancedClientData, @Prefix, @EmptyString)
				Else
					pIrcClient->QuitEvent(pIrcClient->AdvancedClientData, @Prefix, QuitText)
				End If
			End If
			
		Case IrcCommand.Notice
			':Angel!wings@irc.org NOTICE Wiz :Are you receiving this message ?
			':Angel!wings@irc.org NOTICE Qubick :PING 1402355972
			
			Dim ircReceiver As WString Ptr = wStartIrcParam1
			Dim wStartIrcParam2 As WString Ptr = GetNextWord(wStartIrcParam1)
			
			Dim strNoticeText As WString Ptr = GetIrcMessageText(wStartIrcParam2)
			
			If strNoticeText <> 0 Then
				Dim NoticeTextLength As Integer = lstrlen(strNoticeText)
				
				If IsCtcpMessage(strNoticeText, NoticeTextLength) Then
					strNoticeText[NoticeTextLength - 1] = 0
					Dim wStartCtcpParam As WString Ptr = GetNextWord(@strNoticeText[1])
					
					Select Case GetCtcpCommand(@strNoticeText[1])
						
						Case CtcpMessageKind.Ping
							If CInt(pIrcClient->CtcpPingResponseEvent) Then
								pIrcClient->CtcpPingResponseEvent(pIrcClient->AdvancedClientData, @Prefix, ircReceiver, wStartCtcpParam)
							End If
							
						Case CtcpMessageKind.UserInfo
							If CInt(pIrcClient->CtcpUserInfoResponseEvent) Then
								pIrcClient->CtcpUserInfoResponseEvent(pIrcClient->AdvancedClientData, @Prefix, ircReceiver, wStartCtcpParam)
							End If
							
						Case CtcpMessageKind.Time
							If CInt(pIrcClient->CtcpTimeResponseEvent) Then
								pIrcClient->CtcpTimeResponseEvent(pIrcClient->AdvancedClientData, @Prefix, ircReceiver, wStartCtcpParam)
							End If
							
						Case CtcpMessageKind.Version
							If CInt(pIrcClient->CtcpVersionResponseEvent) Then
								pIrcClient->CtcpVersionResponseEvent(pIrcClient->AdvancedClientData, @Prefix, ircReceiver, wStartCtcpParam)
							End If
							
					End Select
					
				Else
					If lstrcmp(ircReceiver, @pIrcClient->ClientNick) = 0 Then
						If CInt(pIrcClient->NoticeEvent) Then
							pIrcClient->NoticeEvent(pIrcClient->AdvancedClientData, @Prefix, strNoticeText)
						End If
					Else
						If CInt(pIrcClient->ChannelNoticeEvent) Then
							pIrcClient->ChannelNoticeEvent(pIrcClient->AdvancedClientData, @Prefix, ircReceiver, strNoticeText)
						End If
					End If
				End If
			End If
			
		Case IrcCommand.Part
			':WiZ!jto@tolsun.oulu.fi PART #playzone :I lost
			If CInt(pIrcClient->UserLeavedEvent) Then
				Dim wStartIrcParam2 As WString Ptr = GetNextWord(wStartIrcParam1)
				Dim PartText As WString Ptr = GetIrcMessageText(wStartIrcParam2)
				If PartText = 0 Then
					pIrcClient->UserLeavedEvent(pIrcClient->AdvancedClientData, @Prefix, wStartIrcParam1, @EmptyString)
				Else
					pIrcClient->UserLeavedEvent(pIrcClient->AdvancedClientData, @Prefix, wStartIrcParam1, PartText)
				End If
			End If
			
		Case IrcCommand.Nick
			':WiZ!jto@tolsun.oulu.fi NICK Kilroy
			If CInt(pIrcClient->NickChangedEvent) Then
				pIrcClient->NickChangedEvent(pIrcClient->AdvancedClientData, @Prefix, wStartIrcParam1)
			End If
			
		Case IrcCommand.Invite
			':Angel!wings@irc.org INVITE Wiz #Dust
			If CInt(pIrcClient->InviteEvent) Then
				Dim wStartIrcParam2 As WString Ptr = GetNextWord(wStartIrcParam1)
				pIrcClient->InviteEvent(pIrcClient->AdvancedClientData, @Prefix, wStartIrcParam1, wStartIrcParam2)
			End If
			
		Case IrcCommand.Kick
			':WiZ!jto@tolsun.oulu.fi KICK #Finnish John
			If CInt(pIrcClient->KickEvent) Then
				Dim wStartIrcParam2 As WString Ptr = GetNextWord(wStartIrcParam1)
				pIrcClient->KickEvent(pIrcClient->AdvancedClientData, @Prefix, wStartIrcParam1, wStartIrcParam2)
			End If
			
		Case IrcCommand.Topic
			':WiZ!jto@tolsun.oulu.fi TOPIC #test :New topic
			If CInt(pIrcClient->TopicEvent) Then
				Dim wStartIrcParam2 As WString Ptr = GetNextWord(wStartIrcParam1)
				Dim TopicText As WString Ptr = GetIrcMessageText(wStartIrcParam2)
				If TopicText = 0 Then
					pIrcClient->TopicEvent(pIrcClient->AdvancedClientData, @Prefix, wStartIrcParam1, @EmptyString)
				Else
					pIrcClient->TopicEvent(pIrcClient->AdvancedClientData, @Prefix, wStartIrcParam1, TopicText)
				End If
			End If
			
		Case IrcCommand.Mode
			':ChanServ!ChanServ@services. MODE #freebasic +v ssteiner
			':FreeBasicCompile MODE FreeBasicCompile :+i
			If CInt(pIrcClient->ModeEvent) Then
				Dim wStartIrcParam2 As WString Ptr = GetNextWord(wStartIrcParam1)
				Dim wStartIrcParam3 As WString Ptr = GetNextWord(wStartIrcParam2)
				pIrcClient->ModeEvent(pIrcClient->AdvancedClientData, @Prefix, wStartIrcParam1, wStartIrcParam2, wStartIrcParam3)
			End If
			
		Case IrcCommand.PongWord
			'PONG :barjavel.freenode.net
			Dim ServerName As WString Ptr = GetIrcServerName(wStartIrcParam1)
			If ServerName <> 0 Then
				If CInt(pIrcClient->PongEvent) Then
					pIrcClient->PongEvent(pIrcClient->AdvancedClientData, @Prefix, ServerName)
				End If
			End If
			
		Case IrcCommand.ErrorWord
			'ERROR :Closing Link: 89.22.170.64 (Client Quit)
			Dim MessageText As WString Ptr = GetIrcMessageText(wStartIrcParam1)
			If MessageText <> 0 Then
				If CInt(pIrcClient->ServerErrorEvent) Then
					pIrcClient->ServerErrorEvent(pIrcClient->AdvancedClientData, @Prefix, MessageText)
				End If
			End If
			
			Return False
			
		Case IrcCommand.Server
			':orwell.freenode.net 376 FreeBasicCompile :End of /MOTD command.
			If CInt(pIrcClient->ServerMessageEvent) Then
				pIrcClient->ServerMessageEvent(pIrcClient->AdvancedClientData, @Prefix, wStartIrcCommand, wStartIrcParam1)
			End If
			
	End Select
	
	Return True
	
End Function
