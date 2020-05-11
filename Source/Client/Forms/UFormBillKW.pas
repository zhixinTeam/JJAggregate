{*******************************************************************************
  作者: dmzn@163.com 2018-12-14
  描述: 开提货单     提货单勘误
*******************************************************************************}
unit UFormBillKW;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  UFormNormal, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, ComCtrls, cxListView,
  cxDropDownEdit, cxTextEdit, cxMaskEdit, cxButtonEdit, cxMCListBox,
  dxLayoutControl, StdCtrls;

type
  TfFormBillKW = class(TfFormNormal)
    dxLayout1Item9: TdxLayoutItem;
    EditSalesMan: TcxComboBox;
    dxLayout1Item10: TdxLayoutItem;
    EditName: TcxComboBox;
    EditZK: TcxComboBox;
    dxLayout1Item3: TdxLayoutItem;
    EditPrice: TcxTextEdit;
    dxLayout1Item4: TdxLayoutItem;
    dxLayout1Item5: TdxLayoutItem;
    ListQuery: TcxListView;
    EditProject: TcxTextEdit;
    dxLayout1Item6: TdxLayoutItem;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure EditSalesManPropertiesChange(Sender: TObject);
    procedure EditNamePropertiesEditValueChanged(Sender: TObject);
    procedure EditNameKeyPress(Sender: TObject; var Key: Char);
    procedure BtnOKClick(Sender: TObject);
    procedure EditZKPropertiesEditValueChanged(Sender: TObject);
  protected
    { Private declarations }
    FListA: TStrings;
    nL_Value,nL_Money,AL_Money: Double;
    nL_ID,nL_ZhiKa,nL_CusID,nL_CusName,nL_SaleID,nL_SaleMan,nL_Price:string;
    ASaleID,ASaleMan,ACusID,ACusName,ACus_PY,ACus_Area,AL_ZhiKa,AL_Project:string;
    FShowPrice: Boolean;
    //显示单价
    procedure InitFormData(const nID: string);
    //载入数据
    procedure ClearCustomerInfo;
    function LoadCustomerInfo(nID: string;
      const nIsCode: Boolean= False): Boolean;
    //载入客户
    procedure WriteOptionLog(const LID: string);
  public
    { Public declarations }
    class function CreateForm(const nPopedom: string = '';
      const nParam: Pointer = nil): TWinControl; override;
    class function FormID: integer; override;
  end;

implementation

{$R *.dfm}
uses
  DB, IniFiles, ULibFun, UFormBase, UMgrControl, UAdjustForm, UDataModule,
  USysPopedom, USysGrid, USysDB, USysConst, USysBusiness;

var
  gParam: PFormCommandParam = nil;
  //全局使用

class function TfFormBillKW.CreateForm(const nPopedom: string;
  const nParam: Pointer): TWinControl;
var
  nModifyStr: string;
begin
  Result := nil;
  if Assigned(nParam) then
    gParam := nParam
  else Exit;
  
  nModifyStr :=gParam.FParamA;

  with TfFormBillKW.Create(Application) do
  try
    Caption := '提货单勘误';

    FListA.Text := nModifyStr;
    InitFormData('');
    FShowPrice := gPopedomManager.HasPopedom(nPopedom, sPopedom_ViewPrice);
    
    gParam.FCommand := cCmd_ModalResult;
    gParam.FParamA := ShowModal;
  finally
    Free;
  end;
end;

class function TfFormBillKW.FormID: integer;
begin
  Result := cFI_FormBillKW;
end;

procedure TfFormBillKW.FormCreate(Sender: TObject);
begin
  FListA    := TStringList.Create;
  dxGroup1.AlignVert := avTop;
end;

procedure TfFormBillKW.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  ReleaseCtrlData(Self);
  FListA.Free;
end;

//------------------------------------------------------------------------------
procedure TfFormBillKW.InitFormData(const nID: string);
var
  nStr: string;
begin
  dxGroup1.AlignVert := avTop;
  ActiveControl := EditSalesMan; 
  LoadSaleMan(EditSalesMan.Properties.Items);

  nStr := 'select *, L_Price*L_Value L_Money From %s where L_ID = ''%s'' ';
  nStr := Format(nStr,[sTable_Bill,FListA.Strings[0]]);

  with FDM.QueryTemp(nStr) do
  begin
    if RecordCount < 1 then Exit;

    with ListQuery.Items.Add do
    begin
      Caption := FieldByName('L_ID').AsString;
      SubItems.Add(FieldByName('L_Zhika').AsString);
      SubItems.Add(FieldByName('L_SaleMan').AsString);
      SubItems.Add(FieldByName('L_CusName').AsString);
      SubItems.Add(FieldByName('L_Price').AsString);
      SubItems.Add(FieldByName('L_Truck').AsString);
      ImageIndex := cItemIconIndex;
    end;

    nL_ID      := FieldByName('L_ID').AsString;
    nL_ZhiKa   := FieldByName('L_ZhiKa').AsString;
    nL_CusID   := FieldByName('L_CusID').AsString;
    nL_CusName := FieldByName('L_CusName').AsString;
    nL_SaleID  := FieldByName('L_SaleID').AsString;
    nL_SaleMan := FieldByName('L_SaleMan').AsString;
    nL_Price   := FieldByName('L_Price').AsString;
    nL_Value   := FieldByName('L_Value').AsFloat;
    nL_Money   := FieldByName('L_Money').AsFloat;
    nL_Money   := Float2Float(nL_Money, cPrecision, True);
  end;
