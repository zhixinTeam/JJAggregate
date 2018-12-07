{*******************************************************************************
  ����: fendou116688@163.com 2016/4/22
  ����: TTCE����һ����������Ԫ
*******************************************************************************}
unit UMgrTTCEM100;

interface

uses
  Windows, Classes, SysUtils, SyncObjs, NativeXml, IdTCPClient, IdGlobal,
  UWaitItem, USysLoger, ULibFun;

const
  cM100Reader_Wait_Short     = 150;
  cM100Reader_Wait_Long      = 2 * 1000;
  cM100Reader_MaxThread      = 10;

  cTTCE_M100_ACK = $06;                      //�϶�Ӧ��
  cTTCE_M100_NAK = $15;                      //��Ӧ��
  cTTCE_M100_ENQ = $05;                      //ִ����������
  cTTCE_M100_EOT = $04;                      //ȡ������
  cTTCE_M100_STX = $02;                      //����ʼ�����̶�Ϊ��0X02
  cTTCE_M100_ETX = $03;                      //����������̶�Ϊ��0x03
  cTTCE_M100_Success = 'P';                  //=0x50����ʾ����ִ�гɹ�
  cTTCE_M100_Failure = 'N';                  //=0x4E����ʾ����ִ��ʧ��

  cTTCE_M100_GetSiteErr = $FF;               //��ȡ��Ƭλ��ʧ��
  cTTCE_M100_Config = 'TTCEM100.XML';

