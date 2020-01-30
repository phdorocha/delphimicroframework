{ *************************************************************************** }
{ }
{ }
{ Copyright (C) Paulo Henrique dos S Andrade }
{ }
{ https://github.com/phdorocha }
{ }
{ }
{ *************************************************************************** }
{ }
{ Licensed under the Apache License, Version 2.0 (the "License"); }
{ you may not use this file except in compliance with the License. }
{ You may obtain a copy of the License at }
{ }
{ http://www.apache.org/licenses/LICENSE-2.0 }
{ }
{ Unless required by applicable law or agreed to in writing, software }
{ distributed under the License is distributed on an "AS IS" BASIS, }
{ WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. }
{ See the License for the specific language governing permissions and }
{ limitations under the License. }
{ }
{ *************************************************************************** }

{
  Alteraçoes:
  30/06/18 - Primeira versão publicada
  21/07/18 - Implementação JOINs;
  29/01/20 - Implementdo retorno em TDataSet (mais baixo nível de DataSet) e melhorado os Wheres podendo por
    exemplo criar uma cadeia de wheres (Classe.where(field,value).where(field,value).where(field,value).get);.

}

unit uIBuilderSQL;

interface

uses
  // Próprias
  uIBase,
  // Rest Dataware
  uDWConstsData, uRESTDWPoolerDB, uDWAbout, uDWMassiveBuffer, uDWDataset,
  // Delphi
  Vcl.Controls, Classes, SysUtils, Generics.Collections, DB, DBClient, Provider,
  DBXJSon, System.TypInfo, System.Rtti, System.Variants;

{ IfThen will return the true string if the value passed in is true, else
  it will return the false string }
function IfThen(AValue: Boolean; const ATrue: string;
  AFalse: string = ''): string; overload; inline;

function IsEmpty(Str: String = ''): Boolean;

type
  TFieldType = (ftVarChar, ftDate, ftNumber);

  TBuilderSQL = class(TComponent)
  private
    FTable: string;
    FKeyField: string;
    cdsTabela: TClientDataSet;
    dsProvider: TDataSetProvider;
    FConexao: IProvider;
    FOwner: TComponent;

    function newQuery(Columns: array of string; AWhere: string = ''; AOrderBy: string = ''): String;
    function swhere(getKeyName: String; sOperator: String = '='; getKey: String = ''): string; overload;
    function swhere(getKeyName: String; getKey: String = ''): string; overload;

  protected
    fillable: TArray<string>;
    Columns : TArray<String>;
    wheres  : TArray<String>;
    withm: array of string;
    withCount: array of string;
    rdwTabela: TRESTDWClientSQL;

    procedure InitModel; virtual; abstract;
    procedure rdwTabelaBeforeOpen(DataSet: TDataSet);

  public
    Join: array of string;
    property Conexao: IProvider read FConexao write FConexao;

    function TableName: string; virtual;
    function PrimaryKey: string; virtual;
    function All(Columns: array of string): TClientDataSet;
    function where(getKeyName, sOperator, getKey: String): TRESTDWClientSQL; overload;
    function where(getKeyName, getKey: String): TRESTDWClientSQL; overload;
    function where(Column, AOperator: String; AValue: Variant):
      TBuilderSQL; overload;
    function get: TDataSet; overload; virtual;
    function get(AColumns: TArray<String>): TDataSet; overload; virtual;
    function get(AID: Integer = -1): TRESTDWClientSQL; overload; virtual;
    function Select(Columns: Array of string): TBuilderSQL; virtual;
    procedure Save(AObject: TObject); overload;
    function Save(ArdwSQL: TRestDWClientSQL): TRESTDWClientSQL; overload;
    function JSONDataSet(Columns: array of string): String;

    Constructor Create(AOwner: TComponent);
    Destructor Destroy; override;
  end;

implementation

{ TBuilderSQL }

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

function TBuilderSQL.All(Columns: array of string): TClientDataSet;
var
  sSQL: String;
begin
  Result := NIL;

  try
  // Monta o select com as colunas no parâmetro
    if Length(Columns) > 0 then
      sSQL := newQuery(Columns)
    else
      sSQL := newQuery(fillable);

    cdsTabela.CommandText := sSQL;
    rdwTabela.SQL.Text    := sSQL;

    try
      rdwTabela.Open;
    except
      On E: Exception do
        Assert(False,'Erro :' + E.Message + sLineBreak + E.ClassName.QuotedString);
    end;
  finally

  end;

  Result := cdsTabela;
end;

function TBuilderSQL.swhere(getKeyName, sOperator, getKey: String): string;
begin
  Result := getKeyName + ' ' + sOperator + ' ' + getKey;
end;

function TBuilderSQL.swhere(getKeyName, getKey: String): string;
begin
  Result := getKeyName + ' = ' + getKey;
end;

constructor TBuilderSQL.Create(AOwner: TComponent);
begin
  FOwner := AOwner;
  FConexao := uIBase.TProvider.Create(AOwner);
  rdwTabela  := TRESTDWClientSQL.Create(AOwner);

  with rdwTabela do
  begin
    BinaryRequest := True;
    Params.Clear;
    DataBase           := FConexao.RDWConn;
    ActionCursor       := crSQLWait;
    AutoCommitData     := True;
    CacheUpdateRecords := not AutoCommitData;
    ReflectChanges     := True;
    SequenceField      := PrimaryKey;
    UpdateTableName    := TableName;
  end;

  dsProvider := TDataSetProvider.Create(AOwner);

  with dsProvider do
  begin
    DataSet := rdwTabela;
    Options := [poIncFieldProps,poAllowCommandText];
    UpdateMode := upWhereKeyOnly;
  end;

  cdsTabela := TClientDataSet.Create(NIL);
  cdsTabela.SetProvider(dsProvider);
end;

destructor TBuilderSQL.Destroy;
begin
  if cdsTabela <> NIL then
  begin
    if cdsTabela.Active then
      cdsTabela.Close;
    cdsTabela.Free;
  end;

  if rdwTabela <> NIL then
  begin
    if rdwTabela.Active then
      rdwTabela.Close;
    rdwTabela.Free;
  end;

  if dsProvider <> NIL then
    dsProvider.Free;

  inherited;
end;

function TBuilderSQL.get: TDataSet;
begin
  Result := Self.get(['*']);
end;

function TBuilderSQL.get(AColumns: TArray<String>): TDataSet;
var
  FOriginal: Array of string;
  cdsResult: TClientDataSet;
  fillable: TArray<string>;
  I: Integer;
begin
  TArray(FOriginal) := TArray(Self.Columns);

  if Length(AColumns) > 0 then
  begin
    SetLength(Self.Columns, Length(AColumns));
    Self.Columns := AColumns;
  end else
    if Length(Self.Columns) <= 0 then
      Self.Columns := ['*'];

  cdsResult := self.All(Self.Columns);
  TArray(Self.Columns) := TArray(FOriginal);

  Result := TDataSet(cdsResult);
end;

function TBuilderSQL.get(AID: Integer): TRESTDWClientSQL;
var
  sSQL: String;
begin
  try
    if AID > 0 then
      sSQL := newQuery(fillable,swhere(PrimaryKey,'=',AID.ToString), PrimaryKey)   // Monsta o select com as colunas no parâmetro
    else
      sSQL := newQuery(fillable);   // Monsta o select com as colunas no parâmetro

    if rdwTabela = NIL then
      rdwTabela := TRESTDWClientSQL.Create(Self);

    rdwTabela.BinaryRequest := True;

    if rdwTabela.Active then
      rdwTabela.Close;

    if not FConexao.RDWConn.Connected then
      FConexao.RDWConn.Open;

    with Self.rdwTabela do
    begin
      DataBase := FConexao.RDWConn;
      SQL.Clear;
      SQL.Text := sSQL;
      AutoCommitData := True;
      AutoCalcFields := True;
      CacheUpdateRecords := not rdwTabela.AutoCommitData;
      ReflectChanges := True;
      UpdateTableName := Self.TableName;
      SequenceField := Self.PrimaryKey;
    end;

    try
      rdwTabela.Open;
    except
      On E: Exception do
        Assert(False,'Erro :' + E.Message + QuotedStr(self.ClassName) + sLineBreak);
    end;
  finally
    if rdwTabela.Active then
      rdwTabela.Open;

    Result := rdwTabela;
  end;
end;

function TBuilderSQL.JSONDataSet(Columns: array of string): String;
{var
  sSQL: String;
  ArrayJSon:TJSONArray;
  ObjJSon:TJSONObject;
  strJSon:TJSONString;
  intJSon:TJSONNumber;
  TrueJSon:TJSONTrue;
  FalseJSon:TJSONFalse;
  I: Integer;
  pField: TField;  }
begin          {
  sSQL := newQuery(Columns);   // Monsta o select com as colunas no parâmetro
  rdwTabela.SQL.Text := sSQL;
  cdsTabela.CommandText   := sSQL;
  try
    cdsTabela.Open;
  except
    On E: Exception do
      Assert(False,'Erro :' + E.Message + QuotedStr(self.ClassName) + sLineBreak);
  end;

{-- Prepara JSON convert                                                     --}
{  ArrayJSon:=TJSONArray.Create;
  try
    cdsTabela.First;
    cdsTabela.DisableControls;
    while not cdsTabela.Eof do
    begin
      ObjJSon := TJSONObject.Create;
      for pField in cdsTabela.Fields do
      begin
        case pField.DataType of
          ftAutoInc:
          begin
            IntJSon:=TJSONNumber.Create(pField.AsInteger);
            ObjJSon.AddPair(pField.FieldName,IntJSon);
          end;
          ftString:
          begin
            strJSon:=TJSONString.Create(pField.AsString);
            ObjJSon.AddPair(pField.FieldName,strJSon);
          end;
          ftWideString:
          begin
            strJSon:=TJSONString.Create(pField.AsString);
            ObjJSon.AddPair(pField.FieldName,strJSon);
          end;
          ftInteger:
          begin
            IntJSon:=TJSONNumber.Create(pField.AsInteger);
            ObjJSon.AddPair(pField.FieldName,IntJSon);
          end;
          ftBoolean:
          if pField.AsBoolean then
          begin
            TrueJSon:=TJSONTrue.Create;
            ObjJSon.AddPair(pField.FieldName,TrueJSon);
          end else begin
            FalseJSon:=TJSONFalse.Create;
            ObjJSon.AddPair(pField.FieldName,FalseJSon);
          end;
        end;
      end;
      ArrayJSon.AddElement(ObjJSon);
      cdsTabela.Next;
    end;
    Result:=ArrayJSon.ToString;
  finally
    ArrayJSon.Free;
  end;         }
end;

function TBuilderSQL.newQuery(Columns: array of string; AWhere,
  AOrderBy: string): String;
var
  sQuery, Str: String;
  I: Integer;
begin
  sQuery := 'SELECT ';

  for I := Low(Columns) to High(Columns) do
  begin
    if I = 0 then
      sQuery := sQuery + Columns[I]
    else
      sQuery := sQuery + ' ,' + Columns[I];
  end;

  if Trim(AWhere) = EmptyStr then
    for I := Low(Wheres) to High(Wheres) do
    begin
      if I = 0 then
        AWhere := AWhere + Wheres[I]
      else
        AWhere := AWhere + ' AND ' + Wheres[I];
    end;

  sQuery := UpperCase(Trim(sQuery)) + ' FROM ' + UpperCase(self.TableName) + Ifthen(IsEmpty(Trim(AWhere)), '',
    ' WHERE ' + UpperCase(Trim(AWhere))) + Ifthen(IsEmpty(Trim(AOrderBy)), '', ' ORDER BY ' + AOrderBy);
  Result := Trim(sQuery);
end;

function TBuilderSQL.PrimaryKey: string;
begin
  Assert(False, 'A função "PrimaryKey" não foi implementada em ' + QuotedStr(self.ClassName) + sLineBreak);
end;

procedure TBuilderSQL.rdwTabelaBeforeOpen(DataSet: TDataSet);
begin
  inherited;

  if not(PrimaryKey = EmptyStr) then
    TField(rdwTabela.FieldByName(PrimaryKey)).ProviderFlags := [pfInUpdate,pfInWhere,pfInKey];
end;

procedure TBuilderSQL.Save(AObject: TObject);
var
  FContext: TRttiContext;
  FProp   : TRttiProperty;
  SubObj  : TObject;
  AListProp: TStrings;
  FType: TRttiType;
begin
  FContext  := TRttiContext.Create;
  AListProp := TStrings.Create;
  AListProp.BeginUpdate;

  try
    // Erro aqui
    FType := FContext.GetType(AObject);

    for FProp in FContext.GetType(AObject.ClassType).GetProperties do
    begin
      AListProp.Add(Format('[ %s ]', [FProp.Name]));
      AListProp.Add(Format('- ClassName : %s', [AObject.QualifiedClassName]));
      AListProp.Add(Format('- TypeKind  : %s', [GetEnumName(TypeInfo(TTypeKind), Integer(FProp.PropertyType.TypeKind))]));
      AListProp.Add(Format('- TypeName  : %s', [FProp.PropertyType.Name]));
      AListProp.Add(Format('- StrValue  : %s', [FProp.GetValue(AObject).ToString]));

      try
        AListProp.Add(Format('- PropValue : %s', [VarToStr(FProp.GetValue(AObject).AsVariant)]));
      except
        // POG   ??
      end;

      if FProp.PropertyType.TypeKind = tkEnumeration then
        AListProp.Add(Format('- EnumValue : %s', [GetEnumName(FProp.GetValue(AObject).TypeInfo, FProp.GetValue(AObject).AsOrdinal)]));

      AListProp.Add(Format('- Visibility: %s', [GetEnumName(TypeInfo(TMemberVisibility), Integer(FProp.Visibility))]));
      AListProp.Add(Format('- IsReadable: %s', [BoolToStr(FProp.IsReadable, True)]));
      AListProp.Add(Format('- IsWritable: %s', [BoolToStr(FProp.IsWritable, True)]));
      AListProp.Add('');
    end;
  finally
    AListProp.EndUpdate;
    FContext.Free;
  end;
end;

function TBuilderSQL.Save(ArdwSQL: TRestDWClientSQL): TRESTDWClientSQL;
var
  sSQL, sError: String;
  I: Integer;
begin
  sSQL := 'INSERT INTO ' + TableName + ' (';

  for I := 0 to ArdwSQL.FieldCount do
  begin
    if I = 0 then
      sSQL := sSQL + ArdwSQL.Fields[i].FieldName
    else
      sSQL := sSQL + ',' + ArdwSQL.Fields[i].FieldName;
  end;

  sSQL := sSQL + ') VALUES (';

  for I := 0 to ArdwSQL.FieldCount do
  begin
    if I = 0 then
      sSQL := sSQL + ArdwSQL.Fields[i].Value
    else
      sSQL := sSQL + ',' + ArdwSQL.Fields[i].Value;
  end;

  sSQL := sSQL + ')';

  if rdwTabela.Active then
    rdwTabela.Close;

  rdwTabela.DataBase := FConexao.RDWConn;
  rdwTabela.SQL.Clear;
  rdwTabela.SQL.Text := sSQL;

  Assert(rdwTabela.ExecSQL(sError),'Erro :'
    + sError + sLineBreak
    + QuotedStr(self.ClassName) + sLineBreak
  );

  Result := ArdwSQL;
end;

function TBuilderSQL.Select(Columns: array of string): TBuilderSQL;
var
  I: Integer;
begin
  if (Length(Columns) >0) then
  begin
    SetLength(Self.Columns, Length(Columns));

    for I := 0 to Length(Columns)-1 do
      Self.Columns[i] := Columns[i];
  end else
    Self.Columns := ['*'];

  result := self;
end;

function TBuilderSQL.TableName: string;
begin
  Assert(False, 'A função "TableName" não foi implementada em ' + QuotedStr(self.ClassName) + sLineBreak);
end;

function TBuilderSQL.where(Column, AOperator: String;
  AValue: Variant): TBuilderSQL;
begin
  if Length(Trim(AOperator)) = 0 then
    AOperator := '=';

  SetLength(Wheres, Length(Wheres)+1);
  Wheres[High(Wheres)] := Column +' '+ AOperator +' '+ AValue;

  Result := Self;
end;

function TBuilderSQL.where(getKeyName, sOperator,
  getKey: String): TRESTDWClientSQL;
var
  sSQL: String;
begin
  sSQL := newQuery(fillable,swhere(getKeyName,sOperator,getKey), PrimaryKey);   // Monsta o select com as colunas no parâmetro

  if rdwTabela.Active then
    rdwTabela.Close;

  rdwTabela.DataBase := FConexao.RDWConn;
  rdwTabela.SQL.Clear;
  rdwTabela.SQL.Text := sSQL;

  try
    rdwTabela.Open;
  except
    On E: Exception do
      Assert(False,'Erro :' + E.Message + QuotedStr(self.ClassName) + sLineBreak);
  end;
  Result := rdwTabela;
end;

function TBuilderSQL.where(getKeyName, getKey: String): TRESTDWClientSQL;
var
  sSQL: String;
begin
  sSQL := newQuery(fillable,swhere(getKeyName,'=',getKey), PrimaryKey);   // Monsta o select com as colunas no parâmetro

  if rdwTabela.Active then
    rdwTabela.Close;

  rdwTabela.DataBase := FConexao.RDWConn;
  rdwTabela.SQL.Clear;
  rdwTabela.SQL.Text := sSQL;

  try
    rdwTabela.Open;
  except
    On E: Exception do
      Assert(False,'Erro :' + E.Message + QuotedStr(self.ClassName) + sLineBreak);
  end;
  Result := rdwTabela;
end;

end.
