{*******************************************************************************
  ����: dmzn@163.com 2010-3-16
  ����: �����鵥
*******************************************************************************}
unit UFormHYData;
{$I Link.inc}
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  UFormNormal, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, cxLabel, cxDropDownEdit,
  cxCalendar, cxButtonEdit, cxMaskEdit, cxTextEdit, dxLayoutControl,
  StdCtrls;

type
  TfFormHYData = class(TfFormNormal)
    dxLayout1Item7: TdxLayoutItem;
    EditTruck: TcxTextEdit;
    dxLayout1Item8: TdxLayoutItem;
    EditValue: TcxTextEdit;
    EditSMan: TcxComboBox;
    dxLayout1Item13: TdxLayoutItem;
    EditCustom: TcxComboBox;
    dxLayout1Item3: TdxLayoutItem;
    EditNo: TcxButtonEdit;
    dxLayout1Item4: TdxLayoutItem;
    dxLayout1Group2: TdxLayoutGroup;
    EditDate: TcxDateEdit;
    dxLayout1Item5: TdxLayoutItem;
    dxLayout1Group4: TdxLayoutGroup;
    EditName: TcxTextEdit;
    dxLayout1Item9: TdxLayoutItem;
    dxLayout1Item6: TdxLayoutItem;
    cxLabel2: TcxLabel;
    chk_IsBD: TCheckBox;
    dxLayout1Item10: TdxLayoutItem;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure EditCustomKeyPress(Sender: TObject; var Key: Char);
    procedure EditSManPropertiesEditValueChanged(Sender: TObject);
    procedure EditNoPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure EditTruckKeyPress(Sender: TObject; var Key: Char);
    procedure EditNameKeyPress(Sender: TObject; var Key: Char);
  protected
    { Protected declarations }
    FSelectVal: Double;
    //ѡ����
    function OnVerifyCtrl(Sender: TObject; var nHint: string): Boolean; override;
    procedure GetSaveSQLList(const nList: TStrings); override;
    procedure AfterSaveData(var nDefault: Boolean); override;
    //��֤����
    procedure InitFormData(const nID: string);
    //��������
  public
    { Public declarations }
    class function CreateForm(const nPopedom: string = '';
      const nParam: Pointer = nil): TWinControl; override;
    class function FormID: integer; override;
  end;

implementation

{$R *.dfm}
uses
  IniFiles, ULibFun, UFormCtrl, UAdjustForm, UFormBase, UMgrControl,
  UDataModule, USysBusiness, USysDB, USysConst;

class function TfFormHYData.CreateForm(const nPopedom: string;
  const nParam: Pointer): TWinControl;
var nP: PFormCommandParam;
begin
  Result := nil;
  nP := nParam;

  with TfFormHYData.Create(Application) do
  try
    Caption := '�����鵥';
    InitFormData('');

    if Assigned(nP) then
    begin
      nP.FCommand := cCmd_ModalResult;
      nP.FParamA := ShowModal;
    end else ShowModal;
  finally
    Free;
  end;
end;

class function TfFormHYData.FormID: integer;
begin
  Result := cFI_FormStockHuaYan;
end;

procedure TfFormHYData.FormCreate(Sender: TObject);
var nIni: TIniFile;
begin
  nIni := TIniFile.Create(gPath + sFormConfig);
  try
    LoadFormConfig(Self, nIni);
  finally
    nIni.Free;
  end;
end;

procedure TfFormHYData.FormClose(Sender: TObject; var Action: TCloseAction);
var nIni: TIniFile;
begin
  nIni := TIniFile.Create(gPath + sFormConfig);
  try
    SaveFormConfig(Self, nIni);
  finally
    nIni.Free;
  end;

  Action := caFree;
  ReleaseCtrlData(Self);
end;

//------------------------------------------------------------------------------
//Desc: ��ʼ������
procedure TfFormHYData.InitFormData(const nID: string);
begin
  EditDate.Date := Now;
  EditValue.Text := '0';
  LoadSaleMan(EditSMan.Properties.Items);
  {$IFDEF HuaYanAddKindType}
    chk_IsBD.Visible := True;
  {$ELSE}
    chk_IsBD.Visible := False;
  {$ENDIF}
