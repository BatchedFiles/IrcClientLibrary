#include "GetIrcData.bi"
#include "CharacterConstants.bi"
#include "StringConstants.bi"
#include "win\shlwapi.bi"

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
