{*******************************************************************************
  作者: dmzn@163.com 2012-4-22
  描述: 硬件动作业务
*******************************************************************************}
unit UHardBusiness;

{$I Link.Inc}
interface

uses
  Windows, Classes, Controls, SysUtils, UMgrDBConn, UMgrParam, DB, IdGlobal,
  UBusinessWorker, UBusinessConst, UBusinessPacker, UMgrQueue, UFormCtrl,
  UMgrHardHelper, U02NReader, UMgrERelay, UMgrRemotePrint, UMgrTruckProbe,
  UMgrRFID102, UMgrTTCEM100, UMgrBasisWeight, UMgrPoundTunnels,
  {$IFDEF UseERelayPLC} UMgrERelayPLC, {$ENDIF}
  UMgrRemoteSnap,{$IFDEF HKVDVR}UMgrCamera, {$ENDIF} Graphics, UMITConst, UMgrVoiceNet;

procedure WhenReaderCardArrived(const nReader: THHReaderItem);
procedure WhenHYReaderCardArrived(const nReader: PHYReaderItem);
//有新卡号到达读头
procedure WhenTTCE_M100_ReadCard(const nItem: PM100ReaderItem);
//票箱读卡器
procedure WhenReaderCardIn(const nCard: string; const nHost: PReaderHost);
//现场读头有新卡号
procedure WhenReaderCardOut(const nCard: string; const nHost: PReaderHost);
//现场读头卡号超时
procedure WhenBusinessMITSharedDataIn(const nData: string);
//业务中间件共享数据
function WhenParsePoundWeight(const nPort: PPTPortItem): Boolean;
//地磅数据解析
procedure WhenBasisWeightStatusChange(const nTunnel: PBWTunnel);
//定量装车状态改变
procedure WhenTruckLineChanged(const nTruckLine: TList);
//通道状态切换
function VerifySnapTruck(const nTruck,nBill,nPos,nDept: string;
  var nResult: string): Boolean;
//车牌识别
{$IFDEF HKVDVR}
procedure WhenCaptureFinished(const nPtr: Pointer);
//保存图片
{$ENDIF}
function SaveDBImage(const nDS: TDataSet; const nFieldName: string;
      const nImage: string): Boolean; overload;
function SaveDBImage(const nDS: TDataSet; const nFieldName: string;
  const nImage: TGraphic): Boolean; overload;

implementation

uses
  ULibFun, USysDB, USysLoger, UTaskMonitor, HKVNetSDK;

const
  sPost_In   = 'in';
  sPost_Out  = 'out';

function SaveDBImage(const nDS: TDataSet; const nFieldName: string;
      const nImage: string): Boolean;
var nPic: TPicture;
begin
  Result := False;
  if not FileExists(nImage) then Exit;

  nPic := nil;
  try
    nPic := TPicture.Create;
    nPic.LoadFromFile(nImage);

    SaveDBImage(nDS, nFieldName, nPic.Graphic);
    FreeAndNil(nPic);
  except
    if Assigned(nPic) then nPic.Free;
  end;
end;

function SaveDBImage(const nDS: TDataSet; const nFieldName: string;
  const nImage: TGraphic): Boolean;
var nField: TField;
    nStream: TMemoryStream;
    nBuf: array[1..MAX_PATH] of Char;
