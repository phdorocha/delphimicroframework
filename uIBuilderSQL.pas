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

}

unit uIBuilderSQL;

interface

uses
  // Próprias
  uIBase, Easy.DB.Helper,
  // Delphi
  Classes, SysUtils, Forms, Generics.Collections, DB, DBClient, Provider,
  DBXJSon, RTTI;

{ IfThen will return the true string if the value passed in is true, else
  it will return the false string }
function IfThen(AValue: Boolean; const ATrue: string;
  AFalse: string = ''): string; overload; inline;

function IsEmpty(Str: String = ''): Boolean;

type
  TValidator = class
    class function Execute(const AModule: string): TDataSet;
  end;

  TJoin = Array [0 .. 2] of String;

  IBuilderSQL = interface(IInterface)
    ['{C38BE0C0-CEA2-4A87-8FAD-CBF54FABC8D6}']
    // Métodos públicos
    function TableName: string;
    function hasOne(AModule, APrimariKey, ALocalKey: string;
      AdsAtivo: TDataSource): TClientDataSet;
    function PrimaryKey: string;
    function All(Columns: Array of string): TClientDataSet;
    function Get(getKeyName: String; sOperator: String = '=';
      getKey: String = ''; AOrderBy: string = ''): TClientDataSet;
    // Métodos privados

    // Propriedades

  end;

  TBuilderSQL = class(TInterfacedObject, IBuilderSQL)
  private
    FTable: string;
    FKeyField: string;
    FWith: string;
    cdsTabela: TClientDataSet;
    dsProvider: TDataSetProvider;
    FConexao: IProvider;
    function newQuery(Columns: array of string; AWhere: string = '';
      AOrderBy: string = ''): String;
    function where(getKeyName: String; sOperator: String = '=';
      getKey: String = ''): string;
    function hasMany(AModulo, AForkey, ALocalKey: string): string; virtual;

  protected
    fillable: TArray<string>;
    Joins: TList<TJoin>;
    withCount: array of string;

    procedure InitModel; virtual; abstract;
  public
    Join: array of string;

    function TableName: string; virtual;
    function hasOne(AModule, APrimariKey, ALocalKey: string;
      AdsAtivo: TDataSource): TClientDataSet; virtual;
    function PrimaryKey: string; virtual;
    function All(Columns: Array of string): TClientDataSet; virtual;
    function Get(getKeyName: String; sOperator: String = '=';
      getKey: String = ''; AOrderBy: string = ''): TClientDataSet; virtual;
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

function TBuilderSQL.All(Columns: Array of string): TClientDataSet;
var
  sSQL: String;
begin
  try
    // Monta o select com as colunas no parâmetro
    if Length(Columns) > 0 then
      sSQL := newQuery(Columns)
    else
      sSQL := newQuery(fillable);
    FConexao.Query.SQL.CommaText := sSQL;
    cdsTabela.CommandText := sSQL;
    try
      cdsTabela.Open;
    except
      On E: Exception do
        Assert(False, 'Erro :' + E.Message + QuotedStr(self.ClassName)
            + sLineBreak);
    end;
    Result := cdsTabela;
  finally

  end;
end;

function TBuilderSQL.where(getKeyName, sOperator, getKey: String): string;
begin
  Result := getKeyName + ' ' + sOperator + ' ' + getKey;
end;

constructor TBuilderSQL.Create(AOwner: TComponent);
begin
  inherited Create();

  FConexao := uIBase.TProvider.Create;

  FConexao.Query.Connection := FConexao.Conn;
  FConexao.Query.Parameters.Clear;

  dsProvider := TDataSetProvider.Create(AOwner);
  dsProvider.Name := 'dsProvider';
  dsProvider.DataSet := FConexao.Query;
  dsProvider.Options := [poIncFieldProps, poAllowCommandText];
  dsProvider.UpdateMode := upWhereKeyOnly;

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

  inherited;
end;

function TBuilderSQL.Get(getKeyName: String; sOperator: String = '=';
  getKey: String = ''; AOrderBy: string = ''): TClientDataSet;
var
  sSQL: String;
