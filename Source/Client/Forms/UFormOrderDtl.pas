{*******************************************************************************
作者: fendou116688@163.com 2016/10/31
描述: 采购明细管理
*******************************************************************************}
unit UFormOrderDtl;

{$I Link.Inc}
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  UDataModule, UFormBase, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, dxLayoutControl, cxCheckBox,
  cxLabel, StdCtrls, cxMaskEdit, cxDropDownEdit, cxMCListBox, cxMemo,
  cxTextEdit, cxButtonEdit;

type
  TfFormOrderDtl = class(TBaseForm)
    dxLayoutControl1Group_Root: TdxLayoutGroup;
    dxLayoutControl1: TdxLayoutControl;
    dxLayoutControl1Group1: TdxLayoutGroup;
    EditMemo: TcxMemo;
    dxLayoutControl1Item4: TdxLayoutItem;
    BtnOK: TButton;
    dxLayoutControl1Item10: TdxLayoutItem;
    BtnExit: TButton;
    dxLayoutControl1Item11: TdxLayoutItem;
    dxLayoutControl1Group5: TdxLayoutGroup;
    EditPValue: TcxTextEdit;
    dxLayoutControl1Item1: TdxLayoutItem;
    EditMValue: TcxTextEdit;
    dxLayoutControl1Item2: TdxLayoutItem;
    dxLayoutControl1Group3: TdxLayoutGroup;
    EditProID: TcxButtonEdit;
    dxLayoutControl1Item3: TdxLayoutItem;
    dxLayoutControl1Group2: TdxLayoutGroup;
    EditProName: TcxTextEdit;
    dxLayoutControl1Item5: TdxLayoutItem;
    dxLayoutControl1Group4: TdxLayoutGroup;
    EditStock: TcxButtonEdit;
    dxLayoutControl1Item6: TdxLayoutItem;
    EditStockName: TcxTextEdit;
    dxLayoutControl1Item7: TdxLayoutItem;
    EditTruck: TcxButtonEdit;
    dxLayoutControl1Item9: TdxLayoutItem;
    cxTextEdit3: TcxTextEdit;
    dxLayoutControl1Item12: TdxLayoutItem;
    EditCheck: TcxCheckBox;
    dxLayoutControl1Item8: TdxLayoutItem;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure BtnOKClick(Sender: TObject);
    procedure BtnExitClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure EditStockKeyPress(Sender: TObject; var Key: Char);
  private
    { Private declarations }
    FOrderID,FDetailID: string;
    //单据标识
    procedure InitFormData(const nID: string);
    //载入数据
    function SetData(Sender: TObject; const nData: string): Boolean;
    //数据相关
    procedure WriteOptionLog;
  public
    { Public declarations }
    class function CreateForm(const nPopedom: string = '';
      const nParam: Pointer = nil): TWinControl; override;
    class function FormID: integer; override;
  end;

implementation

{$R *.dfm}
uses
  IniFiles, ULibFun, UMgrControl, UFormCtrl, UAdjustForm, USysBusiness,
  USysGrid, USysDB, USysConst;

type
  TDataOldItem = record
    FID        : string;
    FName      : string;
    FProID     : string;
    FProName   : string;
    FTruck     : string;
    FKzValue   : string;
    FPValue    : string;
    FMValue    : string;
    FUpdate    : Boolean;
  end;

var
  gForm: TfFormOrderDtl = nil;
  //全局使用
  gOldData: TDataOldItem;
  //原始通道配置

class function TfFormOrderDtl.CreateForm(const nPopedom: string;
  const nParam: Pointer): TWinControl;
var nP: PFormCommandParam;
begin
  Result := nil;
  if Assigned(nParam) then
       nP := nParam
  else Exit;

  case nP.FCommand of
   cCmd_EditData:
    with TfFormOrderDtl.Create(Application) do
    begin
      FDetailID := nP.FParamA;
      FOrderID  := nP.FParamB;
      Caption := '采购过磅单 - 修改';

      InitFormData(FDetailID);
      nP.FCommand := cCmd_ModalResult;
      nP.FParamA := ShowModal;
      Free;
    end;
   cCmd_ViewData:
    begin
      if not Assigned(gForm) then
      begin
        gForm := TfFormOrderDtl.Create(Application);
        with gForm do
        begin
          Caption := '采购过磅单 - 查看';
          FormStyle := fsStayOnTop;

          BtnOK.Visible := False;
        end;
      end;

      with gForm  do
      begin
        FDetailID := nP.FParamA;
        FOrderID  := nP.FParamB;
        InitFormData(FDetailID);
        if not Showing then Show;
      end;
    end;
   cCmd_FormClose:
    begin
      if Assigned(gForm) then FreeAndNil(gForm);
    end;
  end; 
