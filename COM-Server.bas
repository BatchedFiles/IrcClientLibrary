#include once "COM-Server.bi"

Common Shared GlobalObjectsCount As Long
Common Shared GlobalClassFactoryCount As Long

Dim Shared DllModuleHandle As HMODULE

#ifdef withoutrtl
Function DllMain Alias "DllMain"(ByVal hinstDLL As HINSTANCE, ByVal fdwReason As DWORD, ByVal lpvReserved As LPVOID)As Integer Export
	Select Case fdwReason
		
		Case DLL_PROCESS_ATTACH
			' Initialize once for each new process.
			' Return FALSE to fail DLL load.
			DllModuleHandle = hinstDLL
			
		Case DLL_THREAD_ATTACH
			' Do thread-specific initialization.
			
		Case DLL_THREAD_DETACH
			' Do thread-specific cleanup.
			
		Case DLL_PROCESS_DETACH
			' Perform any necessary cleanup.
			
	End Select
	
 	Return True
End Function
#endif

Function DllGetClassObject Alias "DllGetClassObject"(ByVal rclsid As REFCLSID, ByVal riid As REFIID, ByVal ppv As Any Ptr Ptr)As HRESULT Export
	
	*ppv = 0
	
	If IsEqualIID(@IID_IIrcClient, rclsid) = 0 Then
		Return CLASS_E_CLASSNOTAVAILABLE
	End If
	
	Dim pClassFactory As ClassFactory Ptr = ConstructorClassFactory()
	If pClassFactory = 0 Then
		Return E_OUTOFMEMORY
	End If
	
	Dim hr As HRESULT = pClassFactory->VirtualTable->QueryInterface(CPtr(IClassFactory Ptr, pClassFactory), riid, ppv)
	
	If FAILED(hr) Then
		DestructorClassFactory(pClassFactory)
	End If
	
	Return hr
	
End Function

Function DllCanUnloadNow Alias "DllCanUnloadNow"()As HRESULT Export
	If GlobalObjectsCount = 0 AndAlso GlobalClassFactoryCount = 0 Then
		Return S_OK
	End If
	
	Return S_FALSE
End Function

Function DllRegisterServer Alias "DllRegisterServer"()As HRESULT Export
	/'
	Dim lv_temp_str As ZString*2048
	Dim lv_varstr As ZString*2048


	CREATEREGSTRING(HKEY_CLASSES_ROOT,ProgID_POINT,NULL,ProgID_POINT)
	CREATEREGSTRING(HKEY_CLASSES_ROOT,ProgID_POINT & "\CLSID",NULL,CLSIDS_POINT)
	' prepare entery for HKEY_CLASSES_ROOT
	lv_varstr = ProgID_POINT
	lv_temp_str = "CLSID\" & CLSIDS_POINT
	CREATEREGSTRING(HKEY_CLASSES_ROOT,lv_temp_str,NULL,lv_varstr)
	CREATEREGSTRING(HKEY_CLASSES_ROOT,lv_temp_str,"AppID",CLSIDS_POINT) ' aa
	' define localtion of dll in system32
	lv_temp_str = "CLSID\" & CLSIDS_POINT & "\InprocServer32"

	lv_varstr = SPACE$(1024)
	GetModuleFileName(GetModuleHandle(MY_DLL_NAME),lv_varstr,Len(lv_varstr))

	lv_varstr = TRIM$(lv_varstr)
	CREATEREGSTRING(HKEY_CLASSES_ROOT,lv_temp_str,NULL,lv_varstr)


	lv_temp_str = TRIM$(REGSTRING(HKEY_CLASSES_ROOT,lv_temp_str,NULL))

	If lv_temp_str <> lv_varstr Then ' VERIFY THAT CORRECT VALUE IS WRITTEN IN REGISTRY
		Return  S_FALSE
	End If

	lv_temp_str = "CLSID\" & CLSIDS_POINT & "\ProgID"
	CREATEREGSTRING(HKEY_CLASSES_ROOT,lv_temp_str,NULL,ProgID_POINT)

	Return  S_OK
'/
	Return E_UNEXPECTED
End Function

Function DllUnregisterServer Alias "DllUnregisterServer"() As HRESULT Export
	/'
	Dim lv_temp_str As ZString*2048
	
	RegDeleteKey(HKEY_CLASSES_ROOT, ProgID_IrcClient & "\CLSID")
	
	RegDeleteKey(HKEY_CLASSES_ROOT, "\" & ProgID_IrcClient)




	'''''''''''''
	lv_temp_str  = "CLSID\" & CLSIDS_IrcClient & "\InprocServer32"
	RegDeleteKey(HKEY_CLASSES_ROOT,lv_temp_str)

	lv_temp_str = "CLSID\" & CLSIDS_IrcClient & "\ProgID"
	RegDeleteKey(HKEY_CLASSES_ROOT,lv_temp_str)

	lv_temp_str = "CLSID\" & CLSIDS_IrcClient
	RegDeleteKey(HKEY_CLASSES_ROOT,lv_temp_str)
	
	Return S_OK
'/
	Return E_UNEXPECTED
End Function
