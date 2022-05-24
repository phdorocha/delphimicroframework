unit Model.Conexao.Factory;

interface

uses
  Builder,
  Model.Conexao.ADO.Conexao,
  Model.Conexao.ADO.Query;

type
  TModelConexaoFactory = class(TInterfacedObject, iModelConexaoFactory)
  private

  public
    function Conexao: iModelConexao;
    function ConexaoSys: iModelConexao;
    function Query: iModelQuery;
    function belongsTo(ATableName, AForeignKey, ALocalKey: String): iModelQuery;

    Constructor Create;
    Destructor Destroy; override;
    class function New: TModelConexaoFactory;
  end;

implementation

{ TModelConexaoFactory }

function TModelConexaoFactory.belongsTo(ATableName, AForeignKey,
  ALocalKey: String): iModelQuery;

begin
//  Result := TModelConexaoADOQuery.New(Self.Conexao);
//  Result.TableName := ATableName;
//  Result.Select(['*']);
//  Result.LeftJoin(ATableName, AForeignKey, '=', ALocalKey)
//  .Where(AForeignKey, Query.Query.FieldByName('IdCliente').AsInteger)
//  .Get;
end;

function TModelConexaoFactory.Conexao: iModelConexao;
begin
  Result := TModelConexaoADOConecao.New;
end;

function TModelConexaoFactory.ConexaoSys: iModelConexao;
begin
  Result := TModelConexaoADOConecao.New;
end;

constructor TModelConexaoFactory.Create;
begin

end;

destructor TModelConexaoFactory.Destroy;
begin

  inherited;
end;

class function TModelConexaoFactory.New: TModelConexaoFactory;
begin
  Result := Self.Create;
end;

function TModelConexaoFactory.Query: iModelQuery;
begin
  Result := TModelConexaoADOQuery.New(Self.Conexao);
end;

end.
