' HACK for Win95
#ifdef Allocate
#undef Allocate
#endif
#ifdef Deallocate
#undef Deallocate
#endif
#ifdef RtlCopyMemory
#undef RtlCopyMemory
#endif
#ifdef RtlMoveMemory
#undef RtlMoveMemory
#endif
#ifdef RtlZeroMemory
#undef RtlZeroMemory
#endif
#ifdef CopyMemory
#undef CopyMemory
#endif
#ifdef MoveMemory
#undef MoveMemory
#endif
#ifdef ZeroMemory
#undef ZeroMemory
#endif

Declare Sub RtlCopyMemory Alias "RtlCopyMemory"( _
	ByVal Destination As Any Ptr, _
	ByVal Source As Const Any Ptr, _
	ByVal Length As Integer _
)
Declare Sub RtlMoveMemory Alias "RtlMoveMemory"( _
	ByVal Destination As Any Ptr, _
	ByVal Source As Const Any Ptr, _
	ByVal Length As Integer _
)
Declare Sub RtlZeroMemory Alias "RtlZeroMemory"( _
	ByVal Destination As Any Ptr, _
	ByVal Length As Integer _
)
#define Allocate(dwBytes) HeapAlloc(GetProcessHeap(), 0, (dwBytes))
#define Deallocate(lpMem) HeapFree(GetProcessHeap(), 0, (lpMem))
#define CopyMemory(d, s, l) RtlCopyMemory((d), (s), (l))
#define MoveMemory(d, s, l) RtlMoveMemory((d), (s), (l))
#define ZeroMemory(d, l) RtlZeroMemory((d), (l))