type
  PTTCE_M100_Send = ^TTTCE_M100_Send;
  TTTCE_M100_Send = record
    FSTX   : Char;                           //����ʼ�����̶�Ϊ��0X02
    FLen   : Integer;                        //���͵����ݰ��������ȶ����ֽ�
    FCM    : Char;                           //�������
    FPM    : Char;                           //�������
    FSE_DATAB : string;                      //���͵����ݰ�
    FETX   : Char;                           //����������̶�Ϊ��0x03
    FBCC   : Char;                           //���У��͡����㷽������STX������STX����ETX������ETX��֮���ÿ�����ݽ������
  end;

  PTTCE_M100_Recv = ^TTTCE_M100_Recv;
  TTTCE_M100_Recv = record
    FSTX   : Char;                           //����ʼ�����̶�Ϊ��0X02
    FLen   : Integer;                        //�������ݰ��������ȶ����ֽ�
    FACK   : Char;                           //�����룺'P':�����ɹ�;'N':����ʧ��
    FCM    : Char;                           //�������
    FPM    : Char;                           //�������
    FRE_DATAB : string;                      //���ص����ݰ�,���ߴ������
    FETX   : Char;                           //����������̶�Ϊ��0x03
    FBCC   : Char;                           //���У��͡����㷽������STX������STX����ETX������ETX��֮���ÿ�����ݽ������
  end;

  TM100ReaderVType = (rtInM100, rtOutM100, rtPoundM100, rtGateM100, rtQueueGateM100);
  //�����ͷ����: ��,��,��,��բ,������բ

  PM100ReaderItem = ^TM100ReaderItem;
  TM100ReaderItem = record
    FID     : string;          //��ͷ��ʶ
    FHost   : string;          //��ַ
    FPort   : Integer;         //�˿�

    FCard   : string;          //����
    FTunnel : string;          //ͨ����
    FEnable : Boolean;         //�Ƿ�����
    FLocked : Boolean;         //�Ƿ�����
    FLastActive: Int64;        //�ϴλ

    FVirtual: Boolean;         //�����ͷ
    FVReader: string;          //��ͷ��ʶ
    FVPrinter: string;         //�����ӡ��
    FVHYPrinter: string;       //�����ӡ��
    FVType  : TM100ReaderVType;  //��������

    FKeepOnce: Integer;        //���α���
    FKeepPeer: Boolean;        //����ģʽ
    FKeepLast: Int64;          //�ϴλ
    FClient : TIdTCPClient;    //ͨ����·
  end;

  TM100ReaderThreadType = (ttAll, ttActive);
  //�߳�ģʽ: ȫ��;ֻ���

  TM100ReaderManager = class;
  TM100Reader = class(TThread)
  private
    FOwner: TM100ReaderManager;
    //ӵ����
    FWaiter: TWaitObject;
    //�ȴ�����
    FActiveReader: PM100ReaderItem;
    //��ǰ��ͷ
    FThreadType: TM100ReaderThreadType;
    //�߳�ģʽ
    //FSendItem: TTTCE_M100_Send;
    //FRecvItem: TTTCE_M100_Recv;
    //����&����ָ��
  protected
    procedure DoExecute;
    procedure Execute; override;
    //ִ���߳�
    procedure ScanActiveReader(const nActive: Boolean);
    //ɨ�����
    function ReadCard(const nReader: PM100ReaderItem): Boolean;
    //����Ƭ
    function IsCardValid(const nCard: string): Boolean;
    //У�鿨��
  public
    constructor Create(AOwner: TM100ReaderManager; AType: TM100ReaderThreadType);
    destructor Destroy; override;
    //�����ͷ�
    procedure StopMe;
    //ֹͣ�߳�
  end;

  //----------------------------------------------------------------------------
  THYReaderProc = procedure (const nItem: PM100ReaderItem);
  THYReaderEvent = procedure (const nItem: PM100ReaderItem) of Object;

  TM100ReaderManager = class(TObject)
  private
    FEnable: Boolean;
    //�Ƿ�����
    FMonitorCount: Integer;
    FThreadCount: Integer;
    //�����߳�
    FReaderIndex: Integer;
    FReaderActive: Integer;
    //��ͷ����
    FReaders: TList;
    //��ͷ�б�
    FCardLength: Integer;
    FCardPrefix: TStrings;
    //���ű�ʶ
    FSyncLock: TCriticalSection;
    //ͬ������
    FThreads: array[0..cM100Reader_MaxThread-1] of TM100Reader;
    //��������
    FOnProc: THYReaderProc;
    FOnEvent: THYReaderEvent;
    //�¼�����
  protected
    procedure ClearReaders(const nFree: Boolean);
    //������Դ
    procedure CloseReader(const nReader: PM100ReaderItem);
    //�رն�ͷ

    function SendStandardCmd(var nData: String;
      nClient: TIdTCPClient=nil): Boolean;
    //���ͱ�׼ָ��

    function InitReader(nPM: Word; nClient: TIdTCPClient=nil): Boolean;
    //��ʼ��������
    function CardMoveIn(nPM: Word; nClient: TIdTCPClient=nil): Boolean;
    //����
    function CardMoveOver(nPM: Word; nClient: TIdTCPClient=nil): Boolean;
    //�ƶ���
    function GetCardSite(nClient: TIdTCPClient=nil): Word;
    //��Ƭλ��
    function HasCard(nClient: TIdTCPClient=nil): Boolean;
    //�Ƿ��п��ڶ���λ��
    function ReaderCancel(nClient: TIdTCPClient=nil): Boolean;
    //ȡ������
    function GetCardSerial(nClient: TIdTCPClient=nil): string;
    //��ȡ�����к�
  public
    constructor Create;
    destructor Destroy; override;
    //�����ͷ�
    procedure LoadConfig(const nFile: string);
    //��������
    procedure StartReader;
    procedure StopReader;
    //��ͣ��ͷ
    function DealtWithCard(const nReader: PM100ReaderItem;
      nRetain: Boolean = True): Boolean;
    //����ID��
    property OnCardProc: THYReaderProc read FOnProc write FOnProc;
    property OnCardEvent: THYReaderEvent read FOnEvent write FOnEvent;
    //�������
  end;

var
  gM100ReaderManager: TM100ReaderManager = nil;
  //ȫ��ʹ��
  
implementation

procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(TM100ReaderManager, '����һ������', nEvent);
end;

constructor TM100ReaderManager.Create;
var nIdx: Integer;
begin
  FEnable := False;
  FThreadCount := 1;
  FMonitorCount := 1;  

  for nIdx:=Low(FThreads) to High(FThreads) do
    FThreads[nIdx] := nil;
  //xxxxx

  FCardLength := 0;
  FCardPrefix := TStringList.Create;
  
  FReaders := TList.Create;
  FSyncLock := TCriticalSection.Create;
end;

destructor TM100ReaderManager.Destroy;
begin
  StopReader;
  ClearReaders(True);
  FCardPrefix.Free;

  FSyncLock.Free;
  inherited;
end;

procedure TM100ReaderManager.ClearReaders(const nFree: Boolean);
var nIdx: Integer;
    nItem: PM100ReaderItem;
begin
  for nIdx:=FReaders.Count - 1 downto 0 do
  begin
    nItem := FReaders[nIdx];
    nItem.FClient.Free;
    nItem.FClient := nil;
    
    Dispose(nItem);
    FReaders.Delete(nIdx);
  end;

  if nFree then
    FReaders.Free;
  //xxxxx
