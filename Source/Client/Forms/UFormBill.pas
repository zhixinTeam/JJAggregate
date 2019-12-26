{*******************************************************************************
  作者: dmzn@163.com 2018-12-14
  描述: 开提货单
*******************************************************************************}
unit UFormBill;

{$I Link.Inc}
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  UFormNormal, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, ComCtrls, cxMaskEdit,
  cxDropDownEdit, cxListView, cxTextEdit, cxMCListBox, dxLayoutControl,
  StdCtrls, cxButtonEdit, cxCheckBox, dxSkinsCore, dxSkinsDefaultPainters,
  dxSkinsdxLCPainter;

type
  TfFormBill = class(TfFormNormal)
    dxGroup2: TdxLayoutGroup;
    dxLayout1Item3: TdxLayoutItem;
    ListInfo: TcxMCListBox;
    dxLayout1Item4: TdxLayoutItem;
    ListBill: TcxListView;
    EditValue: TcxTextEdit;
    dxLayout1Item8: TdxLayoutItem;
    EditTruck: TcxTextEdit;
    dxLayout1Item9: TdxLayoutItem;
    EditStock: TcxComboBox;
    dxLayout1Item7: TdxLayoutItem;
    BtnAdd: TButton;
    dxLayout1Item10: TdxLayoutItem;
    BtnDel: TButton;
    dxLayout1Item11: TdxLayoutItem;
    EditLading: TcxComboBox;
    dxLayout1Item12: TdxLayoutItem;
    dxLayout1Group5: TdxLayoutGroup;
    dxLayout1Group8: TdxLayoutGroup;
    dxLayout1Group7: TdxLayoutGroup;
    dxLayout1Group2: TdxLayoutGroup;
    dxLayout1Item6: TdxLayoutItem;
    EditType: TcxComboBox;
    EditPrice: TcxButtonEdit;
    dxLayout1Item13: TdxLayoutItem;
    dxLayout1Group3: TdxLayoutGroup;
    EditPValue: TcxTextEdit;
    dxLayout1Item5: TdxLayoutItem;
    EditYFPrice: TcxTextEdit;
    dxLayout1Item15: TdxLayoutItem;
    dxLayout1Group4: TdxLayoutGroup;
    EditCarrier: TcxComboBox;
    dxLayout1Item16: TdxLayoutItem;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure EditStockPropertiesChange(Sender: TObject);
    procedure BtnAddClick(Sender: TObject);
    procedure BtnDelClick(Sender: TObject);
    procedure BtnOKClick(Sender: TObject);
    procedure EditLadingKeyPress(Sender: TObject; var Key: Char);
    procedure EditPricePropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure EditLadingPropertiesChange(Sender: TObject);
  protected
    { Protected declarations }
    FBuDanFlag: string;
    //补单标记
    procedure LoadFormData;
    procedure LoadStockList;
    //载入数据
    procedure CombinStockAndPrice(const nApplyPrice: Boolean);
    //合并价格
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
  ULibFun, DB, IniFiles, UMgrControl, UAdjustForm, UFormBase, UBusinessPacker,
  UBusinessConst, UDataModule, USysPopedom, USysBusiness, USysDB, USysGrid,
  USysConst, UFormWait, UFormPriceShow;

type
  TCommonInfo = record
    FZhiKa: string;
    FCusID: string;
    FMoney: Double;
    FOnlyMoney: Boolean;
    FIDList: string;
    FShowPrice: Boolean;
    FCard: string;
    FTruck: string;
  end;

  TStockItem = record
    FType: string;
    FStockNO: string;
    FStockName: string;
    FPrice: Double;
    FPriceIndex: Integer;
    FValue: Double;
    FSelecte: Boolean;
  end;

var
  gInfo: TCommonInfo;
  gStockTypes: TStockTypeItems;
  gStockList: array of TStockItem;
  //全局使用

class function TfFormBill.CreateForm(const nPopedom: string;
  const nParam: Pointer): TWinControl;
var nBool,nBuDan: Boolean;
    nInfo: TCommonInfo;
    nP: PFormCommandParam;
