unit Model.Conexao.ADO.Query;

interface

uses
{$REGION 'Próprias'}
  Builder,
  Methods,
  Easy.DB.Helper,
{$ENDREGION}
{$REGION 'Delphi'}
  System.JSON,
  System.Variants, System.SysUtils,
  Data.Win.ADODB, Data.DB;
{$ENDREGION}

Type
  TModelConexaoADOQuery = class(TInterfacedObject, iModelQuery)
  private
    FQuery: TADODataSet;
    FConexao: iModelConexao;
    FTableName: string;
    FPrimaryKey: string;
    FJoin: TArray<String>;
    FColumns: TArray<String>;
    FFillable: TArray<string>;
    FLeftJoins: array of array [1..3] of String;
    FRightJoins: array of array [1..3] of String;
    FInnerJoins: array of array [1..3] of String;
    FWheres: TArray<String>;
    FHavings: TArray<String>;
    FOrderBys: TArray<String>;
    FGroupBys: TArray<String>;

    function GetTableName: string;
    procedure SetTableName(const Value: string);
    function GetPrimaryKey: string;
    procedure SetPrimaryKey(const Value: string);
    function newQuery: string;
    function firstSQL: string;

  public
    property TableName: string read GetTableName write SetTableName;
    property PrimaryKey: string read GetPrimaryKey write SetPrimaryKey;
    Constructor Create(AValue: iModelConexao);
    Destructor Destroy; override;
    class function New(AValue: iModelConexao): iModelQuery;
    function belongsTo(ATableName, AForeignKey, ALocalKey: String): iModelQuery;

    function OpenTable(ATable: String): iModelQuery;
    function Open(aSQL : String) : iModelQuery;
    procedure ToJsonArray(var pJsonArray: TJsonArray; const pIncludeNullFields: Boolean = False);
    function LeftJoin(AJoin, AForKey, AOperator, APrimaryKey: String): iModelQuery;
    function RightJoin(AJoin, AForKey, AOperator, APrimaryKey: String): iModelQuery;
    function InnerJoin(AJoin, AForKey, AOperator, APrimaryKey: String): iModelQuery;
    function ExecSQL(ASQL : String) : iModelQuery;
    function Select(AColumns: Array of string): iModelQuery;
    function Where(AColumn, AOperator: String; AValue: Variant): iModelQuery; overload;
    function Where(AColumn: String; AValue: Variant): iModelQuery; overload;
    function Having(AColumn, AOperator: String; AValue: Variant): iModelQuery;
    function GroupBy(AColumns: Array of string): iModelQuery;
    function OrderBy(AColumn: String; AType: String = ''): iModelQuery;
    function Raw(ASQLCommand: String): iModelQuery;
    function Get: iModelQuery; overload;
    function Get(AID: Integer): iModelQuery; overload;
    function First(AColumns: Array of string): iModelQuery;
  end;

implementation

{ TModelCoenxaoFiredacQuery }

function TModelConexaoADOQuery.belongsTo(ATableName, AForeignKey,
  ALocalKey: String): iModelQuery;
begin
  LeftJoin(ATableName, AForeignKey, '=', ALocalKey)
end;

Constructor TModelConexaoADOQuery.Create(AValue: iModelConexao);
begin
  FConexao := AValue;
  FQuery   := TADODataSet.Create(NIL);
  FQuery.Connection := TADOConnection(FConexao.Connection);
  setlength(FInnerJoins, 0); // inicializa o array Inner Join
end;

destructor TModelConexaoADOQuery.Destroy;
begin
  FreeAndNil(FQuery);

  inherited;
end;

function TModelConexaoADOQuery.ExecSQL(ASQL : String) : iModelQuery;
var
  LComand: TADOCommand;
begin
  Result := Self;
  LComand := TADOCommand.Create(NIL);

  try
    LComand.CommandText := ASQL;
    try
      LComand.Execute;
    except
      raise Exception.Create('Erro ao executar Script SQL');
    end;
  finally
    FreeAndNil(LComand);
  end;
end;

