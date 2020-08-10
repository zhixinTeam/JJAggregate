unit UFormBillCardHandl;

interface

{$I Link.Inc}
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, dxSkinsCore, dxSkinsDefaultPainters, cxTextEdit, UBusinessConst,
  cxMaskEdit, cxDropDownEdit, StdCtrls, Grids, DBGrids, DB, USysBusiness,
  ADODB, DBClient, Provider, Buttons, ExtCtrls;

type
  TFormBillCardHandl = class(TForm)
    edt1: TEdit;
    lbl1: TLabel;
    btn1: TButton;
    lbl2: TLabel;
    lbl3: TLabel;
    lbl4: TLabel;
    cbb_Stocks: TcxComboBox;
    lbl5: TLabel;
    edt_Value: TcxTextEdit;
    lbl6: TLabel;
    btnOK: TButton;
    btnBtnExit: TButton;
    lbl7: TLabel;
    Ds_Mx1: TDataSource;
    lbl8: TLabel;
    lbl9: TLabel;
    Qry_1: TADOQuery;
    lbl10: TLabel;
    cbb_TruckNo: TcxComboBox;
    TimerAutoClose: TTimer;
    lbl_ZhiKa: TLabel;
    lbl_Close: TLabel;
    procedure btnBtnExitClick(Sender: TObject);
    procedure btn1Click(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure cbb_StocksPropertiesEditValueChanged(Sender: TObject);
    procedure edt_ValueKeyPress(Sender: TObject; var Key: Char);
    procedure edt1KeyPress(Sender: TObject; var Key: Char);
    procedure FormShow(Sender: TObject);
    procedure TimerAutoCloseTimer(Sender: TObject);
    procedure cbb_TruckNoKeyPress(Sender: TObject; var Key: Char);
  private
    { Private declarations }
    nSuccCard, FCurrPriceDesc : string;
    Fbegin    : TDateTime;
    FIsLoading:Boolean;
    FAutoClose:Integer; //窗口自动关闭倒计时（分钟）
  private
    procedure SearchCusInfo(nName:string);
    procedure LoadCusZhiKa(nCusId:string);
    procedure LoadCusStocks(nZkId:string);
    procedure LoadTruckPre;
    function  VerifyCtrl(Sender: TObject; var nHint: string): Boolean;
    procedure Writelog(nMsg: string);
    function IsCanCreateBill(nTruck : string; var nStdMI:Double): Boolean;
    //出厂后N分钟后方可开单
    function  IsCustomerHaveTruckNo(nTruck, nCid: string): Boolean;
    //检查车牌、客户匹配关系

    function IsHasOPenLine(nMID: string): Boolean;
    function IsTruckNoValid(nTruck, nCid: string): Boolean;
    function CanUseCard(const nCardNo: string): Boolean;

    function  SaveBillProxy: Boolean;
    procedure CombinStockAndPrice(const nApplyPrice: Boolean);
    //合并价格
  public
    { Public declarations }
    FNewLid   : string;
  public
    procedure SetControlsClear;
  end;

type
  TBillInfo = record
    FCusID   : string;
    FCusName : string;
    FZhiKaId : string;
    FOnlyMoney: Boolean;
    FIDList  : string;
    FCard    : string;
    FTruck   : string;
    FValue   : Double;
    FPrice   : Double;
    FMoney   : Double;
    FPriceDesc:string;
  end;


  TStockItem = record
    FType: string;
    FStockNO: string;
    FStockName: string;
    FStockSeal: string;
    FPrice: Double;
    FPriceIndex: Integer;
    FValue: Double;
    FYfPrice: Double;
    FPriceDesc:string;
    FSelecte: Boolean;
  end;


var
  FormBillCardHandl: TFormBillCardHandl;
  gStockList: array of TStockItem;
  gBill : TBillInfo;
  gStockTypes: TStockTypeItems;

implementation

uses UDataModule, USysDB, UAdjustForm, ULibFun, USysConst, USysLoger,UBusinessPacker,
      UFormMain,UFormBase,UDataReport,NativeXml,UFormWait,DateUtils, UMgrTTCEDispenser;


{$R *.dfm}


function IsHaveChinese(nStr: string): boolean;
var nWStr:WideString;
    nX : string;
begin
  nWStr:= nStr;
  nX:= nWStr[1];
  Result:= ( Length(nX)>1 ) ;
end;

procedure TFormBillCardHandl.SetControlsClear;
var
  i : Integer;
  nComp : TComponent;
begin
  edt1.Clear;         gSysParam.FUserID := 'AICM';
  edt_Value.Text:= '';
  cbb_TruckNo.ItemIndex:= 0;
  FNewLid:= '';
  lbl2.Caption:=''; lbl3.Caption:=''; lbl10.Caption:='';
  lbl_ZhiKa.Caption:='';

  cbb_Stocks.Properties.Items.Clear;
end;

//Desc: 将价格合并到纸卡品种列表
procedure TFormBillCardHandl.CombinStockAndPrice(const nApplyPrice: Boolean);
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
      begin
        gStockList[nIdx].FPrice := gStockTypes[i].FPrice;
        gStockList[nIdx].FPriceDesc := gStockTypes[i].FParam;
      end;

      gStockList[nIdx].FPriceIndex := i;
      Break;
    end;
  end;
end;

procedure TFormBillCardHandl.SearchCusInfo(nName:string);
var nStr : string;
    nIdx : Integer;
begin
  SetLength(gStockList, 0);
  edt_Value.Text:= ''; lbl2.Caption:= '';  lbl3.Caption:= '';

  nStr := ' Select * From S_ZhiKa Left Join S_Customer On Z_Customer=C_ID  '+
          ' Where Z_Password='''+nName+''' ';
  //扩展信息

  with FDM.QuerySQLx(nStr) do
  begin
    if RecordCount>0 then
    begin
      edt_Value.Text:= '';  lbl10.Caption:= '';
      cbb_Stocks.Properties.Items.Clear;
      //**************************************************

      lbl2.Caption:= FieldByName('C_ID').AsString;
      lbl3.Caption:= FieldByName('C_Name').AsString;

      gBill.FCusID   := FieldByName('C_ID').AsString;
      gBill.FCusName := FieldByName('C_Name').AsString;
      gBill.FZhiKaId := FieldByName('Z_ID').AsString;

      lbl_ZhiKa.caption:= gBill.FZhiKaId;
      LoadCusStocks( gBill.FZhiKaId );

      BtnOK.Enabled := LoadStockItemsPrice(gBill.FCusID, gStockTypes);
    end
    else ShowMsg('未查询到相关订单、请检查提货码', '提示');
  end;
end;

procedure TFormBillCardHandl.btnBtnExitClick(Sender: TObject);
begin
  Close;
end;

procedure TFormBillCardHandl.btn1Click(Sender: TObject);
begin
  FAutoClose := gSysParam.FAutoClose_Second;
  SearchCusInfo(Trim(edt1.Text));
end;

procedure TFormBillCardHandl.LoadCusZhiKa(nCusId:string);
begin
end;

procedure TFormBillCardHandl.LoadCusStocks(nZkId:string);
var nStr : string;
    nIdx : Integer;
begin
  SetLength(gStockList, 0);
  cbb_Stocks.Properties.Items.Clear;
  nStr := 'Select * From %s Left Join Sys_Dict On D_ParamB=D_StockNo Where D_ZID=''%s'' And D_ParamB<>'''' '+
          'Order By D_Index ';
  nStr := Format(nStr, [sTable_ZhiKaDtl, nZkId]);

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
      FPrice := FieldByName('D_Price').AsFloat;
      FYfPrice := FieldByName('D_YunFei').AsFloat;

      FValue := 0;
      FSelecte := False;

      cbb_Stocks.Properties.Items.Add(gStockList[nIdx].FStockName);

      Inc(nIdx);
      Next;
    end;

    cbb_Stocks.ItemIndex:= 0;
    cbb_Stocks.DroppedDown:= True;
  end
end;

procedure TFormBillCardHandl.LoadTruckPre;
var nStr : string;
begin
  FIsLoading:= True;
  cbb_TruckNo.Properties.Items.Clear;
  nStr := 'Select * From %s Where D_Name=''TruckPreItem'' Order by D_Index ';
  nStr := Format(nStr, [sTable_SysDict]);

  with FDM.QueryTemp(nStr) do
  if RecordCount > 0 then
  begin
    First;
    
    while not Eof do
    begin
      cbb_TruckNo.Properties.Items.Add(FieldByName('D_Value').AsString);
      Next;
    end;

    cbb_Stocks.ItemIndex:= 0;
    cbb_Stocks.DroppedDown:= True;
  end;
  FIsLoading:= False;
end;

procedure TFormBillCardHandl.Writelog(nMsg: string);
begin
  gSysLoger.AddLog(nMsg);
end;

function TFormBillCardHandl.VerifyCtrl(Sender: TObject;
  var nHint: string): Boolean;
var nVal: Double;
begin
  Result := True;

  if Sender = cbb_TruckNo then
  begin
    Result := Length(cbb_TruckNo.Text) > 5;
    if not Result then
    begin
      nHint := '车牌号长度应大于2位';
      Writelog(nHint);
      Exit;
    end;

    Result:= IsHaveChinese(cbb_TruckNo.Text);
    if not Result then
    begin
      nHint := '需录入车牌前缀';
      Writelog(nHint);
      Exit;
    end;

  end;
  if Sender = edt_Value then
  begin
    Result := IsNumber(edt_Value.Text, True) and (StrToFloat(edt_Value.Text)>0);
    if not Result then
    begin
      nHint := '请填写有效的办理量';
      Writelog(nHint);
      Exit;
    end;
  end;
end;

function TFormBillCardHandl.IsCustomerHaveTruckNo(nTruck, nCid: string): Boolean;
var nStr : string;
begin
  Result:= False;
  //*************
  nStr := 'Select * From %s Where T_Truck=''%s'' And T_CID=''%s''';
  nStr := Format(nStr, [sTable_TruckCus, nTruck, nCid]);

  with FDM.QuerySQLChk(nStr) do
    Result:= (RecordCount>0)
end;

function TFormBillCardHandl.IsCanCreateBill(nTruck : string; var nStdMI:Double): Boolean;
var nStr : string;
begin
  Result:= True;
  //*************
  nStr := 'Select * From %s Where D_Name=''OutTimeDiffStd'' ';
  nStr := Format(nStr, [sTable_SysDict]);
  with FDM.QuerySQLChk(nStr) do
  if (RecordCount>0) then
  begin
    nStdMI:= (FieldByName('D_Value').AsFloat);
  end
  else nStdMI:= 10;

  nStr := 'Select DATEDIFF(MI, L_OutFact, GETDATE()) OutMi From %s Where L_Truck=''%s'' Order By L_OutFact Desc ';
  nStr := Format(nStr, [sTable_Bill, nTruck]);

  with FDM.QuerySQLChk(nStr) do
  if (RecordCount>0) then
  begin
    Result:= (FieldByName('OutMi').AsFloat > nStdMI);
  end;
end;

function TFormBillCardHandl.IsTruckNoValid(nTruck, nCid: string): Boolean;
var nStr : string;
begin
  Result:= False;
  //*************
  nStr := 'Select * From %s Where T_Truck=''%s'' And T_CID=''%s'' And T_InValidTime>GetDate()';
  nStr := Format(nStr, [sTable_TruckCus, nTruck, nCid]);

  with FDM.QuerySQLChk(nStr) do
    Result:= (RecordCount>0)
end;

function TFormBillCardHandl.IsHasOPenLine(nMID: string): Boolean;
var nStr : string;
begin
  Result:= False;
  //*************
  nStr := 'Select * From %s Where Z_StockNo=''%s'' And Z_Valid=''Y'' ';
  nStr := Format(nStr, [sTable_ZTLines, nMID]);

  with FDM.QuerySQLChk(nStr) do
    Result:= (RecordCount>0)
end;

function TFormBillCardHandl.CanUseCard(const nCardNo: string): Boolean;
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

  nStr := 'Select * From %s Where C_Card=''%s''';
  nStr := Format(nStr,[sTable_Card,nCardNo]);
  with FDM.QueryTemp(nStr) do
  begin
    Result:= RecordCount=1;
  end;
end;

procedure TFormBillCardHandl.btnOKClick(Sender: TObject);
VAR nIdx:Integer;
    nMi :Double;
begin
  FAutoClose := gSysParam.FAutoClose_Second;
  BtnOK.Enabled := False;
  try
    gBill.FValue:= StrToFloatDef(Trim(edt_Value.Text), 0);
    gBill.FTruck:= Trim(cbb_TruckNo.Text);

    {$IFDEF OutTimeCreateBillChk}
    nMi:= 10;
    if Not IsCanCreateBill(gBill.FTruck, nMi) then
    begin
      ShowMsg(Format('%s 暂不能开单、出厂后 %g 分钟内禁止开单',[gBill.FTruck, nMi]), sHint);
      Exit;
    end;
    {$ENDIF}

    if Not IsHasOPenLine(gStockList[cbb_Stocks.ItemIndex].FStockNO) then
    begin
      ShowMsg(Format('您所开单物料 %s %s, 当前尚未开启装车线、暂不能开单、请联系工作人员',
                                    [gStockList[cbb_Stocks.ItemIndex].FStockNO,
                                     gStockList[cbb_Stocks.ItemIndex].FStockName ]), sHint);
      Exit;
    end;
    if Not IsTruckNoValid(gBill.FTruck, gBill.FCusID) then
    begin
      ShowMsg(Format('%s 授权 %s 已过有效期、请联系工厂处理',[gBill.FCusName, gBill.FTruck]), sHint);
      Exit;
    end;
    if (gBill.FValue<=0)or(gBill.FTruck='')or(cbb_Stocks.ItemIndex<0) then
    begin
      ShowMsg('请录入开单数量、车牌号及水泥品种', sHint);
      Exit;
    end;
    if Not IsCustomerHaveTruckNo(gBill.FTruck, gBill.FCusID) then
    begin
      ShowMsg('请录入正确的车牌号码', sHint);
      Exit;
    end;

    ///************************************
    if not LoadStockItemsPrice(gBill.FCusID, gStockTypes) then Exit;
    //重新载入价格
    CombinStockAndPrice(True);

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
    ///******************

    if not SaveBillProxy then Exit;
    nSuccCard:= '' ;
    Close;
  finally
    BtnOK.Enabled := True;            //PrintBillRt('TH181021311', False);
  end;
end;

function TFormBillCardHandl.SaveBillProxy: Boolean;
var
  nHint:string;
  nList,nTmp,nStocks: TStrings;
  nPrint,nInFact:Boolean;
  nBillData, nFact, nBillID:string;
  nNewCardNo, nLid:string;
  i, nidx:Integer;
  nRet: Boolean;
var nInt: Int64;
begin
  Result := False;  nLid:= '';
                                    
  if (not VerifyCtrl(cbb_TruckNo, nHint)) or
      (not VerifyCtrl(edt_Value, nHint)) then
  begin
    ShowMsg(nHint, sHint);
    Writelog(nHint);
    Exit;
  end;

  with gStockList[cbb_Stocks.ItemIndex] do
  begin
    if FPrice<=0 then
    begin
      ShowMsg('获取物料价格异常！请联系工作人员',sHint);
      Writelog('获取物料价格异常！请联系工作人员');
      Exit;
    end;

    if FPrice > 0 then
    begin
      nInt := Float2PInt(gBill.FMoney / FPrice, cPrecision, False);
      if (nInt/cPrecision)<gBill.FValue then
      begin
        ShowMsg('当前资金最大开单量为：'+FloatToStr(nInt/cPrecision)+' 吨、请调整数量',sHint);
        Exit;
      end;
    end;

    gBill.FPrice:= FPrice;
    gBill.FPriceDesc:= FPriceDesc;
  end;

  nNewCardNo := '';
  Fbegin := Now;

  try
    //连续三次读卡均失败，则回收卡片，重新发卡
    for i := 0 to 3 do
    begin
      for nidx := 0 to 3 do
      begin
        nNewCardNo := gDispenserManager.GetCardNo(gSysParam.FTTCEK720ID, nHint, False);
        if nNewCardNo <> '' then
          Break;
        Sleep(500);
      end;
        //连续三次读卡,成功则退出。
      if nNewCardNo <> '' then
        if IsCardValid(nNewCardNo) then
          Break;
    end;

    if nNewCardNo = '' then
    begin
        ShowDlg('卡箱异常,请查看是否有卡.', sWarn, Self.Handle);
        Exit;
    end
    else WriteLog(nNewCardNo);
  except on Ex:Exception do
    begin
      WriteLog('卡箱异常 ' + Ex.Message);
      ShowDlg('卡箱异常, 请联系管理人员.', sWarn, Self.Handle);
    end;
  end;

  if not CanUseCard(nNewCardNo) then
  begin
    gDispenserManager.RecoveryCard(gSysParam.FTTCEK720ID, nHint);
    ShowDlg('发卡失败、请新扫描开卡.', sWarn, Self.Handle);
    Exit;
  end;
  WriteLog('TfFormNewCard.SaveBillProxy 发卡机读卡-耗时：'+InttoStr(MilliSecondsBetween(Now, FBegin))+'ms');


  if FNewLid='' then
  begin
    //保存提货单
    nStocks := TStringList.Create;
    nList := TStringList.Create;
    nTmp := TStringList.Create;
    try
      LoadSysDictItem(sFlag_PrintBill, nStocks);

      nTmp.Values['Type'] := gStockList[cbb_Stocks.ItemIndex].FType;

      nTmp.Values['StockNO'] := gStockList[cbb_Stocks.ItemIndex].FStockNO;
      nTmp.Values['StockName'] := gStockList[cbb_Stocks.ItemIndex].FStockName;
      nTmp.Values['Price'] := FloatToStr(gBill.FPrice);
      nTmp.Values['L_YFPrice'] := FloatToStr(gStockList[cbb_Stocks.ItemIndex].FYfPrice);
      nTmp.Values['Value'] := FloatToStr(gBill.FValue);
      
      nTmp.Values['PriceDesc'] := gBill.FPriceDesc;
      //价格描述

      nTmp.Values['PrintHY'] := sFlag_No;
      //****************
      nList.Add(PackerEncodeStr(nTmp.Text));

      with nList do
      begin
        Values['Bills'] := PackerEncodeStr(nList.Text);
        Values['ZhiKa'] := gBill.FZhiKaId;
        Values['Truck'] := UpperCase(gBill.FTruck);
        Values['Lading'] := sFlag_TiHuo;
        Values['Memo']  := EmptyStr;
        Values['IsVIP'] := 'C';
        Values['Seal']  := '';
        Values['HYDan'] := '';
      end;
      Writelog('单据内容：'+nList.Text);
      nBillData := PackerEncodeStr(nList.Text);
      FBegin := Now;
      nBillID := SaveBill(nBillData);
      if nBillID = '' then Exit;
      Writelog('TfFormNewCard.SaveBillProxy 生成提货单['+nBillID+']-耗时：'+InttoStr(MilliSecondsBetween(Now, FBegin))+'ms');
      FBegin := Now;
      Writelog('TfFormNewCard.SaveBillProxy 保存商城订单号-耗时：'+InttoStr(MilliSecondsBetween(Now, FBegin))+'ms');
    finally
      nStocks.Free;
      nList.Free;
      nTmp.Free;
    end;

    ShowMsg('提货单保存成功', sHint);
  end
  else nBillID:= FNewLid;

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
    nHint := '自助申请发卡成功,卡号['+nNewCardNo+'],请收好您的卡片';
    WriteLog(nHint);
    ShowMsg(nHint,sWarn);
  end
  else begin
    gDispenserManager.RecoveryCard(gSysParam.FTTCEK720ID, nHint);

    nHint := '自助申请卡号['+nNewCardNo+']关联订单失败，请到开票窗口重新关联。';
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
  {$IFDEF SWTC}
  PrintBillRt(nBillID, False);
  // 声威开单小票
  {$ENDIF}

  if nRet then Close;
end;

procedure TFormBillCardHandl.cbb_StocksPropertiesEditValueChanged(
  Sender: TObject);
var nInt: Int64;
    nIdx: Integer;
begin
  FAutoClose := gSysParam.FAutoClose_Second;
  if FIsLoading then Exit;
  IF gBill.FZhiKaId<>'' then
  begin
    if cbb_Stocks.ItemIndex<0 then Exit;
    gBill.FMoney := GetZhikaValidMoney(gBill.FZhiKaId, gBill.FOnlyMoney);

    ///************************************
    if not LoadStockItemsPrice(gBill.FCusID, gStockTypes) then Exit;
    //重新载入价格
    CombinStockAndPrice(True);

    for nIdx:=Low(gStockList) to High(gStockList) do
    with gStockList[nIdx] do
    begin
      if not FSelecte then Continue;
      FCurrPriceDesc:= gStockTypes[FPriceIndex].FParam;
      if (FPriceIndex < 0) or (FPrice <> gStockTypes[FPriceIndex].FPrice) then
      begin
        ShowDlg('当前价格已失效(刚调价),请重新执行开单操作', sHint);
        Exit;
      end;
    end;
    ///******************

    with gStockList[cbb_Stocks.ItemIndex] do
    begin
      if FPrice > 0 then
      begin
        FSelecte := True;
        
        nInt := Float2PInt(gBill.FMoney / FPrice, cPrecision, False);
        lbl10.Caption := '最大：'+FloatToStr(nInt / cPrecision) + ' 吨';
      end;
    end;
  end
  else ShowMsg('请选择有效纸卡', sHint);
end;

procedure TFormBillCardHandl.edt_ValueKeyPress(Sender: TObject;
  var Key: Char);
begin
  FAutoClose := gSysParam.FAutoClose_Second;
  if not (key in ['0'..'9','.',#8]) then
    key:=#0;
  if (key='.') and (Pos('.',edt_Value.Text)>0)   then
    key:=#0;
end;

procedure TFormBillCardHandl.edt1KeyPress(Sender: TObject; var Key: Char);
begin
  FAutoClose := gSysParam.FAutoClose_Second;
  if Key = #13 then
  begin
    btn1.Click;
  end;
end;

procedure TFormBillCardHandl.FormShow(Sender: TObject);
begin
  FAutoClose := gSysParam.FAutoClose_Second;
  TimerAutoClose.Interval := 1*1000;
  TimerAutoClose.Enabled := True;
  LoadTruckPre;
end;

procedure TFormBillCardHandl.TimerAutoCloseTimer(Sender: TObject);
begin
  if FAutoClose=0 then
  begin
    TimerAutoClose.Enabled := False;
    Close;
  end;
  Dec(FAutoClose);
  lbl_Close.Caption := IntToStr(FAutoClose);
end;

procedure TFormBillCardHandl.cbb_TruckNoKeyPress(Sender: TObject;
  var Key: Char);
begin
  FAutoClose := gSysParam.FAutoClose_Second;
end;

end.
