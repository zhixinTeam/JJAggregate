{*******************************************************************************
  ����: 289525016@163.com 2016-11-13
  ����: �����쿨����--���ްӵ���ˮ�����޹�˾
*******************************************************************************}
unit uNewCard;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxLabel, Menus, StdCtrls, cxButtons, cxGroupBox,
  cxRadioGroup, cxTextEdit, cxCheckBox, ExtCtrls, dxLayoutcxEditAdapters,
  dxLayoutControl, cxDropDownEdit, cxMaskEdit, cxButtonEdit,
  USysConst, cxListBox, ComCtrls,Uszttce_api,Contnrs;

type
  PWorkshop=^TWorkshop;
  TWorkshop = record
    code:string;
    desc:string;
    remainder:Integer;
    defcemmentcode:string;
    WarehouseList:TStringList;
  end;
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
    EditCard: TcxTextEdit;
    EditID: TcxTextEdit;
    EditCus: TcxTextEdit;
    EditCName: TcxTextEdit;
    EditMan: TcxTextEdit;
    EditDate: TcxTextEdit;
    EditFirm: TcxTextEdit;
    EditArea: TcxTextEdit;
    EditStock: TcxTextEdit;
    EditSName: TcxTextEdit;
    EditMax: TcxTextEdit;
    EditTruck: TcxButtonEdit;
    EditType: TcxComboBox;
    EditTrans: TcxTextEdit;
    EditWorkAddr: TcxTextEdit;
    PrintFH: TcxCheckBox;
    EditFQ: TcxButtonEdit;
    EditGroup: TcxComboBox;
    dxLayoutGroup1: TdxLayoutGroup;
    dxGroup1: TdxLayoutGroup;
    dxGroupLayout1Group2: TdxLayoutGroup;
    dxLayoutGroup2: TdxLayoutGroup;
    dxLayout1Item5: TdxLayoutItem;
    dxLayout1Item9: TdxLayoutItem;
    dxlytmLayout1Item3: TdxLayoutItem;
    dxlytmLayout1Item4: TdxLayoutItem;
    dxlytmLayout1Item5: TdxLayoutItem;
    dxlytmLayout1Item6: TdxLayoutItem;
    dxlytmLayout1Item7: TdxLayoutItem;
    dxlytmLayout1Item8: TdxLayoutItem;
    dxLayout1Item6: TdxLayoutItem;
    dxLayout1Item3: TdxLayoutItem;
    dxGroup2: TdxLayoutGroup;
    dxlytmLayout1Item9: TdxLayoutItem;
    dxlytmLayout1Item10: TdxLayoutItem;
    dxGroupLayout1Group5: TdxLayoutGroup;
    dxLayout1Group4: TdxLayoutGroup;
    dxlytmLayout1Item13: TdxLayoutItem;
    dxLayout1Item12: TdxLayoutItem;
    dxLayout1Group3: TdxLayoutGroup;
    dxLayout1Item11: TdxLayoutItem;
    dxlytmLayout1Item11: TdxLayoutItem;
    dxGroupLayout1Group6: TdxLayoutGroup;
    dxlytmLayout1Item12: TdxLayoutItem;
    dxLayout1Item8: TdxLayoutItem;
    dxLayoutGroup3: TdxLayoutGroup;
    dxLayout1Item7: TdxLayoutItem;
    dxLayoutItem1: TdxLayoutItem;
    dxLayout1Item2: TdxLayoutItem;
    dxLayout1Group1: TdxLayoutGroup;
    pnlMiddle: TPanel;
    cxLabel1: TcxLabel;
    lvOrders: TListView;
    Label1: TLabel;
    btnClear: TcxButton;
    TimerAutoClose: TTimer;
    procedure BtnExitClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure BtnOKClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnQueryClick(Sender: TObject);
    procedure editWebOrderNoKeyPress(Sender: TObject; var Key: Char);
    procedure EditValueKeyPress(Sender: TObject; var Key: Char);
    procedure lvOrdersClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure TimerAutoCloseTimer(Sender: TObject);
    procedure editWebOrderNoKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure EditGroupPropertiesChange(Sender: TObject);
  private
    { Private declarations }
    FErrorCode:Integer;
    FErrorMsg:string;
    FCardData:TStrings;
    FNewBillID,FWebOrderID:string;
    FWebOrderItems:array of stMallOrderItem;
    FWebOrderIndex,FWebOrderCount:Integer;
    FSzttceApi:TSzttceApi;
    FWorkshopList:TList;
    FAutoClose:Integer;
    FRequireCementcode:Boolean; //��ǰƷ���Ƿ���Ҫ�������
    function DownloadOrder(const nCard:string):Boolean;
    function CheckYunTianOrderInfo(const nOrderId:string;var nWebOrderItem:stMallOrderItem):Boolean;
    function SaveBillProxy:Boolean;
    function VerifyCtrl(Sender: TObject; var nHint: string): Boolean;
    procedure SaveWebOrderMatch;
    procedure SetControlsReadOnly;
    procedure InitListView;
    procedure LoadSingleOrder;
    procedure AddListViewItem(var nWebOrderItem:stMallOrderItem);
    function IsRepeatCard(const nWebOrderItem:string):Boolean;
    function LoadValidZTLineGroupSpec(const nStockno:string;const nList: TStrings):Boolean;
    function LoadWarehouseConfig:Boolean;
    function GetOutASH(const nStr: string): string;
    //��ȡ���κ�����
    function GetStockType(const nStockno:string):string;
    procedure Writelog(nMsg:string);
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
  UAdjustForm,UFormCard,UFormBase,UDataReport,UDataModule,NativeXml;
{$R *.dfm}
procedure TfFormNewCard.Writelog(nMsg:string);
var
  nStr:string;