function TModelConexaoADOQuery.First(AColumns: Array of string): iModelQuery;
var
  LIndex,
  LCountAtual: Integer;
begin
  Result := Self;
  LCountAtual := Length(Self.FColumns);

  if ((Length(AColumns)+LCountAtual) >0) then
  begin
    SetLength(Self.FColumns, LCountAtual+Length(AColumns));

    for LIndex := 0 to Length(AColumns)-1 do
      Self.FColumns[LIndex+LCountAtual] := AColumns[LIndex];
  end else
    Self.FColumns := ['*'];

  FQuery.Active := False;

  if not FQuery.Connection.Connected then
    FQuery.Connection.Open;

  FQuery.CommandText := firstSQL;

  try
    FQuery.Open;
  except
    on e: exception do
      Assert(
        False,
        'Erro ao abrir tabela: ' + e.Message + sLineBreak
        +'Classe: ' + e.ClassName.QuotedString
      );
  end;
end;

function TModelConexaoADOQuery.firstSQL: string;
var
  LOrderBy, LWhere,
  LHaving, LWith,
  LLeftJoin, LInnerJoin,
  LGroupBy,
  sQuery, Str: String;
  I: Integer;
begin
  sQuery := 'SELECT TOP 1, ';

  {$REGION 'Atribui as Colunas da tabela'}
  for I := Low(Self.FColumns) to High(Self.FColumns) do
  begin
    if I = 0 then // se primeira coluna, não coloca vírgula
      sQuery := sQuery + Self.FColumns[I]
    else
      sQuery := sQuery + ' ,' + Self.FColumns[I];
  end;
  {$ENDREGION}

  {$REGION 'Left Join'}
  if Length(Self.FLeftJoins) = 1 then
  begin
    LLeftJoin := format('LEFT JOIN %s ON %s.%s = %s.%s',[FLeftJoins[0,1],TableName,FLeftJoins[0,3],FLeftJoins[0,1],FLeftJoins[0,2]]);
  end else
    if Length(Self.FLeftJoins) = 2 then
    begin
      LLeftJoin := format(
        'LEFT JOIN (%s LEFT JOIN %s'+
        ' ON %s.%s = %s.%s)'+
        ' ON %s.%s = %s.%s',
        [FLeftJoins[0,1], FLeftJoins[1,1],
        FLeftJoins[0,1], FLeftJoins[0,3], FLeftJoins[1,1], FLeftJoins[0,2],
        TableName, FLeftJoins[1,2], FLeftJoins[1,1], FLeftJoins[1,3]]
      );
    end;
  {$ENDREGION}

  {$REGION 'Right Join'}
  if Length(Self.FRightJoins) = 1 then
  begin
    LLeftJoin := format('LEFT JOIN %s ON %s.%s = %s.%s',[FRightJoins[0,1],TableName,FRightJoins[0,3],FRightJoins[0,1],FRightJoins[0,2]]);
  end else
    if Length(Self.FRightJoins) = 2 then
    begin
      LLeftJoin := format(
        'LEFT JOIN (%s RIGHT JOIN %s'+
        ' ON %s.%s = %s.%s)'+
        ' ON %s.%s = %s.%s',
        [FRightJoins[0,1], FRightJoins[1,1],
        FRightJoins[0,1], FRightJoins[0,3], FRightJoins[1,1], FRightJoins[0,2],
        TableName, FRightJoins[1,2], FRightJoins[1,1], FRightJoins[1,3]]
      );
    end;
  {$ENDREGION}

  {$REGION 'Inner Join'}
  if Length(Self.FInnerJoins) = 1 then
  begin
    LInnerJoin := format('INNER JOIN %s ON %s.%s = %s.%s',[FInnerJoins[0,1],TableName,FInnerJoins[0,3],FInnerJoins[0,1],FInnerJoins[0,2]]);
  end else
    if Length(Self.FInnerJoins) = 2 then
    begin
      LInnerJoin := format(
        'INNER JOIN (%s INNER JOIN %s'+
        ' ON %s.%s = %s.%s)'+
        ' ON %s.%s = %s.%s',
        [FInnerJoins[0,1], FInnerJoins[1,1],
        FInnerJoins[0,1], FInnerJoins[0,3], FInnerJoins[1,1], FInnerJoins[0,2],
        TableName, FInnerJoins[1,2], FInnerJoins[1,1], FInnerJoins[1,3]]
      );
    end;
  {$ENDREGION}

  {$REGION 'Wheres conditions'}
  for I := Low(Self.FWheres) to High(Self.FWheres) do
  begin
    if I = 0 then
      LWhere := LWhere + Self.FWheres[I]
    else
      LWhere := LWhere + ' AND ' + Self.FWheres[I];
  end;
  {$ENDREGION}

  {$REGION 'Havings Conditions'}
  for I := Low(Self.FHavings) to High(Self.FHavings) do
  begin
    if I = 0 then
      LHaving := LHaving + Self.FHavings[I]
    else
      LHaving := LHaving + ' AND ' + Self.FHavings[I];
  end;
  {$ENDREGION}

  {$REGION 'Gourps By'}
  for I := Low(Self.FGroupBys) to High(Self.FGroupBys) do
  begin
    if I = 0 then // se primeira coluna, não coloca vírgula
      LGroupBy := LGroupBy + Self.FGroupBys[I]
    else
      LGroupBy := LGroupBy + ' ,' + Self.FGroupBys[I];
  end;
  {$ENDREGION}

  {$REGION 'Orders By'}
  for I := Low(Self.FOrderBys) to High(Self.FOrderBys) do
  begin
    if I = 0 then
      LOrderBy := LOrderBy + Self.FOrderBys[I]
    else
      LOrderBy := LOrderBy + ' AND ' + Self.FOrderBys[I];
  end;
  {$ENDREGION}

  {$REGION 'Incrementa Tabel, Where, Order By e Join'}
  sQuery := Trim(sQuery) + ' FROM ' + Self.TableName
    + IfThen(IsEmpty(Trim(LLeftJoin)), '', ' ' + Trim(LLeftJoin))
    + IfThen(IsEmpty(Trim(LInnerJoin)), '', ' ' + Trim(LInnerJoin))
    + IfThen(IsEmpty(Trim(LWhere)), '', ' WHERE ' + Trim(LWhere))
    + IfThen(IsEmpty(Trim(LGroupBy)), '', ' GROUP BY ' + Trim(LGroupBy))
    + IfThen(IsEmpty(Trim(LHaving)), '', ' HAVING ' + Trim(LHaving))
    + IfThen(IsEmpty(Trim(LOrderBy)), '', ' ORDER BY ' + LOrderBy) + IfThen
    (IsEmpty(Trim(LWith)), '', LWith);
  {$ENDREGION}

  Result := Trim(sQuery);
