{*******************************************************************************
  作者: dmzn@163.com 2013-11-23
  描述: 模块工作对象,用于响应框架事件
*******************************************************************************}
unit UEventHardware;

{$I Link.Inc}
interface

uses
  Windows, Classes, UMgrPlug, UBusinessConst, ULibFun,
  UMITConst{$IFDEF HKVDVR}, UMgrCamera{$ENDIF}, UPlugConst;

type
  THardwareWorker = class(TPlugEventWorker)
  public
    class function ModuleInfo: TPlugModuleInfo; override;
    procedure RunSystemObject(const nParam: PPlugRunParameter); override;
    procedure InitSystemObject; override;
    //主程序启动时初始化
    procedure BeforeStartServer; override;
    //服务启动之前调用
    procedure AfterStopServer; override;
    //服务关闭之后调用
  end;

var
  gPlugRunParam: TPlugRunParameter;
  //运行参数

implementation

uses
  SysUtils, USysLoger, UHardBusiness, UMgrTruckProbe, UMgrParam,
  UMgrQueue, UMgrLEDCard, UMgrHardHelper, UMgrRemotePrint, U02NReader,
  UMgrERelay, UMgrCodePrinter, UMgrTTCEM100, UMgrRFID102, UMgrVoiceNet,
  UMgrBasisWeight, UMgrRemoteSnap, USendStatusToDCS, UMgrBXFontCard, UMgrSendCardNo
  {$IFDEF UseERelayPLC} ,UMgrERelayPLC {$ENDIF};

class function THardwareWorker.ModuleInfo: TPlugModuleInfo;
begin
  Result := inherited ModuleInfo;
  with Result do
  begin
    FModuleID := sPlug_ModuleHD;
    FModuleName := '硬件守护';
    FModuleVersion := '2014-09-30';
    FModuleDesc := '提供水泥一卡通发货的硬件处理对象';
    FModuleBuildTime:= Str2DateTime('2014-09-30 15:01:01');
  end;
end;

