{*******************************************************************************
  ����: dmzn@163.com 2019-04-04
  ����: ΢����Ϣ��ʱ����
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
    //ӵ����
    FDBConn: PDBWorker;
    //���ݶ���
    FListA,FListB: TStrings;
    //�б����
    FWaiter: TWaitObject;
    //�ȴ�����
    FSyncLock: TCrossProcWaitObject;
    //ͬ������
  protected
    procedure DoExecute;
    procedure Execute; override;
    //ִ���߳�
  public
    constructor Create(AOwner: TWXMessager);
    destructor Destroy; override;
    //�����ͷ�
    procedure Wakeup;
    procedure StopMe;
    //��ֹ�߳�
  end;

  TWXMessager = class(TObject)
  private
    FSyncTime: Integer;
    //ͬ������
    FThread: TWXMessageSender;
    //ɨ���߳�
  public
    constructor Create;
    destructor Destroy; override;
    //�����ͷ�
    procedure StartService;
    procedure StopService;
    //��ͣ�ϴ�
  end;

var
  gWXMessager: TWXMessager = nil;
  //ȫ��ʹ��

implementation

procedure WriteLog(const nMsg: string);
begin
  gSysLoger.AddLog(TWXMessager, '΢����ʱ����', nMsg);
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
    //������������ִ��

    FDBConn := nil;
    try
      nStr:= 'Select Top 100 * from %s ' +
             'Where WOM_SyncNum <= %d And WOM_deleted <> ''%s''';
      //nStr:= Format(nStr,[sTable_WebOrderMatch, FOwner.FSyncTime, sFlag_Yes]);

      with gDBConnManager.SQLQuery(nStr, FDBConn) do
      if RecordCount > 0 then
      begin
        nStr := '����ѯ��[ %d ]������,��ʼ����...';
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

