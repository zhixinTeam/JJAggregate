unit UFormPurCardHandl;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, dxSkinsCore, dxSkinsDefaultPainters, cxTextEdit,
  cxMaskEdit, cxDropDownEdit, Provider, DBClient, DB, ADODB, Grids, USysConst,
  DBGrids, StdCtrls, ExtCtrls;

const
  sHint = '��ʾ';

type

  TFormPurCardHandl = class(TForm)
    lbl1: TLabel;
    edt1: TEdit;
    btn1: TButton;
    dbgrd1: TDBGrid;
    Ds_Mx1: TDataSource;
    Qry_1: TADOQuery;
    CltDs_1: TClientDataSet;
    dtstprvdr1: TDataSetProvider;
    lbl9: TLabel;
    lbl_ProName: TLabel;
    lbl8: TLabel;
    lbl_MName: TLabel;
    lbl7: TLabel;
    cbb_Company: TcxComboBox;
    lbl6: TLabel;
    edt_Value: TcxTextEdit;
    btnOK: TButton;
    btnExit: TButton;
    lbl4: TLabel;
    cbb_TruckNo: TcxComboBox;
    TimerAutoClose: TTimer;
    lbl2: TLabel;
    cbb_TranCmp: TcxComboBox;
    lbl_Company: TLabel;
    lbl_TranCmp: TLabel;
    Qry_2: TADOQuery;
    procedure btnExitClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btn1Click(Sender: TObject);
    procedure dbgrd1CellClick(Column: TColumn);
    procedure btnOKClick(Sender: TObject);
    procedure edt_ValueKeyPress(Sender: TObject; var Key: Char);
    procedure cbb_TranCmpPropertiesChange(Sender: TObject);
  private
    { Private declarations }
    nSuccCard: string;
    Fbegin: TDateTime;
    FOrderItems : array of stMallPurchaseItem; //��������
  private
    procedure Writelog(nMsg: string);
    procedure LoadPurCompany;
    procedure LoadTransportCompany;
    procedure SearchPurOrdersInfo(nName:string);
    function  SaveBillProxy: Boolean;
  public
    { Public declarations }
  end;

var
  FormPurCardHandl: TFormPurCardHandl;

implementation

uses                                                                                //UMgrK720Reader
  ULibFun,UBusinessPacker,USysLoger,UBusinessConst,UFormMain,USysBusiness,USysDB,Util_utf8,
  UAdjustForm,UFormBase,UDataReport,UDataModule,NativeXml,UFormWait, UMgrTTCEDispenser,
  DateUtils;

{$R *.dfm}

procedure TFormPurCardHandl.Writelog(nMsg: string);
var
  nStr:string;
begin
  nStr := '�����쿨 contractcode[%s]provname[%s]productname[%s]:';
  nStr := Format(nStr,[FOrderItems[0].Fpurchasecontract_no,FOrderItems[0].FGoodsID,FOrderItems[0].FGoodsname]);
  gSysLoger.AddLog(nStr+nMsg);
end;

procedure TFormPurCardHandl.LoadPurCompany;
var nStr: string;
    nInt, nIdx: Integer;
begin
  nStr :='Select * From %s Where D_Name=''%s'' And D_Memo=''%s'' ';
  nStr := Format(nStr, [sTable_SysDict, 'SysParam', 'PurCompany']);

  cbb_Company.Properties.Items.Clear;
  with FDM.QueryTemp(nStr) do
  begin
    if RecordCount < 1 then Exit;
    First;

    while not Eof do
    begin
      cbb_Company.Properties.Items.Add(FieldByName('D_Value').AsString);
      Next;
    end;
    //cbb_Company.ItemIndex := 0;
  end;
end;

procedure TFormPurCardHandl.LoadTransportCompany;
var nStr: string;
    nInt, nIdx: Integer;
begin
  nStr :='Select * From %s  ';
  if Trim(cbb_TranCmp.Text)<>'' then  nStr:= nStr + ' Where T_Name Like ''%%'+
          Trim(cbb_TranCmp.Text)+'%%'' Or T_PY Like ''%%'+Trim(cbb_TranCmp.Text)+'%%''';

  nStr := Format(nStr, [sTable_TransportCompany, 'SysParam', 'PurCompany']);

  cbb_TranCmp.Properties.Items.Clear;
  with FDM.QueryTemp(nStr) do
  begin
    if RecordCount < 1 then Exit;
    First;

    while not Eof do
    begin
      cbb_TranCmp.Properties.Items.Add(FieldByName('T_Name').AsString);
      Next;
    end;
    //cbb_Company.ItemIndex := 0;
  end;
end;

procedure TFormPurCardHandl.btnExitClick(Sender: TObject);
begin
  Close;
end;

