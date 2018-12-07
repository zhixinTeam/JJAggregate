{*******************************************************************************
  ����: fendou116688@163.com 2014/12/1
  ����: ΢�Ź���ƽ̨ģ����Ϣ����
*******************************************************************************}
unit UMgrRemoteWXMsg;

{$I Link.Inc}
interface

uses
  Windows, Classes, SysUtils, SyncObjs, NativeXml, IdComponent, IdTCPConnection,
  IdTCPClient, IdUDPServer, IdGlobal, IdSocketHandle, USysLoger, UWaitItem,
  ULibFun, UBase64;

type
  PWXDataBase = ^TWXDataBase;
  TWXDataBase = record
    FCommand   : Byte;     //������
    FDataLen   : Word;     //���ݳ�
  end;

  PWXTemplateMsg = ^TWXTemplateMsg;
  TWXTemplateMsg = record
    FBase      : TWXDataBase;
    FData      : string;
  end;

const
  cWXCmd_SendMsg  = $12;  //
  cWXBus_OutFact  = 'OUTFACT';
  cWXBus_MakeCard = 'MAKECARD';
  cSizeWXDataBase = SizeOf(TWXDataBase);
  
type
  TWXPlatFormItem = record
    FID        : string;
    FName      : string;
    FHost      : string;
    FPort      : Integer;
    FEnable    : Boolean;
  end;

  TWXPlatFormHelper = class;
  TTWXPlatFormConnector = class(TThread)
  private
    FOwner: TWXPlatFormHelper;
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
    constructor Create(AOwner: TWXPlatFormHelper);
    destructor Destroy; override;
    //�����ͷ�
    procedure WakupMe;
    //�����߳�
    procedure StopMe;
    //ֹͣ�߳�
  end;

  TWXPlatFormHelper = class(TObject)
  private
    FHost: TWXPlatFormItem;
    FPlatConnector: TTWXPlatFormConnector;
    //����ģ�����ݶ���
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
    procedure StartPlatConnector;
    procedure StopPlatConnector;
    //��ͣ��ȡ
    procedure WXSendMsg(const nData: string); overload;
    //��������
    procedure WXSendMsg(const nBusType, nBusData: string); overload;
  end;

var
  gWXPlatFormHelper: TWXPlatFormHelper = nil;
  //ȫ��ʹ��

implementation

procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(TWXPlatFormHelper, '΢��ģ����Ϣ����', nEvent);
end;

constructor TWXPlatFormHelper.Create;
begin
  FBuffData := TList.Create;
  FSyncLock := TCriticalSection.Create;
end;

destructor TWXPlatFormHelper.Destroy;
begin
  StopPlatConnector;
  ClearBuffer(FBuffData);
  FBuffData.Free;

  FSyncLock.Free;
  inherited;
end;

procedure TWXPlatFormHelper.ClearBuffer(const nList: TList);
var nIdx: Integer;
    nBase: PWXDataBase;
begin
  for nIdx:=nList.Count - 1 downto 0 do
  begin
    nBase := nList[nIdx];

    case nBase.FCommand of
     cWXCmd_SendMsg : Dispose(PWXTemplateMsg(nBase));
    end;

    nList.Delete(nIdx);
  end;
end;

procedure TWXPlatFormHelper.StartPlatConnector;
begin
  if not Assigned(FPlatConnector) then
    FPlatConnector := TTWXPlatFormConnector.Create(Self);
  if FHost.FEnable then FPlatConnector.WakupMe;
end;

procedure TWXPlatFormHelper.StopPlatConnector;
begin
  if Assigned(FPlatConnector) then
    FPlatConnector.StopMe;
  FPlatConnector := nil;
end;

//Date: 2014/12/1
//Parm:
//Desc:
procedure TWXPlatFormHelper.WXSendMsg(const nData: string);
var nIdx: Integer;
    nPtr: PWXTemplateMsg;
    nBase: PWXDataBase;
