unit UCommon;

interface

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{$I switches.inc}

uses
  SysUtils,
  Classes,
  {$IFDEF MSWINDOWS}
  Windows,
  Messages,
  {$ENDIF}
  ULog;

{$IFNDEF DARWIN}
// FIXME: remove this if it is not needed anymore
type
  hStream        = THandle;
  HGLRC          = THandle;
  TLargeInteger  = Int64;
  TWin32FindData = LongInt;
{$ENDIF}

function GetResourceStream(const aName, aType : string): TStream;

procedure ShowMessage( const msg : String );

{$IFDEF FPC}
function RandomRange(aMin: Integer; aMax: Integer) : Integer;
{$ENDIF}

{$IF Defined(MSWINDOWS) and Defined(FPC)}
function  AllocateHWnd(Method: TWndMethod): HWND;
procedure DeallocateHWnd(hWnd: HWND);
{$IFEND}

function StringReplaceW(text : WideString; search, rep: WideChar):WideString;
function AdaptFilePaths( const aPath : widestring ): widestring;

procedure DisableFloatingPointExceptions();
procedure SetDefaultNumericLocale();
procedure RestoreNumericLocale();

{$IFNDEF win32}
  procedure ZeroMemory( Destination: Pointer; Length: DWORD );
{$ENDIF}

function FileExistsInsensitive(var FileName: string): boolean;

(*
 * Character classes
 *)

function IsAlphaChar(ch: WideChar): boolean;
function IsNumericChar(ch: WideChar): boolean;
function IsAlphaNumericChar(ch: WideChar): boolean;
function IsPunctuationChar(ch: WideChar): boolean;
function IsControlChar(ch: WideChar): boolean;


implementation

uses
  Math,
  {$IFDEF Delphi}
  Dialogs,
  {$ENDIF}
  {$IFDEF LINUX}
  libc,
  {$ENDIF}
  UMain,
  UConfig;

var
  PrevNumLocale: string;

// In Linux and maybe MacOSX some units (like cwstring) call setlocale(LC_ALL, '')
// to set the language/country specific locale (e.g. charset) for this application.
// Unfortunately, LC_NUMERIC is set by this call too.
// It defines the decimal-separator and other country-specific numeric settings.
// This parameter is used by the C string-to-float parsing functions atof() and strtod().
// After changing LC_NUMERIC some external C-based libs (like projectM) are not
// able to parse strings correctly
// (e.g. in Germany "0.9" is not recognized as a valid number anymore but "0,9" is).
// So we reset the numeric settings to the default ('C').
// Note: The behaviour of Pascal parsing functions (e.g. strtofloat()) is not
//   changed by this because it doesn't use the locale-settings.
// TODO:
// - Check if this is needed in MacOSX (at least the locale is set in cwstring)
// - Find out which libs are concerned by this problem.
//   If only projectM is concerned by this problem set and restore the numeric locale
//   for each call to projectM instead of changing it globally.
procedure SetDefaultNumericLocale();
begin
  {$ifdef LINUX}
  PrevNumLocale := setlocale(LC_NUMERIC, nil);
  setlocale(LC_NUMERIC, 'C');
  {$endif}
end;

procedure RestoreNumericLocale();
begin
  {$ifdef LINUX}
  setlocale(LC_NUMERIC, PChar(PrevNumLocale));
  {$endif}
end;