begin
  nStr := 'weborder[%s]clientid[%s]clientname[%s]sotckno[%s]stockname[%s]';
  nStr := Format(nStr,[editWebOrderNo.Text,EditCus.Text,EditCName.Text,EditStock.Text,EditSName.Text]);
  gSysLoger.AddLog(nStr+nMsg);
end;

procedure TfFormNewCard.BtnExitClick(Sender: TObject);
begin
  Close;
end;

procedure TfFormNewCard.FormClose(Sender: TObject;
  var Action: TCloseAction);
var
  i:Integer;
  nItem:PWorkshop;
begin
  Action:=  caFree;
  fFormNewCard := nil;
  FCardData.Free;
  for i := FWorkshopList.Count-1 downto 0 do
  begin
    nItem := PWorkshop(FWorkshopList.Items[i]);
    nItem.WarehouseList.Free;
    Dispose(nItem);
  end;
  FWorkshopList.Free;
  FreeAndNil(FDR);
  fFormMain.TimerInsertCard.Enabled := True;
end;

procedure TfFormNewCard.FormShow(Sender: TObject);
begin
  SetControlsReadOnly;
  dxLayout1Item5.Visible := False;
  dxLayout1Item9.Visible := False;
  dxlytmLayout1Item5.Visible := False;
  dxlytmLayout1Item6.Visible := False;
  dxlytmLayout1Item7.Visible := False;
  dxlytmLayout1Item8.Visible := False;
  dxLayout1Item6.Visible := False;
  dxLayout1Item3.Visible := False;

//  dxLayout1Item11.Visible := False;
//  dxlytmLayout1Item11.Visible := False;
  dxlytmLayout1Item13.Visible := False;
//  dxLayout1Item12.Visible := False;
  EditTruck.Properties.Buttons[0].Visible := False;
  if not fFormMain.FCursorShow then
  begin
    EditFQ.Properties.Buttons[0].Visible := False;
  end;
  ActiveControl := editWebOrderNo;
  btnOK.Enabled := False;
  FAutoClose := gSysParam.FAutoClose_Mintue;
  TimerAutoClose.Interval := 60*1000;
  TimerAutoClose.Enabled := True;  
end;

procedure TfFormNewCard.BtnOKClick(Sender: TObject);
begin
  BtnOK.Enabled := False;
  try
    if not SaveBillProxy then Exit;
    Close;
  finally
    BtnOK.Enabled := True;
  end;
end;

procedure TfFormNewCard.FormCreate(Sender: TObject);
begin
  FCardData := TStringList.Create;
  FWorkshopList := TList.Create;
  if not Assigned(FDR) then
  begin
    FDR := TFDR.Create(Application);
  end;
  if not LoadWarehouseConfig then
  begin
    ShowMsg(FErrorMsg,sHint);
  end;
  InitListView;
  gSysParam.FUserID := 'AICM';
  FRequireCementcode := False;
  EditGroup.Properties.ImeMode := imDisable;
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
      Writelog('���������ɨ�趩����');
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
  nXmlStr,nData:string;
  nIDCard:string;
  nListA,nListB:TStringList;
  i,j:Integer;
