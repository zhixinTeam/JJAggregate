{*******************************************************************************
  作者: dmzn@163.com 2012-5-3
  描述: 用户自助查询
*******************************************************************************}
unit UFormMain;

interface

{$I Link.Inc}
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxLabel, ExtCtrls, CPort, StdCtrls, Buttons,Uszttce_api,
  UHotKeyManager,uReadCardThread, dxSkinsCore, dxSkinsDefaultPainters, jpeg;

type 
  TCardType = (ctTTCE,ctRFID);
  
  TfFormMain = class(TForm)
    ComPort1: TComPort;
    TimerReadCard: TTimer;
    img1: TImage;
    LabelTruck: TcxLabel;
    LabelOrder: TcxLabel;
    LabelTon: TcxLabel;
    LabelStock: TcxLabel;
    LabelNum: TcxLabel;
    imgCard: TImage;
    LabelHint: TcxLabel;
    LabelDec: TcxLabel;
    LabelBill: TcxLabel;
    imgPrint: TImage;
    imgPurchaseCard: TImage;
    cxlbl_Tips: TcxLabel;
    tmr1: TTimer;
    LabelCusName: TcxLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ComPort1RxChar(Sender: TObject; Count: Integer);
    procedure TimerReadCardTimer(Sender: TObject);
    procedure LabelTruckDblClick(Sender: TObject);
    procedure TimerInsertCardTimer(Sender: TObject);
    procedure imgPrintClick(Sender: TObject);
    procedure imgCardClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure LabelHintClick(Sender: TObject);
    procedure LabelDecClick(Sender: TObject);
    procedure tmr1Timer(Sender: TObject);
  private
    { Private declarations }
    FBuffer: string;
    //接收缓冲
    FLastCard: string;
    FLastQuery: Int64;
    //上次查询
    FTimeCounter: Integer;
    //计时

    FHotKeyMgr: THotKeyManager;
    FHotKey: Cardinal;

    FHYDan,FStockName:string;
    FHyDanPrinterName,FDefaultPrinterName:string;
    FReadCardThread:TReadCardThread;
    Fbegin:TDateTime;
  private
    procedure LoadConfig;
    procedure ActionComPort(const nStop: Boolean);
    //串口处理
    procedure DoHotKeyHotKeyPressed(HotKey: Cardinal; Index: Word);
    {*热键处理*}
  public
    { Public declarations }
    FCursorShow:Boolean;
    FCardType:TCardType;
    procedure QueryCard(const nCard: string);
    //查询卡信息
    procedure QueryPorderinfo(const nCard: string);
  end;

var
  fFormMain: TfFormMain;

implementation

{$R *.dfm}

uses
  IniFiles, ULibFun, CPortTypes, USysLoger, USysDB, USmallFunc, UDataModule,
  UFormConn, uZXNewCard,USysConst,UClientWorker,UMITPacker,USysModule,USysBusiness,
  UDataReport,UFormInputbox,UFormBarcodePrint,uZXNewPurchaseCard,  NativeXml,
  UFormBase,DateUtils, UFormChoseOPType, UFormBillCardHandl;

type
  TReaderType = (ptT800, pt8142);
  //表头类型

  TReaderItem = record
    FType: TReaderType;
    FPort: string;
    FBaud: string;
    FDataBit: Integer;
    FStopBit: Integer;
    FCheckMode: Integer;
  end;

var
  gPath: string;
  gReaderItem: TReaderItem;
  //全局使用

resourcestring
  sHint       = '提示';
  sConfig     = 'Config.Ini';
  sForm       = 'FormInfo.Ini';
  sDB         = 'DBConn.Ini';

//------------------------------------------------------------------------------
//Desc: 记录日志
procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(TfFormMain, '自助主窗体', nEvent);
end;

//Desc: 测试nConnStr是否有效
function ConnCallBack(const nConnStr: string): Boolean;
begin
  FDM.ADOConn.Close;
  FDM.ADOConn.ConnectionString := nConnStr;
  FDM.ADOConn.Open;
  Result := FDM.ADOConn.Connected;
