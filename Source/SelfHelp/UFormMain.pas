{*******************************************************************************
  作者: dmzn@163.com 2012-5-3
  描述: 用户自助查询
*******************************************************************************}
unit UFormMain;

{$I Link.Inc} 
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, Menus, ExtCtrls, CPort, cxButtonEdit, cxTextEdit,
  cxMaskEdit, cxDropDownEdit, UBitmapButton, StdCtrls, UTransEdit,
  cxButtons, cxLabel, UBitmapPanel, cxPC;

type
  TfFormMain = class(TForm)
    ComPort1: TComPort;
    Timer1: TTimer;
    wPage1: TcxPageControl;
    SheetQuery: TcxTabSheet;
    SheetBill: TcxTabSheet;
    PanelBG: TZnBitmapPanel;
    LabelNum: TcxLabel;
    LabelTon: TcxLabel;
    LabelStock: TcxLabel;
    LabelOrder: TcxLabel;
    LabelBill: TcxLabel;
    PanelTitle: TZnBitmapPanel;
    LabelTruck: TcxLabel;
    LabelDec: TcxLabel;
    PanelFoot: TZnBitmapPanel;
    BtnZhiKa: TZnBitmapButton;
    BtnPrint: TZnBitmapButton;
    LabelHint: TcxLabel;
    PanelZKBG: TZnBitmapPanel;
    LabelZKCustomer: TcxLabel;
    LabelZKDays: TcxLabel;
    LabelZKMoney: TcxLabel;
    EditZKStocks: TcxComboBox;
    cxLabel5: TcxLabel;
    SheetBG: TcxTabSheet;
    PanelBGDefault: TZnBitmapPanel;
    PanelCode: TPanel;
    Label1: TcxLabel;
    BtnCodeOK: TcxButton;
    BtnCodeExit: TcxButton;
    EditCode: TZnTransEdit;
    cxLabel6: TcxLabel;
    EditZKTrucks: TcxComboBox;
    cxLabel7: TcxLabel;
    EditZKValue: TcxButtonEdit;
    BtnZKOK: TcxButton;
    BtnZKExit: TcxButton;
    PanelZKTitle: TZnBitmapPanel;
    LabelZK: TcxLabel;
    LabelZKDesc: TcxLabel;
    PanelDlg: TPanel;
    BtnDlgExit: TcxButton;
    LabelMsg: TcxLabel;
    TimerDlg: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ComPort1RxChar(Sender: TObject; Count: Integer);
    procedure Timer1Timer(Sender: TObject);
    procedure LabelDecDblClick(Sender: TObject);
    procedure BtnZhiKaClick(Sender: TObject);
    procedure BtnCodeExitClick(Sender: TObject);
    procedure BtnCodeOKClick(Sender: TObject);
    procedure BtnZKExitClick(Sender: TObject);
    procedure BtnDlgExitClick(Sender: TObject);
    procedure EditCodeKeyPress(Sender: TObject; var Key: Char);
    procedure EditZKTrucksPropertiesEditValueChanged(Sender: TObject);
    procedure EditZKValuePropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure BtnZKOKClick(Sender: TObject);
    procedure TimerDlgTimer(Sender: TObject);
    procedure EditZKTrucksKeyPress(Sender: TObject; var Key: Char);
    procedure EditZKValueEnter(Sender: TObject);
  private
    { Private declarations }
    FBuffer: string;
    //接收缓冲
    FLastCard: string;
    FLastQuery: Int64;
    //上次查询
    FTimeCounter: Integer;
    //计时
    FDlgTimerStatus: Boolean;
    FDlgLastPage: TcxTabSheet;
    //对话框跳转
    procedure ActionComPort(const nStop: Boolean);
    //串口处理
    procedure QueryCard(const nCard: string);
    //查询卡信息
    procedure StopTimer;
    //停止倒计时
    procedure ShowZKCodePanel(const nShow: Boolean);
    procedure ShowDlgPanel(nMsg: string; const nTag: Integer = 0;
      const nShow: Boolean = True);
    //显示面板
    function LoadZhiKaStocks(const nZhiKa: string): Boolean;
    //纸卡可选品种
    procedure CombinStockAndPrice(const nApplyPrice: Boolean);
    //合并价格
    procedure LoadZhiKaInfo(const nZhiKa: string);
    //纸卡扩展信息
    procedure MakeBill;
    //开单
  public
    { Public declarations }
  end;

