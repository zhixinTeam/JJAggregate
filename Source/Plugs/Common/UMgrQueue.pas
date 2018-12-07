{*******************************************************************************
  ����: dmzn@163.com 2012-4-11
  ����: ��ɢװ�����й���
*******************************************************************************}
unit UMgrQueue;

{$I Link.Inc}
interface

uses
  Windows, Classes, DB, SysUtils, SyncObjs, UMgrDBConn, UWaitItem, ULibFun,
  USysLoger, USysDB, UMgrRemoteVoice, UMgrVoiceNet;

type
  PLineItem = ^TLineItem;
  TLineItem = record
    FEnable     : Boolean;
    FLineID     : string;
    FName       : string;
    FStockNo    : string;
    FStockName  : string;
    FStockType  : string;
    FStockGroup : string;
    FPeerWeight : Integer;

    FQueueMax   : Integer;
    FIsVIP      : string;
    FIsValid    : Boolean;
    FIndex      : Integer;
    FTrucks     : TList;
    FRealCount  : Integer;     //ʵλ����
  end;//װ����

  PTruckItem = ^TTruckItem;
  TTruckItem = record
    FEnable     : Boolean;
    FCusName    : string;
    FTruck      : string;      //���ƺ�
    FStockNo    : string;      //���Ϻ�
    FStockName  : string;      //Ʒ����
    FStockGroup : string;      //Ʒ�ַ���
    FLine       : string;      //װ����
    FBill       : string;      //������
    FHKBills    : string;      //�Ͽ���
    FInTime     : Int64;       //����ʱ��
    FInFact     : Boolean;     //�Ƿ����
    FInLade     : Boolean;     //�Ƿ����
    FIsVIP      : string;      //��Ȩ��
    FIndex      : Integer;     //��������
    FIsReal     : Boolean;     //����λ

    FValue      : Double;      //�����
    FDai        : Integer;     //����
    FIsBuCha    : Boolean;     //�Ƿ񲹲�
    FNormal     : Integer;     //������װ
    FBuCha      : Integer;     //������װ
    FStarted    : Boolean;     //�Ƿ�����
  end;

  TQueueParam = record
    FLoaded     : Boolean;     //������
    FAutoIn     : Boolean;     //�Զ�����
    FAutoOut    : Boolean;     //�Զ�����
    FInTimeout  : Integer;     //������ʱ
    FNoDaiQueue : Boolean;     //��װ���ö���
    FNoSanQueue : Boolean;     //ɢװ���ö���
    FDelayQueue : Boolean;     //��ʱ�Ŷ�(����)
    FPoundQueue : Boolean;     //��ʱ�Ŷ�(�������ݹ�Ƥʱ��)
    FNetVoice   : Boolean;     //���粥������
    FFobiddenInMul : Boolean;  //��ֹ��ν���
  end;

  TStockMatchItem = record
    FGroup      : string;      //��������
    FMate       : string;      //���Ϻ�
    FName       : string;      //������
    FLineNo     : string;      //ͨ��ר�÷���
  end;

  TTruckQueueManager = class;
  TTruckQueueDBReader = class(TThread)
  private
    FOwner: TTruckQueueManager;
    //ӵ����
    FDBConn: PDBWorker;
    //���ݶ���
    FWaiter: TWaitObject;
    //�ȴ�����
    FParam: TQueueParam;
    //���в���
    FTruckChanged: Boolean;
    FTruckPool: array of TTruckItem;
    //��������
    FMatchItems: array of TStockMatchItem;
    //Ʒ��ӳ��
  protected
    procedure Execute; override;
    //ִ���߳�
    procedure ExecuteSQL(const nList: TStrings);
    //ִ��SQL���
    procedure LoadStockMatck;
    function GetStockMatchGroup(const nStockNo: string;
      const nLineNo: string = ''; const nStockInLine: Boolean = True): string;
    function IsStockMatch(const nStockA, nStockB: string): Boolean; overload;
    function IsStockMatch(nTruck: PTruckItem; nLine: PLineItem): Boolean; overload;
    function IsStockMatch(const nStock: string; nLine: PLineItem): Boolean; overload;
    //Ʒ�ַ���ӳ��
    procedure LoadQueueParam;
    //�����ŶӲ���
    procedure LoadLines;
    //����װ����
    procedure LoadTruckPool;
    procedure LoadTrucks;
    //���복��
    function MakeTruckInLine(const nTimes: Integer): Boolean;
    procedure MakePoolTruckIn(const nIdx: Integer; const nLine: PLineItem);
    //�������
    procedure InvalidTruckOutofQueue;
    function IsLineTruckLeast(const nLine: PLineItem; nIsReal: Boolean): Boolean;
    procedure SortTruckList(const nList: TList);
    //���д���
    function RealTruckInQueue(const nTruck: string): Boolean;
    //������ʵλ����
    function BillInPool(const nBill: string): Integer;
    function TruckFirst(const nTruck: string; const nValue: Double): Boolean;
    //�����ж�
    procedure TruckOutofQueue(const nTruck: string);
    //��������
  public
    constructor Create(AOwner: TTruckQueueManager);
    destructor Destroy; override;
    //�����ͷ�
    procedure Wakup;
    procedure StopMe;
    //��ͣ�߳�
  end;

  TTruckQueueManager = class(TObject)
  private
    FDBName: string;
    //���ݱ�ʶ
    FLines: TList;
    //װ����
    FLineLoaded: Boolean;
    //�Ƿ�������
    FLineChanged: Int64;
    //���б䶯
    FSyncLock: TCriticalSection;
    //ͬ����
    FDBReader: TTruckQueueDBReader;
    //���ݶ�д
    FSQLList: TStrings;
    //SQL���
    FLastQueueVoice: string;
    //��������
  protected
    procedure FreeLine(nItem: PLineItem; nIdx: Integer = -1);
    procedure ClearLines(const nFree: Boolean);
    //�ͷ���Դ
  public
    constructor Create;
    destructor Destroy; override;
    //�����ͷ�
    procedure AddExecuteSQL(const nSQL: string);
    //���SQL
    procedure StartQueue(const nDB: string);
    procedure StopQueue;
    //��ͣ����
    function IsTruckAutoIn: Boolean;
    function IsTruckAutoOut: Boolean;
    function IsDaiQueueClosed: Boolean;
    function IsSanQueueClosed: Boolean;
    function IsDelayQueue: Boolean;
    function IsNetPlayVoice: Boolean;
    function IsFobiddenInMul: Boolean;
    //���в���
    procedure RefreshParam;
    procedure RefreshTrucks(const nLoadLine: Boolean);
    //ˢ�¶���
    function GetLine(const nLineID: string): Integer;
    //װ����
    function TruckInQueue(const nTruck: string): Integer;
    function TruckInLine(const nTruck: string; const nList: TList): Integer;
    function BillInLine(const nBill: string; const nList: TList;
     const nSetStatus: Boolean = False; const nStatus: Boolean = False): Integer;
    //��������
    procedure SendTruckQueueVoice(const nLocked: Boolean);
    //��������
    function GetVoiceTruck(const nSeparator: string;
     const nLocked: Boolean): string;
    //��������
    function GetVoiceTruckEx(const nSeparator: string;
      const nLocked: Boolean): string;
    function GetTruckTunnel(const nTruck: string): string;
    //����ͨ��
    function TruckReInfactFobidden(const nTruck: string): Boolean;
    //��ֹ����
    function StockMatch(const nStockA, nStockB: string): Boolean; overload;
    function StockMatch(nTruck: PTruckItem; nLine: PLineItem): Boolean; overload;
    function StockMatch(const nStock: string; nLine: PLineItem): Boolean; overload;
    //Ʒ�ַ���ӳ��
    property Lines: TList read FLines;
    property LineChanged: Int64 read FLineChanged;
    property SyncLock: TCriticalSection read FSyncLock;
    //�������
  end;

