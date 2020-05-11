unit UFormBillReturns;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, UFormNormal, cxGraphics, cxControls, cxLookAndFeels, UFormInputbox,
  cxLookAndFeelPainters, dxSkinsCore, dxSkinsDefaultPainters,
  dxSkinsdxLCPainter, cxContainer, cxEdit, cxTextEdit, dxLayoutControl,
  StdCtrls, cxLabel;

type
  TfFormBillReturns = class(TfFormNormal)
    dxlytmLayout1Item3: TdxLayoutItem;
    edt_BillNo: TcxTextEdit;
    dxlytmLayout1Item31: TdxLayoutItem;
    edt_CusID: TcxTextEdit;
    dxlytmLayout1Item32: TdxLayoutItem;
    edt_CusName: TcxTextEdit;
    dxlytmLayout1Item33: TdxLayoutItem;
    edt_MID: TcxTextEdit;
    dxlytmLayout1Item34: TdxLayoutItem;
    edt_MName: TcxTextEdit;
    dxlytmLayout1Item35: TdxLayoutItem;
    edt_ZhiKa: TcxTextEdit;
    dxlytmLayout1Item36: TdxLayoutItem;
    edt_Truck: TcxTextEdit;
    dxlytmLayout1Item37: TdxLayoutItem;
    edt_Mmo: TcxTextEdit;
    dxlytmLayout1Item38: TdxLayoutItem;
    edt_Value: TcxTextEdit;
    dxLayout1Group2: TdxLayoutGroup;
    dxLayout1Group3: TdxLayoutGroup;
    dxLayout1Group4: TdxLayoutGroup;
    dxLayout1Group5: TdxLayoutGroup;
    cxlbl1: TcxLabel;
    dxlytmLayout1Item39: TdxLayoutItem;
    procedure BtnOKClick(Sender: TObject);
  private
    { Private declarations }

  public
    { Public declarations }
    class function CreateForm(const nPopedom: string = '';
      const nParam: Pointer = nil): TWinControl; override;
    class function FormID: integer; override;
  end;

var
  fFormBillReturns: TfFormBillReturns;

implementation

{$R *.dfm}

uses
  ULibFun, DB, IniFiles, UMgrControl, UAdjustForm, UFormBase, UBusinessPacker,
  UDataModule, USysPopedom, USysBusiness, USysDB, USysGrid, USysConst,
  UFormWait;




function GetLeftStr(SubStr, Str: string): string;
begin
   Result := Copy(Str, 1, Pos(SubStr, Str) - 1);
end;
//-------------------------------------------

function GetRightStr(SubStr, Str: string): string;
var
   i: integer;
begin
   i := pos(SubStr, Str);
   if i > 0 then
     Result := Copy(Str
       , i + Length(SubStr)
       , Length(Str) - i - Length(SubStr) + 1)
   else
     Result := '';
end;
//-------------------------------------------

class function TfFormBillReturns.CreateForm(const nPopedom: string;
  const nParam: Pointer): TWinControl;
var nP : PFormCommandParam;
    nPlan : TStrings;
begin
  Result:= nil;
  nPlan := TStringList.Create;

  if not Assigned(nParam) then
  begin
    New(nP);
    FillChar(nP^, SizeOf(TFormCommandParam), #0);
  end
  else nP := nParam;

  with TfFormBillReturns.Create(Application) do
  try
    nPlan.Delimiter := ',';
    nPlan.CommaText := nP.FParamA;

    edt_BillNo.Text := nPlan[0];
    edt_ZhiKa.Text  := nPlan[1];  //StringReplace(nPlan[1], '@', ' ', [rfReplaceAll]);
    edt_CusID.Text  := nPlan[2];
    edt_CusName.Text:= nPlan[3];
    edt_MID.Text    := nPlan[4];
    edt_MName.Text  := nPlan[5];
    edt_Truck.Text  := nPlan[6];
    edt_Value.Text  := nPlan[7];

    nP.FCommand:= ShowModal;
  finally
    Free;
    nPlan.Free;
  end;
end;

class function TfFormBillReturns.FormID: integer;
begin
  Result := cFI_FormBillReturns;
end;

procedure TfFormBillReturns.BtnOKClick(Sender: TObject);
var nStr, nLID, nTruck : string;
    nList : TStrings;
begin
  nLID  := edt_BillNo.Text;
  nTruck:= edt_Truck.Text;


  nStr := '确定要为[ %s %s ]做退货么?';
  nStr := Format(nStr, [nLID, nTruck]);
  if not QueryDlg(nStr, sAsk) then Exit;

  nStr:= '';
  nList := TStringList.Create;
  try
      with nList do
      begin
        Values['Bill']  := edt_BillNo.Text;
        Values['Reson'] := edt_Mmo.Text;
        Values['Card']  := nStr;
      end;

      BtnOK.Enabled := False;   nStr:= '';
      try
        ShowWaitForm(Self, '正在保存', True);
        nStr := SaveBillReturns(PackerEncodeStr(nList.Text));
        if nStr<>'' then
        begin
          SetBillCard(nStr, nTruck, True);
          //办理磁卡
          ShowMsg('单据保存成功','提示');
          Close;
        end
        else
        begin
          ShowMsg('单据保存失败','提示');
          Exit;
        end;
      finally
        BtnOK.Enabled := True;
        CloseWaitForm;
      end;
  finally
    nList.Free;
  end;
end;

initialization
  gControlManager.RegCtrl(TfFormBillReturns, TfFormBillReturns.FormID);


end.