end;

function TModelConexaoADOQuery.Get: iModelQuery;
begin
  Result := Self;

  if Length(FColumns) = 0 then
    FColumns := ['*'];

  FQuery.Active := False;

  if not FQuery.Connection.Connected then
    FQuery.Connection.Open;

  FQuery.CommandText := newQuery;

  try
    FQuery.Open;
  except
    on e: exception do
      Assert(
        False,
        'Erro ao abrir tabela: ' + e.Message + sLineBreak
        +'Classe: ' + e.ClassName.QuotedString
      );
  end;
end;

function TModelConexaoADOQuery.Get(AID: Integer): iModelQuery;
begin
  Result := Self;

  if Length(FColumns) = 0 then
    FColumns := ['*'];

  Self.Where(PrimaryKey,AID);
  FQuery.CommandText := newQuery;
  FQuery.Open;
end;

function TModelConexaoADOQuery.GetPrimaryKey: string;
begin
  Result := Self.FPrimaryKey;
end;

function TModelConexaoADOQuery.GetTableName: string;
begin
  result := Self.FTableName;
end;

function TModelConexaoADOQuery.GroupBy(AColumns: array of string): iModelQuery;
var
  I: Integer;
begin
  SetLength(Self.FGroupBys, Length(AColumns));

  for I := 0 to Length(AColumns)-1 do
    Self.FGroupBys[i] := AColumns[i];
