unit UMgrK720Reader;

interface

uses
  SysUtils, Classes, SyncObjs, UWaitItem, UMemDataPool, UMgrKCDF360,
  NativeXml, USysLoger;

{.$DEFINE DEBUG}  
const
  cK720ReaderData = 'K720ReaderData';

  cK720Reader_CmdRecycle = 'CP';          //���տ�Ƭ
  cK720Reader_CmdFC7     = 'FC7';         //����������λ��

  cK720Reader_CmdInterval     = 20;       //������
  cK720Reader_FreshInterval   = 200;      //ˢ��Ƶ��
type
  TK720ReaderComport = record
    FPort     : string;          //���ں�,��'COM1'
    FAddr     : Integer;         //������ַ,��Чֵ(0-15)
  end;

  TK720OutData = array [0..512] of Char;
  //��������

  TK720ReaderAction = (raQueryStatus, raRead, raRecycle, raControl);
  //֡����: ��ѯ״̬,����, ����, ����

  TK720ReaderDataOwner = (roIgnore, roCaller, roThread);
  //���ݹ���: ����,���з�,�����߳�

  PK720ReaderDataItem = ^TK720ReaderDataItem;
  TK720ReaderDataItem = record
    FEnable : Boolean;                  //�Ƿ�����
    FAction : TK720ReaderAction;        //ִ�ж���
    FOwner: TK720ReaderDataOwner;       //�ͷŷ�ʽ

    FDataStr: string;                   //�ַ�����
    FDataBool: Boolean;                 //��������

    FResultStr : string;                //�ַ�����
    FResultBool: Boolean;               //��������
    FWaiter: TWaitObject;               //�ȴ�����
  end;

  TK720ReaderManager = class;
  TK720Reader = class(TThread)
  private
    { Private declarations }
    FOwner: TK720ReaderManager;
    //ӵ����
    FWaiter: TWaitObject;
    //�ȴ�����
    FReaderHandle: Cardinal;
    //���������
  protected
    procedure Execute; override;
    procedure DoExecute;
    //ִ���߳�

    procedure ClosePort;
    procedure AddQueryFrame(const nList: TList);
    //��ѯָ��
    procedure SendDataFrame(const nItem: PK720ReaderDataItem);
    //����ָ��
  public
    constructor Create(AOwner: TK720ReaderManager);
    destructor Destroy; override;
    //�����ͷ�
    procedure WakupMe;
    //�����߳�
    procedure StopMe;
    //ֹͣ�߳�
  end;

  TOnCardEvent = procedure (const nCard: string) of object;
  TOnCardProc = procedure (const nCard: string);
  //�����¼�

  TOnStatusEvent = procedure (const nStatus: string) of object;
  TOnStatusProc = procedure (const nStatus: string);
  //������״̬

  TK720ReaderManager = class(TObject)
  private
    { Private declarations }
    FReader: TK720Reader;
    //�������߳�
    FSyncLock: TCriticalSection;
    //������
    FBuffer, FTmpList: TList;
    //ָ���
    FIDK720ReaderData: Integer;
    //�߳�����
    FPortParam: TK720ReaderComport;
    //��������

    FEvent: TOnCardEvent;
    FProc:  TOnCardProc;

    FStatusEvent: TOnStatusEvent;
    FStatusProc: TOnStatusProc;
  public
    constructor Create;
    destructor Destroy; override;
    //�����ͷ�

    procedure RegisterDataType;
    //ע����������
    function NewK720ReaderData(const nInterval: Integer): PK720ReaderDataItem;
    //�½�ָ������
    procedure DeleteK720ReaderDataItem(const nData: PK720ReaderDataItem;
              nList: TList);
    //ɾ��ָ��
    procedure ClearBuffer(const nList: TList; const nFree: Boolean=False);
    //���ָ���

    procedure LoadConfig(const nFile: string);
    //��ȡ����
    procedure StartReader;
    procedure StopReader;
    //��ͣ������
    function ReadCard(var nCard: string): Boolean;
    //��ȡ�ſ����к�
    procedure RecycleCard;
    //���տ�Ƭ
    function SendReaderCmd(const nCMD: string): Boolean;
    //���Ͷ�����ָ��

    function ParseCardNO(const nCardHex: string): string;
    //��������

    property OnEvent: TOnCardEvent read FEvent write FEvent;
    property OnProc: TOnCardProc read FProc write FProc;
    //�¼�����

    property OnStatusEvent: TOnStatusEvent read FStatusEvent write FStatusEvent;
    property OnStatusProc: TOnStatusProc read FStatusProc write FStatusProc;
    //�¼�����
  end;

