#include "IrcPrefix.bi"
#include "CharacterConstants.bi"
#include "StringConstants.bi"
#include "win\shlwapi.bi"

Function GetIrcPrefix( _
		ByVal pIrcPrefix As IrcPrefix Ptr, _
		ByVal bstrIrcMessage As BSTR _
	)As Integer
	
	'prefix     =  servername / ( nickname [ [ "!" user ] "@" host ] )
	':Qubick!~miranda@192.168.1.1 JOIN ##freebasic
	
	If bstrIrcMessage[0] = Characters.Colon Then
		
		Dim wWhiteSpaceChar As WString Ptr = StrChrW(@bstrIrcMessage[1], Characters.WhiteSpace)
		
		If wWhiteSpaceChar <> NULL Then
			Dim IrcPrefixLength As Integer = wWhiteSpaceChar - CPtr(WString Ptr, bstrIrcMessage) - 1
			
			wWhiteSpaceChar[0] = Characters.NullChar
			
			pIrcPrefix->Nick = @bstrIrcMessage[1]
			
			Dim wExclamationChar As WString Ptr = StrChr(@bstrIrcMessage[1], Characters.ExclamationMark)
			If wExclamationChar = NULL Then
				pIrcPrefix->NickLength = wWhiteSpaceChar - CPtr(WString Ptr, bstrIrcMessage) - 1
				pIrcPrefix->User = @EmptyString
				pIrcPrefix->UserLength = 0
				pIrcPrefix->Host = @EmptyString
				pIrcPrefix->HostLength = 0
			Else
				pIrcPrefix->NickLength = wExclamationChar - CPtr(WString Ptr, bstrIrcMessage) - 1
				wExclamationChar[0] = Characters.NullChar
				
				pIrcPrefix->User = @wExclamationChar[1]
				
				Dim wCommercialAtChar As WString Ptr = StrChr(@wExclamationChar[1], Characters.CommercialAt)
				If wCommercialAtChar = NULL Then
					pIrcPrefix->UserLength = wWhiteSpaceChar - wExclamationChar - 1
					
					pIrcPrefix->Host = @EmptyString
					pIrcPrefix->HostLength = 0
				Else
					pIrcPrefix->UserLength = wCommercialAtChar - wExclamationChar - 1
					wCommercialAtChar[0] = Characters.NullChar
					
					pIrcPrefix->Host = @wCommercialAtChar[1]
					pIrcPrefix->HostLength = wWhiteSpaceChar - wCommercialAtChar - 1
				End If
			End If
			
			Return IrcPrefixLength
		End If
	End If
	
	pIrcPrefix->Nick = @EmptyString
	pIrcPrefix->NickLength = 0
	pIrcPrefix->User = @EmptyString
	pIrcPrefix->UserLength = 0
	pIrcPrefix->Host = @EmptyString
	pIrcPrefix->HostLength = 0
	
	Return 0
	
End Function