begin
  Result := False;
  nField := nDS.FindField(nFieldName);
  if not (Assigned(nField) and (nField is TBlobField)) then Exit;

  nStream := nil;
  try
    if not Assigned(nImage) then
    begin
      nDS.Edit;
      TBlobField(nField).Clear;
      nDS.Post; Result := True; Exit;
    end;
    
    nStream := TMemoryStream.Create;
    nImage.SaveToStream(nStream);
    nStream.Seek(0, soFromEnd);

    FillChar(nBuf, MAX_PATH, #0);
    StrPCopy(@nBuf[1], nImage.ClassName);
    nStream.WriteBuffer(nBuf, MAX_PATH);

    nDS.Edit;
    nStream.Position := 0;
    TBlobField(nField).LoadFromStream(nStream);

    nDS.Post;
    FreeAndNil(nStream);
    Result := True;
  except
    if Assigned(nStream) then nStream.Free;
    if nDS.State = dsEdit then nDS.Cancel;
  end;
end;

//Date: 2014-09-15
//Parm: 命令;数据;参数;输出
//Desc: 本地调用业务对象
function CallBusinessCommand(const nCmd: Integer;
  const nData, nExt: string; const nOut: PWorkerBusinessCommand): Boolean;
var nStr: string;
    nIn: TWorkerBusinessCommand;
    nPacker: TBusinessPackerBase;
    nWorker: TBusinessWorkerBase;
begin
  nPacker := nil;
  nWorker := nil;
  try
    nIn.FCommand := nCmd;
    nIn.FData := nData;
    nIn.FExtParam := nExt;

    nPacker := gBusinessPackerManager.LockPacker(sBus_BusinessCommand);
    nStr := nPacker.PackIn(@nIn);
    nWorker := gBusinessWorkerManager.LockWorker(sBus_BusinessCommand);
    //get worker

    Result := nWorker.WorkActive(nStr);
    if Result then
         nPacker.UnPackOut(nStr, nOut)
    else nOut.FData := nStr;
  finally
    gBusinessPackerManager.RelasePacker(nPacker);
    gBusinessWorkerManager.RelaseWorker(nWorker);
  end;
end;

//Date: 2014-09-05
//Parm: 命令;数据;参数;输出
//Desc: 调用中间件上的销售单据对象
function CallBusinessSaleBill(const nCmd: Integer;
  const nData, nExt: string; const nOut: PWorkerBusinessCommand): Boolean;
var nStr: string;
    nIn: TWorkerBusinessCommand;
    nPacker: TBusinessPackerBase;
    nWorker: TBusinessWorkerBase;
begin
  nPacker := nil;
  nWorker := nil;
  try
    nIn.FCommand := nCmd;
    nIn.FData := nData;
    nIn.FExtParam := nExt;

    nPacker := gBusinessPackerManager.LockPacker(sBus_BusinessCommand);
    nStr := nPacker.PackIn(@nIn);
    nWorker := gBusinessWorkerManager.LockWorker(sBus_BusinessSaleBill);
    //get worker

    Result := nWorker.WorkActive(nStr);
    if Result then
         nPacker.UnPackOut(nStr, nOut)
    else nOut.FData := nStr;
  finally
    gBusinessPackerManager.RelasePacker(nPacker);
    gBusinessWorkerManager.RelaseWorker(nWorker);
  end;
end;

//Date: 2015-08-06
//Parm: 命令;数据;参数;输出
//Desc: 调用中间件上的销售单据对象
function CallBusinessPurchaseOrder(const nCmd: Integer;
  const nData, nExt: string; const nOut: PWorkerBusinessCommand): Boolean;
var nStr: string;
    nIn: TWorkerBusinessCommand;
    nPacker: TBusinessPackerBase;
    nWorker: TBusinessWorkerBase;
begin
  nPacker := nil;
  nWorker := nil;
  try
    nIn.FCommand := nCmd;
    nIn.FData := nData;
    nIn.FExtParam := nExt;

    nPacker := gBusinessPackerManager.LockPacker(sBus_BusinessCommand);
    nStr := nPacker.PackIn(@nIn);
    nWorker := gBusinessWorkerManager.LockWorker(sBus_BusinessPurchaseOrder);
    //get worker

    Result := nWorker.WorkActive(nStr);
    if Result then
         nPacker.UnPackOut(nStr, nOut)
    else nOut.FData := nStr;
  finally
    gBusinessPackerManager.RelasePacker(nPacker);
    gBusinessWorkerManager.RelaseWorker(nWorker);
  end;
end;

//Date: 2014-10-16
//Parm: 命令;数据;参数;输出
//Desc: 调用硬件守护上的业务对象
function CallHardwareCommand(const nCmd: Integer;
  const nData, nExt: string; const nOut: PWorkerBusinessCommand): Boolean;
var nStr: string;
    nIn: TWorkerBusinessCommand;
    nPacker: TBusinessPackerBase;
    nWorker: TBusinessWorkerBase;
begin
  nPacker := nil;
  nWorker := nil;
  try
    nIn.FCommand := nCmd;
    nIn.FData := nData;
    nIn.FExtParam := nExt;

    nPacker := gBusinessPackerManager.LockPacker(sBus_BusinessCommand);
    nStr := nPacker.PackIn(@nIn);
    nWorker := gBusinessWorkerManager.LockWorker(sBus_HardwareCommand);
    //get worker

    Result := nWorker.WorkActive(nStr);
    if Result then
         nPacker.UnPackOut(nStr, nOut)
    else nOut.FData := nStr;
  finally
    gBusinessPackerManager.RelasePacker(nPacker);
    gBusinessWorkerManager.RelaseWorker(nWorker);
  end;
end;

//Date: 2012-3-23
//Parm: 磁卡号;岗位;交货单列表
//Desc: 获取nPost岗位上磁卡为nCard的交货单列表
function GetLadingBills(const nCard,nPost: string;
 var nData: TLadingBillItems): Boolean;
var nOut: TWorkerBusinessCommand;
begin
  Result := CallBusinessSaleBill(cBC_GetPostBills, nCard, nPost, @nOut);
  if Result then
       AnalyseBillItems(nOut.FData, nData)
  else gSysLoger.AddLog(TBusinessWorkerManager, '业务对象', nOut.FData);
end;

//Date: 2014-09-18
//Parm: 岗位;交货单列表
//Desc: 保存nPost岗位上的交货单数据
function SaveLadingBills(const nPost: string; nData: TLadingBillItems): Boolean;
var nStr: string;
    nOut: TWorkerBusinessCommand;
begin
  nStr := CombineBillItmes(nData);
  Result := CallBusinessSaleBill(cBC_SavePostBills, nStr, nPost, @nOut);

  if not Result then
    gSysLoger.AddLog(TBusinessWorkerManager, '业务对象', nOut.FData);
  //xxxxx
end;

//Date: 2015-08-06
//Parm: 磁卡号
//Desc: 获取磁卡使用类型
function GetCardUsed(const nCard: string; var nCardType: string): Boolean;
var nOut: TWorkerBusinessCommand;
begin
  Result := CallBusinessCommand(cBC_GetCardUsed, nCard, '', @nOut);

  if Result then
       nCardType := nOut.FData
  else gSysLoger.AddLog(TBusinessWorkerManager, '业务对象', nOut.FData);
  //xxxxx
end;

//Date: 2015-08-06
//Parm: 磁卡号;岗位;采购单列表
//Desc: 获取nPost岗位上磁卡为nCard的交货单列表
function GetLadingOrders(const nCard,nPost: string;
 var nData: TLadingBillItems): Boolean;
var nOut: TWorkerBusinessCommand;
begin
  Result := CallBusinessPurchaseOrder(cBC_GetPostOrders, nCard, nPost, @nOut);
  if Result then
       AnalyseBillItems(nOut.FData, nData)
  else gSysLoger.AddLog(TBusinessWorkerManager, '业务对象', nOut.FData);
end;

//Date: 2015-08-06
//Parm: 岗位;采购单列表
//Desc: 保存nPost岗位上的采购单数据
function SaveLadingOrders(const nPost: string; nData: TLadingBillItems): Boolean;
var nStr: string;
    nOut: TWorkerBusinessCommand;
begin
  nStr := CombineBillItmes(nData);
  Result := CallBusinessPurchaseOrder(cBC_SavePostOrders, nStr, nPost, @nOut);

  if not Result then
    gSysLoger.AddLog(TBusinessWorkerManager, '业务对象', nOut.FData);
  //xxxxx
end;
                                                             
//------------------------------------------------------------------------------
//Date: 2013-07-21
//Parm: 事件描述;岗位标识
//Desc:
procedure WriteHardHelperLog(const nEvent: string; nPost: string = '');
begin
  //gDisplayManager.Display(nPost, nEvent);
  gSysLoger.AddLog(THardwareHelper, '硬件守护辅助', nEvent);
end;

procedure BlueOpenDoor(const nReader: string;const nReaderType: string = '');
var nIdx: Integer;
begin
  if nReader = '' then Exit;
  nIdx := 0;

  while nIdx < 3 do
  begin
    Inc(nIdx);
    gHYReaderManager.OpenDoor(nReader);
    WriteHardHelperLog('华益读卡器抬杆:' + nReader);
  end;
end;

//Date: 2012-4-22
//Parm: 卡号
//Desc: 对nCard放行进厂
procedure MakeTruckIn(const nCard,nReader,nPost,nDept: string; const nDB: PDBWorker;
                      const nReaderType: string = '');
var nStr,nTruck,nCardType,nSnapStr: string;
    nIdx,nInt: Integer;
    nPLine: PLineItem;
    nPTruck: PTruckItem;
    nTrucks: TLadingBillItems;
    nRet: Boolean;
begin
  if gTruckQueueManager.IsTruckAutoIn and (GetTickCount -
     gHardwareHelper.GetCardLastDone(nCard, nReader) < 2 * 60 * 1000) then
  begin
    gHardwareHelper.SetReaderCard(nReader, nCard);
    Exit;
  end; //同读头同卡,在2分钟内不做二次进厂业务.

  nCardType := '';
  if not GetCardUsed(nCard, nCardType) then Exit;

  if nCardType = sFlag_Provide then
        nRet := GetLadingOrders(nCard, sFlag_TruckIn, nTrucks)
  else  nRet := GetLadingBills(nCard, sFlag_TruckIn, nTrucks);

  if not nRet then
  begin
    nStr := '读取磁卡[ %s ]订单信息失败.';
    nStr := Format(nStr, [nCard]);

    WriteHardHelperLog(nStr, sPost_In);
    Exit;
  end;

  if Length(nTrucks) < 1 then
  begin
    nStr := '磁卡[ %s ]没有需要进厂车辆.';
    nStr := Format(nStr, [nCard]);

    WriteHardHelperLog(nStr, sPost_In);
    Exit;
  end;

  for nIdx:=Low(nTrucks) to High(nTrucks) do
  with nTrucks[nIdx] do
  begin
    if gTruckQueueManager.IsFobiddenInMul then//禁止多次进厂
    begin
      if FStatus = sFlag_TruckNone then Continue;
      //未进厂
    end
    else
    begin
      if (FStatus = sFlag_TruckNone) or (FStatus = sFlag_TruckIn) then Continue;
      //未进厂,或已进厂
    end;

    nStr := '车辆[ %s ]下一状态为:[ %s ],进厂刷卡无效.';
    nStr := Format(nStr, [FTruck, TruckStatusToStr(FNextStatus)]);

    WriteHardHelperLog(nStr, sPost_In);
    Exit;
  end;

  {$IFDEF RemoteSnap}
  if (nTrucks[0].FStatus = sFlag_TruckNone) then//已进厂不判断
  if not VerifySnapTruck(nTrucks[0].FTruck,nTrucks[0].FID,nPost,nDept,nSnapStr) then
  begin
    nStr := nSnapStr+ '进厂车牌识别失败.';

    gHKSnapHelper.Display(nPost, nSnapStr, 3);
    //小屏显示

    WriteHardHelperLog(nStr+'岗位:'+nPost);

    Exit;
  end;
  nStr := nSnapStr + ' 请进厂';
  gHKSnapHelper.Display(nPost, nStr, 2);
    //小屏显示
  {$ENDIF}

  if nTrucks[0].FStatus = sFlag_TruckIn then
  begin
    if gTruckQueueManager.IsTruckAutoIn then
    begin
      gHardwareHelper.SetCardLastDone(nCard, nReader);
      gHardwareHelper.SetReaderCard(nReader, nCard);
    end else
    begin
      if gTruckQueueManager.TruckReInfactFobidden(nTrucks[0].FTruck) then
      begin
        BlueOpenDoor(nReader, nReaderType);
        //抬杆

        nStr := '车辆[ %s ]再次抬杆操作.';
        nStr := Format(nStr, [nTrucks[0].FTruck]);
        WriteHardHelperLog(nStr, sPost_In);
      end;
    end;

    Exit;
  end;

  if nCardType = sFlag_Provide then
  begin
    if not SaveLadingOrders(sFlag_TruckIn, nTrucks) then
    begin
      nStr := '车辆[ %s ]进厂放行失败.';
      nStr := Format(nStr, [nTrucks[0].FTruck]);

      WriteHardHelperLog(nStr, sPost_In);
      Exit;
    end;

    if gTruckQueueManager.IsTruckAutoIn then
    begin
      gHardwareHelper.SetCardLastDone(nCard, nReader);
      gHardwareHelper.SetReaderCard(nReader, nCard);
    end else
    begin
      BlueOpenDoor(nReader,nReaderType);
      //抬杆
    end;

    nStr := '原材料卡[%s]进厂抬杆成功';
    nStr := Format(nStr, [nCard]);
    WriteHardHelperLog(nStr, sPost_In);
    Exit;
  end;
  //采购磁卡直接抬杆

  nPLine := nil;
  //nPTruck := nil;

  with gTruckQueueManager do
  if not IsDelayQueue then //非延时队列(厂内模式)
  try
    SyncLock.Enter;
    nStr := nTrucks[0].FTruck;

    for nIdx:=Lines.Count - 1 downto 0 do
    begin
      nInt := TruckInLine(nStr, PLineItem(Lines[nIdx]).FTrucks);
      if nInt >= 0 then
      begin
        nPLine := Lines[nIdx];
        //nPTruck := nPLine.FTrucks[nInt];
        Break;
      end;
    end;

    if not Assigned(nPLine) then
    begin
      nStr := '车辆[ %s ]没有在调度队列中.';
      nStr := Format(nStr, [nTrucks[0].FTruck]);

      WriteHardHelperLog(nStr, sPost_In);
      Exit;
    end;
  finally
    SyncLock.Leave;
  end;

  if not SaveLadingBills(sFlag_TruckIn, nTrucks) then
  begin
    nStr := '车辆[ %s ]进厂放行失败.';
    nStr := Format(nStr, [nTrucks[0].FTruck]);

    WriteHardHelperLog(nStr, sPost_In);
    Exit;
  end;

  if gTruckQueueManager.IsTruckAutoIn then
  begin
    gHardwareHelper.SetCardLastDone(nCard, nReader);
    gHardwareHelper.SetReaderCard(nReader, nCard);
  end else
  begin
    BlueOpenDoor(nReader, nReaderType);
    //抬杆
  end;

  with gTruckQueueManager do
  if not IsDelayQueue then //厂外模式,进厂时绑定道号(一车多单)
  try
    SyncLock.Enter;
    nTruck := nTrucks[0].FTruck;

    for nIdx:=Lines.Count - 1 downto 0 do
    begin
      nPLine := Lines[nIdx];
      nInt := TruckInLine(nTruck, PLineItem(Lines[nIdx]).FTrucks);

      if nInt < 0 then Continue;
      nPTruck := nPLine.FTrucks[nInt];

      nStr := 'Update %s Set T_Line=''%s'',T_PeerWeight=%d Where T_Bill=''%s''';
      nStr := Format(nStr, [sTable_ZTTrucks, nPLine.FLineID, nPLine.FPeerWeight,
              nPTruck.FBill]);
      //xxxxx

      gDBConnManager.WorkerExec(nDB, nStr);
      //绑定通道
    end;
  finally
    SyncLock.Leave;
  end;
end;

//Date: 2012-4-22
//Parm: 卡号;读头;打印机;化验单打印机
//Desc: 对nCard放行出厂
function MakeTruckOut(const nCard,nReader,nPrinter,nPost,nDept: string;
 const nHYPrinter: string = '';const nReaderType: string = ''): Boolean;
var nStr,nCardType, nSnapStr: string;
    nIdx: Integer;
    nRet: Boolean;
    nTrucks: TLadingBillItems;
    {$IFDEF PrintBillMoney}
    nOut: TWorkerBusinessCommand;
    {$ENDIF}
begin
  Result := False;
  nCardType := '';
  if not GetCardUsed(nCard, nCardType) then Exit;

  if nCardType = sFlag_Provide then
        nRet := GetLadingOrders(nCard, sFlag_TruckOut, nTrucks)
  else  nRet := GetLadingBills(nCard, sFlag_TruckOut, nTrucks);

  if not nRet then
  begin
    nStr := '读取磁卡[ %s ]订单信息失败.';
    nStr := Format(nStr, [nCard]);

    WriteHardHelperLog(nStr, sPost_Out);
    Exit;
  end;

  if Length(nTrucks) < 1 then
  begin
    nStr := '磁卡[ %s ]没有需要出厂车辆.';
    nStr := Format(nStr, [nCard]);

    WriteHardHelperLog(nStr, sPost_Out);
    Exit;
  end;

  for nIdx:=Low(nTrucks) to High(nTrucks) do
  with nTrucks[nIdx] do
  begin
    if FNextStatus = sFlag_TruckOut then Continue;
    nStr := '车辆[ %s ]下一状态为:[ %s ],无法出厂.';
    nStr := Format(nStr, [FTruck, TruckStatusToStr(FNextStatus)]);

    WriteHardHelperLog(nStr, sPost_Out);
    Exit;
  end;

  {$IFDEF RemoteSnap}
  //if (nTrucks[0].FStatus = sFlag_TruckNone) then//已进厂不判断
  if not VerifySnapTruck(nTrucks[0].FTruck,nTrucks[0].FID,nPost,nDept,nSnapStr) then
  begin
    nStr := nSnapStr+ '进厂车牌识别失败.';

    gHKSnapHelper.Display(nPost, nSnapStr, 3);
    //小屏显示

    WriteHardHelperLog(nStr+'岗位:'+nPost);

    Exit;
  end;
  nStr := nSnapStr + ' 请出厂';
  gHKSnapHelper.Display(nPost, nStr, 2);
    //小屏显示
  {$ENDIF}

  if nCardType = sFlag_Provide then
        nRet := SaveLadingOrders(sFlag_TruckOut, nTrucks)
  else  nRet := SaveLadingBills(sFlag_TruckOut, nTrucks);

  if not nRet then
  begin
    nStr := '车辆[ %s ]出厂放行失败.';
    nStr := Format(nStr, [nTrucks[0].FTruck]);

    WriteHardHelperLog(nStr, sPost_Out);
    Exit;
  end;

  if (nReader <> '') and (Copy(nReader,1,1) <> 'V') then
    BlueOpenDoor(nReader, nReaderType); //抬杆
  Result := True;

  for nIdx:=Low(nTrucks) to High(nTrucks) do
  begin
    {$IFDEF PrintBillMoney}
    if CallBusinessCommand(cBC_GetZhiKaMoney,nTrucks[nIdx].FZhiKa,'',@nOut) then
         nStr := #8 + nOut.FData
    else nStr := #8 + '0';
    {$ELSE}
    nStr := '';
    {$ENDIF}

    nStr := nStr + #7 + nCardType;
    //磁卡类型
    if nHYPrinter <> '' then
      nStr := nStr + #6 + nHYPrinter;
    //化验单打印机

    if nPrinter = '' then
         gRemotePrinter.PrintBill(nTrucks[nIdx].FID + nStr)
    else gRemotePrinter.PrintBill(nTrucks[nIdx].FID + #9 + nPrinter + nStr);
  end; //打印报表
end;

//Date: 2012-10-19
//Parm: 卡号;读头
//Desc: 检测车辆是否在队列中,决定是否抬杆
procedure MakeTruckPassGate(const nCard,nReader: string; const nDB: PDBWorker;
                            const nReaderType: string = '');
var nStr: string;
    nIdx: Integer;
    nTrucks: TLadingBillItems;
begin
  if not GetLadingBills(nCard, sFlag_TruckOut, nTrucks) then
  begin
    nStr := '读取磁卡[ %s ]交货单信息失败.';
    nStr := Format(nStr, [nCard]);

    WriteHardHelperLog(nStr);
    Exit;
  end;

  if Length(nTrucks) < 1 then
  begin
    nStr := '磁卡[ %s ]没有需要通过道闸的车辆.';
    nStr := Format(nStr, [nCard]);

    WriteHardHelperLog(nStr);
    Exit;
  end;

  if gTruckQueueManager.TruckInQueue(nTrucks[0].FTruck) < 0 then
  begin
    nStr := '车辆[ %s ]不在队列,禁止通过道闸.';
    nStr := Format(nStr, [nTrucks[0].FTruck]);

    WriteHardHelperLog(nStr);
    Exit;
  end;

  BlueOpenDoor(nReader, nReaderType);
  //抬杆

  for nIdx:=Low(nTrucks) to High(nTrucks) do
  begin
    nStr := 'Update %s Set T_InLade=%s Where T_Bill=''%s'' And T_InLade Is Null';
    nStr := Format(nStr, [sTable_ZTTrucks, sField_SQLServer_Now, nTrucks[nIdx].FID]);

    gDBConnManager.WorkerExec(nDB, nStr);
    //更新提货时间,语音程序将不再叫号.
  end;
end;

//Date: 2014-10-25
//Parm: 读头数据
//Desc: 华益读头磁卡动作
procedure WhenHYReaderCardArrived(const nReader: PHYReaderItem);
begin
  {$IFDEF DEBUG}
  WriteHardHelperLog(Format('华益标签 %s:%s', [nReader.FTunnel, nReader.FCard]));
  {$ENDIF}

  if nReader.FVirtual then
  begin
    case nReader.FVType of
      rt900 :gHardwareHelper.SetReaderCard(nReader.FVReader, 'H' + nReader.FCard, False);
      rt02n :g02NReader.SetReaderCard(nReader.FVReader, 'H' + nReader.FCard);
    end;
  end else g02NReader.ActiveELabel(nReader.FTunnel, nReader.FCard);
end;

//Date: 2018-01-08
//Parm: 三合一读卡器
//Desc: 处理三合一读卡器信息
procedure WhenTTCE_M100_ReadCard(const nItem: PM100ReaderItem);
var nStr: string;
    nRetain: Boolean;
    nCType: string;
    nDBConn: PDBWorker;
    nErrNum: Integer;
begin
  nRetain := False;
  //init

  {$IFDEF DEBUG}
  nStr := '三合一读卡器卡号'  + nItem.FID + ' ::: ' + nItem.FCard;
  WriteHardHelperLog(nStr);
  {$ENDIF}

  try
    if not nItem.FVirtual then Exit;
    if nItem.FVType = rtOutM100 then
    begin
      nRetain := MakeTruckOut(nItem.FCard, nItem.FVReader, nItem.FVPrinter,nitem.FPost,nitem.FDept,
                              nItem.FVHYPrinter);
      //xxxxx

      if not GetCardUsed(nItem.FCard, nCType) then
        nCType := '';

        if nCType = sFlag_Provide then
        begin
          nDBConn := nil;
          with gParamManager.ActiveParam^ do
          Try
            nDBConn := gDBConnManager.GetConnection(FDB.FID, nErrNum);
            if not Assigned(nDBConn) then
            begin
              WriteHardHelperLog('连接HM数据库失败(DBConn Is Null).');
              Exit;
            end;

            if not nDBConn.FConn.Connected then
              nDBConn.FConn.Connected := True;
            //conn db
            nStr := 'select O_CType from %s Where O_Card=''%s'' ';
            nStr := Format(nStr, [sTable_Order, nItem.FCard]);
            with gDBConnManager.WorkerQuery(nDBConn,nStr) do
            if RecordCount > 0 then
            begin
              if FieldByName('O_CType').AsString = sFlag_OrderCardG then
                nRetain := False;
            end;
          finally
            gDBConnManager.ReleaseConnection(nDBConn);
          end;
        end;
        if nRetain then
          WriteHardHelperLog('吞卡机执行状态:'+'卡类型:'+nCType+'动作:吞卡')
        else
          WriteHardHelperLog('吞卡机执行状态:'+'卡类型:'+nCType+'动作:吞卡后吐卡');
    end else
    begin
      gHardwareHelper.SetReaderCard(nItem.FVReader, nItem.FCard, False);
    end;
  finally
    gM100ReaderManager.DealtWithCard(nItem, nRetain)
  end;
end;

//------------------------------------------------------------------------------
procedure WriteNearReaderLog(const nEvent: string);
begin
  gSysLoger.AddLog(T02NReader, '现场近距读卡器', nEvent);
end;

//Date: 2019-03-12
//Parm: 通道号;提示信息;车牌号
//Desc: 在nTunnel的小屏上显示信息
procedure ShowLEDHint(const nTunnel: string; nHint: string;
  const nTruck: string = '';const nUnPLC:string = '');
begin
  if nTruck <> '' then
    nHint := nTruck + StringOfChar(' ', 12 - Length(nTruck)) + nHint;
  //xxxxx
  
  if Length(nHint) > 24 then
    nHint := Copy(nHint, 1, 24);
  {$IFDEF UseERelayPLC}
    if nUnPLC = '' then
      gERelayManagerPLC.ShowText(nTunnel, nHint)
    else
    begin
      {$IFDEF BasisWeightTruckProber}
        gProberManager.ShowTxt(nTunnel, nHint);
      {$ELSE}
        gERelayManager.ShowTxt(nTunnel, nHint);
      {$ENDIF}
    end;
  {$ELSE}
    gERelayManager.ShowTxt(nTunnel, nHint);
  {$ENDIF}
end;

//Date: 2012-4-24
//Parm: 车牌;通道;是否检查先后顺序;提示信息
//Desc: 检查nTuck是否可以在nTunnel装车
function IsTruckInQueue(const nTruck,nTunnel: string; const nQueued: Boolean;
 var nHint: string; var nPTruck: PTruckItem; var nPLine: PLineItem;
 const nStockType: string = ''): Boolean;
var i,nIdx,nInt: Integer;
    nLineItem: PLineItem;
begin
  with gTruckQueueManager do
  try
    Result := False;
    SyncLock.Enter;
    nIdx := GetLine(nTunnel);

    if nIdx < 0 then
    begin
      nHint := Format('通道[ %s ]无效.', [nTunnel]);
      Exit;
    end;

    nPLine := Lines[nIdx];
    nIdx := TruckInLine(nTruck, nPLine.FTrucks);

    if (nIdx < 0) and (nStockType <> '') and (
       ((nStockType = sFlag_Dai) and IsDaiQueueClosed) or
       ((nStockType = sFlag_San) and IsSanQueueClosed)) then
    begin
      for i:=Lines.Count - 1 downto 0 do
      begin
        if Lines[i] = nPLine then Continue;
        nLineItem := Lines[i];
        nInt := TruckInLine(nTruck, nLineItem.FTrucks);

        if nInt < 0 then Continue;
        //不在当前队列
        if not StockMatch(nPLine.FStockNo, nLineItem) then Continue;
        //刷卡道与队列道品种不匹配

        nIdx := nPLine.FTrucks.Add(nLineItem.FTrucks[nInt]);
        nLineItem.FTrucks.Delete(nInt);
        //挪动车辆到新道

        nHint := 'Update %s Set T_Line=''%s'' ' +
                 'Where T_Truck=''%s'' And T_Line=''%s''';
        nHint := Format(nHint, [sTable_ZTTrucks, nPLine.FLineID, nTruck,
                nLineItem.FLineID]);
        gTruckQueueManager.AddExecuteSQL(nHint);

        nHint := '车辆[ %s ]自主换道[ %s->%s ]';
        nHint := Format(nHint, [nTruck, nLineItem.FName, nPLine.FName]);
        WriteNearReaderLog(nHint);
        Break;
      end;
    end;
    //袋装重调队列

    if nIdx < 0 then
    begin
      nHint := Format('车辆[ %s ]不在[ %s ]队列中.', [nTruck, nPLine.FName]);
      Exit;
    end;

    nPTruck := nPLine.FTrucks[nIdx];
    nPTruck.FStockName := nPLine.FName;
    //同步物料名
    Result := True;
  finally
    SyncLock.Leave;
  end;
end;

//Date: 2019-03-12
//Parm: 车辆;通道;皮重
//Desc: 授权nTruck在nTunnel车道放灰
procedure TruckStartFH(const nTruck: PTruckItem; const nTunnel: string;
 const nLading: TLadingBillItem; const UnPLC:string = '');
var nStr: string;
begin
  {$IFDEF UseERelayPLC}
    if UnPLC = '' then
    begin
      gERelayManagerPLC.OpenTunnel(nTunnel);
      WriteNearReaderLog(nTunnel+'打开进厂道闸,红绿灯');
    end
    else
    begin
      {$IFDEF BasisWeightTruckProber}
        gProberManager.OpenTunnel(nTunnel);
      {$ELSE}
        gERelayManager.LineOpen(nTunnel);
      {$ENDIF}
    end;
    //语音播报
    if Assigned(gNetVoiceHelper) then
      gNetVoiceHelper.PlayVoice(nLading.FTruck+'刷卡成功请上磅',nTunnel);
  {$ELSE}
    gERelayManager.LineOpen(nTunnel);
  {$ENDIF}
  //开始放灰

  nStr := Format('Truck=%s', [nTruck.FTruck]);
  gBasisWeightManager.StartWeight(nTunnel, nTruck.FBill, nTruck.FValue,
    nLading.FPData.FValue, nStr);
  //开始定量装车

  if nLading.FStatus <> sFlag_TruckIn then
  begin
    {$IFDEF UseERelayPLC}
      if UnPLC = '' then
      begin
        gERelayManagerPLC.OpenTunnel(nTunnel+'_O');
        WriteNearReaderLog(nTunnel+'允许放灰');
      end
      else
      begin
        {$IFDEF BasisWeightTruckProber}
          gProberManager.OpenTunnel(nTunnel+'_O');
        {$ENDIF}
      end;
    {$ENDIF}
    gBasisWeightManager.SetParam(nTunnel, 'CanFH', sFlag_Yes);
  //添加可放灰标记
  end;
end;

//Date: 2019-03-12
//Parm: 磁卡号;通道号
//Desc: 对nCard执行袋装装车操作
procedure MakeTruckLadingSan(const nCard,nTunnel: string);
begin

end;

//Date: 2019-03-12
//Parm: 磁卡号;通道号
//Desc: 对nCard执行称量操作
procedure MakeTruckWeightFirst(const nCard,nTunnel: string;const UnPLC:string = '');
var nStr: string;
    nIdx: Integer;
    nPound: TBWTunnel;
    nPLine: PLineItem;
    nPTruck: PTruckItem;
    nTrucks: TLadingBillItems;
    nPT: PPTTunnelItem;
begin
  {$IFDEF DEBUG}
  WriteNearReaderLog('MakeTruckWeightFirst进入.');
  {$ENDIF}

  if not GetLadingBills(nCard, sFlag_TruckFH, nTrucks) then
  begin
    nStr := '读取磁卡[ %s ]交货单信息失败.';
    nStr := Format(nStr, [nCard]);

    WriteNearReaderLog(nStr);
    ShowLEDHint(nTunnel, '读取交货单信息失败','',UnPLC);
    Exit;
  end;

  if Length(nTrucks) < 1 then
  begin
    nStr := '磁卡[ %s ]没有需要装料车辆.';
    nStr := Format(nStr, [nCard]);

    WriteNearReaderLog(nStr);
    ShowLEDHint(nTunnel, '没有需要装料车辆','',UnPLC);
    Exit;
  end;

  for nIdx:=Low(nTrucks) to High(nTrucks) do
  with nTrucks[nIdx] do
  begin
    if FStatus = sFlag_TruckNone then
    begin
      ShowLEDHint(nTunnel, '请进厂刷卡', nTrucks[0].FTruck,UnPLC);
      Exit;
    end;
  end;

 if gBasisWeightManager <> nil then
 begin
    with gBasisWeightManager.TunnelManager do
    begin
      nPT := GetTunnel(nTunnel);
      if not Assigned(nPT) then
      begin
        ShowLEDHint(nTunnel, '通道未启用', nTrucks[0].FTruck,UnPLC);
        Exit;
      end;
    end;

    if gBasisWeightManager.IsTunnelBusy(nTunnel, @nPound) and
       (nPound.FBill <> nTrucks[0].FID) then //通道忙
    begin
      if nPound.FValTunnel = 0 then //前车已下磅
      begin
        nStr := Format('%s 请等待前车', [nTrucks[0].FTruck]);
        ShowLEDHint(nTunnel, nStr,'',UnPLC);
        Exit;
      end;
    end;
  end;


  WriteNearReaderLog('通道' + nTunnel +'当前业务:' + nPound.FBill +
                     '新刷卡:' + nTrucks[0].FID);

  if nPound.FBill <> '' then
  if (nPound.FBill <> nTrucks[0].FID) then //前车业务未完成后车刷卡
  begin
    if (nPound.FValTunnel < 0) or (nPound.FValTunnel > nPound.FTunnel.FPort.FMinValue) then 
    begin
      nStr := Format('%s.%s 地磅重量异常', [nTrucks[0].FID, nTrucks[0].FTruck]);
      WriteNearReaderLog(nStr);
      Exit;
    end;
  end;

  if not IsTruckInQueue(nTrucks[0].FTruck, nTunnel, False, nStr,
         nPTruck, nPLine, sFlag_San) then
  begin
    WriteNearReaderLog(nStr);
    ShowLEDHint(nTunnel, '请换道装车', nTrucks[0].FTruck,UnPLC);
    Exit;
  end; //检查通道

  if nTrucks[0].FStatus = sFlag_TruckIn then
  begin
    nStr := '车辆[ %s ]刷卡,等待称皮重.';
    nStr := Format(nStr, [nTrucks[0].FTruck]);
    WriteNearReaderLog(nStr);

    nStr := Format('请 %s 上磅称量皮重', [nTrucks[0].FTruck]);
    ShowLEDHint(nTunnel, nStr,'',UnPLC);
  end else
  begin
    if nPound.FValTunnel > 0 then
         nStr := '请上磅装车'
    else nStr := '请开始装车';

    ShowLEDHint(nTunnel, nStr, nTrucks[0].FTruck,UnPLC);
  end;

  TruckStartFH(nPTruck, nTunnel, nTrucks[0],UnPLC);
  //执行放灰
end;

//Date: 2012-4-22
//Parm: 读头数据
//Desc: 对nReader读到的卡号做具体动作
procedure WhenReaderCardArrived(const nReader: THHReaderItem);
var nStr,nCard,nReaderType: string;
    nErrNum: Integer;
    nDBConn: PDBWorker;
begin
  nDBConn := nil;
  {$IFDEF DEBUG}
  WriteHardHelperLog('WhenReaderCardArrived进入.');
  {$ENDIF}

  with gParamManager.ActiveParam^ do
  try
    nDBConn := gDBConnManager.GetConnection(FDB.FID, nErrNum);
    if not Assigned(nDBConn) then
    begin
      WriteHardHelperLog('连接HM数据库失败(DBConn Is Null).');
      Exit;
    end;

    if not nDBConn.FConn.Connected then
      nDBConn.FConn.Connected := True;
    //conn db

    nStr := 'Select C_Card From $TB Where C_Card=''$CD'' or ' +
            'C_Card2=''$CD'' or C_Card3=''$CD''';
    nStr := MacroValue(nStr, [MI('$TB', sTable_Card), MI('$CD', nReader.FCard)]);

    with gDBConnManager.WorkerQuery(nDBConn, nStr) do
    if RecordCount > 0 then
    begin
      nCard := Fields[0].AsString;
    end else
    begin
      nStr := Format('磁卡号[ %s ]匹配失败.', [nReader.FCard]);
      WriteHardHelperLog(nStr);
      Exit;
    end;


    if (Assigned(nReader.FOptions)) and
      (Trim(nReader.FOptions.Values['Tunnel']) <> '') then
    begin
      MakeTruckWeightFirst(nCard, nReader.FOptions.Values['Tunnel'],Trim(nReader.FOptions.Values['TruckProber']));
    end
    else
    begin
      if Assigned(nReader.FOptions) then
           nReaderType := nReader.FOptions.Values['ReaderType']
      else nReaderType := '';

      try
        if nReader.FType = rtIn then
        begin
          MakeTruckIn(nCard, nReader.FID,nReader.FPost,nReader.FDept, nDBConn, nReaderType);
        end else

        if nReader.FType = rtOut then
        begin
          if Assigned(nReader.FOptions) then
               nStr := nReader.FOptions.Values['HYPrinter']
          else nStr := '';
          MakeTruckOut(nCard, nReader.FID, nReader.FPrinter,nReader.FPost,nReader.FDept, nStr, nReaderType);
        end else

        if nReader.FType = rtGate then
        begin
          if nReader.FID <> '' then
            BlueOpenDoor(nReader.FID, nReaderType);
          //抬杆
        end else

        if nReader.FType = rtQueueGate then
        begin
          if nReader.FID <> '' then
            MakeTruckPassGate(nCard, nReader.FID, nDBConn, nReaderType);
          //抬杆
        end;
      except
        On E:Exception do
        begin
          WriteHardHelperLog(E.Message);
        end;
      end;
    end;
  finally
    gDBConnManager.ReleaseConnection(nDBConn);
  end;
end;

//Date: 2012-4-24
//Parm: 主机;卡号
//Desc: 对nHost.nCard新到卡号作出动作
procedure WhenReaderCardIn(const nCard: string; const nHost: PReaderHost);
var nStr: string;
begin
  if nHost.FType = rtOnce then
  begin
    if nHost.FFun = rfOut then
    begin
      if Assigned(nHost.FOptions) then
           nStr := nHost.FOptions.Values['HYPrinter']
      else nStr := '';
      MakeTruckOut(nCard, '', nHost.FPrinter,'','', nStr);
    end// else MakeTruckLadingDai(nCard, nHost.FTunnel);
    else //单刷支持定量装车
    begin
      {$IFDEF BasisWeightWithPM}
        MakeTruckWeightFirst(nCard, nHost.FTunnel);
      {$ENDIF}
    end;
  end else

  if nHost.FType = rtKeep then
  begin
    {$IFDEF BasisWeightWithPM}
    MakeTruckWeightFirst(nCard, nHost.FTunnel);
    {$ELSE}
    MakeTruckLadingSan(nCard, nHost.FTunnel);
    {$ENDIF}

    gBasisWeightManager.SetParam(nHost.FTunnel, 'LEDText', nHost.FLEDText, True);
    //附加参数
  end;
end;

//Date: 2012-4-24
//Parm: 主机;卡号
//Desc: 对nHost.nCard超时卡作出动作
procedure WhenReaderCardOut(const nCard: string; const nHost: PReaderHost);
begin
  {$IFDEF DEBUG}
  WriteHardHelperLog('WhenReaderCardOut退出.');
  {$ENDIF}

  {$IFDEF UseERelayPLC}
  if nHost.FOptions.Values['TruckProber'] = '' then
  begin
    gERelayManagerPLC.CloseTunnel(nHost.FTunnel+'_N');
    WriteNearReaderLog(nHost.FTunnel+'关闭放灰');
  end
  else
  begin
    {$IFDEF BasisWeightTruckProber}
     // gProberManager.CloseTunnel(nHost.FTunnel+'_O');
    {$ELSE}
      gERelayManager.LineClose(nHost.FTunnel);
    {$ENDIF}
  end;
  {$ELSE}
    gERelayManager.LineClose(nHost.FTunnel);
  {$ENDIF}

  Sleep(100);

  if nHost.FETimeOut then
  begin
    {$IFDEF UseERelayPLC}
    if nHost.FOptions.Values['TruckProber'] = '' then
      gERelayManagerPLC.ShowText(nHost.FTunnel, '电子标签超出范围')
    else
      gERelayManager.ShowTxt(nHost.FTunnel, '电子标签超出范围');
    {$ELSE}
      gERelayManager.ShowTxt(nHost.FTunnel, '电子标签超出范围');
    {$ENDIF}
  end
  else
  begin
    {$IFDEF UseERelayPLC}
    if nHost.FOptions.Values['TruckProber'] = '' then
      gERelayManagerPLC.ShowText(nHost.FTunnel, nHost.FLEDText)
    else
      gERelayManager.ShowTxt(nHost.FTunnel, nHost.FLEDText);
    {$ELSE}
      gERelayManager.ShowTxt(nHost.FTunnel, nHost.FLEDText);
    {$ENDIF}
  end;
  Sleep(100);
end;

//Date: 2012-12-16
//Parm: 磁卡号
//Desc: 对nCardNo做自动出厂(模拟读头刷卡)
procedure MakeTruckAutoOut(const nCardNo: string);
var nReader: string;
begin
  if gTruckQueueManager.IsTruckAutoOut then
  begin
    nReader := gHardwareHelper.GetReaderLastOn(nCardNo);
    if nReader <> '' then
      gHardwareHelper.SetReaderCard(nReader, nCardNo);
    //模拟刷卡
  end;
end;

//Date: 2012-12-16
//Parm: 共享数据
//Desc: 处理业务中间件与硬件守护的交互数据
procedure WhenBusinessMITSharedDataIn(const nData: string);
begin
  WriteHardHelperLog('收到Bus_MIT业务请求:::' + nData);
  //log data

  if Pos('TruckOut', nData) = 1 then
    MakeTruckAutoOut(Copy(nData, Pos(':', nData) + 1, MaxInt));
  //auto out
end;

//------------------------------------------------------------------------------
//Date: 2019-03-12
//Parm: 端口
//Desc: 解析磅站数据
function WhenParsePoundWeight(const nPort: PPTPortItem): Boolean;
var nIdx,nLen: Integer;
    nVerify: Word;
    nBuf: TIdBytes;
begin
  Result := False;
  nBuf := ToBytes(nPort.FCOMBuff, Indy8BitEncoding);
  nLen := Length(nBuf) - 2;
  if nLen < 52 then Exit; //48-51为磅重数据

  nVerify := 0;
  nIdx := 0;

  while nIdx < nLen do
  begin
    nVerify := nBuf[nIdx] + nVerify;
    Inc(nIdx);
  end;

  if (nBuf[nLen] <> (nVerify shr 8 and $00ff)) or
     (nBuf[nLen+1] <> (nVerify and $00ff)) then Exit;
  //校验失败

  nPort.FCOMData := IntToStr(StrToInt('$' +
    IntToHex(nBuf[51], 2) + IntToHex(nBuf[50], 2) +
    IntToHex(nBuf[49], 2) + IntToHex(nBuf[48], 2)));
  //毛重显示数据

  Result := True;
end;

//Desc: 构建图片路径
function MakePicName: string;
begin
  while True do
  begin
    Result := gSysParam.FPicPath + IntToStr(gSysParam.FPicBase) + '.jpg';
    if not FileExists(Result) then
    begin
      Inc(gSysParam.FPicBase);
      Exit;
    end;

    DeleteFile(Result);
    if FileExists(Result) then Inc(gSysParam.FPicBase)
  end;
end;

procedure CapturePicture(const nTunnel: PPTTunnelItem; const nList: TStrings);
const
  cRetry = 2;
  //重试次数
var nStr,nTmp: string;
    nIdx,nInt: Integer;
    nLogin,nErr: Integer;
    nPic: NET_DVR_JPEGPARA;
    nInfo: TNET_DVR_DEVICEINFO;
begin
  nList.Clear;

  if not Assigned(nTunnel.FCamera) then
  begin
    WriteNearReaderLog('抓拍通道无效');
    Exit;
  end;

  if not DirectoryExists(gSysParam.FPicPath) then
    ForceDirectories(gSysParam.FPicPath);

  if gSysParam.FPicBase >= 100 then
    gSysParam.FPicBase := 0;

  nLogin := -1;

  NET_DVR_Init();

  try
    for nIdx:=1 to cRetry do
    begin
      nStr := 'NET_DVR_Login(IPAddr=%s,wDVRPort=%d,UserName=%s,PassWord=%s)';
      nStr := Format(nStr,[nTunnel.FCamera.FHost,nTunnel.FCamera.FPort,nTunnel.FCamera.FUser,nTunnel.FCamera.FPwd]);

      nLogin := NET_DVR_Login(PChar(nTunnel.FCamera.FHost),
                   nTunnel.FCamera.FPort,
                   PChar(nTunnel.FCamera.FUser),
                   PChar(nTunnel.FCamera.FPwd), @nInfo);

      nErr := NET_DVR_GetLastError;
      if nErr = 0 then break;

      if nIdx = cRetry then
      begin
        nStr := '登录摄像机[ %s.%d ]失败,错误码: %d';
        nStr := Format(nStr, [nTunnel.FCamera.FHost, nTunnel.FCamera.FPort, nErr]);
        WriteNearReaderLog(nStr);
        Exit;
      end;
    end;

    nPic.wPicSize := nTunnel.FCamera.FPicSize;
    nPic.wPicQuality := nTunnel.FCamera.FPicQuality;
    nStr := 'nPic.wPicSize=%d,nPic.wPicQuality=%d';
    nStr := Format(nStr,[nPic.wPicSize,nPic.wPicQuality]);

    for nIdx:=Low(nTunnel.FCameraTunnels) to High(nTunnel.FCameraTunnels) do
    begin
      if nTunnel.FCameraTunnels[nIdx] = MaxByte then continue;

      for nInt:=1 to cRetry do
      begin
        nStr := MakePicName();
        WriteNearReaderLog('抓拍图片路径:'+nStr);
        nTmp := 'NET_DVR_CaptureJPEGPicture(LoginID=%d,lChannel=%d,sPicFileName=%s)';
        nTmp := Format(nTmp,[nLogin,nTunnel.FCameraTunnels[nIdx],nStr]);

        NET_DVR_CaptureJPEGPicture(nLogin, nTunnel.FCameraTunnels[nIdx],
                                   @nPic, PChar(nStr));

        nErr := NET_DVR_GetLastError;

        if nErr = 0 then
        begin
          nList.Add(nStr);
          Break;
        end;

        if nIdx = cRetry then
        begin
          nStr := '抓拍图像[ %s.%d ]失败,错误码: %d';
          nStr := Format(nStr, [nTunnel.FCamera.FHost,
                   nTunnel.FCameraTunnels[nIdx], nErr]);
          WriteNearReaderLog(nStr);
        end;
      end;
    end;
  finally
    if nLogin > -1 then
      NET_DVR_Logout(nLogin);
    NET_DVR_Cleanup();
  end;
end;

procedure SavePicture(const nID, nTruck, nMate, nFile: string);
var nStr: string;
    nRID: Integer;
    nDBConn: PDBWorker;
    nIdx:Integer;
begin
  nDBConn := nil;
  with gParamManager.ActiveParam^ do
  begin
    try
      nDBConn := gDBConnManager.GetConnection(FDB.FID, nIdx);
      if not Assigned(nDBConn) then
      begin
        WriteNearReaderLog('连接HM数据库失败(DBConn Is Null).');
        Exit;
      end;

      if not nDBConn.FConn.Connected then
        nDBConn.FConn.Connected := True;

      nDBConn.FConn.BeginTrans;
      try
        nStr := MakeSQLByStr([
            SF('P_ID', nID),
            SF('P_Name', nTruck),
            SF('P_Mate', nMate),
            SF('P_Date', sField_SQLServer_Now, sfVal)
            ], sTable_Picture, '', True);
        gDBConnManager.WorkerExec(nDBConn, nStr);
        WriteNearReaderLog('保存抓拍'+nStr);

        nStr := 'Select Max(%s) From %s';
        nStr := Format(nStr, ['R_ID', sTable_Picture]);

        with gDBConnManager.WorkerQuery(nDBConn, nStr) do
        if RecordCount > 0 then
        begin
          nRID := Fields[0].AsInteger;
        end;

        nStr := 'Select P_Picture From %s Where R_ID=%d';
        nStr := Format(nStr, [sTable_Picture, nRID]);
        SaveDBImage(gDBConnManager.WorkerQuery(nDBConn, nStr), 'P_Picture', nFile);

        nDBConn.FConn.CommitTrans;
      except
        nDBConn.FConn.RollbackTrans;
      end;
    finally
      gDBConnManager.ReleaseConnection(nDBConn);
    end;
  end;
end;

//Date: 2019-03-12
//Parm: 交货单号;重量
//Desc: 依据nBill状态写入nValue重量
function SavePoundData(const nTunnel: PBWTunnel; const nValue: Double; out nMsg:string): Boolean;
var nStr, nStatus, nTruck: string;
    nDBConn: PDBWorker;
    nPvalue,nDefaultPValue,nPValueWuCha : Double;
    nList: TStrings;
    nIdx: Integer;
begin
  nDBConn := nil;
  try
    Result := False;
    nStr := 'Select L_Status,L_Value,L_PValue,L_Truck From %s Where L_ID=''%s''';
    nStr := Format(nStr, [sTable_Bill, nTunnel.FBill]);
     
    with gDBConnManager.SQLQuery(nStr, nDBConn) do
    begin
      if RecordCount < 1 then
      begin
        WriteNearReaderLog(Format('交货单[ %s ]已丢失', [nTunnel.FBill]));
        Exit;
      end;

      nStatus := FieldByName('L_Status').AsString;
      nTruck  := FieldByName('L_Truck').AsString;
      if nStatus = sFlag_TruckIn then //皮重
      begin
        //查找默认皮重值
        nStr := ' Select D_Value from %s  where D_Name = ''%s'' and D_Memo = ''%s''  ';
        nStr := Format(nStr, [sTable_SysDict, sFlag_SysParam,sFlag_DefaultPValue]);
        with gDBConnManager.WorkerQuery(nDBConn, nStr) do
        begin
          if RecordCount < 1 then
            nDefaultPValue := 21
          else
            nDefaultPValue :=  FieldByName('D_Value').AsFloat;
        end;
        //查找皮重上下浮动值
        nStr := ' Select D_Value from %s  where D_Name = ''%s'' and D_Memo = ''%s''  ';
        nStr := Format(nStr, [sTable_SysDict, sFlag_SysParam,sFlag_PValueWuCha]);
        with gDBConnManager.WorkerQuery(nDBConn, nStr) do
        begin
          if RecordCount < 1 then
            nPValueWuCha := 3
          else
            nPValueWuCha :=  FieldByName('D_Value').AsFloat;
        end;

        //判断皮重有效性
        nPvalue := 0;
        nStr := ' Select Top 5 L_PValue from %s  where L_Truck = ''%s'' and L_PValue is not null order by R_ID Desc ';
        nStr := Format(nStr, [sTable_Bill, nTruck]);
        with gDBConnManager.WorkerQuery(nDBConn, nStr) do
        begin
          if RecordCount < 1 then
            nPvalue := nDefaultPValue
          else
          begin
            First;
            while not Eof do
            begin
              nPvalue := nPvalue + FieldByName('L_Pvalue').AsFloat;
              Next;
            end;
            nPvalue := nPvalue / RecordCount;
          end;
        end;
        //皮重有效范围值
        if  (nValue < nPvalue - nPvalueWucha)  or (nValue > nPvalue + nPvalueWucha) then
        begin
          nMsg := '皮重异常';
          WriteNearReaderLog(nTunnel.FID+'历史平均皮重：'+FloatToStr(nPValue)
          +'当前皮重：'+FloatToStr(nValue)+'浮动范围：'+FloatToStr(nPValueWuCha));
          Exit;
        end;

        nStr := MakeSQLByStr([SF('L_Status', sFlag_TruckBFP),
                SF('L_NextStatus', sFlag_TruckFH),
                SF('L_LadeTime', sField_SQLServer_Now, sfVal),
                SF('L_PValue', nValue, sfVal),
                SF('L_PDate', sField_SQLServer_Now, sfVal)
          ], sTable_Bill, SF('L_ID', nTunnel.FBill), False);
        gDBConnManager.WorkerExec(nDBConn, nStr);

        gBasisWeightManager.SetTruckPValue(nTunnel.FID, nValue);
        //更新通道皮重, 确认磅重上限
        {$IFDEF UseERelayPLC}
        if nTunnel.FTunnel.FOptions.Values['TruckProber'] = '' then
        begin
          gERelayManagerPLC.OpenTunnel(nTunnel.FID+'_O');
          WriteNearReaderLog(nTunnel.FID+'保存皮重,允许放灰');
        end
        else
        begin
          gProberManager.OpenTunnel(nTunnel.FID+'_O');
          WriteNearReaderLog(nTunnel.FID+'保存皮重,允许放灰');
        end;
          //保存皮重之后开始放灰
          //语音播报
          if Assigned(gNetVoiceHelper) then
            gNetVoiceHelper.PlayVoice(nTunnel.FParams.Values['Truck']+'称重完毕请装车',nTunnel.FID);
        {$ENDIF}

        {$IFDEF HKVDVR}
        gCameraManager.CapturePicture(nTunnel.FID, nTunnel.FBill);
        //抓拍
        {$ENDIF}
      end else
      begin
        nStr := MakeSQLByStr([SF('L_Status', sFlag_TruckBFM),
                SF('L_NextStatus', sFlag_TruckOut),
                SF('L_MValue', nValue, sfVal),
                SF('L_MDate', sField_SQLServer_Now, sfVal)
          ], sTable_Bill, SF('L_ID', nTunnel.FBill), False);
        gDBConnManager.WorkerExec(nDBConn, nStr);
        WriteNearReaderLog((nTunnel.FID+'更新毛重值：'+FloatToStr(nValue)));
      end; //放灰状态,只更新重量,出厂时计算净重
    end;

    Result := True;
  finally
    gDBConnManager.ReleaseConnection(nDBConn);
  end;   
end;

//Date: 2019-03-11
//Parm: 定量装车通道
//Desc: 当nTunnel状态改变时,处理业务
procedure WhenBasisWeightStatusChange(const nTunnel: PBWTunnel);
var
  nStr, nTruck, nMsg: string;
  nList : TStrings;
  nIdx  : Integer;
  FLevel1,FLevel2: Double;
begin
  if nTunnel.FStatusNew = bsProcess then
  begin
    if nTunnel.FWeightMax > 0 then
    begin
      nStr := Format('%.2f/%.2f', [nTunnel.FWeightMax, nTunnel.FValTunnel]);
      
      FLevel1 := StrToFloatDef(nTunnel.FTunnel.FOptions.Values['Level1'],0);
      FLevel2 := StrToFloatDef(nTunnel.FTunnel.FOptions.Values['Level2'],0);
      if (FLevel1 > 0) and (FLevel2 > FLevel1)  then
      begin
        if (not nTunnel.FWeightDone) and (not nTunnel.FLevel1)
          and (nTunnel.FValTunnel >= nTunnel.FWeightMax * FLevel1)
          and (nTunnel.FValTunnel < nTunnel.FWeightMax * FLevel2) then  //模拟量1
        begin
          {$IFDEF UseERelayPLC}
          if nTunnel.FTunnel.FOptions.Values['TruckProber'] = '' then
          begin
            nTunnel.FLevel1 := True;
            gERelayManagerPLC.OpenTunnel(nTunnel.FID+'_O01');
            WriteNearReaderLog(nTunnel.FID+'关一级'+' 当前量：'+FloatToStr(nTunnel.FValTunnel)+'最终量：'+FloatToStr(nTunnel.FWeightMax));
          end;
          {$ENDIF}
        end;
      end;
      if (FLevel2 > 0) and (FLevel2 < 1) then
      begin
        if (not nTunnel.FWeightDone) and (not nTunnel.FLevel2)
          and (nTunnel.FValTunnel >= nTunnel.FWeightMax * FLevel2)
          and (nTunnel.FValTunnel < (nTunnel.FWeightMax - 0.1)) then  //模拟量2
        begin
          {$IFDEF UseERelayPLC}
          if nTunnel.FTunnel.FOptions.Values['TruckProber'] = '' then
          begin
            nTunnel.FLevel2 := True;
            gERelayManagerPLC.OpenTunnel(nTunnel.FID+'_O02');
            WriteNearReaderLog(nTunnel.FID+'关二级'+' 当前量：'+FloatToStr(nTunnel.FValTunnel)+'最终量：'+FloatToStr(nTunnel.FWeightMax));
          end;
          {$ENDIF}
        end;
      end;
    end
    else nStr := Format('%.2f/%.2f', [nTunnel.FValue, nTunnel.FValTunnel]);

    ShowLEDHint(nTunnel.FID, nStr, nTunnel.FParams.Values['Truck'],nTunnel.FTunnel.FOptions.Values['TruckProber']);
    Exit;
  end;

  case nTunnel.FStatusNew of
   bsInit      : WriteNearReaderLog('初始化:' + nTunnel.FID   + '单据号：' + nTunnel.FBill);
   bsNew       : WriteNearReaderLog('新添加:' + nTunnel.FID   + '单据号：' + nTunnel.FBill);
   bsStart     : WriteNearReaderLog('开始称重:' + nTunnel.FID + '单据号：' + nTunnel.FBill);
   bsClose     : WriteNearReaderLog('称重关闭:' + nTunnel.FID + '单据号：' + nTunnel.FBill);
   bsDone      : WriteNearReaderLog('称重完成:' + nTunnel.FID + '单据号：' + nTunnel.FBill);
   bsStable    : WriteNearReaderLog('数据平稳:' + nTunnel.FID + '单据号：' + nTunnel.FBill);
   bsError     : WriteNearReaderLog('地磅连接故障:' + nTunnel.FID + '单据号：' + nTunnel.FBill);
  end; //log

  if nTunnel.FStatusNew = bsClose then
  begin
    ShowLEDHint(nTunnel.FID, '装车业务关闭', nTunnel.FParams.Values['Truck'],nTunnel.FTunnel.FOptions.Values['TruckProber']);
    WriteNearReaderLog(nTunnel.FID+'装车业务关闭');

    {$IFDEF UseERelayPLC}
    if nTunnel.FTunnel.FOptions.Values['TruckProber'] <> 'Y' then
    begin
      gERelayManagerPLC.CloseTunnel(nTunnel.FID+'_N');
      WriteNearReaderLog(nTunnel.FID+'装车业务关闭,关闭放灰');
    end
    else
    begin
    {$IFDEF BasisWeightTruckProber}
      gProberManager.CloseTunnel(nTunnel.FID+'_O');
      WriteNearReaderLog(nTunnel.FID+'装车业务关闭,关闭放灰');
    {$ENDIF}
    end;
    {$ENDIF}
    
    gBasisWeightManager.SetParam(nTunnel.FID, 'CanFH', sFlag_No);
    //通知DCS关闭装车
    Exit;
  end;

  if nTunnel.FStatusNew = bsError then
  begin
    ShowLEDHint(nTunnel.FID, '地磅连接故障', nTunnel.FParams.Values['Truck'],nTunnel.FTunnel.FOptions.Values['TruckProber']);
    {$IFDEF UseERelayPLC}
    if nTunnel.FTunnel.FOptions.Values['TruckProber'] <> 'Y' then
    begin
      gERelayManagerPLC.CloseTunnel(nTunnel.FID+'_N');
    end
    else
    begin
    {$IFDEF BasisWeightTruckProber}
      gProberManager.CloseTunnel(nTunnel.FID+'_O');
    {$ENDIF}
    end;
    {$ENDIF}
    WriteNearReaderLog(nTunnel.FID+'地磅连接故障');

    //尝试重新连接
    gBasisWeightManager.TunnelManager.ClosePort(nTunnel.FID);
    nTunnel.FEnable := gBasisWeightManager.TunnelManager.ActivePort(nTunnel.FID, nil, True);
    {$IFDEF UseERelayPLC}
    if nTunnel.FTunnel.FOptions.Values['TruckProber'] <> 'Y' then
    begin
      gERelayManagerPLC.CloseTunnel(nTunnel.FID+'_N');
      WriteNearReaderLog(nTunnel.FID+'关闭放灰');
    end
    else
    begin
    {$IFDEF BasisWeightTruckProber}
      gProberManager.CloseTunnel(nTunnel.FID+'_O');
    {$ENDIF}
    end;
    {$ENDIF}
    
    gBasisWeightManager.SetParam(nTunnel.FID, 'CanFH', sFlag_No);
    //通知DCS关闭装车
    Exit;
  end;

  if nTunnel.FStatusNew = bsDone then
  begin
    {$IFDEF BasisWeightWithPM}
      ShowLEDHint(nTunnel.FID, '装车完成请等待保存称重','',nTunnel.FTunnel.FOptions.Values['TruckProber']);
      WriteNearReaderLog(nTunnel.FID+'装车完成请等待保存称重');
    {$ELSE}
      ShowLEDHint(nTunnel.FID, '装车完成 请下磅');
      {$IFDEF UseERelayPLC}
      if nTunnel.FTunnel.FOptions.Values['TruckProber'] <> 'Y' then
      begin
        gERelayManagerPLC.OpenTunnel(nTunnel.FID + '_Z');
        WriteNearReaderLog(nTunnel.FID+'装车完成,打开出口道闸,红绿灯');
      end
      else
      begin
        gProberManager.OpenTunnel(nTunnel.FID + '_Z');
      end;
      {$ELSE}
        gProberManager.OpenTunnel(nTunnel.FID + '_Z');
      {$ENDIF}
    //打开道闸
    {$ENDIF}

    {$IFDEF UseERelayPLC}
    if nTunnel.FTunnel.FOptions.Values['TruckProber'] = '' then
    begin
      gERelayManagerPLC.CloseTunnel(nTunnel.FID+'_N');
      WriteNearReaderLog(nTunnel.FID+'装车完成,关闭放灰');
    end
    else
    begin
    {$IFDEF BasisWeightTruckProber}
      gProberManager.CloseTunnel(nTunnel.FID+'_O');
    {$ELSE}
      gERelayManager.LineClose(nTunnel.FID);
    {$ENDIF}
    end;
    {$ELSE}
      gERelayManager.LineClose(nTunnel.FID);
    {$ENDIF}

    {$IFDEF HKVDVR}
    gCameraManager.CapturePicture(nTunnel.FID, nTunnel.FBill);
    //抓拍
    {$ENDIF}
    
    //停止装车
    gBasisWeightManager.SetParam(nTunnel.FID, 'CanFH', sFlag_No);
    //通知DCS关闭装车
    Exit;
  end;

  if nTunnel.FStatusNew = bsStable then
  begin
    {$IFNDEF BasisWeightWithPM}
    Exit; //非库底计量,不保存数据
    {$ENDIF}

    {$IFDEF UseERelayPLC}
    if nTunnel.FTunnel.FOptions.Values['TruckProber'] <> 'Y' then
    begin
      if not gERelayManagerPLC.IsTunnelOK(nTunnel.FID) then
      begin
        nTunnel.FStableDone := False;
        //继续触发事件
        ShowLEDHint(nTunnel.FID, '车辆未停到位 请移动车辆','',nTunnel.FTunnel.FOptions.Values['TruckProber']);
        //语音播报
        if Assigned(gNetVoiceHelper) then
          gNetVoiceHelper.PlayVoice('车辆未停到位请移动车辆',nTunnel.FID);
        Exit;
      end;
    end
    else
    begin
      if not gProberManager.IsTunnelOK(nTunnel.FID) then
      begin
        nTunnel.FStableDone := False;
        //继续触发事件
        ShowLEDHint(nTunnel.FID, '车辆未停到位 请移动车辆','','Y');
        //语音播报
        if Assigned(gNetVoiceHelper) then
          gNetVoiceHelper.PlayVoice('车辆未停到位请移动车辆',nTunnel.FID);
        Exit;
      end;
    end;
    {$ELSE}
      if not gProberManager.IsTunnelOK(nTunnel.FID) then
      begin
        nTunnel.FStableDone := False;
        //继续触发事件
        ShowLEDHint(nTunnel.FID, '车辆未停到位 请移动车辆','','Y');
        Exit;
      end;
    {$ENDIF}

    //ShowLEDHint(nTunnel.FID, '数据平稳准备保存称重');
    WriteNearReaderLog(nTunnel.FID+'数据平稳准备保存称重');
                                   
    if SavePoundData(nTunnel, nTunnel.FValHas,nMsg) then
    begin
      gBasisWeightManager.SetParam(nTunnel.FID, 'CanFH', sFlag_Yes);
      //添加可放灰标记

      if nTunnel.FWeightDone then
      begin
        ShowLEDHint(nTunnel.FID, '毛重'+ FloatToStr(nTunnel.FValHas) +'保存完毕请下磅.','',nTunnel.FTunnel.FOptions.Values['TruckProber']);
        WriteNearReaderLog(nTunnel.FID+'毛重'+ FloatToStr(nTunnel.FValHas) +'保存完毕,请下磅');
        {$IFDEF UseERelayPLC}
        if nTunnel.FTunnel.FOptions.Values['TruckProber'] = '' then
        begin
          gERelayManagerPLC.OpenTunnel(nTunnel.FID+ '_Z');
          gERelayManagerPLC.CloseTunnel(nTunnel.FID+'_N');
          WriteNearReaderLog(nTunnel.FID+'毛重保存完毕,打开出口道闸,红绿灯,关闭放灰');
        end
        else
        begin
        {$IFDEF BasisWeightTruckProber}
          gProberManager.OpenTunnel(nTunnel.FID + '_Z');
          gProberManager.CloseTunnel(nTunnel.FID +'_O');
        {$ELSE}
          gProberManager.OpenTunnel(nTunnel.FID + '_Z');
        {$ENDIF}
        end;
          //语音播报
          if Assigned(gNetVoiceHelper) then
            gNetVoiceHelper.PlayVoice(nTunnel.FParams.Values['Truck']+'装车完毕请下磅',nTunnel.FID);
        {$ELSE}
          gProberManager.OpenTunnel(nTunnel.FID + '_Z');
        {$ENDIF}

        {$IFDEF HKVDVR}
        gCameraManager.CapturePicture(nTunnel.FID, nTunnel.FBill);
        //抓拍
        {$ENDIF}
        
      end else
      begin
        //ShowLEDHint(nTunnel.FID, '保存完毕请等待装车.');
        WriteNearReaderLog(nTunnel.FID+'保存完毕,请等待装车');
      end;
    end else
    begin
      nTunnel.FStableDone := False;
      //继续触发事件
      if nMsg <> '' then
      begin
        ShowLEDHint(nTunnel.FID, nMsg,'',nTunnel.FTunnel.FOptions.Values['TruckProber']);
        WriteNearReaderLog(nTunnel.FID+nMsg);
      end
      else
      begin
        ShowLEDHint(nTunnel.FID, '保存失败请联系管理员','',nTunnel.FTunnel.FOptions.Values['TruckProber']);
        WriteNearReaderLog(nTunnel.FID+'保存失败 请联系管理员');
      end;
    end;
  end;
end;

//Date: 2019-03-19
//Parm: 通道列表
//Desc: 装车线状态切换
procedure WhenTruckLineChanged(const nTruckLine: TList);
var nStr: string;
    nIdx: Integer;
    nLine: PLineItem;
begin
  for nIdx:=nTruckLine.Count - 1 downto 0 do
  begin
    nLine := nTruckLine[nIdx];
    if nLine.FIsValid then
         nStr := '1'
    else nStr := '0';

    gBasisWeightManager.SetParam(nLine.FLineID, 'LineStatus', nStr, True);
    //更新通道状态

//    {$IFDEF ReverseTrafficLight}
//      if nLine.FIsValid then
//           gProberManager.CloseTunnel(nLine.FLineID)
//      else gProberManager.OpenTunnel(nLine.FLineID);
//    {$ELSE}
//      if nLine.FIsValid then
//           gProberManager.OpenTunnel(nLine.FLineID)
//      else gProberManager.CloseTunnel(nLine.FLineID);
//    {$ENDIF} //同步道闸
  end;
end;

function VerifySnapTruck(const nTruck,nBill,nPos,nDept: string;var nResult: string): Boolean;
var nList: TStrings;
    nOut: TWorkerBusinessCommand;
    nID,nDefDept: string;
begin
  nDefDept := '门岗';
  if nBill = '' then
    nID := nTruck + FormatDateTime('YYMMDD',Now)
  else
    nID := nBill;
  nList := nil;
  try
    nList := TStringList.Create;
    nList.Values['Truck'] := nTruck;
    nList.Values['Bill'] := nID;
    nList.Values['Pos'] := nPos;
    if nDept = '' then
      nList.Values['Dept'] := nDefDept
    else
      nList.Values['Dept'] := nDept;

    Result := CallBusinessCommand(cBC_VerifySnapTruck, nList.Text, '', @nOut);
    nResult := nOut.FData;
  finally
    nList.Free;
  end;
end;

{$IFDEF HKVDVR}
procedure WhenCaptureFinished(const nPtr: Pointer);
var nStr: string;
    nDS: TDataSet;
    nPic: TPicture;
    nDBConn: PDBWorker;
    nErrNum, nRID: Integer;
    nCapture: PCameraFrameCapture;
begin
  nDBConn := nil;
  {$IFDEF DEBUG}
  WriteHardHelperLog('WhenCaptureFinished进入.');
  {$ENDIF}

  nCapture :=  PCameraFrameCapture(nPtr);
  if not FileExists(nCapture.FCaptureName) then Exit;

  with gParamManager.ActiveParam^ do
  try
    nDBConn := gDBConnManager.GetConnection(FDB.FID, nErrNum);
    if not Assigned(nDBConn) then
    begin
      WriteHardHelperLog('连接HM数据库失败(DBConn Is Null).');
      Exit;
    end;

    if not nDBConn.FConn.Connected then
      nDBConn.FConn.Connected := True;
    //conn db

    nDBConn.FConn.BeginTrans;
    try
      nStr := MakeSQLByStr([
              SF('P_ID', nCapture.FCaptureFix),
              //SF('P_Name', nCapture.FCaptureName),
              SF('P_Date', sField_SQLServer_Now, sfVal)
              ], sTable_Picture, '', True);
      //xxxxx

      if gDBConnManager.WorkerExec(nDBConn, nStr) < 1 then Exit;

      nStr := 'Select Max(%s) From %s';
      nStr := Format(nStr, ['R_ID', sTable_Picture]);
      with gDBConnManager.WorkerQuery(nDBConn, nStr) do
        nRID := Fields[0].AsInteger;

      nStr := 'Select P_Picture From %s Where R_ID=%d';
      nStr := Format(nStr, [sTable_Picture, nRID]);
      nDS := gDBConnManager.WorkerQuery(nDBConn, nStr);

      WriteHardHelperLog('开始保存图片:' + IntToStr(nRID) + ',路径:' + nCapture.FCaptureName);
      nPic := nil;
      try
        nPic := TPicture.Create;
        nPic.LoadFromFile(nCapture.FCaptureName);
        SaveDBImage(nDS, 'P_Picture', nPic.Graphic);
        WriteHardHelperLog('保存图片成功:' + IntToStr(nRID));
        FreeAndNil(nPic);
      except
        if Assigned(nPic) then nPic.Free;
      end;

      DeleteFile(nCapture.FCaptureName);
      nDBConn.FConn.CommitTrans;
    except
      nDBConn.FConn.RollbackTrans;
    end;
  finally
    gDBConnManager.ReleaseConnection(nDBConn);
  end;
end;
{$ENDIF}

end.
