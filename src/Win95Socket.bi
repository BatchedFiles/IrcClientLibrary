#ifndef WIN95SOCKET_BI
#define WIN95SOCKET_BI

#include once "windows.bi"

Type Win95Socket As _Win95Socket

Type Win95AsyncResult As _Win95AsyncResult

Type OnConnect As Sub( _
	ByVal lpParameter As Any Ptr, _
	ByVal dwError As DWORD _
)
Type OnDisconnect As Sub( _
	ByVal lpParameter As Any Ptr _
)
Type OnReceiveData As Sub( _
	ByVal lpParameter As Any Ptr, _
	ByVal cbTransferred As DWORD, _
	ByVal dwError As DWORD _
)
Type OnWriteData As Sub( _
	ByVal lpParameter As Any Ptr, _
	ByVal cbTransferred As DWORD, _
	ByVal dwError As DWORD _
)

Declare Function CreateWin95Socket( _
) As Win95Socket Ptr

Declare Sub DestroyWin95Socket( _
	ByVal pSock As Win95Socket Ptr _
)

Declare Function Win95SocketBeginRead( _
	ByVal pSock As Win95Socket Ptr, _
	ByVal lpContext As Any Ptr, _
	ByVal Buffer As Any Ptr, _
	ByVal Count As DWORD, _
	ByVal pCB As OnReceiveData, _
	ByVal ppState As Win95AsyncResult Ptr Ptr _
)As HRESULT

Declare Function Win95SocketEndRead( _
	ByVal pSock As Win95Socket Ptr, _
	ByVal pState As Win95AsyncResult Ptr, _
	ByVal pReadedBytes As DWORD Ptr _
)As HRESULT

Declare Function Win95SocketBeginWrite( _
	ByVal pSock As Win95Socket Ptr, _
	ByVal lpContext As Any Ptr, _
	ByVal Buffer As Any Ptr, _
	ByVal Count As DWORD, _
	ByVal pCB As OnWriteData, _
	ByVal ppState As Win95AsyncResult Ptr Ptr _
)As HRESULT

Declare Function Win95SocketEndWrite( _
	ByVal pSock As Win95Socket Ptr, _
	ByVal pState As Win95AsyncResult Ptr, _
	ByVal pWritedBytes As DWORD Ptr _
)As HRESULT

Declare Function Win95SocketBeginConnect( _
	ByVal pSock As Win95Socket Ptr, _
	ByVal lpContext As Any Ptr, _
	ByVal LocalAddress As LPCWSTR, _
	ByVal LocalPort As LPCWSTR, _
	ByVal RemoteAddress As LPCWSTR, _
	ByVal RemotePort As LPCWSTR, _
	ByVal pCB As OnConnect, _
	ByVal ppState As Win95AsyncResult Ptr Ptr _
)As HRESULT

Declare Function Win95SocketEndConnect( _
	ByVal pSock As Win95Socket Ptr _
)As HRESULT

Declare Sub Win95SocketCloseConnection( _
	ByVal pSock As Win95Socket Ptr _
)

Declare Function Win95SocketMainLoop( _
	ByVal pSock As Win95Socket Ptr _
)As HRESULT

#endif
