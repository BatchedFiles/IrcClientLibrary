#include "ValueBSTR.bi"

Constructor ValueBSTR()
	
	'Padding = 0
	BytesCount = 0
	WChars(0) = 0
	
End Constructor

Constructor ValueBSTR(ByRef lhs As Const WString)
	
	'Padding = 0
	Dim lhsLength As Integer = lstrlenW(lhs)
	Dim Chars As Integer = min(MAX_VALUEBSTR_BUFFER_LENGTH, lhsLength)
	
	BytesCount = Chars * SizeOf(OLECHAR)
	CopyMemory(@WChars(0), @lhs, BytesCount)
	WChars(Chars) = 0
	
End Constructor

Constructor ValueBSTR(ByRef lhs As Const WString, ByVal NewLength As Const Integer)
	
	'Padding = 0
	Dim Chars As Integer = min(MAX_VALUEBSTR_BUFFER_LENGTH, NewLength)
	
	BytesCount = Chars * SizeOf(OLECHAR)
	CopyMemory(@WChars(0), @lhs, BytesCount)
	WChars(Chars) = 0
	
End Constructor

Constructor ValueBSTR(ByRef lhs As Const ValueBSTR)
	
	'Padding = 0
	BytesCount = lhs.BytesCount
	CopyMemory(@WChars(0), @lhs.WChars(0), BytesCount + SizeOf(OLECHAR))
	
End Constructor

Constructor ValueBSTR(ByRef lhs As Const BSTR)
	
	'Padding = 0
	Dim lhsLength As Integer = CInt(SysStringLen(lhs))
	Dim Chars As Integer = min(MAX_VALUEBSTR_BUFFER_LENGTH, lhsLength)
	
	BytesCount = Chars * SizeOf(OLECHAR)
	CopyMemory(@WChars(0), lhs, BytesCount)
	WChars(Chars) = 0
	
End Constructor

Operator ValueBSTR.Let(ByRef lhs As Const WString)
	
	'Padding = 0
	Dim lhsLength As Integer = lstrlenW(lhs)
	Dim Chars As Integer = min(MAX_VALUEBSTR_BUFFER_LENGTH, lhsLength)
	
	BytesCount = Chars * SizeOf(OLECHAR)
	CopyMemory(@WChars(0), @lhs, BytesCount)
	WChars(Chars) = 0
	
End Operator

Operator ValueBSTR.Let(ByRef lhs As Const ValueBSTR)
	
	'Padding = 0
	BytesCount = lhs.BytesCount
	CopyMemory(@WChars(0), @lhs.WChars(0), BytesCount + SizeOf(OLECHAR))
	
End Operator

Operator ValueBSTR.Let(ByRef lhs As Const BSTR)
	
	'Padding = 0
	Dim lhsLength As Integer = CInt(SysStringLen(lhs))
	Dim Chars As Integer = min(MAX_VALUEBSTR_BUFFER_LENGTH, lhsLength)
	
	BytesCount = Chars * SizeOf(OLECHAR)
	CopyMemory(@WChars(0), lhs, BytesCount)
	WChars(Chars) = 0
	
End Operator

Operator ValueBSTR.Cast()ByRef As Const WString
	
	Return WChars(0)
	
End Operator

Operator ValueBSTR.Cast()As Const BSTR
	
	Return @WChars(0)
	
End Operator

Operator ValueBSTR.Cast()As Const Any Ptr
	
	Return CPtr(Any Ptr, @WChars(0))
	
End Operator

Operator ValueBSTR.&=(ByRef rhs As Const WString)
	
	Append(rhs, lstrlenW(rhs))
	
End Operator

' Declare Operator &=(ByRef rhs As Const ValueBSTR)

Operator ValueBSTR.&=(ByRef rhs As Const BSTR)
	Append(*CPtr(WString Ptr, rhs), SysStringLen(rhs))
End Operator

Operator ValueBSTR.+=(ByRef rhs As Const WString)
	
	Append(rhs, lstrlenW(rhs))
	
End Operator

' Declare Operator +=(ByRef rhs As Const ValueBSTR)
' Declare Operator +=(ByRef rhs As Const BSTR)

Sub ValueBSTR.Append(ByVal Ch As Const OLECHAR)
	Dim meLength As Integer = Len(this)
	Dim UnusedChars As Integer = MAX_VALUEBSTR_BUFFER_LENGTH - meLength
	
	If UnusedChars > 0 Then
		BytesCount += SizeOf(OLECHAR)
		WChars(meLength) = Ch
		WChars(meLength + 1) = 0
	End If
	
End Sub

Sub ValueBSTR.Append(ByRef rhs As Const WString, ByVal rhsLength As Const Integer)
	
	Dim meLength As Integer = Len(this)
	Dim UnusedChars As Integer = MAX_VALUEBSTR_BUFFER_LENGTH - meLength
	
	If UnusedChars > 0 Then
		
		Dim Chars As Integer = min(UnusedChars, rhsLength)
		
		BytesCount = (meLength + Chars) * SizeOf(OLECHAR)
		CopyMemory(@WChars(meLength), @rhs, Chars * SizeOf(OLECHAR))
		WChars(meLength + Chars) = 0
		
	End If

End Sub

Operator Len(ByRef b As Const ValueBSTR)As Integer
	
	' Return SysStringLen(b)
	Return b.BytesCount \ SizeOf(OLECHAR)
	
End Operator

Property ValueBSTR.Length(ByVal NewLength As Const Integer)
	Dim Chars As Integer = min(MAX_VALUEBSTR_BUFFER_LENGTH, NewLength)
	BytesCount = Chars * SizeOf(OLECHAR)
	WChars(Chars) = 0
End Property

Property ValueBSTR.Length()As Const Integer
	Return BytesCount \ SizeOf(OLECHAR)
End Property

Function ValueBSTR.GetTrailingNullChar()As WString Ptr
	Return CPtr(WString Ptr, @WChars(Len(this)))
End Function
