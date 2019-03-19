{*******************************************************************************
  ����: zyw   2019-03-19
  ����: DCSͨ�ŷ��͵�ǰ״̬
*******************************************************************************}
unit USendStatusToDCS;

interface

uses
  Windows, Classes, SysUtils, SyncObjs, NativeXml, IdComponent, IdTCPConnection,
  IdTCPClient, IdUDPServer, IdGlobal, IdSocketHandle, USysLoger, UWaitItem,
  ULibFun;

type
  PRPDataBase = ^TRPDataBase;
  TRPDataBase = record
    FCommand   : Byte;     //������
    FDataLen   : Word;     //���ݳ�
  end;

  PStatusData = ^TStatusData;
  TStatusData = record
    FBase      : TRPDataBase;
    FData      : TIdBytes;
  end;

const
  cRPCmd_PrintBill  = $95;  //��ӡ��
  cSizeRPBase       = SizeOf(TRPDataBase);
  
type
  TSenderItem = record
    FID        : string;
    FName      : string;
    FHost      : string;
    FPort      : Integer;
  end;

  TSenderHelper = class;
  TSenderConnector = class(TThread)
  private
    FOwner: TSenderHelper;
    //ӵ����
    FBuffer: TList;
    //���ͻ���
    FWaiter: TWaitObject;
    //�ȴ�����
    FClient: TIdTCPClient;
    //�������
  protected
    procedure DoExuecte;
    procedure Execute; override;
    //ִ���߳�
  public
    constructor Create(AOwner: TSenderHelper);
    destructor Destroy; override;
    //�����ͷ�
    procedure WakupMe;
    //�����߳�
    procedure StopMe;
    //ֹͣ�߳�
  end;

  TSenderHelper = class(TObject)
  private
    FHost: TSenderItem;
    FPrinter: TSenderConnector;
    //��ӡ����
    FBuffData: TList;
    //��ʱ����
    FSyncLock: TCriticalSection;
    //ͬ����
  protected
    procedure ClearBuffer(const nList: TList);
    //������
  public
    constructor Create;
    destructor Destroy; override;
    //�����ͷ�
    procedure LoadConfig(const nFile: string);
    //��ȡ����
    procedure StartSender;
    procedure StopSender;
    //��ͣ��ȡ
    procedure SendData(const nStatusData: TIdBytes);
    //��ӡ��
  end;

var
  gDcsStatusSender: TSenderHelper = nil;
  //ȫ��ʹ��

implementation

procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(TSenderHelper, 'Զ�̴�ӡ����', nEvent);
end;

constructor TSenderHelper.Create;
begin
  FBuffData := TList.Create;
  FSyncLock := TCriticalSection.Create;
end;

destructor TSenderHelper.Destroy;
begin
  StopSender;
  ClearBuffer(FBuffData);
  FBuffData.Free;

  FSyncLock.Free;
  inherited;
end;

procedure TSenderHelper.ClearBuffer(const nList: TList);
var nIdx: Integer;
    nBase: PRPDataBase;
begin
  for nIdx:=nList.Count - 1 downto 0 do
  begin
    nBase := nList[nIdx];

    case nBase.FCommand of
     cRPCmd_PrintBill : Dispose(PStatusData(nBase));
    end;

    nList.Delete(nIdx);
  end;
end;

procedure TSenderHelper.StartSender;
begin
  if not Assigned(FPrinter) then
    FPrinter := TSenderConnector.Create(Self);
  FPrinter.WakupMe;
end;

procedure TSenderHelper.StopSender;
begin
  if Assigned(FPrinter) then
    FPrinter.StopMe;
  FPrinter := nil;
end;

//Desc: ��nBillִ�д�ӡ����
procedure TSenderHelper.SendData(const nStatusData: TIdBytes);
var nIdx: Integer;
    nPtr: PStatusData;
    nBase: PRPDataBase;
