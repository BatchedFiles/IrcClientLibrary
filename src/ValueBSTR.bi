#ifndef BATCHEDFILES_VALUEBSTR_BI
#define BATCHEDFILES_VALUEBSTR_BI

#include "windows.bi"
#include "win\ole2.bi"

#ifndef __FB_64BIT__
#define WStringPtrToValueBstrPtr(pWString) Cast(ValueBSTR Ptr, Cast(Byte Ptr, (pWString)) - SizeOf(UINT))
#else
#define WStringPtrToValueBstrPtr(pWString) Cast(ValueBSTR Ptr, Cast(Byte Ptr, (pWString)) - SizeOf(UINT) - SizeOf(DWORD))
#endif

'IRCPROTOCOL_BYTESPERMESSAGEMAXIMUM - Len(CrLf)
Const MAX_VALUEBSTR_BUFFER_LENGTH As Integer = 510

Type ValueBSTR As _ValueBSTR

Type LPVALUEBSTR As _ValueBSTR Ptr

Type _ValueBSTR
	
	#ifdef __FB_64BIT__
		Padding As DWORD
	#endif
	Dim BytesCount As UINT
	Dim WChars(0 To (MAX_VALUEBSTR_BUFFER_LENGTH + 1) - 1) As OLECHAR
	
	Declare Constructor()
	Declare Constructor(ByRef rhs As Const WString)
	Declare Constructor(ByRef rhs As Const WString, ByVal NewLength As Const Integer)
	Declare Constructor(ByRef rhs As Const ValueBSTR)
	Declare Constructor(ByRef rhs As Const BSTR)
	
	'Declare Destructor()
	
	Declare Operator Let(ByRef rhs As Const WString)
	Declare Operator Let(ByRef rhs As Const ValueBSTR)
	Declare Operator Let(ByRef rhs As Const BSTR)
	
	Declare Operator Cast()ByRef As Const WString
	Declare Operator Cast()As Const BSTR
	Declare Operator Cast()As Const Any Ptr
	
	Declare Operator &=(ByRef rhs As Const WString)
	Declare Operator &=(ByRef rhs As Const ValueBSTR)
	Declare Operator &=(ByRef rhs As Const BSTR)
	
	Declare Operator +=(ByRef rhs As Const WString)
	Declare Operator +=(ByRef rhs As Const ValueBSTR)
	Declare Operator +=(ByRef rhs As Const BSTR)
	
	Declare Sub Append(ByVal Ch As Const OLECHAR)
	Declare Sub Append(ByRef rhs As Const WString, ByVal rhsLength As Const Integer)
	
	Declare Function GetTrailingNullChar()As WString Ptr
	
	Declare Property Length(ByVal NewLength As Const Integer)
	Declare Property Length()As Const Integer
	
End Type

Declare Operator Len(ByRef lhs As Const ValueBSTR)As Integer

#endif
