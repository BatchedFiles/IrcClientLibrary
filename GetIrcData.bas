#include once "GetIrcData.bi"
#include once "StringConstants.bi"

#ifndef unicode
#define unicode
#endif
#include once "windows.bi"
#include once "win\shlwapi.bi"

Sub GetIrcUserName( _
		ByVal strReturn As WString Ptr, _
		ByVal strData As WString Ptr _
	)
	
	':Qubick!~miranda@192.168.1.1 JOIN ##freebasic
	Dim Start As Integer = Any
	If strData[0] = ColonChar Then
		Start = 1
	Else
		Start = 0
	End If
	
	' Скопировать без учёта начального двоеточия
	lstrcpy(strReturn, @strData[Start])
	
	' Найти знак "!" и удалить
	Dim w As WString Ptr = StrChr(strReturn, ExclamationChar)
	If w <> 0 Then
		w[0] = 0
	End If
	
End Sub

Function GetIrcMessageText( _
		ByVal strData As WString Ptr _
	)As WString Ptr
	
	':Qubick!~miranda@192.168.1.1 PRIVMSG ##freebasic :Hello World
	Dim w As WString Ptr = StrChr(strData, ColonChar)
	If w = 0 Then
		Return 0
	Else
		Return w + 1
	End If
End Function

Function GetIrcServerName( _
		ByVal strData As WString Ptr _
	)As WString Ptr
	
	' Вернуть строку после двоеточия
	Dim w As WString Ptr = StrChr(strData, ColonChar)
	If w = 0 Then
		Return 0
	Else
		Return w + 1
	End If
	
End Function

Function GetServerWord( _
		ByVal w As WString Ptr _
	)As ServerWord
	
	If lstrcmp(w, @PingString) = 0 Then
		Return ServerWord.PingWord
	End If
	
	If lstrcmp(w, @PongString) = 0 Then
		Return ServerWord.PongWord
	End If
	
	If lstrcmp(w, @ErrorString) = 0 Then
		Return ServerWord.ErrorWord
	End If
	
	Return ServerWord.ElseWord
End Function

Function GetServerCommand( _
		ByVal w As WString Ptr _
	)As ServerCommand
	
	If lstrcmp(w, @PrivateMessage) = 0 Then
		Return ServerCommand.PrivateMessage
	End If
	
	If lstrcmp(w, @NoticeString) = 0 Then
		Return ServerCommand.Notice
	End If
	
	If lstrcmp(w, @JoinString) = 0 Then
		Return ServerCommand.Join
	End If
	
	If lstrcmp(w, @QuitString) = 0 Then
		Return ServerCommand.Quit
	End If
	
	If lstrcmp(w, @InviteString) = 0 Then
		Return ServerCommand.Invite
	End If
	
	If lstrcmp(w, @KickString) = 0 Then
		Return ServerCommand.Kick
	End If
	
	If lstrcmp(w, @ModeString) = 0 Then
		Return ServerCommand.Mode
	End If
	
	If lstrcmp(w, @NickString) = 0 Then
		Return ServerCommand.Nick
	End If
	
	If lstrcmp(w, @PartString) = 0 Then
		Return ServerCommand.Part
	End If
	
	If lstrcmp(w, @SQuitString) = 0 Then
		Return ServerCommand.SQuit
	End If
	
	If lstrcmp(w, @TopicString) = 0 Then
		Return ServerCommand.Topic
	End If
	
	Return ServerCommand.Server
End Function

Function GetCtcpCommand( _
		ByVal w As WString Ptr _
	)As CtcpMessageKind
	
	If lstrcmp(w, @PingString) = 0 Then
		Return CtcpMessageKind.Ping
	End If
	
	If lstrcmp(w, @UserInfoString) = 0 Then
		Return CtcpMessageKind.UserInfo
	End If
	
	If lstrcmp(w, @TimeString) = 0 Then
		Return CtcpMessageKind.Time
	End If
	
	If lstrcmp(w, @VersionString) = 0 Then
		Return CtcpMessageKind.Version
	End If
	
	If lstrcmp(w, @ActionString) = 0 Then
		Return CtcpMessageKind.Action
	End If
	
	Return CtcpMessageKind.None
End Function

Function GetNextWord( _
		ByVal wStart As WString Ptr _
	)As WString Ptr
	
	Dim ws As WString Ptr = StrChr(wStart, WhiteSpaceChar)
	
	If ws = 0 Then
		Return wStart
	End If
	
	ws[0] = 0
	Return ws + 1
End Function
