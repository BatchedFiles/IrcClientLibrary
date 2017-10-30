#ifndef unicode
#define unicode
#endif

#include once "windows.bi"
#include once "win\objbase.bi"

Type ClassFactory
	Dim VirtualTable As IClassFactoryVtbl Ptr
	
	Dim ReferenceCounter As DWORD
	
End Type

Declare Function ConstructorClassFactory()As ClassFactory Ptr

Declare Sub DestructorClassFactory(ByVal pClassFactory As ClassFactory Ptr)

Declare Function ClassFactoryQueryInterface(ByVal This As ClassFactory Ptr, ByVal riid As REFIID, ByVal ppv As Any Ptr Ptr)As HRESULT

Declare Function ClassFactoryAddRef(ByVal This As ClassFactory Ptr)As ULONG

Declare Function ClassFactoryRelease(ByVal This As ClassFactory Ptr)As ULONG

Declare Function ClassFactoryCreateInstance(ByVal This As ClassFactory Ptr, ByVal pUnknownOuter As IUnknown Ptr, ByVal riid As REFIID, ByVal ppv As Any Ptr Ptr)As HRESULT

Declare Function ClassFactoryLockServer(ByVal This As ClassFactory Ptr, ByVal fLock As BOOL)As HRESULT