end;

function TModelConexaoADOQuery.Having(AColumn, AOperator: String; AValue: Variant): iModelQuery;
begin
  Result := Self;

  if Length(Trim(AOperator)) = 0 then
    AOperator := '=';

  if VarIsClear(AValue) or VarIsEmpty(AValue) then
    AValue := '"%%"'
  else
    if VarIsBoolean(AValue) then
      AValue := BoolToStr(AValue)
    else
      if VarIsStr(AValue) then
        AValue := '"' + AValue + '"'
      else
        if VarIsNumeric(AValue) then
          AValue := FloatToStr(AValue);

  SetLength(FHavings, Length(FHavings)+1);
  FHavings[High(FHavings)] := AColumn +' '+ AOperator +' '+ AValue;
end;

function TModelConexaoADOQuery.InnerJoin(AJoin, AForKey, AOperator, APrimaryKey: String): iModelQuery;
var
  LLinha: Integer;
begin
  Result := Self;

  if Length(Trim(AOperator)) = 0 then
    AOperator := '=';

  LLinha := Length(FInnerJoins);
  SetLength(FInnerJoins, LLinha+1); // Incrementa o array
  LLinha := high(FInnerJoins);

  FInnerJoins[LLinha][1] := AJoin;
  FInnerJoins[LLinha][2] := AForKey;
  FInnerJoins[LLinha][3] := APrimaryKey;
end;

function TModelConexaoADOQuery.LeftJoin(AJoin, AForKey, AOperator, APrimaryKey: String): iModelQuery;
var
  LLinha: Integer;
begin
  Result := Self;

  if Length(Trim(AOperator)) = 0 then
    AOperator := '=';

  LLinha := Length(FLeftJoins);
  SetLength(FLeftJoins, LLinha+1); // Incrementa o array
  LLinha := high(FLeftJoins);

  FLeftJoins[LLinha][1] := AJoin;
  FLeftJoins[LLinha][2] := AForKey;
  FLeftJoins[LLinha][3] := APrimaryKey;
end;

class function TModelConexaoADOQuery.New(AValue: iModelConexao): iModelQuery;
begin
  Result := Self.Create(AValue);
end;

function TModelConexaoADOQuery.newQuery: string;
var
  LOrderBy, LWhere,
  LHaving, LWith,
  LLeftJoin, LInnerJoin,
  LGroupBy,
  sQuery, Str: String;
  I: Integer;