procedure THardwareWorker.RunSystemObject(const nParam: PPlugRunParameter);
var nStr,nCfg: string;
begin
  gPlugRunParam := nParam^;
  nCfg := gPlugRunParam.FAppPath + 'Hardware\';

  try
    nStr := 'LED';
    gCardManager.TempDir := nCfg + 'Temp\';
    gCardManager.FileName := nCfg + 'LED.xml';

    nStr := '远距读头';
    gHardwareHelper.LoadConfig(nCfg + '900MK.xml');

    nStr := '近距读头';
    g02NReader.LoadConfig(nCfg + 'Readers.xml');

    nStr := '继电器';
    gERelayManager.LoadConfig(nCfg + 'ERelay.xml');

    nStr := '远程打印';
    gRemotePrinter.LoadConfig(nCfg + 'Printer.xml');

    nStr := '网络语音服务';
    if FileExists(nCfg + 'NetVoice.xml') then
    begin
      if not Assigned(gNetVoiceHelper) then
        gNetVoiceHelper := TNetVoiceManager.Create;
      gNetVoiceHelper.LoadConfig(nCfg + 'NetVoice.xml');
    end;

    nStr := '喷码机';
    gCodePrinterManager.LoadConfig(nCfg + 'CodePrinter.xml');

    {$IFDEF HKVDVR}
    nStr := '硬盘录像机';
    gCameraManager.LoadConfig(nCfg + cCameraXML);
    {$ENDIF}

    {$IFDEF HYRFID201}
    nStr := '华益RFID102';
    if not Assigned(gHYReaderManager) then
    begin
      gHYReaderManager := THYReaderManager.Create;
      gHYReaderManager.LoadConfig(nCfg + 'RFID102.xml');
    end;
    {$ENDIF}

    {$IFDEF TTCEM100}
    nStr := '三合一读卡器';
    if not Assigned(gM100ReaderManager) then
    begin
      gM100ReaderManager := TM100ReaderManager.Create;
      gM100ReaderManager.LoadConfig(nCfg + cTTCE_M100_Config);
    end;
    {$ENDIF}

    nStr := '车辆检测器';
    if FileExists(nCfg + 'TruckProber.xml') then
    begin
      gProberManager := TProberManager.Create;
      gProberManager.LoadConfig(nCfg + 'TruckProber.xml');
    end;

    {$IFDEF BasisWeight}
    nStr := '定量装车业务';
    gBasisWeightManager := TBasisWeightManager.Create;
    gBasisWeightManager.LoadConfig(nCfg + 'Tunnels.xml');
    {$ENDIF}

    {$IFDEF SendStatusToDCS}
    nStr := 'DCS数据发送';
    if FileExists(nCfg + 'DcsSender.xml') then
    begin
      gDcsStatusSender := TSenderHelper.Create;
      gDcsStatusSender.LoadConfig(nCfg + 'DcsSender.xml');
    end;
    {$ENDIF}

    {$IFDEF UseERelayPLC}
    nStr := '车检由PLC控制';
    if FileExists(nCfg + 'ERelayPLC.xml') then
    begin
      gERelayManagerPLC := TERelayManager.Create;
      gERelayManagerPLC.LoadConfig(nCfg + 'ERelayPLC.xml');
    end;
    {$ENDIF}

    {$IFDEF RemoteSnap}
    nStr := '海康威视远程抓拍';
    if FileExists(nCfg + 'RemoteSnap.xml') then
    begin
      gHKSnapHelper.LoadConfig(nCfg + 'RemoteSnap.xml');
    end;
    {$ENDIF}

    {$IFDEF FixLoad}
    nStr := '转子秤';
    gSendCardNo.LoadConfig(nCfg + 'PLCController.xml');
    {$ENDIF}

    {$IFDEF UseBXFontLED}
    nStr := '装车道网口小屏';
    if FileExists(nCfg + 'BXFontLED.xml') then
    begin
      gBXFontCardManager := TBXFontCardManager.Create;
      gBXFontCardManager.LoadConfig(nCfg + 'BXFontLED.xml');
    end;
    {$ENDIF}
  except
    on E:Exception do
    begin
      nStr := Format('加载[ %s ]配置文件失败: %s', [nStr, E.Message]);
      gSysLoger.AddLog(nStr);
    end;
  end;
end;

procedure THardwareWorker.InitSystemObject;
begin
  gHardwareHelper := THardwareHelper.Create;
  //远距读头

  if not Assigned(g02NReader) then
    g02NReader := T02NReader.Create;
  //近距读头

  gHardShareData := WhenBusinessMITSharedDataIn;
  //hard monitor share

  {$IFDEF FixLoad}
  gSendCardNo := TReaderHelper.Create;
  {$ENDIF}
end;