end;

//Desc: ѡ��ͻ�
procedure TfFormHYData.EditCustomKeyPress(Sender: TObject; var Key: Char);
var nStr: string;
    nP: TFormCommandParam;
begin
  if Key = Char(VK_SPACE) then
  begin
    Key := #0;
    nP.FParamA := GetCtrlData(EditCustom);
    
    if nP.FParamA = '' then
      nP.FParamA := EditCustom.Text;
    //xxxxx

    CreateBaseFormItem(cFI_FormGetCustom, '', @nP);
    if (nP.FCommand <> cCmd_ModalResult) or (nP.FParamA <> mrOK) then Exit;

    SetCtrlData(EditSMan, nP.FParamD);
    SetCtrlData(EditCustom, nP.FParamB);
    
    if EditCustom.ItemIndex < 0 then
    begin
      nStr := Format('%s=%s.%s', [nP.FParamB, nP.FParamB, nP.FParamC]);
      EditCustom.ItemIndex := InsertStringsItem(EditCustom.Properties.Items, nStr);
    end;
  end;
  if Key = Char(VK_RETURN) then
  begin
    Key := #0;

    if Sender = EditCustom then ActiveControl := EditName else
      Perform(WM_NEXTDLGCTL, 0, 0);
  end;
end;

//Desc: ѡ����
procedure TfFormHYData.EditTruckKeyPress(Sender: TObject; var Key: Char);
var nP: TFormCommandParam;
begin
  if Key = Char(VK_SPACE) then
  begin
    Key := #0;
    nP.FParamA := EditTruck.Text;
    CreateBaseFormItem(cFI_FormGetTruck, '', @nP);

    if (nP.FCommand = cCmd_ModalResult) and(nP.FParamA = mrOk) then
      EditTruck.Text := nP.FParamB;
    EditTruck.SelectAll;
  end;
  if Key = Char(VK_RETURN) then
  begin
    Key := #0;

    if Sender = EditTruck then
         ActiveControl := EditValue
    else Perform(WM_NEXTDLGCTL, 0, 0);
  end;
end;

//Desc: ҵ��Ա���,ѡ��ͻ�
procedure TfFormHYData.EditSManPropertiesEditValueChanged(Sender: TObject);
var nStr: string;
begin
  EditCustom.Text := '';
  
  if EditSMan.ItemIndex >= 0 then
  begin
    AdjustStringsItem(EditCustom.Properties.Items, True);
    nStr := 'C_ID=Select C_ID,C_Name From %s Where C_SaleMan=''%s''';
    nStr := Format(nStr, [sTable_Customer, GetCtrlData(EditSMan)]);

    FDM.FillStringsData(EditCustom.Properties.Items, nStr, -1, '.');
    AdjustStringsItem(EditCustom.Properties.Items, False);
  end;
end;

//Desc: ѡ��ˮ����
procedure TfFormHYData.EditNoPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
var nP: TFormCommandParam;
begin
  nP.FCommand := cCmd_ViewData;
  nP.FParamA := Trim(EditNo.Text);
  CreateBaseFormItem(cFI_FormGetStockNo, '', @nP);

  if (nP.FCommand = cCmd_ModalResult) and (nP.FParamA = mrOK) then
  begin
    EditNo.Text := nP.FParamB;
  end;
end;

