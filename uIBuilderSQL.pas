unit uIBuilderSQL;

interface  

uses
  // Próprias
  uIBuilderSQL,
  // Delphi
  Classes, SysUtils, Generics.Collections, DB, DBClient, Provider, ADODB,
  DBXJSon;

{ IfThen will return the true string if the value passed in is true, else
  it will return the false string }
function IfThen(AValue: Boolean; const ATrue: string;
  AFalse: string = ''): string; overload; inline;

function IsEmpty(Str: String = ''): Boolean;

type
  TFieldType = (ftVarChar, ftDate, ftNumber);

  IBuilderSQL = interface(IInterface)
  ['{C38BE0C0-CEA2-4A87-8FAD-CBF54FABC8D6}']
    function TableName: string;
    function PrimaryKey: string;
    function All(Columns: array of string): TClientDataSet;
  end;

  TBuilderSQL = class(TInterfacedObject, IBuilderSQL)
  private
    FTable: string;
    FKeyField: string;
    cdsTabela: TClientDataSet;
    dsProvider: TDataSetProvider;
    qryTabela: TADOQuery;
    FConexao: IProvider;

    function newQuery(Columns: array of string; AWhere: string = ''; AOrderBy: string = ''): String;
    function where(getKeyName: String; sOperator: String = '='; getKey: String = ''): string;

  protected
    fillable: TArray<string>;
    withm: array of string;
    withCount: array of string;

    procedure InitModel; virtual; abstract;
  public
    function TableName: string; virtual;
    function PrimaryKey: string; virtual;
    function All(Columns: array of string): TClientDataSet;
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
  try
    sSQL := newQuery(Columns);   // Monsta o select com as colunas no parâmetro
    qryTabela.sql.CommaText := sSQL;
    cdsTabela.CommandText := sSQL;
    try
      cdsTabela.Open;
    except
      On E: Exception do
        Assert(False,'Erro :' + E.Message + QuotedStr(self.ClassName) + sLineBreak);
    end;
  result := cdsTabela;
  finally

  end;
end;

function TBuilderSQL.where(getKeyName, sOperator, getKey: String): string;
begin
  Result := getKeyName + ' ' + sOperator + ' ' + getKey;
end;

constructor TBuilderSQL.Create(AOwner: TComponent);
begin
  FConexao := uIBase.TProvider.Create;

  qryTabela  := TADOQuery.Create(AOwner);
  qryTabela.Connection  := FConexao.Conn;
  qryTabela.CursorType  := ctStatic;
  qryTabela.Parameters.Clear;

  dsProvider := TDataSetProvider.Create(AOwner);
  dsProvider.Name := 'dsProvider';
  dsProvider.DataSet := qryTabela;
  dsProvider.Options := [poIncFieldProps,poAllowCommandText];
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

function TBuilderSQL.JSONDataSet(Columns: array of string): String;
var
  sSQL: String;
  ArrayJSon:TJSONArray;
  ObjJSon:TJSONObject;
  strJSon:TJSONString;
  intJSon:TJSONNumber;
  TrueJSon:TJSONTrue;
  FalseJSon:TJSONFalse;
  I: Integer;
  pField: TField;
begin
  sSQL := newQuery(Columns);   // Monsta o select com as colunas no parâmetro
  qryTabela.sql.CommaText := sSQL;
  cdsTabela.CommandText   := sSQL;
  try
    cdsTabela.Open;
  except
    On E: Exception do
      Assert(False,'Erro :' + E.Message + QuotedStr(self.ClassName) + sLineBreak);
  end;

{-- Prepara JSON convert                                                     --}
  ArrayJSon:=TJSONArray.Create;
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
  end;
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
  sQuery := UpperCase(Trim(sQuery)) + ' FROM ' + UpperCase(self.TableName) + Ifthen(IsEmpty(Trim(AWhere)), '',
    ' WHERE ' + UpperCase(Trim(AWhere))) + Ifthen(IsEmpty(Trim(AOrderBy)), '', ' ORDER BY ' + AOrderBy);

  Result := Trim(sQuery);
end;

function TBuilderSQL.PrimaryKey: string;
begin
  Assert(False, 'A função "PrimaryKey" não foi implementada em ' + QuotedStr(self.ClassName) + sLineBreak);
end;

function TBuilderSQL.TableName: string;
begin
  Assert(False, 'A função "TableName" não foi implementada em ' + QuotedStr(self.ClassName) + sLineBreak);
end;

end.