var
  gTruckQueueManager: TTruckQueueManager = nil;
  //ȫ��ʹ��

implementation

//Desc: ��¼��־
procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(TTruckQueueManager, 'װ�����е���', nEvent);
end;

constructor TTruckQueueManager.Create;
begin
  FDBReader := nil;
  FLineLoaded := False;
  FLineChanged := GetTickCount;

  FLastQueueVoice := '';
  FSQLList := TStringList.Create;

  FLines := TList.Create;
  FSyncLock := TCriticalSection.Create;
end;

destructor TTruckQueueManager.Destroy;
begin
  StopQueue;
  ClearLines(True);

  FSyncLock.Free;
  FSQLList.Free;
  inherited;
end;

//Desc: �ͷ�װ����
procedure TTruckQueueManager.FreeLine(nItem: PLineItem; nIdx: Integer);
var i: Integer;
begin
  if Assigned(nItem) then
    nIdx := FLines.IndexOf(nItem);
  if nIdx < 0 then Exit;

  if (not Assigned(nItem)) and (nIdx > -1) then
    nItem := FLines[nIdx];
  if not Assigned(nItem) then Exit;

  for i:=nItem.FTrucks.Count - 1 downto 0 do
  begin
    Dispose(PTruckItem(nItem.FTrucks[i]));
    nItem.FTrucks.Delete(i);
  end;

  nItem.FTrucks.Free;
  Dispose(PLineItem(nItem));
  FLines.Delete(nIdx);
end;

procedure TTruckQueueManager.ClearLines(const nFree: Boolean);
var nIdx: Integer;
begin
  for nIdx:=FLines.Count - 1 downto 0 do
    FreeLine(nil, nIdx);
  if nFree then FreeAndNil(FLines);
end;

procedure TTruckQueueManager.StartQueue(const nDB: string);
begin
  FDBName := nDB;
  if not Assigned(FDBReader) then
    FDBReader := TTruckQueueDBReader.Create(Self);
  FDBReader.Wakup;
end;

procedure TTruckQueueManager.StopQueue;
begin
  if Assigned(FDBReader) then
  try
    FSyncLock.Enter;
    FDBReader.StopMe;
  finally
    FSyncLock.Leave;
  end;

  FDBReader := nil;
end;

//Desc: �����Զ�����
function TTruckQueueManager.IsTruckAutoIn: Boolean;
begin
  Result := False;

  if Assigned(FDBReader) then
  try
    FSyncLock.Enter;
    Result := FDBReader.FParam.FAutoIn;
  finally
    FSyncLock.Leave;
  end;
end;

//Desc: �����Զ�����
function TTruckQueueManager.IsTruckAutoOut: Boolean;
begin
  Result := False;

  if Assigned(FDBReader) then
  try
    FSyncLock.Enter;
    Result := FDBReader.FParam.FAutoOut;
  finally
    FSyncLock.Leave;
  end;
end;

//Desc: �رմ�װ����
function TTruckQueueManager.IsDaiQueueClosed: Boolean;
begin
  Result := False;

  if Assigned(FDBReader) then
  try
    FSyncLock.Enter;
    Result := FDBReader.FParam.FNoDaiQueue;
  finally
    FSyncLock.Leave;
  end;
end;

//Desc: �ر�ɢװ����
function TTruckQueueManager.IsSanQueueClosed: Boolean;
begin
  Result := False;

  if Assigned(FDBReader) then
  try
    FSyncLock.Enter;
    Result := FDBReader.FParam.FNoSanQueue;
  finally
    FSyncLock.Leave;
  end;
end;

//Desc: �Ƿ������ӳٶ���(����ģʽ)
function TTruckQueueManager.IsDelayQueue: Boolean;
begin
  Result := False;

  if Assigned(FDBReader) then
  try
    FSyncLock.Enter;
    Result := FDBReader.FParam.FDelayQueue;
  finally
    FSyncLock.Leave;
  end;
end;

function TTruckQueueManager.IsNetPlayVoice: Boolean;
begin
  Result := False;

  if Assigned(FDBReader) then
  try
    FSyncLock.Enter;
    Result := FDBReader.FParam.FNetVoice;
  finally
    FSyncLock.Leave;
  end;
end;

function TTruckQueueManager.IsFobiddenInMul: Boolean;
begin
  Result := False;

  if Assigned(FDBReader) then
  try
    FSyncLock.Enter;
    Result := FDBReader.FParam.FFobiddenInMul;
  finally
    FSyncLock.Leave;
  end;
end;

//Desc: ���nSQL���
procedure TTruckQueueManager.AddExecuteSQL(const nSQL: string);
begin
  FSyncLock.Enter;
  try
    FSQLList.Add(nSQL);
  finally
    FSyncLock.Leave;
  end;
end;

procedure TTruckQueueManager.RefreshParam;
begin
  if Assigned(FDBReader) then
  begin
    FDBReader.FParam.FLoaded := False;
    //�޸�������
    FDBReader.Wakup;
  end;
end;

procedure TTruckQueueManager.RefreshTrucks(const nLoadLine: Boolean);
begin
  if Assigned(FDBReader) then
  begin
    if nLoadLine then
      FLineLoaded := False;
    FDBReader.Wakup;
  end;
end;