begin
  sQuery := 'SELECT ';

  {$REGION 'Atribui as Colunas da tabela'}
  for I := Low(Self.FColumns) to High(Self.FColumns) do
  begin
    if I = 0 then // se primeira coluna, não coloca vírgula
      sQuery := sQuery + Self.FColumns[I]
    else
      sQuery := sQuery + ' ,' + Self.FColumns[I];
  end;
  {$ENDREGION}

  {$REGION 'Left Join'}
  if Length(Self.FLeftJoins) = 1 then
  begin
    LLeftJoin := format('LEFT JOIN %s ON %s.%s = %s.%s',[FLeftJoins[0,1],TableName,FLeftJoins[0,3],FLeftJoins[0,1],FLeftJoins[0,2]]);
  end else
    if Length(Self.FLeftJoins) = 2 then
    begin
      LLeftJoin := format(
        'LEFT JOIN (%s LEFT JOIN %s'+
        ' ON %s.%s = %s.%s)'+
        ' ON %s.%s = %s.%s',
        [FLeftJoins[0,1], FLeftJoins[1,1],
        FLeftJoins[0,1], FLeftJoins[0,3], FLeftJoins[1,1], FLeftJoins[0,2],
        TableName, FLeftJoins[1,2], FLeftJoins[1,1], FLeftJoins[1,3]]
      );
    end;
  {$ENDREGION}

  {$REGION 'Right Join'}
  if Length(Self.FRightJoins) = 1 then
  begin
    LLeftJoin := format('LEFT JOIN %s ON %s.%s = %s.%s',[FRightJoins[0,1],TableName,FRightJoins[0,3],FRightJoins[0,1],FRightJoins[0,2]]);
  end else
    if Length(Self.FRightJoins) = 2 then
    begin
      LLeftJoin := format(
        'LEFT JOIN (%s RIGHT JOIN %s'+
        ' ON %s.%s = %s.%s)'+
        ' ON %s.%s = %s.%s',
        [FRightJoins[0,1], FRightJoins[1,1],
        FRightJoins[0,1], FRightJoins[0,3], FRightJoins[1,1], FRightJoins[0,2],
        TableName, FRightJoins[1,2], FRightJoins[1,1], FRightJoins[1,3]]
      );
    end;
  {$ENDREGION}

  {$REGION 'Inner Join'}
  if Length(Self.FInnerJoins) = 1 then
  begin
    LInnerJoin := format('INNER JOIN %s ON %s.%s = %s.%s',[FInnerJoins[0,1],TableName,FInnerJoins[0,3],FInnerJoins[0,1],FInnerJoins[0,2]]);
  end else
    if Length(Self.FInnerJoins) = 2 then
    begin
      LInnerJoin := format(
        'INNER JOIN (%s INNER JOIN %s'+
        ' ON %s.%s = %s.%s)'+
        ' ON %s.%s = %s.%s',
        [FInnerJoins[0,1], FInnerJoins[1,1],
        FInnerJoins[0,1], FInnerJoins[0,3], FInnerJoins[1,1], FInnerJoins[0,2],
        TableName, FInnerJoins[1,2], FInnerJoins[1,1], FInnerJoins[1,3]]
      );
    end;
  {$ENDREGION}

  {$REGION 'Wheres conditions'}
  for I := Low(Self.FWheres) to High(Self.FWheres) do
  begin
    if I = 0 then
      LWhere := LWhere + Self.FWheres[I]
    else
      LWhere := LWhere + ' AND ' + Self.FWheres[I];
  end;
  {$ENDREGION}

  {$REGION 'Havings Conditions'}
  for I := Low(Self.FHavings) to High(Self.FHavings) do
  begin
    if I = 0 then
      LHaving := LHaving + Self.FHavings[I]
    else
      LHaving := LHaving + ' AND ' + Self.FHavings[I];
  end;
  {$ENDREGION}

  {$REGION 'Gourps By'}
  for I := Low(Self.FGroupBys) to High(Self.FGroupBys) do
  begin
    if I = 0 then // se primeira coluna, não coloca vírgula
      LGroupBy := LGroupBy + Self.FGroupBys[I]
    else
      LGroupBy := LGroupBy + ' ,' + Self.FGroupBys[I];
  end;
  {$ENDREGION}

  {$REGION 'Orders By'}
  for I := Low(Self.FOrderBys) to High(Self.FOrderBys) do
  begin
    if I = 0 then
      LOrderBy := LOrderBy + Self.FOrderBys[I]
    else
      LOrderBy := LOrderBy + ' AND ' + Self.FOrderBys[I];
  end;
  {$ENDREGION}

  {$REGION 'Incrementa Tabel, Where, Order By e Join'}
  sQuery := Trim(sQuery) + ' FROM ' + Self.TableName
    + IfThen(IsEmpty(Trim(LLeftJoin)), '', ' ' + Trim(LLeftJoin))
    + IfThen(IsEmpty(Trim(LInnerJoin)), '', ' ' + Trim(LInnerJoin))
    + IfThen(IsEmpty(Trim(LWhere)), '', ' WHERE ' + Trim(LWhere))
    + IfThen(IsEmpty(Trim(LGroupBy)), '', ' GROUP BY ' + Trim(LGroupBy))
    + IfThen(IsEmpty(Trim(LHaving)), '', ' HAVING ' + Trim(LHaving))
    + IfThen(IsEmpty(Trim(LOrderBy)), '', ' ORDER BY ' + LOrderBy) + IfThen
    (IsEmpty(Trim(LWith)), '', LWith);
  {$ENDREGION}

  Result := Trim(sQuery);
