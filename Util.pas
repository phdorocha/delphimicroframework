unit Util;

interface

uses
  IniFiles, Windows, SysUtils, Classes, DateUtils, MkDirMul
  {$IFDEF VER210}
    , Forms, StdCtrls, DBCtrls, Controls, Graphics;
  {$ELSE}
    , Vcl.Forms, Vcl.StdCtrls, Vcl.DBCtrls, Vcl.Controls, Vcl.Graphics;
  {$ENDIF}

const
  BARRA: String = '-------------------------------------------------------------------------------------------------------';

type
  TOperacao = (opeInsert, opeUpdate, opeNone);

  TUtil = Class
  public
    { Funções e procedimentos para arquivos INI e TXT }
    class function calcularNivelDependente(textoOrigem: String; adiciona : String): String;
    class function ReadIni(lcIni, lcSessao, lcSub: String): String;
    class function ReadIniBool(lcIni, lcSessao, lcSub: String): Boolean;
    class function ReadIniInt(lcIni, lcSessao, lcSub: String): Integer;
    class function ReadIniVer(lcIni, lcSessao, lcSub: String): String;
    class function ReadIniDateTime(lcIni, lcSessao, lcSub: String): TDateTime;
    class function TxtFileBD: String;
    class function TxtFileLog: String;
    class function TxtFileOpenCat: String;
    class function TxtIntegracaoLog: String;
    class function IniFile: String;
    class function IniVer: String;
    class function IniFileServer: String;
    class function IniFilePDV: String;
    class function IniFileChq: String;
    class function IniFileOpenCart: String;
    class function TxtFileKey: String;
    class procedure WriteTxtBD(lcTxt, lcValor: String);
    class procedure WriteTxtSys(lcTxt, lcValor: String);
    class procedure WriteIniVer(lcIni, lcSessao, lcSub, lcValor: String);
    class procedure WriteIni(lcIni, lcSessao, lcSub, lcValor: String);
    class procedure WriteIniBoo(lcIni, lcSessao, lcSub: String; lcValor: Boolean);
    class procedure WriteIniDateTime(lcIni, lcSessao, lcSub: String; lcValor: TDateTime);

    { Funções e procedimentos diversos }
    class procedure RegraNeg(tpMov, tpReceita, tpDespesa: String; valor1, valor2: Currency);
    class function EnDeCripta(Texto: String; Chave: Word) : String;
    class function Criptografar(wStri: String): String;
    class function Decriptografar(wStri: String): String;
    class function GetFileDate(Arquivo: String): TDateTime;

    class function CaminhoExe: String;
    class function CaminhoTmp: String;
    class function RetornaKiloBytes(ValorAtual: real): string;
    class function RetornaPorcentagem(ValorMaximo, ValorAtual: real): string;
    class function ComparaHora(Primeira, Segunda: String): boolean;
    class function ComparaTexto(Primeira, Segunda: String): boolean;
    class function EliminaPonto(Valor: string): String;
    class function SoNumero(Texto: String): String;
    class function IsDigit(Texto: string): Boolean;
    class procedure ConfirmaExclusao();
    class procedure GravaLog(const Msg: String; Acao: Integer = 1);
    class function SysSystemDir: string;
    class function ConverteData(Data:TDate) : String;
  end;

var  
    hPackage: Cardinal;

implementation

uses Constants;

{ TUtil }

class function TUtil.TxtFileLog: String;
var
  FileName: String;
begin
  FileName := ChangeFileExt(Application.ExeName, '.log');
  result := FileName;
end;

class function TUtil.TxtFileOpenCat: String;
var
  FileName: String;
begin
  FileName := ChangeFileExt('ExportaOpencart', '.log');
  result := FileName;
end;

class function TUtil.TxtIntegracaoLog: String;
var
  FileName: String;
begin
  FileName := ChangeFileExt('EasyIntegracaoXML', '.log');
  result := FileName;
end;

class function TUtil.CaminhoExe: String;
begin
  result := ExtractFilePath(Application.ExeName);
end;

class function TUtil.CaminhoTmp: String;
begin
  result := ReadIni(IniFile,INI_SESSAO_CONFIG,INI_PATHTMP);
end;

class function TUtil.TxtFileBD: String;
var
  FileName: String;
begin
  FileName := ChangeFileExt (Application.ExeName, '-BD.log');
  result := ExtractFilePath(Application.ExeName)+FileName;
end;

