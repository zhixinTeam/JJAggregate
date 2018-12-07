{*******************************************************************************
  作者: fendou116688@163.com 2016/4/21
  描述: 蓝卡读卡器控制单元
*******************************************************************************}
unit UBlueReader;

interface

uses
  Windows, Classes, SysUtils, SyncObjs, NativeXml, Controls, WinSock,
  UWaitItem, UMemDataPool, USysLoger, ULibFun,
  IdTCPConnection, IdTCPClient, IdTCPServer,
  IdGlobal, IdSocketHandle, IdContext, IdUDPClient;
  
const
  cBlueReader_NullASCII     = $30;                          //ASCII空字节
  cBlueReader_Flag_End      = #13#10;                       //指令结束标识


  cBlueReader_Flag_Bumac    = 'BUMAC=';                     //读卡器编号标识
  cBlueReader_Flag_ReaderID = 'READERID';                   //读卡器编号标识
  cBlueReader_Flag_FIRMWARE = 'FIRMWARE';                   //读卡器固件版本号

  cBlueReader_Flag_CardNO   = 'PARKMODE CARDNO ';           //实时卡片编号
  cBlueReader_Flag_Record   = 'PARKMODE RECORD ';           //实时卡片编号

  cBlueReader_BUMAC         = 'BUMAC';                      //读卡器ID指令
  cBlueReader_WatchDog      = 'watchdog';                   //读卡器心跳指令
  cBlueReader_OpenDoor      = 'WRITEGPIO 01';               //读卡器抬杆指令
  cBlueReader_BroastServer  = 'SERVERIP $ServIP $ServPort'; //广播服务器地址

  cBlueReader_Query_Interval= 3*100;                          //指令间隔
  cBlueReader_Recv_Length   = 200;                             //接收缓冲区长度

  sBlueReaderConfig = 'BlueCardReader.XML';
type
  PBlueReaderItem = ^TBlueReaderItem;
  TBlueReaderItem = record
    FID      :string;
    FEnable  :Boolean;

    FHostIP  :string;
    FHostPort:Integer;
  end;

  TBlueReaderItems = array of TBlueReaderItem;
  //array of Config host

  TBlueReaderHost = record
    FReaderID :string;                          //读卡器编号
    FRecvData :string;                          //接收区缓冲

    FContext  :TIdContext;                      //读卡器链路
    FPeerIP   : string;                         //读卡器IP
  end;
  //online host

  PBlueReaderHost = ^TBlueReaderHost;
  //Point of host

  TBlueReaderHosts = array of TBlueReaderHost;
  //array of host

  PBlueReaderCard = ^TBlueReaderCard;
  TBlueReaderCard = record
    FHost   : PBlueReaderHost;   //读头
    FCard   : string;            //卡号
    FOldOne : Boolean;           //超时卡

    FEvent  : Boolean;           //已触发
    FLast   : Int64;             //上次触发
    FInTime : Int64;             //首次时间
  end;

  TOnCard = procedure (nHost: TBlueReaderHost; nCard: TBlueReaderCard);
  //卡片事件

  TBlueReader = class(TThread)
  private
    FItems: TBlueReaderItems;
    //配置读头列表
    FActiveReaders: TList;
    //活动读头列表
    FDataBuffer: TStrings;
    //抬杆指令集
    FCards: TList;
    //收到卡列表
    FCardInfo: TStrings;
    //收到单次卡号信息
    FKeepTime: Integer;
    //超时等待
    FSrvIPList: TStrings;
    //服务器IP地址表
    FSrvPort: Integer;
    FServer: TIdTCPServer;
    //服务端
    FUDPClient: TIdUDPClient;
    //广播服务器IP地址(定期广播)
    FWaiter: TWaitObject;
    //等待对象
    FSyncLock: TCriticalSection;
    //同步锁
    FEnable: Boolean;
    //是否启用
    FCardArrived: TOnCard;
    //事件
  protected
    procedure Execute; override;
    //执行线程

    procedure TCPServerConnect(AContext: TIdContext);
    //客户端连接
    procedure TCPServerDisconnect(AContext: TIdContext);
    //客户端断开
    procedure TCPServerExecute(AContext: TIdContext);
    //服务器执行线程
    procedure DoReadEvent(const nContext: TIdContext; const nBuff: string='');
    //处理读到的内容

    function GetReaderID(const nContext: TIdContext): String;
    //获取读卡器编号
    function GetReaderContext(const nReaderID: string): TIdContext;
    //获取读卡器链路
    procedure Socket_Connection(const nContext: TIdContext; const nReaderID: string;
      nFlag :Boolean = True);
    //更新读卡器列表

    procedure ClearReader(const nFree: Boolean);
    procedure ClearCards(const nFree: Boolean);
    //清理资源

    function GetReader(const nID: string): Integer;
    //检索读头
    procedure GetACard(const nReader, nCard: string);
    //上行卡号

    procedure UDPBroadcast;
    //广播服务器IP地址
    procedure TCPCheckOnline;
    //发送在线心跳报文
    procedure DoOpenDoor;
    //抬杆指令
  public
    constructor Create;
    destructor Destroy; override;
    //创建释放
    procedure LoadConfig(const nFile: string);
    //载入配置
    procedure StartReader(const nPort: Integer = 0);
    procedure StopReader;
    procedure StopMe(const nFree: Boolean = True);
    //启停读头
    procedure SeTBlueReaderCard(const nReader,nCard: string);
    //发送卡号
    function OpenDoor(const nReaderID: string): Boolean;
    //打开道闸
    property ServerPort: Integer read FSrvPort write FSrvPort;
    property KeepTime: Integer read FKeepTime write FKeepTime;
    property OnCardArrived: TOnCard read FCardArrived write FCardArrived;
    //属性相关
  end;