var
  gMgrK720Reader: TK720ReaderManager = nil;
  //ȫ��ʹ��

implementation

//------------------------------------------------------------------------------
procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(TK720ReaderManager, '720����������', nEvent);
end;

//------------------------------------------------------------------------------
constructor TK720ReaderManager.Create;
begin
  FSyncLock := TCriticalSection.Create;
  FBuffer := TList.Create;
  FTmpList:= TList.Create;

  with FPortParam do
  begin
    FPort := 'COM1';
    FAddr := 15;
  end;

  RegisterDataType;
  //���ڴ��������  
end;

destructor TK720ReaderManager.Destroy;
begin
  StopReader;
  //ֹͣ����
  
  ClearBuffer(FBuffer, True);
  ClearBuffer(FTmpList, True);
  //xxxxxx

  FSyncLock.Free;
end;

//Desc: ����nFile�����ļ�
procedure TK720ReaderManager.LoadConfig(const nFile: string);
var nXML: TNativeXml;
    nNode: TXmlNode;
begin
  nXML := TNativeXml.Create;
  try
    nXML.LoadFromFile(nFile);
    nNode := nXML.Root.NodeByName('comport');

    with FPortParam do
    begin
      FPort     := nNode.NodeByName('port').ValueAsString;
      if FPort = '' then FPort := 'COM1';
      FAddr     := StrToIntDef(nNode.NodeByName('addr').ValueAsString, -1);
    end;
  finally
    nXML.Free;
  end;
end;

procedure TK720ReaderManager.StartReader;
begin
  if not Assigned(FReader) then
    FReader := TK720Reader.Create(Self);
  FReader.WakupMe;
end;

procedure TK720ReaderManager.StopReader;
begin
  if Assigned(FReader) then
    FReader.StopMe;
  FReader := nil;
end;

function TK720ReaderManager.ReadCard(var nCard: string): Boolean;
var nItem: PK720ReaderDataItem;
begin
  FSyncLock.Enter;
  try
    nItem := NewK720ReaderData(1*1000);
    nItem.FAction := raRead;
    FBuffer.Add(nItem);

    FReader.WakupMe;
  finally
    FSyncLock.Leave;
  end;

  nItem.FWaiter.EnterWait;
  //�ȴ�����
  Result := nItem.FResultBool;
  nCard := nItem.FResultStr;

  {$IFDEF DEBUG}
  WriteLog('ReadCard:::' + nItem.FResultStr);
  {$ENDIF}

  DeleteK720ReaderDataItem(nItem, FBuffer);
  //ɾ��ָ��
end;

procedure TK720ReaderManager.RecycleCard;
var nItem: PK720ReaderDataItem;
begin
  FSyncLock.Enter;
  try
    nItem := NewK720ReaderData(500);
    nItem.FAction := raRecycle;
    FBuffer.Add(nItem);

    FReader.WakupMe;
  finally
    FSyncLock.Leave;
  end;

  nItem.FWaiter.EnterWait;
  //�ȴ�ָ�����

  {$IFDEF DEBUG}
  WriteLog('RecycleCard:::' + nItem.FResultStr);
  {$ENDIF}

  DeleteK720ReaderDataItem(nItem, FBuffer);
  //ɾ��ָ��
end;

function TK720ReaderManager.SendReaderCmd(const nCMD: string): Boolean;
var nItem: PK720ReaderDataItem;
begin
  FSyncLock.Enter;
  try
    nItem := NewK720ReaderData(10 * 100);
    nItem.FAction := raControl;
    nItem.FDataStr:= nCMD;
    FBuffer.Add(nItem);

    FReader.WakupMe;
  finally
    FSyncLock.Leave;
  end;

  nItem.FWaiter.EnterWait;
  //�ȴ�ָ�����
  Result := nItem.FResultBool;

  {$IFDEF DEBUG}
  WriteLog('SendReaderCmd:::' + nItem.FResultStr);
  {$ENDIF}

  DeleteK720ReaderDataItem(nItem, FBuffer);
  //ɾ��ָ��
end;

function TK720ReaderManager.ParseCardNO(const nCardHex: string): string;
var nIdx:Integer;
    nInt: Int64;
    nHexTmp: string;
begin
  Result := '';
  if Length(nCardHex) < 4 then Exit;
  //xxxxx

  nHexTmp := Copy(nCardHex, 1, 4);
  //����4λ
  for nIdx := Length(nHexTmp) downto 1 do
    Result := Result + IntToHex(Ord(nHexTmp[nIdx]), 2);

  nInt := StrToInt64('$' + Result);
  Result := IntToStr(nInt);
  Result := StringOfChar('0', 12 - Length(Result)) + Result;
