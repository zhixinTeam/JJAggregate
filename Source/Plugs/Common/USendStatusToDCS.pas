{*******************************************************************************
  作者: zyw   2019-03-19
  描述: DCS通信发送当前状态
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
    //拥有者
    FWaiter: TWaitObject;
    //等待对象
    FClient: TIdTCPClient;
    //网络对象
  protected
    procedure DoExuecte;
    procedure Execute; override;
    //执行线程
    procedure DisconnectClient;
  public
    constructor Create(AOwner: TSenderHelper);
    destructor Destroy; override;
    //创建释放
    procedure WakupMe;
    //唤醒线程
    procedure StopMe;
    //停止线程
  end;

  TSenderHelper = class(TObject)
  private
    FHost: TSenderItem;
    FSender: TSenderConnector;
    //打印对象
  public
    constructor Create;
    destructor Destroy; override;
    //创建释放
    procedure LoadConfig(const nFile: string);
    //读取配置
    procedure StartSender;
    procedure StopSender;
    //启停读取
  end;

var
  gDcsStatusSender: TSenderHelper = nil;
  //全局使用

implementation

procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(TSenderHelper, '同步DCS状态', nEvent);
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

//Desc: 载入nFile配置文件
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
        WriteLog(Format('连接DCS服务[ %s:%d ]失败.', [FHost, FPort]));
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
  //发送缓存
  gSweetHeart: Boolean = False;
  //心跳标记

//Date: 2019-03-19
//Parm: 通道列表
//Desc: 组合nTunnels数据
procedure Callback(const nTunnels: TList);
const cSize = 20;
var nStr: string;
    nFlag: Byte;
    nIdx: Integer;
    nBuf: TIdBytes;
    nVal: Integer;
    nValBuf: TIdBytes;

    procedure MakeData(const nTunnel: PBWTunnel);
    begin
      nFlag := 0;
      FillChar(nBuf[0], cSize, #0);
      
      if Assigned(nTunnel.FFixParams) and
         (nTunnel.FFixParams.Values['LineStatus'] <> '') then
           nStr := nTunnel.FFixParams.Values['LineStatus']
      else nStr := '0';

      nFlag := SetNumberBit(nFlag, 1, StrToInt(nStr), Bit_8);
      //装车位状态

      if gSweetHeart then
        nFlag := SetNumberBit(nFlag, 5, 1, Bit_8);
      //心跳
      
      if (nTunnel.FBill = '') or (nTunnel.FValue <= 0) then
      begin
        nBuf[0] := nFlag;
        Exit;
      end;

      nStr := nTunnel.FParams.Values['CanFH'];
      if nStr <> sFlag_Yes then
      begin
        nFlag := SetNumberBit(nFlag, 4, 1, Bit_8); //业务终止,关闭散装机
        nBuf[0] := nFlag;
        Exit;
      end;

      nFlag := SetNumberBit(nFlag, 2, 1, Bit_8); //可以放灰
      if nTunnel.FWeightDone then
        nFlag := SetNumberBit(nFlag, 3, 1, Bit_8);
      //装车完成

      nBuf[0] := nFlag;
      nVal := Trunc(nTunnel.FValue * 10);
      nValBuf := ToBytes(nVal);

      nBuf[4] := nValBuf[0];
      nBuf[5] := nValBuf[1];
      nBuf[6] := nValBuf[2];
      nBuf[7] := nValBuf[3]; //应装

      nVal := Trunc(nTunnel.FValTunnel * 10);
      nValBuf := ToBytes(nVal);

      nBuf[8] := nValBuf[0];
      nBuf[9] := nValBuf[1];
      nBuf[10] := nValBuf[2];
      nBuf[11] := nValBuf[3]; //已装

      nVal := Trunc(nTunnel.FValTruckP * 10);
      nValBuf := ToBytes(nVal);

      nBuf[12] := nValBuf[0];
      nBuf[13] := nValBuf[1];
      nBuf[14] := nValBuf[2];
      nBuf[15] := nValBuf[3]; //皮重
    end;
begin
  SetLength(gBuffer, 0);
  SetLength(nBuf, cSize);

  for nIdx:=nTunnels.Count - 1 downto 0 do
  begin
    MakeData(nTunnels[nIdx]);
    AppendBytes(gBuffer, nBuf);
  end;

  gSweetHeart := not gSweetHeart;
  //切换心跳
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