(*
 * If an invalid floating point operation was performed the Floating-point unit (FPU)
 * generates a Floating-point exception (FPE). Dependending on the settings in
 * the FPU's control-register (interrupt mask) the FPE is handled by the FPU itself
 * (we will call this as "FPE disabled" later on) or is passed to the application
 * (FPE enabled).
 * If FPEs are enabled a floating-point division by zero (e.g. 10.0 / 0.0) is
 * considered an error and an exception is thrown. Otherwise the FPU will handle
 * the error and return the result infinity (INF) (10.0 / 0.0 = INF) without
 * throwing an error to the application.
 * The same applies to a division by INF that either raises an exception
 * (FPE enabled) or returns 0.0 (FPE disabled).
 * Normally (as with C-programs), Floating-point exceptions (FPE) are DISABLED
 * on program startup (at least with Intel CPUs), but for some strange reasons
 * they are ENABLED in pascal (both delphi and FPC) by default.
 * Many libs operating with floating-point values rely heavily on the C-specific
 * behaviour. So using them in delphi is a ticking time-bomb because sooner or
 * later they will crash because of an FPE (this problem occurs massively
 * in OpenGL-based libs like projectM). In contrast to this no error will occur
 * if the lib is linked to a C-program.
 *
 * Further info on FPUs:
 * For x86 and x86_64 CPUs we have to consider two FPU instruction sets.
 * The math co-processor i387 (aka 8087 or x87) set introduced with the i386
 * and SSE (Streaming SIMD Extensions) introduced with the Pentium3.
 * Both of them have separate control-registers (x87: FPUControlWord, SSE: MXCSR)
 * to control FPEs. Either has (among others) 6bits to enable/disable several
 * exception types (Invalid,Denormalized,Zero,Overflow,Underflow,Precision).
 * Those exception-types must all be masked (=1) to get the default C behaviour.
 * The control-registers can be set with the asm-ops FLDCW (x87) and LDMXCSR (SSE).
 * Instead of using assembler code, we can use Set8087CW() provided by delphi and
 * FPC to set the x87 control-word. FPC also provides SetSSECSR() for SSE's MXCSR.
 * Note that both Delphi and FPC enable FPEs (e.g. for div-by-zero) on program
 * startup but only FPC enables FPEs (especially div-by-zero) for SSE too.
 * So we have to mask FPEs for x87  in Delphi and FPC and for SSE in FPC only.
 * FPC and Delphi both provide a SetExceptionMask() for control of the FPE
 * mask. SetExceptionMask() sets the masks for x87 in Delphi and for x87 and SSE
 * in FPC (seems as if Delphi [2005] is not SSE aware). So SetExceptionMask()
 * is what we need and it even is plattform and CPU independent.
 *
 * Pascal OpenGL headers (like the Delphi standard ones or JEDI-SDL headers)
 * already call Set8087CW() to disable FPEs but due to some bugs in the JEDI-SDL
 * headers they do not work properly with FPC. I already patched them, so they
 * work at least until they are updated the next time. In addition Set8086CW()
 * does not suffice to disable FPEs because the SSE FPEs are not disabled by this.
 * FPEs with SSE are a big problem with some libs because many linux distributions
 * optimize code for SSE or Pentium3 (for example: int(INF) which convert the
 * double value "infinity" to an integer might be automatically optimized by
 * using SSE's CVTSD2SI instruction). So SSE FPEs must be turned off in any case
 * to make USDX portable.
 *
 * Summary:
 * Call this function on initialization to make sure FPEs are turned off.
 * It will solve a lot of errors with FPEs in external libs.
 *)
procedure DisableFloatingPointExceptions();
begin
  (*
  // We will use SetExceptionMask() instead of Set8087CW()/SetSSECSR().
  // Note: Leave these lines for documentation purposes just in case
  //       SetExceptionMask() does not work anymore (due to bugs in FPC etc.).
  {$IF Defined(CPU386) or Defined(CPUI386) or Defined(CPUX86_64)}
  Set8087CW($133F);
  {$IFEND}
  {$IF Defined(FPC)}
  if (has_sse_support) then
    SetSSECSR($1F80);
  {$IFEND}
  *)
  
  // disable all of the six FPEs (x87 and SSE) to be compatible with C/C++ and
  // other libs which rely on the standard FPU behaviour (no div-by-zero FPE anymore).
  SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide,
                    exOverflow, exUnderflow, exPrecision]);
end;

function StringReplaceW(text : WideString; search, rep: WideChar):WideString;
var
  iPos  : integer;
