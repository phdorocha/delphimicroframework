unit Model.Conexao.ADO.Conexao;

{*
 * Classe de conexão usando ADO
 * Pode criar outtras classes semelhantes para uso de outros conectores como
 * FireDac, Zeos, UniDac, RestDataware e outros.
**
*}

interface

uses
{$REGION 'Próprias'}
  Contants,
  Builder,
{$ENDREGION}
{$REGION 'Delphi'}
  Data.DB, Data.Win.ADODB, System.IniFiles, System.SysUtils;
{$ENDREGION}

Type
  TModelConexaoADOConecao = class(TInterfacedObject, iModelConexao)
  private
    FConexao: TADOConnection;

    function ReadIni(lcIni, lcSessao, lcSub: String): String;
    function IniFileServer: String;
    function Criptografar(Value: String): String;
  public
    function Connection: TCustomConnection;

    Constructor Create;
    Destructor Destroy; override;
    class function New: iModelConexao;
  end;

implementation

{ TModelConexaoADOConecao }

function TModelConexaoADOConecao.Connection: TCustomConnection;
begin
  Result := FConexao;
end;

constructor TModelConexaoADOConecao.Create;
begin
  FConexao := TADOConnection.Create(nil);
  FConexao.LoginPrompt := False;
  FConexao.ConnectionString := 'Provider=Microsoft.Jet.OLEDB.4.0;'+
    'Data Source='+ ReadIni(IniFileServer, INI_SESSAO_CONEXAO, INI_BD) + ';'+
    'Jet OLEDB:Database Password='+Criptografar(ReadIni(IniFileServer, INI_SESSAO_CONEXAO, INI_PSWDB));
  FConexao.Connected := True;
end;

function TModelConexaoADOConecao.Criptografar(Value: String): String;
var
  Simbolos : array [0..4] of String;
  x: Integer;
begin
  Result := Value;
end;

destructor TModelConexaoADOConecao.Destroy;
begin
  FreeAndNil(FConexao);

  inherited;
end;

function TModelConexaoADOConecao.IniFileServer: String;
begin
  result := ExtractFilePath(ParamStr(0)) + 'ServerConfig.ini';
end;

class function TModelConexaoADOConecao.New: iModelConexao;
begin
  Result := Self.Create;
end;

function TModelConexaoADOConecao.ReadIni(lcIni, lcSessao, lcSub: String): String;
var
  loINI: TIniFile;
begin
  loINI := TIniFile.Create(lcIni);

  try
    result := loINI.ReadString(lcSessao, lcSub, '');
  finally
    FreeAndNil(loINI);
  end;
end;

end.
