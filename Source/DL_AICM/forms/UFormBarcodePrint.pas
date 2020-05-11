{*******************************************************************************
  作者: 289525016@163.com 2017-4-9
  描述: 扫描二维码打印化验单
*******************************************************************************}
unit UFormBarcodePrint;

{$I Link.Inc}

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
   UFormNormal, UFormBase, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, cxLabel, cxTextEdit,
  dxLayoutControl, StdCtrls, cxGraphics, dxLayoutcxEditAdapters, ExtCtrls,
  CPort, Menus, cxButtons;

type
  TfFormBarcodePrint = class(TfFormNormal)
    editWebOrderNo: TcxTextEdit;
    dxLayout1Item5: TdxLayoutItem;
    cxLabel1: TcxLabel;
    dxLayout1Item3: TdxLayoutItem;
    cxLabel2: TcxLabel;
    dxLayout1Item4: TdxLayoutItem;
    btnClear: TcxButton;
    dxLayout1Item6: TdxLayoutItem;
    TimerAutoClose: TTimer;
    procedure BtnOKClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure editWebOrderNoKeyPress(Sender: TObject; var Key: Char);
    procedure TimerAutoCloseTimer(Sender: TObject);
    procedure editWebOrderNoPropertiesChange(Sender: TObject);
  private
    { Private declarations }
    FAutoClose:Integer;
    FParam: PFormCommandParam;
    function GetHYDan(const nwebOrderid:string; var nHYDan,nStockname,nStockno:string):Boolean;
    procedure Writelog(nMsg:string);
  public
    { Public declarations }
    class function CreateForm(const nPopedom: string = '';
      const nParam: Pointer = nil): TWinControl; override;
    class function FormID: integer; override;
  end;

implementation

{$R *.dfm}
uses
  IniFiles, ULibFun, UMgrControl, USysBusiness, USmallFunc, USysConst, USysDB,
  UDataModule,USysLoger;

class function TfFormBarcodePrint.FormID: integer;
begin
  Result := cFI_FormBarCodePrint;
end;

class function TfFormBarcodePrint.CreateForm(const nPopedom: string;
  const nParam: Pointer): TWinControl;
begin
  Result := nil;
  if not Assigned(nParam) then Exit;
  with TfFormBarcodePrint.Create(Application) do
  try
    editWebOrderNo.Properties.MaxLength := gSysParam.FWebOrderLength;
    FAutoClose := 20;
    TimerAutoClose.Interval := 1000;
    TimerAutoClose.Enabled := True;
    ActiveControl := editWebOrderNo;
    FParam := nParam;
    FParam.FCommand := cCmd_ModalResult;
    FParam.FParamA := ShowModal;
  finally
    Free;
  end;

end;

procedure TfFormBarcodePrint.BtnOKClick(Sender: TObject);
var
  nWebOrderID:string;
  nHyDan,nstockname,nstockno:string;
  nMsg:string;
begin
  nWebOrderID := Trim(editWebOrderNo.Text);
  if nWebOrderID='' then
  begin
    nMsg:= '请录入或扫描二维码';
    ShowMsg(nMsg,sHint);
    Exit;
  end;
  if not GetHYDan(nWebOrderID,nHyDan,nstockname,nstockno) then Exit;
  FParam.FParamB := nHyDan;
  FParam.FParamC := nstockname;
  FParam.FParamD := nstockno;
  ModalResult := mrok;
end;

function TfFormBarcodePrint.GetHYDan(const nwebOrderid:string;var nHYDan,nStockname,nStockno: string): Boolean;
var
  nStr:string;
  nBillno:string;
  nMsg:string;
  nStatus:string;