begin
  FSyncLock.Enter;
  try
    for nIdx:=FBuffData.Count - 1 downto 0 do
    begin
      nBase := FBuffData[nIdx];
      if nBase.FCommand <> cRPCmd_PrintBill then Continue;

      nPtr := PStatusData(nBase);
      //if CompareText(nStatusData, nPtr.FData) = 0 then Exit;
    end;

    New(nPtr);
    FBuffData.Add(nPtr);

    nPtr.FBase.FCommand := cRPCmd_PrintBill;
    nPtr.FData := nStatusData;

    if Assigned(FPrinter) then
      FPrinter.WakupMe;
    //xxxxx
  finally
    FSyncLock.Leave;
  end;
end;

//Desc: ����nFile�����ļ�
procedure TSenderHelper.LoadConfig(const nFile: string);
var nXML: TNativeXml;
    nNode: TXmlNode;
begin
  nXML := TNativeXml.Create;
  try
    nXML.LoadFromFile(nFile);
    nNode := nXML.Root.NodeByName('item');

    with FHost do
    begin
      FID    := nNode.NodeByName('id').ValueAsString;
      FName  := nNode.NodeByName('name').ValueAsString;
      FHost  := nNode.NodeByName('ip').ValueAsString;
      FPort  := nNode.NodeByName('port').ValueAsInteger;
    end;
  finally
    nXML.Free;
  end;
end;

//------------------------------------------------------------------------------
constructor TSenderConnector.Create(AOwner: TSenderHelper);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FOwner := AOwner;
  
  FBuffer := TList.Create;
  FWaiter := TWaitObject.Create;
  FWaiter.Interval := 1000;

  FClient := TIdTCPClient.Create;
  FClient.ReadTimeout := 5 * 1000;
  FClient.ConnectTimeout := 5 * 1000;
end;

destructor TSenderConnector.Destroy;
begin
  FClient.Disconnect;
  FClient.Free;

  FOwner.ClearBuffer(FBuffer);
  FBuffer.Free;

  FWaiter.Free;
  inherited;
end;

procedure TSenderConnector.StopMe;
begin
  Terminate;
  FWaiter.Wakeup;

  WaitFor;
  Free;
end;

procedure TSenderConnector.WakupMe;
begin
  FWaiter.Wakeup;
end;

procedure TSenderConnector.Execute;
var nIdx: Integer;
begin
  while not Terminated do
  try
    FWaiter.EnterWait;
    if Terminated then Exit;

    try
      if not FClient.Connected then
      begin
        FClient.Host := FOwner.FHost.FHost;
        FClient.Port := FOwner.FHost.FPort;
        FClient.Connect;
      end;
    except
      WriteLog('����Զ�̴�ӡ����ʧ��.');
      FClient.Disconnect;
      Continue;
    end;

    FOwner.FSyncLock.Enter;
    try
      for nIdx:=0 to FOwner.FBuffData.Count - 1 do
        FBuffer.Add(FOwner.FBuffData[nIdx]);
      FOwner.FBuffData.Clear;
    finally
      FOwner.FSyncLock.Leave;
    end;

    try
      DoExuecte;
      FOwner.ClearBuffer(FBuffer);
    except
      FOwner.ClearBuffer(FBuffer);
      FClient.Disconnect;
      
      if Assigned(FClient.IOHandler) then
        FClient.IOHandler.InputBuffer.Clear;
      raise;
    end;
  except
    on E:Exception do
    begin
      WriteLog(E.Message);
    end;
  end;
end;

procedure TSenderConnector.DoExuecte;
var nIdx: Integer;
    nBuf,nTmp: TIdBytes;
    nPBase: PRPDataBase;
begin
  for nIdx:=FBuffer.Count - 1 downto 0 do
  begin
    nPBase := FBuffer[nIdx];

    if nPBase.FCommand = cRPCmd_PrintBill then
    begin
      SetLength(nTmp, 0);
      nTmp := PStatusData(nPBase).FData;
      nPBase.FDataLen := Length(nTmp);

      nBuf := RawToBytes(nPBase^, cSizeRPBase);
      AppendBytes(nBuf, nTmp);
      FClient.Socket.Write(nBuf);
    end;
  end;  
end;

initialization
  gDcsStatusSender := TSenderHelper.Create;
finalization
  FreeAndNil(gDcsStatusSender);
end.
