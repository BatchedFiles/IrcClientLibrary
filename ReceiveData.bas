#include "ReceiveData.bi"

Function FindCrLfA( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal pFindIndex As Integer Ptr _
	)As Boolean
	' Минус 2 потому что один байт под Lf и один, чтобы не выйти за границу
	For i As Integer = 0 To pIrcClient->ClientRawBufferLength - 2
		If pIrcClient->ClientRawBuffer[i] = 13 AndAlso pIrcClient->ClientRawBuffer[i + 1] = 10 Then
			*pFindIndex = i
			Return True
		End If
	Next
	*pFindIndex = 0
	Return False
End Function

Function ReceiveData( _
		ByVal pIrcClient As IrcClient Ptr, _
		ByVal strReceiveData As WString Ptr _
	)As Boolean
	
	' Ищем в буфере символы CrLf
	' Если они есть, то возвращаем строку до CrLf
	' иначе получаем данные, добавляя их в буфер, до тех пор, пока не появятся CrLf
	Dim CrLfIndex As Integer = 0
	Dim FindCrLfResult As Boolean = FindCrLfA(pIrcClient, @CrLfIndex)
	
	Do While FindCrLfResult = False
		' Проверить размер текущего накопительного буфера
		' Если он заполнен, то вернуть его весь
		
		If pIrcClient->ClientRawBufferLength >= IrcClient.MaxBytesCount Then
			' Буфер заполнен, вернуть его весь
			CrLfIndex = IrcClient.MaxBytesCount
			pIrcClient->ClientRawBufferLength = IrcClient.MaxBytesCount
			Exit Do
		Else
			' Получаем данные
			Dim intReceivedBytesCount As Integer = recv(pIrcClient->ClientSocket, @pIrcClient->ClientRawBuffer + pIrcClient->ClientRawBufferLength, IrcClient.MaxBytesCount - pIrcClient->ClientRawBufferLength, 0)
			
			Select Case intReceivedBytesCount
				Case SOCKET_ERROR
					' Ошибка, так как должно быть как минимум 1 байт на блокирующем сокете
					strReceiveData[0] = 0
					Return False
				Case 0
					' Клиент закрыл соединение
					strReceiveData[0] = 0
					Return False
				Case Else
					' Увеличить размер буфера на количество принятых байт
					pIrcClient->ClientRawBufferLength += intReceivedBytesCount
					' Заключительный нулевой символ
					pIrcClient->ClientRawBuffer[pIrcClient->ClientRawBufferLength] = 0
			End Select
		End If
		FindCrLfResult = FindCrLfA(pIrcClient, @CrLfIndex)
	Loop
	
	pIrcClient->ClientRawBuffer[CrLfIndex] = 0
	
	MultiByteToWideChar(pIrcClient->CodePage, 0, @pIrcClient->ClientRawBuffer, -1, strReceiveData, IrcClient.MaxBytesCount + 1)
	
	' Сдвинуть буфер влево
	If IrcClient.MaxBytesCount - CrLfIndex = 0 Then
		pIrcClient->ClientRawBuffer[0] = 0
		pIrcClient->ClientRawBufferLength = 0
	Else
		Dim NextCharIndex As Integer = CrLfIndex + 2
		If NextCharIndex = pIrcClient->ClientRawBufferLength Then
			pIrcClient->ClientRawBuffer[0] = 0
			pIrcClient->ClientRawBufferLength = 0
		Else
			memmove(@pIrcClient->ClientRawBuffer, @pIrcClient->ClientRawBuffer + NextCharIndex, IrcClient.MaxBytesCount - NextCharIndex + 1)
			pIrcClient->ClientRawBufferLength -= NextCharIndex
		End If
	End If
	
	If CInt(pIrcClient->ReceivedRawMessageEvent) Then
		pIrcClient->ReceivedRawMessageEvent(pIrcClient->AdvancedClientData, strReceiveData)
	End If
	
	Return True
End Function