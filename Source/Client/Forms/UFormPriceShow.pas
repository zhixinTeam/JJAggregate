{*******************************************************************************
  作者: dmzn@163.com 2018-12-16
  描述: 查看价格清单
*******************************************************************************}
unit UFormPriceShow;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  UBusinessConst, UFormNormal, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, ComCtrls, cxContainer, cxListView,
  dxLayoutControl, StdCtrls;

type
  TfFormPriceShow = class(TfFormNormal)
    dxLayout1Item3: TdxLayoutItem;
    ListPrice: TcxListView;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
  protected
    { Protected declarations }
  public
    { Public declarations }
    class function FormID: integer; override;
  end;

procedure ShowPriceViewForm(const nPriceList: TStockTypeItems);
//入口函数

implementation

{$R *.dfm}
uses
  ULibFun, UMgrControl, USysDB, USysConst, UFormBase, USysGrid;

var
  gForm: TfFormPriceShow = nil;
  //xxxxx

procedure ShowPriceViewForm(const nPriceList: TStockTypeItems);
var nIdx: Integer;
begin
  if not Assigned(gForm) then
    gForm := TfFormPriceShow.Create(Application);
  //xxxxx

  with gForm do
  begin
    ListPrice.Items.BeginUpdate;
    try
      ListPrice.Items.Clear;
      for nIdx:=Low(nPriceList) to High(nPriceList) do
      with ListPrice.Items.Add,nPriceList[nIdx] do
      begin
        Caption := FName;
        SubItems.Add(Format('%.2f', [FPrice]));
        SubItems.Add(FParam);
        ImageIndex := 17;
      end;
    finally
      ListPrice.Items.EndUpdate;
    end;

    FormStyle := fsStayOnTop;
    BtnOK.Enabled := False;
    Show();
  end;
end;

class function TfFormPriceShow.FormID: integer;
begin
  Result := -1;
end;

procedure TfFormPriceShow.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  inherited;
  SaveFormConfig(Self);
  SavecxListViewConfig(Name, ListPrice);

  Action := caFree;
  gForm := nil;
end;

procedure TfFormPriceShow.FormShow(Sender: TObject);
begin
  LoadFormConfig(Self);
  LoadcxListViewConfig(Name, ListPrice);
end;

initialization
  gControlManager.RegCtrl(TfFormPriceShow, TfFormPriceShow.FormID);
end.
