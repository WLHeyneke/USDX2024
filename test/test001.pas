program test001;

{
This program test the function glext_ExtensionSupported from unit glext.
}

uses
  SysUtils,
  SDL          in '../src/lib/JEDI-SDL/SDL/Pas/sdl.pas',
  moduleloader in '../src/lib/JEDI-SDL/SDL/Pas/moduleloader.pas',
  gl           in '../src/lib/JEDI-SDL/OpenGL/Pas/gl.pas',
  glext        in '../src/lib/JEDI-SDL/OpenGL/Pas/glext.pas';

const
  s1:  pchar = '';
  s2:  pchar = 'ext';
  s3:  pchar = ' ext';
  s4:  pchar = ' ext ';
  s5:  pchar = 'kkshf kjsfh ext';
  s6:  pchar = 'fakh sajhf ext jskdhf';
  s7:  pchar = 'ext jshf';
  s8:  pchar = 'sdkjfh ksjhext sjdha';
  s9:  pchar = 'sdkjfh ksjh extsjdha';
  s10: pchar = 'sdkjfh ksjhextsjdha';
  s11: pchar = 'sd kjf jdha';

  e1: pchar = '';
  e2: pchar = 'ext';
  e3: pchar = 'GL_ARB_window_pos';

  SCREEN_WIDTH  = 640;
  SCREEN_HEIGHT = 480;
  SCREEN_BPP    =  16;

var
  surface:    PSDL_Surface;
  videoFlags: integer;
  testFailed: boolean;

begin
  write ('test001: Start ... ');
  testFailed := false;

// initialize SDL and OpenGL for the use of glGetString(GL_EXTENSIONS)
// within glext_ExtensionSupported.

  SDL_Init( SDL_INIT_VIDEO);

// the flags to pass to SDL_SetVideoMode
  videoFlags := SDL_OPENGL;

// get a SDL surface
  surface := SDL_SetVideoMode(SCREEN_WIDTH, SCREEN_HEIGHT, SCREEN_BPP, videoFlags);

// Initialization finished

  if     glext_ExtensionSupported(e1, s1)  then begin writeln; write ('test001, 1: failed');  testFailed := true; end;
  if     glext_ExtensionSupported(e1, s2)  then begin writeln; write ('test001, 2: failed');  testFailed := true; end;
  if     glext_ExtensionSupported(e2, s1)  then begin writeln; write ('test001, 3: failed');  testFailed := true; end;
  if not glext_ExtensionSupported(e2, s2)  then begin writeln; write ('test001, 4: failed');  testFailed := true; end;
  if not glext_ExtensionSupported(e2, s3)  then begin writeln; write ('test001, 5: failed');  testFailed := true; end;
  if not glext_ExtensionSupported(e2, s4)  then begin writeln; write ('test001, 6: failed');  testFailed := true; end;
  if not glext_ExtensionSupported(e2, s5)  then begin writeln; write ('test001, 7: failed');  testFailed := true; end;
  if not glext_ExtensionSupported(e2, s6)  then begin writeln; write ('test001, 8: failed');  testFailed := true; end;
  if not glext_ExtensionSupported(e2, s7)  then begin writeln; write ('test001, 9: failed');  testFailed := true; end;
  if     glext_ExtensionSupported(e2, s8)  then begin writeln; write ('test001, 10: failed'); testFailed := true; end;
  if     glext_ExtensionSupported(e2, s9)  then begin writeln; write ('test001, 11: failed'); testFailed := true; end;
  if     glext_ExtensionSupported(e2, s10) then begin writeln; write ('test001, 12: failed'); testFailed := true; end;
  if     glext_ExtensionSupported(e2, s11) then begin writeln; write ('test001, 13: failed'); testFailed := true; end;
  if not glext_ExtensionSupported(e3, s1)  then begin writeln; write ('test001, 14: failed'); testFailed := true; end;

  if testFailed then
  begin
    writeln;
    writeln ('test001: End');
  end
  else
    writeln ('End');
end.