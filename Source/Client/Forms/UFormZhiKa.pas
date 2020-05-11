{*******************************************************************************
  作者: dmzn@163.com 2010-3-8
  描述: 纸卡办理
*******************************************************************************}
unit UFormZhiKa;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  UFormNormal, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, Menus, ImgList,
  cxCheckListBox, cxLabel, cxButtonEdit, cxDropDownEdit, cxCalendar,
  cxMaskEdit, cxTextEdit, dxLayoutControl, StdCtrls, cxCheckBox;

type
  TfFormZhiKa = class(TfFormNormal)
    EditPName: TcxTextEdit;
    dxLayout1Item8: TdxLayoutItem;
    EditLading: TcxComboBox;
    dxLayout1Item11: TdxLayoutItem;
    EditDays: TcxDateEdit;
    dxLayout1Item18: TdxLayoutItem;
    EditName: TcxTextEdit;
    dxLayout1Item13: TdxLayoutItem;
    EditCode: TcxButtonEdit;
    dxLayout1Item3: TdxLayoutItem;
    EditAll: TcxTextEdit;
    dxLayout1Item5: TdxLayoutItem;
    EditMoney: TcxTextEdit;
    dxLayout1Item6: TdxLayoutItem;
    dxLayout1Item7: TdxLayoutItem;
    EditCustomer: TcxButtonEdit;
    Label1: TcxLabel;
    dxLayout1Item9: TdxLayoutItem;
    ListItems: TcxCheckListBox;
    dxLayout1Item10: TdxLayoutItem;
    cxImageList1: TcxImageList;
    PMenu1: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    Check1: TcxCheckBox;
    dxLayout1Item4: TdxLayoutItem;
    Label2: TcxLabel;
    dxLayout1Item12: TdxLayoutItem;
    EditUsed: TcxTextEdit;
    dxLayout1Item14: TdxLayoutItem;
    dxLayout1Group3: TdxLayoutGroup;
    dxLayout1Group6: TdxLayoutGroup;
    dxLayout1Group2: TdxLayoutGroup;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure BtnOKClick(Sender: TObject);
    procedure EditCodePropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure N1Click(Sender: TObject);
    procedure ListItemsExit(Sender: TObject);
    procedure EditMoneyPropertiesChange(Sender: TObject);
    procedure EditCustomerPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure Check1Click(Sender: TObject);
  protected
    { Protected declarations }
    FRecordID: string;
    //记录编号
    FCusID,FCusName,FSaleMan: string;
    //客户信息
    procedure InitFormData(const nID: string);
    //载入数据
  public
    { Public declarations }
    class function CreateForm(const nPopedom: string = '';
      const nParam: Pointer = nil): TWinControl; override;
    class function FormID: integer; override;
    function OnVerifyCtrl(Sender: TObject; var nHint: string): Boolean; override;
  end;

implementation

{$R *.dfm}

uses
  IniFiles, UBusinessConst, ULibFun, UMgrControl, UAdjustForm, UDataModule,
  UFormCtrl, UFormBase, UFrameBase, USysDB, USysConst, USysBusiness;

type
  TZhiKaItem = record
    FDays: TDateTime;
    FMoney: Double;
    FMoneyAll: string;
    FMoneyUsed: Double;
    FMoneyTotal: Double;
  end;

var
  gZhiKa: TZhiKaItem;
  gStockTypes: TStockTypeItems;

class function TfFormZhiKa.CreateForm(const nPopedom: string;
  const nParam: Pointer): TWinControl;
var nP: PFormCommandParam;
    nD: TFormCommandParam;
begin
  Result := nil;
  nD.FCommand := cCmd_AddData;

  if Assigned(nParam) then
       nP := nParam
  else nP := @nD;

  case nP.FCommand of
   cCmd_AddData:
    with TfFormZhiKa.Create(Application) do
    begin
      FRecordID := '';
      Caption := '纸卡 - 办理';

      InitFormData('');
      nP.FCommand := cCmd_ModalResult;
      nP.FParamA := ShowModal;
      Free;
    end;
   cCmd_EditData:
    with TfFormZhiKa.Create(Application) do
    begin
      FRecordID := nP.FParamA;
      Caption := '纸卡 - 修改';

      InitFormData(FRecordID);
      nP.FCommand := cCmd_ModalResult;
      nP.FParamA := ShowModal;
      Free;
    end;
  end;
end;

class function TfFormZhiKa.FormID: integer;
begin
  Result := cFI_FormZhiKa;
