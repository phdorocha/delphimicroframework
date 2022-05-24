unit Controller;

interface

uses
  // Próprias
  BaseController,
  // Delphi
  Classes, SysUtils, Generics.Collections, DB, DBClient;

type
  TControleControle = class(TBaseController)
  private
    { private declarations }
  protected
    { protected declarations }
  public
    { public declarations }
    Constructor Create(AOwner: TComponent); overload;
    Destructor Destroy; override;
  end;

implementation

  { TControllerControle }

Constructor TControleControle.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

end;

destructor TControleControle.Destroy;
begin

  inherited;
end;

end.