end;

//Desc: 清理客户信息
procedure TfFormBillKW.ClearCustomerInfo;
begin
  if not EditName.Focused then EditName.ItemIndex := -1;
end;

//Desc: 载入nID客户的信息
function TfFormBillKW.LoadCustomerInfo(nID: string;
  const nIsCode: Boolean): Boolean;
var nDS: TDataSet;
    nStr,nZhiKa,nCusName,nSaleMan: string;
begin
  Result := False;
  ClearCustomerInfo;

  if nIsCode then
  begin
    nZhiKa := nID;
    if not IsZhiKaValid(nZhiKa, nID, True) then
    begin
      ShowDlg(nID, sHint);
      Exit;
    end;
  end else nZhiKa := '';

  if GetStringsItemIndex(EditName.Properties.Items, nID) < 0 then
  begin
    nStr := Format('%s=%s.%s', [nID, nID, nCusName]);
    InsertStringsItem(EditName.Properties.Items, nStr);
  end;

  SetCtrlData(EditName, nID);
  //customer info done

  //----------------------------------------------------------------------------
  if nZhiKa = '' then
  begin
    nStr := 'Z_ID=Select Z_ID, Z_Name From %s ' +
            'Where Z_Customer=''%s'' And Z_ValidDays>%s And ' +
            'IsNull(Z_InValid, '''')<>''%s'' And ' +
            'IsNull(Z_Freeze, '''')<>''%s'' Order By Z_ID';
    nStr := Format(nStr, [sTable_ZhiKa, nID, sField_SQLServer_Now,
            sFlag_Yes, sFlag_Yes]);
    //xxxxx
  end else
  begin
    nStr := 'Z_ID=Select Z_ID, Z_Name From %s Where Z_ID=''%s''';
    nStr := Format(nStr, [sTable_ZhiKa, nZhiKa]);
  end;

  with EditZK.Properties do
  begin
    AdjustStringsItem(Items, True);
    FDM.FillStringsData(Items, nStr, 0, '.');
    AdjustStringsItem(Items, False);

    if Items.Count > 0 then
      EditZK.ItemIndex := 0;
    //xxxxx

    ActiveControl := BtnOK;
  end;
end;

procedure TfFormBillKW.EditSalesManPropertiesChange(Sender: TObject);
var nStr: string;
begin
  if EditSalesMan.ItemIndex > -1 then
  begin
    nStr := Format('C_SaleMan=''%s''', [GetCtrlData(EditSalesMan)]);
    LoadCustomer(EditName.Properties.Items, nStr);
  end;
end;

procedure TfFormBillKW.EditNamePropertiesEditValueChanged(Sender: TObject);
begin
  if (EditName.ItemIndex > -1) and EditName.Focused then
    LoadCustomerInfo(GetCtrlData(EditName));
  //xxxxx
end;

//Desc: 选择客户
procedure TfFormBillKW.EditNameKeyPress(Sender: TObject; var Key: Char);
var nStr: string;
    nP: TFormCommandParam;
begin
  if Key = #13 then
  begin
    Key := #0;
    nP.FParamA := GetCtrlData(EditName);
    
    if nP.FParamA = '' then
      nP.FParamA := EditName.Text;
    //xxxxx

    CreateBaseFormItem(cFI_FormGetCustom, '', @nP);
    if (nP.FCommand <> cCmd_ModalResult) or (nP.FParamA <> mrOK) then Exit;
  end;
end;

procedure TfFormBillKW.BtnOKClick(Sender: TObject);
var
  nStr, nSQL: string;
begin
  if EditZK.ItemIndex < 0 then
  begin
    ShowMsg('请选择纸卡', sHint);
    Exit;
  end;
  if Trim(EditPrice.Text) = '' then
  begin
    ShowMsg('请输入价格', sHint);  
    Exit;
  end;
  if StrToFloatDef(Trim(EditPrice.Text),0) <= 0 then
  begin
    ShowMsg('价格需要大于零', sHint);  
    Exit;
  end;

  AL_Money := StrToFloatDef(Trim(EditPrice.Text),0) * nL_Value;
  AL_Money := Float2Float(AL_Money, cPrecision, True);

  if EditSalesMan.ItemIndex > -1 then
  begin
    ASaleID := GetCtrlData(EditSalesMan);
  end;

  nStr := 'Select S_NAME From %s Where S_ID=''%s'' ';
  nStr := Format(nStr, [sTable_Salesman, ASaleID]);

  with FDM.QueryTemp(nStr) do
  begin
    if RecordCount < 1 then Exit;
    ASaleMan := FieldByName('S_NAME').AsString;
  end;

  if EditName.ItemIndex > -1 then
  begin
    ACusID := GetCtrlData(EditName);
  end;

  nStr := 'Select C_NAME,C_PY,C_Area From %s Where C_ID=''%s'' ';
  nStr := Format(nStr, [sTable_Customer, ACusID]);

  with FDM.QueryTemp(nStr) do
  begin
    if RecordCount < 1 then Exit;
    ACusName  := FieldByName('C_NAME').AsString;
    ACus_PY   := FieldByName('C_PY').AsString;
    ACus_Area := FieldByName('C_Area').AsString;
  end;

  AL_ZhiKa := GetCtrlData(EditZK);
