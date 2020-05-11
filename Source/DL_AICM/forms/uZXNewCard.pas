{*******************************************************************************
  作者: juner11212436@163.com 2017-12-28
  描述: 自助办卡窗口--单厂版
*******************************************************************************}
unit uZXNewCard;

{$I Link.Inc}
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxLabel, Menus, StdCtrls, cxButtons, cxGroupBox,
  cxRadioGroup, cxTextEdit, cxCheckBox, ExtCtrls, dxLayoutcxEditAdapters,
  dxLayoutControl, cxDropDownEdit, cxMaskEdit, cxButtonEdit,
  USysConst, cxListBox, ComCtrls,Uszttce_api,Contnrs,UFormCtrl,
  dxSkinsCore, dxSkinsDefaultPainters, dxSkinsdxLCPainter;

type

  TfFormNewCard = class(TForm)
    editWebOrderNo: TcxTextEdit;
    labelIdCard: TcxLabel;
    btnQuery: TcxButton;
    PanelTop: TPanel;
    PanelBody: TPanel;
    dxLayout1: TdxLayoutControl;
    BtnOK: TButton;
    BtnExit: TButton;
    EditValue: TcxTextEdit;
    EditCus: TcxTextEdit;
    EditCName: TcxTextEdit;
    EditStock: TcxTextEdit;
    EditSName: TcxTextEdit;
    EditTruck: TcxButtonEdit;
    EditType: TcxComboBox;
    EditPrice: TcxButtonEdit;
    dxLayoutGroup1: TdxLayoutGroup;
    dxGroup1: TdxLayoutGroup;
    dxlytmLayout1Item3: TdxLayoutItem;
    dxlytmLayout1Item4: TdxLayoutItem;
    dxGroup2: TdxLayoutGroup;
    dxlytmLayout1Item9: TdxLayoutItem;
    dxlytmLayout1Item10: TdxLayoutItem;
    dxGroupLayout1Group5: TdxLayoutGroup;
    dxlytmLayout1Item13: TdxLayoutItem;
    dxLayout1Item11: TdxLayoutItem;
    dxGroupLayout1Group6: TdxLayoutGroup;
    dxlytmLayout1Item12: TdxLayoutItem;
    dxLayout1Item8: TdxLayoutItem;
    dxLayoutGroup3: TdxLayoutGroup;
    dxLayoutItem1: TdxLayoutItem;
    dxLayout1Item2: TdxLayoutItem;
    dxLayout1Group1: TdxLayoutGroup;
    pnlMiddle: TPanel;
    cxLabel1: TcxLabel;
    lvOrders: TListView;
    Label1: TLabel;
    btnClear: TcxButton;
    TimerAutoClose: TTimer;
    dxLayout1Group2: TdxLayoutGroup;
    edt_YunFei: TcxTextEdit;
    dxlytmLayout1Item1: TdxLayoutItem;
    dxlytmFact: TdxLayoutItem;
    cbb_Factory: TcxComboBox;
    dxLayout1Item1: TdxLayoutItem;
    PrintHY: TcxCheckBox;
    dxLayout1Group3: TdxLayoutGroup;
    procedure BtnExitClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure TimerAutoCloseTimer(Sender: TObject);
    procedure btnQueryClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure BtnOKClick(Sender: TObject);
    procedure lvOrdersClick(Sender: TObject);
    procedure editWebOrderNoKeyPress(Sender: TObject; var Key: Char);
    procedure btnClearClick(Sender: TObject);
  private
    { Private declarations }
    FSzttceApi:TSzttceApi; //发卡机驱动
    FAutoClose:Integer; //窗口自动关闭倒计时（分钟）
    FWebOrderIndex:Integer; //商城订单索引
    FWebOrderItems:array of stMallOrderItem; //商城订单数组
    FCardData:TStrings; //云天系统返回的大票号信息
    Fbegin:TDateTime;
    nSuccCard : string;

    procedure InitListView;
    procedure SetControlsReadOnly;
    function DownloadOrder(const nCard:string):Boolean;
    procedure Writelog(nMsg:string);
    procedure AddListViewItem(var nWebOrderItem:stMallOrderItem);
    procedure LoadSingleOrder;
    function IsRepeatCard(const nWebOrderItem:string;var nLId:string):Boolean;
    function CanUseCard(const nCardNo: string): Boolean;
    function VerifyCtrl(Sender: TObject; var nHint: string): Boolean;
    function SaveBillProxy:Boolean;
    function SaveWebOrderMatch(const nBillID,nWebOrderID,nBillType:string):Boolean;
    procedure LoadStockFactory;
    function IsEleCardVaid(const nTruckNo,nStockNo: string): Boolean;
  public
    { Public declarations }
    procedure SetControlsClear;
    property SzttceApi:TSzttceApi read FSzttceApi write FSzttceApi;
  end;