end;

procedure TM100ReaderManager.StartReader;
var nIdx,nNum: Integer;
    nType: TM100ReaderThreadType;
begin
  if not FEnable then Exit;
  FReaderIndex := 0;
  FReaderActive := 0;

  nNum := 0;
  //init
  
  for nIdx:=Low(FThreads) to High(FThreads) do
  begin
    if (nNum >= FThreadCount) or
       (nNum > FReaders.Count) then Exit;
    //�̲߳��ܳ���Ԥ��ֵ,�򲻶����ͷ����

    if nNum < FMonitorCount then
         nType := ttAll
    else nType := ttActive;

    if not Assigned(FThreads[nIdx]) then
      FThreads[nIdx] := TM100Reader.Create(Self, nType);
    Inc(nNum);
  end;
end;

procedure TM100ReaderManager.CloseReader(const nReader: PM100ReaderItem);
begin
  if not FEnable then Exit;

  if Assigned(nReader) and Assigned(nReader.FClient) then
  begin
    if not  nReader.FEnable then Exit;
    ReaderCancel(nReader.FClient);
    //ȡ������������
    
    nReader.FClient.Disconnect;
    if Assigned(nReader.FClient.IOHandler) then
      nReader.FClient.IOHandler.InputBuffer.Clear;
    //xxxxx
  end;
end;

procedure TM100ReaderManager.StopReader;
var nIdx: Integer;
begin
  for nIdx:=Low(FThreads) to High(FThreads) do
   if Assigned(FThreads[nIdx]) then
    FThreads[nIdx].Terminate;
  //�����˳����

  for nIdx:=Low(FThreads) to High(FThreads) do
  begin
    if Assigned(FThreads[nIdx]) then
      FThreads[nIdx].StopMe;
    FThreads[nIdx] := nil;
  end;

  FSyncLock.Enter;
  try
    for nIdx:=FReaders.Count - 1 downto 0 do
      CloseReader(FReaders[nIdx]);
    //�رն�ͷ
  finally
    FSyncLock.Leave;
  end;
end;

procedure TM100ReaderManager.LoadConfig(const nFile: string);
var nIdx, i: Integer;
    nXML: TNativeXml;  
    nReader: PM100ReaderItem;
    nRoot,nNode,nTmp: TXmlNode;
begin
  FEnable := False;
  if not FileExists(nFile) then Exit;

  nXML := nil;
  try
    nXML := TNativeXml.Create;
    nXML.LoadFromFile(nFile);

    nRoot := nXML.Root.FindNode('config');
    if Assigned(nRoot) then
    begin
      nNode := nRoot.FindNode('enable');
      if Assigned(nNode) then
        Self.FEnable := nNode.ValueAsString <> 'N';
      //xxxxx

      nNode := nRoot.FindNode('cardlen');
      if Assigned(nNode) then
           FCardLength := nNode.ValueAsInteger
      else FCardLength := 0;

      nNode := nRoot.FindNode('cardprefix');
      if Assigned(nNode) then
           SplitStr(UpperCase(nNode.ValueAsString), FCardPrefix, 0, ',')
      else FCardPrefix.Clear;

      nNode := nRoot.FindNode('thread');
      if Assigned(nNode) then
           FThreadCount := nNode.ValueAsInteger
      else FThreadCount := 1;

      if (FThreadCount < 1) or (FThreadCount > cM100Reader_MaxThread) then
        raise Exception.Create('TTCE_M100 Reader Thread-Num Need Between 1-10.');
      //xxxxx

      nNode := nRoot.FindNode('monitor');
      if Assigned(nNode) then
           FMonitorCount := nNode.ValueAsInteger
      else FMonitorCount := 1;

      if (FMonitorCount < 1) or (FMonitorCount > FThreadCount) then
        raise Exception.Create(Format(
          'TTCE_M100 Reader Monitor-Num Need Between 1-%d.', [FThreadCount]));
      //xxxxx
    end;

    //--------------------------------------------------------------------------
    nRoot := nXML.Root.FindNode('readers');
    if not Assigned(nRoot) then Exit;
    ClearReaders(False);

    for nIdx:=0 to nRoot.NodeCount - 1 do
    begin
      nNode := nRoot.Nodes[nIdx];
      if CompareText(nNode.Name, 'reader') <> 0 then Continue;

      New(nReader);
      FReaders.Add(nReader);

      with nNode,nReader^ do
      begin
        FLocked := False;
        FKeepLast := 0;
        FLastActive := GetTickCount;

        FID := AttributeByName['id'];
        FHost := NodeByName('ip').ValueAsString;
        FPort := NodeByName('port').ValueAsInteger;
        FEnable := NodeByName('enable').ValueAsString <> 'N';

        nTmp := FindNode('tunnel');
        if Assigned(nTmp) then
          FTunnel := nTmp.ValueAsString;
        //ͨ����

        nTmp := FindNode('virtual');
        if Assigned(nTmp) then
        begin
          FVirtual := nTmp.ValueAsString = 'Y';
          FVReader := nTmp.AttributeByName['reader'];
          FVPrinter:= nTmp.AttributeByName['printer'];
          FVHYPrinter := nTmp.AttributeByName['hy_printer'];

          i := StrToIntDef(nTmp.AttributeByName['type'], 0);
          case i of
           1: FVType := rtInM100;
           2: FVType := rtOutM100;
           3: FVType := rtPoundM100;
           4: FVType := rtGateM100;
           5: FVType := rtQueueGateM100 else FVType := rtGateM100;
          end;
        end else
        begin
          FVirtual := False;
          //Ĭ�ϲ�����
        end;

        nTmp := FindNode('keeponce');
        if Assigned(nTmp) then
        begin
          FKeepOnce := nTmp.ValueAsInteger;
          FKeepPeer := nTmp.AttributeByName['keeppeer'] = 'Y';
        end else
        begin
          FKeepOnce := 0;
          //Ĭ�ϲ��ϲ�
        end;

        FClient := TIdTCPClient.Create;
        with FClient do
        begin
          Host := FHost;
          Port := FPort;
          ReadTimeout := 3 * 1000;
          ConnectTimeout := 3 * 1000;   
        end;  
      end;
    end;
  finally
    nXML.Free;
  end;
