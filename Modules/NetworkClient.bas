#include "NetworkClient.bi"

Function ConnectToServerA( _
		ByVal LocalAddress As PCSTR, _
		ByVal LocalPort As PCSTR, _
		ByVal RemoteAddress As PCSTR, _
		ByVal RemotePort As PCSTR, _
		ByVal pSocket As SOCKET Ptr _
	)As HRESULT
	
	Dim ClientSocket As SOCKET = Any
	Dim hr As HRESULT = CreateSocketAndBindA(LocalAddress, LocalPort, @ClientSocket)
	
	If FAILED(hr) Then
		
		Return hr
		
	End If
	
	Dim pAddressList As addrinfo Ptr = NULL
	hr = ResolveHostA(RemoteAddress, RemotePort, @pAddressList)
	
	If FAILED(hr) Then
		
		closesocket(ClientSocket)
		Return HRESULT_FROM_WIN32(WSAGetLastError())
		
	End If
	
	Dim pAddress As addrinfo Ptr = pAddressList
	Dim ConnectResult As Integer = Any
	
	Dim e As Long = 0
	Do
		ConnectResult = connect(ClientSocket, Cast(LPSOCKADDR, pAddress->ai_addr), pAddress->ai_addrlen)
		e = WSAGetLastError()
		
		If ConnectResult = 0 Then
			Exit Do
		End If
		
		pAddress = pAddress->ai_next
		
	Loop Until pAddress = 0
	
	FreeAddrInfo(pAddressList)
	
	If ConnectResult <> 0 Then
		
		closesocket(ClientSocket)
		Return HRESULT_FROM_WIN32(e)
		
	End If
	
	*pSocket = ClientSocket
	Return S_OK
	
End Function

Function ConnectToServerW( _
		ByVal LocalAddress As PCWSTR, _
		ByVal LocalPort As PCWSTR, _
		ByVal RemoteAddress As PCWSTR, _
		ByVal RemotePort As PCWSTR, _
		ByVal pSocket As SOCKET Ptr _
	)As HRESULT
	
	Dim ClientSocket As SOCKET = Any
	Dim hr As HRESULT = CreateSocketAndBindW(LocalAddress, LocalPort, @ClientSocket)
	
	If FAILED(hr) Then
		
		Return hr
		
	End If
	
	Dim pAddressList As addrinfoW Ptr = NULL
	hr = ResolveHostW(RemoteAddress, RemotePort, @pAddressList)
	
	If FAILED(hr) Then
		
		closesocket(ClientSocket)
		Return HRESULT_FROM_WIN32(WSAGetLastError())
		
	End If
	
	Dim pAddress As addrinfoW Ptr = pAddressList
	Dim ConnectResult As Integer = Any
	
	Dim e As Long = 0
	Do
		ConnectResult = connect(ClientSocket, Cast(LPSOCKADDR, pAddress->ai_addr), pAddress->ai_addrlen)
		e = WSAGetLastError()
		
		If ConnectResult = 0 Then
			Exit Do
		End If
		
		pAddress = pAddress->ai_next
		
	Loop Until pAddress = 0
	
	FreeAddrInfoW(pAddressList)
	
	If ConnectResult <> 0 Then
		
		closesocket(ClientSocket)
		Return HRESULT_FROM_WIN32(e)
		
	End If
	
	*pSocket = ClientSocket
	Return S_OK
	
End Function