end;

class function TfFormOrderDtl.FormID: integer;
begin
  Result := cFI_FormOrderDtl;
end;

//------------------------------------------------------------------------------
procedure TfFormOrderDtl.FormCreate(Sender: TObject);
var nIni: TIniFile;
begin
  nIni := TIniFile.Create(gPath + sFormConfig);
  try
    LoadFormConfig(Self, nIni);
  finally
    nIni.Free;
  end;

  ResetHintAllForm(Self, 'D', sTable_OrderDtl);
  //重置表名称
end;

procedure TfFormOrderDtl.FormClose(Sender: TObject;
  var Action: TCloseAction);
var nIni: TIniFile;
begin
  nIni := TIniFile.Create(gPath + sFormConfig);
  try
    SaveFormConfig(Self, nIni);
  finally
    nIni.Free;
  end;

  gForm := nil;
  Action := caFree;
  ReleaseCtrlData(Self);
end;

procedure TfFormOrderDtl.BtnExitClick(Sender: TObject);
begin
  Close;
end;

procedure TfFormOrderDtl.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
 if Key = VK_ESCAPE then
  begin
    Key := 0; Close;
  end;
end;

//------------------------------------------------------------------------------
//Desc: 设置数据
function TfFormOrderDtl.SetData(Sender: TObject; const nData: string): Boolean;
begin
  Result := False;
end;

//Date: 2009-6-2
//Parm: 供应商编号
//Desc: 载入nID供应商的信息到界面
procedure TfFormOrderDtl.InitFormData(const nID: string);
var nStr: string;
begin
  if nID <> '' then
  begin
    nStr := 'Select * From %s ' +
            ' Left Join %s On D_OID=O_ID ' +
            'Where D_ID=''%s''';
    nStr := Format(nStr, [sTable_OrderDtl, sTable_Order, nID]);
    LoadDataToCtrl(FDM.QueryTemp(nStr), Self, '', SetData);

    //记录原始数据
    gOldData.FID        := EditStock.Text;
    gOldData.FName      := EditStockName.Text;
    gOldData.FProID     := EditProID.Text;
    gOldData.FProName   := EditProName.Text;
    gOldData.FTruck     := EditTruck.Text;
    gOldData.FKzValue   := cxTextEdit3.Text;
    gOldData.FPValue    := EditPValue.Text;
    gOldData.FMValue    := EditMValue.Text;
    gOldData.FUpdate    := EditCheck.Checked = True;
  end;
end;

//Desc: 保存数据
procedure TfFormOrderDtl.BtnOKClick(Sender: TObject);
var nSQL, nStr: string;
    nP: TFormCommandParam;
begin
  {$IFDEF ForceMemo}
  with nP do
  begin
    nStr := FDetailID;
    nStr := Format('请填写修改[ %s ]单据的原因', [nStr]);

    FCommand := cCmd_EditData;
    FParamA := nStr;
    FParamB := 320;
    FParamD := 2;

    FParamC := 'Update %s Set D_Memo=''$Memo'' Where D_ID=''%s''';
    FParamC := Format(FParamC, [sTable_OrderDtl, FDetailID]);

    CreateBaseFormItem(cFI_FormMemo, '', @nP);
    if (FCommand <> cCmd_ModalResult) or (FParamA <> mrOK) then Exit;
  end;
  {$ENDIF}

  nSQL := MakeSQLByForm(Self, sTable_OrderDtl, SF('D_ID', FDetailID), False);

  FDM.ADOConn.BeginTrans;
  try
    FDM.ExecuteSQL(nSQL);

    nSQL := MakeSQLByStr([SF('P_CusID', EditProID.Text),
            SF('P_CusName', EditProName.Text),
            SF('P_MID', EditStock.Text),
            SF('P_MName', EditStockName.Text),
            SF('P_Truck', EditTruck.Text),
            SF('P_PValue', StrToFloatDef(EditPValue.Text, 0), sfVal),
            SF('P_MValue', StrToFloatDef(EditMValue.Text, 0), sfVal)
            ], sTable_PoundLog, SF('P_Order', FDetailID), False);
    FDM.ExecuteSQL(nSQL);
    //更新磅单

    if EditCheck.Checked and (FOrderID <> '') then
    begin
      nSQL := MakeSQLByStr([SF('O_ProID', EditProID.Text),
              SF('O_ProName', EditProName.Text),
              SF('O_ProPY', GetPinYinOfStr(EditProName.Text)),
              SF('O_StockNo', EditStock.Text),
              SF('O_StockName', EditStockName.Text),
              SF('O_Truck', EditTruck.Text)
              ], sTable_Order, SF('O_ID', FOrderID), False);
      FDM.ExecuteSQL(nSQL);
    end;

    FDM.ADOConn.CommitTrans;
    WriteOptionLog;
    //--写入操作日志
    ModalResult := mrOK;
    ShowMsg('数据已保存', sHint);
  except
    FDM.ADOConn.RollbackTrans;
    ShowMsg('数据保存失败', '未知原因');
  end;