end;

procedure TfFormZhiKa.FormCreate(Sender: TObject);
var nIni: TIniFile;
begin
  nIni := TIniFile.Create(gPath + sFormConfig);
  try
    LoadFormConfig(Self, nIni);
  finally
    nIni.Free;
  end;

  AdjustCtrlData(Self);
end;

procedure TfFormZhiKa.FormClose(Sender: TObject; var Action: TCloseAction);
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
//Desc: 纸卡编号
procedure TfFormZhiKa.InitFormData(const nID: string);
var nStr: string;
    nIdx: Integer;
begin
  if nID = '' then
  begin
    FCusID := '';
    FCusName := '';
    FSaleMan := '';

    EditName.Text := '标准纸卡';
    EditDays.Date := Date() + 90;
    EditLading.ItemIndex := 0;
    EditCode.Text := MakeZhiKaCode();
  end;

  with gZhiKa do
  begin
    FMoney := 0;
    FMoneyUsed := 0;
    FMoneyTotal := 0;
  end;

  ListItems.Clear;
  GetLadingStockItems(gStockTypes);

  for nIdx:=Low(gStockTypes) to High(gStockTypes) do
  with ListItems.Items.Add, gStockTypes[nIdx] do
  begin
    Text := FName;
    Tag := nIdx;
  end;

  if nID <> '' then
  begin
    nStr := 'Select zk.*,C_Name From %s zk ' +
            ' Left Join %s On C_ID=Z_Customer Where Z_ID=''%s''';
    nStr := Format(nStr, [sTable_ZhiKa, sTable_Customer, nID]);

    with FDM.QueryTemp(nStr) do
    begin
      BtnOK.Enabled := RecordCount > 0;
      if RecordCount < 1 then
      begin
        ShowMsg('纸卡已丢失', sHint);
        Exit;
      end;

      FCusID := FieldByName('Z_Customer').AsString;
      FCusName := FieldByName('C_Name').AsString;
      
      EditCustomer.Text := Format('%s.%s', [FCusID, FCusName]);
      EditCustomer.Enabled := False;

      EditName.Text := FieldByName('Z_Name').AsString;
      EditPName.Text := FieldByName('Z_Project').AsString;
      EditCode.Text := FieldByName('Z_Password').AsString;

      SetCtrlData(EditLading, FieldByName('Z_Lading').AsString);
      EditDays.Date := FieldByName('Z_ValidDays').AsDateTime;
      Check1.Checked := FieldByName('Z_MoneyAll').AsString = sFlag_Yes;
      Check1.Enabled := False;

      gZhiKa.FDays := EditDays.Date;
      gZhiKa.FMoneyAll := FieldByName('Z_MoneyAll').AsString; 
      if FieldByName('Z_InValid').AsString = sFlag_Yes then //无效卡
           gZhiKa.FMoney := 0
      else gZhiKa.FMoney := FieldByName('Z_Money').AsFloat;

      EditMoney.Text := Format('%.2f', [gZhiKa.FMoney]);
      gZhiKa.FMoneyTotal := GetCustomerValidMoney(FCusID, True) + gZhiKa.FMoney;
      EditAll.Text := Format('%.2f', [gZhiKa.FMoneyTotal]);

      gZhiKa.FMoneyUsed := GetZhikaUsedMoney(FRecordID);
      EditUsed.Text := Format('%.2f', [gZhiKa.FMoneyUsed]);
    end;

    nStr := 'Select D_StockNo From %s Where D_ZID=''%s''';
    nStr := Format(nStr, [sTable_ZhiKaDtl, nID]);

    with FDM.QueryTemp(nStr) do
    if RecordCount > 0 then
    begin
      First;
      while not Eof do
      begin
        nStr := Fields[0].AsString;
        for nIdx:=ListItems.Count-1 downto 0 do
        if nStr = gStockTypes[ListItems.Items[nIdx].Tag].FID then
        begin
          ListItems.Items[nIdx].Checked := True;
          Break;
        end;

        Next;
      end;
    end;
  end;
end;

procedure TfFormZhiKa.EditCustomerPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
var nP: TFormCommandParam;
begin
  nP.FParamA := FCusName;
  CreateBaseFormItem(cFI_FormGetCustom, '', @nP);

  if (nP.FCommand = cCmd_ModalResult) and (nP.FParamA = mrOK) and
     (nP.FParamB <> FCusID) then
  begin
    FCusID := nP.FParamB;
    FCusName := nP.FParamC;
    FSaleMan := nP.FParamD;
    EditCustomer.Text := Format('%s.%s', [FCusID, FCusName]);

    gZhiKa.FMoneyTotal := GetCustomerValidMoney(FCusID, True);
    EditAll.Text := Format('%.2f', [gZhiKa.FMoneyTotal]);
    ActiveControl := EditMoney;
  end;
