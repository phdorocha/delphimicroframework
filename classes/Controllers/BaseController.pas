unit BaseController;

interface

uses
  Classes;

type
  TBaseController = class abstract (TComponent)
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

{ TBaseController }

constructor TBaseController.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

end;

destructor TBaseController.Destroy;
begin

  inherited;
end;

end.