end;


//------------------------------------------------------------------------------
//Date: 2015-02-08
//Parm: �ַ�����Ϣ;�ַ�����
//Desc: �ַ���ת����
function Str2Buf(const nStr: string; var nBuf: TIdBytes): Integer;
var nIdx: Integer;
begin
  Result := Length(nStr);;
  SetLength(nBuf, Result);

  for nIdx:=1 to Result do
    nBuf[nIdx-1] := Ord(nStr[nIdx]);
  //xxxxx
end;

//Date: 2015-07-08
//Parm: Ŀ���ַ���;ԭʼ�ַ�����
//Desc: ����ת�ַ���
function Buf2Str(const nBuf: TIdBytes): string;
var nIdx,nLen: Integer;
begin
  nLen := Length(nBuf);
  SetLength(Result, nLen);

  for nIdx:=1 to nLen do
    Result[nIdx] := Char(nBuf[nIdx-1]);
  //xxxxx
end;

//Date: 2015-12-06
//Parm: �����ƴ�
//Desc: ��ʽ��nBinΪʮ�����ƴ�
function HexStr(const nBin: string): string;
var nIdx,nLen: Integer;
begin
  nLen := Length(nBin);
  SetLength(Result, nLen * 2);

  for nIdx:=1 to nLen do
    StrPCopy(@Result[2*nIdx-1], IntToHex(Ord(nBin[nIdx]), 2));
  //xxxxx
end;

//Date: 2016/4/22
//Parm: 
//Desc: BCC���У���㷨
function CalcStringBCC(const nData: string; const nLen: Integer=-1;
  const nInit: Word=0): Word;
var nIdx, nLenTemp: Integer;
begin
  Result := nInit;

  if nLen < 0 then
       nLenTemp := Length(nData)
  else nLenTemp := nLen;

  for nIdx := 1 to nLenTemp do
    Result := Result xor Ord(nData[nIdx]);
end;

//Date: 2016/4/22
//Parm:
//Desc: ��װ������ָ��
function PackSendData(const nData:PTTCE_M100_Send): string;
var nBCC: Word;
begin
  Result := nData.FSTX +
            Chr(nData.FLen div 256) +
            Chr(nData.FLen mod 256) +
            nData.FCM +
            nData.FPM +
            nData.FSE_DATAB +
            nData.FETX;
  //len addr cmd data

  nBCC := CalcStringBCC(Result);
  Result := Result + Chr(nBCC);
end;

//Date: 2015-07-08
//Parm: Ŀ��ṹ;������
//Desc: ����ͨ��Э�����
function UnPackRecvData(const nItem:PTTCE_M100_Recv; const nData: string): Boolean;
var nInt,nLen: Integer;
    nBCC: Word;
