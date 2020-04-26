#include "IrcPrefix.bi"
#include "CharacterConstants.bi"
#include "StringConstants.bi"
#include "win\shlwapi.bi"

Function GetIrcPrefix( _
		ByVal pIrcPrefix As IrcPrefix Ptr, _
		ByVal IrcData As WString Ptr _
	)As WString Ptr
	
	If IrcData[0] = Characters.Colon Then
		'prefix     =  servername / ( nickname [ [ "!" user ] "@" host ] )
		':Qubick!~miranda@192.168.1.1 JOIN ##freebasic
		Dim wWhiteSpaceChar As WString Ptr = StrChr(IrcData, Characters.WhiteSpace)
		
		If wWhiteSpaceChar <> 0 Then
			wWhiteSpaceChar[0] = Characters.NullChar
			
			pIrcPrefix->Nick = @IrcData[1]
			
			Dim wExclamationChar As WString Ptr = StrChr(@IrcData[1], Characters.ExclamationMark)
			If wExclamationChar = 0 Then
				pIrcPrefix->User = @EmptyString
				pIrcPrefix->Host = @EmptyString
			Else
				wExclamationChar[0] = Characters.NullChar
				pIrcPrefix->User = @wExclamationChar[1]
				
				Dim wCommercialAtChar As WString Ptr = StrChr(@wExclamationChar[1], Characters.CommercialAt)
				If wCommercialAtChar = 0 Then
					pIrcPrefix->Host = @EmptyString
				Else
					wCommercialAtChar[0] = Characters.NullChar
					pIrcPrefix->Host = @wCommercialAtChar[1]
				End If
			End If
			
			Return @wWhiteSpaceChar[1]
		End If
	End If
	
	pIrcPrefix->Nick = @EmptyString
	pIrcPrefix->User = @EmptyString
	pIrcPrefix->Host = @EmptyString
	
	Return IrcData
	
End Function