var
  fFormMain: TfFormMain;

implementation

{$R *.dfm}

uses
  IniFiles, ULibFun, CPortTypes, USmallFunc, USysLoger, USysDB, UDataModule,
  UMgrTTCEDispenser, UFormConn, UBusinessPacker, USysConst;

//Desc: 测试nConnStr是否有效
function ConnCallBack(const nConnStr: string): Boolean;
begin
  FDM.ADOConn.Close;
  FDM.ADOConn.ConnectionString := nConnStr;
  FDM.ADOConn.Open;
  Result := FDM.ADOConn.Connected;
end;

procedure TfFormMain.FormCreate(Sender: TObject);
var nStr: string;
    nIdx: Integer;
begin
  Randomize();
  gPath := ExtractFilePath(Application.ExeName);
  InitGlobalVariant(gPath, gPath+sConfigFile, gPath+sFormConfig, gPath+sDBConfig);

  gSysLoger := TSysLoger.Create(gPath + 'Logs\');
  gSysLoger.LogSync := False;
  //system loger
  gShowDlg := ShowDlgPanel;

  FLastQuery := 0;
  FLastCard := '';
  FTimeCounter := 0; //init
  PanelTitle.Height := LabelBill.Height;
  PanelZKTitle.Height := LabelZKCustomer.Height;
  
  for nIdx:=wPage1.PageCount-1 downto 0 do
    wPage1.Pages[nIdx].TabVisible := False;
  wPage1.ActivePage := SheetQuery;

  FDlgLastPage := nil;
  FDlgTimerStatus := False;

  ShowCursor(True);
  ShowZKCodePanel(False);
  ShowDlgPanel('', 0, False);
                           
  nStr := gPath + 'bg.bmp';
  if FileExists(nStr) then
  begin
    for nIdx:=ComponentCount -1 downto 0 do
     if Components[nIdx] is TZnBitmapPanel then
      TZnBitmapPanel(Components[nIdx]).LoadBitmap(nStr);
    //xxxxx
  end;

  ShowConnectDBSetupForm(ConnCallBack);
  FDM.ADOConn.Close;
  FDM.ADOConn.ConnectionString := BuildConnectDBStr;
  //数据库连接

  InitSystemObject;
  //初始化对象
  ActionComPort(False);
  //启动读头
end;

procedure TfFormMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  ActionComPort(True);
  gDispenserManager.StopDispensers;
end;

procedure TfFormMain.LabelDecDblClick(Sender: TObject);
begin
  ShowCursor(True);
  if QueryDlg(sCloseQuery, sHint) then
       Close
  else ShowCursor(False);
end;

//Desc: 串口操作
procedure TfFormMain.ActionComPort(const nStop: Boolean);
var nInt: Integer;
    nIni: TIniFile;
begin
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

    if Port <> '' then
      ComPort1.Open;
    //xxxxx
  end;
end;

procedure TfFormMain.Timer1Timer(Sender: TObject);
begin
  if FTimeCounter <= 0 then
  begin
    StopTimer();
    //停止计时

    if wPage1.ActivePage = SheetBill then
      BtnZKExit.Click();
    //xxxxx
  end else
  begin
    if wPage1.ActivePage = SheetBill then
         LabelZKDesc.Caption := IntToStr(FTimeCounter) + ' '
    else LabelDec.Caption := IntToStr(FTimeCounter) + ' ';
  end;

  Dec(FTimeCounter);
end;

procedure TfFormMain.TimerDlgTimer(Sender: TObject);
begin
  if (TimerDlg.Tag <= 0) then
  begin
    TimerDlg.Enabled := False;
    BtnDlgExit.Click();
    BtnDlgExit.Caption := '关闭';
  end else
  begin  
    BtnDlgExit.Caption := Format('关闭(%d)', [TimerDlg.Tag]);
    TimerDlg.Tag := TimerDlg.Tag - 1;
  end;
end;

procedure TfFormMain.ComPort1RxChar(Sender: TObject; Count: Integer);
var nStr: string;
    nIdx,nLen: Integer;
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
    QueryCard(ParseCardNO(nStr, True));
    Exit;
  end;
end;

//Date: 2012-5-3
//Parm: 卡号
//Desc: 查询nCard信息
procedure TfFormMain.QueryCard(const nCard: string);
var nVal: Double;
    nDate,nInFact,nPDate: TDateTime;
    nStr,nStock,nBill,nVip,nLine,nPoundQueue: string;
begin
  mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0);
  mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, 0);
  //close screen saver

  if wPage1.ActivePage <> SheetQuery then Exit;
  //非查询界面

  if (nCard = FLastCard) and (GetTickCount - FLastQuery < 8 * 1000) then
  begin
    LabelDec.Caption := '请不要频繁刷卡';
    Exit;
  end;    

  try
    FTimeCounter := 10;
    Timer1.Enabled := True;

    nStr := 'Select * From %s Where L_Card=''%s''';
    nStr := Format(nStr, [sTable_Bill, nCard]);

    with FDM.SQLQuery(nStr) do
    begin
      if RecordCount < 1 then
      begin
        LabelDec.Caption := '磁卡号无效';
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

      nBill :=  FieldByName('L_ID').AsString;
      nStock := FieldByName('L_StockNo').AsString;
      nVip := FieldByName('L_IsVip').AsString;

      LabelBill.Caption := '交货单号: ' + FieldByName('L_ID').AsString;
      LabelOrder.Caption := '销售订单: ' + FieldByName('L_ZhiKa').AsString;
      LabelTruck.Caption := '车牌号码: ' + FieldByName('L_Truck').AsString;
      LabelStock.Caption := '品种名称: ' + FieldByName('L_StockName').AsString;
      LabelTon.Caption := '提货数量: ' + FieldByName('L_Value').AsString + '吨';
    end;

    //--------------------------------------------------------------------------
    nStr := 'Select Count(*) From %s ' +
            'Where Z_StockNo=''%s'' And Z_Valid=''%s'' And Z_VipLine=''%s''';
    nStr := Format(nStr, [sTable_ZTLines, nStock, sFlag_Yes, nVip]);

    with FDM.SQLQuery(nStr) do
    begin
      LabelNum.Caption := '开放道数: ' + Fields[0].AsString + '个';
    end;

    //--------------------------------------------------------------------------
    nStr := 'Select T_line,T_InTime,T_InFact,T_PDate,T_Valid From %s ZT ' +
             'Where T_Bill=''%s'' ';
    nStr := Format(nStr, [sTable_ZTTrucks, nBill]);

    with FDM.SQLQuery(nStr) do
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

      nInFact := FieldByName('T_InFact').AsDateTime;
      nPDate := FieldByName('T_PDate').AsDateTime;
      //进厂过皮
    end;

    if nLine <> '' then
    begin
      nStr := 'Select Z_Valid,Z_Name From %s Where Z_ID=''%s'' ';
      nStr := Format(nStr, [sTable_ZTLines, nLine]);

      with FDM.SQLQuery(nStr) do
      begin
        if FieldByName('Z_Valid').AsString = 'N' then
        begin
          LabelHint.Caption := '您所在的通道已关闭，请联系调度人员.';
          Exit;
        end else
        begin
          LabelHint.Caption := '系统内您的车辆已入厂,请到' +
            FieldByName('Z_Name').AsString + '提货.';
          Exit;
        end;
      end;
    end;

    nPoundQueue := sFlag_No;
    nStr := 'Select D_Value From $DT Where D_Memo = ''$PQ''';
    nStr := MacroValue(nStr, [MI('$DT', sTable_SysDict),
            MI('$PQ', sFlag_PoundQueue)]);
    //xxxxx

    with FDM.SQLQuery(nStr) do
     if (RecordCount > 0) and (FieldByName('D_Value').AsString = sFlag_Yes) then
       nPoundQueue := sFlag_Yes;
    //xxxxx

    nStr := 'Select D_Value From $DT Where D_Memo = ''$DQ''';
    nStr := MacroValue(nStr, [MI('$DT', sTable_SysDict),
            MI('$DQ', sFlag_DelayQueue)]);
    //xxxxx

    with FDM.SQLQuery(nStr) do
    begin
      if (RecordCount > 0) and (FieldByName('D_Value').AsString = sFlag_Yes) then
      begin
        if nPoundQueue = sFlag_Yes then
        begin
          if nPDate < Date() - 365 then
          begin
            LabelHint.Caption := '称量皮重后才能查询队列信息';
            Exit;
          end;

          nDate := nPDate;
          //使用皮重时间
          
          nStr := 'Select Count(*) From $TB Where T_InQueue Is Null And ' +
                  'T_Valid=''$Yes'' And T_StockNo=''$SN'' And ' +
                  'T_PDate<''$IT'' And T_Vip=''$VIP''';
          //xxxxx
        end else
        begin
          if nInFact < Date() - 365 then
          begin
            LabelHint.Caption := '刷卡进厂后才能查询队列信息';
            Exit;
          end;

          nDate := nInFact;
          //使用进厂时间

          nStr := 'Select Count(*) From $TB Where T_InQueue Is Null And ' +
                  'T_Valid=''$Yes'' And T_StockNo=''$SN'' And ' +
                  'T_InFact<''$IT'' And T_Vip=''$VIP''';
          //xxxxx
        end;
      end else
      begin
        nStr := 'Select Count(*) From $TB Where T_InQueue Is Null And ' +
                'T_Valid=''$Yes'' And T_StockNo=''$SN'' And ' +
                'T_InTime<''$IT'' And T_Vip=''$VIP''';
      end;

      nStr := MacroValue(nStr, [MI('$TB', sTable_ZTTrucks),
            MI('$Yes', sFlag_Yes), MI('$SN', nStock),
            MI('$IT', DateTime2Str(nDate)),MI('$VIP', nVip)]);
    end;
    //xxxxx

    with FDM.SQLQuery(nStr) do
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

  FDM.ADOConn.Connected := False;