begin
  Result := False;
  nStr := 'select * from %s where WOM_WebOrderID=''%s'' ';  // and WOM_deleted=''%s''   , sFlag_No
  nStr := Format(nStr,[sTable_WebOrderMatch, nwebOrderid]);

  with fdm.QueryTemp(nStr) do
  begin
    if RecordCount<1 then
    begin
      nMsg := '商城订单号不存在或已删除';
      ShowMsg(nMsg, sHint);
      Writelog(nMsg);
      Exit;
    end;
    nBillno := FieldByName('WOM_LID').AsString;
  end;

  nStr := ' Select L_Status,L_HYDan,L_StockName,l_Stockno, IsNull(H_PrintNum, 0) H_PrintNum  From %s'+
          ' Left Join S_StockHuaYan On H_Reporter=L_ID' +
          ' Where L_ID=''%s''';

  nStr := Format(nStr, [sTable_Bill, nBillno]);
  with fdm.QueryTemp(nStr) do
  begin
    if RecordCount<1 then
    begin
      nMsg := '未能找到相关订单、请确认您输入的订单号';
      ShowMsg(nMsg, sHint);
      Writelog(nMsg);
      Exit;
    end;

    nStatus := FieldByName('L_Status').AsString;
    if (nStatus<>sFlag_TruckBFM) and (nStatus<>sFlag_TruckOut) then
    begin
      nMsg := '请在称完毛重或者车辆出厂后再扫描二维码图片打印化验单';
      ShowMsg(nMsg, sHint);
      Writelog(nMsg);
      Exit;
    end;

    if (FieldByName('H_PrintNum').AsInteger>1) then
    begin
      nMsg := '您已打印过化验单、如有需要再次打印请联系工作人员处理';
      ShowMsg(nMsg, sHint);
      Writelog('单号：'+nBillno+' 再次自助打印化验单、已拒绝本次请求');
      Exit;
    end;
  end;

  {$IFDEF ChkPopedomPrintHYD}
  nStr:= 'Select L_ID, L_CusName, C_InstantPrintHYD From $Bill '+
         'Left   Join $Customer On L_CusID=C_ID '+
         'Where  L_ID=''$ID'' And DATEDIFF(day, L_OutFact, GETDATE())>=3 ';

    {$IFDEF SWAS}
      nStr:= nStr + '  And C_InstantPrintHYD=''Y''  ';
    {$ENDIF}

  nStr:= MacroValue(nStr, [MI('$Bill', sTable_Bill),
          MI('$Customer', sTable_Customer), MI('$ID', nBillno)]);
  //xxxxx

  if FDM.QueryTemp(nStr).RecordCount < 1 then
  begin
    nMsg := '您的订单所属批次的化验结果尚未检测完毕、请按照约定时间前来打印';
    ShowMsg(nMsg, sHint);
    Exit;
  end;
  {$ENDIF}

  nStr := ' Select H_CusName, H_SerialNo, H_Reporter, ISNULL(H_PrintNum, 0) H_PrintNum, P_Stock, P_Name '+
          ' From S_StockHuaYan hy  Left Join S_Customer cus on cus.C_ID=hy.H_Custom           '+
          ' Left Join (Select R_SerialNo,P_Type,P_Stock,P_Name,P_QLevel From S_StockRecord sr '+
          ' Left Join S_StockParam sp on sp.P_ID=sr.R_PID) sr on sr.R_SerialNo=H_SerialNo     '+
          ' Where H_Reporter=''%s''';

  nStr := Format(nStr, [nBillno]);
  with FDM.QueryTemp(nStr) do
  begin
    if (RecordCount<1)or(FieldByName('P_Stock').AsString='') then
    begin
      nMsg := '您的订单所属批次的化验结果尚未检测完毕、请按照约定时间前来打印';
      ShowMsg(nMsg, sHint);
      Writelog(nMsg);
      Exit;
    end;

    nStockName := FieldByName('P_Stock').AsString;
    nStockno := FieldByName('P_Name').AsString;
    nHYDan := nBillno;
    Result := True;
  end;

end;

procedure TfFormBarcodePrint.btnClearClick(Sender: TObject);
begin
  editWebOrderNo.Clear;
  self.ActiveControl := editWebOrderNo;
  FAutoClose := 20;
end;

procedure TfFormBarcodePrint.Writelog(nMsg: string);
var
  nStr:string;
begin
  nStr := 'weborder[%s]';
  nStr := Format(nStr,[editWebOrderNo.Text]);
  gSysLoger.AddLog(nStr+nMsg);
end;

procedure TfFormBarcodePrint.editWebOrderNoKeyPress(Sender: TObject;
  var Key: Char);
begin
  if Key=Char(vk_return) then
  begin
    key := #0;
    btnok.Click;
  end;
end;

procedure TfFormBarcodePrint.TimerAutoCloseTimer(Sender: TObject);
begin
  if FAutoClose=0 then
  begin
    BtnExit.Click;
  end;
  Dec(FAutoClose);
end;

procedure TfFormBarcodePrint.editWebOrderNoPropertiesChange(
  Sender: TObject);
begin
  FAutoClose := 20;
end;

initialization
  gControlManager.RegCtrl(TfFormBarcodePrint, TfFormBarcodePrint.FormID);
end.
