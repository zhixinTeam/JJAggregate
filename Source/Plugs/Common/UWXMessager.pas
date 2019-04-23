{*******************************************************************************
  作者: dmzn@163.com 2019-04-04
  描述: 微信消息延时推送
*******************************************************************************}
unit UWXMessager;

{$I Link.inc}
interface

uses
  Windows, Classes, SysUtils, DateUtils, NativeXml, UBusinessConst, UMgrDBConn,
  UBusinessWorker, UBusinessPacker, UWaitItem;

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
    FXML: TNativeXml;
    //XML解析
    FWaiter: TWaitObject;
    //等待对象
    FSyncLock: TCrossProcWaitObject;
    //同步锁定
  protected
    procedure Execute; override;
    //执行线程
    function SendMessage(var nData: string): Boolean;
    //发送消息
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
    procedure SendNow();
    //立即发送
  end;

var
  gWXMessager: TWXMessager = nil;
  //全局使用

implementation

uses
  UWorkerBussinessWechat, UFormCtrl, ULibFun, USysDB, UMITConst, USysLoger;
  
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

procedure TWXMessager.SendNow;
begin
  if Assigned(FThread) then
    FThread.Wakeup;
  //xxxx
end;

//------------------------------------------------------------------------------
constructor TWXMessageSender.Create(AOwner: TWXMessager);
begin
  inherited Create(False);
  FreeOnTerminate := False;

  FOwner := AOwner;  
  FXML   := TNativeXml.Create;
  FListA := TStringList.Create;
  FListB := TStringList.Create;

  FWaiter := TWaitObject.Create;
  FWaiter.Interval := 10 * 1000;
  FSyncLock := TCrossProcWaitObject.Create('WXService_Messager');
end;

destructor TWXMessageSender.Destroy;
begin
  FWaiter.Free;
  FSyncLock.Free;

  FListA.Free;
  FListB.Free;
  FXML.Free;
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
var nStr,nResult: string;
    nInt: Integer;
begin
  while not Terminated do
  try
    FWaiter.EnterWait;
    if Terminated then Exit;

    if not FSyncLock.SyncLockEnter() then Continue;
    //其它进程正在执行

    FDBConn := nil;
    try
      nStr:= 'Select DateDiff(n,IsNull(L_LastSend,%s-1),%s) as L_LastSend,' +
             'L_Count,L_Data,R_ID from %s ' +
             'Where L_Status=''%s'' And L_Count<%d';
      nStr:= Format(nStr, [sField_SQLServer_Now, sField_SQLServer_Now,
             sTable_WeixinLog, sFlag_No, FOwner.FSyncTime]);
      //xxxxx

      with gDBConnManager.SQLQuery(nStr, FDBConn) do
      begin
        if RecordCount < 1 then Continue;
        FListA.Clear;
        nStr := '共查询到[ %d ]条数据,开始推送...';
        WriteLog(Format(nStr, [RecordCount]));

        First;
        while not Eof do
        begin
          nInt := FieldByName('L_LastSend').AsInteger;
          if nInt >= FieldByName('L_Count').AsInteger * 3 then
          begin
            nResult := FieldByName('L_Data').AsString;
            if SendMessage(nResult) then
                 nStr := sFlag_Yes
            else nStr := sFlag_No;
            
            nStr := MakeSQLByStr([SF('L_Count', 'L_Count+1', sfVal),
              SF('L_LastSend', sField_SQLServer_Now, sfVal),
              SF('L_Status', nStr),
              SF('L_Result', nResult)], sTable_WeixinLog,
              SF('R_ID', FieldByName('R_ID').AsString, sfVal), False);
            FListA.Add(nStr);
          end;

          Next;
        end;
      end;

      for nInt:=FListA.Count-1 downto 0 do
        gDBConnManager.WorkerExec(FDBConn, FListA[nInt]);
      //xxxxx
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

//Date: 2019-04-22
//Parm: 记录标识;数据
//Desc: 发送微信数据
function TWXMessageSender.SendMessage(var nData: string): Boolean;
var nNode: TXmlNode;
begin
  with TBusWorkerBusinessWechat do
    Result := CallRemote('provideInterface', nData, nData);
  if not Result then Exit;

  FXML.ReadFromString(nData);
  nNode := FXML.Root.NodeByNameR('head');

  Result := nNode.NodeByNameR('errcode').ValueAsString = '0';
  nData := nNode.NodeByNameR('errmsg').ValueAsString;
end;

initialization
  gWXMessager := nil;
finalization
  FreeAndNil(gWXMessager);
end.

