{******************************************************************************}
{                                                                              }
{    Código criado com base no: https://github.com/amarildolacerda/helpers     }
{    Créditos: Amarildo Lacerda                                                }
{                                                                              }
{                                                                              }
{******************************************************************************}


unit Easy.DB.Helper;

interface

uses
  System.Classes,
  System.SysUtils,
  Data.DB,
  System.JSON,
  Variants,
  Data.SqlTimSt,
  Data.FmtBcd,
  System.NetEncoding,
  System.Generics.Collections;

type
  TJSONArrayHelper = class Helper for TJSONArray
    function Paginate(const AOwnerPair: String; ALimit, APage: Integer): String;
  end;

  TFieldsHelper = class Helper for TFields
  private

  public
    function JsonObject(var pJsonObject: TJSONObject; const pIncludeNullFields: Boolean = True): Integer;
    function ToJson(const pIncludeNullFields: Boolean = True): string;
  end;

type
  TDatasetHelper = class helper for TDataset
    procedure FieldMask(fld: String; mask: string);
    procedure FieldTitle(AFld: string; ATitle: string);
    function FieldChanged(fld: string): boolean;

    function BeginUpdate(const pDisableControls: Boolean = True): TDataSet;
    function EndUpdate: TDataSet;
    procedure ToJsonArray(var pJsonArray: TJsonArray; const pIncludeNullFields: Boolean = False);
    function ToJsonString(const pIncludeNullFields: Boolean = False): string;
  end;

implementation

var
  BookmarkDictionary: TDictionary<TDataSet, TBookmark>;

{ TDatasetHelper }

function TDatasetHelper.BeginUpdate(const pDisableControls: Boolean): TDataSet;
begin
  Result := Self;
  if not(ControlsDisabled) and pDisableControls then
    DisableControls;
  if not IsEmpty then
    BookmarkDictionary.AddOrSetValue(Self, GetBookmark);
end;

function TDatasetHelper.EndUpdate: TDataSet;
begin
  Result := Self;
  try
    if not IsEmpty then
    begin
      if BookmarkDictionary.ContainsKey(Self) then
        if BookmarkValid(BookmarkDictionary.Items[Self]) then
          GotoBookmark(BookmarkDictionary.Items[Self]);
    end;
    if ControlsDisabled then
      EnableControls;
  finally
    BookmarkDictionary.Remove(Self);
  end;
end;

function TDatasetHelper.FieldChanged(fld: string): boolean;
var
  fd: TField;
begin
  result := false;
  fd := FindField(fld);
  if fd = nil then
    exit;
  try
    if VarIsNull(fd.OldValue) and VarIsNull(fd.Value) then
      exit;
  except
  end;
  if not(State in [dsEdit, dsInsert]) then
    exit;
  try
    if State in [dsEdit] then
      if fd.OldValue = fd.Value then
        exit;
    if State in [dsInsert] then
      if VarIsNull(fd.Value) then
        exit;
    result := true;
  except
  end;
end;

procedure TDatasetHelper.FieldMask(fld, mask: string);
var
  f: TField;
begin
  f := FindField(fld);
  if not assigned(f) then
    exit;
  case f.DataType of
    ftFloat, ftCurrency:
      TFloatField(f).DisplayFormat := mask;
    ftDate:
      TDateField(f).DisplayFormat := mask;
    ftDateTime:
      TDateTimeField(f).DisplayFormat := mask;
    ftString:
      begin
        TStringField(f).DisplayLabel := mask;
        TStringField(f).EditMask := mask;
      end;
  end;
end;

procedure TDatasetHelper.FieldTitle(AFld, ATitle: string);
var
  f: TField;
begin
  f := FindField(AFld);
  if not assigned(f) then
    exit;
  f.DisplayLabel := ATitle;
end;

procedure TDatasetHelper.ToJsonArray(var pJsonArray: TJsonArray; const pIncludeNullFields: Boolean);
var
  FJsonObj: TJSONObject;
begin
  if IsEmpty then
    Exit;
  DisableControls;
  BeginUpdate;
  First;
  try
    while not(Eof) do
    begin
      FJsonObj := TJSONObject.Create;
      Fields.JsonObject(FJsonObj, pIncludeNullFields);
      pJsonArray.AddElement(FJsonObj);
      Next;
    end;
  finally
    EndUpdate;
    EnableControls;
  end;
end;

function TDatasetHelper.ToJsonString(const pIncludeNullFields: Boolean): string;
var
  LJsonArray: TJSONArray;
begin
  LJsonArray := TJSONArray.Create;
  ToJsonArray(LJsonArray, pIncludeNullFields);
  try
    Result := LJsonArray.ToJSON;
  finally
    LJsonArray.Free;
  end;
end;

{ TFieldsHelper }

function TFieldsHelper.JsonObject(var pJsonObject: TJSONObject; const pIncludeNullFields: Boolean): Integer;
var
  LFieldName: string;
  LMemoryStream: TMemoryStream;
  LStringStream: TStringStream;
  LField: TField;
begin
  Result := 0;
  if not(Assigned(pJsonObject)) then
    Exit;
  for LField in Self do
  begin
    LFieldName := LField.FieldName.ToLower;
    if LField.IsNull then
    begin
      if not(pIncludeNullFields) then
        Continue;
      pJsonObject.AddPair(LFieldName, TJSONNull.Create);
    end;

    case LField.DataType of
      TFieldType.ftInteger, TFieldType.ftAutoInc, TFieldType.ftSmallint, TFieldType.ftShortint:
        pJsonObject.AddPair(LFieldName, TJSONNumber.Create(LField.AsInteger));

      TFieldType.ftLargeint:
        pJsonObject.AddPair(LFieldName, TJSONNumber.Create(LField.AsLargeInt));

      ftWideString, ftMemo, ftWideMemo:
        pJsonObject.AddPair(LFieldName, LField.AsWideString);

      ftString:
        pJsonObject.AddPair(LFieldName, LField.AsString);

      TFieldType.ftTime:
        pJsonObject.AddPair(LFieldName, FormatDateTime('hh:mm:ss', LField.AsDateTime));

      TFieldType.ftDate:
        pJsonObject.AddPair(LFieldName, FormatDateTime('yyyy-mm-dd', LField.AsDateTime));

      TFieldType.ftDateTime:
        pJsonObject.AddPair(LFieldName, FormatDateTime('yyyy-mm-dd hh:mm:ss', LField.AsDateTime));

      TFieldType.ftTimeStamp:
        pJsonObject.AddPair(LFieldName, SQLTimeStampToStr('yyyy-mm-dd hh:mm:ss', LField.AsSQLTimeStamp));

      TFieldType.ftCurrency:
        pJsonObject.AddPair(LFieldName, TJSONNumber.Create(LField.AsCurrency));

      TFieldType.ftBCD, TFieldType.ftFMTBcd:
        pJsonObject.AddPair(LFieldName, TJSONNumber.Create(BcdToDouble(LField.AsBcd)));

      TFieldType.ftSingle, TFieldType.ftFloat:
        pJsonObject.AddPair(LFieldName, TJSONNumber.Create(LField.AsFloat));

      TFieldType.ftGraphic, TFieldType.ftBlob, TFieldType.ftStream:
        begin
          LMemoryStream := TMemoryStream.Create;
          try
            TBlobField(LField).SaveToStream(LMemoryStream);
            LMemoryStream.Position := 0;
            LStringStream := TStringStream.Create('', TEncoding.ASCII);
            try
              TNetEncoding.Base64.Encode(LMemoryStream, LStringStream);
              LStringStream.Position := 0;
              pJsonObject.AddPair(LFieldName, LStringStream.DataString);
            finally
              LStringStream.Free;
            end;
          finally
            LMemoryStream.Free;
          end;
        end;

      TFieldType.ftBoolean:
        begin
          pJsonObject.AddPair(LFieldName, TJSONBool.Create(LField.AsBoolean));
        end;
    end;
    Inc(Result);
  end;
end;

function TFieldsHelper.ToJson(const pIncludeNullFields: Boolean): string;
var
  LJsonObject: TJSONObject;
begin
  LJsonObject := TJSONObject.Create;
  try
    JsonObject(LJsonObject, pIncludeNullFields);
    Result := LJsonObject.ToString;
  finally
    LJsonObject.Free;
  end;
end;

{ TJSONArrayHelper }

function TJSONArrayHelper.Paginate(const AOwnerPair: String; ALimit, APage: Integer): String;
var
  LNewJsonArray: TJSONArray;
  LJsonObjectResponse: TJsonObject;
  I, LPages: Integer;
begin
  LNewJsonArray := TJSONArray.Create;
  LPages := Trunc((Self.Count / ALimit) + 1);

  try
    for I := (ALimit * (APage - 1)) to ((ALimit * APage)) - 1 do
    begin
      if I < Self.Count then
        LNewJsonArray.AddElement(Self.Items[I].Clone as TJSONValue);
    end;

    LJsonObjectResponse := TJsonObject.Create;
    LJsonObjectResponse.AddPair(AOwnerPair, LNewJsonArray)
      .AddPair(TJsonPair.Create(TJSONString.Create('total'), TJSONNumber.Create(Self.Count)))
      .AddPair(TJsonPair.Create(TJSONString.Create('limit'), TJSONNumber.Create(ALimit)))
      .AddPair(TJsonPair.Create(TJSONString.Create('page'), TJSONNumber.Create(APage)))
      .AddPair(TJsonPair.Create(TJSONString.Create('pages'), TJSONNumber.Create(LPages)));
    Result := LJsonObjectResponse.ToJSON;
  finally
    LNewJsonArray.Free;
  end;
end;

initialization

BookmarkDictionary := TDictionary<TDataSet, TBookmark>.Create;

finalization

BookmarkDictionary.Free;

end.
