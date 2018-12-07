{*******************************************************************************
  ����: fendou116688@163.com 2016/4/21
  ����: �������������Ƶ�Ԫ
*******************************************************************************}
unit UBlueReader;

interface

uses
  Windows, Classes, SysUtils, SyncObjs, NativeXml, Controls, WinSock,
  UWaitItem, UMemDataPool, USysLoger, ULibFun,
  IdTCPConnection, IdTCPClient, IdTCPServer,
  IdGlobal, IdSocketHandle, IdContext, IdUDPClient;
  
const
  cBlueReader_NullASCII     = $30;                          //ASCII���ֽ�
  cBlueReader_Flag_End      = #13#10;                       //ָ�������ʶ


  cBlueReader_Flag_Bumac    = 'BUMAC=';                     //��������ű�ʶ
  cBlueReader_Flag_ReaderID = 'READERID';                   //��������ű�ʶ
  cBlueReader_Flag_FIRMWARE = 'FIRMWARE';                   //�������̼��汾��

  cBlueReader_Flag_CardNO   = 'PARKMODE CARDNO ';           //ʵʱ��Ƭ���
  cBlueReader_Flag_Record   = 'PARKMODE RECORD ';           //ʵʱ��Ƭ���

  cBlueReader_BUMAC         = 'BUMAC';                      //������IDָ��
  cBlueReader_WatchDog      = 'watchdog';                   //����������ָ��
  cBlueReader_OpenDoor      = 'WRITEGPIO 01';               //������̧��ָ��
  cBlueReader_BroastServer  = 'SERVERIP $ServIP $ServPort'; //�㲥��������ַ

  cBlueReader_Query_Interval= 3*100;                          //ָ����
  cBlueReader_Recv_Length   = 200;                             //���ջ���������

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
    FReaderID :string;                          //���������
    FRecvData :string;                          //����������

    FContext  :TIdContext;                      //��������·
    FPeerIP   : string;                         //������IP
  end;
  //online host

  PBlueReaderHost = ^TBlueReaderHost;
  //Point of host

  TBlueReaderHosts = array of TBlueReaderHost;
  //array of host

  PBlueReaderCard = ^TBlueReaderCard;
  TBlueReaderCard = record
    FHost   : PBlueReaderHost;   //��ͷ
    FCard   : string;            //����
    FOldOne : Boolean;           //��ʱ��

    FEvent  : Boolean;           //�Ѵ���
    FLast   : Int64;             //�ϴδ���
    FInTime : Int64;             //�״�ʱ��
  end;

  TOnCard = procedure (nHost: TBlueReaderHost; nCard: TBlueReaderCard);
  //��Ƭ�¼�

  TBlueReader = class(TThread)
  private
    FItems: TBlueReaderItems;
    //���ö�ͷ�б�
    FActiveReaders: TList;
    //���ͷ�б�
    FDataBuffer: TStrings;
    //̧��ָ�
    FCards: TList;
    //�յ����б�
    FCardInfo: TStrings;
    //�յ����ο�����Ϣ
    FKeepTime: Integer;
    //��ʱ�ȴ�
    FSrvIPList: TStrings;
    //������IP��ַ��
    FSrvPort: Integer;
    FServer: TIdTCPServer;
    //�����
    FUDPClient: TIdUDPClient;
    //�㲥������IP��ַ(���ڹ㲥)
    FWaiter: TWaitObject;
    //�ȴ�����
    FSyncLock: TCriticalSection;
    //ͬ����
    FEnable: Boolean;
    //�Ƿ�����
    FCardArrived: TOnCard;
    //�¼�
  protected
    procedure Execute; override;
    //ִ���߳�

    procedure TCPServerConnect(AContext: TIdContext);
    //�ͻ�������
    procedure TCPServerDisconnect(AContext: TIdContext);
    //�ͻ��˶Ͽ�
    procedure TCPServerExecute(AContext: TIdContext);
    //������ִ���߳�
    procedure DoReadEvent(const nContext: TIdContext; const nBuff: string='');
    //�������������

    function GetReaderID(const nContext: TIdContext): String;
    //��ȡ���������
    function GetReaderContext(const nReaderID: string): TIdContext;
    //��ȡ��������·
    procedure Socket_Connection(const nContext: TIdContext; const nReaderID: string;
      nFlag :Boolean = True);
    //���¶������б�

    procedure ClearReader(const nFree: Boolean);
    procedure ClearCards(const nFree: Boolean);
    //������Դ

    function GetReader(const nID: string): Integer;
    //������ͷ
    procedure GetACard(const nReader, nCard: string);
    //���п���

    procedure UDPBroadcast;
    //�㲥������IP��ַ
    procedure TCPCheckOnline;
    //����������������
    procedure DoOpenDoor;
    //̧��ָ��
  public
    constructor Create;
    destructor Destroy; override;
    //�����ͷ�
    procedure LoadConfig(const nFile: string);
    //��������
    procedure StartReader(const nPort: Integer = 0);
    procedure StopReader;
    procedure StopMe(const nFree: Boolean = True);
    //��ͣ��ͷ
    procedure SeTBlueReaderCard(const nReader,nCard: string);
    //���Ϳ���
    function OpenDoor(const nReaderID: string): Boolean;
    //�򿪵�բ
    property ServerPort: Integer read FSrvPort write FSrvPort;
    property KeepTime: Integer read FKeepTime write FKeepTime;
    property OnCardArrived: TOnCard read FCardArrived write FCardArrived;
    //�������
  end;