begin
  Result := False;
  nInt := Length(nData);
  if nInt < 1 then Exit;    

  nLen := Ord(nData[2]) * 256 + Ord(nData[3]);
  if nLen <> nInt-5 then Exit;
  //���ݳ��Ȳ���,

  nBCC := CalcStringBCC(nData);
  if nBCC <> 0 then Exit;
  //BCC error

  with nItem^ do
  begin
    FSTX     := nData[1];
    FLen     := nLen;

    FACK     := nData[4];
    FCM      := nData[5];
    FPM      := nData[6];

    FRE_DATAB:= Copy(nData, 7, nLen-3);
    FETX     := nData[nLen + 4];

    Result   := FACK = cTTCE_M100_Success;
    //correct command
  end;
end;

//Date: 2016/4/23
//Parm: 
//Desc: ���Ͷ�����ָ��
function TM100ReaderManager.SendStandardCmd(var nData: String;
  nClient: TIdTCPClient): Boolean;
var nLen: Integer;
    nByteBuf: TIdBytes;
    nStr, nSend: string;
begin
  Result := False;
  if not Assigned(nClient) then Exit;

  with nClient do
  try
    if Assigned(IOHandler) then
      IOHandler.InputBuffer.Clear;
    //Clear Input Buffer

    if not Connected then Connect;
    //xxxxx

    nSend := nData;
    nLen  := Str2Buf(nSend, nByteBuf);
    Socket.Write(nByteBuf, nLen, 0);
    //Send Command

    nData := '';
    //Init Result

    SetLength(nByteBuf, 0);
    Socket.ReadBytes(nByteBuf, 1, False);
    nStr := Buf2Str(nByteBuf);

    if nStr = Chr(cTTCE_M100_EOT) then
    begin
      nData := 'ȡ����������ɹ�';

      WriteLog(nData);
      Exit;
    end else
    //Cancel Operation

    if nStr = Chr(cTTCE_M100_NAK) then
    begin
      nData := '������У��BCCʧ��';

      WriteLog(nData);
      Exit;
    end;
    //BCC Error

    if nStr <> Chr(cTTCE_M100_ACK) then Exit;
    //If not ACK

    nStr := Chr(cTTCE_M100_ENQ);
    nLen := Str2Buf(nStr, nByteBuf);
    Socket.Write(nByteBuf, nLen, 0);
    //Send ENQ

    while True do
    begin
      if not Connected then Exit;

      SetLength(nByteBuf, 0);
      Socket.ReadBytes(nByteBuf, 1, False);
      nStr := Buf2Str(nByteBuf);
      if nStr = Chr(cTTCE_M100_STX) then Break;
    end;
    // Get STX

    nData := nData + nStr;
    //STX

    SetLength(nByteBuf, 0);
    Socket.ReadBytes(nByteBuf, 2, False);
    nStr := ToHex(nByteBuf);
    nLen := StrToInt('$' + nStr);
    //Get Length

    nData := nData + Buf2Str(nByteBuf);
    //Length

    SetLength(nByteBuf, 0);
    Socket.ReadBytes(nByteBuf, nLen+2, False);
    //Get Data

    nData := nData + Buf2Str(nByteBuf);
    //Data

    nLen := CalcStringBCC(nData, Length(nData), 0);
    if nLen <> 0 then
    begin
      nData := nData + nStr;

      WriteLog('���������͵�����BCCУ��ʧ��');
      Exit;
    end;  
    //Check BCC
    
    Result := True;
  except
    on E: Exception do
    begin
      if Connected then
      begin
        Disconnect;
        if Assigned(IOHandler) then
          IOHandler.InputBuffer.Clear;
      end;

      WriteLog(E.Message);
    end;  
  end;
end;

//Date: 2016/4/22
//Parm: 
//Desc: ��ʼ��������($30����λ�޶���;$31����λ��ǰ�˵���;$32����λ����˵���;$33����λ���뿨)
function TM100ReaderManager.InitReader(nPM: Word; nClient: TIdTCPClient): Boolean;
var nCmd: string;
    nSendItem: TTTCE_M100_Send;
    nRecvItem: TTTCE_M100_Recv;
begin
  Result := False;
  //Init Result

  with nSendItem do
  begin
    FSTX := Chr(cTTCE_M100_STX);
    FETX := Chr(cTTCE_M100_ETX);
    FCM  := Chr($30);
    FPM  := Chr(nPM);
    FSE_DATAB:= '';
    FLen := 2 + Length(FSE_DATAB);
  end;

  nCmd := PackSendData(@nSendItem);
  if not SendStandardCmd(nCmd, nClient) then Exit;

  Result := UnPackRecvData(@nRecvItem, nCmd);