end;

function TModelConexaoADOQuery.Open(aSQL: String): iModelQuery;
begin
  Result := Self;

  if not FQuery.Active then
    FQuery.Open;
end;

function TModelConexaoADOQuery.OpenTable(ATable: String): iModelQuery;
begin
  Result := Self;

  if FQuery.Active then
    FQuery.Close;

  FQuery.CommandText := 'SELECT * FROM ' + aTable;
  FQuery.Open;
end;

function TModelConexaoADOQuery.OrderBy(AColumn: String; AType: String = ''): iModelQuery;
begin
  result := Self;

  SetLength(FOrderBys, Length(FOrderBys)+1);
  FOrderBys[High(FOrderBys)] := AColumn + IfThen(AType = '', '',' '+ AType);
end;

function TModelConexaoADOQuery.Raw(ASQLCommand: String): iModelQuery;
begin
  Result := Self;

  FQuery.Active := False;

  if not FQuery.Connection.Connected then
    FQuery.Connection.Open;

  FQuery.CommandText := ASQLCommand;

  try
    FQuery.Open;
  except
    on e: exception do
      Assert(
        False,
        'Erro ao abrir tabela: ' + e.Message + sLineBreak +
        'Classe: ' + e.ClassName.QuotedString
      );
  end;
end;

function TModelConexaoADOQuery.RightJoin(AJoin, AForKey, AOperator,
  APrimaryKey: String): iModelQuery;
var
  LLinha: Integer;
begin
  Result := Self;

  if Length(Trim(AOperator)) = 0 then
    AOperator := '=';

  LLinha := Length(FRightJoins);
  SetLength(FRightJoins, LLinha+1); // Incrementa o array
  LLinha := high(FRightJoins);

  FRightJoins[LLinha][1] := AJoin;
  FRightJoins[LLinha][2] := AForKey;
  FRightJoins[LLinha][3] := APrimaryKey;
end;

function TModelConexaoADOQuery.Select(AColumns: Array of string): iModelQuery;
var
  LIndex,
  LCountAtual: Integer;
begin
  Result := Self;
  LCountAtual := Length(Self.FColumns);

  if ((Length(AColumns)+LCountAtual) >0) then
  begin
    SetLength(Self.FColumns, LCountAtual+Length(AColumns));

    for LIndex := 0 to Length(AColumns)-1 do
      Self.FColumns[LIndex+LCountAtual] := AColumns[LIndex];
  end else
    Self.FColumns := ['*'];
end;

procedure TModelConexaoADOQuery.SetPrimaryKey(const Value: string);
begin
  Self.FPrimaryKey := Value;
end;

procedure TModelConexaoADOQuery.SetTableName(const Value: string);
begin
  Self.FTableName := Value;
end;

procedure TModelConexaoADOQuery.ToJsonArray(var pJsonArray: TJsonArray; const pIncludeNullFields: Boolean);
begin
  FQuery.ToJsonArray(pJsonArray,pIncludeNullFields);
end;

function TModelConexaoADOQuery.where(AColumn, AOperator: String; AValue: Variant): iModelQuery;
begin
  Result := Self;

  if Length(Trim(AOperator)) = 0 then
    AOperator := '=';

  if VarIsClear(AValue) or VarIsEmpty(AValue) then
    AValue := '"%%"'
  else
    if VarIsBoolean(AValue) then
      AValue := BoolToStr(AValue)
    else
      if VarIsStr(AValue) then
        AValue := '"' + AValue + '"'
      else
        if VarIsNumeric(AValue) then
          AValue := FloatToStr(AValue);

  SetLength(FWheres, Length(FWheres)+1);
  FWheres[High(FWheres)] := AColumn +' '+ AOperator +' '+ AValue;
end;

function TModelConexaoADOQuery.where(AColumn: String; AValue: Variant): iModelQuery;
begin
  Result := Self;
  Where(AColumn, '=', AValue);
end;

end.