procedure THardwareWorker.BeforeStartServer;
begin
  gTruckQueueManager.OnLineLoad := WhenTruckLineChanged;
  gTruckQueueManager.StartQueue(gParamManager.ActiveParam.FDB.FID);
  //truck queue

  gHardwareHelper.OnProce := WhenReaderCardArrived;
  gHardwareHelper.StartRead;
  //long reader

  {$IFDEF HYRFID201}
  if Assigned(gHYReaderManager) then
  begin
    gHYReaderManager.OnCardProc := WhenHYReaderCardArrived;
    gHYReaderManager.StartReader;
  end;
  {$ENDIF}

  g02NReader.OnCardIn := WhenReaderCardIn;
  g02NReader.OnCardOut := WhenReaderCardOut;
  g02NReader.StartReader;
  //near reader
  gERelayManager.ControlStart;
  //erelay

  gRemotePrinter.StartPrinter;
  //printer
  if Assigned(gNetVoiceHelper) then
    gNetVoiceHelper.StartVoice;
  //NetVoice

  gCardManager.StartSender;
  //led display
  {$IFDEF MITTruckProber}
  gProberManager.StartProber;
  {$ENDIF} //truck

  {$IFDEF HKVDVR}
  gCameraManager.OnCameraProc := WhenCaptureFinished;
  gCameraManager.ControlStart;
  //硬盘录像机
  {$ENDIF}

  {$IFDEF TTCEM100}
  if Assigned(gM100ReaderManager) then
  begin
    gM100ReaderManager.OnCardProc := WhenTTCE_M100_ReadCard;
    gM100ReaderManager.StartReader;
  end; //三合一读卡器
  {$ENDIF}

  {$IFDEF BasisWeight}
  //gBasisWeightManager.TunnelManager.OnUserParseWeight := WhenParsePoundWeight;
  gBasisWeightManager.OnStatusChange := WhenBasisWeightStatusChange;
  gBasisWeightManager.StartService;
  {$ENDIF}

  {$IFDEF RemoteSnap}
  gHKSnapHelper.StartSnap;
  //remote snap
  {$ENDIF}

  {$IFDEF SendStatusToDcs}
  if Assigned(gDcsStatusSender) then
    gDcsStatusSender.StartSender;
  //向DCS发数据
  {$ENDIF}

  {$IFDEF UseERelayPLC}
  if Assigned(gERelayManagerPLC) then
    gERelayManagerPLC.StartService;
  //车检由PLC控制
  {$ENDIF}

  {$IFDEF UseBXFontLED}
  gBXFontCardManager.StartService;
  {$ENDIF}

  {$IFDEF FixLoad}
  if Assigned(gSendCardNo) then
    gSendCardNo.StartPrinter;
  //sendcard
  {$ENDIF}
end;

procedure THardwareWorker.AfterStopServer;
begin
  gRemotePrinter.StopPrinter;
  //printer
  if Assigned(gNetVoiceHelper) then
    gNetVoiceHelper.StopVoice;
  //NetVoice
  gERelayManager.ControlStop;
  //erelay

  g02NReader.StopReader;
  g02NReader.OnCardIn := nil;
  g02NReader.OnCardOut := nil;

  gHardwareHelper.StopRead;
  gHardwareHelper.OnProce := nil;
  //reader

  {$IFDEF HYRFID201}
  if Assigned(gHYReaderManager) then
  begin
    gHYReaderManager.StopReader;
    gHYReaderManager.OnCardProc := nil;
  end;
  {$ENDIF}

  gCardManager.StopSender;
  //led

  {$IFDEF MITTruckProber}
  gProberManager.StopProber;
  {$ENDIF} //truck

  {$IFDEF HKVDVR}
  gCameraManager.OnCameraProc := nil;
  gCameraManager.ControlStop;
  //硬盘录像机
  {$ENDIF}

  {$IFDEF TTCEM100}
  if Assigned(gM100ReaderManager) then
  begin
    gM100ReaderManager.StopReader;
    gM100ReaderManager.OnCardProc := nil;
  end; //三合一读卡器
  {$ENDIF}

  gTruckQueueManager.StopQueue;
  //queue

  {$IFDEF BasisWeight}
  gBasisWeightManager.StopService;
  gBasisWeightManager.OnStatusChange := nil;
  {$ENDIF}

  {$IFDEF RemoteSnap}
  gHKSnapHelper.StopSnap;
  //remote snap
  {$ENDIF}
             
  {$IFDEF SendStatusToDCS}
  if Assigned(gDcsStatusSender) then
    gDcsStatusSender.StopSender;
  //向DCS发数据
  {$ENDIF}

  {$IFDEF UseERelayPLC}
  if Assigned(gERelayManagerPLC) then
    gERelayManagerPLC.StopService;
  //车检由PLC控制
  {$ENDIF}

  {$IFDEF RemoteSnap}
  gHKSnapHelper.StopSnap;
  //remote snap
  {$ENDIF}

  {$IFDEF UseBXFontLED}
  gBXFontCardManager.StopService;
  {$ENDIF}

  {$IFDEF FixLoad}
  if Assigned(gSendCardNo) then
    gSendCardNo.StopPrinter;
  //sendcard
  {$ENDIF}
end;

end.