end;  

//Date: 2016/4/22
//Parm:
//Desc: ����($30���ȴ���ʽǰ����;$31���ſ��ȴ���ʽǰ����;$32���ȴ���ʽ�����;
//      $33����ֹ����;$34������ǰ����;$35���ſ���������)
function TM100ReaderManager.CardMoveIn(nPM: Word; nClient: TIdTCPClient): Boolean;
var nCmd: string;
    nSendItem: TTTCE_M100_Send;
    nRecvItem: TTTCE_M100_Recv;
begin
  Result := False;
  //Init Result

  with nSendItem do
  begin
    FSTX := Chr(cTTCE_M100_STX);
    FETX := Chr(cTTCE_M100_ETX);
    FCM  := Chr($32);
    FPM  := Chr(nPM);
    FSE_DATAB:= '';
    FLen := 2 + Length(FSE_DATAB);
  end;

  nCmd := PackSendData(@nSendItem);
  if not SendStandardCmd(nCmd, nClient) then Exit;

  Result := UnPackRecvData(@nRecvItem, nCmd);
end;

//Date: 2016/4/22
//Parm:
//Desc: �ƶ���($30������Ƭ�Ƶ��������ڲ�;$31������Ƭ�Ƶ�IC��λ��;$32������Ƭ�Ƶ�ǰ�˼п�λ��;
//      $33������Ƭ�Ƶ���˼п�λ��;$34������Ƭ��ǰ�˵���;$35������Ƭ�Ӻ�˵���)
function TM100ReaderManager.CardMoveOver(nPM: Word; nClient: TIdTCPClient): Boolean;
var nCmd: string;
    nSendItem: TTTCE_M100_Send;
    nRecvItem: TTTCE_M100_Recv;
begin
  Result := False;
  //Init Result

  with nSendItem do
  begin
    FSTX := Chr(cTTCE_M100_STX);
    FETX := Chr(cTTCE_M100_ETX);
    FCM  := Chr($33);
    FPM  := Chr(nPM);
    FSE_DATAB:= '';
    FLen := 2 + Length(FSE_DATAB);
  end;

  nCmd := PackSendData(@nSendItem);
  if not SendStandardCmd(nCmd, nClient) then Exit;

  Result := UnPackRecvData(@nRecvItem, nCmd);
end;

//Date: 2016/4/22
//Parm: 
//Desc: ��ȡ��Ƭλ��
function TM100ReaderManager.GetCardSite(nClient: TIdTCPClient): Word;
var nCmd: string;
    nSendItem: TTTCE_M100_Send;
    nRecvItem: TTTCE_M100_Recv;
begin
  Result := cTTCE_M100_GetSiteErr;
  with nSendItem do
  begin
    FSTX := Chr(cTTCE_M100_STX);
    FETX := Chr(cTTCE_M100_ETX);
    FCM  := Chr($31);
    FPM  := Chr($30);
    FSE_DATAB:= '';
    FLen := 2 + Length(FSE_DATAB);
  end;

  nCmd := PackSendData(@nSendItem);
  if not SendStandardCmd(nCmd, nClient) then Exit;
  if (not UnPackRecvData(@nRecvItem, nCmd)) or (nRecvItem.FRE_DATAB = '') then Exit;

  Result := StrToInt(nRecvItem.FRE_DATAB);
end;

//Date: 2016/4/22
//Parm: 
//Desc: �Ƿ��п��ڶ���λ��
function TM100ReaderManager.HasCard(nClient: TIdTCPClient): Boolean;
var nSite: Integer;
begin
  nSite := GetCardSite(nClient);
  Result := (nSite = 3) or (nSite = 2) or (nSite = 6);
end;  

function TM100ReaderManager.ReaderCancel(nClient: TIdTCPClient): Boolean;
var nCmd :string;
begin
  nCmd := Chr(cTTCE_M100_EOT);
  Result := SendStandardCmd(nCmd, nClient);
end;

//Date: 2012-4-22
//Parm: 16λ��������
//Desc: ��ʽ��nCardΪ��׼����
function ParseCardNO(const nCard: string; const nHex: Boolean): string;
var nInt: Int64;
    nIdx: Integer;