begin
  Result := False;
  FWebOrderIndex := 0;
  nIDCard := Trim(editWebOrderNo.Text);
  nXmlStr := '<?xml version="1.0" encoding="UTF-8"?>'
            +'<DATA>'
            +'<head>'
            +'<Factory>%s</Factory>'
            +'      <NO>%s</NO>'
            +'</head>'
            +'</DATA>';

  nXmlStr := Format(nXmlStr,[gSysParam.FFactory,nIDCard]);
  nXmlStr := PackerEncodeStr(nXmlStr);

  nData := get_shoporderbyno(nXmlStr);
  if nData='' then
  begin
    ShowMsg('δ��ѯ�������̳Ƕ���['+nIDCard+']��ϸ��Ϣ�����鶩�����Ƿ���ȷ',sHint);
    Writelog('δ��ѯ�������̳Ƕ���['+nIDCard+']��ϸ��Ϣ�����鶩�����Ƿ���ȷ');
    Exit;
  end;

  //�������Ƕ�����Ϣ
  nData := PackerDecodeStr(nData);
  Writelog('get_shoporderbyno res:'+nData);
  nListA := TStringList.Create;
  nListB := TStringList.Create;
  try
    nListA.Text := nData;
    for i := nListA.Count-1 downto 0 do
    begin
      if Trim(nListA.Strings[i])='' then
      begin
        nListA.Delete(i);
      end;
    end;
    FWebOrderCount := nListA.Count;
    SetLength(FWebOrderItems,FWebOrderCount);
    for i := 0 to nListA.Count-1 do
    begin
      nListB.CommaText := nListA.Strings[i];
      FWebOrderItems[i].FOrder_id := nListB.Values['order_id'];
      FWebOrderItems[i].FOrdernumber := nListB.Values['ordernumber'];
      FWebOrderItems[i].FGoodsID := nListB.Values['goodsID'];
      FWebOrderItems[i].FGoodstype := nListB.Values['goodstype'];
      FWebOrderItems[i].FGoodsname := nListB.Values['goodsname'];
      FWebOrderItems[i].FData := nListB.Values['data'];
      FWebOrderItems[i].Ftracknumber := nListB.Values['tracknumber'];
      FWebOrderItems[i].FYunTianOrderId := nListB.Values['fac_order_no'];
      AddListViewItem(FWebOrderItems[i]);
    end;
  finally
    nListB.Free;
    nListA.Free;
  end;
  LoadSingleOrder;
end;

function TfFormNewCard.CheckYunTianOrderInfo(const nOrderId: string;
  var nWebOrderItem: stMallOrderItem): Boolean;
var
  nCardDataStr: string;
  nIn: TWorkerBusinessCommand;
  nOut: TWorkerBusinessCommand;
  nCard,nParam:string;
  nList: TStrings;

  nYuntianOrderItem:stMallOrderItem;
  nOrderNumberWeb,nOrderNumberYT:Double;
  nType:string;
