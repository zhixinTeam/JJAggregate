{*******************************************************************************
  ����: dmzn@163.com 2012-4-21
  ����: Ӳ���ػ�����������
*******************************************************************************}
unit UMgrHardHelper;

{$I Link.Inc}
interface

uses
  Windows, Classes, SysUtils, SyncObjs, NativeXml, IdComponent, IdTCPConnection,
  IdTCPClient, IdUDPServer, IdGlobal, IdSocketHandle, USysLoger, UWaitItem;

type
  PHHDataBase = ^THHDataBase;
  THHDataBase = record
    FCommand   : Byte;     //������
    FDataLen   : Word;     //���ݳ�
  end;

  PHHOpenDoor = ^THHOpenDoor;
  THHOpenDoor = record
    FBase      : THHDataBase;
    FReaderID  : string;
  end;

const
  cHHCmd_GetCards  = $12;  //��ȡ����
  cHHCmd_OpenDoor  = $27;  //��բ̧��
  cSizeHHBase      = SizeOf(THHDataBase);
  
type
  THHReaderType = (rtIn, rtOut, rtPound, rtGate, rtQueueGate);
  //��ͷ����:��,��,��,��բ,������բ

  THHReaderItem = record
    FID      : string;
    FType    : THHReaderType;
    FPound   : string;
    FCard    : string;
    FCardExt : string;
    FPrinter : string;
    FLast    : Int64;
    FKeep    : Word;
    FOKTime  : Int64;
    FOptions : TStrings;          //���Ӳ���
  end;

  THardwareHelper = class;
  THardwareConnector = class(TThread)
  private
    FOwner: THardwareHelper;
    //ӵ����
    FBuffer: TList;
    //���ͻ���
    FWaiter: TWaitObject;
    //�ȴ�����
    FClient: TIdTCPClient;
    FServer: TIdUDPServer;
    //�������
  protected
    procedure DoCardAction;
    procedure DoExuecte;
    procedure Execute; override;
    //ִ���߳�
    procedure SetReaderCard(const nReader,nCard: string);
    //������Ƭ
    procedure OnUDPRead(AThread: TIdUDPListenerThread;
      AData: TIdBytes; ABinding: TIdSocketHandle);
    //��Ƭ����
  public
    constructor Create(AOwner: THardwareHelper);
    destructor Destroy; override;
    //�����ͷ�
    procedure WakupMe;
    //�����߳�
    procedure StopMe;
    //ֹͣ�߳�
  end;

  THHProce = procedure (const nReader: THHReaderItem);
  THHEvent = procedure (const nReader: THHReaderItem) of Object;
  //�¼����

  THardwareHelper = class(TObject)
  private
    FHostIP: string;
    FHostPort: Integer;
    FUDPPort: Integer;
    FConnHelper: Boolean;
    //��������
    FItems: array of THHReaderItem;
    //��ͷ�б�
    FReader: THardwareConnector;
    //������
    FBuffData: TList;
    //��ʱ����
    FSyncLock: TCriticalSection;
    //ͬ����
    FProce: THHProce;
    FEvent: THHEvent;
    //�¼����
  protected
    procedure ClearBuffer(const nList: TList);
    //������
  public
    constructor Create;
    destructor Destroy; override;
    //�����ͷ�
    procedure LoadConfig(const nFile: string);
    //��ȡ����
    procedure StartRead;
    procedure StopRead;
    //��ͣ��ȡ
    function GetPoundCard(const nPound: string; var nReader: string): string;
    procedure SetPoundCardExt(const nPound,nExtCard: string);
    //��վ����
    procedure OpenDoor(const nReader: string);
    //��բ̧��
    procedure SetReaderCard(const nReader,nCard: string;
      const nVirtualReader: Boolean = True);
    function GetCardLastDone(const nCard,nReader: string): Int64;
    procedure SetCardLastDone(const nCard,nReader: string);
    function GetReaderLastOn(const nCard: string): string;
    //�ſ��
    property ConnHelper: Boolean read FConnHelper write FConnHelper;
    property OnProce: THHProce read FProce write FProce;
    property OnEvent: THHEvent read FEvent write FEvent;
    //�¼����
  end;

var
  gHardwareHelper: THardwareHelper = nil;
  //ȫ��ʹ��

implementation

uses
  ULibFun;

//------------------------------------------------------------------------------
procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(THardwareHelper, 'Ӳ���ػ�����', nEvent);
end;

constructor THardwareHelper.Create;
begin
  FReader := nil;
  FBuffData := TList.Create;
  FSyncLock := TCriticalSection.Create;
end;