//Date: 2012-4-15
//Parm: װ���߱�ʾ
//Desc: ������ʶΪnLineID��װ����(���������)
function TTruckQueueManager.GetLine(const nLineID: string): Integer;
var nIdx: Integer;
begin
  Result := -1;
              
  for nIdx:=FLines.Count - 1 downto 0 do
  if CompareText(nLineID, PLineItem(FLines[nIdx]).FLineID) = 0 then
  begin
    Result := nIdx;
    Break;
  end;
end;

//Date: 2012-4-14
//Parm: ���ƺ�;�б�
//Desc: �ж�nTruck�Ƿ���nList����������(���������)
function TTruckQueueManager.TruckInLine(const nTruck: string;
  const nList: TList): Integer;
var nIdx: Integer;
begin
  Result := -1;

  for nIdx:=nList.Count - 1 downto 0 do
  if CompareText(nTruck, PTruckItem(nList[nIdx]).FTruck) = 0 then
  begin
    Result := nIdx;
    Break;
  end;
end;

//Date: 2014-4-01
//Parm: ������;�б�;����״̬;��״̬
//Desc: �ж�nBill�Ƿ���nList����������(���������)
function TTruckQueueManager.BillInLine(const nBill: string;
  const nList: TList; const nSetStatus, nStatus: Boolean): Integer;
var nIdx: Integer;
begin
  Result := -1;

  for nIdx:=nList.Count - 1 downto 0 do
  if CompareText(nBill, PTruckItem(nList[nIdx]).FBill) = 0 then
  begin
    Result := nIdx;
    if nSetStatus then
      PTruckItem(nList[nIdx]).FEnable := nStatus;
    Break;
  end;
end;

//Date: 2012-4-14
//Parm: ���ƺ�
//Desc: �ж�nTruck�Ƿ��ڶ�����(���������)
function TTruckQueueManager.TruckInQueue(const nTruck: string): Integer;
var nIdx: Integer;
begin
  Result := -1;

  for nIdx:=FLines.Count - 1 downto 0 do
  if TruckInLine(nTruck, PLineItem(FLines[nIdx]).FTrucks) > -1 then
  begin
    Result := nIdx;
    Break;
  end;
end;