begin
  FCardData.Clear;

  nCardDataStr := nOrderId;
  if not (YT_ReadCardInfo(nCardDataStr) and YT_VerifyCardInfo(nCardDataStr)) then
  begin
    ShowMsg(nCardDataStr,sHint);
    Writelog(nCardDataStr);
    Exit;
  end;

  FCardData.Text := PackerDecodeStr(nCardDataStr);

  nYuntianOrderItem.FGoodsID := FCardData.Values['XCB_Cement'];
  nYuntianOrderItem.FGoodsname := FCardData.Values['XCB_CementName'];
  nYuntianOrderItem.FOrdernumber := FCardData.Values['XCB_RemainNum'];
  nYuntianOrderItem.FCusID := FCardData.Values['XCB_Client'];
  nYuntianOrderItem.FCusName := FCardData.Values['XCB_ClientName'];

  if nWebOrderItem.FGoodsID<>nYuntianOrderItem.FGoodsID then
  begin
    ShowMsg('�̳Ƕ����в�Ʒ�ͺ�['+nWebOrderItem.FOrder_id+']����',sError);
    Writelog('�̳Ƕ����в�Ʒ�ͺ�['+nWebOrderItem.FOrder_id+']����');
    Result := False;
    Exit;
  end;

  if nWebOrderItem.FGoodsname<>nYuntianOrderItem.FGoodsname then
  begin
    ShowMsg('�̳Ƕ����в�Ʒ����['+nWebOrderItem.FGoodsname+']����',sError);
    Writelog('�̳Ƕ����в�Ʒ����['+nWebOrderItem.FGoodsname+']����');
    Result := False;
    Exit;
  end;

  nOrderNumberWeb := StrToFloatDef(nWebOrderItem.FData,0);
  nOrderNumberYT := StrToFloatDef(nYuntianOrderItem.FOrdernumber,0);

  if (nOrderNumberWeb<=0.000001) or (nOrderNumberYT<=0.000001) then
  begin
    ShowMsg('���������������ʽ����',sError);
    Writelog('���������������ʽ����');
    Result := False;
    Exit;
  end;

  if nOrderNumberWeb>nOrderNumberYT then
  begin
    ShowMsg('�̳Ƕ���������������������������Ϊ['+FloattoStr(nOrderNumberYT)+']��',sError);
    Writelog('�̳Ƕ���������������������������Ϊ['+FloattoStr(nOrderNumberYT)+']��');
    Result := False;
    Exit;
  end;

  if not gSysParam.FSanZhuangACIM then
  begin
    nType := GetStockType(nWebOrderItem.FGoodsID);
    if nType = sFlag_San then
    begin
      ShowMsg('��ǰ������ɢװ��Ʒ�����ҵ��',sError);
      Writelog('��ǰ������ɢװ��Ʒ�����ҵ��');
      Result := False;
      Exit;
    end;
  end;

  Result := True;
end;

function TfFormNewCard.SaveBillProxy: Boolean;
var
  nTruck:string;
  nBillValue:Double;
  nHint:string;

  nList,nTmp,nStocks: TStrings;
  nPrint,nInFact:Boolean;
  nInFactT: TDateTime;
  nBillData:string;
  nNewCardNo:string;
  nStr,nType:string;
begin
  FNewBillID := '';
  Result := False;
  //У���������Ϣ
  if EditID.Text='' then
  begin
    ShowMsg('δ��ѯ���϶���',sHint);
    Writelog('δ��ѯ���϶���');
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

  if FRequireCementcode then
  begin
    if EditGroup.Text='' then
    begin
      ShowMsg('δѡ�񷢻�����',sHint);
      Writelog('δѡ�񷢻�����');
      Exit;
    end;

    if EditFQ.Text='' then
    begin
      ShowMsg('���������Ч',sHint);
      Writelog('���������Ч');
      Exit;
    end;
  end;
  
  //���������
  nStocks := TStringList.Create;
  nList := TStringList.Create;
  nTmp := TStringList.Create;  
  try
    LoadSysDictItem(sFlag_PrintBill, nStocks);

    nTmp.Values['Type'] := FCardData.Values['XCB_CementType'];
    nTmp.Values['StockNO'] := FCardData.Values['XCB_Cement'];
    nTmp.Values['StockName'] := FCardData.Values['XCB_CementName'];
    nTmp.Values['Price'] := '0.00';
    nTmp.Values['Value'] := EditValue.Text;

    nList.Add(PackerEncodeStr(nTmp.Text));
    nPrint := nStocks.IndexOf(FCardData.Values['XCB_Cement']) >= 0;

    with nList do
    begin
      Values['Bills'] := PackerEncodeStr(nList.Text);
      Values['ZhiKa'] := PackerEncodeStr(FCardData.Text);
      Values['Truck'] := EditTruck.Text;
      Values['Lading'] := sFlag_TiHuo;
      nStr := GetCtrlData(EditGroup);
      Values['LineGroup'] := GetCtrlData(EditGroup);
      Values['Memo']  := EmptyStr;
      Values['IsVIP'] := Copy(GetCtrlData(EditType),1,1);
      Values['Seal'] := FCardData.Values['XCB_CementCodeID'];
      Values['HYDan'] := EditFQ.Text;
      Values['BuDan'] := sFlag_No;
      nType := GetStockType(FCardData.Values['XCB_Cement']);
//      if nType=sFlag_Dai then
//      begin
        Values['Status'] := sFlag_TruckIn;
        Values['NextStatus'] := sFlag_TruckZT;
//      end;

      nInFactT := Now;
      nInFact := TruckInFact(EditTruck.Text, nInFactT);
      if nInFact then Values['InFact'] := sFlag_Yes;
      if PrintFH.Checked  then Values['PrintFH'] := sFlag_Yes;