end;

//------------------------------------------------------------------------------
//Desc: 停止倒计时
procedure TfFormMain.StopTimer;
begin
  Timer1.Enabled := False;
  FTimeCounter := 0;

  LabelDec.Caption := '';
  LabelZKDesc.Caption := '';
  
  LabelBill.Caption := '交货单号:';
  LabelTruck.Caption := '车牌号码:';
  LabelOrder.Caption := '销售订单:';
  LabelStock.Caption := '品种名称:';
  LabelNum.Caption := '开放道数:';
  LabelTon.Caption := '提货数量:';
  LabelHint.Caption := '请您刷卡';
end;

//Desc: 制卡 
procedure TfFormMain.BtnZhiKaClick(Sender: TObject);
begin
  StopTimer();
  ShowZKCodePanel(True);
end;

//Desc: 显隐面板
procedure TfFormMain.ShowZKCodePanel(const nShow: Boolean);
begin
  if nShow then
  begin
    wPage1.ActivePage := SheetBG;
    //xxxxx

    with PanelCode do
    begin
      Left := Trunc((PanelBGDefault.Width - Width) / 2);
      Top := Trunc((PanelBGDefault.Height - Height) / 2);

      BringToFront;
      Visible := True;
    end;

    EditCode.Clear;
    ActiveControl := EditCode;
  end else
  begin
    PanelCode.SendToBack;
    PanelCode.Visible := False;
  end;