function TfFormHYData.OnVerifyCtrl(Sender: TObject; var nHint: string): Boolean;
var nVal,nMax: Double;
begin
  Result := True;

  if Sender = EditCustom then
  begin
    Result := EditCustom.ItemIndex > -1;
    nHint := '��ѡ����Ч�Ŀͻ�';
  end else

  if Sender = EditName then
  begin
    Result := Trim(EditName.Text) <> '';
    nHint := '����д��Ч�Ŀͻ�����';
  end else

  if Sender = EditTruck then
  begin
    Result := Trim(EditTruck.Text) <> '';
    nHint := '����д��Ч�ĳ��ƺ���';
  end else

  if Sender = EditValue then
  begin
    Result := IsNumber(EditValue.Text, True) and (StrToFloat(EditValue.Text) > 0);
    nHint := '����д��Ч�������';
  end else

  if Sender = EditNo then
  begin
    Result := Trim(EditNo.Text) <> '';
    nHint := '����д��Ч�ı��';
    if not Result then Exit;

    nVal := GetHYValueByStockNo(EditNo.Text);
    Result := nVal >= 0;
    nHint := '��Ч��ˮ����';

    if not Result then Exit;
    if not OnVerifyCtrl(EditValue, nHint) then Exit;

    nMax := GetHYMaxValue;
    Result := nVal + StrToFloat(EditValue.Text) <= nMax;

    if not Result then
    begin
      nHint := 'ϵͳÿ���������������[ %.2f ]��,��ǰ�ѿ���[ %.2f ]��.' +
               #13#10 +'ȷ��Ҫ�����û��鵥��?';
      nHint := Format(nHint, [nMax, nVal]);
      
      Result := QueryDlg(nHint, sAsk, Handle);
      nHint := '';
    end;
  end;
end;

//Desc: ����SQL
procedure TfFormHYData.GetSaveSQLList(const nList: TStrings);
var nStr,nKindType : string;
begin
  {$IFDEF HuaYanAddKindType}
  if chk_IsBD.Checked then
    nKindType := 'Y'
  else
    nKindType := 'N';
  nStr := 'Insert Into $Table(H_Custom,H_CusName,H_SerialNo,H_Truck,H_Value,' +
          'H_BillDate,H_ReportDate,H_Reporter,H_KindType) Values(''$Cus'',''$CName'',' +
          '''$No'',''$TN'',$Val,''$BD'',$RD,''$RE'',''$HY'')';
  nStr := MacroValue(nStr, [MI('$Table', sTable_StockHuaYan),
          MI('$Cus', GetCtrlData(EditCustom)), MI('$CName', EditName.Text),
          MI('$No', EditNo.Text), MI('$TN', EditTruck.Text),
          MI('$Val', EditValue.Text), MI('$BD', DateTime2Str(EditDate.Date)),
          MI('$RD', FDM.SQLServerNow), MI('$RE', gSysParam.FUserID), MI('$HY', nKindType)]);
  {$ELSE}
  nStr := 'Insert Into $Table(H_Custom,H_CusName,H_SerialNo,H_Truck,H_Value,' +
          'H_BillDate,H_ReportDate,H_Reporter) Values(''$Cus'',''$CName'',' +
          '''$No'',''$TN'',$Val,''$BD'',$RD,''$RE'')';
  nStr := MacroValue(nStr, [MI('$Table', sTable_StockHuaYan),
          MI('$Cus', GetCtrlData(EditCustom)), MI('$CName', EditName.Text),
          MI('$No', EditNo.Text), MI('$TN', EditTruck.Text),
          MI('$Val', EditValue.Text), MI('$BD', DateTime2Str(EditDate.Date)),
          MI('$RD', FDM.SQLServerNow), MI('$RE', gSysParam.FUserID)]);
  {$ENDIF}
  nList.Add(nStr);
end;

//Desc: ��ӡ���鵥
procedure TfFormHYData.AfterSaveData(var nDefault: Boolean);
var nStr: string;
begin
  nStr := IntToStr(FDM.GetFieldMax(sTable_StockHuaYan, 'H_ID'));
  PrintHeGeReport(nStr, True);
  PrintHuaYanReport(nStr, True);
end;

procedure TfFormHYData.EditNameKeyPress(Sender: TObject; var Key: Char);
begin
  inherited;
  if Key = Char(VK_RETURN) then
  begin
    Key := #0;

    if Sender = EditSMan then ActiveControl := EditCustom else
    if Sender = EditName then ActiveControl := EditDate else
    if Sender = EditDate then ActiveControl := EditNo else

    if Sender = EditNo then
         ActiveControl := EditTruck else
    if Sender = EditValue then
       ActiveControl := BtnOK
    else Perform(WM_NEXTDLGCTL, 0, 0);
  end;
end;

initialization
  gControlManager.RegCtrl(TfFormHYData, TfFormHYData.FormID);
end.
