program Demo;

uses
  Vcl.Forms,
  welcome in 'views\welcome.pas' {Form1},
  BaseController in 'classes\Controllers\BaseController.pas',
  Controller in 'classes\Controllers\Controller.pas',
  Easy.DB.Helper in 'helpers\Easy.DB.Helper.pas',
  Model in 'database\Model.pas',
  Builder in 'database\Builder.pas',
  Model.Conexao.ADO.Conexao in 'database\Model.Conexao.ADO.Conexao.pas',
  Contants in 'config\Contants.pas',
  Methods in 'database\Methods.pas',
  Model.Conexao.Factory in 'database\Model.Conexao.Factory.pas',
  Model.Conexao.ADO.Query in 'database\Model.Conexao.ADO.Query.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
