set CompilerDirectory=%ProgramFiles%\FreeBASIC

set MainFile=
set Classes=
set Forms=
set Modules=IrcClient.bas SendData.bas ReceiveData.bas ParseData.bas GetIrcData.bas SendMessages.bas Network.bas AppendingBuffer.bas
set References=
set Resources=

set OutputFile=libBatchedFilesIrcClient.a

set IncludeFilesPath=-i Classes -i Forms -i Headers -i Interfaces -i Modules
set IncludeLibraries=
set ExeTypeKind=lib

set MaxErrorsCount=-maxerr 1
set MinWarningLevel=-w all
REM set UseThreadSafeRuntime=-mt

REM set EnableShowIncludes=-showincludes
set EnableVerbose=-v
REM set EnableRuntimeErrorChecking=-e
REM set EnableFunctionProfiling=-profile

if "%1"=="service" (
	set SERVICE_DEFINED=-d WINDOWS_SERVICE
) else (
	set SERVICE_DEFINED=
	set PERFORMANCE_TESTING_DEFINED=-d PERFORMANCE_TESTING
)

if "%2"=="debug" (
	set EnableDebug=debug
	set OptimizationLevel=-O 0
	set VectorizationLevel=-vec 0
) else (
	set EnableDebug=release
	set OptimizationLevel=-O 3
	set VectorizationLevel=-vec 0
)

if "%3"=="withoutruntime" (
	set WithoutRuntime=withoutruntime
	set GUIDS_WITHOUT_MINGW=-d GUIDS_WITHOUT_MINGW=1
) else (
	set WithoutRuntime=runtime
	set GUIDS_WITHOUT_MINGW=
)

set CompilerParameters=%SERVICE_DEFINED% %PERFORMANCE_TESTING_DEFINED% %GUIDS_WITHOUT_MINGW% %MaxErrorsCount% %UseThreadSafeRuntime% %MinWarningLevel% %EnableFunctionProfiling% %EnableShowIncludes% %EnableVerbose% %EnableRuntimeErrorChecking% %IncludeFilesPath% %IncludeLibraries% %OptimizationLevel% %VectorizationLevel% 

call translator.cmd "%MainFile% %Classes% %Forms% %Modules% %Resources%" "%ExeTypeKind%" "%OutputFile%" "%CompilerDirectory%" "%CompilerParameters%" %EnableDebug% noprofile %WithoutRuntime%