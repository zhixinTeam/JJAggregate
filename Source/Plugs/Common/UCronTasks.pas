{*******************************************************************************
  ����: dmzn@163.com 2018-12-06
  ����: ��ʱ����

  ��ע:
  *.��ؼ۸����ڵ����� �� �ر�.
*******************************************************************************}
unit UCronTasks;

interface

uses
  Windows, Classes, SysUtils, UBusinessWorker, UBusinessPacker, UBusinessConst,
  UMgrDBConn, UWaitItem, ULibFun, USysDB, UMITConst, USysLoger;

type
  TPriceWeekItem = record
    FID        : string;            //���ڱ�ʶ
    FName      : string;            //��������
    FDateBegin : TDateTime;         //��ʼʱ��
    FDateEnd   : TDateTime;         //����ʱ��
    FEndUse    : Boolean;           //���ý���(��ʱ��)
    FValid     : Boolean;           //�Ƿ���Ч
  end;
  TPriceWeekItems = array of TPriceWeekItem;

  TTaskManager = class;
  TTaskThread = class(TThread)
  private
    FOwner: TTaskManager;
    //ӵ����
    FDB: string;
    FDBConn: PDBWorker;
    //���ݶ���
    FWorker: TBusinessWorkerBase;
    FPacker: TBusinessPackerBase;
    //ҵ�����
    FListA,FListB: TStrings;
    //�б����
    FNumPriceWeek: Integer;
    //��ʱ����
    FLoadPriceWeek: Boolean;
    FWeekItems: TPriceWeekItems;
    //�۸���������
    FWaiter: TWaitObject;
    //�ȴ�����
    FSyncLock: TCrossProcWaitObject;
    //ͬ������
  protected
    procedure DoCheckPriceWeek;
    procedure Execute; override;
    //ִ���߳�
  public
    constructor Create(AOwner: TTaskManager);
    destructor Destroy; override;
    //�����ͷ�
    procedure Wakeup;
    procedure StopMe;
    //��ֹ�߳�
  end;

  TTaskManager = class(TObject)
  private
    FDB: string;
    //���ݱ�ʶ
    FThread: TTaskThread;
    //ɨ���߳�
  public
    constructor Create;
    destructor Destroy; override;
    //�����ͷ�
    procedure Start(const nDB: string = '');
    procedure Stop;
    //��ͣ����
    procedure ReloadPriceWeeks;
    //���ؼ۸�����
  end;

var
  gTaskManager: TTaskManager = nil;
  //ȫ��ʹ��

implementation

procedure WriteLog(const nMsg: string);
begin
  gSysLoger.AddLog(TTaskManager, '��ʱ���������', nMsg);
end;

constructor TTaskManager.Create;
begin
  FThread := nil;
end;

destructor TTaskManager.Destroy;
begin
  Stop;
  inherited;
end;

procedure TTaskManager.Start(const nDB: string);
begin
  if nDB = '' then
  begin
    if Assigned(FThread) then
      FThread.Wakeup;
    //start upload
  end else
  if not Assigned(FThread) then
  begin
    FDB := nDB;
    FThread := TTaskThread.Create(Self);
  end;
end;

procedure TTaskManager.Stop;
begin
  if Assigned(FThread) then
  begin
    FThread.StopMe;
    FThread := nil;
  end;
end;

//Desc: ���¼��ؼ۸�����
procedure TTaskManager.ReloadPriceWeeks;
begin
  with FThread do
  begin
    FLoadPriceWeek := False;
    FNumPriceWeek := 100;
    Wakeup;
  end;
end;

//------------------------------------------------------------------------------
constructor TTaskThread.Create(AOwner: TTaskManager);
begin
  inherited Create(False);
  FreeOnTerminate := False;

  FOwner := AOwner;
  FDB := FOwner.FDB;
  
  FListA := TStringList.Create;
  FListB := TStringList.Create;

  FWaiter := TWaitObject.Create;
  FWaiter.Interval := 100;
  //1/10 second

  FSyncLock := TCrossProcWaitObject.Create('BusMIT_CronTask_Sync');
  //process sync
end;

destructor TTaskThread.Destroy;
begin
  FWaiter.Free;
  FListA.Free;
  FListB.Free;

  FSyncLock.Free;
  inherited;
end;

procedure TTaskThread.Wakeup;
begin
  FWaiter.Wakeup;
end;

procedure TTaskThread.StopMe;
begin
  Terminate;
  FWaiter.Wakeup;

  WaitFor;
  Free;
end;

procedure TTaskThread.Execute;
var nErr: Integer;
    nInit: Int64;
    nStr: string;
begin
  FLoadPriceWeek := False;
  //init data

  FNumPriceWeek := 0;
  //init counter

  while not Terminated do
  try
    FWaiter.EnterWait;
    if Terminated then Exit;

    Inc(FNumPriceWeek);
    //inc counter

    if FNumPriceWeek >= 5 then
       FNumPriceWeek := 0;
    //�۸����ڼ��: 2��/��

    if (FNumPriceWeek <> 0) then
      Continue;
    //��ҵ�����

    //--------------------------------------------------------------------------
    if not FSyncLock.SyncLockEnter() then Continue;
    //������������ִ��

    FDBConn := nil;
    try
      FDBConn := gDBConnManager.GetConnection(FDB, nErr);
      if not Assigned(FDBConn) then Continue;

      FWorker := nil;
      FPacker := nil;

      if FNumPriceWeek = 0 then
      begin
        nInit := GetTickCount;
        DoCheckPriceWeek();

        nInit := GetTickCount - nInit;
        if nInit > 3 * 1000 then
          WriteLog(Format('�۸����ڼ��,��ʱ: %dms.', [nInit]));
        //xxxxx
      end;
    finally
      FSyncLock.SyncLockLeave();
      gDBConnManager.ReleaseConnection(FDBConn);
    end;
  except
    on E:Exception do
    begin
      WriteLog(E.Message);
    end;
  end;