class function TUtil.TxtFileKey: String;
var
  FileName: String;
begin
  FileName := ChangeFileExt('Cliente.key', '.key');
  result := FileName;
end;

class function TUtil.IniVer: String;
begin
  result := CaminhoExe + 'tmp\ver.ini';
end;

class function TUtil.IniFile: String;
begin
  result := ExtractFilePath(Application.ExeName) + 'Config.ini';
end;

class function TUtil.IniFilePDV: String;
begin
  result := ExtractFilePath(Application.ExeName) + 'PDV.ini';
end;

class function TUtil.IniFileChq: String;
begin
  result := ExtractFilePath(Application.ExeName) + 'chq.ini';
end;

class function TUtil.IniFileOpenCart: String;
begin
  result := ExtractFilePath(Application.ExeName) + 'OpenCart.ini';
end;

class function TUtil.ReadIni(lcIni, lcSessao, lcSub: String): String;
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

class function TUtil.ReadIniBool(lcIni, lcSessao, lcSub: String): Boolean;
var
  loINI: TIniFile;
begin
  loINI := TIniFile.Create(lcIni);
  try
    result := loINI.ReadBool(lcSessao, lcSub, True);
  finally
    FreeAndNil(loINI);
  end;
end;

class function TUtil.ReadIniDateTime(lcIni, lcSessao, lcSub: String): TDateTime;
var
  loINI: TIniFile;
begin
  loINI := TIniFile.Create(lcIni);
  try
    result := loINI.ReadDateTime(lcSessao, lcSub, Now);
  finally
    FreeAndNil(loINI);
  end;
end;

class function TUtil.ReadIniInt(lcIni, lcSessao, lcSub: String): Integer;
var
  loINI: TIniFile;
begin
  loINI := TIniFile.Create(lcIni);

  try
    result := loINI.ReadInteger(lcSessao, lcSub, 0);
  finally
    FreeAndNil(loINI);
  end;
end;

class procedure TUtil.WriteTxtBD(lcTxt, lcValor: String);
Var
  FileName: String;
  LogFile: TextFile;
begin
// prepara arquivo de registro de ocorrência (log)
  FileName := ChangeFileExt (Application.ExeName, '-BD.log');
  AssignFile  (LogFile, FileName);
  If FileExists (FileName) then
    Append (LogFile) // abre o arquivo
  else
    ReWrite(LogFile); //cria novo
    // grava no arquivo e exibe o erro
    Writeln(LogFile, lcValor);
    //fecha o arquivo
    CloseFile(LogFile);
end;

class procedure TUtil.WriteIni(lcIni, lcSessao, lcSub, lcValor: String);
var
  loINI: TIniFile;
begin
  loINI := TIniFile.Create(lcIni);
  try
    loINI.WriteString(lcSessao, lcSub, lcValor);
  finally
    FreeAndNil(loINI);
  end;
end;

class procedure TUtil.WriteIniBoo(lcIni, lcSessao, lcSub: String;
  lcValor: Boolean);
var
  loINI: TIniFile;
begin
  loINI := TIniFile.Create(lcIni);
  try
    loINI.WriteBool(lcSessao, lcSub, lcValor);
  finally
    FreeAndNil(loINI);
  end;
end;

class procedure TUtil.WriteIniDateTime(lcIni, lcSessao, lcSub: String;
  lcValor: TDateTime);
var
  loINI: TIniFile;
begin
  loINI := TIniFile.Create(lcIni);
  try
    loINI.WriteDateTime(lcSessao, lcSub, lcValor);
  finally
    FreeAndNil(loINI);
  end;
end;

class procedure TUtil.WriteTxtSys(lcTxt, lcValor: String);
Var
  FileName: String;
  LogFile: TextFile;
begin              
// prepara arquivo de registro de ocorrência (log)
  FileName := lcTxt;
  AssignFile  (LogFile, FileName);
  If FileExists (FileName) then
    Append (LogFile) // abre o arquivo
  else
    ReWrite(LogFile); //cria novo
    // grava no arquivo e exibe o erro
    Writeln(LogFile, lcValor);
    //fecha o arquivo
    CloseFile(LogFile);
end;

class function TUtil.ReadIniVer(lcIni, lcSessao, lcSub: String): String;
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

class procedure TUtil.WriteIniVer(lcIni, lcSessao, lcSub, lcValor: String);
var
  loINI: TIniFile;