procedure TFormPurCardHandl.FormShow(Sender: TObject);
begin
  TimerAutoClose.Interval := 60*1000;
  TimerAutoClose.Enabled := True;
  cbb_TranCmp.ItemIndex:= -1;
  lbl_MName.Caption:= '';
  lbl_ProName.Caption:= '';
  LoadTransportCompany;
  cbb_Company.ItemIndex:= -1;
  cbb_TruckNo.ItemIndex:= 0;
  edt_Value.Text:= '0';
  lbl_TranCmp.Caption:= '';  lbl_TranCmp.Caption:= '';
end;

procedure TFormPurCardHandl.FormCreate(Sender: TObject);
begin
  SetLength(FOrderItems, 1);
  TStringGrid(DBGrd1).DefaultRowHeight:=30;
  LoadPurCompany;
  LoadTransportCompany;
end;

procedure TFormPurCardHandl.SearchPurOrdersInfo(nName:string);
var nStr: string;
begin
  lbl_ProName.Caption:= ''; lbl_MName.Caption:= '';
  cbb_TruckNo.ItemIndex:= 0; lbl_TranCmp.Caption:= '';  lbl_TranCmp.Caption:= '';
//  nStr := ' Select * From P_OrderBase Where ((B_Value-B_SentValue>0) or (B_Value=0)) And B_BStatus=''Y'' '+
//                'And B_ProName like ''%'+nName+'%'' OR B_ProPY like ''%'+nName+'%''';
//  //��չ��Ϣ
//
//  Qry_1.DataSource.DataSet:= FDM.QuerySQLx(nStr);

  nStr := ' Select * From P_OrderBase Where ((B_Value-B_SentValue>0) or (B_Value=0)) And B_BStatus=''Y'' '+
                'And B_ID=''OB'+trim(edt1.Text)+'''';

  with FDM.QueryTemp(nStr) do
  begin

    if not Active then
    begin
      ShowMsg('δ��ѯ����ض��������鶩�����', '��ʾ');
    end;

    if RecordCount=1 then
    begin
      lbl_ProName.Caption:= '';   lbl_MName.Caption:= '';
      edt_Value.Text:= '0';        lbl_TranCmp.Caption:= '';  lbl_TranCmp.Caption:= '';
      cbb_TruckNo.ItemIndex:= 0;

      lbl_ProName.Caption      := FieldByName('B_ProName').AsString;
      lbl_MName.Caption        := FieldByName('B_StockName').AsString;
      lbl_Company.Caption      := FieldByName('B_Company').AsString;
      lbl_TranCmp.Caption      := FieldByName('B_TransportCompany').AsString;

      FOrderItems[0].Fpurchasecontract_no := FieldByName('B_ID').AsString;
      FOrderItems[0].FProvID   := FieldByName('B_ProID').AsString;
      FOrderItems[0].FProvName := FieldByName('B_ProName').AsString;
      FOrderItems[0].FGoodsID  := FieldByName('B_StockNo').AsString;
      FOrderItems[0].FGoodsname:= FieldByName('B_StockName').AsString;
    end
    else ShowMsg('δ��ѯ����ض��������鶩�����', '��ʾ');
  end;

end;

procedure TFormPurCardHandl.btn1Click(Sender: TObject);
begin
  SearchPurOrdersInfo(Trim(edt1.Text));
end;

procedure TFormPurCardHandl.dbgrd1CellClick(Column: TColumn);
var nCId:string;
begin
  with Ds_Mx1.DataSet do
  begin
    if Active then
    if RecordCount>0 then
    begin
      lbl_ProName.Caption:= '';   lbl_MName.Caption:= '';
      edt_Value.Text:= '0';        lbl_TranCmp.Caption:= '';  lbl_TranCmp.Caption:= '';
      cbb_TruckNo.ItemIndex:= 0;


      lbl_ProName.Caption:= FieldByName('B_ProName').AsString;
      lbl_MName.Caption:= FieldByName('B_StockName').AsString;

      FOrderItems[0].Fpurchasecontract_no := FieldByName('B_ID').AsString;
      FOrderItems[0].FProvID   := FieldByName('B_ProID').AsString;
      FOrderItems[0].FProvName := FieldByName('B_ProName').AsString;
      FOrderItems[0].FGoodsID  := FieldByName('B_StockNo').AsString;
      FOrderItems[0].FGoodsname:= FieldByName('B_StockName').AsString;
    end;
  end;
  cbb_Company.ItemIndex:=-1;
end;

procedure TFormPurCardHandl.btnOKClick(Sender: TObject);
begin
  BtnOK.Enabled := False;
  try
    if (Trim(lbl_ProName.Caption)='')or(Trim(lbl_MName.Caption)='') then
    begin
      ShowMsg('�����б�ѡ��Ӧ��ͬ��Ϣ', sHint);
      Exit;
    end;

    if (lbl_Company.Caption='') or (lbl_TranCmp.Caption='') then
    begin
      ShowMsg('�ջ���˾�����˵�λȱʧ,����ϵ��������Ա', sHint);
      Exit;
    end;
//    if (cbb_Company.ItemIndex<0)or(cbb_Company.Text='') then
//    begin
//      ShowMsg('��ѡ���ջ���˾', sHint);
//      Exit;
//    end;
//    
//    if (cbb_TranCmp.ItemIndex<0)or(cbb_TranCmp.Text='') then
//    begin
//      ShowMsg('��ѡ�����乫˾', sHint);
//      Exit;
//    end;

    if (edt_Value.Text='') then
    begin
      ShowMsg('����д��������', sHint);
      Exit;
    end;
    if Length(cbb_TruckNo.Text)<4 then
    begin
      ShowMsg('����д���ƺ�', sHint);
      Exit;
    end;

    if not SaveBillProxy then Exit;
    nSuccCard:= '';
    Close;
  finally
    BtnOK.Enabled := True;
  end;
end;

function TFormPurCardHandl.SaveBillProxy: Boolean;
var
  nHint:string;
  nList: TStrings;
  nOrderItem:stMallPurchaseItem;
  nOrder:string;
  nNewCardNo:string;
  nidx:Integer;
  i:Integer;
  nRet:Boolean;
begin
  Result := False; nNewCardNo := ''; FBegin := Now;
  nOrderItem := FOrderItems[0];
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
    else WriteLog('��ȡ����Ƭ: ' + nNewCardNo);
  except on Ex:Exception do
    begin
      WriteLog('�����쳣 '+Ex.Message);
      ShowDlg('�����쳣, ����ϵ������Ա.', sWarn, Self.Handle);
    end;
  end;
  writelog('TfFormNewPurchaseCard.SaveBillProxy ����������-��ʱ��'+InttoStr(MilliSecondsBetween(Now, FBegin))+'ms');

  nList := TStringList.Create;
  try
    nList.Values['SQID'] := nOrderItem.Fpurchasecontract_no;
    nList.Values['Area'] := '';
    nList.Values['Truck'] := Trim(cbb_TruckNo.Text);
    nList.Values['Project'] := nOrderItem.Fpurchasecontract_no;
    nList.Values['CardType'] := 'L';
    {$IFDEF SendMorefactoryStock}           // ���������ݿ���������ӡ���� ����
    nList.Values['SendFactory'] := '����';
    {$ENDIF}
    
    nList.Values['ProviderID']  := nOrderItem.FProvID;
    nList.Values['ProviderName']:= nOrderItem.FProvName;
    nList.Values['StockNO']     := nOrderItem.FGoodsID;
    nList.Values['StockName']   := nOrderItem.FGoodsname;
    nList.Values['Value']       := edt_Value.Text;
    nList.Values['YJZValue']    := '0';     // ԭʼ����
    nList.Values['KFTime']      := FormatDateTime('yyyy-MM-dd HH:mm:ss', Now);       // ��ʱ��
    nList.Values['PurCompany']  := lbl_Company.Caption;         // �ջ���λ  ���
    nList.Values['TransportCompany'] := lbl_TranCmp.Caption;    // �ջ���λ  ���

    FBegin := Now;
    nOrder := SaveOrder(PackerEncodeStr(nList.Text));
    if nOrder='' then
    begin
      nHint := '����ɹ���ʧ��';
      ShowMsg(nHint,sError);
      Writelog(nHint);
      Exit;
    end;
    writelog('TfFormNewPurchaseCard.SaveBillProxy ����ɹ���-��ʱ��'+InttoStr(MilliSecondsBetween(Now, FBegin))+'ms');
  finally
    nList.Free;
  end;

  ShowMsg('�ɹ�������ɹ�', sHint);

  FBegin := Now;
  nRet := SaveOrderCard(nOrder,nNewCardNo);
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
    nHint := '�����쿨�ɹ�,����['+nNewCardNo+'],���պ����Ŀ�Ƭ';
    WriteLog(nHint);
    ShowMsg(nHint,sWarn);
  end
  else begin
    gDispenserManager.RecoveryCard(gSysParam.FTTCEK720ID, nHint);

    nHint := '�����쿨���� [%s] �����ɹ����� [%s] ʧ�ܣ��뵽��Ʊ�������¹�����';
    nHint := Format(nHint,[nNewCardNo, nOrder]);
    Writelog(nHint);
    ShowMsg(nHint,sHint);
  end;
  writelog('TfFormNewPurchaseCard.SaveBillProxy �����������������ſ���-��ʱ��'+InttoStr(MilliSecondsBetween(Now, FBegin))+'ms');
  if nRet then Close;
end;

procedure TFormPurCardHandl.edt_ValueKeyPress(Sender: TObject;
  var Key: Char);
begin
  if not (key in ['0'..'9','.',#8]) then
    key:=#0;
  if (key='.') and (Pos('.',edt_Value.Text)>0)   then
    key:=#0;
end;

procedure TFormPurCardHandl.cbb_TranCmpPropertiesChange(Sender: TObject);
var nStr:string;
begin
  nStr:= Trim(cbb_TranCmp.text);
  if nStr<>'' then LoadTransportCompany;
end;

end.
