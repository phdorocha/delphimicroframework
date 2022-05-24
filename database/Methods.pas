unit Methods;

interface

uses
  System.SysUtils;

function IfThen(AValue: Boolean; const ATrue: string;
  AFalse: string = ''): string; overload; inline;

function IsEmpty(Str: String = ''): Boolean;

function VarIsBoolean(const V: Variant): Boolean;

implementation

uses
  System.Variants;

function IfThen(AValue: Boolean; const ATrue: string;
  AFalse: string = ''): string;
begin
  if AValue then
    Result := ATrue
  else
    Result := AFalse;
end;

function IsEmpty(Str: String = ''): Boolean;
begin
  Result := Str = EmptyStr;
end;

function VarIsBoolean(const V: Variant): Boolean;
begin
  Result := varIsType(v, varBoolean);
end;

end.