var
  gBlueReader: TBlueReader = nil;
  //ȫ��ʹ��

implementation

procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(TBlueReader, '����Զ�������', nEvent);
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
  //����������Ĭ�Ϸ������˿�

  FUDPClient := TIdUDPClient.Create;
  FUDPClient.Port := 5810;
  FUDPClient.BroadcastEnabled := False;
  //����������Ĭ��UDP�˿�
  
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
  //��ȡIP��ַ��

  FServer.Active := False;
  FServer.Bindings.Clear;
  //ֹͣ����
  
  for nIdx := 0 to FSrvIPList.Count-1 do
  with FServer do
  begin
    Bindings.Add;
    Bindings[nIdx].IP := FSrvIPList[nIdx];
    Bindings[nIdx].Port := FSrvPort;
  end;
  //�󶨶˿�

  FServer.Active := True;
  //��������

  FWaiter.Interval := cBlueReader_Query_Interval;
  FWaiter.Wakeup;
end;

procedure TBlueReader.StopReader;
begin
  FServer.Active := False; 
  FWaiter.Interval := INFINITE;
end;

//Date: 2015-12-05
//Parm: ��ͷ���;�ſ���
//Desc: ��nReader���Ϳ���nCard,����ˢ��ҵ��
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
          end; //����Ч

          if Assigned(nPCard.FHost) then
          begin
            if GetTickCount - nPCard.FLast > FKeepTime then
            begin
              nPCard.FEvent := False;
              nPCard.FOldOne := True;
            end;
          end; //�ѳ�ʱ

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

//Desc: �յ�nReader�ϴ���nCard��Ƭ
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
        //�������Ѹ���
      end;

      if GetTickCount - nPCard.FLast >= 2 * 1000 then
      begin
        nPCard.FEvent := False;
        //�������Ч
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

//Desc: ������ͷ(��������)
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
//Parm: ���������
//Desc: ��ȡ��������Ӧ���� ��������
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
//Desc: ��¼����˽��տͻ�������
procedure TBlueReader.TCPServerConnect(AContext: TIdContext);
var nPeerIP, nPeerPort: string;
begin
  nPeerIP := AContext.Connection.Socket.Binding.PeerIP;
  nPeerPort := IntToStr(AContext.Connection.Socket.Binding.PeerPort);

  WriteLog('�ͻ���: [' + nPeerIP + ':' + nPeerPort + '] ���ӳɹ�');
end;