end;

//Date: 2018-12-06
//Desc: �򿪼۸�����
procedure TTaskThread.DoCheckPriceWeek;
var nStr: string;
    i,nIdx: Integer;
begin
  if not FLoadPriceWeek then
  begin
    FLoadPriceWeek := True;
    SetLength(FWeekItems, 0);

    if not FDBConn.FConn.Connected then
      FDBConn.FConn.Connected := True;
    //conn db
    
    FDBConn.FConn.BeginTrans;
    try
      nStr := 'Update %s Set W_Valid=''%s'' Where W_Valid=''%s''';
      nStr := Format(nStr, [sTable_PriceWeek, sFlag_No, sFlag_Yes]);
      gDBConnManager.WorkerExec(FDBConn, nStr); //invalid all first

      nStr := 'Update %s Set W_Valid=''%s'' Where ' +
              'W_Begin<=%s And W_End>%s And W_EndUse=''%s''';
      nStr := Format(nStr, [sTable_PriceWeek, sFlag_Yes,
              sField_SQLServer_Now, sField_SQLServer_Now, sFlag_Yes]);
      gDBConnManager.WorkerExec(FDBConn, nStr);
      //��ʱ����Ч

      nStr := 'Update %s Set W_Valid=''%s'' Where W_NO In (' +
              'Select Top 1 W_NO From %s Where W_Begin<=%s And ' +
              'W_EndUse=''%s'' Order By W_Begin DESC)';
      nStr := Format(nStr, [sTable_PriceWeek, sFlag_Yes, sTable_PriceWeek,
              sField_SQLServer_Now, sFlag_No]);
      gDBConnManager.WorkerExec(FDBConn, nStr);
      //���ڼ���Ч

      nStr := 'Update %s Set W_ValidTime=%s Where W_Valid=''%s'' And ' +
              'W_ValidTime is Null';
      nStr := Format(nStr, [sTable_PriceWeek, sField_SQLServer_Now, sFlag_Yes]);
      gDBConnManager.WorkerExec(FDBConn, nStr);
      //������Ч����

      FDBConn.FConn.CommitTrans;
      //commit
    except
      FDBConn.FConn.RollbackTrans;
      //roll back
      raise;
    end;

    nStr := 'Select W_NO,W_Name,W_Begin,W_End,W_EndUse,W_Valid From %s ' +
            'Where W_Valid=''%s'' Or W_Begin>=%s ' +
            'Order By W_Begin ASC';
    nStr := Format(nStr, [sTable_PriceWeek, sFlag_Yes, sField_SQLServer_Now]);
    //��ǰ��Ч �� ������Ч

    with gDBConnManager.WorkerQuery(FDBConn, nStr) do
    if RecordCount > 0 then
    begin
      SetLength(FWeekItems, RecordCount);
      nIdx := 0;
      First;

      while not Eof do
      begin
        with FWeekItems[nIdx] do
        begin
          FID        := FieldByName('W_NO').AsString;
          FName      := FieldByName('W_Name').AsString;
          FDateBegin := FieldByName('W_Begin').AsDateTime;
          FDateEnd   := FieldByName('W_End').AsDateTime;
          FEndUse    := FieldByName('W_EndUse').AsString = sFlag_Yes;
          FValid     := FieldByName('W_Valid').AsString = sFlag_Yes;
        end;

        Inc(nIdx);
        Next;
      end;

      for nIdx:=Low(FWeekItems) to High(FWeekItems) do
      begin
        if FWeekItems[nIdx].FEndUse then Continue;
        //��ʱ�۸�

        for i:=nIdx+1 to High(FWeekItems) do
        begin
          if FWeekItems[i].FEndUse then Continue;
          //��ʱ�۸�

          FWeekItems[nIdx].FDateEnd := FWeekItems[i].FDateBegin;
          //��һ����ʼ����һ������
          Break;
        end;
      end;
    end;

    nStr := '�۸������������,��Ч��¼[ %d ]��.';
    WriteLog(Format(nStr, [Length(FWeekItems)]));
  end;

  if Length(FWeekItems) < 1 then Exit;
  //no data
  
  for nIdx:=Low(FWeekItems) to High(FWeekItems) do
  with FWeekItems[nIdx] do
  begin
    if FValid and (FDateEnd <= Now()) then //�۸����
    begin
      nStr := 'Update %s Set W_Valid=''%s'' Where W_NO=''%s''';
      nStr := Format(nStr, [sTable_PriceWeek, sFlag_No, FID]);
      gDBConnManager.WorkerExec(FDBConn, nStr);

      FValid := False;
      nStr := '�۸�����[ %s.%s ]����[ %s ]����.';
      WriteLog(Format(nStr, [FID, FName, DateTime2Str(Now())]));
    end;

    if (not FValid) and ((FDateBegin <= Now()) and (FDateEnd>Now())) then //�۸�����
    begin
      nStr := 'Update %s Set W_Valid=''%s'',W_ValidTime=%s Where W_NO=''%s''';
      nStr := Format(nStr, [sTable_PriceWeek, sFlag_Yes, sField_SQLServer_Now, FID]);
      gDBConnManager.WorkerExec(FDBConn, nStr);

      FValid := True;
      nStr := '�۸�����[ %s.%s ]����[ %s ]��Ч.';
      WriteLog(Format(nStr, [FID, FName, DateTime2Str(Now())]));
    end;
  end;
end;

initialization
  gTaskManager := TTaskManager.Create;
finalization
  FreeAndNil(gTaskManager);
end.
