{*******************************************************************************
  ����: dmzn@163.com 2009-6-25
  ����: ��Ԫģ��

  ��ע: ����ģ������ע������,ֻҪUsesһ�¼���.
*******************************************************************************}
unit UMITModule;

{$I Link.Inc}
interface

uses
  Windows, Forms, Classes, SysUtils, ULibFun, UBusinessWorker, UBusinessPacker,
  UTaskMonitor, UBaseObject, USysShareMem, USysLoger, UMITConst, UMITPacker,
  {$IFDEF HardMon}UEventHardware, UWorkerHardware,{$ENDIF}
  {$IFDEF MicroMsg}UWXMessager, UWorkerBussinessWechat,{$ENDIF}
  UMemDataPool, UObjectList, UMgrDBConn, UMgrParam, UMgrPlug, UMgrChannel,
  UChannelChooser, USAPConnection, UCronTasks, UWorkerBusiness,
  UWorkerBusinessBill;

procedure InitSystemObject(const nMainForm: THandle);
procedure RunSystemObject;
procedure FreeSystemObject;
//��ں���

implementation

uses
  {$IFDEF DEBUG}UFormTest, UPlugConst,{$ENDIF}USysDB;

type
  TMainEventWorker = class(TPlugEventWorker)
  protected
    procedure BeforeStartServer; override;
    procedure AfterStopServer; override;
    {$IFDEF DEBUG}
    procedure GetExtendMenu(const nList: TList); override;
    {$ENDIF}
  public
    class function ModuleInfo: TPlugModuleInfo; override;
  end;

class function TMainEventWorker.ModuleInfo: TPlugModuleInfo;
begin
  Result := inherited ModuleInfo;
  with Result do
  begin
    FModuleID       := '{2497C39C-E1B2-406D-B7AC-9C8DB49C44DF}';
    FModuleName     := '����¼�';
    FModuleAuthor   := 'dmzn@163.com';
    FModuleVersion  := '2013-12-12';
    FModuleDesc     := '����ܶ���,�������ҵ��.';
    FModuleBuildTime:= Str2DateTime('2018-12-02 13:05:00');
  end;
end;

{$IFDEF DEBUG}
procedure TMainEventWorker.GetExtendMenu(const nList: TList);
var nItem: PPlugMenuItem;
begin
  New(nItem);
  nList.Add(nItem);
  nItem.FName := 'Menu_Param_2';

  nItem.FModule := ModuleInfo.FModuleID;
  nItem.FCaption := 'Ӳ������';
  nItem.FFormID := cFI_FormTest1;
  nItem.FDefault := True;
end;
{$ENDIF}

procedure LoadSystemParameters;
var nStr: string;
    nWorker: PDBWorker;
begin
  nWorker := nil;
  try
    nStr := 'Select * From %s Where D_Name=''%s''';
    nStr := Format(nStr, [sTable_SysDict, sFlag_SysParam]);

    with gDBConnManager.SQLQuery(nStr, nWorker),gSysParam do
    if RecordCount > 0 then
    begin
      First;
      while not Eof do
      begin
        nStr := FieldByName('D_Memo').AsString;
        if CompareText(nStr, sFlag_WXSrvURL) = 0 then
        begin
          FWXServiceURL := FieldByName('D_Value').AsString +
                           FieldByName('D_ParamB').AsString;
          //host + path
        end else

        if CompareText(nStr, sFlag_WXFactory) = 0 then
          FWXFactoryID := FieldByName('D_Value').AsString;
        //xxxxx
        
        Next;
      end;
    end;
  finally
    gDBConnManager.ReleaseConnection(nWorker);
  end;
end;

procedure TMainEventWorker.BeforeStartServer;
begin
  {$IFDEF DBPool}
  with gParamManager do
  begin
    gDBConnManager.DefaultConnection := ActiveParam.FDB.FID;
    gDBConnManager.MaxConn := ActiveParam.FDB.FNumWorker;
    LoadSystemParameters();
  end;
  {$ENDIF} //db

  {$IFDEF SAP}
  with gParamManager do
  begin
    gSAPConnectionManager.AddParam(ActiveParam.FSAP^);
    gSAPConnectionManager.PoolSize := ActiveParam.FPerform.FPoolSizeSAP;
  end;
  {$ENDIF}//sap

  {$IFDEF ChannelPool}
  gChannelManager.ChannelMax := 50;
  {$ENDIF} //channel

  {$IFDEF AutoChannel}
  gChannelChoolser.AddChanels(gParamManager.URLRemote.Text);
  gChannelChoolser.StartRefresh;
  {$ENDIF} //channel auto select

  {$IFDEF MicroMsg}
  //gWXMessager.StartService;
  {$ENDIF} //micro message

  gTaskMonitor.StartMon;
  //mon task start

  gTaskManager.Start(gParamManager.ActiveParam.FDB.FID);
  //start cron jobs