destructor THardwareHelper.Destroy;
var nIdx: Integer;
begin
  for nIdx:=Low(FItems) to High(FItems) do
    FreeAndNil(FItems[nIdx].FOptions);
  //xxxxx

  StopRead;
  ClearBuffer(FBuffData);
  FBuffData.Free;

  FSyncLock.Free;
  inherited;
end;

procedure THardwareHelper.ClearBuffer(const nList: TList);
var nIdx: Integer;
    nBase: PHHDataBase;
begin
  for nIdx:=nList.Count - 1 downto 0 do
  begin
    nBase := nList[nIdx];

    case nBase.FCommand of
     cHHCmd_OpenDoor : Dispose(PHHOpenDoor(nBase));
    end;

    nList.Delete(nIdx);
  end;
end;

procedure THardwareHelper.StartRead;
begin
  if not Assigned(FReader) then
    FReader := THardwareConnector.Create(Self);
  FReader.WakupMe;
end;

procedure THardwareHelper.StopRead;
begin
  if Assigned(FReader) then
    FReader.StopMe;
  FReader := nil;
end;

//Desc: ��ȡnPound��ǰ����
function THardwareHelper.GetPoundCard(const nPound: string;
    var nReader: string): string;
var nIdx: Integer;
begin
  FSyncLock.Enter;
  try
    Result := '';

    for nIdx:=Low(FItems) to High(FItems) do
    if CompareText(nPound, FItems[nIdx].FPound) = 0 then
    begin
      if GetTickCount - FItems[nIdx].FLast <= FItems[nIdx].FKeep * 1000 then
        Result := FItems[nIdx].FCard;
      //xxxxx

      FItems[nIdx].FCard := '';
      if Result <> '' then
      begin
        nReader := FItems[nIdx].FID;
        Break;
      end;
      //loop get card
    end;
  finally
    FSyncLock.Leave;
  end;
end;

//Desc: �趨��չ����,�����ض��ȶ�ҵ��
procedure THardwareHelper.SetPoundCardExt(const nPound, nExtCard: string);
var nIdx: Integer;
begin
  FSyncLock.Enter;
  try
    for nIdx:=Low(FItems) to High(FItems) do
     if CompareText(nPound, FItems[nIdx].FPound) = 0 then
      FItems[nIdx].FCardExt := nExtCard;
    //xxxxx
  finally
    FSyncLock.Leave;
  end;
end;

//Desc: ��nReader��ͷִ��̧�˲���
procedure THardwareHelper.OpenDoor(const nReader: string);
var nIdx: Integer;
    nPtr: PHHOpenDoor;
    nBase: PHHDataBase;
begin
  FSyncLock.Enter;
  try
    for nIdx:=FBuffData.Count - 1 downto 0 do
    begin
      nBase := FBuffData[nIdx];
      if nBase.FCommand <> cHHCmd_OpenDoor then Continue;

      nPtr := PHHOpenDoor(nBase);
      if CompareText(nReader, nPtr.FReaderID) = 0 then Exit;
    end;

    New(nPtr);
    FBuffData.Add(nPtr);

    nPtr.FBase.FCommand := cHHCmd_OpenDoor;
    nPtr.FReaderID := nReader;

    if Assigned(FReader) then
      FReader.WakupMe;
    //xxxxx
  finally
    FSyncLock.Leave;
  end;
end;

//Desc: ��ȡnCard��nReader��ͷ�ϵ����ʱ��
function THardwareHelper.GetCardLastDone(const nCard,nReader: string): Int64;
var nIdx: Integer;
begin
  Result := 0;

  for nIdx:=Low(FItems) to High(FItems) do
  with FItems[nIdx] do
  begin
    if (FCard <> nCard) or (FID <> nReader) then Continue;
    //match reader and card_no

    Result := FOKTime;
    Break;
  end;
end;

//Desc: ��ȡnCard��nReader��ͷ�ϵ����ʱ��
procedure THardwareHelper.SetCardLastDone(const nCard,nReader: string);
var nIdx: Integer;
begin
  for nIdx:=Low(FItems) to High(FItems) do
  with FItems[nIdx] do
  begin
    if (FCard <> nCard) or (FID <> nReader) then Continue;
    //match reader and card_no

    FOKTime := GetTickCount;
    Break;
  end;
end;

//Date: 2012-12-15
//Parm: ��ͷ��;�ſ���;�Ƿ������ͷ
//Desc: ����nReader�ϵĴſ���.��Ϊ�����ͷ,���ʽ����ͷ��.
procedure THardwareHelper.SetReaderCard(const nReader, nCard: string;
 const nVirtualReader: Boolean);