end;

procedure TfFormZhiKa.ListItemsExit(Sender: TObject);
begin
  ListItems.ItemIndex := -1;
end;

procedure TfFormZhiKa.EditCodePropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  EditCode.Text := MakeZhiKaCode();
end;

procedure TfFormZhiKa.EditMoneyPropertiesChange(Sender: TObject);
begin
  if IsNumber(EditMoney.Text, True) and (StrToFloat(EditMoney.Text) > 0) then
       Label2.Caption := SmallTOBig(StrToFloat(EditMoney.Text))
  else Label2.Caption := '元';
end;

procedure TfFormZhiKa.Check1Click(Sender: TObject);
begin
  EditMoney.Enabled := not Check1.Checked;
  if Check1.Checked then
       EditMoney.Text := '0'
  else EditMoney.Text := Format('%.2f', [gZhiKa.FMoney]);
end;

procedure TfFormZhiKa.N1Click(Sender: TObject);
var nIdx: Integer;
begin
  for nIdx:=ListItems.Items.Count-1 downto 0 do
  with ListItems.Items[nIdx] do
  begin
    case (Sender as TComponent).Tag of
     10: Checked := True;
     20: Checked := False;
     30: Checked := not Checked;
    end;
  end;
end;

function TfFormZhiKa.OnVerifyCtrl(Sender: TObject; var nHint: string): Boolean;
begin
  Result := True;
  if Sender = EditCustomer then
  begin
    Result := FCusID <> '';
    nHint := '请选择客户';
  end else

  if Sender = EditCode then
  begin
    EditCode.Text := Trim(EditCode.Text);
    Result := EditCode.Text <> '';
    nHint := '请选择提货代码';
  end else

  if Sender = EditLading then
  begin
    Result := EditLading.ItemIndex >= 0;
    nHint := '请选择提货方式';
  end else

  if Sender = EditDays then
  begin
    if FRecordID = '' then
         Result := EditDays.Date >= Date() + 1
    else Result := True;
    nHint := '提货时长至少一天';
  end else

  if Sender = EditMoney then
  begin
    Result := IsNumber(EditMoney.Text, True);
    if Result and (not Check1.Checked) then
      if FRecordID = '' then
           Result := StrToFloat(EditMoney.Text) > 0
      else Result := StrToFloat(EditMoney.Text) >= 0;
    nHint := '请输入有效的金额';
  end;
end;

//Desc: 保存数据
procedure TfFormZhiKa.BtnOKClick(Sender: TObject);
var nStr,nID,nInValid: string;
    nVal: Double;
    nIdx: Integer;
    nNew,nVerify: Boolean;
