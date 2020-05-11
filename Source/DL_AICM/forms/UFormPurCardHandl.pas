unit UFormPurCardHandl;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, dxSkinsCore, dxSkinsDefaultPainters, cxTextEdit,
  cxMaskEdit, cxDropDownEdit, Provider, DBClient, DB, ADODB, Grids, USysConst,
  DBGrids, StdCtrls, ExtCtrls;

const
  sHint = '提示';

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
    FOrderItems : array of stMallPurchaseItem; //订单数组
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
  nStr := '自助办卡 contractcode[%s]provname[%s]productname[%s]:';
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
//  //扩展信息
//
//  Qry_1.DataSource.DataSet:= FDM.QuerySQLx(nStr);

  nStr := ' Select * From P_OrderBase Where ((B_Value-B_SentValue>0) or (B_Value=0)) And B_BStatus=''Y'' '+
                'And B_ID=''OB'+trim(edt1.Text)+'''';

  with FDM.QueryTemp(nStr) do
  begin

    if not Active then
    begin
      ShowMsg('未查询到相关订单、请检查订单编号', '提示');
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
    else ShowMsg('未查询到相关订单、请检查订单编号', '提示');
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
      ShowMsg('请在列表选择供应合同信息', sHint);
      Exit;
    end;

    if (lbl_Company.Caption='') or (lbl_TranCmp.Caption='') then
    begin
      ShowMsg('收货公司、承运单位缺失,请联系工厂管理员', sHint);
      Exit;
    end;
//    if (cbb_Company.ItemIndex<0)or(cbb_Company.Text='') then
//    begin
//      ShowMsg('请选择收货公司', sHint);
//      Exit;
//    end;
//    
//    if (cbb_TranCmp.ItemIndex<0)or(cbb_TranCmp.Text='') then
//    begin
//      ShowMsg('请选择运输公司', sHint);
//      Exit;
//    end;

    if (edt_Value.Text='') then
    begin
      ShowMsg('请填写开单吨数', sHint);
      Exit;
    end;
    if Length(cbb_TruckNo.Text)<4 then
    begin
      ShowMsg('请填写车牌号', sHint);
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
    else WriteLog('读取到卡片: ' + nNewCardNo);
  except on Ex:Exception do
    begin
      WriteLog('卡箱异常 '+Ex.Message);
      ShowDlg('卡箱异常, 请联系管理人员.', sWarn, Self.Handle);
    end;
  end;
  writelog('TfFormNewPurchaseCard.SaveBillProxy 发卡机读卡-耗时：'+InttoStr(MilliSecondsBetween(Now, FBegin))+'ms');

  nList := TStringList.Create;
  try
    nList.Values['SQID'] := nOrderItem.Fpurchasecontract_no;
    nList.Values['Area'] := '';
    nList.Values['Truck'] := Trim(cbb_TruckNo.Text);
    nList.Values['Project'] := nOrderItem.Fpurchasecontract_no;
    nList.Values['CardType'] := 'L';
    {$IFDEF SendMorefactoryStock}           // 开单将根据开单工厂打印单据 声威
    nList.Values['SendFactory'] := '榆林';
    {$ENDIF}
    
    nList.Values['ProviderID']  := nOrderItem.FProvID;
    nList.Values['ProviderName']:= nOrderItem.FProvName;
    nList.Values['StockNO']     := nOrderItem.FGoodsID;
    nList.Values['StockName']   := nOrderItem.FGoodsname;
    nList.Values['Value']       := edt_Value.Text;
    nList.Values['YJZValue']    := '0';     // 原始净重
    nList.Values['KFTime']      := FormatDateTime('yyyy-MM-dd HH:mm:ss', Now);       // 矿发时间
    nList.Values['PurCompany']  := lbl_Company.Caption;         // 收货单位  金九
    nList.Values['TransportCompany'] := lbl_TranCmp.Caption;    // 收货单位  金九

    FBegin := Now;
    nOrder := SaveOrder(PackerEncodeStr(nList.Text));
    if nOrder='' then
    begin
      nHint := '保存采购单失败';
      ShowMsg(nHint,sError);
      Writelog(nHint);
      Exit;
    end;
    writelog('TfFormNewPurchaseCard.SaveBillProxy 保存采购单-耗时：'+InttoStr(MilliSecondsBetween(Now, FBegin))+'ms');
  finally
    nList.Free;
  end;

  ShowMsg('采购单保存成功', sHint);

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
    //发卡
  end;

  if nRet then
  begin
    nHint := '自助办卡成功,卡号['+nNewCardNo+'],请收好您的卡片';
    WriteLog(nHint);
    ShowMsg(nHint,sWarn);
  end
  else begin
    gDispenserManager.RecoveryCard(gSysParam.FTTCEK720ID, nHint);

    nHint := '自助办卡卡号 [%s] 关联采购订单 [%s] 失败，请到开票窗口重新关联。';
    nHint := Format(nHint,[nNewCardNo, nOrder]);
    Writelog(nHint);
    ShowMsg(nHint,sHint);
  end;
  writelog('TfFormNewPurchaseCard.SaveBillProxy 发卡机出卡并关联磁卡号-耗时：'+InttoStr(MilliSecondsBetween(Now, FBegin))+'ms');
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