begin
  if nHex then
  begin
    Result := '';
    for nIdx:=Length(nCard) downto 1 do
      Result := Result + IntToHex(Ord(nCard[nIdx]), 2);
    //xxxxx
  end else Result := nCard;

  nInt := StrToInt64('$' + Result);
  Result := IntToStr(nInt);
  Result := StringOfChar('0', 12 - Length(Result)) + Result;
end;

function TM100ReaderManager.GetCardSerial(nClient: TIdTCPClient=nil): string;
var nCmd: string;
    nSendItem: TTTCE_M100_Send;
    nRecvItem: TTTCE_M100_Recv;
begin
  Result := '';
  with nSendItem do
  begin
    FSTX := Chr(cTTCE_M100_STX);
    FETX := Chr(cTTCE_M100_ETX);
    FCM  := Chr($3C);
    FPM  := Chr($31);
    FSE_DATAB:= '';
    FLen := 2 + Length(FSE_DATAB);
  end;

  nCmd := PackSendData(@nSendItem);
  if not SendStandardCmd(nCmd, nClient) then Exit;
  if not UnPackRecvData(@nRecvItem, nCmd) then Exit;

  nCmd := Copy(nRecvItem.FRE_DATAB, 1, 4);
  Result := ParseCardNO(nCmd, True);
  //�����к� 4λ
end;

//Date: 2016/4/23
//Parm: 
//Desc: ҵ����ɺ���ݶ��������ʹ���ſ�
function TM100ReaderManager.DealtWithCard(const nReader: PM100ReaderItem;
  nRetain: Boolean): Boolean;
begin
  if (nReader.FVType = rtOutM100) and nRetain then
         Result := InitReader($32, nReader.FClient)
  else   Result := InitReader($31, nReader.FClient);
end;

//------------------------------------------------------------------------------
constructor TM100Reader.Create(AOwner: TM100ReaderManager;
  AType: TM100ReaderThreadType);
begin
  inherited Create(False);
  FreeOnTerminate := False;

  FOwner := AOwner;
  FThreadType := AType;

  FWaiter := TWaitObject.Create;
  FWaiter.Interval := cM100Reader_Wait_Short;
end;

destructor TM100Reader.Destroy;
begin
  FWaiter.Free;
  inherited;
end;

procedure TM100Reader.StopMe;
begin
  Terminate;
  FWaiter.Wakeup;

  WaitFor;
  Free;
end;

procedure TM100Reader.Execute;
begin
  while not Terminated do
  try
    FWaiter.EnterWait;
    if Terminated then Exit;

    FActiveReader := nil;
    try
      DoExecute;
    finally
      if Assigned(FActiveReader) then
      begin
        FOwner.FSyncLock.Enter;
        FActiveReader.FLocked := False;
        FOwner.FSyncLock.Leave;
      end;
    end;
  except
    on E: Exception do
    begin
      WriteLog(E.Message);
      Sleep(500);
    end;
  end;
end;

//Date: 2015-12-06
//Parm: �&�����ͷ
//Desc: ɨ��nActive��ͷ,�����ô���FActiveReader.
procedure TM100Reader.ScanActiveReader(const nActive: Boolean);
var nIdx: Integer;
    nReader: PM100ReaderItem;
begin
  if nActive then //ɨ����ͷ
  with FOwner do
  begin
    if FReaderActive = 0 then
         nIdx := 1
    else nIdx := 0; //��0��ʼΪ����һ��

    while True do
    begin
      if FReaderActive >= FReaders.Count then
      begin
        FReaderActive := 0;
        Inc(nIdx);

        if nIdx >= 2 then Break;
        //ɨ��һ��,��Ч�˳�
      end;

      nReader := FReaders[FReaderActive];
      Inc(FReaderActive);
      if nReader.FLocked or (not nReader.FEnable) then Continue;

      if nReader.FLastActive > 0 then 
      begin
        FActiveReader := nReader;
        FActiveReader.FLocked := True;
        Break;
      end;
    end;
  end else

  with FOwner do //ɨ�費���ͷ
  begin
    if FReaderIndex = 0 then
         nIdx := 1
    else nIdx := 0; //��0��ʼΪ����һ��

    while True do
    begin
      if FReaderIndex >= FReaders.Count then
      begin
        FReaderIndex := 0;
        Inc(nIdx);

        if nIdx >= 2 then Break;
        //ɨ��һ��,��Ч�˳�
      end;

      nReader := FReaders[FReaderIndex];
      Inc(FReaderIndex);
      if nReader.FLocked or (not nReader.FEnable) then Continue;

      if nReader.FLastActive = 0 then 
      begin
        FActiveReader := nReader;
        FActiveReader.FLocked := True;
        Break;
      end;
    end;
  end;