begin
  Result := nil;
  if GetSysValidDate < 1 then Exit;

  if not Assigned(nParam) then
  begin
    New(nP);
    FillChar(nP^, SizeOf(TFormCommandParam), #0);
  end else nP := nParam;

  try
    nBuDan := nPopedom = 'MAIN_D04';
    FillChar(nInfo, SizeOf(nInfo), #0);
    gInfo := nInfo;

    CreateBaseFormItem(cFI_FormGetZhika, nPopedom, nP);
    if (nP.FCommand <> cCmd_ModalResult) or (nP.FParamA <> mrOK) then Exit;

    gInfo.FCard  := '';
    gInfo.FZhiKa := nP.FParamB;
    gInfo.FCusID := nP.FParamC;
  finally
    if not Assigned(nParam) then Dispose(nP);
  end;

  with TfFormBill.Create(Application) do
  try
    ShowWaitForm(Application.MainForm, '正在加载数据', True);
    try
      LoadFormData;
      //try load data
    finally
      CloseWaitForm;
    end;

    if not BtnOK.Enabled then Exit;
    Caption := '开提货单';
    with gPopedomManager do
    begin
      gInfo.FShowPrice := HasPopedom(nPopedom, sPopedom_ViewPrice);
      nBool := not HasPopedom(nPopedom, sPopedom_Edit);
      EditLading.Properties.ReadOnly := nBool;
    end;

    if nBuDan then //补单
    begin
      FBuDanFlag := sFlag_Yes;
      dxLayout1Item5.Visible := True;
      EditPValue.Text        := '0';
    end
    else
    begin
      FBuDanFlag := sFlag_No;
      dxLayout1Item5.Visible := False;
      EditPValue.Text        := '0';
    end;

    if Assigned(nParam) then
    with PFormCommandParam(nParam)^ do
    begin
      FCommand := cCmd_ModalResult;
      FParamA := ShowModal;

      if FParamA = mrOK then
           FParamB := gInfo.FIDList
      else FParamB := '';
    end else ShowModal;
  finally
    Free;
  end;
end;

class function TfFormBill.FormID: integer;
begin
  Result := cFI_FormBill;
end;

procedure TfFormBill.FormCreate(Sender: TObject);
var nIni: TIniFile;
begin
  nIni := TIniFile.Create(gPath + sFormConfig);
  try
    LoadMCListBoxConfig(Name, ListInfo, nIni);
    LoadcxListViewConfig(Name, ListBill, nIni);
  finally
    nIni.Free;
  end;

  {$IFDEF UseCarrier}
  dxLayout1Item15.Visible := True;
  EditYFPrice.Text := '';
  dxLayout1Item16.Visible := True;
  EditCarrier.Text := '';
  {$ELSE}
  dxLayout1Item15.Visible := False;
  EditYFPrice.Text := '';
  dxLayout1Item16.Visible := False;
  EditCarrier.Text := '';
  {$ENDIF}

  AdjustCtrlData(Self);
end;

procedure TfFormBill.FormClose(Sender: TObject; var Action: TCloseAction);
var nIni: TIniFile;
begin
  nIni := TIniFile.Create(gPath + sFormConfig);
  try
    SaveMCListBoxConfig(Name, ListInfo, nIni);
    SavecxListViewConfig(Name, ListBill, nIni);
  finally
    nIni.Free;
  end;

  ReleaseCtrlData(Self);
end;

//Desc: 回车键
procedure TfFormBill.EditLadingKeyPress(Sender: TObject; var Key: Char);
var nP: TFormCommandParam;
begin
  if Key = Char(VK_RETURN) then
  begin
    Key := #0;

    if Sender = EditStock then ActiveControl := EditValue else
    if Sender = EditValue then ActiveControl := BtnAdd else
    if Sender = EditTruck then ActiveControl := EditStock else

    if Sender = EditLading then
         ActiveControl := EditTruck
    else Perform(WM_NEXTDLGCTL, 0, 0);
  end;

  if (Sender = EditTruck) and (Key = Char(VK_SPACE)) then
  begin
    Key := #0;
    nP.FParamA := EditTruck.Text;
    CreateBaseFormItem(cFI_FormGetTruck, '', @nP);

    if (nP.FCommand = cCmd_ModalResult) and(nP.FParamA = mrOk) then
      EditTruck.Text := nP.FParamB;
    EditTruck.SelectAll;
  end;
end;

//------------------------------------------------------------------------------
//Desc: 载入界面数据
procedure TfFormBill.LoadFormData;
var nStr: string;
    nDB: TDataSet;
    nIdx: integer;
begin
  BtnOK.Enabled := False;
  nDB := LoadZhiKaInfo(gInfo.FZhiKa, ListInfo, nStr);

  if Assigned(nDB) then
  with gInfo do
  begin
    FCusID := nDB.FieldByName('Z_Customer').AsString;
    SetCtrlData(EditLading, nDB.FieldByName('Z_Lading').AsString);
    FMoney := GetZhikaValidMoney(gInfo.FZhiKa, gInfo.FOnlyMoney);
  end else
  begin
    ShowMsg(nStr, sHint); Exit;
  end;

  BtnOK.Enabled := IsCustomerCreditValid(gInfo.FCusID);
  if not BtnOK.Enabled then Exit;
  //to verify credit

  BtnOK.Enabled := LoadStockItemsPrice(gInfo.FCusID, gStockTypes);
  if not BtnOK.Enabled then Exit;
  //load price

  SetLength(gStockList, 0);
  nStr := 'Select * From %s Where D_ZID=''%s''';
  nStr := Format(nStr, [sTable_ZhiKaDtl, gInfo.FZhiKa]);

  with FDM.QueryTemp(nStr) do
  if RecordCount > 0 then
  begin
    nStr := '';
    nIdx := 0;
    SetLength(gStockList, RecordCount);

    First;  
    while not Eof do
    with gStockList[nIdx] do
    begin
      FType := FieldByName('D_Type').AsString;
      FStockNO := FieldByName('D_StockNo').AsString;
      FStockName := FieldByName('D_StockName').AsString;

      FPrice := 0;
      FValue := 0;
      FSelecte := False;

      Inc(nIdx);
      Next;
    end;
  end;
  
  if Length(gStockList) < 1 then //纸卡不限提货品种
  begin
    SetLength(gStockList, Length(gStockTypes));
    for nIdx:=Low(gStockTypes) to High(gStockTypes) do
    with gStockList[nIdx] do
    begin
      FType := gStockTypes[nIdx].FType;
      FStockNO := gStockTypes[nIdx].FID;
      FStockName := gStockTypes[nIdx].FName;

      FPrice := 0;
      FValue := 0;
      FSelecte := False;
    end;
  end;

  CombinStockAndPrice(True);
  //apply price
  
  EditType.ItemIndex := 0;
  LoadStockList; //load stock into window
  ActiveControl := EditTruck;

  if EditCarrier.Properties.Items.Count < 1 then
  begin
    nStr := 'Select S_Name From %s ';
    nStr := Format(nStr, [sTable_Carrier]);

    with FDM.QueryTemp(nStr) do
    if RecordCount > 0 then
    begin
      First;
      while not Eof do
      begin
        EditCarrier.Properties.Items.Add(FieldByName('S_Name').AsString);
        Next;
      end;
    end;
  end;
end;

//Desc: 将价格合并到纸卡品种列表
procedure TfFormBill.CombinStockAndPrice(const nApplyPrice: Boolean);
var i,nIdx: Integer;
begin
  for nIdx:=Low(gStockList) to High(gStockList) do
  begin
    gStockList[nIdx].FPriceIndex := -1;
    //default
    
    for i:=Low(gStockTypes) to High(gStockTypes) do
    if gStockTypes[i].FID = gStockList[nIdx].FStockNO then
    begin
      if nApplyPrice then
        gStockList[nIdx].FPrice := gStockTypes[i].FPrice;
      gStockList[nIdx].FPriceIndex := i;
      Break;
    end;
  end;
end;

//Desc: 刷新水泥列表到窗体
procedure TfFormBill.LoadStockList;
var nStr: string;
    i,nIdx: integer;
begin
  AdjustCXComboBoxItem(EditStock, True);
  nIdx := ListBill.ItemIndex;

  ListBill.Items.BeginUpdate;
  try
    ListBill.Clear;
    for i:=Low(gStockList) to High(gStockList) do
    if gStockList[i].FSelecte then
    begin
      with ListBill.Items.Add do
      begin
        Caption := gStockList[i].FStockName;
        SubItems.Add(EditTruck.Text);
        SubItems.Add(FloatToStr(gStockList[i].FValue));

        Data := Pointer(i);
        ImageIndex := cItemIconIndex;
      end;
    end else
    begin
      nStr := Format('%d=%s', [i, gStockList[i].FStockName]); 
      EditStock.Properties.Items.Add(nStr);
    end;
  finally
    ListBill.Items.EndUpdate;
    if ListBill.Items.Count > nIdx then
      ListBill.ItemIndex := nIdx;
    //xxxxx

    AdjustCXComboBoxItem(EditStock, False);
    EditStock.ItemIndex := 0;
  end;
end;

//Dessc: 选择品种
procedure TfFormBill.EditStockPropertiesChange(Sender: TObject);
var nInt: Int64;
begin
  dxGroup2.Caption := '提单明细';
  if EditStock.ItemIndex < 0 then Exit;

  with gStockList[StrToInt(GetCtrlData(EditStock))] do
  if FPrice > 0 then
  begin
    nInt := Float2PInt(gInfo.FMoney / FPrice, cPrecision, False);
    EditValue.Text := FloatToStr(nInt / cPrecision);

    if gInfo.FShowPrice then
      dxGroup2.Caption := Format('提单明细 单价:%.2f元/吨', [FPrice]);
    //xxxxx
  end;
end;

procedure TfFormBill.EditPricePropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  if gInfo.FShowPrice then
       ShowPriceViewForm(gStockTypes)
  else ShowMsg('没有足够权限', sHint);
end;

function TfFormBill.OnVerifyCtrl(Sender: TObject; var nHint: string): Boolean;
var nVal,nMax: Double;
begin
  Result := True;

  if Sender = EditStock then
  begin
    Result := EditStock.ItemIndex > -1;
    nHint := '请选择水泥类型';
  end else

  if Sender = EditTruck then
  begin
    Result := Length(EditTruck.Text) > 2;
    nHint := '车牌号长度应大于2位';
  end else

  if Sender = EditLading then
  begin
    Result := EditLading.ItemIndex > -1;
    nHint := '请选择有效的提货方式';
  end else

  if Sender = EditValue then
  begin
    Result := IsNumber(EditValue.Text, True) and (StrToFloat(EditValue.Text)>0);
    nHint := '请填写有效的办理量';

    if not Result then Exit;
    if not OnVerifyCtrl(EditStock, nHint) then Exit;

    with gStockList[StrToInt(GetCtrlData(EditStock))] do
    if FPrice > 0 then
    begin
      nVal := Float2Float(StrToFloat(EditValue.Text), cPrecision, True);
      nMax := Float2Float(gInfo.FMoney / FPrice, cPrecision, False);
      Result := nMax >= nVal;

      nHint := '已超出可办理量';
      if not Result then Exit;

      if nMax = nVal then
      begin
        nHint := '';
        Result := QueryDlg('确定要按最大可提货量全部开出吗?', sAsk);
        if not Result then ActiveControl := EditValue;
      end;
    end else
    begin
      Result := False;
      nHint := '单价[ 0 ]无效';
    end;
  end;
end;

//Desc: 添加
procedure TfFormBill.BtnAddClick(Sender: TObject);
var nIdx: Integer;
begin
  if IsDataValid then
  begin
    nIdx := StrToInt(GetCtrlData(EditStock));
    with gStockList[nIdx] do
    begin
      if (FType = sFlag_San) and (ListBill.Items.Count > 0) then
      begin
        ShowMsg('散装品种不能混装', sHint);
        ActiveControl := EditStock;
        Exit;
      end;

      FValue := StrToFloat(EditValue.Text);
      FValue := Float2Float(FValue, cPrecision, False);
      FSelecte := True;
      
      EditTruck.Properties.ReadOnly := True;
      gInfo.FMoney := gInfo.FMoney - FPrice * FValue;
    end;

    LoadStockList;
    ActiveControl := BtnOK;
  end;
end;

//Desc: 删除
procedure TfFormBill.BtnDelClick(Sender: TObject);
var nIdx: integer;
begin
  if ListBill.ItemIndex > -1 then
  begin
    nIdx := Integer(ListBill.Items[ListBill.ItemIndex].Data);
    with gStockList[nIdx] do
    begin
      FSelecte := False;
      gInfo.FMoney := gInfo.FMoney + FPrice * FValue;
    end;

    LoadStockList;
    EditTruck.Properties.ReadOnly := ListBill.Items.Count > 0;
  end;
end;

//Desc: 保存
procedure TfFormBill.BtnOKClick(Sender: TObject);
var nIdx: Integer;
    nStr: string;
    nValue: Double;
    nPrint: Boolean;
    nList,nTmp,nStocks: TStrings;
begin
  if ListBill.Items.Count < 1 then
  begin
    ShowMsg('请先办理提货单', sHint); Exit;
  end;

  if not LoadStockItemsPrice(gInfo.FCusID, gStockTypes) then Exit;
  //重新载入价格
  CombinStockAndPrice(False);

  for nIdx:=Low(gStockList) to High(gStockList) do
  with gStockList[nIdx] do
  begin
    if not FSelecte then Continue;
    if (FPriceIndex < 0) or (FPrice <> gStockTypes[FPriceIndex].FPrice) then
    begin
      ShowDlg('当前价格已失效(刚调价),请重新执行开单操作', sHint);
      Exit;
    end;
  end;

  nValue := 0;
  for nIdx:=Low(gStockList) to High(gStockList) do
  with gStockList[nIdx] do
  begin
    if not FSelecte then Continue;
    nValue := FValue;

    if nValue >= 50 then
    begin
      nStr := '办理吨数为'+Floattostr(nValue)+',已大于等于50吨,您确定要继续办理吗？';
      if not QueryDlg(nStr, sAsk) then Exit;
    end;
  end;


  nStocks := TStringList.Create;
  nList := TStringList.Create;
  nTmp := TStringList.Create;
  try
    nList.Clear;
    nPrint := False;
    LoadSysDictItem(sFlag_PrintBill, nStocks);
    //需打印品种

    for nIdx:=Low(gStockList) to High(gStockList) do
    with gStockList[nIdx],nTmp do
    begin
      if not FSelecte then Continue;
      //xxxxx

      Values['Type'] := FType;
      Values['StockNO'] := FStockNO;
      Values['StockName'] := FStockName;
      Values['Price'] := FloatToStr(FPrice);
      Values['Value'] := FloatToStr(FValue);
      if FBuDanFlag = sFlag_Yes then
      begin
        Values['PValue'] := FloatToStr(StrToFloatDef(EditPValue.Text,0));
        Values['MValue'] := FloatToStr(StrToFloatDef(EditPValue.Text,0)+FValue);
      end;

      Values['PriceDesc'] := gStockTypes[FPriceIndex].FParam;
      //价格描述
      nList.Add(PackerEncodeStr(nTmp.Text));
      //new bill

      if (not nPrint) and (FBuDanFlag <> sFlag_Yes) then
        nPrint := nStocks.IndexOf(FStockNO) >= 0;
      //xxxxx
    end;

    with nList do
    begin
      Values['Bills']     := PackerEncodeStr(nList.Text);
      Values['ZhiKa']     := gInfo.FZhiKa;
      Values['Truck']     := EditTruck.Text;
      Values['Lading']    := GetCtrlData(EditLading);
      Values['IsVIP']     := GetCtrlData(EditType);
      Values['BuDan']     := FBuDanFlag;
      Values['Card']      := gInfo.FCard;
      Values['L_YFPrice'] := FloatToStr(StrToFloatDef(EditYFPrice.Text,0));
      Values['L_Carrier'] := EditCarrier.Text;
    end;

    BtnOK.Enabled := False;
    try
      ShowWaitForm(Self, '正在保存', True);
      gInfo.FIDList := SaveBill(PackerEncodeStr(nList.Text));
    finally
      BtnOK.Enabled := True;
      CloseWaitForm;
    end;
    //call mit bus
    if gInfo.FIDList = '' then Exit;
  finally
    nTmp.Free;
    nList.Free;
    nStocks.Free;
  end;

  if (FBuDanFlag <> sFlag_Yes) and (gInfo.FCard = '') then
    SetBillCard(gInfo.FIDList, EditTruck.Text, True);
  //办理磁卡

  if nPrint then
    PrintBillReport(gInfo.FIDList, True);
  //print report
  
  ModalResult := mrOk;
  ShowMsg('提货单保存成功', sHint);
end;

procedure TfFormBill.EditLadingPropertiesChange(Sender: TObject);
var
  nStr: string;
begin
  inherited;
  if EditLading.ItemIndex = 1 then
  begin
    nStr := 'Select C_Carrier From %s Where C_ID=''%s'' ';
    nStr := Format(nStr, [sTable_Customer, gInfo.FCusID]);

    with FDM.QueryTemp(nStr) do
    if RecordCount > 0 then
    begin
      EditCarrier.Text := FieldByName('C_Carrier').AsString;
    end;
  end
  else
  begin
    EditCarrier.Text := '';
  end;
end;

initialization
  gControlManager.RegCtrl(TfFormBill, TfFormBill.FormID);
end.