end;

procedure TK720ReaderManager.ClearBuffer(const nList: TList; const nFree: Boolean);
var nIdx: Integer;
begin
  for nIdx := nList.Count - 1 downto 0 do
    DeleteK720ReaderDataItem(nList[nIdx], nList);

  if nFree then
    nList.Free;
end;

procedure OnNew(const nFlag: string; const nType: Word; var nData: Pointer);
var nItem: PK720ReaderDataItem;
begin
  if nFlag = cK720ReaderData then
  begin
    New(nItem);
    nData := nItem;
    nItem.FWaiter := nil;
  end;
end;

procedure OnFree(const nFlag: string; const nType: Word; const nData: Pointer);
var nItem: PK720ReaderDataItem;
begin
  if nFlag = cK720ReaderData then
  begin
    nItem := nData;
    if Assigned(nItem.FWaiter) then
      FreeAndNil(nItem.FWaiter);
    Dispose(nItem);
  end;
end;

procedure TK720ReaderManager.RegisterDataType;
begin
  if not Assigned(gMemDataManager) then
    gMemDataManager := TMemDataManager.Create;
  //xxxxx

  with gMemDataManager do
    FIDK720ReaderData := RegDataType(cK720ReaderData, 'K720ReaderManager',
                         OnNew, OnFree, 2);
  //xxxxx
end;

//Date: 2016-09-13
//Parm: �ȴ�������
//Desc: �½�����������
function TK720ReaderManager.NewK720ReaderData(
  const nInterval: Integer): PK720ReaderDataItem;
begin
  Result := gMemDataManager.LockData(FIDK720ReaderData);
  with Result^ do
  begin
    FEnable := True;
    FAction := raQueryStatus;
    FOwner := roCaller;

    FDataStr := '';
    FDataBool := False;

    FResultStr  := '';
    FResultBool := False;

    if nInterval > 0 then
    begin
      if not Assigned(FWaiter) then
        FWaiter := TWaitObject.Create;
      FWaiter.Interval := nInterval;
    end;
  end;
end;

procedure TK720ReaderManager.DeleteK720ReaderDataItem(
  const nData: PK720ReaderDataItem; nList: TList);
var nIdx: Integer;
begin
  FSyncLock.Enter;
  try
    gMemDataManager.UnLockData(nData);
    nIdx := nList.IndexOf(nData);
    if Assigned(nData.FWaiter) then
    begin
      nData.FWaiter.Free;
      nData.FWaiter := nil;
    end;

    if nIdx >= 0 then
      nList.Delete(nIdx);
    //xxxxx
  finally
    FSyncLock.Leave;
  end;
end;

//------------------------------------------------------------------------------
constructor TK720Reader.Create(AOwner: TK720ReaderManager);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FOwner := AOwner;

  FWaiter := TWaitObject.Create;
  FWaiter.Interval := 1000;

  FReaderHandle := 0;
end;

destructor TK720Reader.Destroy;
begin
  ClosePort;
  FWaiter.Free;
  inherited;
end;

procedure TK720Reader.StopMe;
begin
  Terminate;
  FWaiter.Wakeup;

  WaitFor;
  Free;
end;

procedure TK720Reader.WakupMe;
begin
  FWaiter.Wakeup;
end;

procedure TK720Reader.ClosePort;
begin
  if FReaderHandle > 0 then
    K720_CommClose(FReaderHandle);

  FReaderHandle := 0;
end;  

procedure TK720Reader.Execute;
begin
  { Place thread code here }
  while not Terminated do
  try
    FWaiter.EnterWait;
    if Terminated then Exit;

    DoExecute;
  except
    on E: Exception do
    begin
      WriteLog(E.Message);
      ClosePort;
    end;  
  end;  
end;

procedure TK720Reader.DoExecute;
var nIdx: Integer;
begin
  with FOwner do
  begin
    if FReaderHandle <= 0 then
      FReaderHandle := K720_CommOpen(FPortParam.FPort);

    FSyncLock.Enter;
    try
      for nIdx := FBuffer.Count - 1 downto 0 do
        FTmpList.Add(FBuffer[nIdx]);
    finally
      FSyncLock.Leave;
    end;

    if FTmpList.Count < 1 then
      AddQueryFrame(FTmpList);
    //��Ӳ�ѯ֡

    try
      for nIdx:=0 to FTmpList.Count - 1 do
      begin
        SendDataFrame(FTmpList[nIdx]);
        //��������֡

        if nIdx < FTmpList.Count - 1 then
          Sleep(cK720Reader_FreshInterval);
        //��֡����ʱ����ʱ
      end;

      ClearBuffer(FTmpList);
    except
      ClearBuffer(FTmpList);
      raise;
    end;
  end;  
