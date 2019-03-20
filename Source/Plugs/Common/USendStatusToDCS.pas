{*******************************************************************************
  ����: zyw   2019-03-19
  ����: DCSͨ�ŷ��͵�ǰ״̬
*******************************************************************************}
unit USendStatusToDCS;

interface

uses
  Windows, Classes, SysUtils, SyncObjs, NativeXml, IdComponent, IdTCPConnection,
  IdTCPClient, IdGlobal, IdSocketHandle, UMgrBasisWeight, UWaitItem,
  ULibFun, USysLoger, USysDB;

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
    FWaiter: TWaitObject;
    //�ȴ�����
    FClient: TIdTCPClient;
    //�������
  protected
    procedure DoExuecte;
    procedure Execute; override;
    //ִ���߳�
    procedure DisconnectClient;
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
    FSender: TSenderConnector;
    //��ӡ����
  public
    constructor Create;
    destructor Destroy; override;
    //�����ͷ�
    procedure LoadConfig(const nFile: string);
    //��ȡ����
    procedure StartSender;
    procedure StopSender;
    //��ͣ��ȡ
  end;

var
  gDcsStatusSender: TSenderHelper = nil;
  //ȫ��ʹ��

implementation

procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(TSenderHelper, 'ͬ��DCS״̬', nEvent);
end;

constructor TSenderHelper.Create;
begin
  FSender := nil;
end;

destructor TSenderHelper.Destroy;
begin
  StopSender;
  inherited;
end;

procedure TSenderHelper.StartSender;
begin
  if not Assigned(FSender) then
    FSender := TSenderConnector.Create(Self);
  FSender.WakupMe;
end;

procedure TSenderHelper.StopSender;
begin
  if Assigned(FSender) then
    FSender.StopMe;
  FSender := nil;
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

  FWaiter := TWaitObject.Create;
  FWaiter.Interval := 1000;

  FClient := TIdTCPClient.Create;
  FClient.ReadTimeout := 3 * 1000;
  FClient.ConnectTimeout := 3 * 1000;
end;

destructor TSenderConnector.Destroy;
begin
  DisconnectClient;
  FClient.Free;
  
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

procedure TSenderConnector.DisconnectClient;
begin
  FClient.Disconnect;
  if Assigned(FClient.IOHandler) then
    FClient.IOHandler.InputBuffer.Clear;
  //xxxxx
end;

procedure TSenderConnector.Execute;
begin
  while not Terminated do
  try
    FWaiter.EnterWait;
    if Terminated then Exit;

    if not FClient.Connected then
    try
      FClient.Host := FOwner.FHost.FHost;
      FClient.Port := FOwner.FHost.FPort;
      FClient.Connect;
    except
      with FOwner.FHost do
        WriteLog(Format('����DCS����[ %s:%d ]ʧ��.', [FHost, FPort]));
      //xxxxx
      
      DisconnectClient();
      raise;
    end;

    try
      DoExuecte;
    except
      DisconnectClient();
      raise;
    end;
  except
    on E:Exception do
    begin
      WriteLog(E.Message);
    end;
  end;
end;

var
  gBuffer: TIdBytes;
  //���ͻ���
  gSweetHeart: Boolean = False;
  //�������

//Date: 2019-03-19
//Parm: ͨ���б�
//Desc: ���nTunnels����
procedure Callback(const nTunnels: TList);
const cSize = 20;
var nStr: string;
    nFlag: Byte;
    nIdx: Integer;
    nBuf: TIdBytes;

    procedure MakeData(const nTunnel: PBWTunnel);
    begin
      nFlag := 0;
      FillChar(nBuf, cSize, #0);
      
      if Assigned(nTunnel.FFixParams) and
         (nTunnel.FFixParams.Values['LineStatus'] <> '') then
           nStr := nTunnel.FFixParams.Values['LineStatus']
      else nStr := '0';

      nFlag := SetNumberBit(nFlag, 1, StrToInt(nStr), Bit_8); //װ��λ״̬
      if (nTunnel.FBill = '') or (nTunnel.FValue <= 0) then
      begin
        nBuf[0] := nFlag;
        Exit;
      end;

      nStr := nTunnel.FParams.Values['CanFH'];
      if nStr <> sFlag_Yes then
      begin
        nFlag := SetNumberBit(nFlag, 4, 1, Bit_8); //ҵ����ֹ,�ر�ɢװ��
        nBuf[0] := nFlag;
        Exit;
      end;

      nFlag := SetNumberBit(nFlag, 2, 1, Bit_8); //���ԷŻ�
      if nTunnel.FWeightDone then
        nFlag := SetNumberBit(nFlag, 3, 1, Bit_8);
      //װ�����

      if gSweetHeart then
        nFlag := SetNumberBit(nFlag, 5, 1, Bit_8); //����
      gSweetHeart := not gSweetHeart;

      nBuf[0] := nFlag;
      nStr := IntToStr(Trunc(nTunnel.FValue * 10));
      nStr := StrWithWidth(nStr, 4, 2, '0', True);

      nBuf[4] := StrToInt(nStr[1]);
      nBuf[5] := StrToInt(nStr[2]);
      nBuf[6] := StrToInt(nStr[3]);
      nBuf[7] := StrToInt(nStr[4]); //Ӧװ

      nStr := IntToStr(Trunc(nTunnel.FValTunnel * 10));
      nStr := StrWithWidth(nStr, 4, 2, '0', True);

      nBuf[8] := StrToInt(nStr[1]);
      nBuf[9] := StrToInt(nStr[2]);
      nBuf[10] := StrToInt(nStr[3]);
      nBuf[11] := StrToInt(nStr[4]); //��װ

      nStr := IntToStr(Trunc(nTunnel.FValTruckP * 10));
      nStr := StrWithWidth(nStr, 4, 2, '0', True);

      nBuf[12] := StrToInt(nStr[1]);
      nBuf[13] := StrToInt(nStr[2]);
      nBuf[14] := StrToInt(nStr[3]);
      nBuf[15] := StrToInt(nStr[4]); //Ƥ��
    end;
begin
  SetLength(gBuffer, 0);
  SetLength(nBuf, cSize);

  for nIdx:=0 to nTunnels.Count - 1 do
  begin
    MakeData(nTunnels[nIdx]);
    AppendBytes(gBuffer, nBuf);
  end;
end;

procedure TSenderConnector.DoExuecte;
begin
  gBasisWeightManager.EnumTunnels(Callback);
  FClient.Socket.Write(gBuffer);
end;

initialization
  gDcsStatusSender := nil;
finalization
  FreeAndNil(gDcsStatusSender);
end.
