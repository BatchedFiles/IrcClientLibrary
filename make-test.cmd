set CompilerDirectory=%ProgramFiles%\FreeBASIC

set MainFile=test\bot.bas
set Classes=
set Modules=
set Resources=
set OutputFile=test\bot.exe

set IncludeFilesPath=-i Classes -i Interfaces -i Modules -i Headers
set IncludeLibraries=-l BatchedFilesIrcClient
set ExeTypeKind=console

set MaxErrorsCount=-maxerr 1
set MinWarningLevel=-w all
set OptimizationLevel=-O 3
set VectorizationLevel=-vec 0
REM set UseThreadSafeRuntime=-mt

REM set EnableShowIncludes=-showincludes
REM set EnableVerbose=-v
REM set EnableRuntimeErrorChecking=-e
REM set EnableFunctionProfiling=-profile

if "%2"=="debug" (
	set EnableDebug=debug
) else (
	set EnableDebug=release
)

if "%3"=="withoutruntime" (
	set WithoutRuntime=withoutruntime
	set GUIDS_WITHOUT_MINGW=-d GUIDS_WITHOUT_MINGW=1
) else (
	set WithoutRuntime=runtime
)

set CompilerParameters=%GUIDS_WITHOUT_MINGW% %MaxErrorsCount% %UseThreadSafeRuntime% %IncludeLibraries% %IncludeFilesPath% %OptimizationLevel% %VectorizationLevel% %MinWarningLevel% %EnableFunctionProfiling% %EnableShowIncludes% %EnableVerbose% %EnableRuntimeErrorChecking%

call translator.cmd "%MainFile% %Classes% %Modules% %Resources%" "%ExeTypeKind%" "%OutputFile%" "%CompilerDirectory%" "%CompilerParameters%" %EnableDebug% noprofile %WithoutRuntime%