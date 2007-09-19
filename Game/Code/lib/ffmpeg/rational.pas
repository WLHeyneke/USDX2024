(*
 * Rational numbers
 * Copyright (c) 2003 Michael Niedermayer <michaelni@gmx.at>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 *)
unit rational;

interface

{$IFDEF win32}
uses
  windows;
{$endif}

const

  {$IFDEF win32}
    av__util = 'avutil-49.dll';
  {$ELSE}
    av__util = 'libavutil.so';  // .0d
  {$ENDIF}


type

(*
 * Rational number num/den. *)
  PAVRational = ^TAVRational;
  TAVRational = record
    num: integer; ///< numerator
    den: integer; ///< denominator
  end;

(**
 * returns 0 if a==b, 1 if a>b and -1 if a<b.
 *)
function av_cmp_q(a: TAVRational; b: TAVRational): integer;

(**
 * converts the given AVRational to a double.
 *)
function av_q2d(a: TAVRational): double;

(**
 * reduce a fraction.
 * this is usefull for framerate calculations
 * @param max the maximum allowed for dst_nom & dst_den
 * @return 1 if exact, 0 otherwise
 *)
function av_reduce(dst_nom: pinteger; dst_den: PInteger; nom: int64; den: int64; max: int64): integer;
  cdecl; external av__util;

function av_mul_q(b: TAVRational; c: TAVRational): TAVRational;
  cdecl; external av__util;
function av_div_q(b: TAVRational; c: TAVRational): TAVRational;
  cdecl; external av__util;
function av_add_q(b: TAVRational; c: TAVRational): TAVRational;
  cdecl; external av__util;
function av_sub_q(b: TAVRational; c: TAVRational): TAVRational;
  cdecl; external av__util;
function av_d2q(d: double; max: integer): TAVRational;
  cdecl; external av__util;

implementation

function av_cmp_q (a: TAVRational; b: TAVRational): integer;
var
  tmp: int64;
begin
  tmp := a.num * b.den - b.num * a.den;

  if tmp = 0 then
    Result := (tmp shr 63) or 1
  else
    Result := 0;
end;

function av_q2d(a: TAVRational): double;
begin
  Result := a.num / a.den;
end;

end.
