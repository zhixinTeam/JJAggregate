{*******************************************************************************
  作者: dmzn@163.com 2019-04-04
  描述: 微信消息延时推送
*******************************************************************************}
unit UWXMessager;

{$I Link.inc}
interface

uses
  Windows, Classes, SysUtils, DateUtils, NativeXml, UBusinessConst, UMgrDBConn,
  UBusinessWorker, UBusinessPacker, UWorkerBussinessWechat, UWaitItem,
  ULibFun, USysDB, UMITConst, USysLoger;

type
  TWXMessager = class;
  TWXMessageSender = class(TThread)
  private
    FOwner: TWXMessager;
    //拥有者
    FDBConn: PDBWorker;
    //数据对象
    FListA,FListB: TStrings;
    //列表对象
    FWaiter: TWaitObject;
    //等待对象
    FSyncLock: TCrossProcWaitObject;
    //同步锁定
  protected
    procedure DoExecute;
    procedure Execute; override;
    //执行线程
  public
    constructor Create(AOwner: TWXMessager);
    destructor Destroy; override;
    //创建释放
    procedure Wakeup;
    procedure StopMe;
    //启止线程
  end;

  TWXMessager = class(TObject)
  private
    FSyncTime: Integer;
    //同步次数
    FThread: TWXMessageSender;
    //扫描线程
  public
    constructor Create;
    destructor Destroy; override;
    //创建释放
    procedure StartService;
    procedure StopService;
    //起停上传
  end;

var
  gWXMessager: TWXMessager = nil;
  //全局使用

implementation

procedure WriteLog(const nMsg: string);
begin
  gSysLoger.AddLog(TWXMessager, '微信延时推送', nMsg);
end;

constructor TWXMessager.Create;
begin
  FSyncTime := 3; 
  FThread := nil;
end;

destructor TWXMessager.Destroy;
begin
  StopService;
  inherited;
end;

procedure TWXMessager.StartService;
begin
  if not Assigned(FThread) then
    FThread := TWXMessageSender.Create(Self);
  FThread.Wakeup;
end;

procedure TWXMessager.StopService;
begin
  if Assigned(FThread) then
    FThread.StopMe;
  FThread := nil;
end;

//------------------------------------------------------------------------------
constructor TWXMessageSender.Create(AOwner: TWXMessager);
begin
  inherited Create(False);
  FreeOnTerminate := False;

  FOwner := AOwner;  
  FListA := TStringList.Create;
  FListB := TStringList.Create;

  FWaiter := TWaitObject.Create;
  FWaiter.Interval := 30 * 1000;
  FSyncLock := TCrossProcWaitObject.Create('WXService_Messager');
end;

destructor TWXMessageSender.Destroy;
begin
  FWaiter.Free;
  FSyncLock.Free;

  FListA.Free;
  FListB.Free;
  inherited;
end;

procedure TWXMessageSender.Wakeup;
begin
  FWaiter.Wakeup;
end;

procedure TWXMessageSender.StopMe;
begin
  Terminate;
  FWaiter.Wakeup;

  WaitFor;
  Free;
end;

procedure TWXMessageSender.Execute;
var nStr: string;
begin
  while not Terminated do
  try
    FWaiter.EnterWait;
    if Terminated then Exit;

    if not FSyncLock.SyncLockEnter() then Continue;
    //其它进程正在执行

    FDBConn := nil;
    try
      nStr:= 'Select Top 100 * from %s ' +
             'Where WOM_SyncNum <= %d And WOM_deleted <> ''%s''';
      //nStr:= Format(nStr,[sTable_WebOrderMatch, FOwner.FSyncTime, sFlag_Yes]);

      with gDBConnManager.SQLQuery(nStr, FDBConn) do
      if RecordCount > 0 then
      begin
        nStr := '共查询到[ %d ]条数据,开始推送...';
        WriteLog(Format(nStr, [RecordCount]));
        DoExecute;
      end;
    finally
      gDBConnManager.ReleaseConnection(FDBConn);
      FSyncLock.SyncLockLeave();
    end;
  except
    on E:Exception do
    begin
      WriteLog(E.Message);
    end;
  end;
end;

procedure TWXMessageSender.DoExecute;
begin

end;

initialization
  gWXMessager := nil;
finalization
  FreeAndNil(gWXMessager);
end.