var nStr: string;
begin
  if Assigned(FReader) then
  begin
    if nVirtualReader then
    begin
      nStr := 'V' + Copy(nReader, 2, Length(nReader) - 1);
      FReader.SetReaderCard(nStr, nCard);

      WriteLog(Format('�������ͷ[ %s ]���Ϳ���[ %s ].',  [nStr, nCard]));
    end else FReader.SetReaderCard(nReader, nCard);
  end;
end;

//Date: 2012-12-16
//Parm: �ſ���
//Desc: ��ȡnCard���һ��ˢ�����ڶ�ͷ
function THardwareHelper.GetReaderLastOn(const nCard: string): string;
var nIdx,nLast: Integer;
begin
  Result := '';
  nLast := -1;

  for nIdx:=Low(FItems) to High(FItems) do
  with FItems[nIdx] do
  begin
    if (FCard <> nCard) and (FCardExt <> nCard) then Continue;
    //match card_no

    if nLast < 0 then nLast := nIdx;
    if FLast >= FItems[nLast].FLast then
    begin
      Result := FID;
      nLast := nIdx;
    end;
  end;
end;

//Desc: ����nFile�����ļ�
procedure THardwareHelper.LoadConfig(const nFile: string);
var i,nIdx,nInt: Integer;
    nXML: TNativeXml;
    nNode,nTP: TXmlNode;
begin
  nXML := TNativeXml.Create;
  try
    nXML.LoadFromFile(nFile);
    nNode := nXML.Root.NodeByName('helper');

    FHostIP := nNode.NodeByName('ip').ValueAsString;
    FHostPort := nNode.NodeByName('port').ValueAsInteger;

    nTP := nNode.FindNode('enable');
    if Assigned(nTP) then
         FConnHelper := nTP.ValueAsString <> 'N'
    else FConnHelper := True;

    nTP := nNode.FindNode('local_udp');
    if Assigned(nTP) then
         FUDPPort := nTP.ValueAsInteger
    else FUDPPort := 5005;

    nNode := nXML.Root.NodeByName('readers');
    nInt := 0;
    SetLength(FItems, nNode.NodeCount);

    for nIdx:=0 to nNode.NodeCount - 1 do
    with nNode.Nodes[nIdx],FItems[nInt] do
    begin
      FCard := '';
      FCardExt := '';

      FLast := 0;
      FOKTime := 0;
      FID := AttributeByName['ID'];

      i := NodeByName('type').ValueAsInteger;
      case i of
       1: FType := rtIn;
       2: FType := rtOut;
       3: FType := rtPound;
       4: FType := rtGate;
       5: FType := rtQueueGate else FType := rtGate;
      end;

      nTP := NodeByName('pound');
      if Assigned(nTP) then
           FPound := nTP.ValueAsString
      else FPound := '';

      nTP := NodeByName('printer');
      if Assigned(nTP) then
           FPrinter := nTP.ValueAsString
      else FPrinter := '';

      nTP := NodeByName('options');
      if Assigned(nTP) then
      begin
        FOptions := TStringList.Create;
        SplitStr(nTP.ValueAsString, FOptions, 0, ';');
      end else FOptions := nil;

      nTP := NodeByName('keeptime');
      if Assigned(nTP) then
      begin
        i := nTP.ValueAsInteger;
        if i < 1 then
             FKeep := 1
        else FKeep := i;
      end else
      begin
        if FType = rtPound then
             FKeep := 20
        else FKeep := 3;
      end;

      Inc(nInt);
    end;
  finally
    nXML.Free;
  end;
end;

//------------------------------------------------------------------------------
constructor THardwareConnector.Create(AOwner: THardwareHelper);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FOwner := AOwner;
  
  FBuffer := TList.Create;
  FWaiter := TWaitObject.Create;
  FWaiter.Interval := 500; //3 * 1000;

  FClient := TIdTCPClient.Create;
  FClient.ReadTimeout := 5 * 1000;

  FServer := TIdUDPServer.Create;
  FServer.OnUDPRead := OnUDPRead;
  FServer.DefaultPort := FOwner.FUDPPort;

  FServer.Active := True;
  //udp server
end;

destructor THardwareConnector.Destroy;
begin
  FClient.Disconnect;
  FClient.Free;

  FServer.Active := False;
  FServer.Free;

  FOwner.ClearBuffer(FBuffer);
  FBuffer.Free;

  FWaiter.Free;
  inherited;
end;

procedure THardwareConnector.StopMe;
begin
  Terminate;
  FWaiter.Wakeup;

  WaitFor;
  Free;
end;

procedure THardwareConnector.WakupMe;
begin
  FWaiter.Wakeup;
end;