//  nStr := 'Select Z_Project From %s Where Z_ID=''%s'' ';
//  nStr := Format(nStr, [sTable_ZhiKa, AL_ZhiKa]);
//  with FDM.QueryTemp(nStr) do
//  begin
//    if RecordCount > 0 then
//    begin
//      AL_Project := FieldByName('Z_Project').AsString;
//    end;
//  end;
  AL_Project := EditProject.Text;

  //更改提货信息
  nSQL := 'Update %s Set L_ZhiKa=''%s'',L_CusID=''%s'',L_CusName=''%s'',L_CusPY=''%s'','+
          ' L_SaleID=''%s'',L_SaleMan=''%s'',L_Price=''%s'',L_Area=''%s'',L_Project=''%s'' Where L_ID=''%s''';
  nSQL := Format(nSQL, [sTable_Bill,AL_ZhiKa,ACusID,ACusName,
                                    ACus_PY,ASaleID,ASaleMan,Trim(EditPrice.Text),
                                    ACus_Area,AL_Project, nL_ID]);
  FDM.ExecuteSQL(nSQL);
  WriteOptionLog(nL_ID);

  //更新资金
  nStr := 'Update %s Set A_OutMoney=A_OutMoney+%s Where A_CID=''%s''';
  nStr := Format(nStr, [sTable_CusAccount, FloatToStr(AL_Money),
          ACusID]);
  FDM.ExecuteSQL(nStr);

  nStr := 'Update %s Set Z_MoneyUsed=Z_MoneyUsed+(%.2f) Where Z_ID=''%s''';
  nStr := Format(nStr, [sTable_ZhiKa,  AL_Money, AL_ZhiKa]);
  FDM.ExecuteSQL(nStr);

  //更新资金
  nStr := 'Update %s Set A_OutMoney=A_OutMoney-%s Where A_CID=''%s''';
  nStr := Format(nStr, [sTable_CusAccount, FloatToStr(nL_Money),
          nL_CusID]);
  FDM.ExecuteSQL(nStr);

  nStr := 'Update %s Set Z_MoneyUsed=Z_MoneyUsed-(%.2f) Where Z_ID=''%s''';
  nStr := Format(nStr, [sTable_ZhiKa,  nL_Money, nL_ZhiKa]);
  FDM.ExecuteSQL(nStr);

  ModalResult := mrOk;

  nStr := '勘误完成';
  ShowMsg(nStr, sHint);
end;

procedure TfFormBillKW.WriteOptionLog(const LID: string);
var nEvent: string;
begin
  nEvent := '';

  try
    nEvent := nEvent + '业务人员由 [ %s ] --> [ %s ];';
    nEvent := Format(nEvent, [nL_SaleMan, ASaleMan]);

    nEvent := nEvent + '客户由 [ %s ] --> [ %s ];';
    nEvent := Format(nEvent, [nL_CusName, ACusName]);

    nEvent := nEvent + '纸卡编码由 [ %s ] --> [ %s ];';
    nEvent := Format(nEvent, [nL_ZhiKa, EditZK.Text]);

    nEvent := nEvent + '价格由 [ %s ] --> [ %s ];';
    nEvent := Format(nEvent, [nL_Price, EditPrice.Text]);

    if nEvent <> '' then
    begin
      nEvent := '提货单 [ %s ] 记录已被修改:' + nEvent;
      nEvent := Format(nEvent, [LID]);
    end;
    if nEvent <> '' then
    begin
      FDM.WriteSysLog(sFlag_BillItem, LID, nEvent);
    end;
  except
  end;
end;

procedure TfFormBillKW.EditZKPropertiesEditValueChanged(Sender: TObject);
var
  nStr : string;
begin
  inherited;
  if (EditZK.ItemIndex > -1) then
  begin
    AL_ZhiKa := GetCtrlData(EditZK);
    nStr := 'Select Z_Project From %s Where Z_ID=''%s'' ';
    nStr := Format(nStr, [sTable_ZhiKa, AL_ZhiKa]);
    with FDM.QueryTemp(nStr) do
    begin
      if RecordCount > 0 then
      begin
        AL_Project       := FieldByName('Z_Project').AsString;
        EditProject.Text := FieldByName('Z_Project').AsString;
      end;
    end;
  end;
end;

initialization
  gControlManager.RegCtrl(TfFormBillKW, TfFormBillKW.FormID);
end.