end;

procedure TfFormOrderDtl.EditStockKeyPress(Sender: TObject; var Key: Char);
var nP: TFormCommandParam;
begin
  inherited;
  if Key = Char(VK_RETURN) then
  begin
    Key := #0;

    if Sender = EditStock then
    begin
      CreateBaseFormItem(cFI_FormGetMeterail, '', @nP);
      if (nP.FCommand <> cCmd_ModalResult) or (nP.FParamA <> mrOk) then Exit;

      EditStock.Text := nP.FParamB;
      EditStockName.Text := nP.FParamC;
    end

    else if Sender = EditProID then
    begin
      CreateBaseFormItem(cFI_FormGetProvider, '', @nP);
      if (nP.FCommand <> cCmd_ModalResult) or (nP.FParamA <> mrOk) then Exit;

      EditProID.Text := nP.FParamB;
      EditProName.Text := nP.FParamC;
    end

    else if Sender = EditTruck then
    begin
      CreateBaseFormItem(cFI_FormGetTruck, '', @nP);
      if (nP.FCommand <> cCmd_ModalResult) or (nP.FParamA <> mrOk) then Exit;

      EditTruck.Text := nP.FParamB;
    end;
  end;
end;

procedure TfFormOrderDtl.WriteOptionLog;
var nEvent: string;
begin
  nEvent := '';

  if gOldData.FID <> EditStock.Text then
  begin
    nEvent := nEvent + '原材料编号由 [ %s ] --> [ %s ];';
    nEvent := Format(nEvent, [gOldData.FID, EditStock.Text]);
  end;
  if gOldData.FName <> EditStockName.Text then
  begin
    nEvent := nEvent + '原材料名称由 [ %s ] --> [ %s ];';
    nEvent := Format(nEvent, [gOldData.FName, EditStockName.Text]);
  end;
  if gOldData.FProID <> EditProID.Text then
  begin
    nEvent := nEvent + '供应商编号由 [ %s ] --> [ %s ];';
    nEvent := Format(nEvent, [gOldData.FProID, EditProID.Text]);
  end;
  if gOldData.FProName <> EditProName.Text then
  begin
    nEvent := nEvent + '供应商名称由 [ %s ] --> [ %s ];';
    nEvent := Format(nEvent, [gOldData.FProName, EditProName.Text]);
  end;
  if gOldData.FTruck <> EditTruck.Text then
  begin
    nEvent := nEvent + '车牌号码由 [ %s ] --> [ %s ];';
    nEvent := Format(nEvent, [gOldData.FTruck, EditTruck.Text]);
  end;
  if gOldData.FKzValue <> cxTextEdit3.Text then
  begin
    nEvent := nEvent + '扣杂吨数由 [ %s ] --> [ %s ];';
    nEvent := Format(nEvent, [gOldData.FKzValue, cxTextEdit3.Text]);
  end;
  if gOldData.FPValue <> EditPValue.Text then
  begin
    nEvent := nEvent + '皮重由 [ %s ] --> [ %s ];';
    nEvent := Format(nEvent, [gOldData.FPValue, EditPValue.Text]);
  end;
  if gOldData.FMValue <> EditMValue.Text then
  begin
    nEvent := nEvent + '毛重由 [ %s ] --> [ %s ];';
    nEvent := Format(nEvent, [gOldData.FMValue, EditMValue.Text]);
  end;

  if nEvent <> '' then
  begin
    nEvent := '采购订单 [ %s ] 参数已被修改:' + nEvent;
    nEvent := Format(nEvent, [gOldData.FID]);
  end;

  if nEvent <> '' then
  begin
    FDM.WriteSysLog(sFlag_OrderItem, FOrderID, nEvent);
  end;
end;

initialization
  gControlManager.RegCtrl(TfFormOrderDtl, TfFormOrderDtl.FormID);
end.
