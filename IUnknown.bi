#ifndef unicode
#define unicode
#endif

#include once "windows.bi"

Dim Shared IID_IUnknown As IID = Type(&h00000000, &h0000, &h0000, {&hC0, &h00, &h00, &h00, &h00, &h00, &h00, &h46})

Type IUnknown As IUnknown_

Type IUnknownVirtualTable
	Dim QueryInterface As Function(ByVal This As IUnknown Ptr, ByVal riid As REFIID, ByVal ppv As Any Ptr Ptr)As HRESULT
	Dim AddRef As Function(ByVal This As IUnknown Ptr)As ULONG
	Dim Release As Function(ByVal obj As IUnknown Ptr)As ULONG
End Type

Type IUnknown_
	Dim VirtualTable As IUnknownVirtualTable Ptr
End Type
