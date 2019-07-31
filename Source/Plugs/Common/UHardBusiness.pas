{*******************************************************************************
  ����: dmzn@163.com 2012-4-22
  ����: Ӳ������ҵ��
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
//���¿��ŵ����ͷ
procedure WhenTTCE_M100_ReadCard(const nItem: PM100ReaderItem);
//Ʊ�������
procedure WhenReaderCardIn(const nCard: string; const nHost: PReaderHost);
//�ֳ���ͷ���¿���
procedure WhenReaderCardOut(const nCard: string; const nHost: PReaderHost);
//�ֳ���ͷ���ų�ʱ
procedure WhenBusinessMITSharedDataIn(const nData: string);
//ҵ���м����������
function WhenParsePoundWeight(const nPort: PPTPortItem): Boolean;
//�ذ����ݽ���
procedure WhenBasisWeightStatusChange(const nTunnel: PBWTunnel);
//����װ��״̬�ı�
procedure WhenTruckLineChanged(const nTruckLine: TList);
//ͨ��״̬�л�
function VerifySnapTruck(const nTruck,nBill,nPos,nDept: string;
  var nResult: string): Boolean;
//����ʶ��
{$IFDEF HKVDVR}
procedure WhenCaptureFinished(const nPtr: Pointer);
//����ͼƬ
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
//Parm: ����;����;����;���
//Desc: ���ص���ҵ�����
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
//Parm: ����;����;����;���
//Desc: �����м���ϵ����۵��ݶ���
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
//Parm: ����;����;����;���
//Desc: �����м���ϵ����۵��ݶ���
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
//Parm: ����;����;����;���
//Desc: ����Ӳ���ػ��ϵ�ҵ�����
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
//Parm: �ſ���;��λ;�������б�
//Desc: ��ȡnPost��λ�ϴſ�ΪnCard�Ľ������б�
function GetLadingBills(const nCard,nPost: string;
 var nData: TLadingBillItems): Boolean;
var nOut: TWorkerBusinessCommand;
begin
  Result := CallBusinessSaleBill(cBC_GetPostBills, nCard, nPost, @nOut);
  if Result then
       AnalyseBillItems(nOut.FData, nData)
  else gSysLoger.AddLog(TBusinessWorkerManager, 'ҵ�����', nOut.FData);
end;

//Date: 2014-09-18
//Parm: ��λ;�������б�
//Desc: ����nPost��λ�ϵĽ���������
function SaveLadingBills(const nPost: string; nData: TLadingBillItems): Boolean;
var nStr: string;
    nOut: TWorkerBusinessCommand;
begin
  nStr := CombineBillItmes(nData);
  Result := CallBusinessSaleBill(cBC_SavePostBills, nStr, nPost, @nOut);

  if not Result then
    gSysLoger.AddLog(TBusinessWorkerManager, 'ҵ�����', nOut.FData);
  //xxxxx
end;

//Date: 2015-08-06
//Parm: �ſ���
//Desc: ��ȡ�ſ�ʹ������
function GetCardUsed(const nCard: string; var nCardType: string): Boolean;
var nOut: TWorkerBusinessCommand;
begin
  Result := CallBusinessCommand(cBC_GetCardUsed, nCard, '', @nOut);

  if Result then
       nCardType := nOut.FData
  else gSysLoger.AddLog(TBusinessWorkerManager, 'ҵ�����', nOut.FData);
  //xxxxx
end;

//Date: 2015-08-06
//Parm: �ſ���;��λ;�ɹ����б�
//Desc: ��ȡnPost��λ�ϴſ�ΪnCard�Ľ������б�
function GetLadingOrders(const nCard,nPost: string;
 var nData: TLadingBillItems): Boolean;
var nOut: TWorkerBusinessCommand;
begin
  Result := CallBusinessPurchaseOrder(cBC_GetPostOrders, nCard, nPost, @nOut);
  if Result then
       AnalyseBillItems(nOut.FData, nData)
  else gSysLoger.AddLog(TBusinessWorkerManager, 'ҵ�����', nOut.FData);
end;

//Date: 2015-08-06
//Parm: ��λ;�ɹ����б�
//Desc: ����nPost��λ�ϵĲɹ�������
function SaveLadingOrders(const nPost: string; nData: TLadingBillItems): Boolean;
var nStr: string;
    nOut: TWorkerBusinessCommand;
begin
  nStr := CombineBillItmes(nData);
  Result := CallBusinessPurchaseOrder(cBC_SavePostOrders, nStr, nPost, @nOut);

  if not Result then
    gSysLoger.AddLog(TBusinessWorkerManager, 'ҵ�����', nOut.FData);
  //xxxxx
end;
                                                             
//------------------------------------------------------------------------------
//Date: 2013-07-21
//Parm: �¼�����;��λ��ʶ
//Desc:
procedure WriteHardHelperLog(const nEvent: string; nPost: string = '');
begin
  //gDisplayManager.Display(nPost, nEvent);
  gSysLoger.AddLog(THardwareHelper, 'Ӳ���ػ�����', nEvent);
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
    WriteHardHelperLog('���������̧��:' + nReader);
  end;
end;

//Date: 2012-4-22
//Parm: ����
//Desc: ��nCard���н���
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
  end; //ͬ��ͷͬ��,��2�����ڲ������ν���ҵ��.

  nCardType := '';
  if not GetCardUsed(nCard, nCardType) then Exit;

  if nCardType = sFlag_Provide then
        nRet := GetLadingOrders(nCard, sFlag_TruckIn, nTrucks)
  else  nRet := GetLadingBills(nCard, sFlag_TruckIn, nTrucks);

  if not nRet then
  begin
    nStr := '��ȡ�ſ�[ %s ]������Ϣʧ��.';
    nStr := Format(nStr, [nCard]);

    WriteHardHelperLog(nStr, sPost_In);
    Exit;
  end;

  if Length(nTrucks) < 1 then
  begin
    nStr := '�ſ�[ %s ]û����Ҫ��������.';
    nStr := Format(nStr, [nCard]);

    WriteHardHelperLog(nStr, sPost_In);
    Exit;
  end;

  for nIdx:=Low(nTrucks) to High(nTrucks) do
  with nTrucks[nIdx] do
  begin
    if gTruckQueueManager.IsFobiddenInMul then//��ֹ��ν���
    begin
      if FStatus = sFlag_TruckNone then Continue;
      //δ����
    end
    else
    begin
      if (FStatus = sFlag_TruckNone) or (FStatus = sFlag_TruckIn) then Continue;
      //δ����,���ѽ���
    end;

    nStr := '����[ %s ]��һ״̬Ϊ:[ %s ],����ˢ����Ч.';
    nStr := Format(nStr, [FTruck, TruckStatusToStr(FNextStatus)]);

    WriteHardHelperLog(nStr, sPost_In);
    Exit;
  end;

  {$IFDEF RemoteSnap}
  if (nTrucks[0].FStatus = sFlag_TruckNone) then//�ѽ������ж�
  if not VerifySnapTruck(nTrucks[0].FTruck,nTrucks[0].FID,nPost,nDept,nSnapStr) then
  begin
    nStr := nSnapStr+ '��������ʶ��ʧ��.';

    gHKSnapHelper.Display(nPost, nSnapStr, 3);
    //С����ʾ

    WriteHardHelperLog(nStr+'��λ:'+nPost);

    Exit;
  end;
  nStr := nSnapStr + ' �����';
  gHKSnapHelper.Display(nPost, nStr, 2);
    //С����ʾ
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
        //̧��

        nStr := '����[ %s ]�ٴ�̧�˲���.';
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
      nStr := '����[ %s ]��������ʧ��.';
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
      //̧��
    end;

    nStr := 'ԭ���Ͽ�[%s]����̧�˳ɹ�';
    nStr := Format(nStr, [nCard]);
    WriteHardHelperLog(nStr, sPost_In);
    Exit;
  end;
  //�ɹ��ſ�ֱ��̧��

  nPLine := nil;
  //nPTruck := nil;

  with gTruckQueueManager do
  if not IsDelayQueue then //����ʱ����(����ģʽ)
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
      nStr := '����[ %s ]û���ڵ��ȶ�����.';
      nStr := Format(nStr, [nTrucks[0].FTruck]);

      WriteHardHelperLog(nStr, sPost_In);
      Exit;
    end;
  finally
    SyncLock.Leave;
  end;

  if not SaveLadingBills(sFlag_TruckIn, nTrucks) then
  begin
    nStr := '����[ %s ]��������ʧ��.';
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
    //̧��
  end;

  with gTruckQueueManager do
  if not IsDelayQueue then //����ģʽ,����ʱ�󶨵���(һ���൥)
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
      //��ͨ��
    end;
  finally
    SyncLock.Leave;
  end;
end;

//Date: 2012-4-22
//Parm: ����;��ͷ;��ӡ��;���鵥��ӡ��
//Desc: ��nCard���г���
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
    nStr := '��ȡ�ſ�[ %s ]������Ϣʧ��.';
    nStr := Format(nStr, [nCard]);

    WriteHardHelperLog(nStr, sPost_Out);
    Exit;
  end;

  if Length(nTrucks) < 1 then
  begin
    nStr := '�ſ�[ %s ]û����Ҫ��������.';
    nStr := Format(nStr, [nCard]);

    WriteHardHelperLog(nStr, sPost_Out);
    Exit;
  end;

  for nIdx:=Low(nTrucks) to High(nTrucks) do
  with nTrucks[nIdx] do
  begin
    if FNextStatus = sFlag_TruckOut then Continue;
    nStr := '����[ %s ]��һ״̬Ϊ:[ %s ],�޷�����.';
    nStr := Format(nStr, [FTruck, TruckStatusToStr(FNextStatus)]);

    WriteHardHelperLog(nStr, sPost_Out);
    Exit;
  end;

  {$IFDEF RemoteSnap}
  //if (nTrucks[0].FStatus = sFlag_TruckNone) then//�ѽ������ж�
  if not VerifySnapTruck(nTrucks[0].FTruck,nTrucks[0].FID,nPost,nDept,nSnapStr) then
  begin
    nStr := nSnapStr+ '��������ʶ��ʧ��.';

    gHKSnapHelper.Display(nPost, nSnapStr, 3);
    //С����ʾ

    WriteHardHelperLog(nStr+'��λ:'+nPost);

    Exit;
  end;
  nStr := nSnapStr + ' �����';
  gHKSnapHelper.Display(nPost, nStr, 2);
    //С����ʾ
  {$ENDIF}

  if nCardType = sFlag_Provide then
        nRet := SaveLadingOrders(sFlag_TruckOut, nTrucks)
  else  nRet := SaveLadingBills(sFlag_TruckOut, nTrucks);

  if not nRet then
  begin
    nStr := '����[ %s ]��������ʧ��.';
    nStr := Format(nStr, [nTrucks[0].FTruck]);

    WriteHardHelperLog(nStr, sPost_Out);
    Exit;
  end;

  if (nReader <> '') and (Copy(nReader,1,1) <> 'V') then
    BlueOpenDoor(nReader, nReaderType); //̧��
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
    //�ſ�����
    if nHYPrinter <> '' then
      nStr := nStr + #6 + nHYPrinter;
    //���鵥��ӡ��

    if nPrinter = '' then
         gRemotePrinter.PrintBill(nTrucks[nIdx].FID + nStr)
    else gRemotePrinter.PrintBill(nTrucks[nIdx].FID + #9 + nPrinter + nStr);
  end; //��ӡ����
end;

//Date: 2012-10-19
//Parm: ����;��ͷ
//Desc: ��⳵���Ƿ��ڶ�����,�����Ƿ�̧��
procedure MakeTruckPassGate(const nCard,nReader: string; const nDB: PDBWorker;
                            const nReaderType: string = '');
var nStr: string;
    nIdx: Integer;
    nTrucks: TLadingBillItems;
begin
  if not GetLadingBills(nCard, sFlag_TruckOut, nTrucks) then
  begin
    nStr := '��ȡ�ſ�[ %s ]��������Ϣʧ��.';
    nStr := Format(nStr, [nCard]);

    WriteHardHelperLog(nStr);
    Exit;
  end;

  if Length(nTrucks) < 1 then
  begin
    nStr := '�ſ�[ %s ]û����Ҫͨ����բ�ĳ���.';
    nStr := Format(nStr, [nCard]);

    WriteHardHelperLog(nStr);
    Exit;
  end;

  if gTruckQueueManager.TruckInQueue(nTrucks[0].FTruck) < 0 then
  begin
    nStr := '����[ %s ]���ڶ���,��ֹͨ����բ.';
    nStr := Format(nStr, [nTrucks[0].FTruck]);

    WriteHardHelperLog(nStr);
    Exit;
  end;

  BlueOpenDoor(nReader, nReaderType);
  //̧��

  for nIdx:=Low(nTrucks) to High(nTrucks) do
  begin
    nStr := 'Update %s Set T_InLade=%s Where T_Bill=''%s'' And T_InLade Is Null';
    nStr := Format(nStr, [sTable_ZTTrucks, sField_SQLServer_Now, nTrucks[nIdx].FID]);

    gDBConnManager.WorkerExec(nDB, nStr);
    //�������ʱ��,�������򽫲��ٽк�.
  end;
end;

//Date: 2014-10-25
//Parm: ��ͷ����
//Desc: �����ͷ�ſ�����
procedure WhenHYReaderCardArrived(const nReader: PHYReaderItem);
begin
  {$IFDEF DEBUG}
  WriteHardHelperLog(Format('�����ǩ %s:%s', [nReader.FTunnel, nReader.FCard]));
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
//Parm: ����һ������
//Desc: ��������һ��������Ϣ
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
  nStr := '����һ����������'  + nItem.FID + ' ::: ' + nItem.FCard;
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
              WriteHardHelperLog('����HM���ݿ�ʧ��(DBConn Is Null).');
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
          WriteHardHelperLog('�̿���ִ��״̬:'+'������:'+nCType+'����:�̿�')
        else
          WriteHardHelperLog('�̿���ִ��״̬:'+'������:'+nCType+'����:�̿����¿�');
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
  gSysLoger.AddLog(T02NReader, '�ֳ����������', nEvent);
end;

//Date: 2019-03-12
//Parm: ͨ����;��ʾ��Ϣ;���ƺ�
//Desc: ��nTunnel��С������ʾ��Ϣ
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
//Parm: ����;ͨ��;�Ƿ����Ⱥ�˳��;��ʾ��Ϣ
//Desc: ���nTuck�Ƿ������nTunnelװ��
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
      nHint := Format('ͨ��[ %s ]��Ч.', [nTunnel]);
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
        //���ڵ�ǰ����
        if not StockMatch(nPLine.FStockNo, nLineItem) then Continue;
        //ˢ��������е�Ʒ�ֲ�ƥ��

        nIdx := nPLine.FTrucks.Add(nLineItem.FTrucks[nInt]);
        nLineItem.FTrucks.Delete(nInt);
        //Ų���������µ�

        nHint := 'Update %s Set T_Line=''%s'' ' +
                 'Where T_Truck=''%s'' And T_Line=''%s''';
        nHint := Format(nHint, [sTable_ZTTrucks, nPLine.FLineID, nTruck,
                nLineItem.FLineID]);
        gTruckQueueManager.AddExecuteSQL(nHint);

        nHint := '����[ %s ]��������[ %s->%s ]';
        nHint := Format(nHint, [nTruck, nLineItem.FName, nPLine.FName]);
        WriteNearReaderLog(nHint);
        Break;
      end;
    end;
    //��װ�ص�����

    if nIdx < 0 then
    begin
      nHint := Format('����[ %s ]����[ %s ]������.', [nTruck, nPLine.FName]);
      Exit;
    end;

    nPTruck := nPLine.FTrucks[nIdx];
    nPTruck.FStockName := nPLine.FName;
    //ͬ��������
    Result := True;
  finally
    SyncLock.Leave;
  end;
end;

//Date: 2019-03-12
//Parm: ����;ͨ��;Ƥ��
//Desc: ��ȨnTruck��nTunnel�����Ż�
procedure TruckStartFH(const nTruck: PTruckItem; const nTunnel: string;
 const nLading: TLadingBillItem; const UnPLC:string = '');
var nStr: string;
begin
  {$IFDEF UseERelayPLC}
    if UnPLC = '' then
    begin
      gERelayManagerPLC.OpenTunnel(nTunnel);
      WriteNearReaderLog(nTunnel+'�򿪽�����բ,���̵�');
    end
    else
    begin
      {$IFDEF BasisWeightTruckProber}
        gProberManager.OpenTunnel(nTunnel);
      {$ELSE}
        gERelayManager.LineOpen(nTunnel);
      {$ENDIF}
    end;
    //��������
    if Assigned(gNetVoiceHelper) then
      gNetVoiceHelper.PlayVoice(nLading.FTruck+'ˢ���ɹ����ϰ�',nTunnel);
  {$ELSE}
    gERelayManager.LineOpen(nTunnel);
  {$ENDIF}
  //��ʼ�Ż�

  nStr := Format('Truck=%s', [nTruck.FTruck]);
  gBasisWeightManager.StartWeight(nTunnel, nTruck.FBill, nTruck.FValue,
    nLading.FPData.FValue, nStr);
  //��ʼ����װ��

  if nLading.FStatus <> sFlag_TruckIn then
  begin
    {$IFDEF UseERelayPLC}
      if UnPLC = '' then
      begin
        gERelayManagerPLC.OpenTunnel(nTunnel+'_O');
        WriteNearReaderLog(nTunnel+'����Ż�');
      end
      else
      begin
        {$IFDEF BasisWeightTruckProber}
          gProberManager.OpenTunnel(nTunnel+'_O');
        {$ENDIF}
      end;
    {$ENDIF}
    gBasisWeightManager.SetParam(nTunnel, 'CanFH', sFlag_Yes);
  //��ӿɷŻұ��
  end;
end;

//Date: 2019-03-12
//Parm: �ſ���;ͨ����
//Desc: ��nCardִ�д�װװ������
procedure MakeTruckLadingSan(const nCard,nTunnel: string);
begin

end;

//Date: 2019-03-12
//Parm: �ſ���;ͨ����
//Desc: ��nCardִ�г�������
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
  WriteNearReaderLog('MakeTruckWeightFirst����.');
  {$ENDIF}

  if not GetLadingBills(nCard, sFlag_TruckFH, nTrucks) then
  begin
    nStr := '��ȡ�ſ�[ %s ]��������Ϣʧ��.';
    nStr := Format(nStr, [nCard]);

    WriteNearReaderLog(nStr);
    ShowLEDHint(nTunnel, '��ȡ��������Ϣʧ��','',UnPLC);
    Exit;
  end;

  if Length(nTrucks) < 1 then
  begin
    nStr := '�ſ�[ %s ]û����Ҫװ�ϳ���.';
    nStr := Format(nStr, [nCard]);

    WriteNearReaderLog(nStr);
    ShowLEDHint(nTunnel, 'û����Ҫװ�ϳ���','',UnPLC);
    Exit;
  end;

  for nIdx:=Low(nTrucks) to High(nTrucks) do
  with nTrucks[nIdx] do
  begin
    if FStatus = sFlag_TruckNone then
    begin
      ShowLEDHint(nTunnel, '�����ˢ��', nTrucks[0].FTruck,UnPLC);
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
        ShowLEDHint(nTunnel, 'ͨ��δ����', nTrucks[0].FTruck,UnPLC);
        Exit;
      end;
    end;

    if gBasisWeightManager.IsTunnelBusy(nTunnel, @nPound) and
       (nPound.FBill <> nTrucks[0].FID) then //ͨ��æ
    begin
      if nPound.FValTunnel = 0 then //ǰ�����°�
      begin
        nStr := Format('%s ��ȴ�ǰ��', [nTrucks[0].FTruck]);
        ShowLEDHint(nTunnel, nStr,'',UnPLC);
        Exit;
      end;
    end;
  end;


  WriteNearReaderLog('ͨ��' + nTunnel +'��ǰҵ��:' + nPound.FBill +
                     '��ˢ��:' + nTrucks[0].FID);

  if nPound.FBill <> '' then
  if (nPound.FBill <> nTrucks[0].FID) then //ǰ��ҵ��δ��ɺ�ˢ��
  begin
    if (nPound.FValTunnel < 0) or (nPound.FValTunnel > nPound.FTunnel.FPort.FMinValue) then 
    begin
      nStr := Format('%s.%s �ذ������쳣', [nTrucks[0].FID, nTrucks[0].FTruck]);
      WriteNearReaderLog(nStr);
      Exit;
    end;
  end;

  if not IsTruckInQueue(nTrucks[0].FTruck, nTunnel, False, nStr,
         nPTruck, nPLine, sFlag_San) then
  begin
    WriteNearReaderLog(nStr);
    ShowLEDHint(nTunnel, '�뻻��װ��', nTrucks[0].FTruck,UnPLC);
    Exit;
  end; //���ͨ��

  if nTrucks[0].FStatus = sFlag_TruckIn then
  begin
    nStr := '����[ %s ]ˢ��,�ȴ���Ƥ��.';
    nStr := Format(nStr, [nTrucks[0].FTruck]);
    WriteNearReaderLog(nStr);

    nStr := Format('�� %s �ϰ�����Ƥ��', [nTrucks[0].FTruck]);
    ShowLEDHint(nTunnel, nStr,'',UnPLC);
  end else
  begin
    if nPound.FValTunnel > 0 then
         nStr := '���ϰ�װ��'
    else nStr := '�뿪ʼװ��';

    ShowLEDHint(nTunnel, nStr, nTrucks[0].FTruck,UnPLC);
  end;

  TruckStartFH(nPTruck, nTunnel, nTrucks[0],UnPLC);
  //ִ�зŻ�
end;

//Date: 2012-4-22
//Parm: ��ͷ����
//Desc: ��nReader�����Ŀ��������嶯��
procedure WhenReaderCardArrived(const nReader: THHReaderItem);
var nStr,nCard,nReaderType: string;
    nErrNum: Integer;
    nDBConn: PDBWorker;
begin
  nDBConn := nil;
  {$IFDEF DEBUG}
  WriteHardHelperLog('WhenReaderCardArrived����.');
  {$ENDIF}

  with gParamManager.ActiveParam^ do
  try
    nDBConn := gDBConnManager.GetConnection(FDB.FID, nErrNum);
    if not Assigned(nDBConn) then
    begin
      WriteHardHelperLog('����HM���ݿ�ʧ��(DBConn Is Null).');
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
      nStr := Format('�ſ���[ %s ]ƥ��ʧ��.', [nReader.FCard]);
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
          //̧��
        end else

        if nReader.FType = rtQueueGate then
        begin
          if nReader.FID <> '' then
            MakeTruckPassGate(nCard, nReader.FID, nDBConn, nReaderType);
          //̧��
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
//Parm: ����;����
//Desc: ��nHost.nCard�µ�������������
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
    else //��ˢ֧�ֶ���װ��
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
    //���Ӳ���
  end;
end;

//Date: 2012-4-24
//Parm: ����;����
//Desc: ��nHost.nCard��ʱ����������
procedure WhenReaderCardOut(const nCard: string; const nHost: PReaderHost);
begin
  {$IFDEF DEBUG}
  WriteHardHelperLog('WhenReaderCardOut�˳�.');
  {$ENDIF}

  {$IFDEF UseERelayPLC}
  if nHost.FOptions.Values['TruckProber'] = '' then
  begin
    gERelayManagerPLC.CloseTunnel(nHost.FTunnel+'_N');
    WriteNearReaderLog(nHost.FTunnel+'�رշŻ�');
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
      gERelayManagerPLC.ShowText(nHost.FTunnel, '���ӱ�ǩ������Χ')
    else
      gERelayManager.ShowTxt(nHost.FTunnel, '���ӱ�ǩ������Χ');
    {$ELSE}
      gERelayManager.ShowTxt(nHost.FTunnel, '���ӱ�ǩ������Χ');
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
//Parm: �ſ���
//Desc: ��nCardNo���Զ�����(ģ���ͷˢ��)
procedure MakeTruckAutoOut(const nCardNo: string);
var nReader: string;
begin
  if gTruckQueueManager.IsTruckAutoOut then
  begin
    nReader := gHardwareHelper.GetReaderLastOn(nCardNo);
    if nReader <> '' then
      gHardwareHelper.SetReaderCard(nReader, nCardNo);
    //ģ��ˢ��
  end;
end;

//Date: 2012-12-16
//Parm: ��������
//Desc: ����ҵ���м����Ӳ���ػ��Ľ�������
procedure WhenBusinessMITSharedDataIn(const nData: string);
begin
  WriteHardHelperLog('�յ�Bus_MITҵ������:::' + nData);
  //log data

  if Pos('TruckOut', nData) = 1 then
    MakeTruckAutoOut(Copy(nData, Pos(':', nData) + 1, MaxInt));
  //auto out
end;

//------------------------------------------------------------------------------
//Date: 2019-03-12
//Parm: �˿�
//Desc: ������վ����
function WhenParsePoundWeight(const nPort: PPTPortItem): Boolean;
var nIdx,nLen: Integer;
    nVerify: Word;
    nBuf: TIdBytes;
begin
  Result := False;
  nBuf := ToBytes(nPort.FCOMBuff, Indy8BitEncoding);
  nLen := Length(nBuf) - 2;
  if nLen < 52 then Exit; //48-51Ϊ��������

  nVerify := 0;
  nIdx := 0;

  while nIdx < nLen do
  begin
    nVerify := nBuf[nIdx] + nVerify;
    Inc(nIdx);
  end;

  if (nBuf[nLen] <> (nVerify shr 8 and $00ff)) or
     (nBuf[nLen+1] <> (nVerify and $00ff)) then Exit;
  //У��ʧ��

  nPort.FCOMData := IntToStr(StrToInt('$' +
    IntToHex(nBuf[51], 2) + IntToHex(nBuf[50], 2) +
    IntToHex(nBuf[49], 2) + IntToHex(nBuf[48], 2)));
  //ë����ʾ����

  Result := True;
end;

//Desc: ����ͼƬ·��
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
  //���Դ���
var nStr,nTmp: string;
    nIdx,nInt: Integer;
    nLogin,nErr: Integer;
    nPic: NET_DVR_JPEGPARA;
    nInfo: TNET_DVR_DEVICEINFO;
begin
  nList.Clear;

  if not Assigned(nTunnel.FCamera) then
  begin
    WriteNearReaderLog('ץ��ͨ����Ч');
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
        nStr := '��¼�����[ %s.%d ]ʧ��,������: %d';
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
        WriteNearReaderLog('ץ��ͼƬ·��:'+nStr);
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
          nStr := 'ץ��ͼ��[ %s.%d ]ʧ��,������: %d';
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
        WriteNearReaderLog('����HM���ݿ�ʧ��(DBConn Is Null).');
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
        WriteNearReaderLog('����ץ��'+nStr);

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
//Parm: ��������;����
//Desc: ����nBill״̬д��nValue����
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
        WriteNearReaderLog(Format('������[ %s ]�Ѷ�ʧ', [nTunnel.FBill]));
        Exit;
      end;

      nStatus := FieldByName('L_Status').AsString;
      nTruck  := FieldByName('L_Truck').AsString;
      if nStatus = sFlag_TruckIn then //Ƥ��
      begin
        //����Ĭ��Ƥ��ֵ
        nStr := ' Select D_Value from %s  where D_Name = ''%s'' and D_Memo = ''%s''  ';
        nStr := Format(nStr, [sTable_SysDict, sFlag_SysParam,sFlag_DefaultPValue]);
        with gDBConnManager.WorkerQuery(nDBConn, nStr) do
        begin
          if RecordCount < 1 then
            nDefaultPValue := 21
          else
            nDefaultPValue :=  FieldByName('D_Value').AsFloat;
        end;
        //����Ƥ�����¸���ֵ
        nStr := ' Select D_Value from %s  where D_Name = ''%s'' and D_Memo = ''%s''  ';
        nStr := Format(nStr, [sTable_SysDict, sFlag_SysParam,sFlag_PValueWuCha]);
        with gDBConnManager.WorkerQuery(nDBConn, nStr) do
        begin
          if RecordCount < 1 then
            nPValueWuCha := 3
          else
            nPValueWuCha :=  FieldByName('D_Value').AsFloat;
        end;

        //�ж�Ƥ����Ч��
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
        //Ƥ����Ч��Χֵ
        if  (nValue < nPvalue - nPvalueWucha)  or (nValue > nPvalue + nPvalueWucha) then
        begin
          nMsg := 'Ƥ���쳣';
          WriteNearReaderLog(nTunnel.FID+'��ʷƽ��Ƥ�أ�'+FloatToStr(nPValue)
          +'��ǰƤ�أ�'+FloatToStr(nValue)+'������Χ��'+FloatToStr(nPValueWuCha));
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
        //����ͨ��Ƥ��, ȷ�ϰ�������
        {$IFDEF UseERelayPLC}
        if nTunnel.FTunnel.FOptions.Values['TruckProber'] = '' then
        begin
          gERelayManagerPLC.OpenTunnel(nTunnel.FID+'_O');
          WriteNearReaderLog(nTunnel.FID+'����Ƥ��,����Ż�');
        end
        else
        begin
          gProberManager.OpenTunnel(nTunnel.FID+'_O');
          WriteNearReaderLog(nTunnel.FID+'����Ƥ��,����Ż�');
        end;
          //����Ƥ��֮��ʼ�Ż�
          //��������
          if Assigned(gNetVoiceHelper) then
            gNetVoiceHelper.PlayVoice(nTunnel.FParams.Values['Truck']+'���������װ��',nTunnel.FID);
        {$ENDIF}

        {$IFDEF HKVDVR}
        gCameraManager.CapturePicture(nTunnel.FID, nTunnel.FBill);
        //ץ��
        {$ENDIF}
      end else
      begin
        nStr := MakeSQLByStr([SF('L_Status', sFlag_TruckBFM),
                SF('L_NextStatus', sFlag_TruckOut),
                SF('L_MValue', nValue, sfVal),
                SF('L_MDate', sField_SQLServer_Now, sfVal)
          ], sTable_Bill, SF('L_ID', nTunnel.FBill), False);
        gDBConnManager.WorkerExec(nDBConn, nStr);
        WriteNearReaderLog((nTunnel.FID+'����ë��ֵ��'+FloatToStr(nValue)));
      end; //�Ż�״̬,ֻ��������,����ʱ���㾻��
    end;

    Result := True;
  finally
    gDBConnManager.ReleaseConnection(nDBConn);
  end;   
end;

//Date: 2019-03-11
//Parm: ����װ��ͨ��
//Desc: ��nTunnel״̬�ı�ʱ,����ҵ��
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
          and (nTunnel.FValTunnel < nTunnel.FWeightMax * FLevel2) then  //ģ����1
        begin
          {$IFDEF UseERelayPLC}
          if nTunnel.FTunnel.FOptions.Values['TruckProber'] = '' then
          begin
            nTunnel.FLevel1 := True;
            gERelayManagerPLC.OpenTunnel(nTunnel.FID+'_O01');
            WriteNearReaderLog(nTunnel.FID+'��һ��'+' ��ǰ����'+FloatToStr(nTunnel.FValTunnel)+'��������'+FloatToStr(nTunnel.FWeightMax));
          end;
          {$ENDIF}
        end;
      end;
      if (FLevel2 > 0) and (FLevel2 < 1) then
      begin
        if (not nTunnel.FWeightDone) and (not nTunnel.FLevel2)
          and (nTunnel.FValTunnel >= nTunnel.FWeightMax * FLevel2)
          and (nTunnel.FValTunnel < (nTunnel.FWeightMax - 0.1)) then  //ģ����2
        begin
          {$IFDEF UseERelayPLC}
          if nTunnel.FTunnel.FOptions.Values['TruckProber'] = '' then
          begin
            nTunnel.FLevel2 := True;
            gERelayManagerPLC.OpenTunnel(nTunnel.FID+'_O02');
            WriteNearReaderLog(nTunnel.FID+'�ض���'+' ��ǰ����'+FloatToStr(nTunnel.FValTunnel)+'��������'+FloatToStr(nTunnel.FWeightMax));
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
   bsInit      : WriteNearReaderLog('��ʼ��:' + nTunnel.FID   + '���ݺţ�' + nTunnel.FBill);
   bsNew       : WriteNearReaderLog('�����:' + nTunnel.FID   + '���ݺţ�' + nTunnel.FBill);
   bsStart     : WriteNearReaderLog('��ʼ����:' + nTunnel.FID + '���ݺţ�' + nTunnel.FBill);
   bsClose     : WriteNearReaderLog('���عر�:' + nTunnel.FID + '���ݺţ�' + nTunnel.FBill);
   bsDone      : WriteNearReaderLog('�������:' + nTunnel.FID + '���ݺţ�' + nTunnel.FBill);
   bsStable    : WriteNearReaderLog('����ƽ��:' + nTunnel.FID + '���ݺţ�' + nTunnel.FBill);
   bsError     : WriteNearReaderLog('�ذ����ӹ���:' + nTunnel.FID + '���ݺţ�' + nTunnel.FBill);
  end; //log

  if nTunnel.FStatusNew = bsClose then
  begin
    ShowLEDHint(nTunnel.FID, 'װ��ҵ��ر�', nTunnel.FParams.Values['Truck'],nTunnel.FTunnel.FOptions.Values['TruckProber']);
    WriteNearReaderLog(nTunnel.FID+'װ��ҵ��ر�');

    {$IFDEF UseERelayPLC}
    if nTunnel.FTunnel.FOptions.Values['TruckProber'] <> 'Y' then
    begin
      gERelayManagerPLC.CloseTunnel(nTunnel.FID+'_N');
      WriteNearReaderLog(nTunnel.FID+'װ��ҵ��ر�,�رշŻ�');
    end
    else
    begin
    {$IFDEF BasisWeightTruckProber}
      gProberManager.CloseTunnel(nTunnel.FID+'_O');
      WriteNearReaderLog(nTunnel.FID+'װ��ҵ��ر�,�رշŻ�');
    {$ENDIF}
    end;
    {$ENDIF}
    
    gBasisWeightManager.SetParam(nTunnel.FID, 'CanFH', sFlag_No);
    //֪ͨDCS�ر�װ��
    Exit;
  end;

  if nTunnel.FStatusNew = bsError then
  begin
    ShowLEDHint(nTunnel.FID, '�ذ����ӹ���', nTunnel.FParams.Values['Truck'],nTunnel.FTunnel.FOptions.Values['TruckProber']);
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
    WriteNearReaderLog(nTunnel.FID+'�ذ����ӹ���');

    //������������
    gBasisWeightManager.TunnelManager.ClosePort(nTunnel.FID);
    nTunnel.FEnable := gBasisWeightManager.TunnelManager.ActivePort(nTunnel.FID, nil, True);
    {$IFDEF UseERelayPLC}
    if nTunnel.FTunnel.FOptions.Values['TruckProber'] <> 'Y' then
    begin
      gERelayManagerPLC.CloseTunnel(nTunnel.FID+'_N');
      WriteNearReaderLog(nTunnel.FID+'�رշŻ�');
    end
    else
    begin
    {$IFDEF BasisWeightTruckProber}
      gProberManager.CloseTunnel(nTunnel.FID+'_O');
    {$ENDIF}
    end;
    {$ENDIF}
    
    gBasisWeightManager.SetParam(nTunnel.FID, 'CanFH', sFlag_No);
    //֪ͨDCS�ر�װ��
    Exit;
  end;

  if nTunnel.FStatusNew = bsDone then
  begin
    {$IFDEF BasisWeightWithPM}
      ShowLEDHint(nTunnel.FID, 'װ�������ȴ��������','',nTunnel.FTunnel.FOptions.Values['TruckProber']);
      WriteNearReaderLog(nTunnel.FID+'װ�������ȴ��������');
    {$ELSE}
      ShowLEDHint(nTunnel.FID, 'װ����� ���°�');
      {$IFDEF UseERelayPLC}
      if nTunnel.FTunnel.FOptions.Values['TruckProber'] <> 'Y' then
      begin
        gERelayManagerPLC.OpenTunnel(nTunnel.FID + '_Z');
        WriteNearReaderLog(nTunnel.FID+'װ�����,�򿪳��ڵ�բ,���̵�');
      end
      else
      begin
        gProberManager.OpenTunnel(nTunnel.FID + '_Z');
      end;
      {$ELSE}
        gProberManager.OpenTunnel(nTunnel.FID + '_Z');
      {$ENDIF}
    //�򿪵�բ
    {$ENDIF}

    {$IFDEF UseERelayPLC}
    if nTunnel.FTunnel.FOptions.Values['TruckProber'] = '' then
    begin
      gERelayManagerPLC.CloseTunnel(nTunnel.FID+'_N');
      WriteNearReaderLog(nTunnel.FID+'װ�����,�رշŻ�');
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
    //ץ��
    {$ENDIF}
    
    //ֹͣװ��
    gBasisWeightManager.SetParam(nTunnel.FID, 'CanFH', sFlag_No);
    //֪ͨDCS�ر�װ��
    Exit;
  end;

  if nTunnel.FStatusNew = bsStable then
  begin
    {$IFNDEF BasisWeightWithPM}
    Exit; //�ǿ�׼���,����������
    {$ENDIF}

    {$IFDEF UseERelayPLC}
    if nTunnel.FTunnel.FOptions.Values['TruckProber'] <> 'Y' then
    begin
      if not gERelayManagerPLC.IsTunnelOK(nTunnel.FID) then
      begin
        nTunnel.FStableDone := False;
        //���������¼�
        ShowLEDHint(nTunnel.FID, '����δͣ��λ ���ƶ�����','',nTunnel.FTunnel.FOptions.Values['TruckProber']);
        //��������
        if Assigned(gNetVoiceHelper) then
          gNetVoiceHelper.PlayVoice('����δͣ��λ���ƶ�����',nTunnel.FID);
        Exit;
      end;
    end
    else
    begin
      if not gProberManager.IsTunnelOK(nTunnel.FID) then
      begin
        nTunnel.FStableDone := False;
        //���������¼�
        ShowLEDHint(nTunnel.FID, '����δͣ��λ ���ƶ�����','','Y');
        //��������
        if Assigned(gNetVoiceHelper) then
          gNetVoiceHelper.PlayVoice('����δͣ��λ���ƶ�����',nTunnel.FID);
        Exit;
      end;
    end;
    {$ELSE}
      if not gProberManager.IsTunnelOK(nTunnel.FID) then
      begin
        nTunnel.FStableDone := False;
        //���������¼�
        ShowLEDHint(nTunnel.FID, '����δͣ��λ ���ƶ�����','','Y');
        Exit;
      end;
    {$ENDIF}

    //ShowLEDHint(nTunnel.FID, '����ƽ��׼���������');
    WriteNearReaderLog(nTunnel.FID+'����ƽ��׼���������');
                                   
    if SavePoundData(nTunnel, nTunnel.FValHas,nMsg) then
    begin
      gBasisWeightManager.SetParam(nTunnel.FID, 'CanFH', sFlag_Yes);
      //��ӿɷŻұ��

      if nTunnel.FWeightDone then
      begin
        ShowLEDHint(nTunnel.FID, 'ë��'+ FloatToStr(nTunnel.FValHas) +'����������°�.','',nTunnel.FTunnel.FOptions.Values['TruckProber']);
        WriteNearReaderLog(nTunnel.FID+'ë��'+ FloatToStr(nTunnel.FValHas) +'�������,���°�');
        {$IFDEF UseERelayPLC}
        if nTunnel.FTunnel.FOptions.Values['TruckProber'] = '' then
        begin
          gERelayManagerPLC.OpenTunnel(nTunnel.FID+ '_Z');
          gERelayManagerPLC.CloseTunnel(nTunnel.FID+'_N');
          WriteNearReaderLog(nTunnel.FID+'ë�ر������,�򿪳��ڵ�բ,���̵�,�رշŻ�');
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
          //��������
          if Assigned(gNetVoiceHelper) then
            gNetVoiceHelper.PlayVoice(nTunnel.FParams.Values['Truck']+'װ��������°�',nTunnel.FID);
        {$ELSE}
          gProberManager.OpenTunnel(nTunnel.FID + '_Z');
        {$ENDIF}

        {$IFDEF HKVDVR}
        gCameraManager.CapturePicture(nTunnel.FID, nTunnel.FBill);
        //ץ��
        {$ENDIF}
        
      end else
      begin
        //ShowLEDHint(nTunnel.FID, '���������ȴ�װ��.');
        WriteNearReaderLog(nTunnel.FID+'�������,��ȴ�װ��');
      end;
    end else
    begin
      nTunnel.FStableDone := False;
      //���������¼�
      if nMsg <> '' then
      begin
        ShowLEDHint(nTunnel.FID, nMsg,'',nTunnel.FTunnel.FOptions.Values['TruckProber']);
        WriteNearReaderLog(nTunnel.FID+nMsg);
      end
      else
      begin
        ShowLEDHint(nTunnel.FID, '����ʧ������ϵ����Ա','',nTunnel.FTunnel.FOptions.Values['TruckProber']);
        WriteNearReaderLog(nTunnel.FID+'����ʧ�� ����ϵ����Ա');
      end;
    end;
  end;
end;

//Date: 2019-03-19
//Parm: ͨ���б�
//Desc: װ����״̬�л�
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
    //����ͨ��״̬

//    {$IFDEF ReverseTrafficLight}
//      if nLine.FIsValid then
//           gProberManager.CloseTunnel(nLine.FLineID)
//      else gProberManager.OpenTunnel(nLine.FLineID);
//    {$ELSE}
//      if nLine.FIsValid then
//           gProberManager.OpenTunnel(nLine.FLineID)
//      else gProberManager.CloseTunnel(nLine.FLineID);
//    {$ENDIF} //ͬ����բ
  end;
end;

function VerifySnapTruck(const nTruck,nBill,nPos,nDept: string;var nResult: string): Boolean;
var nList: TStrings;
    nOut: TWorkerBusinessCommand;
    nID,nDefDept: string;
begin
  nDefDept := '�Ÿ�';
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
  WriteHardHelperLog('WhenCaptureFinished����.');
  {$ENDIF}

  nCapture :=  PCameraFrameCapture(nPtr);
  if not FileExists(nCapture.FCaptureName) then Exit;

  with gParamManager.ActiveParam^ do
  try
    nDBConn := gDBConnManager.GetConnection(FDB.FID, nErrNum);
    if not Assigned(nDBConn) then
    begin
      WriteHardHelperLog('����HM���ݿ�ʧ��(DBConn Is Null).');
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

      WriteHardHelperLog('��ʼ����ͼƬ:' + IntToStr(nRID) + ',·��:' + nCapture.FCaptureName);
      nPic := nil;
      try
        nPic := TPicture.Create;
        nPic.LoadFromFile(nCapture.FCaptureName);
        SaveDBImage(nDS, 'P_Picture', nPic.Graphic);
        WriteHardHelperLog('����ͼƬ�ɹ�:' + IntToStr(nRID));
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
