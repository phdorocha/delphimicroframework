unit Model;

interface

uses
  Data.DB, System.JSON;

type
  iModelQuery = interface;

  iModelConexao = interface
    ['{DFEF8A11-246E-4D60-ABD2-50867699AA3E}']
    function Connection: TCustomConnection;
  end;

  iModelQuery = interface
    ['{9D8E55AB-22E0-440D-A77F-820B8B7F6D5C}']
    function GetTableName: string;
    procedure SetTableName(const Value: string);
    property TableName: string read GetTableName write SetTableName;

    function GetPrimaryKey: string;
    procedure SetPrimaryKey(const Value: string);
    property PrimaryKey: string read GetPrimaryKey write SetPrimaryKey;

    function belongsTo(ATableName, AForeignKey, ALocalKey: String): iModelQuery;

    function Open(aSQL : String) : iModelQuery;
    function OpenTable(ATable: String): iModelQuery;
    procedure ToJsonArray(var pJsonArray: TJsonArray; const pIncludeNullFields: Boolean = False);
    function ExecSQL(aSQL : String) : iModelQuery;
    function LeftJoin(AJoin, AForKey, AOperator, APrimaryKey: String): iModelQuery;
    function InnerJoin(AJoin, AForKey, AOperator, APrimaryKey: String): iModelQuery;
    function Select(AColumns: Array of string): iModelQuery;
    function Where(AColumn, AOperator: String; AValue: Variant): iModelQuery; overload;
    function Where(AColumn: String; AValue: Variant): iModelQuery; overload;
    function Having(AColumn, AOperator: String; AValue: Variant): iModelQuery;
    function GroupBy(AColumns: Array of string): iModelQuery;
    function OrderBy(Column: String; AType: String = ''): iModelQuery;
    function Raw(ASQLCommand: String): iModelQuery;
    function Get: iModelQuery; overload;
    function Get(AID: Integer): iModelQuery; overload;
  end;

  iModelConexaoFactory = interface
    ['{D5383A0B-A7DB-42B8-BD59-538E7AF49850}']
    function Conexao: iModelConexao;
    function ConexaoSys: iModelConexao;
    function Query: iModelQuery;
  end;


implementation

end.