//      if PrintHGZ.Checked then Values['PrintHGZ'] := sFlag_Yes;
      //��װ����ֱ����Ϊ����״̬
//      if nType=sFlag_Dai then
//      begin
      Values['InFact'] := sFlag_Yes;
      Values['Status'] := sFlag_TruckIn;
      Values['NextStatus'] := sFlag_TruckZT;
//      end;
    end;
    nBillData := PackerEncodeStr(nList.Text);
    FNewBillID := SaveBill(nBillData);
    if FNewBillID = '' then Exit;
    SaveWebOrderMatch;
  finally
    nStocks.Free;
    nList.Free;
    nTmp.Free;
  end;
  ShowMsg('���������ɹ�', sHint);
  //����
  if not FSzttceApi.IssueOneCard(nNewCardNo) then
  begin
    nHint := '����ʧ��,�뵽��Ʊ���ڲ���ſ���[errorcode=%d,errormsg=%s]';
    nHint := Format(nHint,[FSzttceApi.ErrorCode,FSzttceApi.ErrorMsg]);
    Writelog(nHint);
    ShowMsg(nHint,sHint);
  end
  else begin
    ShowMsg('�����ɹ�,����['+nNewCardNo+'],���պ����Ŀ�Ƭ',sHint);
    Writelog('�����ɹ�,����['+nNewCardNo+'],���պ����Ŀ�Ƭ');
    SetBillCard(FNewBillID, EditTruck.Text,nNewCardNo, True);
  end;

  if nPrint then
    PrintBillReport(FNewBillID, True);
  //print report

  if IFPrintFYD then
    PrintBillFYDReport(FNewBillID, True);
  //��ӡ���˵� 

  Close;
end;

function TfFormNewCard.VerifyCtrl(Sender: TObject;
  var nHint: string): Boolean;
var nVal: Double;
begin
  Result := True;

  if Sender = EditTruck then
  begin
    Result := Length(EditTruck.Text) > 2;
    nHint := '���ƺų���Ӧ����2λ';
    Writelog(nHint);
  end else

  if Sender = EditValue then
  begin
    Result := IsNumber(EditValue.Text, True) and (StrToFloat(EditValue.Text)>0);
    nHint := '����д��Ч�İ�����';
    Writelog(nHint);
    if not Result then Exit;

    nVal := StrToFloat(EditValue.Text);
    Result := FloatRelation(nVal, StrToFloat(EditMax.Text),rtLE);
    nHint := '�ѳ����������';
    Writelog(nHint);
  end;
end;

procedure TfFormNewCard.editWebOrderNoKeyPress(Sender: TObject; var Key: Char);
begin
  FAutoClose := gSysParam.FAutoClose_Mintue;
  if Key=Char(vk_return) then
  begin
    key := #0;
    btnQuery.Click;
  end;
end;

procedure TfFormNewCard.EditValueKeyPress(Sender: TObject; var Key: Char);
begin
  if key=Char(vk_return) then
  begin
    key := #0;
    BtnOK.Click;
  end;
end;

procedure TfFormNewCard.SaveWebOrderMatch;
var
  nStr:string;
begin
  nStr := 'insert into %s(WOM_WebOrderID,WOM_LID) values(''%s'',''%s'')';
  nStr := Format(nStr,[sTable_WebOrderMatch,FWebOrderID,FNewBillID]);
  fdm.ADOConn.BeginTrans;
  try
    fdm.ExecuteSQL(nStr);
    fdm.ADOConn.CommitTrans;
  except
    fdm.ADOConn.RollbackTrans;
  end;
end;

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

procedure TfFormNewCard.SetControlsReadOnly;
var
  i:Integer;
  nComp:TComponent;
begin
//  editIdCard.Properties.ReadOnly := True;
  for i := 0 to dxLayout1.ComponentCount-1 do
  begin
    nComp := dxLayout1.Components[i];
    if nComp is TcxTextEdit then
    begin
      TcxTextEdit(nComp).Properties.ReadOnly := True;
    end;
  end;
  EditWorkAddr.Properties.ReadOnly := True;
  EditFQ.Properties.ReadOnly := True;
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
end;

procedure TfFormNewCard.LoadSingleOrder;
var
  nOrderItem:stMallOrderItem;
  nRepeat:Boolean;
