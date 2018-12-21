{*******************************************************************************
  ����: dmzn@163.com 2012-5-3
  ����: �û�������ѯ
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
    //���ջ���
    FLastCard: string;
    FLastQuery: Int64;
    //�ϴβ�ѯ
    FTimeCounter: Integer;
    //��ʱ
    FDlgTimerStatus: Boolean;
    FDlgLastPage: TcxTabSheet;
    //�Ի�����ת
    procedure ActionComPort(const nStop: Boolean);
    //���ڴ���
    procedure QueryCard(const nCard: string);
    //��ѯ����Ϣ
    procedure StopTimer;
    //ֹͣ����ʱ
    procedure ShowZKCodePanel(const nShow: Boolean);
    procedure ShowDlgPanel(nMsg: string; const nTag: Integer = 0;
      const nShow: Boolean = True);
    //��ʾ���
    function LoadZhiKaStocks(const nZhiKa: string): Boolean;
    //ֽ����ѡƷ��
    procedure CombinStockAndPrice(const nApplyPrice: Boolean);
    //�ϲ��۸�
    procedure LoadZhiKaInfo(const nZhiKa: string);
    //ֽ����չ��Ϣ
    procedure MakeBill;
    //����
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

//Desc: ����nConnStr�Ƿ���Ч
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
  //���ݿ�����

  InitSystemObject;
  //��ʼ������
  ActionComPort(False);
  //������ͷ
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

//Desc: ���ڲ���
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
    //ֹͣ��ʱ

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
    BtnDlgExit.Caption := '�ر�';
  end else
  begin  
    BtnDlgExit.Caption := Format('�ر�(%d)', [TimerDlg.Tag]);
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
//Parm: ����
//Desc: ��ѯnCard��Ϣ
procedure TfFormMain.QueryCard(const nCard: string);
var nVal: Double;
    nDate,nInFact,nPDate: TDateTime;
    nStr,nStock,nBill,nVip,nLine,nPoundQueue: string;
begin
  mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0);
  mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, 0);
  //close screen saver

  if wPage1.ActivePage <> SheetQuery then Exit;
  //�ǲ�ѯ����

  if (nCard = FLastCard) and (GetTickCount - FLastQuery < 8 * 1000) then
  begin
    LabelDec.Caption := '�벻ҪƵ��ˢ��';
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
        LabelDec.Caption := '�ſ�����Ч';
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

      LabelBill.Caption := '��������: ' + FieldByName('L_ID').AsString;
      LabelOrder.Caption := '���۶���: ' + FieldByName('L_ZhiKa').AsString;
      LabelTruck.Caption := '���ƺ���: ' + FieldByName('L_Truck').AsString;
      LabelStock.Caption := 'Ʒ������: ' + FieldByName('L_StockName').AsString;
      LabelTon.Caption := '�������: ' + FieldByName('L_Value').AsString + '��';
    end;

    //--------------------------------------------------------------------------
    nStr := 'Select Count(*) From %s ' +
            'Where Z_StockNo=''%s'' And Z_Valid=''%s'' And Z_VipLine=''%s''';
    nStr := Format(nStr, [sTable_ZTLines, nStock, sFlag_Yes, nVip]);

    with FDM.SQLQuery(nStr) do
    begin
      LabelNum.Caption := '���ŵ���: ' + Fields[0].AsString + '��';
    end;

    //--------------------------------------------------------------------------
    nStr := 'Select T_line,T_InTime,T_InFact,T_PDate,T_Valid From %s ZT ' +
             'Where T_Bill=''%s'' ';
    nStr := Format(nStr, [sTable_ZTTrucks, nBill]);

    with FDM.SQLQuery(nStr) do
    begin
      if RecordCount < 1 then
      begin
        LabelHint.Caption := '���ĳ�������Ч.';
        Exit;
      end;

      if FieldByName('T_Valid').AsString <> sFlag_Yes then
      begin
        LabelHint.Caption := '���ѳ�ʱ����,�뵽������������������.';
        Exit;
      end;

      nDate := FieldByName('T_InTime').AsDateTime;
      //����ʱ��
      nLine := FieldByName('T_Line').AsString;
      //ͨ����

      nInFact := FieldByName('T_InFact').AsDateTime;
      nPDate := FieldByName('T_PDate').AsDateTime;
      //������Ƥ
    end;

    if nLine <> '' then
    begin
      nStr := 'Select Z_Valid,Z_Name From %s Where Z_ID=''%s'' ';
      nStr := Format(nStr, [sTable_ZTLines, nLine]);

      with FDM.SQLQuery(nStr) do
      begin
        if FieldByName('Z_Valid').AsString = 'N' then
        begin
          LabelHint.Caption := '�����ڵ�ͨ���ѹرգ�����ϵ������Ա.';
          Exit;
        end else
        begin
          LabelHint.Caption := 'ϵͳ�����ĳ������볧,�뵽' +
            FieldByName('Z_Name').AsString + '���.';
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
            LabelHint.Caption := '����Ƥ�غ���ܲ�ѯ������Ϣ';
            Exit;
          end;

          nDate := nPDate;
          //ʹ��Ƥ��ʱ��
          
          nStr := 'Select Count(*) From $TB Where T_InQueue Is Null And ' +
                  'T_Valid=''$Yes'' And T_StockNo=''$SN'' And ' +
                  'T_PDate<''$IT'' And T_Vip=''$VIP''';
          //xxxxx
        end else
        begin
          if nInFact < Date() - 365 then
          begin
            LabelHint.Caption := 'ˢ����������ܲ�ѯ������Ϣ';
            Exit;
          end;

          nDate := nInFact;
          //ʹ�ý���ʱ��

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
        nStr := '�����ŵ�����,���ע��������׼������.';
        LabelHint.Caption := nStr;
      end else
      begin
        nStr := '��ǰ�滹�С� %d �������ȴ�����';
        LabelHint.Caption := Format(nStr, [Fields[0].AsInteger]);
      end;
    end;

    FLastQuery := GetTickCount;
    FLastCard := nCard;
    //�ѳɹ�����
  except
    on E: Exception do
    begin
      ShowMsg('��ѯʧ��', sHint);
      WriteLog(E.Message);
    end;
  end;

  FDM.ADOConn.Connected := False;
