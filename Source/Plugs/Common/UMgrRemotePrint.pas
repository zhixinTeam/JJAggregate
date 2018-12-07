{*******************************************************************************
  ����: dmzn@163.com 2012-4-21
  ����: Զ�̴�ӡ������

  ��ע:
  *.���ڴ�ӡ����������,�ʽ���ӡģ�鵥������.
*******************************************************************************}
unit UMgrRemotePrint;

{$I Link.Inc}
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

  PRPPrintBill = ^TRPPrintBill;
  TRPPrintBill = record
    FBase      : TRPDataBase;
    FBill      : string;
  end;

const
  cRPCmd_PrintBill  = $12;  //��ӡ��
  cSizeRPBase       = SizeOf(TRPDataBase);
  
type
  TPrinterItem = record
    FID        : string;
    FName      : string;
    FHost      : string;
    FPort      : Integer;
  end;

  TPrinterHelper = class;
  TPrinterConnector = class(TThread)
  private
    FOwner: TPrinterHelper;
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
    constructor Create(AOwner: TPrinterHelper);
    destructor Destroy; override;
    //�����ͷ�
    procedure WakupMe;
    //�����߳�
    procedure StopMe;
    //ֹͣ�߳�
  end;

  TPrinterHelper = class(TObject)
  private
    FHost: TPrinterItem;
    FPrinter: TPrinterConnector;
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
    procedure StartPrinter;
    procedure StopPrinter;
    //��ͣ��ȡ
    procedure PrintBill(const nBill: string);
    //��ӡ��
  end;

var
  gRemotePrinter: TPrinterHelper = nil;
  //ȫ��ʹ��

implementation

procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(TPrinterHelper, 'Զ�̴�ӡ����', nEvent);
end;

constructor TPrinterHelper.Create;
begin
  FBuffData := TList.Create;
  FSyncLock := TCriticalSection.Create;
end;

destructor TPrinterHelper.Destroy;
begin
  StopPrinter;
  ClearBuffer(FBuffData);
  FBuffData.Free;

  FSyncLock.Free;
  inherited;
end;

procedure TPrinterHelper.ClearBuffer(const nList: TList);
var nIdx: Integer;
    nBase: PRPDataBase;
begin
  for nIdx:=nList.Count - 1 downto 0 do
  begin
    nBase := nList[nIdx];

    case nBase.FCommand of
     cRPCmd_PrintBill : Dispose(PRPPrintBill(nBase));
    end;

    nList.Delete(nIdx);
  end;
end;

procedure TPrinterHelper.StartPrinter;
begin
  if not Assigned(FPrinter) then
    FPrinter := TPrinterConnector.Create(Self);
  FPrinter.WakupMe;
end;

procedure TPrinterHelper.StopPrinter;
begin
  if Assigned(FPrinter) then
    FPrinter.StopMe;
  FPrinter := nil;
end;

//Desc: ��nBillִ�д�ӡ����
procedure TPrinterHelper.PrintBill(const nBill: string);
var nIdx: Integer;
    nPtr: PRPPrintBill;
    nBase: PRPDataBase;
begin
  FSyncLock.Enter;
  try
    for nIdx:=FBuffData.Count - 1 downto 0 do
    begin
      nBase := FBuffData[nIdx];
      if nBase.FCommand <> cRPCmd_PrintBill then Continue;

      nPtr := PRPPrintBill(nBase);
      if CompareText(nBill, nPtr.FBill) = 0 then Exit;
    end;

    New(nPtr);
    FBuffData.Add(nPtr);

    nPtr.FBase.FCommand := cRPCmd_PrintBill;
    nPtr.FBill := nBill;

    if Assigned(FPrinter) then
      FPrinter.WakupMe;
    //xxxxx
  finally
    FSyncLock.Leave;
  end;
end;

//Desc: ����nFile�����ļ�
procedure TPrinterHelper.LoadConfig(const nFile: string);
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
constructor TPrinterConnector.Create(AOwner: TPrinterHelper);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FOwner := AOwner;
  
  FBuffer := TList.Create;
  FWaiter := TWaitObject.Create;
  FWaiter.Interval := 2000;

  FClient := TIdTCPClient.Create;
  FClient.ReadTimeout := 5 * 1000;
  FClient.ConnectTimeout := 5 * 1000;
end;

destructor TPrinterConnector.Destroy;
begin
  FClient.Disconnect;
  FClient.Free;

  FOwner.ClearBuffer(FBuffer);
  FBuffer.Free;

  FWaiter.Free;
  inherited;
end;

procedure TPrinterConnector.StopMe;
begin
  Terminate;
  FWaiter.Wakeup;

  WaitFor;
  Free;
end;

procedure TPrinterConnector.WakupMe;
begin
  FWaiter.Wakeup;
end;

procedure TPrinterConnector.Execute;
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

procedure TPrinterConnector.DoExuecte;
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
      nTmp := ToBytes(PRPPrintBill(nPBase).FBill);
      nPBase.FDataLen := Length(nTmp);

      nBuf := RawToBytes(nPBase^, cSizeRPBase);
      AppendBytes(nBuf, nTmp);
      FClient.Socket.Write(nBuf);
    end;
  end;  
end;

initialization
  gRemotePrinter := TPrinterHelper.Create;
finalization
  FreeAndNil(gRemotePrinter);
end.