//Desc: ��������δ��������
procedure TTruckQueueManager.SendTruckQueueVoice(const nLocked: Boolean);
var nStr: string;
begin
  if nLocked then SyncLock.Enter;
  try
    nStr := GetVoiceTruck(#9, False);
    if nStr = '' then Exit;
    
    nStr := #9 + nStr + #9;
    //truck flag

    if nStr <> FLastQueueVoice then
    begin
      if IsNetPlayVoice and Assigned(gNetVoiceHelper) then
           gNetVoiceHelper.PlayVoice(nStr)
      else gVoiceHelper.PlayVoice(nStr);
      FLastQueueVoice := nStr;
    end;
  finally
    if nLocked then SyncLock.Leave;
  end;
end;

//Date: 2012-8-24
//Parm: �ָ���;�Ƿ�����
//Desc: ��ȡ���������ĳ����б�
function TTruckQueueManager.GetVoiceTruck(const nSeparator: string;
  const nLocked: Boolean): string;
var i,nIdx: Integer;
    nList: TStrings;
    nLine: PLineItem;
    nTruck: PTruckItem;
begin
  nList := nil;
  if nLocked then SyncLock.Enter;
  try
    Result := '';
    nList := TStringList.Create;

    for nIdx:=0 to Lines.Count - 1 do
    begin
      nLine := Lines[nIdx];
      for i:=0 to nLine.FTrucks.Count - 1 do
      begin
        nTruck := nLine.FTrucks[i];
        if (not nTruck.FInFact) or (IsDelayQueue and (not nTruck.FInLade)) then
        begin
          if nList.IndexOf(nTruck.FTruck) < 0 then //һ���൥ʱ�����ظ�
          begin
            nList.Add(UpperCase(nTruck.FTruck));
            Result := Result + nTruck.FTruck + nSeparator;
          end;
        end;
      end;
    end;

    i := Length(Result);
    if i > 0 then
    begin
      nIdx := Length(nSeparator);
      Result := Copy(Result, 1, i - nIdx);
    end;
  finally
    nList.Free;
    if nLocked then SyncLock.Leave;
  end;
end;

//Date: 2012-8-24
//Parm: �ָ���;�Ƿ�����
//Desc: ��ȡ���������ĳ����б�
function TTruckQueueManager.GetVoiceTruckEx(const nSeparator: string;
  const nLocked: Boolean): string;
var i,nIdx: Integer;
    nList: TStrings;
    nLine: PLineItem;
    nTruck: PTruckItem;
begin
  nList := nil;
  if nLocked then SyncLock.Enter;
  try
    Result := '';
    nList := TStringList.Create;

    for nIdx:=0 to Lines.Count - 1 do
    begin
      nLine := Lines[nIdx];
      for i:=0 to nLine.FTrucks.Count - 1 do
      begin
        nTruck := nLine.FTrucks[i];

        if (not nTruck.FInFact) or (IsDelayQueue and (not nTruck.FInLade)) then
        begin
          if nList.IndexOf(nTruck.FTruck) < 0 then //һ���൥ʱ�����ظ�
          begin
            nList.Add(UpperCase(nTruck.FTruck));
            Result := Result + nTruck.FTruck  + '(' + nLine.FName + ')'
                      + nSeparator;
          end;
        end;
      end;
    end;

    i := Length(Result);
    if i > 0 then
    begin
      nIdx := Length(nSeparator);
      Result := Copy(Result, 1, i - nIdx);
    end;
  finally
    nList.Free;
    if nLocked then SyncLock.Leave;
  end;
end;

//Date: 2012-9-1
//Parm: ���ƺ�
//Desc: ��ȡnTruck���ڵ�ͨ����
function TTruckQueueManager.GetTruckTunnel(const nTruck: string): string;
var nIdx: Integer;
begin
  SyncLock.Enter;
  try
    nIdx := TruckInQueue(nTruck);
    if nIdx < 0 then
         Result := ''
    else Result := PLineItem(FLines[nIdx]).FLineID;

    WriteLog(Format('����[ %s ]ѡ��ͨ��[ %d:%s ]', [nTruck, nIdx, Result]));
    //display log
  finally
    SyncLock.Leave;
  end;
end;

//Date: 2013-1-22
//Parm: ���ƺ�
//Desc: �ж�nTruck�Ƿ�������ν���
function TTruckQueueManager.TruckReInfactFobidden(const nTruck: string): Boolean;
var i,nIdx: Integer;
    nPTruck: PTruckItem;
begin
  Result := True;
  if Assigned(FDBReader) then
  try
    SyncLock.Enter;
    //locked

    for i:=FLines.Count - 1 downto 0 do
    begin
      nIdx := TruckInLine(nTruck, PLineItem(FLines[i]).FTrucks);
      if nIdx < 0 then Continue;

      nPTruck := PLineItem(FLines[i]).FTrucks[nIdx];
      Result := (GetTickCount - nPTruck.FInTime) <
                (FDBReader.FParam.FInTimeout * 60 * 1000);
      //����δ��ʱ

      if not Result then
        WriteLog(Format('����[ %s ]������ʱ,����ֹ.', [nTruck]));
      Exit;
    end;
  finally
    SyncLock.Leave;
  end;
end;

//Desc: �ж�nStockA�Ƿ���nStockB���Ϻ�ƥ��
function TTruckQueueManager.StockMatch(const nStockA,nStockB: string): Boolean;
begin
  Result := False;

  if Assigned(FDBReader) then
  try
    FSyncLock.Enter;
    Result := FDBReader.IsStockMatch(nStockA, nStockB);
  finally
    FSyncLock.Leave;
  end;
end;

//Desc: �ж�nTruck�Ƿ���nLine����ƥ��
function TTruckQueueManager.StockMatch(nTruck: PTruckItem;
  nLine: PLineItem): Boolean;
begin
  Result := False;

  if Assigned(FDBReader) then
  try
    FSyncLock.Enter;
    Result := FDBReader.IsStockMatch(nTruck, nLine);
  finally
    FSyncLock.Leave;
  end;
end;

//Desc: �ж�nStock�Ƿ���nLine����ƥ��
function TTruckQueueManager.StockMatch(const nStock: string;
  nLine: PLineItem): Boolean;
begin
  Result := False;

  if Assigned(FDBReader) then
  try
    FSyncLock.Enter;
    Result := FDBReader.IsStockMatch(nStock, nLine);
  finally
    FSyncLock.Leave;
  end;
end;

//------------------------------------------------------------------------------
constructor TTruckQueueDBReader.Create(AOwner: TTruckQueueManager);
begin
  inherited Create(False);
  FreeOnTerminate := False;

  FOwner := AOwner;
  with FParam do
  begin
    FLoaded := False;
    FInTimeout := 10;
    FAutoIn := False;
    FAutoOut := False;
    
    FNoDaiQueue := False;
    FNoSanQueue := False;
    FDelayQueue := False;

    FNetVoice   := False;
    FFobiddenInMul := False;
  end;

  FWaiter := TWaitObject.Create;
  FWaiter.Interval := 20 * 1000;
end;

destructor TTruckQueueDBReader.Destroy;
begin
  FWaiter.Free;
  inherited;
end;

procedure TTruckQueueDBReader.Wakup;
begin
  FWaiter.Wakeup;
end;

procedure TTruckQueueDBReader.StopMe;
begin
  Terminate;
  FWaiter.Wakeup;

  WaitFor;
  Free;
end;

procedure TTruckQueueDBReader.Execute;
var nErr: Integer;
begin
  while not Terminated do
  try
    FWaiter.EnterWait;
    if Terminated then Exit;

    FDBConn := gDBConnManager.GetConnection(FOwner.FDBName, nErr);
    try
      if not Assigned(FDBConn) then
      begin
        WriteLog('DB connection is null.');
        Continue;
      end;

      if not FDBConn.FConn.Connected then
        FDBConn.FConn.Connected := True;
      //conn db

      FOwner.FSyncLock.Enter;
      try
        ExecuteSQL(FOwner.FSQLList);
        LoadStockMatck;
        //match itme list

        LoadQueueParam;
        FTruckChanged := False;

        LoadLines;
        LoadTrucks;

        if FTruckChanged then
          FOwner.SendTruckQueueVoice(False);
        //voice
      finally
        FOwner.FSyncLock.Leave;
      end;
    finally
      gDBConnManager.ReleaseConnection(FDBConn);
    end;
  except
    on E: Exception do
    begin
      WriteLog(E.Message);
    end;
  end;
end;

//Desc: ִ��SQL���
procedure TTruckQueueDBReader.ExecuteSQL(const nList: TStrings);
var nIdx: Integer;
begin
  for nIdx:=nList.Count - 1 downto 0 do
  begin
    gDBConnManager.WorkerExec(FDBConn, nList[nIdx]);
    nList.Delete(nIdx);
  end;
end;

//Date: 2012-10-21
//Desc: ����Ʒ�ַ���ӳ���
procedure TTruckQueueDBReader.LoadStockMatck;
var nStr: string;
    nIdx: Integer;
    nUseLine: Boolean;
begin
  if FOwner.FLineLoaded then Exit;
  {$IFDEF DEBUG}
  WriteLog('ˢ��Ʒ��ӳ���ϵ.');
  {$ENDIF}

  SetLength(FMatchItems, 0);
  nStr := 'Select * From %s Where M_Status=''%s''';
  nStr := Format(nStr, [sTable_StockMatch, sFlag_Enabled]);

  with gDBConnManager.WorkerQuery(FDBConn, nStr) do
  if RecordCount > 0 then
  begin
    nUseLine := Assigned(FindField('M_LineNo'));
    //�Ƿ�ʹ��ͨ������

    SetLength(FMatchItems, RecordCount);
    nIdx := 0;
    First;

    while not Eof do
    begin
      with FMatchItems[nIdx] do
      begin
        FGroup := FieldByName('M_Group').AsString;
        FMate  := FieldByName('M_ID').AsString;
        FName  := FieldByName('M_Name').AsString;

        if nUseLine then
             FLineNo := FieldByName('M_LineNo').AsString
        else FLineNo := '';
      end;

      Inc(nIdx);
      Next;
    end;
  end;
end;

//Date: 2012-10-21
//Parm: Ʒ�ֱ��;װ����;װ���߰���������
//Desc: ��ȡnStockNo��Ʒ��ӳ���ϵ�����ڵķ���
function TTruckQueueDBReader.GetStockMatchGroup(const nStockNo: string;
  const nLineNo: string; const nStockInLine: Boolean): string;
var nIdx: Integer;
begin
  Result := '';
  if nLineNo <> '' then
  begin
    if nStockInLine then
    begin
      for nIdx:=Low(FMatchItems) to High(FMatchItems) do
       with FMatchItems[nIdx] do
        if (FLineNo = nLineNo) and (FMate = nStockNo) then
        begin
          Result := FGroup;
          Exit;
        end;
      //װ����֧�ָ�Ʒ��
    end else
    begin 
      for nIdx:=Low(FMatchItems) to High(FMatchItems) do
       with FMatchItems[nIdx] do
        if FLineNo = nLineNo then
        begin
          Result := FGroup;
          Exit;
        end;
      //װ����ר�÷���
    end;
  end;

  for nIdx:=Low(FMatchItems) to High(FMatchItems) do
   with FMatchItems[nIdx] do
    if (FLineNo = '') and (FMate = nStockNo) then
    begin
      Result := FGroup;
      Exit;
    end;
  //��ͨ���Ϸ���
end;

//Date: 2012-10-21
//Parm: Ʒ��1;Ʒ��2
//Desc: ���nStockA�Ƿ���nStockB��Ʒ��ƥ��
function TTruckQueueDBReader.IsStockMatch(const nStockA, nStockB: string): Boolean;
var nStr: string;
begin
  Result := nStockA = nStockB;
  if not Result then
  begin
    nStr := GetStockMatchGroup(nStockA);
    Result := (nStr <> '') and (nStr = GetStockMatchGroup(nStockB));
  end;
end;

//Date: 2012-10-21
//Parm: ����;װ����
//Desc: ���nTruck�Ƿ���nLine��Ʒ��ƥ��
function TTruckQueueDBReader.IsStockMatch(nTruck: PTruckItem;
  nLine: PLineItem): Boolean;
begin
  Result := nTruck.FStockNo = nLine.FStockNo;
  if not Result then
  begin
    Result := (nTruck.FStockGroup <> '') and
              (nTruck.FStockGroup = nLine.FStockGroup);
    //xxxxx

    if not Result then
    begin
      Result := (nLine.FStockGroup <> '') and
        (nLine.FStockGroup = GetStockMatchGroup(nTruck.FStockNo, nLine.FLineID));
      //xxxxx
    end;
  end;
end;

//Date: 2012-10-21
//Parm: Ʒ��;װ����
//Desc: ���nStock�Ƿ���nLine��Ʒ��ƥ��
function TTruckQueueDBReader.IsStockMatch(const nStock: string;
  nLine: PLineItem): Boolean;
begin
  Result := nStock = nLine.FStockNo;
  if not Result then
  begin
    Result := (nLine.FStockGroup <> '') and
              (nLine.FStockGroup = GetStockMatchGroup(nStock, nLine.FLineID));
    //xxxxx
  end;
end;

//Desc: �����ŶӲ���
procedure TTruckQueueDBReader.LoadQueueParam;
var nStr: string;
begin
  if FParam.FLoaded then Exit;
  nStr := 'Select D_Value,D_Memo From %s Where D_Name=''%s''';
  nStr := Format(nStr, [sTable_SysDict, sFlag_SysParam]);

  with gDBConnManager.WorkerQuery(FDBConn, nStr) do
  if RecordCount > 0 then
  begin
    FParam.FLoaded := True;
    First;

    while not Eof do
    begin
      if CompareText(Fields[1].AsString, sFlag_AutoIn) = 0 then
        FParam.FAutoIn := Fields[0].AsString = sFlag_Yes;
      //xxxxx

      if CompareText(Fields[1].AsString, sFlag_AutoOut) = 0 then
        FParam.FAutoOut := Fields[0].AsString = sFlag_Yes;
      //xxxxx

      if CompareText(Fields[1].AsString, sFlag_InTimeout) = 0 then
        FParam.FInTimeout := Fields[0].AsInteger;
      //xxxxx

      if CompareText(Fields[1].AsString, sFlag_NoDaiQueue) = 0 then
        FParam.FNoDaiQueue := Fields[0].AsString = sFlag_Yes;
      //xxxxx

      if CompareText(Fields[1].AsString, sFlag_NoSanQueue) = 0 then
        FParam.FNoSanQueue := Fields[0].AsString = sFlag_Yes;
      //xxxxx

      if CompareText(Fields[1].AsString, sFlag_DelayQueue) = 0 then
        FParam.FDelayQueue := Fields[0].AsString = sFlag_Yes;

      if CompareText(Fields[1].AsString, sFlag_PoundQueue) = 0 then
        FParam.FPoundQueue := Fields[0].AsString = sFlag_Yes;

      if CompareText(Fields[1].AsString, sFlag_NetPlayVoice) = 0 then
        FParam.FNetVoice := Fields[0].AsString = sFlag_Yes;
      //NetVoice

      if CompareText(Fields[1].AsString, sFlag_FobiddenInMul) = 0 then
        FParam.FFobiddenInMul := Fields[0].AsString = sFlag_Yes;
      Next;
    end;
  end;
end;

//Desc: ����װ�����б�
procedure TTruckQueueDBReader.LoadLines;
var nStr: string;
    nLine: PLineItem;
    i,nIdx,nInt: Integer;
begin
  if FOwner.FLineLoaded then Exit;
  {$IFDEF DEBUG}
  WriteLog('ˢ��ͨ������');
  {$ENDIF}

  nStr := 'Select * From %s Order By Z_Index ASC';
  nStr := Format(nStr, [sTable_ZTLines]);

  with gDBConnManager.WorkerQuery(FDBConn, nStr),FOwner do
  begin
    FLineLoaded := True;
    if RecordCount < 1 then Exit;

    for nIdx:=FLines.Count - 1 downto 0 do
      PLineItem(FLines[nIdx]).FEnable := False;
    //xxxxx

    FLineChanged := GetTickCount;
    First;

    while not Eof do
    begin
      nStr := FieldByName('Z_ID').AsString;
      nIdx := GetLine(nStr);

      if nIdx < 0 then
      begin
        New(nLine);
        FLines.Add(nLine);
        nLine.FTrucks := TList.Create;
      end else nLine := FLines[nIdx];

      with nLine^ do
      begin
        FEnable     := True;
        FLineID     := FieldByName('Z_ID').AsString;
        FName       := FieldByName('Z_Name').AsString;

        FStockNo    := FieldByName('Z_StockNo').AsString;
        FStockName  := FieldByName('Z_Stock').AsString;
        FStockType  := FieldByName('Z_StockType').AsString;
        FStockGroup := GetStockMatchGroup(FStockNo, FLineID, False);
        FPeerWeight := FieldByName('Z_PeerWeight').AsInteger;

        FQueueMax   := FieldByName('Z_QueueMax').AsInteger;
        FIsVIP      := FieldByName('Z_VIPLine').AsString;
        FIsValid    := FieldByName('Z_Valid').AsString <> sFlag_No;
        FIndex      := FieldByName('Z_Index').AsInteger;
      end;

      Next;
    end;

    for nIdx:=FLines.Count - 1 downto 0 do
    begin
      if not PLineItem(FLines[nIdx]).FEnable then
        FreeLine(nil, nIdx);
      //xxxxx
    end;

    for nIdx:=0 to FLines.Count - 1 do
    begin
      nLine := FLines[nIdx];
      nInt := -1;

      for i:=nIdx+1 to FLines.Count - 1 do
      if PLineItem(FLines[i]).FIndex < nLine.FIndex then
      begin
        nInt := i;
        nLine := FLines[i];
        //find the mininum
      end;

      if nInt > -1 then
      begin
        FLines[nInt] := FLines[nIdx];
        FLines[nIdx] := nLine;
      end;
    end;
  end;
end;

//------------------------------------------------------------------------------
//Date: 2014-03-31
//Parm: ���ƺ�
//Desc: ������ǰ�����������Ƿ���nTruck,��ռʵλ
function TTruckQueueDBReader.RealTruckInQueue(const nTruck: string): Boolean;
var i,j: Integer;
    nPLine: PLineItem;
    nPTruck: PTruckItem;
begin
  Result := False;

  for i:=FOwner.FLines.Count - 1 downto 0 do
  begin
    nPLine := FOwner.FLines[i];
    //line item

    for j:=nPLine.FTrucks.Count - 1 downto 0 do
    begin
      nPTruck := nPLine.FTrucks[j];
      //truck item

      if nPTruck.FIsReal and (CompareText(nTruck, nPTruck.FTruck) = 0) then
      begin
        Result := True;
        Exit;
      end;
    end;
  end;
end;

//Desc: ��ȡ�������е������б�
procedure TTruckQueueDBReader.LoadTruckPool;
var nStr: string;
    nIdx: Integer;
begin
  if (FParam.FPoundQueue) and (FParam.FDelayQueue) then
  begin                                      //���ӳ������ݹ�Ƥʱ���Ŷ� 20131114
    nStr := ' Select * From %s  ' +
            ' Where IsNull(T_Valid,''%s'')<>''%s'' And IsNull(T_PDate,'''')<>'''' ' +
            ' Order By T_Index ASC,T_PDate ASC,T_InTime ASC';
    nStr := Format(nStr, [sTable_ZTTrucks, sFlag_Yes, sFlag_No]);
  end else
  begin
    nStr := 'Select * From %s Where IsNull(T_Valid,''%s'')<>''%s'' $Ext ' +
            'Order By T_Index ASC,T_InFact ASC,T_InTime ASC';
    nStr := Format(nStr, [sTable_ZTTrucks, sFlag_Yes, sFlag_No]);

    {++++++++++++++++++++++++++++++ ע�� +++++++++++++++++++++++++
     1.����ģʽʱ,����ʱ��(T_InFact)Ϊ��,�����Կ���ʱ��(T_InTime)Ϊ׼.
     2.����ģʽʱ,�����ѽ���ʱ��Ϊ׼.
     3.����������, T_InFact��T_InTime���ܵ���˳��.
    -------------------------------------------------------------}

    if FParam.FDelayQueue then
         nStr := MacroValue(nStr, [MI('$Ext', 'And IsNull(T_InFact,'''')<>''''')])
    else nStr := MacroValue(nStr, [MI('$Ext', '')]);
  end;

  with gDBConnManager.WorkerQuery(FDBConn, nStr) do
  begin
    if RecordCount < 1 then
    begin
      SetLength(FTruckPool, 0);
      Exit;
    end;

    SetLength(FTruckPool, RecordCount);
    nIdx := 0;
    First;

    while not Eof do
    begin
      with FTruckPool[nIdx] do
      begin
        FEnable     := True;
        FTruck      := FieldByName('T_Truck').AsString;
        FStockNo    := FieldByName('T_StockNo').AsString;
        FStockGroup := GetStockMatchGroup(FStockNo);

        FLine       := FieldByName('T_Line').AsString;
        FBill       := FieldByName('T_Bill').AsString;
        FHKBills    := FieldByName('T_HKBills').AsString;
        FIsVIP      := FieldByName('T_VIP').AsString;

        FInFact     := FieldByName('T_InFact').AsString <> '';
        FInLade     := FieldByName('T_InLade').AsString <> '';

        FIndex      := FieldByName('T_Index').AsInteger;
        if FIndex < 1 then FIndex := MaxInt;

        FValue      := FieldByName('T_Value').AsFloat;
        FNormal     := FieldByName('T_Normal').AsInteger;
        FBuCha      := FieldByName('T_BuCha').AsInteger;
        FIsBuCha    := FNormal > 0;
        FDai        := 0;
      end;
      
      Inc(nIdx);
      Next;
    end; //�ɽ��������ڶ��г��������
  end;
end;

//Desc: Desc: ����װ������
procedure TTruckQueueDBReader.LoadTrucks;
var i,nIdx: Integer;
begin
  LoadTruckPool;
  //1.���복��������

  InvalidTruckOutofQueue;
  //2.����Ч�����Ƴ�����

  nIdx := 0;
  for i:=Low(FTruckPool) to High(FTruckPool) do
  begin
    if FTruckPool[i].FEnable then
    begin
      Inc(nIdx); Break;
    end;
  end;

  if nIdx < 1 then Exit;
  //3.���������³�������

  for nIdx:=Low(FTruckPool) to High(FTruckPool) do
  with FTruckPool[nIdx] do
  begin
    FIsReal := False;
    if not FEnable then continue;

    FIsReal := TruckFirst(FTruck, FValue);
    //���ԭ���������ó���ʵλ����λ

    if FIsReal then
      FIsReal := not RealTruckInQueue(FTruck);
    //�����ѽ�����Ϊʵλ,�򻺳���ȫΪ��λ,�����ظ�ռλ
  end;
  //4.�趨�����ڳ�����λ���

  MakeTruckInLine(1);
  //��һ��ɨ�趨������
  nIdx := 2;
  //�ڶ���ɨ���ѽ�������

  while True do
  begin
    if not MakeTruckInLine(nIdx) then
    begin
      if nIdx = 2 then
           Inc(nIdx)
      else Break;
    end;
  end;
  //5.�����峵��������������Ķ���

  //for nIdx:=FOwner.FLines.Count - 1 downto 0 do
  //  SortTruckList(PLineItem(FOwner.FLines[nIdx]).FTrucks);
  //6.��������
end;

//Date: 2014-04-01
//Parm: ���ô���
//Desc: ��TruckPool�г�����ҵ���߼�����
function TTruckQueueDBReader.MakeTruckInLine(const nTimes: Integer): Boolean;
var i,nIdx: Integer;
begin
  Result := False;

  //��ͨ���ŵĳ������Ƚ���,�����ͨ��״̬�����ݡ�Ʒ��ƥ��.
  if nTimes = 1 then
  begin
    for nIdx:=0 to FOwner.FLines.Count - 1 do
    with PLineItem(FOwner.Lines[nIdx])^,FOwner do
    begin
      for i:=Low(FTruckPool) to High(FTruckPool) do
      begin
        if not FTruckPool[i].FEnable then Continue;
        //0.�������账��

        if FTruckPool[i].FLine <> FLineID then Continue;
        //1.������ͨ����ʶ�Ų�ƥ��

        if BillInLine(FTruckPool[i].FBill, FTrucks, True) >= 0 then Continue;
        //2.�������Ѿ��ڶ�����

        MakePoolTruckIn(i, FOwner.Lines[nIdx]);
        //�����г�������,ȫ������
        Result := True;
      end;
    end;
  end;

  //���˲�������
  for nIdx:=0 to FOwner.FLines.Count - 1 do
  with PLineItem(FOwner.Lines[nIdx])^,FOwner do
  begin
    if (not FIsValid) or (FIsVIP <> sFlag_TypeShip) then Continue;
    //��������ͨ��
    if not IsLineTruckLeast(FOwner.Lines[nIdx], True) then Continue;
    //�ǳ������ٶ���

    for i:=Low(FTruckPool) to High(FTruckPool) do
    begin
      if not FTruckPool[i].FEnable then Continue;
      //0.�������账��

      if FTruckPool[i].FIsVIP <> sFlag_TypeShip then Continue;
      //1.��������ͨ�����Ͳ�ƥ��

      if not IsStockMatch(FTruckPool[i].FStockNo, FOwner.Lines[nIdx]) then Continue;
      //2.��������ͨ��Ʒ�ֲ�ƥ��

      if BillInLine(FTruckPool[i].FBill, FTrucks, True) >= 0 then Continue;
      //3.�������Ѿ��ڶ�����

      MakePoolTruckIn(i, FOwner.Lines[nIdx]);
      //��ֻ����

      Result := True;
      Break;
    end;
  end;

  //��ͨ��������,�ѽ����Ľ���������
  for nIdx:=0 to FOwner.FLines.Count - 1 do
  with PLineItem(FOwner.Lines[nIdx])^,FOwner do
  begin
    if not FIsValid then Continue;
    //���йر�
    if FIsVIP = sFlag_TypeShip then Continue;
    //����ͨ���Ѵ���

    for i:=Low(FTruckPool) to High(FTruckPool) do
    begin
      if not FTruckPool[i].FEnable then Continue;
      //0.�������账��

      if (nTimes = 2) and (not FTruckPool[i].FInFact) then Continue;
      //0.�ڶ���ɨ��,�ѽ�����������

      if FTruckPool[i].FIsVIP <> FIsVIP then Continue;
      //1.��������ͨ�����Ͳ�ƥ��

      if FTruckPool[i].FIsReal and (FRealCount >= FQueueMax) then Continue;
      //2.ʵλ����,��������

      if not IsStockMatch(FTruckPool[i].FStockNo, FOwner.Lines[nIdx]) then Continue;
      //3.��������ͨ��Ʒ�ֲ�ƥ��

      if not IsLineTruckLeast(FOwner.Lines[nIdx], FTruckPool[i].FIsReal) then
        Continue;
      //4.���г�����������

      if not (FTruckPool[i].FIsReal or RealTruckInQueue(FTruckPool[i].FTruck)) then
        Continue;
      //5.��λ����,û��ʵλ(���)��������

      if BillInLine(FTruckPool[i].FBill, FTrucks, True) >= 0 then Continue;
      //6.�������Ѿ��ڶ�����

      MakePoolTruckIn(i, FOwner.Lines[nIdx]);
      //����������

      Result := True;
      Break;
    end;
  end;
end;

//Date: 2012-4-24
//Parm: ����ӳ�������;����
//Desc: ����������nIdx��������nLine��
procedure TTruckQueueDBReader.MakePoolTruckIn(const nIdx: Integer;
 const nLine: PLineItem);
var nStr: string;
    nTruck: PTruckItem;
begin
  New(nTruck);
  nLine.FTrucks.Add(nTruck);
  nTruck^ := FTruckPool[nIdx];

  nTruck.FInTime := GetTickCount;
  nTruck.FStarted := False;

  FTruckPool[nIdx].FEnable := False;
  FTruckChanged := True;
  FOwner.FLineChanged := GetTickCount;

  if nTruck.FIsReal then
    nLine.FRealCount := nLine.FRealCount + 1;
  //ʵλ��������
  
  if (nTruck.FDai <= 0) and (nLine.FPeerWeight > 0) then
  begin
    nTruck.FDai := Trunc(nTruck.FValue * 1000 / nLine.FPeerWeight);
    //dai number
  end;   

  if (nLine.FPeerWeight > 0) and
     (nTruck.FInFact or (nTruck.FIsVIP = sFlag_TypeShip)) then
  begin
    nStr := 'Update %s Set T_Line=''%s'',T_PeerWeight=%d Where T_Bill=''%s''';
    nStr := Format(nStr, [sTable_ZTTrucks, nLine.FLineID, nLine.FPeerWeight,
                          nTruck.FBill]);
    gDBConnManager.WorkerExec(FDBConn, nStr);
  end;

  if (not nTruck.FInFact) or FParam.FDelayQueue then
  begin
    nStr := 'Update %s Set T_InQueue=%s Where T_Truck=''%s''';
    nStr := Format(nStr, [sTable_ZTTrucks, sField_SQLServer_Now, nTruck.FTruck]);
    gDBConnManager.WorkerExec(FDBConn, nStr);
  end;

  {$IFDEF DEBUG}
  WriteLog(Format('����[ %s ]��[ %s ]��.', [nTruck.FTruck, nLine.FName]));
  {$ENDIF}
end;

//Date: 2012-4-15
//Parm: ���ƺ�;�����
//Desc: nTruck�����Ƿ���Խ����ύ����ΪnValue��Ʒ��
function TTruckQueueDBReader.TruckFirst(const nTruck: string;
  const nValue: Double): Boolean;
var nIdx: Integer;
begin
  Result := True;

  for nIdx:=Low(FTruckPool) to High(FTruckPool) do
  with FTruckPool[nIdx] do
  begin
    if FEnable and (CompareText(nTruck, FTruck) = 0) and
       FloatRelation(FValue, nValue, rtGreater, 1000) then
    begin
      Result := False;
      Exit;
    end; //�����������������     
  end;
end;

//Date: 2012-4-15
//Parm: ���ƺ�
//Desc: ����nTruck�ĳ��ӱ��
procedure TTruckQueueDBReader.TruckOutofQueue(const nTruck: string);
var nStr: string;
begin
  nStr := 'Update %s Set T_Valid=''%s'' Where T_Truck=''%s''';
  nStr := Format(nStr, [sTable_ZTTrucks, sFlag_No, nTruck]);
  gDBConnManager.WorkerExec(FDBConn, nStr);
end;

//Date: 2014-04-01
//Parm: ������
//Desc: ����nBill�ڳ���������е�����
function TTruckQueueDBReader.BillInPool(const nBill: string): Integer;
var nIdx: Integer;
begin
  Result := -1;

  for nIdx:=Low(FTruckPool) to High(FTruckPool) do
  if CompareText(nBill, FTruckPool[nIdx].FBill) = 0 then
  begin
    Result := nIdx;
    Break;
  end;
end;

//Date: 2012-4-15
//Desc: ����Ч����(�ѳ���,������ʱ)�Ƴ�����
procedure TTruckQueueDBReader.InvalidTruckOutofQueue;
var i,j,nIdx: Integer;
    nLine: PLineItem;
    nTruck: PTruckItem;
begin
  with FOwner do
  begin
    for nIdx:=FLines.Count - 1 downto 0 do
     with PLineItem(FLines[nIdx])^ do
      for i:=FTrucks.Count - 1 downto 0 do
       PTruckItem(FTrucks[i]).FEnable := False;
    //xxxxx
  end;

  for nIdx:=FOwner.FLines.Count - 1 downto 0 do
  begin
    nLine := FOwner.FLines[nIdx];
    for i:=nLine.FTrucks.Count - 1 downto 0 do
    begin
      nTruck := nLine.FTrucks[i];
      j := BillInPool(nTruck.FBill);
      if j < 0 then Continue;

      if (FTruckPool[j].FLine <> '') and
         (FTruckPool[j].FLine <> nLine.FLineID) then Continue;
      //����������������λ��

      if CompareText(nTruck.FTruck, FTruckPool[j].FTruck) <> 0 then Continue;
      //�������ĳ��ƺ�

      with FTruckPool[j] do
      begin
        if (FInFact or ((GetTickCount - nTruck.FInTime) <
           FParam.FInTimeout * 60 * 1000)) or (FIsVIP = sFlag_TypeShip) then
        begin
          if FInFact and (not nTruck.FInFact) then
            FTruckChanged := True;
          //xxxxx

          nTruck.FEnable := True;
          nTruck.FInFact := FInFact;
          nTruck.FInLade := FInLade;

          nTruck.FIsVIP := FIsVIP;
          nTruck.FIndex := FIndex;

          nTruck.FValue := FValue;
          if nLine.FPeerWeight>0 then
            nTruck.FDai := Trunc(FValue * 1000 / nLine.FPeerWeight);

          nTruck.FBill  := FBill;
          nTruck.FHKBills := FHKBills;

          if FIsVIP = sFlag_TypeShip then
            nTruck.FInFact := True;
          //������Ϊ����
        end else
        begin
          {$IFDEF DEBUG}
          WriteLog(Format('����[ %s ]����.', [nTruck.FTruck]));
          {$ENDIF}

          TruckOutofQueue(nTruck.FTruck);
          //δ����������ʱ
        end;

        FTruckPool[j].FEnable := False;
      end;
    end;
  end;
  //�ж϶��г����Ƿ���Ч

  for nIdx:=FOwner.FLines.Count - 1 downto 0 do
  begin
    nLine := FOwner.FLines[nIdx];
    nLine.FRealCount := 0;

    for i:=nLine.FTrucks.Count - 1 downto 0 do
    begin
      nTruck := nLine.FTrucks[i];
      if nTruck.FEnable then Continue;

      {$IFDEF DEBUG}
      WriteLog(Format('����[ %s ]��Ч����.', [nTruck.FTruck]));
      {$ENDIF}
      
      Dispose(nTruck);
      nLine.FTrucks.Delete(i);

      FTruckChanged := True;
      FOwner.FLineChanged := GetTickCount;
    end; //������Ч����

    for i:=nLine.FTrucks.Count - 1 downto 0 do
    begin
      nTruck := nLine.FTrucks[i];
      if nTruck.FIsReal then
        nLine.FRealCount := nLine.FRealCount + 1;
      //���¼�������е�ʵλ����
    end;
  end;   
end;

//Date: 2012-4-25
//Parm: װ����;ʵλ����
//Desc: �ж�nLine�Ķ��г�����ΪͬƷ��ͨ��������
function TTruckQueueDBReader.IsLineTruckLeast(const nLine: PLineItem;
  nIsReal: Boolean): Boolean;
var nIdx: Integer;
begin
  Result := True;

  for nIdx:=FOwner.Lines.Count - 1 downto 0 do
  with PLineItem(FOwner.Lines[nIdx])^ do
  begin
    if (not FIsValid) or (FIsVIP <> nLine.FIsVIP) then Continue;
    //1.ͨ����Ч,��ͨ�����Ͳ�ƥ��

    if FRealCount >= FQueueMax then Continue;
    //2.ͨ����������

    if nIsReal and (FRealCount >= nLine.FRealCount) then Continue;
    //3.ʵλ����,�Ա�ʵλ��������

    if (not nIsReal) and (FTrucks.Count >= nLine.FTrucks.Count) then Continue;
    //4.��λ����,�Աȳ����б��С

    if not IsStockMatch(FStockNo, nLine) then Continue;
    //5.����ͨ��Ʒ�ֲ�ƥ��

    Result := False;
    Break;
  end;
end;

//Desc: ��nList���г������Ⱥ�����
procedure TTruckQueueDBReader.SortTruckList(const nList: TList);
var nTruck: PTruckItem;
    i,nIdx,nInt: Integer;
begin
  for nIdx:=0 to nList.Count - 1 do
  begin
    nTruck := nList[nIdx];
    nInt := -1;

    for i:=nIdx+1 to nList.Count - 1 do
    if PTruckItem(nList[i]).FIndex < nTruck.FIndex then
    begin
      nInt := i;
      nTruck := nList[i];
      //find the mininum
    end;

    if nInt > -1 then
    begin
      nList[nInt] := nList[nIdx];
      nList[nIdx] := nTruck;
    end;
  end;
end;

initialization
  gTruckQueueManager := TTruckQueueManager.Create
finalization
  FreeAndNil(gTruckQueueManager);
end.