end;

procedure TfFormMain.LoadConfig;
var nIni: TIniFile;
begin
  nIni := TIniFile.Create(gPath + sConfig);
  with gSysParam do
  try
    FAutoClose_Second := nIni.ReadInteger('ZXSOFT', 'CloseForm', 30);

  finally
    nIni.Free;
  end;
end;

procedure TfFormMain.FormCreate(Sender: TObject);
var
  nStr:string;
begin
  gPath := ExtractFilePath(Application.ExeName);
  InitGlobalVariant(gPath, gPath+sConfig, gPath+sForm, gPath+sDB);

  img1.Picture.LoadFromFile(gPath+'\Images\BackGround.jpg');
  gSysLoger := TSysLoger.Create(gPath + 'Logs\');
  gSysLoger.LogSync := False;
  ShowConnectDBSetupForm(ConnCallBack);
//  ShowCursor(False);

  FDM.ADOConn.Close;
  FDM.ADOConn.ConnectionString := BuildConnectDBStr;
  //数据库连接

  RunSystemObject;
  FLastQuery := 0;
  FLastCard := '';
  FTimeCounter := 0;
  try
    ActionComPort(False);
    //启动读头
  except
  end;

  FHotKeyMgr := THotKeyManager.Create(Self);
  FHotKeyMgr.OnHotKeyPressed := DoHotKeyHotKeyPressed;

  FHotKey := TextToHotKey('Ctrl + Alt + D', False);
  FHotKeyMgr.AddHotKey(FHotKey);

  if not Assigned(FDR) then
  begin
    FDR := TFDR.Create(Application);
  end;

  {$IFDEF AICMOnleSale}
  imgPurchaseCard.Visible:= False;
  {$ENDIF}
  //imgPrint.Visible:= False;
  LoadConfig;
end;

procedure TfFormMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  try
    ActionComPort(True);
  except
  end;
  FHotKeyMgr.Free;
end;

procedure TfFormMain.LabelTruckDblClick(Sender: TObject);
begin

end;

//Desc: 串口操作
procedure TfFormMain.ActionComPort(const nStop: Boolean);
var nInt: Integer;
    nIni: TIniFile;
begin
  {$IFNDEF HardMon} Exit;{$ENDIF}
  if nStop then
  begin
    ComPort1.Close;
    Exit;
  end;

  with ComPort1 do
  begin
    with Timeouts do
    begin
      ReadTotalConstant := 100;
      ReadTotalMultiplier := 10;
    end;

    nIni := TIniFile.Create(gPath + 'Reader.Ini');
    with gReaderItem do
    try
      nInt := nIni.ReadInteger('Param', 'Type', 1);
      FType := TReaderType(nInt - 1);

      FPort := nIni.ReadString('Param', 'Port', '');
      FBaud := nIni.ReadString('Param', 'Rate', '4800');
      FDataBit := nIni.ReadInteger('Param', 'DataBit', 8);
      FStopBit := nIni.ReadInteger('Param', 'StopBit', 0);
      FCheckMode := nIni.ReadInteger('Param', 'CheckMode', 0);

      Port := FPort;
      BaudRate := StrToBaudRate(FBaud);

      case FDataBit of
       5: DataBits := dbFive;
       6: DataBits := dbSix;
       7: DataBits :=  dbSeven else DataBits := dbEight;
      end;

      case FStopBit of
       2: StopBits := sbTwoStopBits;
       15: StopBits := sbOne5StopBits
       else StopBits := sbOneStopBit;
      end;
    finally
      nIni.Free;
    end;

    ComPort1.Open;
  end;
end;

procedure TfFormMain.TimerReadCardTimer(Sender: TObject);
begin
  if FTimeCounter <= 0 then
  begin
    TimerReadCard.Enabled := False;
    FHYDan := '';
    FStockName := '';
    LabelDec.Caption := '';
    cxlbl_Tips.Caption := '';
//    imgPrint.Visible := False;

    LabelBill.Caption := '交货单号:';
    LabelTruck.Caption := '车牌号码:';
    LabelOrder.Caption := '销售订单:';
    LabelStock.Caption := '品种名称:';
    LabelNum.Caption := '开放道数:';
    LabelTon.Caption := '提货数量:';
    LabelCusName.Caption := '客户名称:';
    LabelHint.Caption := '请您刷卡';
  end else
  begin
    LabelDec.Caption := IntToStr(FTimeCounter) + ' ';
  end;

  Dec(FTimeCounter);
end;

procedure TfFormMain.ComPort1RxChar(Sender: TObject; Count: Integer);
var nStr: string;
    nIdx,nLen: Integer;
    nCardno:string;
    nSql:string;
begin
  ComPort1.ReadStr(nStr, Count);
  FBuffer := FBuffer + nStr;

  nLen := Length(FBuffer);
  if nLen < 7 then Exit;

  for nIdx:=1 to nLen do
  begin
    if (FBuffer[nIdx] <> #$AA) or (nLen - nIdx < 6) then Continue;
    if (FBuffer[nIdx+1] <> #$FF) or (FBuffer[nIdx+2] <> #$00) then Continue;

    nStr := Copy(FBuffer, nIdx+3, 4);
    FBuffer := '';
    WriteLog('ComPort1RxChar:'+ParseCardNO(nStr, True));
    FCardType := ctRFID;
    nCardno := ParseCardNO(nStr, True);
    nSql := 'select * from %s where c_card=''%s''';
    nSql := Format(nSql,[sTable_Card,nCardno]);
    with FDM.QuerySQL(nSql) do
    begin
      if RecordCount<=0 then
      begin
        cxlbl_Tips.Caption := '磁卡号无效';
        tmr1.Enabled:= True;
        Exit;
      end;
      if FieldByName('c_used').AsString=sflag_sale then
      begin
        QueryCard(nCardno);
        Exit;
      end
      else if FieldByName('c_used').AsString=sFlag_Provide then begin
        QueryPorderinfo(nCardno);
        Exit;
      end
      else begin
        cxlbl_Tips.Caption := '磁卡号无效';
        tmr1.Enabled:= True;
        Exit;
      end;
    end;
  end;
end;

//Date: 2012-5-3
//Parm: 卡号
//Desc: 查询nCard信息
procedure TfFormMain.QueryCard(const nCard: string);
var nVal: Double;
    nStr,nStock,nBill,nVip,nLine,nPoundQueue,nTruck: string;
    nDate: TDateTime;
    nBeginTotal:TDateTime;
begin
//  mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0);
//  mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, 0);
  //close screen saver

  if (nCard = FLastCard) and (GetTickCount - FLastQuery < 8 * 1000) then
  begin
    cxlbl_Tips.Caption := '请不要频繁读卡';
    tmr1.Enabled:= True;
    Exit;
  end;

  nBeginTotal := Now;
  try
    FTimeCounter := 10;
    TimerReadCard.Enabled := True;

    nStr := 'Select * From %s Where L_Card=''%s''';
    nStr := Format(nStr, [sTable_Bill, nCard]);
    FBegin := Now;
    with FDM.QuerySQL(nStr) do
    begin
      if RecordCount < 1 then
      begin
        FTimeCounter := 1;
        cxlbl_Tips.Caption := '磁卡号无效';
        tmr1.Enabled:= True;
        Exit;
      end;

      nVal := 0;
      First;

      while not Eof do
      begin
        if FieldByName('L_Value').AsFloat > nVal then
        begin
          nBill := FieldByName('L_ID').AsString;
          nVal := FieldByName('L_Value').AsFloat;
        end;

        Next;
      end;

      First;
      while not Eof do
      begin
        if FieldByName('L_ID').AsString = nBill then
          Break;
        Next;
      end;

      nBill  := FieldByName('L_ID').AsString;
      nVip   := FieldByName('L_IsVip').AsString;
      nTruck := FieldByName('L_Truck').AsString;
      nStock := FieldByName('L_StockNo').AsString;
      FHYDan := FieldByName('L_HYDan').AsString;
      FStockName := FieldByName('L_StockName').AsString;

      LabelBill.Caption    := '交货单号: ' + FieldByName('L_ID').AsString;
      LabelOrder.Caption   := '销售订单: ' + FieldByName('L_ZhiKa').AsString;
      LabelTruck.Caption   := '车牌号码: ' + FieldByName('L_Truck').AsString;
      LabelStock.Caption   := '品种名称: ' + FieldByName('L_StockName').AsString;
      LabelCusName.Caption := '客户名称: '+ FieldByName('L_CusName').AsString;
      LabelTon.Caption     := '提货数量: ' + FieldByName('L_Value').AsString + '吨';
    end;
    WriteLog('TfFormMain.QueryCard(nCard='''+nCard+''')查询提货单[nStr]-耗时：'+InttoStr(MilliSecondsBetween(Now, nBeginTotal))+'ms');
    //--------------------------------------------------------------------------
    nStr := 'Select Count(*) From %s ' +
            'Where Z_StockNo=''%s'' And Z_Valid=''%s'' And Z_VipLine=''%s''';
    nStr := Format(nStr, [sTable_ZTLines, nStock, sFlag_Yes,nVip]);
    FBegin := Now;
    with FDM.QuerySQL(nStr) do
    begin
      LabelNum.Caption := '开放道数: ' + Fields[0].AsString + '个';
    end;
    WriteLog('TfFormMain.QueryCard(nCard='''+nCard+''')查询开放道数[+nStr+]-耗时：'+InttoStr(MilliSecondsBetween(Now, FBegin))+'ms');
    //--------------------------------------------------------------------------
    nStr := 'Select T_line,T_InTime,T_Valid From %s ZT ' +
             'Where T_HKBills like ''%%%s%%'' ';
    nStr := Format(nStr, [sTable_ZTTrucks, nBill]);
    FBegin := Now;
    with FDM.QuerySQL(nStr) do
    begin
      if RecordCount < 1 then
      begin
        LabelHint.Caption := '您的车辆已无效.';
        Exit;
      end;

      if FieldByName('T_Valid').AsString <> sFlag_Yes then
      begin
        LabelHint.Caption := '您已超时出队,请到服务大厅办理入队手续.';
        Exit;
      end;

      nDate := FieldByName('T_InTime').AsDateTime;
      //进队时间

      nLine := FieldByName('T_Line').AsString;
      //通道号
    end;
    WriteLog('TfFormMain.QueryCard(nCard='''+nCard+''')查询车辆状态['+nStr+']-耗时：'+InttoStr(MilliSecondsBetween(Now, FBegin))+'ms');
    if nLine <> '' then
    begin
      nStr := 'Select Z_Valid,Z_Name From %s Where Z_ID=''%s'' ';
      nStr := Format(nStr, [sTable_ZTLines, nLine]);

      with FDM.QuerySQL(nStr) do
      begin
        if FieldByName('Z_Valid').AsString = 'N' then
        begin
        LabelHint.Caption := '您所在的通道已关闭，请联系调度人员.';
        Exit;
        end else
        begin
        LabelHint.Caption := '系统内您的车辆已入厂,请到' + FieldByName('Z_Name').AsString + '提货.';
        Exit;
        end;
      end;
    end;

    nStr := 'Select D_Value From $DT Where D_Memo = ''$PQ''';
    nStr := MacroValue(nStr, [MI('$DT', sTable_SysDict),
            MI('$PQ', sFlag_PoundQueue)]);

    with FDM.QuerySQL(nStr) do
    begin
      if FieldByName('D_Value').AsString = 'Y' then
      nPoundQueue := 'Y';
    end;

    nStr := 'Select D_Value From $DT Where D_Memo = ''$DQ''';
    nStr := MacroValue(nStr, [MI('$DT', sTable_SysDict),
            MI('$DQ', sFlag_DelayQueue)]);

    with FDM.QuerySQL(nStr) do
    begin
    if  FieldByName('D_Value').AsString = 'Y' then
      begin
        if nPoundQueue <> 'Y' then
        begin
          nStr := 'Select Count(*) From $TB Where T_InQueue Is Null And ' +
                  'T_Valid=''$Yes'' And T_StockNo=''$SN'' And T_InFact<''$IT'' And T_Vip=''$VIP''';
        end else
        begin
          nStr := ' Select Count(*) From $TB left join S_PoundLog on S_PoundLog.P_Bill=S_ZTTrucks.T_Bill ' +
                  ' Where T_InQueue Is Null And ' +
                  ' T_Valid=''$Yes'' And T_StockNo=''$SN'' And P_PDate<''$IT'' And T_Vip=''$VIP''';
        end;
      end else
      begin
        nStr := 'Select Count(*) From $TB Where T_InQueue Is Null And ' +
                'T_Valid=''$Yes'' And T_StockNo=''$SN'' And T_InTime<''$IT'' And T_Vip=''$VIP''';
      end;

      nStr := MacroValue(nStr, [MI('$TB', sTable_ZTTrucks),
            MI('$Yes', sFlag_Yes), MI('$SN', nStock),
            MI('$IT', DateTime2Str(nDate)),MI('$VIP', nVip)]);
    end;
    //xxxxx
    FBegin := Now;
    with FDM.QuerySQL(nStr) do
    begin
      if Fields[0].AsInteger < 1 then
      begin
        nStr := '您已排到队首,请关注大屏调度准备进厂.';
        LabelHint.Caption := nStr;
      end else
      begin
        nStr := '您前面还有【 %d 】辆车等待进厂';
        LabelHint.Caption := Format(nStr, [Fields[0].AsInteger]);
      end;
    end;
    WriteLog('TfFormMain.QueryCard(nCard='''+nCard+''')查询车辆队列-耗时：'+InttoStr(MilliSecondsBetween(Now, FBegin))+'ms');
    FLastQuery := GetTickCount;
    FLastCard := nCard;
    //已成功卡号
  except
    on E: Exception do
    begin
      ShowMsg('查询失败', sHint);
      WriteLog(E.Message);
    end;
  end;
  WriteLog('TfFormMain.QueryCard(nCard='''+nCard+''')查询磁卡信息-耗时：'+InttoStr(MilliSecondsBetween(Now, FBegin))+'ms');
  FDM.ADOConn.Connected := False;
end;

procedure TfFormMain.TimerInsertCardTimer(Sender: TObject);
begin
  FReadCardThread := TReadCardThread.Create(True);
  FReadCardThread.FreeOnTerminate := True;
  FReadCardThread.Resume;
  WaitForSingleObject(FReadCardThread.Handle,INFINITE);
end;

procedure TfFormMain.DoHotKeyHotKeyPressed(HotKey: Cardinal; Index: Word);
begin
  if (HotKey = FHotKey) then
  begin
    ShowCursor(True);
    FCursorShow := True;
  end;
end;

//Desc: 获取nStock品种的报表文件
function GetReportFileByStock(const nStock: string): string;
begin
  Result := GetPinYinOfStr(nStock);

  if Pos('dj', Result) > 0 then
    Result := gPath + sReportDir + 'HuaYan42_DJ.fr3'
  else if Pos('gsysl', Result) > 0 then
    Result := gPath + sReportDir + 'HuaYan_gsl.fr3'
  else if Pos('kzf', Result) > 0 then
    Result := gPath + sReportDir + 'HuaYan_kzf.fr3'
  else if Pos('qz', Result) > 0 then
    Result := gPath + sReportDir + 'HuaYan_qz.fr3'
  else if Pos('32', Result) > 0 then
    Result := gPath + sReportDir + 'HuaYan32.fr3'
  else if Pos('42', Result) > 0 then
    Result := gPath + sReportDir + 'HuaYan42.fr3'
  else if Pos('52', Result) > 0 then
    Result := gPath + sReportDir + 'HuaYan42.fr3'

  else if Pos('dlsn', Result) > 0 then
    Result := gPath + sReportDir + 'HuaYan_DaoLu.fr3'
  else if Pos('zrsn', Result) > 0 then
    Result := gPath + sReportDir + 'HuaYan_ZhongRe.fr3'
  else Result := '';
end;

//Desc: 打印标识为nHID的化验单
function PrintHuaYanReport(const nHID: string; const nAsk: Boolean): Boolean;
var nStr,nSR: string;
begin
  if nAsk then
  begin
    Result := True;
    nStr := '是否要打印化验单?';
    if not QueryDlg(nStr, sAsk) then Exit;
  end else Result := False;

  nSR := 'Select * From %s sr ' +
         ' Left Join %s sp on sp.P_ID=sr.R_PID';
  nSR := Format(nSR, [sTable_StockRecord, sTable_StockParam]);

  nStr := 'Select hy.*,sr.*,C_Name,(case when H_PrintNum>0 THEN ''补'' ELSE '''' END) AS IsBuDan From $HY hy ' +
          ' Left Join $Cus cus on cus.C_ID=hy.H_Custom' +
          ' Left Join ($SR) sr on sr.R_SerialNo=H_SerialNo ' +
          'Where H_Reporter =''$ID''';
  //xxxxx

  nStr := MacroValue(nStr, [MI('$HY', sTable_StockHuaYan),
          MI('$Cus', sTable_Customer), MI('$SR', nSR), MI('$ID', nHID)]);
  //xxxxx

  if FDM.QueryTemp(nStr).RecordCount < 1 then
  begin
    nStr := '编号为[ %s ] 的化验单记录已无效!!';
    nStr := Format(nStr, [nHID]);
    ShowMsg(nStr, sHint); Exit;
  end;

  nStr := FDM.SqlTemp.FieldByName('P_Stock').AsString;
  nStr := GetReportFileByStock(nStr);

  if not FDR.LoadReportFile(nStr) then
  begin
    nStr := '无法正确加载报表文件';
    ShowMsg(nStr, sHint); Exit;
  end;

  FDR.Dataset1.DataSet := FDM.SqlTemp;
  //FDR.ShowReport;
  FDR.PrintReport;
  Result := FDR.PrintSuccess;

  if Result  then
  begin
    nStr := 'UPDate %s Set H_PrintNum=H_PrintNum+1 Where H_Reporter=''%s'' ';
    nStr := Format(nStr, [sTable_StockHuaYan, nHID]);
    FDM.ExecuteSQL(nStr);
  end;
end;

procedure TfFormMain.imgPrintClick(Sender: TObject);
var
  nP: TFormCommandParam;
  nHyDan,nStockname,nstockno:string;
  nShortFileName:string;
  nStr:string;
begin
  nShortFileName := '';
  CreateBaseFormItem(cFI_FormBarCodePrint, '', @nP);
  if (nP.FCommand = cCmd_ModalResult) and (nP.FParamA = mrOK) then
  begin
    nHyDan := nP.FParamB;
    nStockname := nP.FParamC;
    nstockno := nP.FParamD;
    nShortFileName := gSysParam.FQCReportFR3Map.Values[nstockno];
    if nHyDan='' then
    begin
      ShowMsg('当前品种无需打印化验单。',sHint);
      Exit;
    end;

//    if (nShortFileName='') then
//    begin
//      nStr := '品种[ '+nstockno+' ]暂不支持自助打印质检单，请到开票窗口咨询';
//      ShowMsg(nStr,sHint);
//      WriteLog(nStr);
//      Exit;
//    end;

    if not Assigned(FDR) then
    begin
      FDR := TFDR.Create(Application);
    end;

    //if PrintHuaYanReport(nHYDan, nStockName,nstockno,nShortFileName, False) then
    if PrintHuaYanReport(nHYDan, False) then
    begin
      ShowMsg('打印成功，请在下方出纸口取走您的化验单',sHint);
    end
    else begin
      ShowMsg('打印失败，请联系开票员补打',sHint);
    end;
  end;
end;

procedure TfFormMain.imgCardClick(Sender: TObject);
var nOrderType:string;
begin
  if gSysParam.FTTCEK720ID = '' then
  begin
    ShowMsg('未配置发卡机,请联系管理员', sHint);
    Exit;
  end;

  {$IFDEF JJGL3}
    // // 选择框   可选 扫码或自助
    if Sender=imgCard then
    begin
      if not Assigned(FormBillCardHandl) then
      begin
        FormBillCardHandl := TFormBillCardHandl.Create(nil);
      end;
      FormBillCardHandl.SetControlsClear;
      FormBillCardHandl.BringToFront;
      FormBillCardHandl.Left := fFormMain.Left;
      FormBillCardHandl.Top := fFormMain.Top;
      FormBillCardHandl.Width := fFormMain.Width;
      FormBillCardHandl.Height := fFormMain.Height;
      FormBillCardHandl.Show;
    end
    else if Sender=imgPurchaseCard then
    begin
      nOrderType := 'Purchase';
    end;
  {$ELSE}
    if Sender=imgCard then
    begin
        if not Assigned(fFormNewCard) then
        begin
          fFormNewCard := TfFormNewCard.Create(nil);
          fFormNewCard.SetControlsClear;
        end;
        fFormNewCard.BringToFront;
        fFormNewCard.Left := self.Left;
        fFormNewCard.Top := self.Top;
        fFormNewCard.Width := self.Width;
        fFormNewCard.Height := self.Height;
        fFormNewCard.Show;
    end
    else if Sender=imgPurchaseCard then
    begin
        if not Assigned(fFormNewPurchaseCard) then
        begin
          fFormNewPurchaseCard := TfFormNewPurchaseCard.Create(nil);
          fFormNewPurchaseCard.SetControlsClear;
        end;
        fFormNewPurchaseCard.BringToFront;
        fFormNewPurchaseCard.Left := self.Left;
        fFormNewPurchaseCard.Top := self.Top;
        fFormNewPurchaseCard.Width := self.Width;
        fFormNewPurchaseCard.Height := self.Height;
        fFormNewPurchaseCard.Show;
    end;
  {$ENDIF}
end;

procedure TfFormMain.FormResize(Sender: TObject);
var
  nIni:TIniFile;
  nFileName:string;
  nLeft,nTop,nWidth,nHeight:Integer;
  nItemHeigth:Integer;
begin
  nFileName := ExtractFilePath(ParamStr(0))+'Config.Ini';
  if not FileExists(nFileName) then
  begin
    Exit;
  end;
  nIni := TIniFile.Create(nFileName);
  try
    nLeft := nIni.ReadInteger('screen','left',0);
    nTop := nIni.ReadInteger('screen','top',0);
    nWidth := nIni.ReadInteger('screen','width',1024);
    nHeight := nIni.ReadInteger('screen','height',768);
    nItemHeigth := nHeight div 8;

    LabelTruck.Height := nItemHeigth;
    LabelDec.Height := nItemHeigth;
    LabelBill.Height := nItemHeigth;
    LabelOrder.Height := nItemHeigth;
    LabelTon.Height := nItemHeigth;
    LabelStock.Height := nItemHeigth;
    LabelNum.Height := nItemHeigth;
    LabelHint.Height := nItemHeigth;
    imgCard.Height := nItemHeigth;
    imgPurchaseCard.Height := nItemHeigth;
    imgPrint.Height := nItemHeigth;
    imgCard.Top := LabelHint.Top;
    imgPurchaseCard.Top := imgCard.Top+imgPurchaseCard.Height+50;
    imgPrint.Top := LabelHint.Top;

    Self.Left := nLeft;
    self.Top := nTop;
    self.Width := nWidth;
    self.Height := nHeight;

    imgPrint.Left := self.Width-imgprint.Width;
  finally
    nIni.Free;
  end;
end;

procedure TfFormMain.QueryPorderinfo(const nCard: string);
var
  nStr:string;
  nDate: TDateTime;
begin
  if (nCard = FLastCard) and (GetTickCount - FLastQuery < 8 * 1000) then
  begin
    cxlbl_Tips.Caption := '请不要频繁读卡';
    tmr1.Enabled:= True;
    Exit;
  end;

  try
    FTimeCounter := 10;
    TimerReadCard.Enabled := True;

    nStr := 'select * from %s where o_card=''%s''';
    nStr := Format(nStr, [sTable_Order, nCard]);
    FBegin := Now;
    with FDM.QuerySQL(nStr) do
    begin
      if RecordCount < 1 then
      begin
        FTimeCounter := 1;
        cxlbl_Tips.Caption := '磁卡号无效';
        tmr1.Enabled:= True;
        Exit;
      end;
      LabelBill.Caption := '交货单号: ' + FieldByName('o_id').AsString;
      LabelOrder.Caption := '采购订单: ' + FieldByName('o_bid').AsString;
      LabelTruck.Caption := '车牌号码: ' + FieldByName('o_Truck').AsString;
      LabelStock.Caption := '品种名称: ' + FieldByName('o_StockName').AsString;
      LabelTon.Caption := '开单数量: ';
    end;
    WriteLog('TfFormMain.QueryPorderinfo(nCard='''+nCard+''')查询采购单['+nStr+']-耗时：'+InttoStr(MilliSecondsBetween(Now, FBegin))+'ms');
    FLastQuery := GetTickCount;
    FLastCard := nCard;
  except
    on E: Exception do
    begin
      ShowMsg('查询失败', sHint);
      WriteLog(E.Message);
    end;
  end;
end;

function DecodeUtf8Str(const S: UTF8String): WideString;
var lenSrc, lenDst  : Integer;
begin
  lenSrc  := Length(S);
  if(lenSrc=0)then Exit;
  lenDst  := MultiByteToWideChar(CP_UTF8, 0, Pointer(S), lenSrc, nil, 0);
  SetLength(Result, lenDst);
  MultiByteToWideChar(CP_UTF8, 0, Pointer(S), lenSrc, Pointer(Result), lenDst);
end;

procedure TfFormMain.LabelHintClick(Sender: TObject);
var str, xx:string;
begin
          exit;
  str:= '5rm/57KJ54Wk54GwXOa5v+iEseehq+efs+iGjw==';
  str:= 'YjNKa1pYSmZhV1E5WVRRME16WmpNbUppTnpaak5HWTRNV0UxTm1JME9XTXdPREJqT0RZM05tWU5DbVpoWTE5dmNtUmxjbDl1YnoxUFFqRTRNRFl5TmpBd01E'+
  'a05DbTl5WkdWeWJuVnRZbVZ5UFRFNE1EY3hNamM1TVRZTkNtZHZiMlJ6U1VROU1ETTNEUXBuYjI5a2MyNWhiV1U5eXFyTjBjSHl5cTgvUHcwS2RISmhZMnR1ZFcxaVpYSTlzdUpUTXpVMk56Z05DbVJoZEdFOU1BMEtEUW89';
  str:= DecodeBase64(str);
  str:= DecodeBase64(str);
  xx:= UTF8Decode(str);
  xx:= DecodeUtf8Str(str);
  xx:= DecodeUtf8Str(str);

end;

procedure TfFormMain.LabelDecClick(Sender: TObject);
var
  nStr: string;
begin
  ShowCursor(True);
  if ShowInputPWDBox('请输入退出密码:', '用户自助查询系统', nStr) and (nStr = '6934') then
  begin
    Close;
  end
  else ShowCursor(False);
end;

procedure TfFormMain.tmr1Timer(Sender: TObject);
begin
  cxlbl_Tips.Caption:= '';
  tmr1.Enabled:= False;
end;

end.