begin
  nOrderItem := FWebOrderItems[FWebOrderIndex];
  FWebOrderID := nOrderItem.FOrdernumber;
  nRepeat := IsRepeatCard(FWebOrderID);

  if nRepeat then
  begin
    ShowMsg('�˶����ѳɹ��쿨�������ظ�����',sHint);
    Writelog('�˶����ѳɹ��쿨�������ظ�����');
    Exit;
  end;
  //������Ч��У��
  if not CheckYunTianOrderInfo(nOrderItem.FYunTianOrderId,nOrderItem) then
  begin
    BtnOK.Enabled := False;
    Exit;
  end;

  //��������Ϣ
  //������Ϣ
  EditID.Text     := FCardData.Values['XCB_ID'];
  EditCard.Text   := FCardData.Values['XCB_CardId'];
  EditCus.Text    := FCardData.Values['XCB_Client'];
  EditCName.Text  := FCardData.Values['XCB_ClientName'];
  EditMan.Text    := FCardData.Values['XCB_CreatorNM'];
  EditDate.Text   := FCardData.Values['XCB_CDate'];
  EditFirm.Text   := FCardData.Values['XCB_FirmName'];
  EditArea.Text   := FCardData.Values['pcb_name'];
  EditTrans.Text  := FCardData.Values['XCB_TransName'];
  EditWorkAddr.Text:= FCardData.Values['XCB_WorkAddr'];

  //�ᵥ��Ϣ
  //����ջ̨����
  if not LoadValidZTLineGroupSpec(FCardData.Values['XCB_Cement'],EditGroup.Properties.Items) then
  begin
    ShowMsg(FErrorMsg,sHint);
    BtnOK.Enabled := False;
    Exit;
  end;

  EditType.ItemIndex := 0;
  EditStock.Text  := FCardData.Values['XCB_Cement'];
  EditSName.Text  := FCardData.Values['XCB_CementName'];
  EditMax.Text    := FCardData.Values['XCB_RemainNum'];
  EditFQ.Text     := FCardData.Values['XCB_CementCode'];
  EditValue.Text := nOrderItem.FData;
  EditTruck.Text := nOrderItem.Ftracknumber;
  FRequireCementcode := Pos('����',EditSName.Text) = 0;

  if EditGroup.Properties.Items.Count = 1 then
  begin
    EditGroup.ItemIndex := 0;
    EditGroupPropertiesChange(nil);
  end
  else begin
    EditGroup.ItemIndex := -1;
  end;
    
  if not FRequireCementcode then
  begin
    EditFQ.Text := '';
    BtnOK.Enabled := not nRepeat;
    Exit;
  end;
  BtnOK.Enabled := not nRepeat;
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

function TfFormNewCard.IsRepeatCard(const nWebOrderItem: string): Boolean;
var
  nStr:string;
begin
  Result := False;
  nStr := 'select * from %s where WOM_WebOrderID=''%s'' and WOM_deleted=''%s''';
  nStr := Format(nStr,[sTable_WebOrderMatch,nWebOrderItem,sFlag_No]);
  with fdm.QueryTemp(nStr) do
  begin
    if RecordCount>0 then
    begin
      Result := True;
    end;
  end;
end;

function TfFormNewCard.LoadValidZTLineGroupSpec(const nStockno:string;const nList: TStrings):Boolean;
var
  i:Integer;
  nworkshopList,nworkshopNameList:TStringList;
  nSQL:string;
  nCode,nName:string;
  nData: PStringsItemData;
begin
  Result := False;
  for i := 0 to nList.Count-1 do
  begin
    Dispose(Pointer(nList.Objects[i]));
    nList.Objects[i] := nil;
  end;
  nList.Clear;

  nworkshopList := TStringList.Create;
  nworkshopNameList := TStringList.Create;
  try
    nSQL := 'select * from %s where d_name=''%s'' and d_paramb=''%s''';
    nSQL := Format(nSQL,[sTable_SysDict,sFlag_AICMWorkshop,nStockno]);
    with FDM.QueryTemp(nSql) do
    begin
      if RecordCount<1 then
      begin
        FErrorCode := 1010;
        FErrorMsg := '��ǰû�п��õ�װ���ߣ���Ⱥ�';
        Writelog('��ǰû�п��õ�װ���ߣ���Ⱥ�');
        Exit;
      end;
      nworkshopList.CommaText := FieldByName('d_desc').AsString;
      nworkshopNameList.CommaText := FieldByName('d_memo').AsString;
    end;

    for i := 0 to nworkshopList.Count-1 do
    begin
      nCode := nworkshopList.Strings[i];
      nName := nworkshopNameList.Strings[i];
      New(nData);
      nList.Add(nName+'.');
      nData.FString := nCode;
      nList.Objects[i] := TObject(nData);
    end;
  finally
    nworkshopList.Free;
    nworkshopNameList.Free;
  end;
  Result := True;
