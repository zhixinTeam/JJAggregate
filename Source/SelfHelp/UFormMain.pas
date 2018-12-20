{*******************************************************************************
  ����: dmzn@163.com 2012-5-3
  ����: �û�������ѯ
*******************************************************************************}
unit UFormMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, cxLabel, ExtCtrls, CPort, UBitmapPanel, UTransGlass,
  UBitmapButton, cxPC, cxGroupBox, Menus, StdCtrls, cxButtons, cxTextEdit,
  cxRadioGroup, cxCheckComboBox, cxCheckListBox, cxMaskEdit, cxDropDownEdit,
  UTransEdit, cxButtonEdit;

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
  private
    { Private declarations }
    FBuffer: string;
    //���ջ���
    FLastCard: string;
    FLastQuery: Int64;
    //�ϴβ�ѯ
    FTimeCounter: Integer;
    //��ʱ
    procedure ActionComPort(const nStop: Boolean);
    //���ڴ���
    procedure QueryCard(const nCard: string);
    //��ѯ����Ϣ
    procedure ShowZKCodePanel(const nShow: Boolean);
    procedure ShowDlgPanel(const nMsg: string; const nTag: Integer = 0;
      const nShow: Boolean = True);
    //��ʾ���
  public
    { Public declarations }
  end;

var
  fFormMain: TfFormMain;

implementation

{$R *.dfm}

uses
  IniFiles, ULibFun, CPortTypes, USysLoger, USysDB, USmallFunc, UDataModule,
  UFormConn, UMgrTTCEDispenser, UClientWorker, USysConst;

//Desc: ��¼��־
procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(TfFormMain, '����������', nEvent);
end;

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
  gPath := ExtractFilePath(Application.ExeName);
  InitGlobalVariant(gPath, gPath+sConfigFile, gPath+sFormConfig, gPath+sDBConfig);

  gSysLoger := TSysLoger.Create(gPath + 'Logs\');
  gSysLoger.LogSync := False;

  gDispenserManager := TDispenserManager.Create;
  gDispenserManager.LoadConfig(gPath + 'TTCE_K720.xml');
  gDispenserManager.StartDispensers;

  PanelTitle.Height := LabelBill.Height;
  PanelZKTitle.Height := LabelZKCustomer.Height;
  
  for nIdx:=wPage1.PageCount-1 downto 0 do
    wPage1.Pages[nIdx].TabVisible := False;
  wPage1.ActivePage := SheetQuery;

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

  FLastQuery := 0;
  FLastCard := '';
  FTimeCounter := 0;
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
    Timer1.Enabled := False;
    if wPage1.ActivePage = SheetBill then
         BtnZKExit.Click
    else LabelDec.Caption := '';

    LabelBill.Caption := '��������:';
    LabelTruck.Caption := '���ƺ���:';
    LabelOrder.Caption := '���۶���:';
    LabelStock.Caption := 'Ʒ������:';
    LabelNum.Caption := '���ŵ���:';
    LabelTon.Caption := '�������:';
    LabelHint.Caption := '����ˢ��';
  end else
  begin
    if wPage1.ActivePage = SheetBill then
         LabelZKDesc.Caption := IntToStr(FTimeCounter) + ' '
    else LabelDec.Caption := IntToStr(FTimeCounter) + ' ';
  end;

  Dec(FTimeCounter);
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
//Desc: �ƿ� 
procedure TfFormMain.BtnZhiKaClick(Sender: TObject);
begin
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

//Desc: ��ʾ��Ϣ
procedure TfFormMain.ShowDlgPanel(const nMsg: string; const nTag: Integer;
  const nShow: Boolean);
begin
  if nShow then
  begin
    wPage1.ActivePage := SheetBG;
    //xxxxx

    with PanelDlg do
    begin
      Left := Trunc((PanelBGDefault.Width - Width) / 2);
      Top := Trunc((PanelBGDefault.Height - Height) / 2);
      Tag := nTag;
      
      BringToFront;
      Visible := True; 
    end;

    LabelMsg.Caption := nMsg;
    ActiveControl := BtnDlgExit;
    BtnDlgExit.Invalidate;
  end else
  begin
    PanelDlg.SendToBack;
    PanelDlg.Visible := False;
  end;
end;

//Desc: �����ȡ��
procedure TfFormMain.BtnCodeExitClick(Sender: TObject);
begin
  ShowZKCodePanel(False);
  wPage1.ActivePage := SheetQuery;
end;

//Desc: �Ի���ȡ��
procedure TfFormMain.BtnDlgExitClick(Sender: TObject);
begin
  ShowDlgPanel('', 0, False);
  case PanelDlg.Tag of
   10: //���������ҵ��
    begin
      ActiveControl := EditCode;
      EditCode.SelectAll;
    end;
  end;
end;

//Desc: �����ȷ��
procedure TfFormMain.BtnCodeOKClick(Sender: TObject);
begin
  EditCode.Text := Trim(EditCode.Text);
  if EditCode.Text = '' then
  begin
    ShowDlgPanel('��������Ч���������', 10);
    Exit;
  end;

  ShowZKCodePanel(False);
  wPage1.ActivePage := SheetBill;
  FTimeCounter := 50;
  Timer1.Enabled := True;
end;

//Desc: �ƿ�����
procedure TfFormMain.BtnZKExitClick(Sender: TObject);
begin
  wPage1.ActivePage := SheetQuery;
end;

end.