//Date: 2016/4/21
//Parm: 
//Desc: ��¼�ͻ��˴ӷ���˶Ͽ�����
procedure TBlueReader.TCPServerDisconnect(AContext: TIdContext);
var nPeerIP, nPeerPort: string;
begin
  nPeerIP := AContext.Connection.Socket.Binding.PeerIP;
  nPeerPort := IntToStr(AContext.Connection.Socket.Binding.PeerPort);

  Socket_Connection(AContext, '', False);
  WriteLog('�ͻ���: [' + nPeerIP + ':' + nPeerPort + '] �Ͽ�����');
end;

procedure TBlueReader.TCPServerExecute(AContext: TIdContext);
var nSend: string;
begin
  nSend := cBlueReader_BUMAC + cBlueReader_Flag_End;
  //��ȡ��������Ϣ
  
  with AContext.Connection do
  try
    FWaiter.EnterWait;
    if Terminated then Exit;

    if Socket.InputBufferIsEmpty then
    begin
      Socket.Write(nSend);
      Exit;
    end;

    //ReadLn�����������̣߳������߳�����Ӧ
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
    end else //�¶�����

    begin
       nReader.FContext := nContext;
       nReader.FRecvData:= nReader.FRecvData + nBuff;
    end;     //�Ѵ��ڶ�����

    if Length(nReader.FRecvData) < 10 then Exit;
    //��С���ȴ���10

    while Length(nReader.FRecvData)>10 do
    begin
      nPos := Pos(cBlueReader_Flag_End, nReader.FRecvData);
      if nPos < 1 then Exit;
      //�����������ݰ�,ÿ�����ݰ�����#13#10����

      nStr := Copy(nReader.FRecvData, 1, nPos-1);
      Delete(nReader.FRecvData, 1, nPos + 1);
      if Length(nStr) < 1 then Continue;
      //NULL ����

      FCardInfo.Clear;
      //��տ�����Ϣ

      nPos := Pos(cBlueReader_Flag_Record, nStr);
      if nPos > 0 then
      begin
        SplitStr(nStr, FCardInfo, 0, ' ', False);
        SeTBlueReaderCard(nReader.FReaderID, FCardInfo[2]);
        //��������

        {$IFDEF DEBUG}
        WriteLog('������:' + nReader.FReaderID + ' �յ�����:' + FCardInfo[2]);
        {$ENDIF}
        Continue;
      end;
      //����

      nPos := Pos(cBlueReader_Flag_CardNO, nStr);
      if nPos > 0 then
      begin
        SplitStr(nStr, FCardInfo, 0, ' ', False);
        SeTBlueReaderCard(nReader.FReaderID, FCardInfo[2]);
        
        {$IFDEF DEBUG}
        WriteLog('������:' + nReader.FReaderID + ' �յ�����:' + FCardInfo[2]);
        {$ENDIF}
        Continue;
      end;
      //����

      nPos := Pos(cBlueReader_Flag_ReaderID, nStr);
      if nPos > 0 then
      begin
        nReader.FReaderID := Copy(nStr, 10, 10);
        //��ȡ�����������

        {$IFDEF DEBUG}
        WriteLog(nReader.FReaderID);
        {$ENDIF}
        Continue;
      end;
      //���������

      nPos := Pos(cBlueReader_Flag_Bumac, nStr);
      if nPos > 0 then
      begin
        nReader.FReaderID := Copy(nStr, 7, 10);
        //��ȡ�����������

        {$IFDEF DEBUG}
        WriteLog(nReader.FReaderID);
        {$ENDIF}
        Continue;
      end;
      //���������
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
//Desc: �㲥������IP��ַ��˿�
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
//Desc: �����������ı�֤�豸����
procedure TBlueReader.TCPCheckOnline;
var nIdx: Integer;
    nSend: string;
    nLocalThreads: TList;
    nThreads: TThreadList;
    nPeerContext: TIdContext;
begin
  nSend := cBlueReader_WatchDog + cBlueReader_Flag_End;
  //��������

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
            //����������Ͽ���Connection=nil

            WriteLog('������ [' + nReader + '] ִ��̧��');
            Socket.Write(nSend);
            WriteLog('������ [' + nReader + '] ̧�˳ɹ���');
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
//Desc: �򿪵�բ
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