end;

function TfFormNewCard.LoadWarehouseConfig: Boolean;
var
  nFileName:string;
  nRoot,nworkshopNode, nWarehouseNode: TXmlNode;
  nXML: TNativeXml;
  nPWorkshopItem:PWorkshop;
  i,j,nworkshopCount,nWarehouseCount:Integer;
  nStr:string;
begin
  Result := False;
  nFileName := ExtractFilePath(ParamStr(0))+'Warehouse_config.xml';
  if not FileExists(nFileName) then
  begin
    FErrorCode := 1000;
    FErrorMsg := 'ϵͳ�����ļ�['+nFileName+']������';
    Writelog('ϵͳ�����ļ�['+nFileName+']������');
    Exit;
  end;

  nXML := TNativeXml.Create;
  try
    nXML.LoadFromFile(nFileName);
    nRoot := nXML.Root;
    nworkshopCount := nRoot.NodeCount;
    for i := 0 to nworkshopCount-1 do
    begin
      nworkshopNode := nRoot.Nodes[i];
      New(nPWorkshopItem);
      nPWorkshopItem.code := UTF8Decode(nworkshopNode.ReadAttributeString('code'));
      nPWorkshopItem.desc := UTF8Decode(nworkshopNode.ReadAttributeString('desc'));
      nPWorkshopItem.remainder := StrToIntDef(UTF8Decode(nworkshopNode.ReadAttributeString('remainder')),0);
      nPWorkshopItem.defcemmentcode := UTF8Decode(nworkshopNode.ReadAttributeString('defcemmentcode'));
      nPWorkshopItem.WarehouseList := TStringList.Create;
      nWarehouseCount := nworkshopNode.NodeCount;
      for j := 0 to nWarehouseCount-1 do
      begin
        nWarehouseNode := nworkshopNode.Nodes[j];
        nStr := UTF8Decode(nWarehouseNode.ValueAsString);
        nPWorkshopItem.WarehouseList.Add(nStr);
      end;
      FWorkshopList.Add(nPWorkshopItem);
    end;
    Result := True;
  finally
    nXML.Free;
  end;
end;

function TfFormNewCard.GetOutASH(const nStr: string): string;
var nPos: Integer;
    nTmp: string;
begin
  nTmp := nStr;
  nPos := Pos('.', nTmp);

  System.Delete(nTmp, 1, nPos);
  Result := nTmp;
end;

function TfFormNewCard.getStockType(const nStockno: string): string;
var
  nSql:string;
begin
  Result := '';
  nSql := 'select D_Memo from %s where d_name = ''%s'' and d_paramB=''%s''';
  nSql := Format(nSql,[sTable_SysDict,sFlag_StockItem,nStockno]);

  with FDM.QueryTemp(nSql) do
  begin
    if recordcount>0 then
    begin
      Result := FieldByName('D_Memo').AsString;
    end;
  end;
end;

procedure TfFormNewCard.btnClearClick(Sender: TObject);
begin
  FAutoClose := gSysParam.FAutoClose_Mintue;
  editWebOrderNo.Clear;
  ActiveControl := editWebOrderNo;
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

procedure TfFormNewCard.editWebOrderNoKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  FAutoClose := gSysParam.FAutoClose_Mintue;
end;

procedure TfFormNewCard.EditGroupPropertiesChange(Sender: TObject);
var
  nGroupCode:string; //�����������
  nSQL:string;
  nSpecCemmentCode:TStringList;//����ͻ���ˮ����
  i:Integer;
  nPWorkshop:PWorkshop; //��������xml������Ϣ
  nCementData,nListA, nListB: TStrings;
  nStr:string;
  nIdxBatchItem:integer;//���ó������ѭ������
  nPostfix:Integer;//�����ֺ�׺
  nPostfix_str:string;//��#���ַ�����׺
  nBatchValue:double;//�������ʣ������
  ndOrderValue:Double;//��������
  nCementCode:string;//���ճ������ֵ
  nCementCodeID:string;//���ճ������IDֵ
  nFoundSuccess:Boolean;//�Ƿ��ҵ����ʵĳ������
