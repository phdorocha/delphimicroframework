unit uIBase;

interface

uses
  SysUtils, Classes, Variants, ADODB, Util, Constants;

type
  TField = class
    private
      FoValue: Variant;
      FcName: String;
    protected
      function get_AsInteger: integer;
      function get_AsFloat  : Double;
      function get_AsDate   : TDateTime;
      function get_AsString : String;
      function get_AsValue : Variant;

      procedure set_AsInteger(value: integer);
      procedure set_AsFloat  (value: Double);
      procedure set_AsDate   (value: TDateTime);
      procedure set_AsString (value: String);
      procedure set_AsValue  (value: Variant);
    public
      constructor Create(Field: string);
      property Name     : String    read FcName        write FcName;
      property AsInteger: Integer   read get_AsInteger write set_AsInteger;
      property AsFloat  : Double    read get_AsFloat   write set_AsFloat;
      property AsDate   : TDateTime read get_AsDate    write set_AsDate;
      property AsString : String    read get_AsString  write set_AsString;
      property AsValue  : Variant   read get_AsValue   write set_AsValue;
  end;

  TFieldType = (ftVarChar, ftDate, ftNumber);

  TFieldSearch = class
    private
      FcName: String;
      FcDesc: String;
      FoFieldType: TFieldType;
    public
      property Name: String read FcName write FcName;
      property Desc: String read FcDesc write FcDesc;
      property FieldType: TFieldType read FoFieldType write FoFieldType;
  end;

  ITabela = Interface
    function canInsert(): boolean;
    function canUpdate(): boolean;
    function canDelete(): boolean;
    procedure Assign(loObj: ITabela);

    function get_Master: ITabela;
    procedure set_Master(value: ITabela);

    property MasterTabela: ITabela read get_Master write set_Master;

    function FieldByName(lcField: string): TField;
  End;

  TTabelaBase = class(TInterfacedObject, ITabela)
    private
      FoConn  : TADOConnection;
      FcTabela: string;
      FoLista : TList;
      FoMaster: ITabela;
    protected
      function canInsert(): boolean; virtual; abstract;
      function canUpdate(): boolean; virtual; abstract;
      function canDelete(): boolean; virtual; abstract;

      function get_Master: ITabela; virtual;
      procedure set_Master(Value: ITabela); virtual;

      constructor Create(Conn: TADOConnection; Tabela: string); virtual;

      // para master detail
      property MasterTable: ITabela read get_Master write set_Master;

    public
      destructor Destroy; override;

      procedure Assign(loObj: ITabela);
      function FieldByName(lcField: string): TField;

      property Conn: TADOConnection read FoConn;

  end;

  IProvider = Interface
    function Insert: boolean;
    function Update: boolean;
    function Delete: boolean;

    function get_conn: TADOConnection;
    procedure set_conn(value: TADOConnection);

    function  get_ITable: ITabela;
    procedure set_ITable(Value: ITabela);

    property Conn: TADOConnection read get_conn write set_conn;
    property Table: ITabela read get_ITable write set_ITable;
  end;

  TProvider = class(TInterfacedObject, IProvider)
    private
      FoConn: TADOConnection;
      FoTabela: ITabela;

    protected
      function get_conn: TADOConnection;
      procedure set_conn(value: TADOConnection);

      function  get_ITable: ITabela; virtual;
      procedure set_ITable(Value: ITabela); virtual;

      function doInsert: boolean; virtual; abstract;
      function doUpdate: boolean; virtual; abstract;
      function doDelete: boolean; virtual; abstract;

    public
      function Insert: boolean; virtual;
      function Update: boolean; virtual;
      function Delete: boolean; virtual;

      property Conn: TADOConnection read get_conn write set_conn;
      property Table: ITabela read get_ITable write set_ITable;

      Constructor Create;
      Destructor Destroy; override;
  end;

implementation

{ TProvider }