end;

procedure TM100Reader.DoExecute;
begin
  FOwner.FSyncLock.Enter;
  try
    if FThreadType = ttAll then
    begin
      ScanActiveReader(False);
      //����ɨ�費���ͷ

      if not Assigned(FActiveReader) then
        ScanActiveReader(True);
      //����ɨ����
    end else

    if FThreadType = ttActive then //ֻɨ��߳�
    begin
      ScanActiveReader(True);
      //����ɨ����ͷ

      if Assigned(FActiveReader) then
      begin
        FWaiter.Interval := cM100Reader_Wait_Short;
        //�л��ͷ,����
      end else
      begin
        FWaiter.Interval := cM100Reader_Wait_Long;
        //�޻��ͷ,����
        ScanActiveReader(False);
        //����ɨ�費���
      end;
    end;
  finally
    FOwner.FSyncLock.Leave;
  end;

  if Assigned(FActiveReader) and (not Terminated) then
  try
    if ReadCard(FActiveReader) then
    begin
      if FThreadType = ttActive then
        FWaiter.Interval := cM100Reader_Wait_Short;
      FActiveReader.FLastActive := GetTickCount;
    end else
    begin
      if (FActiveReader.FLastActive > 0) and
         (GetTickCount - FActiveReader.FLastActive >= 5 * 1000) then
        FActiveReader.FLastActive := 0;
      //�޿�Ƭʱ,�Զ�תΪ���
    end;
  except
    on E:Exception do
    begin
      FActiveReader.FLastActive := 0;
      //��Ϊ���

      WriteLog(Format('Reader:[ %s:%d ] Msg: %s', [FActiveReader.FHost,
        FActiveReader.FPort, E.Message]));
      //xxxxx

      FOwner.CloseReader(FActiveReader);
      //focus reconnect
    end;
  end;
end;

//Date: 2015-12-07
//Parm: ����
//Desc: ��֤nCard�Ƿ���Ч
function TM100Reader.IsCardValid(const nCard: string): Boolean;
var nIdx: Integer;
begin
  with FOwner do
  begin
    Result := False;
    nIdx := Length(Trim(nCard));
    if (nIdx < 1) or ((FCardLength > 0) and (nIdx < FCardLength)) then Exit;
    //leng verify

    Result := FCardPrefix.Count = 0;
    if Result then Exit;

    for nIdx:=FCardPrefix.Count - 1 downto 0 do
     if Pos(FCardPrefix[nIdx], nCard) = 1 then
     begin
       Result := True;
       Exit;
     end;
  end;
end;

function TM100Reader.ReadCard(const nReader: PM100ReaderItem): Boolean;
var nCard: string;
begin
  Result := False;
  //Init Result

  with FOwner, nReader^ do
  try
    if not FClient.Connected then
    begin
      FClient.Connect;
      InitReader($31, FClient);
    end;
    //��������������,��λ��������Ƭ

    if HasCard(FClient) then
    begin
      nCard := GetCardSerial(FClient);
      if nCard = '' then
      begin
        InitReader($31, FClient);
        Exit;
      end;
      //����ʧ��,��λ���ҵ���
    end else

    begin
      CardMoveIn($34, FClient);
      Exit;
      //���û�п�Ƭ,������������ָ��
    end;

    if (not Terminated) then
    begin
      Result := True;
      //read success
    
      if nReader.FKeepOnce > 0 then
      begin
        if CompareText(nCard, nReader.FCard) = 0 then
        begin
          if GetTickCount - nReader.FKeepLast < nReader.FKeepOnce then
          begin
            if not nReader.FKeepPeer then
              nReader.FKeepLast := GetTickCount;
            Exit;
          end;
        end;

        nReader.FKeepLast := GetTickCount;
        //ͬ������ˢѹ��
      end;

      nReader.FCard := nCard;
      //multi card
    
      if Assigned(FOwner.FOnProc) then
        FOwner.FOnProc(nReader);
      //xxxxx

      if Assigned(FOwner.FOnEvent) then
        FOwner.FOnEvent(nReader);
      //xxxxx
    end;
  except
    on E: Exception do
    begin
      FClient.Disconnect;
      if Assigned(FClient.IOHandler) then
        FClient.IOHandler.InputBuffer.Clear;
      //xxxxx

      WriteLog(E.Message);
    end;
  end;
end;

initialization
  gM100ReaderManager := nil;
finalization
  FreeAndNil(gM100ReaderManager);
end.