end;

//Desc: ��nList����Ӳ�ѯ֡
procedure TK720Reader.AddQueryFrame(const nList: TList);
var nItem: PK720ReaderDataItem;
begin
  nItem := FOwner.NewK720ReaderData(0); //10s
  nList.Add(nItem);
  nItem.FAction := raQueryStatus;
  nItem.FOwner  := roThread;
end;

//Desc: ��������
procedure TK720Reader.SendDataFrame(const nItem: PK720ReaderDataItem);
var nOut, nRecord: TK720OutData;
    nRet, nIdx: Integer;
begin
  if not nItem.FEnable then Exit;
  nItem.FEnable := False;

  if FReaderHandle <= 0 then Exit;
  //�޲������

  case nItem.FAction of
  raQueryStatus :
  begin
    if FOwner.FPortParam.FAddr < 0 then
    for nIdx := 0 to 15 do
    begin
      nRet := K720_SensorQuery(FReaderHandle, nIdx, nOut, nRecord);

      if nRet <> 0 then Continue;

      FOwner.FPortParam.FAddr := nIdx;
      Break;
    end else nRet := K720_SensorQuery(FReaderHandle, FOwner.FPortParam.FAddr,
                     nOut, nRecord);
    //��ȡ״̬

    {$IFDEF DEBUG}
    WriteLog('��ǰ״̬:' + StrPas(nOut));
    WriteLog('ͨѶ��¼:' + StrPas(nRecord));
    {$ENDIF}

    nItem.FResultStr := StrPas(nOut);
    nItem.FResultBool := nRet = 0;
    if not nItem.FResultBool then FOwner.FPortParam.FAddr := -1;

    if Assigned(nItem.FWaiter) then
      nItem.FWaiter.Wakeup();
    //xxxxx

    if Assigned(FOwner.FStatusEvent) then
      FOwner.FStatusEvent(StrPas(nOut));

    if Assigned(FOwner.FStatusProc) then
      FOwner.FStatusProc(StrPas(nOut));
  end;
  raRead :
  begin
    K720_SendCmd(FReaderHandle, FOwner.FPortParam.FAddr,
      cK720Reader_CmdFC7, Length(cK720Reader_CmdFC7), nRecord);
    //����������λ��

    {$IFDEF DEBUG}
    WriteLog('����������λ��:' + StrPas(nRecord));
    {$ENDIF}

    nRet := K720_S50GetCardID(FReaderHandle, FOwner.FPortParam.FAddr,
            nOut, nRecord);
    //��ȡID��

    {$IFDEF DEBUG}
    WriteLog('50CardID:' + StrPas(nOut));
    WriteLog('ͨѶ��¼:' + StrPas(nRecord));
    {$ENDIF}

    nItem.FResultStr := StrPas(nOut);
    nItem.FResultBool := nRet = 0;

    if Assigned(nItem.FWaiter) then
      nItem.FWaiter.Wakeup();
    //xxxxx

    if Assigned(FOwner.FEvent) then
      FOwner.FEvent(StrPas(nOut));

    if Assigned(FOwner.FProc) then
      FOwner.FProc(StrPas(nOut));
  end;
  raRecycle :
  begin
    nRet := K720_SendCmd(FReaderHandle, FOwner.FPortParam.FAddr,
            cK720Reader_CmdRecycle, Length(cK720Reader_CmdRecycle), nRecord);
    //���տ�Ƭ

    {$IFDEF DEBUG}
    WriteLog('ͨѶ��¼:' + StrPas(nRecord));
    {$ENDIF}

    nItem.FResultStr := '';
    nItem.FResultBool := nRet = 0;

    if Assigned(nItem.FWaiter) then
      nItem.FWaiter.Wakeup();
    //xxxxx
  end;
  raControl :
  begin
    nRet := K720_SendCmd(FReaderHandle, FOwner.FPortParam.FAddr,
            nItem.FDataStr, Length(nItem.FDataStr), nRecord);
    //����ָ��

    {$IFDEF DEBUG}
    WriteLog('ͨѶ��¼:' + StrPas(nRecord));
    {$ENDIF}

    nItem.FResultStr := '';
    nItem.FResultBool := nRet = 0;

    if Assigned(nItem.FWaiter) then
      nItem.FWaiter.Wakeup();
    //xxxxx
  end;       
  end;   
end;

initialization
  gMgrK720Reader := nil;
finalization
  FreeAndNil(gMgrK720Reader);
end.