constructor TProvider.Create;
begin
  inherited Create;

  FoConn := TADOConnection.Create(NIL);
  FoConn.LoginPrompt := False;
  FoConn.ConnectionString :=
    'Provider=SQLOLEDB.1;'
    +'Persist Security Info=True;'
    +'User ID='+TUtil.ReadIni(TUtil.IniFileServer, INI_SESSAO_CONEXAO, INI_ONLOGIN)+';'
    +'Password='+TUtil.Criptografar(TUtil.ReadIni(TUtil.IniFileServer, INI_SESSAO_CONEXAO, INI_ONSENHA))+';'
    +'Initial Catalog=base;'
    +'Data Source='+TUtil.ReadIni(TUtil.IniFileServer, INI_SESSAO_CONEXAO, INI_SERVER);
  FoConn.Provider := 'SQLOLEDB.1';
  FoConn.Open;
end;

function TProvider.Delete: boolean;
begin

end;

destructor TProvider.Destroy;
begin
  if Conn.Connected then
    Conn.Close;
  Conn.Free;

  inherited;
end;

function TProvider.get_conn: TADOConnection;
begin
  result := FoConn;
end;

function TProvider.get_ITable: ITabela;
begin
  result := FoTabela;
end;

function TProvider.Insert: boolean;
begin
  try
    if not Table.canInsert then
      raise Exception.Create('Parâmetros insuficientes!');
    result := doInsert;
  except
    on e: exception do
    begin
      raise E.Create('Erro ao tentar incluir!');
    end;
  end;
end;

procedure TProvider.set_conn(value: TADOConnection);
begin
  FoConn := value;
end;

procedure TProvider.set_ITable(Value: ITabela);
begin
  FoTabela := Value;
end;

function TProvider.Update: boolean;
begin

end;

{ TTabelaBase }

procedure TTabelaBase.Assign(loObj: ITabela);
var
  I: integer;
  loField: TField;
begin
  for I := 0 to FoLista.Count - 1 do
  begin
    // Campo I do loop
    loField := TField(FoLista[I]);
    // Copiando o conteúdo do loObj para dentro do campo
    Self.FieldByName(loField.Name).asValue := loObj.FieldByName(loField.Name).asValue;
  end;
end;

constructor TTabelaBase.Create(Conn: TADOConnection; Tabela: string);
begin
  inherited Create;
  FoConn := Conn;
  FcTabela := Tabela;
  FoLista := TList.Create;
end;

destructor TTabelaBase.Destroy;
var
  I: Integer;
begin
  for I := 0 to FoLista.Count - 1 do
  begin
    TField(FoLista[I]).Free;
    FoLista[I] := nil;
  end;
  FoLista.Pack;

  inherited;
end;

function TTabelaBase.FieldByName(lcField: string): TField;
var
  I: Integer;
begin
  result := nil;
  for I := 0 to FoLista.Count - 1 do
    if UpperCase(TField(FoLista[i]).Name) = UpperCase(lcField) then
    begin
      result := TField(FoLista[I]);
      break;
    end;
end;

function TTabelaBase.get_Master: ITabela;
begin
  result := FoMaster;
end;

procedure TTabelaBase.set_Master(Value: ITabela);
begin
  FoMaster := Value;
end;

{ TField }

constructor TField.Create(Field: string);
begin
  inherited Create;
  FcName := Field;
end;

function TField.get_AsDate: TDateTime;
begin
  result := FoValue;
end;

function TField.get_AsFloat: Double;
begin
  result := FoValue;
end;

function TField.get_AsInteger: integer;
begin
  result := FoValue;
end;

function TField.get_AsString: String;
begin
  result := FoValue;
end;

function TField.get_AsValue: Variant;
begin
  result := FoValue;
end;

procedure TField.set_AsDate(value: TDateTime);
begin
  FoValue:= value;
end;

procedure TField.set_AsFloat(value: Double);
begin
  FoValue:= value;
end;

procedure TField.set_AsInteger(value: integer);
begin
  FoValue:= value;
end;

procedure TField.set_AsString(value: String);
begin
  FoValue:= value;
end;

procedure TField.set_AsValue(value: Variant);
begin
  FoValue:= value;
end;

end.
