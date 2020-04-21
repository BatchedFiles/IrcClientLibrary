#ifndef BATCHEDFILES_IRCCLIENT_APPENDINGBUFFER_BI
#define BATCHEDFILES_IRCCLIENT_APPENDINGBUFFER_BI

Type AppendingBuffer
	Dim Buffer As WString Ptr
	Dim BufferLength As Integer
	
	Declare Constructor(ByVal pBuffer As WString Ptr, ByVal BufferLength As Integer)
	
	Declare Sub AppendWLine()
	Declare Sub AppendWLine(ByVal w As WString Ptr)
	Declare Sub AppendWLine(ByVal w As WString Ptr, ByVal Length As Integer)
	Declare Sub AppendWString(ByVal w As WString Ptr)
	Declare Sub AppendWString(ByVal w As WString Ptr, ByVal Length As Integer)
	Declare Sub AppendWChar(ByVal wc As Integer)
End Type

#endif