var
  fFormNewCard: TfFormNewCard;

implementation
uses
  ULibFun,UBusinessPacker,USysLoger,UBusinessConst,UFormMain,USysBusiness,USysDB,
  UAdjustForm,UFormBase,UDataReport,UDataModule,NativeXml,UMgrTTCEDispenser,UFormWait,
  DateUtils;
{$R *.dfm}

{ TfFormNewCard }

procedure TfFormNewCard.SetControlsClear;
var
  i:Integer;
  nComp:TComponent;
begin
  editWebOrderNo.Clear;
  for i := 0 to dxLayout1.ComponentCount-1 do
  begin
    nComp := dxLayout1.Components[i];
    if nComp is TcxTextEdit then
    begin
      TcxTextEdit(nComp).Clear;
    end;
  end;
end;

procedure TfFormNewCard.BtnExitClick(Sender: TObject);
begin
  Close;
end;

procedure TfFormNewCard.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  FCardData.Free;  nSuccCard:= '';
  Action:=  caFree;
  fFormNewCard := nil;
end;

// 加载开单工厂
procedure TfFormNewCard.LoadStockFactory;
var nStr: string;
    i,nIdx: integer;
begin
  cbb_Factory.Clear;
  cbb_Factory.Properties.Items.Clear;
  nStr := ' Select * From Sys_Dict  Where D_Name=''BillFromFactory''';
  //扩展信息

  with FDM.QueryTemp(nStr) do
  if RecordCount > 0 then
  begin
    First;
    while not Eof do
    begin
        nStr := FieldByName('D_Value').AsString;
        cbb_Factory.Properties.Items.Add(nStr);
        Next;
    end;
  end;
  {$IFNDEF SendMorefactoryStock}           // 开单将根据开单工厂打印单据 声威
  dxlytmFact.Visible:= False;
  cbb_Factory.ItemIndex:= 0;
  {$ENDIF}
end;

procedure TfFormNewCard.FormShow(Sender: TObject);
begin
  SetControlsReadOnly;
  dxlytmLayout1Item13.Visible := False;      dxlytmFact.Visible:= False;
  EditTruck.Properties.Buttons[0].Visible := False;
  ActiveControl := editWebOrderNo;
  btnOK.Enabled := False;
  FAutoClose := gSysParam.FAutoClose_Mintue;
  TimerAutoClose.Interval := 60*1000;
  TimerAutoClose.Enabled := True;
  EditPrice.Properties.Buttons[0].Visible := False;
  dxLayout1Item11.Visible := False;           nSuccCard:= '';
  LoadStockFactory;
  {$IFDEF PrintHYEach}
  PrintHY.Checked := True;
  {$ELSE}
  PrintHY.Checked := False;
  {$ENDIF}     PrintHY.Visible := False;
end;

procedure TfFormNewCard.SetControlsReadOnly;
var
  i:Integer;
  nComp:TComponent;
begin
  for i := 0 to dxLayout1.ComponentCount-1 do
  begin
    nComp := dxLayout1.Components[i];
    if nComp is TcxTextEdit then
    begin
      TcxTextEdit(nComp).Properties.ReadOnly := True;
    end;
  end;
  EditPrice.Properties.ReadOnly := True;
end;

procedure TfFormNewCard.TimerAutoCloseTimer(Sender: TObject);
begin
  if FAutoClose=0 then
  begin
    TimerAutoClose.Enabled := False;
    Close;
  end;
  Dec(FAutoClose);
end;

procedure TfFormNewCard.btnQueryClick(Sender: TObject);
var
  nCardNo,nStr:string;
begin
  FAutoClose := gSysParam.FAutoClose_Mintue;
  btnQuery.Enabled := False;
  try
    nCardNo := Trim(editWebOrderNo.Text);
    if nCardNo='' then
    begin
      nStr := '请先输入或扫描订单号';
      ShowMsg(nStr,sHint);
      Writelog(nStr);
      Exit;
    end;
    lvOrders.Items.Clear;
    if not DownloadOrder(nCardNo) then Exit;
    btnOK.Enabled := True;
  finally
    btnQuery.Enabled := True;
  end;