end;

//Desc: 提货码取消
procedure TfFormMain.BtnCodeExitClick(Sender: TObject);
begin
  ShowZKCodePanel(False);
  wPage1.ActivePage := SheetQuery;
end;

//Desc: 显示消息
procedure TfFormMain.ShowDlgPanel(nMsg: string; const nTag: Integer;
  const nShow: Boolean);
begin
  if nShow then
  begin
    FDlgTimerStatus := Timer1.Enabled;
    Timer1.Enabled := False;
    //停用计时
    
    FDlgLastPage := wPage1.ActivePage;
    //备份页面,关闭时还原
    wPage1.ActivePage := SheetBG;

    with PanelDlg do
    begin
      Left := Trunc((PanelBGDefault.Width - Width) / 2);
      Top := Trunc((PanelBGDefault.Height - Height) / 2);
      Tag := nTag;
      
      BringToFront;
      Visible := True; 
    end;

    if Pos('来源', nMsg) = 1 then
    begin
      System.Delete(nMsg, 1, Pos(#13#10, nMsg));
      nMsg := Trim(nMsg);
    end;

    if Pos('对象', nMsg) = 1 then
    begin
      System.Delete(nMsg, 1, Pos(#13#10, nMsg));
      nMsg := Trim(nMsg);
    end;

    LabelMsg.Caption := nMsg;
    ActiveControl := BtnDlgExit;
    BtnDlgExit.Invalidate;

    TimerDlg.Tag := cShowDlgLong;
    TimerDlg.Enabled := True;
  end else
  begin
    TimerDlg.Enabled := False;
    TimerDlg.Tag := 0;

    PanelDlg.SendToBack;
    PanelDlg.Visible := False;

    if Assigned(FDlgLastPage) then
    begin
      wPage1.ActivePage := FDlgLastPage;
      FDlgLastPage := nil;

      if not Timer1.Enabled then
        Timer1.Enabled := FDlgTimerStatus;
      //xxxxx
    end;
  end;
end;

//Desc: 对话框取消
procedure TfFormMain.BtnDlgExitClick(Sender: TObject);
begin
  ShowDlgPanel('', 0, False);
  if PanelCode.Visible and (wPage1.ActivePage = SheetBG) then //输入提货码业务
  begin
    ActiveControl := EditCode;
    EditCode.SelectAll;
  end;

  case PanelDlg.Tag of
   cBus_CheckTruck: //输入车牌号
    begin
      ActiveControl := EditZKTrucks;
    end;
   cBus_CheckValue: //输入提货量
    begin
      ActiveControl := EditZKValue;
      EditZKValue.SelectAll;
    end;
   cBus_BillDone: //办卡成功
    begin
      StopTimer();
      wPage1.ActivePage := SheetQuery;
    end;
  end;
end;

//Desc: 制卡返回
procedure TfFormMain.BtnZKExitClick(Sender: TObject);
begin
  StopTimer();
  wPage1.ActivePage := SheetQuery;
end;

procedure TfFormMain.EditCodeKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = Char(VK_RETURN) then
  begin
    Key := #0;
    BtnCodeOK.Click();
  end;
end;

procedure TfFormMain.EditZKTrucksKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = Char(VK_RETURN) then
  begin
    Key := #0;
    if Sender = EditZKTrucks then
    begin
      ActiveControl := EditZKValue;
      EditZKValue.SelectAll;
    end else

    if Sender = EditZKValue then
    begin
      BtnZKOK.Click();
    end;
  end;
end;

procedure TfFormMain.EditZKValueEnter(Sender: TObject);
begin
  EditZKValue.SelectAll;
end;

//Desc: 提货码确认
procedure TfFormMain.BtnCodeOKClick(Sender: TObject);
var nStr,nHint: string;
begin
  EditCode.Text := Trim(EditCode.Text);
  if EditCode.Text = '' then
  begin
    ShowDlgPanel('请输入有效的提货代码', cBus_CheckCode);
    Exit;
  end;

  nStr := gDispenserManager.GetCardNo(sDispenser, nHint, False);
  if nStr = '' then
  begin
    if nHint = '' then
         ShowDlgPanel('发卡机中没有磁卡,请稍后再试', cBus_CheckCode)
    else ShowDlgPanel(nHint, cBus_CheckCode);
    Exit;
  end;

  with gZhiKa do
  try
    BtnCodeOK.Enabled := False;
    FCode := EditCode.Text;
    FZhiKa := FCode;
    FCard := nStr;

    if not IsZhiKaValid(FZhiKa, FCusID, True) then Exit;
    //验证纸卡
    FMoney := GetZhikaValidMoney(FZhiKa);
    //获取纸卡可用金

    if FMoney < 1 then
    begin
      ShowDlgPanel('客户资金余额不足,无法办理业务', cBus_CheckCode);
      Exit;
    end;

    if not IsCustomerCreditValid(FCusID) then Exit;
    //验证信用过期

    if not LoadStockItemsPrice(FCusID, gStockTypes) then Exit;
    //载入价格列表

    if not LoadZhiKaStocks(FZhiKa) then Exit;
    //载入可选品种
    LoadZhiKaInfo(FZhiKa);
    
    ShowZKCodePanel(False);
    wPage1.ActivePage := SheetBill;
    ActiveControl := EditZKTrucks;

    EditZKValue.Text := '';
    EditZKTrucks.SelLength := 0;
    EditZKTrucks.SelStart := Length(EditZKTrucks.Text);
    
    FTimeCounter := cMakeBillLong;
    Timer1.Enabled := True;
  finally
    BtnCodeOK.Enabled := True;
  end;
end;

procedure TfFormMain.EditZKTrucksPropertiesEditValueChanged(
  Sender: TObject);
begin
  EditZKTrucks.SelLength := 0;
  EditZKTrucks.SelStart := Length(EditZKTrucks.Text);
end;

//Date: 2018-12-20
//Parm: 纸卡号
//Desc: 载入nZhiKa的可用品种
function TfFormMain.LoadZhiKaStocks(const nZhiKa: string): Boolean;
var nStr: string;
    nIdx,nInt,nMax: Integer;
begin
  SetLength(gStockList, 0);
  nStr := 'Select * From %s Where D_ZID=''%s''';
  nStr := Format(nStr, [sTable_ZhiKaDtl, nZhiKa]);

  with FDM.SQLQuery(nStr) do
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

  Result := Length(gStockList) > 0;
  if not Result then
  begin
    ShowDlgPanel('纸卡上没有可以提货的品种,请联系管理');
    Exit;
  end;

  CombinStockAndPrice(True);
  //apply price
  EditZKStocks.Properties.Items.Clear;
  
  for nIdx:=Low(gStockList) to High(gStockList) do
   with gStockList[nIdx] do
    EditZKStocks.Properties.Items.AddObject(FStockName, Pointer(nIdx));
  EditZKStocks.ItemIndex := 0;

  nStr := 'Select D_Value From %s Where D_Name=''%s'' And D_Memo=''%s''';
  nStr := Format(nStr, [sTable_SysDict, sFlag_SysParam, sFlag_TruckItem]);

  with FDM.SQLQuery(nStr) do
  if RecordCount > 0 then
  begin
    EditZKTrucks.Properties.Items.Clear;
    SplitStr(Fields[0].AsString, EditZKTrucks.Properties.Items, 0, ',');
    EditZKTrucks.ItemIndex := 0;
  end;

  nMax := 0;
  EditZKStocks.Canvas.Font.Assign(EditZKStocks.Style.Font);
  for nIdx:=Low(gStockList) to High(gStockList) do
  begin
    nInt := EditZKStocks.Canvas.TextWidth(gStockList[nIdx].FStockName);
    if nInt > nMax then nMax := nInt;
  end;

  if nMax > 100 then
  begin
    nMax := nMax + 200;
    EditZKStocks.Width := nMax;
    EditZKTrucks.Width := nMax;
    EditZKValue.Width := nMax;
  end;
end;

//Desc: 将价格合并到纸卡品种列表
procedure TfFormMain.CombinStockAndPrice(const nApplyPrice: Boolean);
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

//Desc: 获取最小提货量
procedure TfFormMain.EditZKValuePropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
var nStr: string;
begin
  EditZKTrucks.Text := Trim(EditZKTrucks.Text);
  if EditZKTrucks.Text = '' then
  begin
    ShowDlgPanel('请输入车牌号', cBus_CheckTruck);
    Exit;
  end;

  nStr := 'Select T_MaxNet From %s Where T_Truck=''%s''';
  nStr := Format(nStr, [sTable_Truck, EditZKTrucks.Text]);

  with FDM.SQLQuery(nStr) do
  if RecordCount > 0 then
  begin
    EditZKValue.Text := Fields[0].AsString;
    EditZKValue.SelectAll;
  end;
end;

//Date: 2018-12-20
//Parm: 纸卡号
//Desc: 载入纸卡信息
procedure TfFormMain.LoadZhiKaInfo(const nZhiKa: string);
var nStr: string;
begin
  nStr := 'Select Z_ValidDays,C_Name From %s ' +
          ' Left Join %s On C_ID=Z_Customer ' +
          'Where Z_ID=''%s''';
  nStr := Format(nStr, [sTable_ZhiKa, sTable_Customer, nZhiKa]);

  with FDM.SQLQuery(nStr),gZhiKa do
  if RecordCount > 0 then
  begin
    LabelZK.Caption := '纸卡编号: ' + FZhiKa;
    FCusName := FieldByName('C_Name').AsString;
    LabelZKCustomer.Caption := '客户名称: ' + FCusName;

    LabelZKDays.Caption := '有效期至: ' +
                           Date2Str(FieldByName('Z_ValidDays').AsDateTime);
    //xxxxx

    if FMoney > 10000 then
         LabelZKMoney.Caption := '可用金额: ' + '>10000元'
    else LabelZKMoney.Caption := '可用金额: ' + Format('%.2f元', [FMoney]);
  end;
end;

//Desc: 制卡
procedure TfFormMain.BtnZKOKClick(Sender: TObject);
begin
  if EditZKStocks.ItemIndex < 0 then
  begin
    ShowDlgPanel('请选择提货品种');
    Exit;
  end;

  if (not IsNumber(EditZKValue.Text, True)) or
     (StrToFloat(EditZKValue.Text) <= 0) then
  begin
    ShowDlgPanel('提货量是大于0的数值', cBus_CheckValue);
    Exit;
  end;

  BtnZKOK.Enabled := False;
  try
    Timer1.Enabled := False;
    MakeBill;
  finally
    if FTimeCounter > 10 then
      Timer1.Enabled := True;
    BtnZKOK.Enabled := True;
  end;   
end;

procedure TfFormMain.MakeBill;
var nStr: string;
    nIdx: Integer;
    nVal: Double;
    nList,nTmp: TStrings;
begin
  if not LoadStockItemsPrice(gZhiKa.FCusID, gStockTypes) then Exit;
  //重新载入价格
  CombinStockAndPrice(False);

  with EditZKStocks do
    nIdx := Integer(Properties.Items.Objects[ItemIndex]);
  //选中品种

  with gStockList[nIdx] do
  begin
    if (FPriceIndex < 0) or (FPrice <> gStockTypes[FPriceIndex].FPrice) then
    begin
      ShowDlgPanel('当前价格已失效(刚调价),请返回重新制卡');
      Exit;
    end;

    FSelecte := True;
    //选中

    nVal := FPrice * StrToFloat(EditZKValue.Text);
    nVal := Float2Float(nVal, cPrecision, True);
    nVal := nVal - gZhiKa.FMoney;

    if nVal > 0 then
    begin
      nStr := '当前纸卡余额不足,请补交%.2f元 或 使用其它提货代码';
      ShowDlgPanel(Format(nStr, [nVal]), cBus_CheckValue);
      Exit;
    end;
  end;

  nList := TStringList.Create;
  nTmp := TStringList.Create;
  try
    nList.Clear;
    for nIdx:=Low(gStockList) to High(gStockList) do
    with gStockList[nIdx],nTmp do
    begin
      if not FSelecte then Continue;
      //xxxxx

      Values['Type'] := FType;
      Values['StockNO'] := FStockNO;
      Values['StockName'] := FStockName;
      Values['Price'] := FloatToStr(FPrice);
      Values['Value'] := EditZKValue.Text;

      Values['PriceDesc'] := gStockTypes[FPriceIndex].FParam;
      //价格描述
      nList.Add(PackerEncodeStr(nTmp.Text));
      //new bill
    end;

    with nList do
    begin
      Values['Bills'] := PackerEncodeStr(nList.Text);
      Values['ZhiKa'] := gZhiKa.FZhiKa;
      Values['Truck'] := EditZKTrucks.Text;
      Values['Lading'] := sFlag_TiHuo;
      Values['IsVIP'] := sFlag_TypeCommon;
      Values['BuDan'] := sFlag_No;
      Values['Card'] := gZhiKa.FCard;
    end;

    gZhiKa.FBill := SaveBill(PackerEncodeStr(nList.Text));
    if gZhiKa.FBill = '' then Exit;

    if not SaveBillCard(gZhiKa.FBill, gZhiKa.FCard) then Exit;
    gDispenserManager.SendCardOut(sDispenser, nStr);
    ShowDlgPanel('办卡成功,请取卡', cBus_BillDone);
  finally
    nTmp.Free;
    nList.Free;
  end;
end;

end.
