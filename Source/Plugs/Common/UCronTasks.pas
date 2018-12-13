{*******************************************************************************
  作者: dmzn@163.com 2018-12-06
  描述: 定时任务

  备注:
  *.监控价格周期的启用 或 关闭.
*******************************************************************************}
unit UCronTasks;

interface

uses
  Windows, Classes, SysUtils, UBusinessWorker, UBusinessPacker, UBusinessConst,
  UMgrDBConn, UWaitItem, ULibFun, USysDB, UMITConst, USysLoger;

type
  TPriceWeekItem = record
    FID        : string;            //周期标识
    FName      : string;            //周期名称
    FDateBegin : TDateTime;         //开始时间
    FDateEnd   : TDateTime;         //结束时间
    FEndUse    : Boolean;           //启用结束(临时价)
    FValid     : Boolean;           //是否生效
  end;
  TPriceWeekItems = array of TPriceWeekItem;

  TTaskManager = class;
  TTaskThread = class(TThread)
  private
    FOwner: TTaskManager;
    //拥有者
    FDB: string;
    FDBConn: PDBWorker;
    //数据对象
    FWorker: TBusinessWorkerBase;
    FPacker: TBusinessPackerBase;
    //业务对象
    FListA,FListB: TStrings;
    //列表对象
    FNumPriceWeek: Integer;
    FLoadPriceWeek: Boolean;
    FWeekItems: TPriceWeekItems;
    //价格周期数据
    FNumNextDay: Int64;
    FNumUpdateZhiKa: Integer;
    //更新纸卡
    FWaiter: TWaitObject;
    //等待对象
    FSyncLock: TCrossProcWaitObject;
    //同步锁定
  protected
    procedure DoCheckPriceWeek;
    procedure DoUpdateZhiKa;
    procedure Execute; override;
    //执行线程
  public
    constructor Create(AOwner: TTaskManager);
    destructor Destroy; override;
    //创建释放
    procedure Wakeup;
    procedure StopMe;
    //启止线程
  end;

  TTaskManager = class(TObject)
  private
    FDB: string;
    //数据标识
    FThread: TTaskThread;
    //扫描线程
  public
    constructor Create;
    destructor Destroy; override;
    //创建释放
    procedure Start(const nDB: string = '');
    procedure Stop;
    //起停任务
    procedure ReloadPriceWeeks;
    //重载价格周期
  end;

var
  gTaskManager: TTaskManager = nil;
  //全局使用

implementation

procedure WriteLog(const nMsg: string);
begin
  gSysLoger.AddLog(TTaskManager, '定时任务管理器', nMsg);
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