begin
  try
    sSQL := newQuery(fillable, where(getKeyName, sOperator, getKey), AOrderBy);
    // Monta o select com as colunas no parâmetro
    if cdsTabela.Active then
      cdsTabela.Close;
    FConexao.Query.SQL.CommaText := sSQL;
    cdsTabela.SetProvider(dsProvider);
    cdsTabela.CommandText := sSQL;
    try
      cdsTabela.Open;
    except
      On E: Exception do
        Assert(False, 'Erro :' + E.Message + QuotedStr(self.ClassName)
            + sLineBreak);
    end;
    Result := cdsTabela;
  except
    On E: Exception do
      Assert(False, 'Erro Builder: ' + E.Message + #13 + #10 + QuotedStr(self.ClassName) + sLineBreak);
  end;
end;

function TBuilderSQL.hasMany(AModulo, AForkey, ALocalKey: string): string;
begin

end;

function TBuilderSQL.hasOne(AModule, APrimariKey, ALocalKey: string;
  AdsAtivo: TDataSource): TClientDataSet;
begin
  Result := self.All(['*']);
  Result.IndexFieldNames := APrimariKey;
  Result.MasterFields := ALocalKey;
  Result.MasterSource := AdsAtivo;
end;

function TBuilderSQL.JSONDataSet(Columns: array of string): String;
var
  sSQL: String;
  ArrayJSon: TJSONArray;
  ObjJSon: TJSONObject;
  strJSon: TJSONString;
  intJSon: TJSONNumber;
  TrueJSon: TJSONTrue;
  FalseJSon: TJSONFalse;
  I: Integer;
  pField: TField;
begin
  sSQL := newQuery(Columns); // Monsta o select com as colunas no parâmetro
  FConexao.Query.SQL.CommaText := sSQL;
  cdsTabela.CommandText := sSQL;
  try
    cdsTabela.Open;
  except
    On E: Exception do
      Assert(False, 'Erro :' + E.Message + QuotedStr(self.ClassName)
          + sLineBreak);
  end;

  { -- Prepara JSON convert                                                     -- }
  ArrayJSon := TJSONArray.Create;
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
              intJSon := TJSONNumber.Create(pField.AsInteger);
              ObjJSon.AddPair(pField.FieldName, intJSon);
            end;
          ftString:
            begin
              strJSon := TJSONString.Create(pField.AsString);
              ObjJSon.AddPair(pField.FieldName, strJSon);
            end;
          ftWideString:
            begin
              strJSon := TJSONString.Create(pField.AsString);
              ObjJSon.AddPair(pField.FieldName, strJSon);
            end;
          ftInteger:
            begin
              intJSon := TJSONNumber.Create(pField.AsInteger);
              ObjJSon.AddPair(pField.FieldName, intJSon);
            end;
          ftBoolean:
            if pField.AsBoolean then
            begin
              TrueJSon := TJSONTrue.Create;
              ObjJSon.AddPair(pField.FieldName, TrueJSon);
            end
            else
            begin
              FalseJSon := TJSONFalse.Create;
              ObjJSon.AddPair(pField.FieldName, FalseJSon);
            end;
        end;
      end;
      ArrayJSon.AddElement(ObjJSon);
      cdsTabela.Next;
    end;
    Result := ArrayJSon.ToString;
  finally
    ArrayJSon.Free;
  end;
end;

function TBuilderSQL.newQuery(Columns: array of string;
  AWhere, AOrderBy: string): String;
var
  sQuery, Str: String;
  I: Integer;
begin
  sQuery := 'SELECT ';

  // Atribui as Colunas da tabela
  for I := Low(Columns) to High(Columns) do
  begin
    if I = 0 then // se primeira coluna, não coloca vírgula
      sQuery := sQuery + Columns[I]
    else
      sQuery := sQuery + ' ,' + Columns[I];
  end;

  if Length(Self.Join) > 0 then
  begin
    self.FWith := ' INNER JOIN ';
    self.FWith := self.FWith + Self.Join[0];
    self.FWith := self.FWith + ' ON ' + UpperCase(self.TableName) + '.' + Self.Join[2] + ' = '
      + Self.Join[0] + '.' + Self.Join[1];
  end;

  // Incrementa Tabel, Where, Order By e Join
  sQuery := UpperCase(Trim(sQuery)) + ' FROM ' + UpperCase(self.TableName)
    + IfThen(IsEmpty(Trim(FWith)), '', FWith)
    + IfThen(IsEmpty(Trim(AWhere)), '', ' WHERE ' + UpperCase(Trim(AWhere)))
    + IfThen(IsEmpty(Trim(AOrderBy)), '', ' ORDER BY ' + AOrderBy);

  Result := Trim(sQuery);
end;

function TBuilderSQL.PrimaryKey: string;
begin
  Assert(False,
    'A função "PrimaryKey" não foi implementada em ' + QuotedStr
      (self.ClassName) + sLineBreak);
end;

function TBuilderSQL.TableName: string;
begin
  Assert(False,
    'A função "TableName" não foi implementada em ' + QuotedStr
      (self.ClassName) + sLineBreak);
end;

{ TValidator }

class function TValidator.Execute(const AModule: string): TDataSet;
var
  Obj: IBuilderSQL;
begin
  Obj := TBuilderSQL.Create(NIL);

  Result := Obj.All(['*']);
end;

end.
