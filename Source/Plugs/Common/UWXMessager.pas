{*******************************************************************************
  ����: dmzn@163.com 2019-04-04
  ����: ΢����Ϣ��ʱ����
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
    //ӵ����
    FDBConn: PDBWorker;
    //���ݶ���
    FListA,FListB: TStrings;
    //�б����
    FXML: TNativeXml;
    //XML����
    FWaiter: TWaitObject;
    //�ȴ�����
    FSyncLock: TCrossProcWaitObject;
    //ͬ������
  protected
    procedure Execute; override;
    //ִ���߳�
    function SendMessage(var nData: string): Boolean;
    //������Ϣ
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
    procedure SendNow();
    //��������
  end;

var
  gWXMessager: TWXMessager = nil;
  //ȫ��ʹ��

implementation

uses
  UWorkerBussinessWechat, UFormCtrl, ULibFun, USysDB, UMITConst, USysLoger;
  
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
    //������������ִ��

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
        nStr := '����ѯ��[ %d ]������,��ʼ����...';
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
//Parm: ��¼��ʶ;����
//Desc: ����΢������
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