//Desc: 重新加载价格周期
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
  FWaiter.Interval := 500;
  //1/2 second

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
begin
  FLoadPriceWeek := False;
  //init data

  FNumNextDay := 0;
  FNumPriceWeek := 0;
  FNumUpdateZhiKa := 0;
  //init counter

  while not Terminated do
  try
    FWaiter.EnterWait;
    if Terminated then Exit;

    Inc(FNumPriceWeek);
    Inc(FNumUpdateZhiKa);
    Dec(FNumNextDay);
    //inc&dec counter

    if FNumPriceWeek >= 2 then
       FNumPriceWeek := 0;
    //价格周期监控: 2次/秒

    if (FNumUpdateZhiKa >= 7200) or (FNumNextDay <= 0) then
      FNumUpdateZhiKa := 0;
    //更新纸卡信息: 1次/小时 或 新一天

    if FNumNextDay <= 0 then
      FNumNextDay := Trunc(((Date() + 1) - Now()) * 24 * 3600 * 2) + 3;
    //距离明天的计数:延迟1秒
    
    if (FNumPriceWeek <> 0) and (FNumUpdateZhiKa <> 0) then
      Continue;
    //无业务可做

    //--------------------------------------------------------------------------
    if not FSyncLock.SyncLockEnter() then Continue;
    //其它进程正在执行

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
          WriteLog(Format('价格周期监控,耗时: %dms.', [nInit]));
        //xxxxx
      end;

      if FNumUpdateZhiKa = 0 then
      begin
        nInit := GetTickCount;
        DoUpdateZhiKa();
        nInit := GetTickCount - nInit;
        
        if nInit > 3 * 1000 then
          WriteLog(Format('更新纸卡状态,耗时: %dms.', [nInit]));
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
//Desc: 打开价格周期
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
      //临时价生效

      nStr := 'Update %s Set W_Valid=''%s'' Where W_NO In (' +
              'Select Top 1 W_NO From %s Where W_Begin<=%s And ' +
              'W_EndUse=''%s'' Order By W_Begin DESC)';
      nStr := Format(nStr, [sTable_PriceWeek, sFlag_Yes, sTable_PriceWeek,
              sField_SQLServer_Now, sFlag_No]);
      gDBConnManager.WorkerExec(FDBConn, nStr);
      //长期价生效

      nStr := 'Update %s Set W_ValidTime=%s Where W_Valid=''%s'' And ' +
              'W_ValidTime is Null';
      nStr := Format(nStr, [sTable_PriceWeek, sField_SQLServer_Now, sFlag_Yes]);
      gDBConnManager.WorkerExec(FDBConn, nStr);
      //更新生效日期

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
    //当前有效 或 即将生效

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
        //临时价格

        for i:=nIdx+1 to High(FWeekItems) do
        begin
          if FWeekItems[i].FEndUse then Continue;
          //临时价格

          FWeekItems[nIdx].FDateEnd := FWeekItems[i].FDateBegin;
          //下一个开始是上一个结束
          Break;
        end;
      end;
    end;

    nStr := '价格周期载入完毕,有效记录[ %d ]笔.';
    WriteLog(Format(nStr, [Length(FWeekItems)]));
  end;

  if Length(FWeekItems) < 1 then Exit;
  //no data
  
  for nIdx:=Low(FWeekItems) to High(FWeekItems) do
  with FWeekItems[nIdx] do
  begin
    if FValid and (FDateEnd <= Now()) then //价格过期
    begin
      nStr := 'Update %s Set W_Valid=''%s'' Where W_NO=''%s''';
      nStr := Format(nStr, [sTable_PriceWeek, sFlag_No, FID]);
      gDBConnManager.WorkerExec(FDBConn, nStr);

      FValid := False;
      nStr := '价格周期[ %s.%s ]已在[ %s ]过期.';
      WriteLog(Format(nStr, [FID, FName, DateTime2Str(Now())]));
    end;

    if (not FValid) and ((FDateBegin <= Now()) and (FDateEnd>Now())) then //价格启用
    begin
      nStr := 'Update %s Set W_Valid=''%s'',W_ValidTime=%s Where W_NO=''%s''';
      nStr := Format(nStr, [sTable_PriceWeek, sFlag_Yes, sField_SQLServer_Now, FID]);
      gDBConnManager.WorkerExec(FDBConn, nStr);

      FValid := True;
      nStr := '价格周期[ %s.%s ]已在[ %s ]生效.';
      WriteLog(Format(nStr, [FID, FName, DateTime2Str(Now())]));
    end;
  end;
end;

//Date: 2018-12-12
//Desc: 更新纸卡状态信息
procedure TTaskThread.DoUpdateZhiKa;
var nStr,nMoney: string;
begin
  nMoney := '';
  nStr := 'Select D_Value From %s Where D_Name=''%s'' And D_Memo=''%s''';
  nStr := Format(nStr, [sTable_SysDict, sFlag_SysParam, sFlag_ZKMinMoney]);

  with gDBConnManager.WorkerQuery(FDBConn, nStr) do
  if RecordCount > 0 then
  begin
    nStr := Fields[0].AsString;
    if IsNumber(nStr, True) and (StrToFloat(nStr) > 0) then
      nMoney := Format(' Or (Z_Money > 0 And Z_Money-Z_MoneyUsed<=%s)', [nStr]);
    //xxxx
  end;

  nStr := 'Update %s Set Z_InValid=''%s'' Where Z_InValid=''%s'' And (' +
          'Z_ValidDays<=%s%s)';
  nStr := Format(nStr, [sTable_ZhiKa, sFlag_Yes, sFlag_No,
          sField_SQLServer_Now, nMoney]);
  gDBConnManager.WorkerExec(FDBConn, nStr);
end;

initialization
  gTaskManager := TTaskManager.Create;
finalization
  FreeAndNil(gTaskManager);
end.
