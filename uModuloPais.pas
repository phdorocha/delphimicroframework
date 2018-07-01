unit uModuloPais;

interface

uses
  // Próprias
  uIBuilderSQL,
  // Delphi
  Classes, SysUtils, Generics.Collections, DB, DBClient, ADODB;

type
  TModuloPais = class(TBuilderSQL, IBuilderSQL)
  private
    FID: Integer;
    FCPais: String;
    FNome: String;

    function TableName: string; override;
    function PrimaryKey: string; override;

    procedure setID(const Value: Integer);
    procedure setNome(const Value: String);
    procedure setCPais(const Value: String);
    function getID: Integer;
    function getNome: String;
    function getCPais: String;

  public
    property ID   : Integer read getID    write setID;
    property CPais: String  read getCPais write setCPais;
    property Nome : String  read getNome  write setNome;

    Constructor Create(AOwner: TComponent); overload;
    Constructor Create(
      AOwner: TComponent;
      AID   : Integer;
      ACPais: String;
      ANome : String
    ); overload; virtual;
    Destructor Destroy; override;
  end;

  TListaPaises = TObjectList<TModuloPais>;

  TPaisDAO = class(TModuloPais)
  private
    FPaisLista: TListaPaises;
    FADO: TADOConnection;
    FKeyID: Integer;
    cdsPais: TClientDataSet;

  public
    property Lista: TListaPaises read FPaisLista write FPaisLista;

    Constructor Create(AOwner: TComponent); overload;
    Constructor Create(
      AOwner: TComponent;
      AID   : Integer;
      ACPais: String;
      ANome : String
    ); overload; override;

    procedure setLista;
    procedure Locate(Column: String; Value: Variant);
    function CPaisPorNome(ANome: String): String;
    function JSON: String;
  end;

implementation

{ TModuloPais }

constructor TModuloPais.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

end;

constructor TModuloPais.Create(AOwner: TComponent; AID: Integer; ACPais: String;
  ANome: String);
begin
  inherited Create(AOwner);

  ID    := AID;
  CPais := ACPais;
  Nome  := ANome;
end;

destructor TModuloPais.Destroy;
begin

  inherited;
end;

function TModuloPais.getCPais: String;
begin
  result := FCPais;
end;

function TModuloPais.getID: Integer;
begin
  result := FID;
end;

function TModuloPais.getNome: String;
begin
  result := FNome;
end;

function TModuloPais.PrimaryKey: string;
begin
  Result := 'Id';
end;

procedure TModuloPais.setCPais(const Value: String);
begin
  FCPais := Value;
end;

procedure TModuloPais.setID(const Value: Integer);
begin
  FID := Value;
end;

procedure TModuloPais.setNome(const Value: String);
begin
  FNome := Value;
end;

function TModuloPais.TableName: string;
begin
  result := 'easyupdate.dbo.pais';
end;

{ TPaisDAO }

constructor TPaisDAO.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  SetLength(fillable, 3);
  fillable[0] := 'Id';
  fillable[1] := 'cPAis';
  fillable[2] := 'pais_nome';
end;

function TPaisDAO.CPaisPorNome(ANome: String): String;
begin
  self.Locate('pais_nome',ANome);
end;

constructor TPaisDAO.Create(AOwner: TComponent; AID: Integer; ACPais: String; ANome: String);
begin
  inherited Create(AOwner, AID, ACPais, ANome);

  SetLength(fillable, 3);
  fillable[0] := 'Id';
  fillable[1] := 'cPAis';
  fillable[2] := 'pais_nome';
end;

function TPaisDAO.JSON: String;
begin
  Result := self.JSONDataSet(self.fillable);
end;

procedure TPaisDAO.Locate(Column: String; Value: Variant);
begin
  if self.Lista = NIL then
    self.setLista;
  cdsPais.DisableControls;
  Assert(
    cdsPais.Locate(Column,Value,[loCaseInsensitive]),
    'Erro localizar país' + QuotedStr(self.ClassName) + sLineBreak
  );
  self.ID    := cdsPais.Fields[0].AsInteger;
  self.CPais := cdsPais.Fields[1].AsString;
  self.Nome  := cdsPais.Fields[2].AsString;
end;

procedure TPaisDAO.setLista;
var
  I: Integer;
begin
  if self.Lista = NIL then
    self.Lista := TObjectList<TModuloPais>.Create;
  try
    cdsPais := self.All(fillable);
    cdsPais.First;
    cdsPais.DisableControls;
    for I := 0 to cdsPais.RecordCount - 1 do
    begin
      self.Lista.Add(TModuloPais.Create(
        NIL,
        cdsPais.Fields[0].AsInteger,
        cdsPais.Fields[1].AsString,
        cdsPais.Fields[2].AsString
      ));
      cdsPais.Next;
    end;
  finally

  end;
end;

end.