procedure THardwareConnector.Execute;
var nIdx: Integer;
begin
  while not Terminated do
  try
    FWaiter.EnterWait;
    if Terminated then Exit;

    if not FOwner.FConnHelper then
    begin
      DoCardAction;
      FOwner.ClearBuffer(FOwner.FBuffData);
      Continue;
    end;

    try
      if not FClient.Connected then
      begin
        FClient.Host := FOwner.FHostIP;
        FClient.Port := FOwner.FHostPort;

        FClient.ConnectTimeout := 5 * 1000;
        FClient.Connect;
      end;
    except
      WriteLog('����Ӳ����������ʧ��.');
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

    DoCardAction;
    //����
  except
    on E:Exception do
    begin
      WriteLog(E.Message);
    end;
  end;
end;

procedure THardwareConnector.DoExuecte;
var nIdx: Integer;
    nBuf,nTmp: TIdBytes;
    //nBase: THHDataBase;
    nPBase: PHHDataBase;
begin
  FClient.Socket.InputBuffer.Clear;
  for nIdx:=FBuffer.Count - 1 downto 0 do
  begin
    nPBase := FBuffer[nIdx];

    if nPBase.FCommand = cHHCmd_OpenDoor then
    begin
      SetLength(nTmp, 0);
      nTmp := ToBytes(PHHOpenDoor(nPBase).FReaderID);
      nPBase.FDataLen := Length(nTmp);

      nBuf := RawToBytes(nPBase^, cSizeHHBase);
      AppendBytes(nBuf, nTmp);
      FClient.Socket.Write(nBuf);
    end;
  end;
end;

//Desc: ����nReader�ĵ�ǰ��ΪnCard
procedure THardwareConnector.SetReaderCard(const nReader, nCard: string);
var nIdx: Integer;
begin
  {$IFDEF DEBUG}
  WriteLog(nReader + ' ::: ' + nCard);
  {$ENDIF}

  for nIdx:=Low(FOwner.FItems) to High(FOwner.FItems) do
  with FOwner.FItems[nIdx] do
  begin
    if CompareText(nReader, FID) = 0 then
    begin
      {$IFDEF DEBUG}
      WriteLog(nReader + ' ::: ƥ��ɹ�.');
      {$ENDIF}

      if FType = rtPound then
      begin
        FLast := GetTickCount;
        //����ͷ��������Ч��ʱ
      end else

      if GetTickCount - FLast <= FKeep * 1000 then
      begin
        Break;
        //��ʱ���ظ�ˢ����Ч
      end;

      FCard := nCard;
      WriteLog(Format('���յ�����: %s,%s', [nReader, nCard]));
      Break;
    end;
  end;
end;

//Desc: ִ�п�Ƭ����
procedure THardwareConnector.DoCardAction;
var nIdx,nNum: Integer;
    nItem: THHReaderItem;
begin
  while True do
  with FOwner do
  begin
    FSyncLock.Enter;
    try
      nNum := -1;

      for nIdx:=Low(FItems) to High(FItems) do
      if (FItems[nIdx].FCard <> '') and (FItems[nIdx].FType <> rtPound) then
      begin
        FItems[nIdx].FLast := GetTickCount + 500;
        //�ظ�ˢ���������,���Ӻ�500ms

        nItem := FItems[nIdx];
        FItems[nIdx].FCard := '';

        {$IFDEF DEBUG}
        WriteLog(nItem.FID + ' ::: �ѱ�ѡ��.');
        {$ENDIF}

        nNum := nIdx;
        Break;
      end;
    finally
      FSyncLock.Leave;
    end;

    if nNum < 0 then Exit;
    //�������
    WriteLog(nItem.FID + ' ::: ��ʼִ��ҵ��.');
    //loged

    if Assigned(FProce) then FProce(nItem);
    if Assigned(FEvent) then FEvent(nItem);

    WriteLog(nItem.FID + ' ::: ҵ�����.');
    //loged
  end;
end;

//Desc: UDP��������
procedure THardwareConnector.OnUDPRead(AThread: TIdUDPListenerThread;
  AData: TIdBytes; ABinding: TIdSocketHandle);
var nStr,nR: string;
    nPos: Integer;
begin
  nStr := BytesToString(AData);
  nPos := Pos('NEWDATA', nStr);
  if nPos < 1 then Exit;

  System.Delete(nStr, nPos, 7);
  nPos := Pos(' ', nStr);
  if nPos < 1 then Exit;

  nR := Copy(nStr, 1, nPos - 1);
  System.Delete(nStr, 1, nPos);
  //reader

  nPos := Pos(' ', nStr);
  if nPos > 1 then
  try
    FOwner.FSyncLock.Enter;
    nStr := Copy(nStr, 1, nPos - 1);
    SetReaderCard(nR, nStr);
  finally
    FOwner.FSyncLock.Leave;
  end;
end;

initialization
  gHardwareHelper := nil;
finalization
  FreeAndNil(gHardwareHelper);
end.