end;

procedure TMainEventWorker.AfterStopServer;
begin
  inherited;
  gTaskMonitor.StopMon;
  //stop mon task

  gTaskManager.Stop;
  //stop cron jobs

  {$IFDEF AutoChannel}
  gChannelChoolser.StopRefresh;
  {$ENDIF} //channel

  {$IFDEf SAP}
  gSAPConnectionManager.ClearAllConnection;
  {$ENDIF}//stop sap

  {$IFDEF DBPool}
  gDBConnManager.Disconnection();
  {$ENDIF} //db

  {$IFDEF MicroMsg}
  gWXMessager.StopService;
  {$ENDIF} //micro message
end;

//------------------------------------------------------------------------------
//Desc: ������ݿ����
procedure FillAllDBParam;
var nIdx: Integer;
    nList: TStrings;
begin
  nList := TStringList.Create;
  try
    gParamManager.LoadParam(nList, ptDB);
    for nIdx:=0 to nList.Count - 1 do
      gDBConnManager.AddParam(gParamManager.GetDB(nList[nIdx])^);
    //xxxxx
  finally
    nList.Free;
  end;
end;

//Desc: ��ʼ��ϵͳ����
procedure InitSystemObject(const nMainForm: THandle);
var nParam: TPlugRunParameter;
begin
  gSysLoger := TSysLoger.Create(gPath + sLogDir, sLogSyncLock);
  //��־������
  gCommonObjectManager := TCommonObjectManager.Create;
  //ͨ�ö���״̬����

  gTaskMonitor := TTaskMonitor.Create;
  //��������
  gMemDataManager := TMemDataManager.Create;
  //�ڴ������
  gObjectPoolManager := TObjectPoolManager.Create;
  //���������

  gParamManager := TParamManager.Create(gPath + 'Parameters.xml');
  if gSysParam.FParam <> '' then
    gParamManager.GetParamPack(gSysParam.FParam, True);
  //����������

  TBusinessWorkerSweetHeart.RegWorker(gParamManager.URLLocal.Text);
  //for channel manager

  {$IFDEF DBPool}
  gDBConnManager := TDBConnManager.Create;
  FillAllDBParam;
  {$ENDIF}

  {$IFDEF SAP}
  gSAPConnectionManager := TSAPConnectionManager.Create;
  //sap conn pool
  {$ENDIF}

  {$IFDEF ChannelPool}
  gChannelManager := TChannelManager.Create;
  {$ENDIF}

  {$IFDEF AutoChannel}
  gChannelChoolser := TChannelChoolser.Create('');
  gChannelChoolser.AutoUpdateLocal := False;
  gChannelChoolser.AddChanels(gParamManager.URLRemote.Text);
  {$ENDIF}

  {$IFDEF MicroMsg}
  gWXMessager := TWXMessager.Create;
  {$ENDIF} //micro message

  with nParam do
  begin
    FAppHandle := Application.Handle;
    FMainForm  := nMainForm;
    FAppFlag   := gSysParam.FAppFlag;
    FAppPath   := gPath;

    FLocalIP   := gSysParam.FLocalIP;
    FLocalMAC  := gSysParam.FLocalMAC;
    FLocalName := gSysParam.FLocalName;
    FExtParam  := TStringList.Create;
  end;

  gPlugManager := TPlugManager.Create(nParam);
  with gPlugManager do
  begin
    AddEventWorker(TMainEventWorker.Create);
    {$IFDEF HardMon}
    AddEventWorker(THardwareWorker.Create);
    {$ENDIF}
    LoadPlugsInDirectory(gPath + sPlugDir);

    RefreshUIMenu;
    InitSystemObject;
  end; //���������(�����һ����ʼ��)
end;

//Desc: ����ϵͳ����
procedure RunSystemObject;
var nStr: string;
begin
  gPlugManager.RunSystemObject;
  //�������ʼ����
end;

//Desc: �ͷ�ϵͳ����
procedure FreeSystemObject;
begin
  FreeAndNil(gPlugManager);
  //���������(���һ���ͷ�)

  if Assigned(gProcessMonitorSapMITClient) then
  begin
    gProcessMonitorSapMITClient.StopMonitor(Application.Active);
    FreeAndNil(gProcessMonitorSapMITClient);
  end; //stop monitor
end;

end.
