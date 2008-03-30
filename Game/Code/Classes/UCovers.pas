unit UCovers;

interface

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{$I switches.inc}

uses OpenGL12,
     {$IFDEF win32}
     windows,
     {$ENDIF}
     Math,
     Classes,
     SysUtils,
     {$IFNDEF FPC}
     Graphics,
     {$ENDIF}
     UThemes,
     UTexture;

type
  TCover = record
    Name:       string;
    W:          word;
    H:          word;
    Size:       integer;
    Position:   integer; // position of picture in the cache file
//    Data:       array of byte;
  end;

  TCovers = class
    private
      Filename:   String;



      WritetoFile: Boolean;
    public
      W:          word;
      H:          word;
      Size:       integer;
      Data:       array of byte;
      Cover:      array of TCover;

      constructor Create;
      procedure Load;
      procedure Save;
      Function AddCover(FileName: string): Integer;    //Returns ID, Checks Cover for Change, Updates Cover if required
      function CoverExists(FileName: string): boolean;
      function CoverNumber(FileName: string): integer; //Returns ID by FilePath
      procedure PrepareData(FileName: string);
      Procedure LoadTextures;
  end;

var
  Covers:     TCovers;
 // to - do : new Song management
implementation

uses UMain,
     // UFiles,
     ULog,
     DateUtils;

constructor TCovers.Create;
begin
  W := 128;
  H := 128;
  Size := W*H*3;
  Load;
  WritetoFile := True;
end;

procedure TCovers.Load;
var
  F:      File;
  C:      integer; // cover number
  W:      word;
  H:      word;
  Bits:   byte;
  NLen:   word;
  Name:   string;
//  Data:   array of byte;
begin
  if FileExists(GamePath + 'covers.cache') then
  begin
    AssignFile(F, GamePath + 'covers.cache');
    Reset(F, 1);

    WritetoFile := not FileIsReadOnly(GamePath + 'covers.cache');

    SetLength(Cover, 0);

    while not EOF(F) do
    begin
      SetLength(Cover, Length(Cover)+1);

      BlockRead(F, W, 2);
      Cover[High(Cover)].W := W;

      BlockRead(F, H, 2);
      Cover[High(Cover)].H := H;

      BlockRead(F, Bits, 1);

      Cover[High(Cover)].Size := W * H * (Bits div 8);

      // test
  //    W := 128;
  //    H := 128;
  //    Bits := 24;
  //    Seek(F, FilePos(F) + 3);

      BlockRead(F, NLen, 2);
      SetLength(Name, NLen);

      BlockRead(F, Name[1], NLen);
      Cover[High(Cover)].Name := Name;

      Cover[High(Cover)].Position := FilePos(F);
      Seek(F, FilePos(F) + W*H*(Bits div 8));

  //    SetLength(Cover[High(Cover)].Data, W*H*(Bits div 8));
  //    BlockRead(F, Cover[High(Cover)].Data[0], W*H*(Bits div 8));

    end; // While

    CloseFile(F);
  end; // fileexists
end;

procedure TCovers.Save;
var
  F:      File;
  C:      integer; // cover number
  W:      word;
  H:      word;
  NLen:   word;
  Bits:   byte;
begin
{  AssignFile(F, GamePath + 'covers.cache');
  Rewrite(F, 1);

  Bits := 24;
  for C := 0 to High(Cover) do begin
    W := Cover[C].W;
    H := Cover[C].H;

    BlockWrite(F, W, 2);
    BlockWrite(F, H, 2);
    BlockWrite(F, Bits, 1);

    NLen := Length(Cover[C].Name);
    BlockWrite(F, NLen, 2);
    BlockWrite(F, Cover[C].Name[1], NLen);
    BlockWrite(F, Cover[C].Data[0], W*H*(Bits div 8));
  end;

  CloseFile(F);}
end;

Function TCovers.AddCover(FileName: string): Integer;
var
  B:      integer;
  F:      File;
  C:      integer; // cover number
  NLen:   word;
  Bits:   byte;
begin
  if not CoverExists(FileName) then
  begin
    SetLength(Cover, Length(Cover)+1);
    Cover[High(Cover)].Name := FileName;

    Cover[High(Cover)].W := W;
    Cover[High(Cover)].H := H;
    Cover[High(Cover)].Size := Size;

    // do not copy data. write them directly to file
//    SetLength(Cover[High(Cover)].Data, Size);
//    for B := 0 to Size-1 do
//      Cover[High(Cover)].Data[B] := CacheMipmap[B];

    if WritetoFile then
    begin
      AssignFile(F, GamePath + 'covers.cache');
      
      if FileExists(GamePath + 'covers.cache') then
      begin
        Reset(F, 1);
        Seek(F, FileSize(F));
      end
      else
      begin
        Rewrite(F, 1);
      end;

      Bits := 24;

      BlockWrite(F, W, 2);
      BlockWrite(F, H, 2);
      BlockWrite(F, Bits, 1);

      NLen := Length(FileName);
      BlockWrite(F, NLen, 2);
      BlockWrite(F, FileName[1], NLen);

      Cover[High(Cover)].Position := FilePos(F);
      BlockWrite(F, CacheMipmap[0], W*H*(Bits div 8));

      CloseFile(F);
    end;
  end
  else
    Cover[High(Cover)].Position := 0;
end;

function TCovers.CoverExists(FileName: string): boolean;
var
  C:    integer; // cover
begin
  Result := false;
  C      := 0;
  
  while (C <= High(Cover)) and (Result = false) do
  begin
    if Cover[C].Name = FileName then
      Result := true;
      
    Inc(C);
  end;
end;

function TCovers.CoverNumber(FileName: string): integer;
var
  C:    integer;
begin
  Result := -1;
  C      := 0;
  
  while (C <= High(Cover)) and (Result = -1) do
  begin
    if Cover[C].Name = FileName then
      Result := C;
      
    Inc(C);
  end;
end;

procedure TCovers.PrepareData(FileName: string);
var
  F:  File;
  C:  integer;
begin
  if FileExists(GamePath + 'covers.cache') then
  begin
    AssignFile(F, GamePath + 'covers.cache');
    Reset(F, 1);

    C := CoverNumber(FileName);
    SetLength(Data, Cover[C].Size);
    if Length(Data) < 6 then beep;
    Seek(F, Cover[C].Position);
    BlockRead(F, Data[0], Cover[C].Size);
    CloseFile(F);
  end;
end;

Procedure TCovers.LoadTextures;
begin

end;

end.