begin
  if not IsDataValid then Exit;
  //check valid
  
  if not Check1.Checked then
  begin
    nVal := GetCustomerValidMoney(FCusID, True) + gZhiKa.FMoney;
    if nVal <> gZhiKa.FMoneyTotal then
      EditAll.Text := Format('%.2f', [nVal]);
    //new money

    if not FloatRelation(nVal, StrToFloat(EditMoney.Text), rtGE) then
    begin
      ActiveControl := EditMoney;
      ShowMsg('纸卡金额不能超过总金额', sHint);
      Exit;
    end;

    if FRecordID <> '' then
    begin
      nVal := GetZhikaUsedMoney(FRecordID);
      if nVal <> gZhiKa.FMoneyUsed then
        EditUsed.Text := Format('%.2f', [nVal]);
      //new used

      if FloatRelation(nVal, StrToFloat(EditMoney.Text), rtGreater) then
      begin
        ActiveControl := EditMoney;
        ShowMsg('纸卡金额不能小于已用金额', sHint);
        Exit;
      end;
    end;
  end;

  if FRecordID = '' then
       nID := GetSerialNo(sFlag_BusGroup, sFlag_ZhiKa, False)
  else nID := FRecordID;
  if nID = '' then Exit; //invalid id

  FDM.ADOConn.BeginTrans;
  try
    nNew := FRecordID = '';
    if not nNew then
    begin
      nStr := 'Delete From %s Where D_ZID=''%s''';
      nStr := Format(nStr, [sTable_ZhiKaDtl, FRecordID]);
      FDM.ExecuteSQL(nStr);
    end;

    nVal := StrToFloat(EditMoney.Text);
    if (Check1.Checked or (nVal > 0)) and (EditDays.Date > Date()) then
         nInValid := sFlag_No
    else nInValid := sFlag_Yes;

    nVerify := not IsZhiKaNeedVerify();
    nStr := SF('Z_ID', FRecordID);
    
    nStr := MakeSQLByStr([SF('Z_Name', EditName.Text),
            SF('Z_Project', EditPName.Text),
            SF('Z_Lading', GetCtrlData(EditLading)),
            SF('Z_InValid', nInValid),
            SF('Z_ValidDays', EditDays.Date, sfDate),
            SF('Z_Password', EditCode.Text),
            SF('Z_Money', EditMoney.Text, sfVal),

            SF_IF([SF('Z_ID', nID), ''], nNew),
            SF_IF([SF('Z_Customer', FCusID), ''], nNew),
            SF_IF([SF('Z_SaleMan', FSaleMan), ''], nNew),
            SF_IF([SF('Z_MoneyUsed', 0, sfVal), ''], nNew),
            SF_IF([SF('Z_Freeze', sFlag_No), ''], nNew),
            SF_IF([SF('Z_Man', gSysParam.FUserID), ''], nNew),
            SF_IF([SF('Z_Date', sField_SQLServer_Now, sfVal), ''], nNew),
            SF_IF([SF('Z_MoneyAll', sFlag_Yes),
                   SF('Z_MoneyAll', sFlag_No)], Check1.Checked),
            //xxxxx
            
            SF_IF([SF_IF([SF('Z_Verified', sFlag_Yes),
                          SF('Z_Verified', sFlag_No)], nVerify), ''], nNew),
            SF_IF([SF_IF([SF('Z_VerifyMan', gSysParam.FUserID),
                          ''], nVerify), ''], nNew),
            SF_IF([SF_IF([SF('Z_VerifyDate', sField_SQLServer_Now, sfVal),
                          ''], nVerify), ''], nNew)
            //xxxxx
            ], sTable_ZhiKa, nStr, nNew);
    FDM.ExecuteSQL(nStr);

    for nIdx:=0 to ListItems.Count-1 do
    with ListItems.Items[nIdx] do
    begin
      if not Checked then Continue;
      nStr := MakeSQLByStr([SF('D_ZID', nID),
              SF('D_Type', gStockTypes[Tag].FType),
              SF('D_StockNo', gStockTypes[Tag].FID),
              SF('D_StockName', gStockTypes[Tag].FName),
              SF('D_Price', 0, sfVal),
              SF('D_Value', 0, sfVal),
              SF('D_FLPrice', 0, sfVal),
              SF('D_YunFei', 0, sfVal),
              SF('D_PPrice', 0, sfVal),
              SF('D_TPrice', sFlag_Yes)
              ], sTable_ZhiKaDtl, '', True);
      FDM.ExecuteSQL(nStr);
    end;

    if not nNew then
    begin
      nStr := '';
      if gZhiKa.FDays <> EditDays.Date then
        nStr := Format('有效期:[ %s -> %s ] ', [Date2Str(gZhiKa.FDays),
         Date2Str(EditDays.Date)]);
      //xxxxx

      if Check1.Checked then
           nID := sFlag_Yes
      else nID := sFlag_No;

      if gZhiKa.FMoneyAll <> nID then
        nStr := nStr + Format('资金状态:[ %s -> %s ] ', [gZhiKa.FMoneyAll, nID]);
      //xxxxx

      nVal := StrToFloat(EditMoney.Text);
      if not FloatRelation(gZhiKa.FMoney, nVal, rtEqual) then
        nStr := nStr + Format('金额:[ %.2f -> %.2f ] ', [gZhiKa.FMoney, nVal]);
      //xxxxx

      if nStr <> '' then
        FDM.WriteSysLog(sFlag_ZhiKaItem, FRecordID, nStr, False);
      //xxxxx
    end;

    FDM.ADOConn.CommitTrans;
    ModalResult := mrOk;
  except
    on nErr: Exception do
    begin
      FDM.ADOConn.RollbackTrans;
      ShowDlg(nErr.Message, sHint);
    end;
  end;   
end;

initialization
  gControlManager.RegCtrl(TfFormZhiKa, TfFormZhiKa.FormID);
end.