var
  gBlueReader: TBlueReader = nil;
  //全局使用

implementation

procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(TBlueReader, '蓝卡远距读卡器', nEvent);
end;

function GetLocalIpList(var nIPList:TStrings):Integer;
type
  TAPInAddr = array[0..10] of PInAddr;
  PAPInAddr = ^TAPInAddr;
var
  nIdx: Integer;
  nPtr: PAPInAddr;
  nNameLen: Integer;
  nWSData: TWSAData;
  nHostEnt: PHostEnt;
  nHostName: array [0..MAX_PATH] of char;
begin
  Result := 0;
  if WSAStartup(MakeWord(2,0), nWSData) <> 0 then Exit;

  try
    nNameLen := SizeOf(nHostName);
    FillChar(nHostName, nNameLen, #0);

    nNameLen := GetHostName(nHostName, nNameLen);
    if nNameLen = SOCKET_ERROR then Exit;

    nHostEnt := GetHostByName(nHostName);
    if not Assigned(nHostEnt) then Exit;

    nIdx := 0;
    nPtr := PAPInAddr(nHostEnt^.h_addr_list);

    nIPList.Clear;
    while Assigned(nPtr^[nIdx]) do
    begin
      nIPList.Add(inet_ntoa(nPtr^[nIdx]^));
      Inc(nIdx);
    end;

    Result := nIPList.Count;
  finally
    WSACleanup;
  end;
end;

constructor TBlueReader.Create;
begin
  inherited Create(False);
  FreeOnTerminate := False;

  SetLength(FItems, 0);
  //0 Items

  FCards := TList.Create;
  FActiveReaders := TList.Create;
  FCardInfo := TStringList.Create;
  FDataBuffer := TStringList.Create;

  FKeepTime := 2 * 1000;
  FWaiter := TWaitObject.Create;
  FWaiter.Interval := INFINITE;
  FSyncLock := TCriticalSection.Create;

  FSrvPort := 5810;
  FSrvIPList := TStringList.Create;
  //蓝卡读卡器默认服务器端口

  FUDPClient := TIdUDPClient.Create;
  FUDPClient.Port := 5810;
  FUDPClient.BroadcastEnabled := False;
  //蓝卡读卡器默认UDP端口
  
  FServer := TIdTCPServer.Create;
  FServer.OnConnect := TCPServerConnect;
  FServer.OnExecute := TCPServerExecute;
  FServer.OnDisconnect := TCPServerDisconnect;
end;

destructor TBlueReader.Destroy;
begin
  StopMe(False);
  FServer.Active := False;
  FServer.Free;
  FUDPClient.Free;

  ClearCards(True);
  ClearReader(True);

  FCardInfo.Free;
  FSrvIPList.Free;
  FDataBuffer.Free;
  //xxxxx

  SetLength(FItems, 0);
  //0 Items

  FWaiter.Free;
  FSyncLock.Free;
  inherited;
end;

procedure TBlueReader.ClearReader(const nFree: Boolean);
var nIdx: Integer;
begin
  for nIdx:=FActiveReaders.Count - 1 downto 0 do
  begin
    Dispose(PBlueReaderHost(FActiveReaders[nIdx]));
    FActiveReaders.Delete(nIdx);
  end;

  if nFree then FActiveReaders.Free;
end;

procedure TBlueReader.ClearCards(const nFree: Boolean);
var nIdx: Integer;
begin
  for nIdx:=FCards.Count - 1 downto 0 do
  begin
    Dispose(PBlueReaderCard(FCards[nIdx]));
    FCards.Delete(nIdx);
  end;

  if nFree then FCards.Free;
end;

procedure TBlueReader.StopMe(const nFree: Boolean);
begin
  Terminate;
  FWaiter.Wakeup;

  WaitFor;
  if nFree then
    Free;
  //xxxxx
end;

procedure TBlueReader.StartReader(const nPort: Integer);
var nIdx: Integer;
begin
  if nPort > 0 then
    FSrvPort := nPort;
  //new port

  FServer.Active := False;
  FServer.DefaultPort := FSrvPort;

  if FSrvIPList.Count < 1 then
    GetLocalIpList(FSrvIPList);
  //获取IP地址表

  FServer.Active := False;
  FServer.Bindings.Clear;
  //停止服务
  
  for nIdx := 0 to FSrvIPList.Count-1 do
  with FServer do
  begin
    Bindings.Add;
    Bindings[nIdx].IP := FSrvIPList[nIdx];
    Bindings[nIdx].Port := FSrvPort;
  end;
  //绑定端口

  FServer.Active := True;
  //启动服务

  FWaiter.Interval := cBlueReader_Query_Interval;
  FWaiter.Wakeup;
end;

procedure TBlueReader.StopReader;
begin
  FServer.Active := False; 
  FWaiter.Interval := INFINITE;
end;

//Date: 2015-12-05
//Parm: 读头编号;磁卡号
//Desc: 向nReader发送卡号nCard,触发刷卡业务
procedure TBlueReader.SeTBlueReaderCard(const nReader, nCard: string);
begin
  GetACard(nReader, nCard);
end;

procedure TBlueReader.LoadConfig(const nFile: string);
var nXML: TNativeXml;
    nNode,nTP: TXmlNode;
    nInt, nIdx: Integer;
begin
  nXML := TNativeXml.Create;
  try
    ClearReader(False);
    if not FileExists(nFile) then Exit;
    nXML.LoadFromFile(nFile);

    nNode := nXML.Root.NodeByName('Server');

    if Assigned(nNode) then
    begin
      FSrvPort := nNode.NodeByName('port').ValueAsInteger;

      FSrvIPList.Clear;
      nTP := nNode.FindNode('IP');
      if Assigned(nTP) then
        FSrvIPList.Add(nTP.ValueAsString);

      nTP := nNode.FindNode('enable');
      if Assigned(nTP) then
           FEnable := nTP.ValueAsString <> 'N'
      else FEnable := True;
    end;

    nNode := nXML.Root.NodeByName('readers');
    SetLength(FItems, nNode.NodeCount);
    nInt := 0;

    for nIdx:=0 to nNode.NodeCount - 1 do
    with nNode.Nodes[nIdx],FItems[nInt] do
    begin
      FID := AttributeByName['ID'];

      nTP := NodeByName('ip');
      if Assigned(nTP) then
           FHostIP := nTP.ValueAsString
      else FHostIP := '';

      nTP := NodeByName('port');
      if Assigned(nTP) then
           FHostPort := StrToIntDef(nTP.ValueAsString, 5810)
      else FHostPort := 5810;

      nTP := NodeByName('Enable');
      if Assigned(nTP) then
           FEnable := nTP.ValueAsString <> '0'
      else FEnable := False;

      Inc(nInt);
    end;
  finally
    nXML.Free;
  end;
end;

//------------------------------------------------------------------------------
procedure TBlueReader.Execute;
var nIdx: Integer;
    nCard: TBlueReaderCard;
    nPCard: PBlueReaderCard;
    nHost: TBlueReaderHost;
begin
  while not Terminated do
  try
    FWaiter.EnterWait;
    if Terminated then Exit;
    if not FServer.Active then Continue;

    UDPBroadcast;
    //Broadcast server

    TCPCheckOnline;
    //Send smart drag

    DoOpenDoor;
    //Open the door

    while True do
    begin
      FSyncLock.Enter;
      try
        nPCard := nil;
        for nIdx:=FCards.Count - 1 downto 0 do
        begin
          nPCard := FCards[nIdx];
          if nPCard.FOldOne then
          begin
            Dispose(nPCard);
            nPCard := nil;

            FCards.Delete(nIdx);
            Continue;
          end; //已无效

          if Assigned(nPCard.FHost) then
          begin
            if GetTickCount - nPCard.FLast > FKeepTime then
            begin
              nPCard.FEvent := False;
              nPCard.FOldOne := True;
            end;
          end; //已超时

          if nPCard.FEvent then
               nPCard := nil
          else Break;
        end;

        if Assigned(nPCard) then
        begin
          nPCard.FEvent := True;
          nCard := nPCard^;

          if Assigned(nPCard.FHost) then
          begin
            nHost := nPCard.FHost^;
          end;
        end else Break;
      finally
        FSyncLock.Leave;
      end;

      if Assigned(FCardArrived) then FCardArrived(nHost, nCard);
    end;
  except
    on E:Exception do
    begin
      WriteLog(E.Message);
    end;
  end;
end;

//Desc: 收到nReader上传的nCard卡片
procedure TBlueReader.GetACard(const nReader, nCard: string);
var nIdx,nInt: Integer;
    nPCard: PBlueReaderCard;
begin
  FSyncLock.Enter;
  try
    if nReader <> '' then
    begin
      nInt := GetReader(nReader);
      if nInt < 0 then Exit;
    end else nInt := -1;

    nPCard := nil;
    //default

    for nIdx:=FCards.Count - 1 downto 0 do
    begin
      nPCard := FCards[nIdx];
      if CompareText(nCard, nPCard.FCard) = 0 then
           Break
      else nPCard := nil;
    end;

    if Assigned(nPCard) then
    begin
      if nInt < 0 then
      begin
        nPCard.FHost := nil;
        nPCard.FEvent := False;
      end else

      if nPCard.FHost <> FActiveReaders[nInt] then
      begin
        nPCard.FHost := FActiveReaders[nInt];
        nPCard.FEvent := False;
        //读卡器已更换
      end;

      if GetTickCount - nPCard.FLast >= 2 * 1000 then
      begin
        nPCard.FEvent := False;
        //间隔后生效
      end;
    end else
    begin
      New(nPCard);
      FCards.Add(nPCard);

      if nInt >= 0 then
      begin
        nPCard.FHost := FActiveReaders[nInt];
      end else nPCard.FHost := nil;

      nPCard.FCard := nCard;
      nPCard.FEvent := False;
      nPCard.FInTime := GetTickCount;
    end;

    nPCard.FOldOne := False;
    nPCard.FLast := GetTickCount;
  finally
    FSyncLock.Leave;
  end;
end;

//Desc: 检索读头(加锁调用)
function TBlueReader.GetReader(const nID: string): Integer;
var nIdx: Integer;
    nHost: PBlueReaderHost;
begin
  Result := -1;

  for nIdx:=FActiveReaders.Count - 1 downto 0 do
  begin
    nHost := FActiveReaders[nIdx];
    if (nID <> '') and (CompareText(nID, nHost.FReaderID) = 0) then
    begin
      Result := nIdx;
      Exit;
    end;
  end;
end;

function TBlueReader.GetReaderID(const nContext: TIdContext): String;
var nIdx: Integer;
    nReader: PBlueReaderHost;
begin
  Result := '';
  //init

  FSyncLock.Enter;
  try
    for nIdx := 0 to FActiveReaders.Count - 1 do
    begin
      nReader := FActiveReaders[nIdx];

      if Assigned(nReader)  and (nReader.FContext = nContext) then
      begin
        Result := nReader.FReaderID;
        Exit;
      end;  
    end;  
  finally
    FSyncLock.Leave;
  end;
end;

//Date: 2016/5/5
//Parm: 读卡器编号
//Desc: 获取读卡器对应连接 加锁调用
function TBlueReader.GetReaderContext(const nReaderID: string): TIdContext;
var nIdx: Integer;
    nReader: PBlueReaderHost;
begin
  Result := nil;
  //init

  for nIdx := 0 to FActiveReaders.Count - 1 do
  begin
    nReader := FActiveReaders[nIdx];

    if Assigned(nReader)  and
       (CompareText(nReaderID, nReader.FReaderID) = 0) then
    begin
      Result := nReader.FContext;
      Exit;
    end;  
  end;
end;

//Date: 2016/4/21
//Parm: 
//Desc: 记录服务端接收客户端连接
procedure TBlueReader.TCPServerConnect(AContext: TIdContext);
var nPeerIP, nPeerPort: string;
begin
  nPeerIP := AContext.Connection.Socket.Binding.PeerIP;
  nPeerPort := IntToStr(AContext.Connection.Socket.Binding.PeerPort);

  WriteLog('客户端: [' + nPeerIP + ':' + nPeerPort + '] 连接成功');
end;

//Date: 2016/4/21
//Parm: 
//Desc: 记录客户端从服务端断开连接
procedure TBlueReader.TCPServerDisconnect(AContext: TIdContext);
var nPeerIP, nPeerPort: string;
begin
  nPeerIP := AContext.Connection.Socket.Binding.PeerIP;
  nPeerPort := IntToStr(AContext.Connection.Socket.Binding.PeerPort);

  Socket_Connection(AContext, '', False);
  WriteLog('客户端: [' + nPeerIP + ':' + nPeerPort + '] 断开连接');
end;

procedure TBlueReader.TCPServerExecute(AContext: TIdContext);
var nSend: string;
begin
  nSend := cBlueReader_BUMAC + cBlueReader_Flag_End;
  //获取读卡器信息
  
  with AContext.Connection do
  try
    FWaiter.EnterWait;
    if Terminated then Exit;

    if Socket.InputBufferIsEmpty then
    begin
      Socket.Write(nSend);
      Exit;
    end;

    //ReadLn方法会阻塞线程，导致线程无响应
    DoReadEvent(AContext, Socket.InputBufferAsString);;
  except
    if Connected then
    begin
      //Disconnect;
      if Assigned(IOHandler) then
        IOHandler.InputBuffer.Clear;
    end;
  end;
end;

procedure TBlueReader.DoReadEvent(const nContext: TIdContext; const nBuff: string);
var nPeerIP, nStr: string;
    nReader: PBlueReaderHost;
    nIdx, nInt, nPos: Integer;
begin
  FSyncLock.Enter;
  try
    nInt := -1;
    nReader := nil;
    nPeerIP := nContext.Connection.Socket.Binding.PeerIP;
    
    for nIdx:=0 to FActiveReaders.Count-1 do
    begin
      nReader := FActiveReaders[nIdx];
      if CompareText(UpperCase(nPeerIP), nReader.FPeerIP) = 0 then
      begin
        nInt := nIdx;
        Break;
      end;  
    end;

    if nInt < 0 then
    begin
      New(nReader);
      nReader.FContext := nContext;
      nReader.FPeerIP  := nPeerIP;

      nReader.FReaderID:= '';
      nReader.FRecvData:= nBuff;

      FActiveReaders.Add(nReader);
    end else //新读卡器

    begin
       nReader.FContext := nContext;
       nReader.FRecvData:= nReader.FRecvData + nBuff;
    end;     //已存在读卡器

    if Length(nReader.FRecvData) < 10 then Exit;
    //最小长度大于10

    while Length(nReader.FRecvData)>10 do
    begin
      nPos := Pos(cBlueReader_Flag_End, nReader.FRecvData);
      if nPos < 1 then Exit;
      //有完整的数据包,每个数据包都已#13#10结束

      nStr := Copy(nReader.FRecvData, 1, nPos-1);
      Delete(nReader.FRecvData, 1, nPos + 1);
      if Length(nStr) < 1 then Continue;
      //NULL 报文

      FCardInfo.Clear;
      //清空卡号信息

      nPos := Pos(cBlueReader_Flag_Record, nStr);
      if nPos > 0 then
      begin
        SplitStr(nStr, FCardInfo, 0, ' ', False);
        SeTBlueReaderCard(nReader.FReaderID, FCardInfo[2]);
        //解析卡号

        {$IFDEF DEBUG}
        WriteLog('读卡器:' + nReader.FReaderID + ' 收到卡号:' + FCardInfo[2]);
        {$ENDIF}
        Continue;
      end;
      //卡号

      nPos := Pos(cBlueReader_Flag_CardNO, nStr);
      if nPos > 0 then
      begin
        SplitStr(nStr, FCardInfo, 0, ' ', False);
        SeTBlueReaderCard(nReader.FReaderID, FCardInfo[2]);
        
        {$IFDEF DEBUG}
        WriteLog('读卡器:' + nReader.FReaderID + ' 收到卡号:' + FCardInfo[2]);
        {$ENDIF}
        Continue;
      end;
      //卡号

      nPos := Pos(cBlueReader_Flag_ReaderID, nStr);
      if nPos > 0 then
      begin
        nReader.FReaderID := Copy(nStr, 10, 10);
        //获取到读卡器编号

        {$IFDEF DEBUG}
        WriteLog(nReader.FReaderID);
        {$ENDIF}
        Continue;
      end;
      //读卡器编号

      nPos := Pos(cBlueReader_Flag_Bumac, nStr);
      if nPos > 0 then
      begin
        nReader.FReaderID := Copy(nStr, 7, 10);
        //获取到读卡器编号

        {$IFDEF DEBUG}
        WriteLog(nReader.FReaderID);
        {$ENDIF}
        Continue;
      end;
      //读卡器编号
    end;

    if Length(nReader.FRecvData) > cBlueReader_Recv_Length then
      nReader.FRecvData := '';
  finally
    FSyncLock.Leave;
  end;
end;  

procedure TBlueReader.Socket_Connection(const nContext: TIdContext;
  const nReaderID: string; nFlag :Boolean = True);
var nIdx, nInt: Integer;
    nReader, nNew: PBlueReaderHost;
begin
  FSyncLock.Enter;
  try
    nInt := -1;
    for nIdx := 0 to FActiveReaders.Count - 1 do
    begin
      nReader := FActiveReaders[nIdx];

      if Assigned(nReader)  and
        ((nReader.FContext = nContext) or (nReader.FReaderID = nReaderID))then
      begin
        nInt := nIdx;
        Break;
      end;
    end;

    case nFlag of
    True  :
      begin
        if nInt < 0 then
        begin
          New(nNew);
          nNew.FContext    := nContext;
          if nReaderID <> '' then
            nNew.FReaderID := nReaderID;

          FActiveReaders.Add(nNew);
        end else
        begin
          with PBlueReaderHost(FActiveReaders[nInt])^ do
          begin
            FContext  := nContext;

            if nReaderID <> '' then
              FReaderID := nReaderID;
          end;  
        end;
      end;  
    False :
      begin
        if nInt > -1 then
        begin
          nReader := FActiveReaders[nInt];
          Dispose(nReader);

          FActiveReaders.Delete(nInt);
          //xxxxx
        end;  
      end;  
    end;
  finally
    FSyncLock.Leave;
  end;
end;

//Date: 2016/4/21
//Parm: 
//Desc: 广播服务器IP地址与端口
procedure TBlueReader.UDPBroadcast;
var nSend, nSendBuf: string;
    nIdx, nJdx: Integer;
begin
  nSend := cBlueReader_BroastServer + cBlueReader_Flag_End;
  //Send Template

  if FSrvIPList.Count < 1 then GetLocalIpList(FSrvIPList);

  for nIdx := 0 to FSrvIPList.Count-1 do
  begin
    nSendBuf := MacroValue(nSend, [MI('$ServIP', FSrvIPList[nIdx]),
                MI('$ServPort', IntToStr(FSrvPort))]);

    if Length(FItems) < 1 then  //0 Items
    begin
      FUDPClient.Broadcast(nSendBuf, FUDPClient.Port);
      //no Items BroadCast
    end else

    begin
      for nJdx := Low(FItems) to High(FItems) do
      with FItems[nJdx] do
      begin
        if FEnable then
          FUDPClient.Send(FHostIP, FHostPort, nSendBuf);
        //Only Enable is true, Send Drag 
      end;  
    end;
  end;
end;

//Date: 2016/4/21
//Parm: 
//Desc: 发送心跳报文保证设备在线
procedure TBlueReader.TCPCheckOnline;
var nIdx: Integer;
    nSend: string;
    nLocalThreads: TList;
    nThreads: TThreadList;
    nPeerContext: TIdContext;
begin
  nSend := cBlueReader_WatchDog + cBlueReader_Flag_End;
  //心跳报文

  FSyncLock.Enter;
  if FServer.Active then
  try
    nThreads := FServer.Contexts;
    if Assigned(nThreads) then
    begin
      nLocalThreads := nThreads.LockList;
      try
        for nIdx := 0 to nLocalThreads.Count-1 do
        begin
          nPeerContext := TIdContext(nLocalThreads[nIdx]);
          nPeerContext.Connection.Socket.Write(nSend);
        end;
      finally
        nThreads.UnlockList;
      end;
    end;
  finally
    FSyncLock.Leave;
  end;
end;

procedure TBlueReader.DoOpenDoor;
var nIdx: Integer;
    nThreads: TThreadList;
    nContext: TIdContext;
    nSend, nReader: string;
begin
  nSend := cBlueReader_OpenDoor + cBlueReader_Flag_End;
  //Send Open door command

  FSyncLock.Enter;
  if FServer.Active then
  try
    nThreads := FServer.Contexts;
    if Assigned(nThreads) then
    begin
      nThreads.LockList;
      try
        for nIdx := FDataBuffer.Count - 1 downto 0 do
        begin
          nReader := FDataBuffer[nIdx];
          nContext := GetReaderContext(nReader);
          if not Assigned(nContext) then Continue;

          with nContext.Connection do
          try
            if not Assigned(nContext.Connection) then Continue;
            if not nContext.Connection.Connected then Continue;
            //服务器网络断开后，Connection=nil

            WriteLog('读卡器 [' + nReader + '] 执行抬杆');
            Socket.Write(nSend);
            WriteLog('读卡器 [' + nReader + '] 抬杆成功。');
            //xxxxx

            FDataBuffer.Delete(nIdx);
          except
            on E: Exception do
            begin
              WriteLog(E.Message);

              //Disconnect;
              if Assigned(IOHandler) then
                IOHandler.InputBuffer.Clear;
            end; 
          end;
        end;
      finally
        nThreads.UnlockList;
      end;
    end;
  finally
    FSyncLock.Leave;
  end;
end;  

//Date: 2016/4/21
//Parm:
//Desc: 打开道闸
function TBlueReader.OpenDoor(const nReaderID: string): Boolean;
begin
  Result := False;
  //init

  FSyncLock.Enter;
  try
    if FDataBuffer.IndexOf(nReaderID) < 0 then
      FDataBuffer.Add(nReaderID);
  finally
    FSyncLock.Leave;
  end;   
end;

initialization
  gBlueReader := TBlueReader.Create;
finalization
  FreeAndNil(gBlueReader);
end.