begin
  FSyncLock.Enter;
  try
    for nIdx:=FBuffData.Count - 1 downto 0 do
    begin
      nBase := FBuffData[nIdx];
      if nBase.FCommand <> cWXCmd_SendMsg then Continue;

      nPtr := PWXTemplateMsg(nBase);
      if CompareText(nData, nPtr.FData) = 0 then Exit;
    end;

    New(nPtr);
    FBuffData.Add(nPtr);

    nPtr.FBase.FCommand := cWXCmd_SendMsg;
    nPtr.FData := EncodeBase64(nData);

    if Assigned(FPlatConnector) and FHost.FEnable then
      FPlatConnector.WakupMe;
    //xxxxx
  finally
    FSyncLock.Leave;
  end;
end;

//Date: 2014/12/1
//Parm: ҵ������;ҵ������
//Desc: ����ģ����Ϣ
procedure TWXPlatFormHelper.WXSendMsg(const nBusType, nBusData: string);
var nIdx: Integer;
    nPtr: PWXTemplateMsg;
    nData: string;nBase: PWXDataBase;
begin
  FSyncLock.Enter;
  try
    nData := nBusType + '#' + nBusData;
    for nIdx:=FBuffData.Count - 1 downto 0 do
    begin
      nBase := FBuffData[nIdx];
      if nBase.FCommand <> cWXCmd_SendMsg then Continue;

      nPtr := PWXTemplateMsg(nBase);
      if CompareText(nData, nPtr.FData) = 0 then Exit;
    end;

    New(nPtr);
    FBuffData.Add(nPtr);

    nPtr.FBase.FCommand := cWXCmd_SendMsg;
    nPtr.FData := EncodeBase64(nData);

    if Assigned(FPlatConnector) and FHost.FEnable  then
      FPlatConnector.WakupMe;
    //xxxxx
  finally
    FSyncLock.Leave;
  end;
end;

//Desc: ����nFile�����ļ�
procedure TWXPlatFormHelper.LoadConfig(const nFile: string);
var nXML: TNativeXml;
    nNode, nTmp: TXmlNode;
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

      nTmp := nNode.FindNode('enable');
      if Assigned(nTmp) then
            FEnable := nTmp.ValueAsString <> '0'
      else  FEnable := False;
    end;
  finally
    nXML.Free;
  end;
end;

//------------------------------------------------------------------------------
constructor TTWXPlatFormConnector.Create(AOwner: TWXPlatFormHelper);
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

destructor TTWXPlatFormConnector.Destroy;
begin
  FClient.Disconnect;
  FClient.Free;

  FOwner.ClearBuffer(FBuffer);
  FBuffer.Free;

  FWaiter.Free;
  inherited;
end;

procedure TTWXPlatFormConnector.StopMe;
begin
  Terminate;
  FWaiter.Wakeup;

  WaitFor;
  Free;
end;

procedure TTWXPlatFormConnector.WakupMe;
begin
  FWaiter.Wakeup;
end;

procedure TTWXPlatFormConnector.Execute;
var nIdx: Integer;
begin
  while not Terminated do
  try
    FWaiter.EnterWait;
    if Terminated or (not FOwner.FHost.FEnable) then Exit;

    try
      if not FClient.Connected then
      begin
        FClient.Host := FOwner.FHost.FHost;
        FClient.Port := FOwner.FHost.FPort;
        FClient.Connect;
      end;
    except
      WriteLog('����΢��ģ����Ϣ���ͷ���ʧ��.');
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

procedure TTWXPlatFormConnector.DoExuecte;
var nIdx: Integer;
    nBuf,nTmp: TIdBytes;
    nPBase: PWXDataBase;
begin
  for nIdx:=FBuffer.Count - 1 downto 0 do
  begin
    nPBase := FBuffer[nIdx];

    if nPBase.FCommand = cWXCmd_SendMsg then
    begin
      SetLength(nTmp, 0);
      nTmp := ToBytes(PWXTemplateMsg(nPBase).FData);
      nPBase.FDataLen := Length(nTmp);

      nBuf := RawToBytes(nPBase^, cSizeWXDataBase);
      AppendBytes(nBuf, nTmp);
      FClient.Socket.Write(nBuf);
    end;
  end;  
end;

initialization
  gWXPlatFormHelper := TWXPlatFormHelper.Create;
finalization
  FreeAndNil(gWXPlatFormHelper);
end.

 