begin
  loINI := TIniFile.Create(lcIni);
  try
    loINI.WriteString(lcSessao, lcSub, lcValor);
  finally
    FreeAndNil(loINI);
  end;
end;

class function TUtil.EnDeCripta(Texto: String; Chave: Word): String;
var
  I: Integer;
  Saida: String;
begin
  Saida := '';
  For I := 1 to Length (Texto) do
    Saida := Saida + Char ( Not ( Ord ( Texto[I] ) - Chave ) );
  Result := Saida;
end;

class function TUtil.GetFileDate(Arquivo: String): TDateTime;
var
  FHandle: integer;
begin
  FHandle := FileOpen(Arquivo, 0);

  try
    Result := FileDateToDateTime(FileGetDate(FHandle));
  finally
    FileClose(FHandle);
  end;
end;

class procedure TUtil.GravaLog(const Msg: String; Acao: Integer = 1);
var
  FileName,newFileName,APath,ALogName: String;
  LogFile: TextFile;
  ADateFile: TDateTime;
begin
// prepara arquivo de registro de ocorrência (log)
  FileName := ChangeFileExt(ExtractFileName(Application.ExeName),'');
  APath := ExtractFilePath(Application.ExeName) + 'Logs\';

  if not DirectoryExists(APath) then
    MkSubDir(APath);

  ALogName := APath + FileName + '.log';

  newFileName := APath + FileName;
  newFileName := newFileName+FormatDateTime('yyyymmdd',Date)+'.log';

  if FileExists(ALogName) then
  begin
    ADateFile := GetFileDate(ALogName);

    if (FormatDateTime('yyyymmdd',ADateFile) <> FormatDateTime('yyyymmdd',Date)) then
      RenameFile(ALogName,newFileName);
  end;

  AssignFile(LogFile, ALogName);

  If FileExists(ALogName) then
    Append (LogFile) // abre o arquivo
  else
    ReWrite(LogFile); //cria novo

    // grava no arquivo e exibe o erro
    Case Acao of
    0:
    begin
      Writeln(LogFile, BARRA);
      Writeln(LogFile, 'Data/Hora: '+DateTimeToStr(Now));
      Writeln(LogFile, Msg);
       Writeln(LogFile, BARRA);
    end;
    1:
    begin
      Writeln(LogFile, Msg);
    end;
    else
    begin
      Writeln(LogFile, BARRA);
      Writeln(LogFile, Msg);
      Writeln(LogFile, 'Fim da execução!');
      Writeln(LogFile, BARRA);
    end;
  end;

  //fecha o arquivo
  CloseFile(LogFile);
end;

class function TUtil.ComparaHora(Primeira, Segunda: String): boolean;
var
Prim,Segu : TDateTime;
begin
  Prim := StrToTime(Primeira);
  Segu := StrToTime(Segunda);

  If (Prim = Segu) then
    Result := true
  else
    Result := false;
end;

class function TUtil.ComparaTexto(Primeira, Segunda: String): boolean;
var
Prim,Segu : String;
begin
  Prim := AnsiUpperCase(Primeira);
  Segu := AnsiUpperCase(Segunda);

  If (Prim = Segu) then
    Result := true
  else
    Result := false;
end;

class procedure TUtil.RegraNeg(tpMov, tpReceita, tpDespesa: String; valor1, valor2: Currency);
begin

end;

class function TUtil.RetornaKiloBytes(ValorAtual: real): string;
var
  resultado : real;
begin
  result := '0 KBs';
  resultado := 0;

  try
    try
      resultado := ((ValorAtual / 1024) / 1024);
      Result := FormatFloat('0.000 KBs', resultado);
    except
      on EDivByZero do
        resultado := 0;
      on EAccessViolation do
        resultado := 0;
    end;
  finally
    Result := FormatFloat('0.000 KBs', resultado);
  end;
end;

class function TUtil.RetornaPorcentagem(ValorMaximo, ValorAtual: real): string;
var
  resultado: Real;
begin
  if ValorMaximo > 0 then
  begin
    try
      resultado := ((ValorAtual * 100) / ValorMaximo);
      Result := FormatFloat('0%', resultado);
    except
      on EDivByZero do
        Result := '0%';
    end;
  end else begin
    Result := '0%';
  end;
end;

class function TUtil.IniFileServer: String;
begin
  result := ExtractFilePath(Application.ExeName) + 'ServerConfig.ini';
end;

class function TUtil.calcularNivelDependente(textoOrigem,
  adiciona: String): String;
