{*******************************************************************************
  ����: juner11212436@163.com 2017-12-28
  ����: �����쿨����--������
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
    FSzttceApi:TSzttceApi; //����������
    FAutoClose:Integer; //�����Զ��رյ���ʱ�����ӣ�
    FWebOrderIndex:Integer; //�̳Ƕ�������
    FWebOrderItems:array of stMallOrderItem; //�̳Ƕ�������
    FCardData:TStrings; //����ϵͳ���صĴ�Ʊ����Ϣ
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

// ���ؿ�������
procedure TfFormNewCard.LoadStockFactory;
var nStr: string;
    i,nIdx: integer;
begin
  cbb_Factory.Clear;
  cbb_Factory.Properties.Items.Clear;
  nStr := ' Select * From Sys_Dict  Where D_Name=''BillFromFactory''';
  //��չ��Ϣ

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
  {$IFNDEF SendMorefactoryStock}           // ���������ݿ���������ӡ���� ����
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
      nStr := '���������ɨ�趩����';
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
    ShowMsg('δ��ѯ�������̳Ƕ�����ϸ��Ϣ�����鶩�����Ƿ���ȷ',sHint);
    Writelog('δ��ѯ�������̳Ƕ�����ϸ��Ϣ�����鶩�����Ƿ���ȷ');
    Exit;
  end;
  Writelog('TfFormNewCard.DownloadOrder(nCard='''+nCard+''') ��ѯ�̳Ƕ���-��ʱ��'+InttoStr(MilliSecondsBetween(Now, FBegin))+'ms');
  //�������Ƕ�����Ϣ
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
  col.Caption := '���϶������';
  col.Width := 300;
  col := lvOrders.Columns.Add;
  col.Caption := 'ˮ���ͺ�';
  col.Width := 200;
  col := lvOrders.Columns.Add;
  col.Caption := 'ˮ������';
  col.Width := 200;
  col := lvOrders.Columns.Add;
  col.Caption := '�������';
  col.Width := 200;
  col := lvOrders.Columns.Add;
  col.Caption := '�������';
  col.Width := 150;
  col := lvOrders.Columns.Add;
  col.Caption := '�������';
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
    nMsg := '�˶����ѳɹ��쿨�������ظ�����';
    ShowMsg(nMsg,sHint);
    Writelog(nMsg);
    Exit;
  end;
  writelog('TfFormNewCard.LoadSingleOrder ����̳Ƕ����Ƿ��ظ�ʹ��-��ʱ��'+InttoStr(MilliSecondsBetween(Now, FBegin))+'ms');

  //��������Ϣ

  //������Ϣ
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

  //�ᵥ��Ϣ
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
      nHint := '���ƺų���Ӧ����2λ';
      Writelog(nHint);
      Exit;
    end;
  end;
  if Sender = EditValue then
  begin
    Result := IsNumber(EditValue.Text, True) and (StrToFloat(EditValue.Text)>0);
    if not Result then
    begin
      nHint := '����д��Ч�İ�����';
      Writelog(nHint);
      Exit;
    end;

    Result := IsNumber(EditValue.Text, True) and (StrToFloat(EditValue.Text)>0.5);
    if not Result then
    begin
      nHint := '���������١��뵽ǰ̨����';
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
      ShowMsg('��ȷ���������϶������Ƿ���ȷ  '+ nSuccCard +' - '+Trim(editWebOrderNo.Text), sHint);
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
      ShowMsg('��ȡ���ϼ۸��쳣������ϵ������Ա',sHint);
      Writelog('��ȡ���ϼ۸��쳣������ϵ������Ա');
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
    if not (Pos('��',EditSName.Text) > 0) then
    if not IsEleCardVaid(EditTruck.Text,EditStock.Text) then
    begin
      ShowMsg('����δ������ӱ�ǩ����ӱ�ǩδ���ã�����ϵ������Ա', sHint);
      Exit;
    end;
    {$ENDIF}

    nNewCardNo := '';
    Fbegin := Now;

    try
      //�������ζ�����ʧ�ܣ�����տ�Ƭ�����·���
      for i := 0 to 3 do
      begin
        for nIdx:=0 to 3 do
        begin
          nNewCardNo:= gDispenserManager.GetCardNo(gSysParam.FTTCEK720ID, nHint, False);
          if nNewCardNo<>'' then Break;
          Sleep(500);
        end;
        //�������ζ���,�ɹ����˳���
        if nNewCardNo<>'' then
          if IsCardValid(nNewCardNo) then Break;
      end;

      if nNewCardNo = '' then
      begin
        ShowDlg('�����쳣,��鿴�Ƿ��п�.', sWarn, Self.Handle);
        Exit;
      end
      else WriteLog(nNewCardNo);
    except on Ex:Exception do
      begin
        WriteLog('�����쳣 '+Ex.Message);
        ShowDlg('�����쳣, ����ϵ������Ա.', sWarn, Self.Handle);
      end;
    end;

    if Not CanUseCard(nNewCardNo) then
    begin
      gDispenserManager.RecoveryCard(gSysParam.FTTCEK720ID, nHint);
      ShowDlg('����ʧ�ܡ�����ɨ�迪��.', sWarn, Self.Handle);
      Exit;
    end;
    //������Ƭ
    WriteLog('TfFormNewCard.SaveBillProxy ����������-��ʱ��'+InttoStr(MilliSecondsBetween(Now, FBegin))+'ms');

  if Not IsRepeatCard(nWebOrderID, nLid) then
  begin
    //���������
    nStocks := TStringList.Create;
    nList := TStringList.Create;
    nTmp := TStringList.Create;
    try
      LoadSysDictItem(sFlag_PrintBill, nStocks);

      if Pos('��',EditSName.Text) > 0 then
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

        {$IFDEF SendMorefactoryStock}           // ���������ݿ���������ӡ���� ����
        nFact:= GetCtrlData(cbb_Factory);

        if nFact='' then
        begin
          {$IFDEF SWYL}
          Values['SendFactory'] := '����';
          {$ENDIF}

          {$IFDEF SWAS}
          Values['SendFactory'] := '����';
          {$ENDIF}
        end
        else Values['SendFactory'] := nFact;
        {$ENDIF}
      end;
      Writelog('�������ݣ�'+nList.Text);
      nBillData := PackerEncodeStr(nList.Text);
      FBegin := Now;
      nBillID := SaveBill(nBillData);
      if nBillID = '' then Exit;
      Writelog('TfFormNewCard.SaveBillProxy ���������['+nBillID+']-��ʱ��'+InttoStr(MilliSecondsBetween(Now, FBegin))+'ms');
      FBegin := Now;
      SaveWebOrderMatch(nBillID,nWebOrderID,sFlag_Sale);
      Writelog('TfFormNewCard.SaveBillProxy �����̳Ƕ�����-��ʱ��'+InttoStr(MilliSecondsBetween(Now, FBegin))+'ms');
    finally
      nStocks.Free;
      nList.Free;
      nTmp.Free;
    end;

    ShowMsg('���������ɹ�', sHint);
  end
  else nBillID:= nLid;

  if (nBillID = '') or (nNewCardNo = '') then
  begin
    Writelog('���������ʧ�ܡ��뵽��̨����');
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
    //����
  end;
  if nRet then
  begin
    nHint := '�̳Ƕ�����['+editWebOrderNo.Text+']�����ɹ�,����['+nNewCardNo+'],���պ����Ŀ�Ƭ';
    WriteLog(nHint);
    ShowMsg(nHint,sWarn);
  end
  else begin
    gDispenserManager.RecoveryCard(gSysParam.FTTCEK720ID, nHint);

    nHint := '�̳Ƕ�����['+editWebOrderNo.Text+'],����['+nNewCardNo+']��������ʧ�ܣ��뵽��Ʊ�������¹�����';
    WriteLog(nHint);
    ShowDlg(nHint,sHint,Self.Handle);
  end;
  writelog('TfFormNewCard.SaveBillProxy �����������������ſ���-��ʱ��'+InttoStr(MilliSecondsBetween(Now, FBegin))+'ms');

  if nPrint then
    PrintBillReport(nBillID, True);           
  //print report
  {$IFDEF AICMPrintHGZ}
  PrintHeGeReport(nBillID, False);
  {$ENDIF}
  {$IFDEF CQJJSN}
  if IsDai then
    PrintBillRt(nBillID, False);
  // ����СƱ
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