end;

function TfFormNewCard.DownloadOrder(const nCard: string): Boolean;
var
  nXmlStr,nData, nStr:string;
  nListA,nListB:TStringList;
  i:Integer;
  nWebOrderCount:Integer;
begin
  Result := False;
  FWebOrderIndex := 0;

  nXmlStr := PackerEncodeStr(nCard);

  FBegin:= Now;
  nData := Get_ShopOrderByNo(nXmlStr);
//  nData := 'b3JkZXJfaWQ9NDAyOGVmZWY2M2IwNTllYTAxNjNlMWJiNDNhZDA4Y2MNCmZhY19vcmRlcl9ubz1aSzAwMDAwMDExNQ0Kb3JkZXJudW1iZXI9MTgwNjA5MTk3MQ0KZ29vZH'+
//           'NJRD1zaHVpbmlwYzMyLjVyZA0KZ29vZHNuYW1lPSi0/NewKVAuQzMyLjVSDQp0cmFja251bWJlcj24ykE3NjAwNQ0KZGF0YT04DQoNCg==';
  if nData='' then
  begin
    ShowMsg('未查询到网上商城订单详细信息，请检查订单号是否正确',sHint);
    Writelog('未查询到网上商城订单详细信息，请检查订单号是否正确');
    Exit;
  end;
  Writelog('TfFormNewCard.DownloadOrder(nCard='''+nCard+''') 查询商城订单-耗时：'+InttoStr(MilliSecondsBetween(Now, FBegin))+'ms');
  //解析网城订单信息
  Writelog('get_shoporderbyno res:'+nData);
  nListA := TStringList.Create;
  nListB := TStringList.Create;
  try
    nListA.Text := nData;   nSuccCard:= nCard;

    nWebOrderCount := nListA.Count;
    SetLength(FWebOrderItems,nWebOrderCount);
    for i := 0 to nWebOrderCount-1 do
    begin
      nListB.Text := PackerDecodeStr(nListA.Strings[i]);

      FWebOrderItems[i].FYunTianOrderId := nListB.Values['fac_order_no'];
      FWebOrderItems[i].FOrder_id := nListB.Values['order_id'];
      FWebOrderItems[i].FOrdernumber := nListB.Values['ordernumber'];           
      FWebOrderItems[i].FGoodsID := nListB.Values['goodsID'];
      //*******************************************
      nStr := 'Select D_StockName From %s a Join %s b on a.Z_ID = b.D_ZID ' +
              'Where Z_ID=''%s'' and D_StockNo=''%s'' ';
      nStr := Format(nStr,[sTable_ZhiKa,sTable_ZhiKaDtl,FWebOrderItems[i].FYunTianOrderId,FWebOrderItems[i].FGoodsID]);
      with FDM.QueryTemp(nStr) do
      begin
        if RecordCount>0 then
        begin
          FWebOrderItems[i].FGoodsname  := Fields[0].AsString;
        end;
      end;
      //*******************************************
      FWebOrderItems[i].FGoodstype := nListB.Values['goodstype'];
      //FWebOrderItems[i].FGoodsname := nListB.Values['goodsname'];
      FWebOrderItems[i].FData := nListB.Values['data'];
      FWebOrderItems[i].Ftracknumber := nListB.Values['tracknumber'];

      AddListViewItem(FWebOrderItems[i]);
    end;
  finally
    nListB.Free;
    nListA.Free;
  end;
  LoadSingleOrder;
end;

procedure TfFormNewCard.Writelog(nMsg: string);
var
  nStr:string;
begin
  nStr := 'WebOrder[%s]ClientId[%s]ClientName[%s]sotckno[%s]StockName[%s]';
  nStr := Format(nStr,[editWebOrderNo.Text,EditCus.Text,EditCName.Text,EditStock.Text,EditSName.Text]);
  gSysLoger.AddLog(nStr+nMsg);
end;

procedure TfFormNewCard.AddListViewItem(
  var nWebOrderItem: stMallOrderItem);
var
  nListItem:TListItem;
begin
  nListItem := lvOrders.Items.Add;
  nlistitem.Caption := nWebOrderItem.FOrdernumber;

  nlistitem.SubItems.Add(nWebOrderItem.FGoodsID);
  nlistitem.SubItems.Add(nWebOrderItem.FGoodsname);
  nlistitem.SubItems.Add(nWebOrderItem.Ftracknumber);
  nlistitem.SubItems.Add(nWebOrderItem.FData);
  nlistitem.SubItems.Add(nWebOrderItem.FYunTianOrderId);
end;

procedure TfFormNewCard.InitListView;
var
  col:TListColumn;
begin
  lvOrders.ViewStyle := vsReport;
  col := lvOrders.Columns.Add;
  col.Caption := '网上订单编号';
  col.Width := 300;
  col := lvOrders.Columns.Add;
  col.Caption := '水泥型号';
  col.Width := 200;
  col := lvOrders.Columns.Add;
  col.Caption := '水泥名称';
  col.Width := 200;
  col := lvOrders.Columns.Add;
  col.Caption := '提货车辆';
  col.Width := 200;
  col := lvOrders.Columns.Add;
  col.Caption := '办理吨数';
  col.Width := 150;
  col := lvOrders.Columns.Add;
  col.Caption := '订单编号';
  col.Width := 250;
end;

procedure TfFormNewCard.FormCreate(Sender: TObject);
begin
  editWebOrderNo.Properties.MaxLength := gSysParam.FWebOrderLength;
  FCardData := TStringList.Create;
  if not Assigned(FDR) then
  begin
    FDR := TFDR.Create(Application);
  end;
  InitListView;
  gSysParam.FUserID := 'AICM';
end;

procedure TfFormNewCard.LoadSingleOrder;
var
  nOrderItem:stMallOrderItem;
  nRepeat:Boolean;
  nWebOrderID, nLid:string;
  nMsg,nStr:string;
begin
  nOrderItem := FWebOrderItems[FWebOrderIndex];
  nWebOrderID := nOrderItem.FOrdernumber;   nLid:= '';

  FBegin := Now;
  nRepeat := IsRepeatCard(nWebOrderID, nLid);

  if nRepeat then
  begin
    nMsg := '此订单已成功办卡，请勿重复操作';
    ShowMsg(nMsg,sHint);
    Writelog(nMsg);
    Exit;
  end;
  writelog('TfFormNewCard.LoadSingleOrder 检查商城订单是否重复使用-耗时：'+InttoStr(MilliSecondsBetween(Now, FBegin))+'ms');

  //填充界面信息

  //基本信息
  EditCus.Text    := '';
  EditCName.Text  := '';

  nStr := 'Select Z_Customer,D_Price,D_YunFei From %s a join %s b on a.Z_ID = b.D_ZID ' +
          'where Z_ID=''%s'' and D_StockNo=''%s'' ';

  nStr := Format(nStr,[sTable_ZhiKa,sTable_ZhiKaDtl,nOrderItem.FYunTianOrderId,nOrderItem.FGoodsID]);
  with fdm.QueryTemp(nStr) do
  begin
    if RecordCount = 1 then
    begin
      EditCus.Text    := Fields[0].AsString;
      EditPrice.Text  := Fields[1].AsString;
      edt_YunFei.Text := Fields[2].AsString;
    end;
  end;

  nStr := 'Select C_Name From %s Where C_ID=''%s'' ';
  nStr := Format(nStr, [sTable_Customer, EditCus.Text]);
  with fdm.QueryTemp(nStr) do
  begin
    if RecordCount>0 then
    begin
      EditCName.Text  := Fields[0].AsString;
    end;
  end;

  //提单信息
  EditType.ItemIndex := 0;
  EditStock.Text  := nOrderItem.FGoodsID;
  EditSName.Text  := nOrderItem.FGoodsname;
  EditValue.Text := nOrderItem.FData;
  EditTruck.Text := nOrderItem.Ftracknumber;

  BtnOK.Enabled := not nRepeat;
end;

function TfFormNewCard.IsRepeatCard(const nWebOrderItem: string;var nLId:string): Boolean;
var
  nStr:string;
begin
  Result := False;
//  nStr := 'Select * From %s Where WOM_WebOrderID=''%s''';
//  nStr := Format(nStr,[sTable_WebOrderMatch, nWebOrderItem]);
//  with fdm.QueryTemp(nStr) do
//  begin
//    if RecordCount>0 then
//    begin
//      nLId:= FieldByName('WOM_LID').AsString;
//      Result := True;
//    end;
//  end;
end;

function TfFormNewCard.CanUseCard(const nCardNo: string): Boolean;
var
  nStr:string;
begin
  Result := False;
  nStr := 'Select * From %s Where L_Card=''%s''';
  nStr := Format(nStr,[sTable_Bill,nCardNo]);
  with FDM.QueryTemp(nStr) do
  begin
    Result:= RecordCount=0;
  end;

  nStr := 'Select * From %s Where O_Card=''%s''';
  nStr := Format(nStr,[sTable_Order,nCardNo]);
  with FDM.QueryTemp(nStr) do
  begin
    Result:= RecordCount=0;
  end;

  nStr := 'Select * From %s Where C_Card=''%s'' ';
  nStr := Format(nStr,[sTable_Card,nCardNo]);
  with FDM.QueryTemp(nStr) do
  begin
    Result:= RecordCount=1;
  end;
end;

function TfFormNewCard.VerifyCtrl(Sender: TObject;
  var nHint: string): Boolean;
var nVal: Double;
begin
  Result := True;

  if Sender = EditTruck then
  begin
    Result := Length(EditTruck.Text) > 2;
    if not Result then
    begin
      nHint := '车牌号长度应大于2位';
      Writelog(nHint);
      Exit;
    end;
  end;
  if Sender = EditValue then
  begin
    Result := IsNumber(EditValue.Text, True) and (StrToFloat(EditValue.Text)>0);
    if not Result then
    begin
      nHint := '请填写有效的办理量';
      Writelog(nHint);
      Exit;
    end;

    Result := IsNumber(EditValue.Text, True) and (StrToFloat(EditValue.Text)>0.5);
    if not Result then
    begin
      nHint := '开单量过少、请到前台办理';
      Writelog(nHint);
      Exit;
    end;
  end;
end;

function TfFormNewCard.IsEleCardVaid(const nTruckNo,nStockNo: string): Boolean;
var
  nStr,nSql:string;
begin
  Result := False;

  nStr := 'Select D_Value,D_Memo,D_ParamB From $Table Where D_Name=''$Name'' And D_Value=''$Value'' ' +
          'And D_Memo=''$Memo'' Order By D_Index ASC';
  nStr := MacroValue(nStr, [MI('$Table', sTable_SysDict),
                            MI('$Name', sFlag_NoEleCard),
                            MI('$Value', nStockNo) ]);
  //xxxxx
  with FDM.QueryTemp(nStr) do
  begin
    if RecordCount > 0 then
    begin
      Result := True;
      Exit;
    end;
  end;

  nSql := 'Select * From %s Where T_Truck = ''%s'' ';
  nSql := Format(nSql,[sTable_Truck,nTruckNo]);

  with FDM.QueryTemp(nSql) do
  begin
    if RecordCount>0 then
    begin
      if (FieldByName('T_Card').AsString = '') and (FieldByName('T_Card2').AsString = '') then
        Exit;
      Result := FieldByName('T_CardUse').AsString = sFlag_Yes;
    end;
  end;
end;

procedure TfFormNewCard.BtnOKClick(Sender: TObject);
begin
  BtnOK.Enabled := False;
  try
    if (nSuccCard='')or(nSuccCard<>Trim(editWebOrderNo.Text)) then
    begin
      ShowMsg('请确认您的网上订单号是否正确  '+ nSuccCard +' - '+Trim(editWebOrderNo.Text), sHint);
      Exit;
    end;
    if not SaveBillProxy then Exit;
    nSuccCard:= '' ;
    Close;
  finally
    BtnOK.Enabled := True;            //PrintBillRt('TH181021311', False);
  end;
end;

function TfFormNewCard.SaveBillProxy: Boolean;
var
  nHint:string;
  nList,nTmp,nStocks: TStrings;
  nPrint,nInFact:Boolean;
  nBillData, nFact, nBillID, nWebOrderID:string;
  nNewCardNo, nLid, nType:string;
  nidx:Integer;
  i:Integer;
  nRet, IsDai: Boolean;
  nOrderItem:stMallOrderItem;
begin
  Result := False;   IsDai:= False;
  nOrderItem := FWebOrderItems[FWebOrderIndex];
  nWebOrderID := editWebOrderNo.Text;     nLid:= '';

    if Trim(EditValue.Text) = '' then
    begin
      ShowMsg('获取物料价格异常！请联系工作人员',sHint);
      Writelog('获取物料价格异常！请联系工作人员');
      Exit;
    end;

    if not VerifyCtrl(EditTruck,nHint) then
    begin
      ShowMsg(nHint,sHint);
      Writelog(nHint);
      Exit;
    end;

    if not VerifyCtrl(EditValue,nHint) then
    begin
      ShowMsg(nHint,sHint);
      Writelog(nHint);
      Exit;
    end;

    {$IFDEF SanNeedChksEleCard}
    if not (Pos('袋',EditSName.Text) > 0) then
    if not IsEleCardVaid(EditTruck.Text,EditStock.Text) then
    begin
      ShowMsg('车辆未办理电子标签或电子标签未启用！请联系工作人员', sHint);
      Exit;
    end;
    {$ENDIF}

    nNewCardNo := '';
    Fbegin := Now;

    try
      //连续三次读卡均失败，则回收卡片，重新发卡
      for i := 0 to 3 do
      begin
        for nIdx:=0 to 3 do
        begin
          nNewCardNo:= gDispenserManager.GetCardNo(gSysParam.FTTCEK720ID, nHint, False);
          if nNewCardNo<>'' then Break;
          Sleep(500);
        end;
        //连续三次读卡,成功则退出。
        if nNewCardNo<>'' then
          if IsCardValid(nNewCardNo) then Break;
      end;

      if nNewCardNo = '' then
      begin
        ShowDlg('卡箱异常,请查看是否有卡.', sWarn, Self.Handle);
        Exit;
      end
      else WriteLog(nNewCardNo);
    except on Ex:Exception do
      begin
        WriteLog('卡箱异常 '+Ex.Message);
        ShowDlg('卡箱异常, 请联系管理人员.', sWarn, Self.Handle);
      end;
    end;

    if Not CanUseCard(nNewCardNo) then
    begin
      gDispenserManager.RecoveryCard(gSysParam.FTTCEK720ID, nHint);
      ShowDlg('发卡失败、请新扫描开卡.', sWarn, Self.Handle);
      Exit;
    end;
    //解析卡片
    WriteLog('TfFormNewCard.SaveBillProxy 发卡机读卡-耗时：'+InttoStr(MilliSecondsBetween(Now, FBegin))+'ms');

  if Not IsRepeatCard(nWebOrderID, nLid) then
  begin
    //保存提货单
    nStocks := TStringList.Create;
    nList := TStringList.Create;
    nTmp := TStringList.Create;
    try
      LoadSysDictItem(sFlag_PrintBill, nStocks);

      if Pos('袋',EditSName.Text) > 0 then
      begin
        IsDai:= True;
        nTmp.Values['Type'] := 'D';
      end
      else nTmp.Values['Type'] := 'S';

      nTmp.Values['StockNO'] := EditStock.Text;
      nTmp.Values['StockName'] := EditSName.Text;
      nTmp.Values['Price'] := EditPrice.Text;
      nTmp.Values['YunFeiPrice'] := edt_YunFei.Text;
      nTmp.Values['Value'] := EditValue.Text;

      if PrintHY.Checked  then
           nTmp.Values['PrintHY'] := sFlag_Yes
      else nTmp.Values['PrintHY'] := sFlag_No;

      nList.Add(PackerEncodeStr(nTmp.Text));
      nPrint := nStocks.IndexOf(EditStock.Text) >= 0;

      with nList do
      begin
        Values['Bills'] := PackerEncodeStr(nList.Text);
        Values['ZhiKa'] := nOrderItem.FYunTianOrderId;
        Values['Truck'] := EditTruck.Text;
        Values['Lading'] := sFlag_TiHuo;
        Values['Memo']  := EmptyStr;
        Values['IsVIP'] := Copy(GetCtrlData(EditType),1,1);
        Values['Seal'] := '';
        Values['HYDan'] := '';
        Values['WebOrderID'] := nWebOrderID;

        {$IFDEF SendMorefactoryStock}           // 开单将根据开单工厂打印单据 声威
        nFact:= GetCtrlData(cbb_Factory);

        if nFact='' then
        begin
          {$IFDEF SWYL}
          Values['SendFactory'] := '榆林';
          {$ENDIF}

          {$IFDEF SWAS}
          Values['SendFactory'] := '安塞';
          {$ENDIF}
        end
        else Values['SendFactory'] := nFact;
        {$ENDIF}
      end;
      Writelog('单据内容：'+nList.Text);
      nBillData := PackerEncodeStr(nList.Text);
      FBegin := Now;
      nBillID := SaveBill(nBillData);
      if nBillID = '' then Exit;
      Writelog('TfFormNewCard.SaveBillProxy 生成提货单['+nBillID+']-耗时：'+InttoStr(MilliSecondsBetween(Now, FBegin))+'ms');
      FBegin := Now;
      SaveWebOrderMatch(nBillID,nWebOrderID,sFlag_Sale);
      Writelog('TfFormNewCard.SaveBillProxy 保存商城订单号-耗时：'+InttoStr(MilliSecondsBetween(Now, FBegin))+'ms');
    finally
      nStocks.Free;
      nList.Free;
      nTmp.Free;
    end;

    ShowMsg('提货单保存成功', sHint);
  end
  else nBillID:= nLid;

  if (nBillID = '') or (nNewCardNo = '') then
  begin
    Writelog('生成提货单失败、请到柜台开单');
    Exit;
  end;

  FBegin := Now;
  nRet := SaveBillCard(nBillID,nNewCardNo);
  if nRet then
  begin
    nRet := False;
    for nIdx := 0 to 3 do
    begin
      nRet := gDispenserManager.SendCardOut(gSysParam.FTTCEK720ID, nHint);
      if nRet then Break;
      Sleep(500);
    end;
    //发卡
  end;
  if nRet then
  begin
    nHint := '商城订单号['+editWebOrderNo.Text+']发卡成功,卡号['+nNewCardNo+'],请收好您的卡片';
    WriteLog(nHint);
    ShowMsg(nHint,sWarn);
  end
  else begin
    gDispenserManager.RecoveryCard(gSysParam.FTTCEK720ID, nHint);

    nHint := '商城订单号['+editWebOrderNo.Text+'],卡号['+nNewCardNo+']关联订单失败，请到开票窗口重新关联。';
    WriteLog(nHint);
    ShowDlg(nHint,sHint,Self.Handle);
  end;
  writelog('TfFormNewCard.SaveBillProxy 发卡机出卡并关联磁卡号-耗时：'+InttoStr(MilliSecondsBetween(Now, FBegin))+'ms');

  if nPrint then
    PrintBillReport(nBillID, True);           
  //print report
  {$IFDEF AICMPrintHGZ}
  PrintHeGeReport(nBillID, False);
  {$ENDIF}
  {$IFDEF CQJJSN}
  if IsDai then
    PrintBillRt(nBillID, False);
  // 开单小票
  {$ENDIF}

  if nRet then Close;
end;

function TfFormNewCard.SaveWebOrderMatch(const nBillID,
  nWebOrderID,nBillType: string):Boolean;
var
  nStr:string;
begin
  Result := False;
  nStr := MakeSQLByStr([
  SF('WOM_WebOrderID'   , nWebOrderID),
  SF('WOM_LID'          , nBillID),
  SF('WOM_StatusType'   , c_WeChatStatusCreateCard),
  SF('WOM_MsgType'      , cSendWeChatMsgType_AddBill),
  SF('WOM_BillType'     , nBillType),
  SF('WOM_deleted'     , sFlag_No)
  ], sTable_WebOrderMatch, '', True);
  fdm.ADOConn.BeginTrans;
  try
    fdm.ExecuteSQL(nStr);
    fdm.ADOConn.CommitTrans;
    Result := True;
  except
    fdm.ADOConn.RollbackTrans;
  end;
end;

procedure TfFormNewCard.lvOrdersClick(Sender: TObject);
var
  nSelItem:TListItem;
  i:Integer;
begin
  nSelItem := lvorders.Selected;
  if Assigned(nSelItem) then
  begin
    for i := 0 to lvOrders.Items.Count-1 do
    begin
      if nSelItem = lvOrders.Items[i] then
      begin
        FWebOrderIndex := i;
        LoadSingleOrder;
        Break;
      end;
    end;
  end;
end;

procedure TfFormNewCard.editWebOrderNoKeyPress(Sender: TObject;
  var Key: Char);
begin
  FAutoClose := gSysParam.FAutoClose_Mintue;
  if Key=Char(vk_return) then
  begin
    key := #0;     btnQuery.SetFocus;
    btnQuery.Click;
  end;
end;

procedure TfFormNewCard.btnClearClick(Sender: TObject);
begin
  FAutoClose := gSysParam.FAutoClose_Mintue;
  editWebOrderNo.Clear;
  ActiveControl := editWebOrderNo;
  nSuccCard:= '';
end;

end.