//  sTemp : WideString;
begin
(*
  result := text;
  iPos   := Pos(search, result);
  while (iPos > 0) do
  begin
    sTemp  := copy(result, iPos + length(search), length(result));
    result := copy(result, 1, iPos - 1) + rep + sTEmp;
    iPos   := Pos(search, result);
  end;
*)
  result := text;

  if search = rep then
    exit;

  for iPos := 0 to length( result ) - 1 do
  begin
    if result[ iPos ] = search then
      result[ iPos ] := rep;
  end;
end;

function AdaptFilePaths( const aPath : widestring ): widestring;
begin
  result := StringReplaceW( aPath, '\', PathDelim );//, [rfReplaceAll] );
end;


{$IFNDEF win32}
procedure ZeroMemory( Destination: Pointer; Length: DWORD );
begin
  FillChar( Destination^, Length, 0 );
end; //ZeroMemory

(*
function QueryPerformanceCounter(lpPerformanceCount:TLARGEINTEGER):Bool;

  // From http://en.wikipedia.org/wiki/RDTSC
  function RDTSC: Int64; register;
  asm
    rdtsc
  end;

begin
  // Use clock_gettime  here maybe ... from libc
  lpPerformanceCount := RDTSC();
  result := true;
end;

function QueryPerformanceFrequency(lpFrequency:TLARGEINTEGER):Bool;
begin
  lpFrequency := 0;
  result := true;
end;
*)
{$ENDIF}

// Checks if a regular files or directory with the given name exists.
// The comparison is case insensitive.
function FileExistsInsensitive(var FileName: string): boolean;
var
  FilePath, LocalFileName: string;
  SearchInfo: TSearchRec;
begin
{$IFDEF LINUX} // eddie: Changed FPC to LINUX: Windows and Mac OS X dont have case sensitive file systems
  // speed up standard case
  if FileExists(FileName) then
  begin
    Result := true;
    exit;
  end;

  Result := false;

  FilePath := ExtractFilePath(FileName);
  if (FindFirst(FilePath+'*', faAnyFile, SearchInfo) = 0) then
  begin
    LocalFileName := ExtractFileName(FileName);
    repeat
      if (AnsiSameText(LocalFileName, SearchInfo.Name)) then
      begin
        FileName := FilePath + SearchInfo.Name;
        Result := true;
        break;
      end;
    until (FindNext(SearchInfo) <> 0);
  end;
  FindClose(SearchInfo);
{$ELSE}
  Result := FileExists(FileName);
{$ENDIF}
end;


{$IFDEF Linux}
  // include resource-file info (stored in the constant array "resources")
  {$I ../resource.inc}
{$ENDIF}

function GetResourceStream(const aName, aType: string): TStream;
{$IFDEF Linux}
var
  ResIndex: integer;
  Filename: string;
{$ENDIF}
begin
  Result := nil;

  {$IFDEF Linux}
  for ResIndex := 0 to High(resources) do
  begin
    if (resources[ResIndex][0] = aName ) and
       (resources[ResIndex][1] = aType ) then
    begin
      try
        Filename := ResourcesPath + resources[ResIndex][2];
        Result := TFileStream.Create(Filename, fmOpenRead);
      except
        Log.LogError('Failed to open: "'+ resources[ResIndex][2] +'"', 'GetResourceStream');
      end;
      exit;
    end;
  end;
  {$ELSE}
  try
    Result := TResourceStream.Create(HInstance, aName , PChar(aType));
  except
    Log.LogError('Invalid resource: "'+ aType + ':' + aName +'"', 'GetResourceStream');
  end;
  {$ENDIF}
end;

{$IFDEF FPC}
function RandomRange(aMin: Integer; aMax: Integer) : Integer;
begin
  RandomRange := Random(aMax-aMin) + aMin ;
end;
{$ENDIF}

{$IF Defined(MSWINDOWS) and Defined(FPC)}
function AllocateHWndCallback(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
var
  Msg: TMessage;
  MethodPtr: ^TWndMethod;
begin
  FillChar(Msg, SizeOf(Msg), 0);  
  Msg.msg := uMsg;
  Msg.wParam := wParam;
  Msg.lParam := lParam;

  MethodPtr := Pointer(GetWindowLongPtr(hwnd, GWL_USERDATA));
  if Assigned(MethodPtr) then
    MethodPtr^(Msg);
   
  Result := DefWindowProc(hwnd, uMsg, wParam, lParam);
end;

function AllocateHWnd(Method: TWndMethod): HWND;
var
  ClassExists: Boolean;
  WndClass, OldClass: TWndClass;
  MethodPtr: ^TMethod;
begin
  Result := 0;

  // setup class-info
  FillChar(WndClass, SizeOf(TWndClass), 0);
  WndClass.hInstance := HInstance;
  // Important: do not enable AllocateHWndCallback before the msg-handler method is assigned,
  //   otherwise race-conditions might occur
  WndClass.lpfnWndProc := @DefWindowProc;
  WndClass.lpszClassName:= 'USDXUtilWindowClass';

  // check if class is already registered
  ClassExists := GetClassInfo(HInstance, WndClass.lpszClassName, OldClass);
  // create window-class shared by all windows created by AllocateHWnd()
  if (not ClassExists) or (@OldClass.lpfnWndProc <> @DefWindowProc) then
  begin
    if ClassExists then
      UnregisterClass(WndClass.lpszClassName, HInstance);
    if (RegisterClass(WndClass) = 0) then
       Exit;
  end;
  // create window
  Result := CreateWindowEx(WS_EX_TOOLWINDOW, WndClass.lpszClassName, '',
    WS_POPUP, 0, 0, 0, 0, 0, 0, HInstance, nil);
  if (Result = 0) then
    Exit;
  // assign individual callback procedure to the window
  if Assigned(Method) then
  begin
    // TMethod contains two pointers but we can pass just one as USERDATA
    GetMem(MethodPtr, SizeOf(TMethod));
    MethodPtr^ := TMethod(Method);
    SetWindowLongPtr(Result, GWL_USERDATA, LONG_PTR(MethodPtr));
  end;
  // now enable AllocateHWndCallback for this window
  SetWindowLongPtr(Result, GWL_WNDPROC, LONG_PTR(@AllocateHWndCallback));
end;

procedure DeallocateHWnd(hWnd: HWND);
var
  MethodPtr: ^TMethod;
begin
  if (hWnd <> 0) then
  begin
    MethodPtr := Pointer(GetWindowLongPtr(hWnd, GWL_USERDATA));
    DestroyWindow(hWnd);
    if Assigned(MethodPtr) then
      FreeMem(MethodPtr);
  end;
end;
{$IFEND}

procedure ShowMessage( const msg : String );
begin
{$IF Defined(MSWINDOWS)}
  MessageBox(0, PChar(msg), PChar(USDXVersionStr()), MB_ICONINFORMATION);
{$ELSE}
  debugwriteln(msg);
{$IFEND}
end;

function IsAlphaChar(ch: WideChar): boolean;
begin
  // TODO: add chars > 255 when unicode-fonts work?
  case ch of
    'A'..'Z',  // A-Z
    'a'..'z',  // a-z
    #170,#181,#186,
    #192..#214,
    #216..#246,
    #248..#255:
      Result := true;
    else
      Result := false;
  end;
end;

function IsNumericChar(ch: WideChar): boolean;
begin
  case ch of
    '0'..'9':
      Result := true;
    else
      Result := false;
  end;
end;

function IsAlphaNumericChar(ch: WideChar): boolean;
begin
  Result := (IsAlphaChar(ch) or IsNumericChar(ch));
end;

function IsPunctuationChar(ch: WideChar): boolean;
begin
  // TODO: add chars outside of Latin1 basic (0..127)?
  case ch of
    ' '..'/',':'..'@','['..'`','{'..'~':
      Result := true;
    else
      Result := false;
  end;
end;

function IsControlChar(ch: WideChar): boolean;
begin
  case ch of
    #0..#31,
    #127..#159:
      Result := true;
    else
      Result := false;
  end;
end;

end.