var
  nivel      : array [0..20] of integer;
  i, nivelC  : SmallInt;
  niveisTxt  : TStringList;
  saida      : String;
begin
  i := 0;
  niveisTxt := TStringList.Create;
  for i := 0 to 20 do
    nivel[i] := -1;
  try
    niveisTxt.Text := StringReplace(textoOrigem, '.', #13, [rfReplaceAll, rfIgnoreCase]);
    for i := 0 to niveisTxt.Count - 2 do
    begin
      nivel[i] := StrToInt(niveisTxt.Strings[i]);
      nivelC := i;
    end;

    if adiciona = '=' then
      if nivel[nivelC + 1] = -1 then
        nivel[nivelC + 1] := 1;

    if adiciona = '+' then
      if nivel[nivelC] = -1 then
        nivel[nivelC] := 1
      else
        nivel[nivelC] := nivel[nivelC] + 1;

    if adiciona = '=' then
      for i := 0 to nivelC + 1 do
        saida := saida + IntToStr(nivel[i]) + '.';

    if adiciona = '+' then
      for i := 0 to nivelC do
        saida := saida + IntToStr(nivel[i]) + '.';

    Result := saida;
  finally
    niveisTxt.Free;
  end;
end;

class function TUtil.EliminaPonto(Valor: string): String;
 var i:integer;
begin
  if Valor <> '' then
    Result := StringReplace(valor,'.','',[rfReplaceAll]);
end;

class function TUtil.SoNumero(Texto: String): String;
var
  Ind    : Integer;
  TmpRet : String;
begin
  TmpRet := '';

  for Ind := 1 to Length(Texto) do
  begin
    if IsDigit(Copy(Texto,Ind,1)) then
      begin
        TmpRet := TmpRet + Copy(Texto, Ind, 1);
      end;
  end;

  Result := TmpRet;
end;

class function TUtil.SysSystemDir: string;
begin
  SetLength(Result, MAX_PATH);

  if GetSystemDirectory(PChar(Result), MAX_PATH) > 0 then
    Result := string(PChar(Result))
  else
   Result := 'C:\Windows\System32';
end;

class function TUtil.IsDigit(Texto: string): Boolean;
begin
  result := true;
 try
    StrToInt(Texto);
 except
    result := false;
 end;
end;

class function TUtil.Criptografar(wStri: String): String;
var
  Simbolos : array [0..4] of String;
  x: Integer;
begin
  Simbolos[1]:='ABCDEFGHIJLMNOPQRSTUVXZYWK ~!@#$%^&*()';

  Simbolos[2]:='ÂÀ©Øû×ƒçêùÿ5Üø£úñÑªº¿®¬¼ëèïÙýÄÅÉæÆôöò»Á';

  Simbolos[3]:='abcdefghijlmnopqrstuvxzywk1234567890';

  Simbolos[4]:='áâäàåíóÇüé¾¶§÷ÎÏ-+ÌÓß¸°¨·¹³²Õµþîì¡«½';

  for x := 1 to Length(Trim(wStri)) do begin
     if pos(copy(wStri,x,1),Simbolos[1])>0 then
        Result := Result+copy(Simbolos[2],
                      pos(copy(wStri,x,1),Simbolos[1]),1)

     else if pos(copy(wStri,x,1),Simbolos[2])>0 then
        Result := Result+copy(Simbolos[1],
                      pos(copy(wStri,x,1),Simbolos[2]),1)

     else if pos(copy(wStri,x,1),Simbolos[3])>0 then
        Result := Result+copy(Simbolos[4],
                      pos(copy(wStri,x,1),Simbolos[3]),1)

     else if pos(copy(wStri,x,1),Simbolos[4])>0 then
        Result := Result+copy(Simbolos[3],
                      pos(copy(wStri,x,1),Simbolos[4]),1);
  end;
end;

class function TUtil.Decriptografar(wStri: String): String;
begin
  result := Criptografar(wStri);
end;

class procedure TUtil.ConfirmaExclusao();
begin
  If Application.MessageBox('Deseja realmente excluir este registro?','Confirme',
    MB_YESNO + MB_ICONQUESTION + MB_DEFBUTTON2) = IDNO then
    Abort;
end;

class function TUtil.ConverteData(Data: TDate): String;
begin
  Result := IntToStr(YearOf(Data)) + '/' + IntToStr(MonthOf(Data)) + '/' + IntToStr(DayOf(data));
end;

end.