end;

//------------------------------------------------------------------------------
//Desc: ֹͣ����ʱ
procedure TfFormMain.StopTimer;
begin
  Timer1.Enabled := False;
  FTimeCounter := 0;

  LabelDec.Caption := '';
  LabelZKDesc.Caption := '';
  
  LabelBill.Caption := '��������:';
  LabelTruck.Caption := '���ƺ���:';
  LabelOrder.Caption := '���۶���:';
  LabelStock.Caption := 'Ʒ������:';
  LabelNum.Caption := '���ŵ���:';
  LabelTon.Caption := '�������:';
  LabelHint.Caption := '����ˢ��';
end;

//Desc: �ƿ� 
procedure TfFormMain.BtnZhiKaClick(Sender: TObject);
begin
  StopTimer();
  ShowZKCodePanel(True);
end;

//Desc: �������
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

//Desc: �����ȡ��
procedure TfFormMain.BtnCodeExitClick(Sender: TObject);
begin
  ShowZKCodePanel(False);
  wPage1.ActivePage := SheetQuery;
end;

//Desc: ��ʾ��Ϣ
procedure TfFormMain.ShowDlgPanel(nMsg: string; const nTag: Integer;
  const nShow: Boolean);
begin
  if nShow then
  begin
    FDlgTimerStatus := Timer1.Enabled;
    Timer1.Enabled := False;
    //ͣ�ü�ʱ
    
    FDlgLastPage := wPage1.ActivePage;
    //����ҳ��,�ر�ʱ��ԭ
    wPage1.ActivePage := SheetBG;

    with PanelDlg do
    begin
      Left := Trunc((PanelBGDefault.Width - Width) / 2);
      Top := Trunc((PanelBGDefault.Height - Height) / 2);
      Tag := nTag;
      
      BringToFront;
      Visible := True; 
    end;

    if Pos('��Դ', nMsg) = 1 then
    begin
      System.Delete(nMsg, 1, Pos(#13#10, nMsg));
      nMsg := Trim(nMsg);
    end;

    if Pos('����', nMsg) = 1 then
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

//Desc: �Ի���ȡ��
procedure TfFormMain.BtnDlgExitClick(Sender: TObject);
begin
  ShowDlgPanel('', 0, False);
  if PanelCode.Visible and (wPage1.ActivePage = SheetBG) then //���������ҵ��
  begin
    ActiveControl := EditCode;
    EditCode.SelectAll;
  end;

  case PanelDlg.Tag of
   cBus_CheckTruck: //���복�ƺ�
    begin
      ActiveControl := EditZKTrucks;
    end;
   cBus_CheckValue: //���������
    begin
      ActiveControl := EditZKValue;
      EditZKValue.SelectAll;
    end;
   cBus_BillDone: //�쿨�ɹ�
    begin
      StopTimer();
      wPage1.ActivePage := SheetQuery;
    end;
  end;
end;

//Desc: �ƿ�����
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

//Desc: �����ȷ��
procedure TfFormMain.BtnCodeOKClick(Sender: TObject);
var nStr,nHint: string;
begin
  EditCode.Text := Trim(EditCode.Text);
  if EditCode.Text = '' then
  begin
    ShowDlgPanel('��������Ч���������', cBus_CheckCode);
    Exit;
  end;

  nStr := gDispenserManager.GetCardNo(sDispenser, nHint, False);
  if nStr = '' then
  begin
    if nHint = '' then
         ShowDlgPanel('��������û�дſ�,���Ժ�����', cBus_CheckCode)
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
    //��ֽ֤��
    FMoney := GetZhikaValidMoney(FZhiKa);
    //��ȡֽ�����ý�

    if FMoney < 1 then
    begin
      ShowDlgPanel('�ͻ��ʽ�����,�޷�����ҵ��', cBus_CheckCode);
      Exit;
    end;

    if not IsCustomerCreditValid(FCusID) then Exit;
    //��֤���ù���

    if not LoadStockItemsPrice(FCusID, gStockTypes) then Exit;
    //����۸��б�

    if not LoadZhiKaStocks(FZhiKa) then Exit;
    //�����ѡƷ��
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
//Parm: ֽ����
//Desc: ����nZhiKa�Ŀ���Ʒ��
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
  
  if Length(gStockList) < 1 then //ֽ���������Ʒ��
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
    ShowDlgPanel('ֽ����û�п��������Ʒ��,����ϵ����');
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

//Desc: ���۸�ϲ���ֽ��Ʒ���б�
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

//Desc: ��ȡ��С�����
procedure TfFormMain.EditZKValuePropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
var nStr: string;
begin
  EditZKTrucks.Text := Trim(EditZKTrucks.Text);
  if EditZKTrucks.Text = '' then
  begin
    ShowDlgPanel('�����복�ƺ�', cBus_CheckTruck);
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
//Parm: ֽ����
//Desc: ����ֽ����Ϣ
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
    LabelZK.Caption := 'ֽ�����: ' + FZhiKa;
    FCusName := FieldByName('C_Name').AsString;
    LabelZKCustomer.Caption := '�ͻ�����: ' + FCusName;

    LabelZKDays.Caption := '��Ч����: ' +
                           Date2Str(FieldByName('Z_ValidDays').AsDateTime);
    //xxxxx

    if FMoney > 10000 then
         LabelZKMoney.Caption := '���ý��: ' + '>10000Ԫ'
    else LabelZKMoney.Caption := '���ý��: ' + Format('%.2fԪ', [FMoney]);
  end;
end;

//Desc: �ƿ�
procedure TfFormMain.BtnZKOKClick(Sender: TObject);
begin
  if EditZKStocks.ItemIndex < 0 then
  begin
    ShowDlgPanel('��ѡ�����Ʒ��');
    Exit;
  end;

  if (not IsNumber(EditZKValue.Text, True)) or
     (StrToFloat(EditZKValue.Text) <= 0) then
  begin
    ShowDlgPanel('������Ǵ���0����ֵ', cBus_CheckValue);
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
  //��������۸�
  CombinStockAndPrice(False);

  with EditZKStocks do
    nIdx := Integer(Properties.Items.Objects[ItemIndex]);
  //ѡ��Ʒ��

  with gStockList[nIdx] do
  begin
    if (FPriceIndex < 0) or (FPrice <> gStockTypes[FPriceIndex].FPrice) then
    begin
      ShowDlgPanel('��ǰ�۸���ʧЧ(�յ���),�뷵�������ƿ�');
      Exit;
    end;

    FSelecte := True;
    //ѡ��

    nVal := FPrice * StrToFloat(EditZKValue.Text);
    nVal := Float2Float(nVal, cPrecision, True);
    nVal := nVal - gZhiKa.FMoney;

    if nVal > 0 then
    begin
      nStr := '��ǰֽ������,�벹��%.2fԪ �� ʹ�������������';
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
      //�۸�����
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
    ShowDlgPanel('�쿨�ɹ�,��ȡ��', cBus_BillDone);
  finally
    nTmp.Free;
    nList.Free;
  end;
end;

end.