begin
  FCardData.Values['XCB_CementCode'] := '';
  FCardData.Values['XCB_CementCodeID'] := '';
  EditFQ.Text     := '';
  BtnOK.Enabled := True;
  if not FRequireCementcode then Exit;
  nCementCode := '';
  nFoundSuccess := False;
  nGroupCode := GetCtrlData(EditGroup);
  if nGroupCode='' then Exit;

  nSpecCemmentCode := TStringList.Create;
  try
    //begin��ȡ����ͻ�ˮ����
    nSQL := 'select * from %s where SCC_CusID=''%s''';
    nSQL := Format(nSQL,[sTable_SpecialCustomerCementcode,FCardData.Values['XCB_Client']]);
    with FDM.QuerySQL(nSQL) do
    begin
      if RecordCount>0 then
      begin
        nSpecCemmentCode.CommaText := FieldByName('SCC_Cementcode').asString;
      end;
    end;
    //end��ȡ����ͻ�ˮ����

    //begin��ȡ��ǰ���������Ӧ��xml������Ϣ
    for i := 0 to FWorkshopList.Count-1 do
    begin
      nPWorkshop := PWorkshop(FWorkshopList.Items[i]);
      if nPWorkshop.code=nGroupCode then Break;
    end;
    //end��ȡ��ǰ���������Ӧ��xml������Ϣ

    //begin��ȡ��ǰ���еĿ��ó������
    nCementData := TStringList.Create;
    nListA := TStringList.Create;
    nListB := TStringList.Create;
    try
      nStr := GetOutASH(EditGroup.Text);
      FCardData.Values['XCB_OutASH'] := nStr;
       nCementData.Text := YT_GetBatchCode(FCardData);
      nListA.Text := PackerDecodeStr(nCementData.Values['XCB_CementRecords']);
      for nIdxBatchItem := 0 to nListA.Count - 1 do
      begin
        nListB.Text := PackerDecodeStr(nListA[nIdxBatchItem]);
        nBatchValue := StrToFloat(nListB.Values['XCB_CementValue']);
        if nBatchValue-ndOrderValue>0.001 then
        begin
          nCementCode := nListB.Values['XCB_CementCode'];
          nCementCodeID := nListB.Values['XCB_CementCodeID'];
          if Pos('#',nCementCode)=0 then
          begin
            nPostfix_str := Copy(nCementCode,Pos('��',nCementCode),Length(nCementCode));
            nStr := Copy(nCementCode,Pos('��',nCementCode)+length('��'),Length(nCementCode));
            nPostfix := StrToIntDef(nStr,0);
          end
          else begin
            nPostfix_str := Copy(nCementCode,Pos('#',nCementCode),Length(nCementCode));
            nStr := Copy(nCementCode,Pos('#',nCementCode)+length('#'),Length(nCementCode));
            nPostfix := StrToIntDef(nStr,0);
          end;

          //�ж��Ƿ�����ͻ�
          if nSpecCemmentCode.Count>0 then
          begin
            if nSpecCemmentCode.IndexOf(nPostfix_str)<>-1 then
            begin
              nFoundSuccess := True;
              Break;
            end;
          end
          //����ͻ�
          else begin
            //�ж��Ƿ�ש�ߺ�������ש�ȹ̶���׺
            if nPWorkshop.defcemmentcode<>'' then
            begin
              if nPWorkshop.defcemmentcode=nPostfix_str then
              begin
                nFoundSuccess := True;
                Break;
              end;
            end

            //�޹̶���׺��������ż�ж�
            else begin
              nPostfix := nPostfix mod 2;
              if nPostfix=nPWorkshop.remainder then
              begin
                nFoundSuccess := True;
                Break;
              end;
            end;
          end;
        end;
      end;
    finally
      nListA.Free;
      nListB.Free;
      nCementData.Free;
    end;
    //end��ȡ��ǰ���еĿ��ó������
  finally
    nSpecCemmentCode.Free;
  end;

  if not nFoundSuccess then
  begin
    FErrorCode := 1020;
    FErrorMsg := 'δ�ҵ����ʵĳ�����ţ��뵽��Ʊ���ڰ���';
    Writelog(FErrorMsg);
    ShowMsg(FErrorMsg,sHint);
    BtnOK.Enabled := False;
    Exit;
  end;

  FCardData.Values['XCB_CementCode'] := nCementCode;
  FCardData.Values['XCB_CementCodeID'] := nCementCodeID;
  EditFQ.Text     := FCardData.Values['XCB_CementCode'];
end;

end.
