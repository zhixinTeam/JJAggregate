{*******************************************************************************
  ����: dmzn@163.com 2013-12-04
  ����: ģ��ҵ�����
*******************************************************************************}
unit UWorkerHardware;

{$I Link.Inc}
interface

uses
  Windows, Classes, Controls, DB, SysUtils, UBusinessWorker, UBusinessPacker,
  UBusinessConst, UMgrDBConn, UMgrParam, ZnMD5, ULibFun, UFormCtrl, USysLoger,
  USysDB, UMITConst, UMgrRFID102, UMgrVoiceNet;

type
  THardwareDBWorker = class(TBusinessWorkerBase)
  protected
    FErrNum: Integer;
    //������
    FDBConn: PDBWorker;
    //����ͨ��
    FDataIn,FDataOut: PBWDataBase;
    //��γ���
    FDataOutNeedUnPack: Boolean;
    //��Ҫ���
    procedure GetInOutData(var nIn,nOut: PBWDataBase); virtual; abstract;
    //�������
    function VerifyParamIn(var nData: string): Boolean; virtual;
    //��֤���
    function DoDBWork(var nData: string): Boolean; virtual; abstract;
    function DoAfterDBWork(var nData: string; nResult: Boolean): Boolean; virtual;
    //����ҵ��
  public
    function DoWork(var nData: string): Boolean; override;
    //ִ��ҵ��
    procedure WriteLog(const nEvent: string);
    //��¼��־
  end;

  THardwareCommander = class(THardwareDBWorker)
  private
    FListA,FListB,FListC: TStrings;
    //list
    FIn: TWorkerBusinessCommand;
    FOut: TWorkerBusinessCommand;
  protected
    procedure GetInOutData(var nIn,nOut: PBWDataBase); override;
    function DoDBWork(var nData: string): Boolean; override;
    //base funciton
    function ChangeDispatchMode(var nData: string): Boolean;
    //�л�����ģʽ
    function PoundCardNo(var nData: string): Boolean;
    //��ȡ��վ����
    function LoadQueue(var nData: string): Boolean;
    //��ȡ��������
    function ExecuteSQL(var nData: string): Boolean;
    //ִ��SQL���
    function SaveDaiNum(var nData: string): Boolean;
    //�����������
    function PrintCode(var nData: string): Boolean;
    function PrintFixCode(var nData: string): Boolean;
    //�������ӡ����
    function PrinterEnable(var nData: string): Boolean;
    //��ͣ�����
    function StartJS(var nData: string): Boolean;
    function PauseJS(var nData: string): Boolean;
    function StopJS(var nData: string): Boolean;
    function JSStatus(var nData: string): Boolean;
    //������ҵ��
    function TruckProbe_IsTunnelOK(var nData: string): Boolean;
    function TruckProbe_TunnelOC(var nData: string): Boolean;
    function TruckProbe_ShowTxt(var nData: string): Boolean;
    //������������ҵ��
    function OpenDoorByReader(var nData: string): Boolean;
    //ͨ���������򿪵�բ
    function ShowLedText(var nData: string): Boolean;
    //���ƷŻҵ���С����ʾ
    function LineClose(var nData: string): Boolean;
    //���ƷŻ�
    function CallLineNextPTruck(var nData: string): Boolean;
  public
    constructor Create; override;
    destructor destroy; override;
    //new free
    function GetFlagStr(const nFlag: Integer): string; override;
    class function FunctionName: string; override;
    //base function
  end;

implementation

uses
	{$IFDEF MultiReplay}UMultiJS_Reply, {$ELSE}UMultiJS, {$ENDIF}
  UMgrHardHelper, UMgrCodePrinter, UMgrQueue, UTaskMonitor,
  UMgrTruckProbe, UMgrERelay;

//Date: 2012-3-13
//Parm: ���������
//Desc: ��ȡ�������ݿ��������Դ
function THardwareDBWorker.DoWork(var nData: string): Boolean;
begin
  Result := False;
  FDBConn := nil;

  with gParamManager.ActiveParam^ do
  try
    FDBConn := gDBConnManager.GetConnection(FDB.FID, FErrNum);
    if not Assigned(FDBConn) then
    begin
      nData := '�������ݿ�ʧ��(DBConn Is Null).';
      Exit;
    end;

    if not FDBConn.FConn.Connected then
      FDBConn.FConn.Connected := True;
    //conn db

    FDataOutNeedUnPack := True;
    GetInOutData(FDataIn, FDataOut);
    FPacker.UnPackIn(nData, FDataIn);

    with FDataIn.FVia do
    begin
      FUser   := gSysParam.FAppFlag;
      FIP     := gSysParam.FLocalIP;
      FMAC    := gSysParam.FLocalMAC;
      FTime   := FWorkTime;
      FKpLong := FWorkTimeInit;
    end;

    {$IFDEF DEBUG}
    WriteLog('Fun: '+FunctionName+' InData:'+ FPacker.PackIn(FDataIn, False));
    {$ENDIF}
    if not VerifyParamIn(nData) then Exit;
    //invalid input parameter

    FPacker.InitData(FDataOut, False, True, False);
    //init exclude base
    FDataOut^ := FDataIn^;

    Result := DoDBWork(nData);
    //execute worker

    if Result then
    begin
      if FDataOutNeedUnPack then
        FPacker.UnPackOut(nData, FDataOut);
      //xxxxx

      Result := DoAfterDBWork(nData, True);
      if not Result then Exit;

      with FDataOut.FVia do
        FKpLong := GetTickCount - FWorkTimeInit;
      nData := FPacker.PackOut(FDataOut);

      {$IFDEF DEBUG}
      WriteLog('Fun: '+FunctionName+' OutData:'+ FPacker.PackOut(FDataOut, False));
      {$ENDIF}
    end else DoAfterDBWork(nData, False);
  finally
    gDBConnManager.ReleaseConnection(FDBConn);
  end;
end;

//Date: 2012-3-22
//Parm: �������;���
//Desc: ����ҵ��ִ����Ϻ����β����
function THardwareDBWorker.DoAfterDBWork(var nData: string; nResult: Boolean): Boolean;
begin
  Result := True;
end;

//Date: 2012-3-18
//Parm: �������
//Desc: ��֤��������Ƿ���Ч
function THardwareDBWorker.VerifyParamIn(var nData: string): Boolean;
begin
  Result := True;
end;

//Desc: ��¼nEvent��־
procedure THardwareDBWorker.WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(THardwareDBWorker, FunctionName, nEvent);
end;

//------------------------------------------------------------------------------
class function THardwareCommander.FunctionName: string;
begin
  Result := sBus_HardwareCommand;
end;

constructor THardwareCommander.Create;
begin
  FListA := TStringList.Create;
  FListB := TStringList.Create;
  FListC := TStringList.Create;
  inherited;
end;

destructor THardwareCommander.destroy;
begin
  FreeAndNil(FListA);
  FreeAndNil(FListB);
  FreeAndNil(FListC);
  inherited;
end;

function THardwareCommander.GetFlagStr(const nFlag: Integer): string;
begin
  Result := inherited GetFlagStr(nFlag);

  case nFlag of
   cWorker_GetPackerName : Result := sBus_BusinessCommand;
  end;
end;

procedure THardwareCommander.GetInOutData(var nIn,nOut: PBWDataBase);
begin
  nIn := @FIn;
  nOut := @FOut;
  FDataOutNeedUnPack := False;
end;

//Date: 2012-3-22
//Parm: ��������
//Desc: ִ��nDataҵ��ָ��
function THardwareCommander.DoDBWork(var nData: string): Boolean;
begin
  with FOut.FBase do
  begin
    FResult := True;
    FErrCode := 'S.00';
    FErrDesc := 'ҵ��ִ�гɹ�.';
  end;

  case FIn.FCommand of
   cBC_ChangeDispatchMode   : Result := ChangeDispatchMode(nData);
   cBC_GetPoundCard         : Result := PoundCardNo(nData);
   cBC_GetQueueData         : Result := LoadQueue(nData);
   cBC_SaveCountData        : Result := SaveDaiNum(nData);
   cBC_RemoteExecSQL        : Result := ExecuteSQL(nData);
   cBC_PrintCode            : Result := PrintCode(nData);
   cBC_PrintFixCode         : Result := PrintFixCode(nData);
   cBC_PrinterEnable        : Result := PrinterEnable(nData);

   cBC_JSStart              : Result := StartJS(nData);
   cBC_JSStop               : Result := StopJS(nData);
   cBC_JSPause              : Result := PauseJS(nData);
   cBC_JSGetStatus          : Result := JSStatus(nData);

   cBC_IsTunnelOK           : Result := TruckProbe_IsTunnelOK(nData);
   cBC_TunnelOC             : Result := TruckProbe_TunnelOC(nData);
   cBC_ShowTxt              : Result := TruckProbe_ShowTxt(nData);
   
   cBC_OpenDoorByReader     : Result := OpenDoorByReader(nData);

   cBC_ShowLedTxt           : Result := ShowLedText(nData);
   cBC_LineClose            : Result := LineClose(nData);
   cBC_CallLineNextPTruck   : Result := CallLineNextPTruck(nData);
   //xxxxxx
   else
    begin
      Result := False;
      nData := '��Ч��ҵ�����(Invalid Command).';
    end;
  end;
end;

//Date: 2014-10-07
//Parm: ����ģʽ[FIn.FData]
//Desc: �л�ϵͳ����ģʽ
function THardwareCommander.ChangeDispatchMode(var nData: string): Boolean;
var nStr,nSQL: string;
begin
  Result := True;
  nSQL := 'Update %s Set D_Value=''%s'' Where D_Name=''%s'' And D_Memo=''%s''';
  {
  if FIn.FData = '1' then
  begin
    nStr := Format(nSQL, [sTable_SysDict, sFlag_No, sFlag_SysParam,
            sFlag_SanMultiBill]);
    gDBConnManager.WorkerExec(FDBConn, nStr); //�ر�ɢװԤ��

    nStr := Format(nSQL, [sTable_SysDict, '20', sFlag_SysParam,
            sFlag_InTimeout]);
    gDBConnManager.WorkerExec(FDBConn, nStr); //���̽�����ʱ

    gTruckQueueManager.RefreshParam;
    //ʹ���µ��Ȳ���
  end else

  if FIn.FData = '2' then
  begin
    nStr := Format(nSQL, [sTable_SysDict, sFlag_Yes, sFlag_SysParam,
            sFlag_SanMultiBill]);
    gDBConnManager.WorkerExec(FDBConn, nStr); //����ɢװԤ��

    nStr := Format(nSQL, [sTable_SysDict, '1440', sFlag_SysParam,
            sFlag_InTimeout]);
    gDBConnManager.WorkerExec(FDBConn, nStr); //�ӳ�������ʱ

    gTruckQueueManager.RefreshParam;
    //ʹ���µ��Ȳ���
  end; }
end;

//Date: 2014-10-01
//Parm: ��վ��[FIn.FData]
//Desc: ��ȡָ����վ�������ϵĴſ���
function THardwareCommander.PoundCardNo(var nData: string): Boolean;
var nStr, nReader, nPoundID: string;
    nIdx: Integer;
begin
  Result := True;
  if FIn.FExtParam = sFlag_Yes then
  begin
    FListA.Clear;
    FListB.Clear;
    if not SplitStr(FIn.FData, FListA, 0, ',') then Exit;

    for nIdx:=0 to FListA.Count - 1 do
    begin
      nPoundID := FListA[nIdx];
      FListB.Values[nPoundID] := gHardwareHelper.GetPoundCard(nPoundID, FOut.FExtParam);
    end;

    FOut.FData := FListB.Text;
    Exit;
  end;

  FOut.FData := gHardwareHelper.GetPoundCard(FIn.FData, nReader);
  if FOut.FData = '' then Exit;

  nStr := 'Select C_Card From $TB Where C_Card=''$CD'' or ' +
          'C_Card2=''$CD'' or C_Card3=''$CD''';
  nStr := MacroValue(nStr, [MI('$TB', sTable_Card), MI('$CD', FOut.FData)]);

  with gDBConnManager.WorkerQuery(FDBConn, nStr) do
  if RecordCount > 0 then
  begin
    FOut.FExtParam := nReader;
    FOut.FData := Fields[0].AsString;
    gHardwareHelper.SetPoundCardExt(FIn.FData, FOut.FData);
    //��Զ���뿨�Ŷ�Ӧ�Ľ����뿨�Ű�
  end;
end;

//Date: 2014-10-01
//Parm: �Ƿ�ˢ��[FIn.FData]
//Desc: ��ȡ��������
function THardwareCommander.LoadQueue(var nData: string): Boolean;
var nVal: Double;
    i,nIdx: Integer;
    nLine: PLineItem;
    nTruck: PTruckItem;
begin
  gTruckQueueManager.RefreshTrucks(FIn.FData = sFlag_Yes);
  Sleep(320);
  //ˢ������

  with gTruckQueueManager do
  try
    SyncLock.Enter;
    Result := True;

    FListB.Clear;
    FListC.Clear;

    for nIdx:=0 to Lines.Count - 1 do
    begin
      nLine := Lines[nIdx];
      FListB.Values['ID'] := nLine.FLineID;
      FListB.Values['Name'] := nLine.FName;
      FListB.Values['Stock'] := nLine.FStockNo;
      FListB.Values['Weight'] := IntToStr(nline.FPeerWeight);

      if nLine.FIsValid then
           FListB.Values['Valid'] := sFlag_Yes
      else FListB.Values['Valid'] := sFlag_No;

      if gCodePrinterManager.IsPrinterEnable(nLine.FLineID) then
           FListB.Values['Printer'] := sFlag_Yes
      else FListB.Values['Printer'] := sFlag_No;

      FListC.Add(PackerEncodeStr(FListB.Text));
      //��������
    end;

    FListA.Values['Lines'] := PackerEncodeStr(FListC.Text);
    //ͨ���б�
    FListC.Clear;

    for nIdx:=0 to Lines.Count - 1 do
    begin
      nLine := Lines[nIdx];
      FListB.Clear;

      for i:=0 to nLine.FTrucks.Count - 1 do
      begin
        nTruck := nLine.FTrucks[i];
        FListB.Values['Truck'] := nTruck.FTruck;
        FListB.Values['Line'] := nLine.FLineID;
        FListB.Values['Bill'] := nTruck.FBill;
        FListB.Values['Value'] := FloatToStr(nTruck.FValue);

        if nLine.FPeerWeight > 0 then
        begin
          nVal := nTruck.FValue * 1000;
          nTruck.FDai := Trunc(nVal / nLine.FPeerWeight);
        end else nTruck.FDai := 0;
        
        FListB.Values['Dai'] := IntToStr(nTruck.FDai);
        FListB.Values['Total'] := IntToStr(nTruck.FNormal + nTruck.FBuCha);

        if nTruck.FStarted then
             FListB.Values['IsRun'] := sFlag_Yes
        else FListB.Values['IsRun'] := sFlag_No;

        if nTruck.FInFact then
             FListB.Values['InFact'] := sFlag_Yes
        else FListB.Values['InFact'] := sFlag_No;

        FListC.Add(PackerEncodeStr(FListB.Text));
        //��������
      end;
    end;

    FListA.Values['Trucks'] := PackerEncodeStr(FListC.Text);
    //�����б�
    FOut.FData := PackerEncodeStr(FListA.Text);
  finally
    SyncLock.Leave;
  end;
end;

//Date: 2014-10-01
//Parm: ������[FIn.FData];ͨ����[FIn.FExtParam]
//Desc: ��ָ��ͨ��������
function THardwareCommander.PrintCode(var nData: string): Boolean;
var nStr,nCode,nPrint: string;
begin
  Result := True;
  if not gCodePrinterManager.EnablePrinter then Exit;

  nStr := '��ͨ��[ %s ]���ͽ�����[ %s ]��Υ����.';
  nStr := Format(nStr, [FIn.FExtParam, FIn.FData]);
  WriteLog(nStr);

  if Pos('@', FIn.FData) = 1 then
  begin
    nCode := Copy(FIn.FData, 2, Length(FIn.FData) - 1);
    //�̶�����
  end else
  begin
    {$IFDEF BatchInHYOfBill}
    nPrint := 'L_HYDan';
    {$ELSE}
    nPrint := 'L_Seal';
    {$ENDIF}
    
    nStr := 'Select L_ID,%s From %s Where L_ID=''%s''';
    nStr := Format(nStr, [nPrint, sTable_Bill, FIn.FData]);

    with gDBConnManager.WorkerQuery(FDBConn, nStr) do
    begin
      if RecordCount < 1 then
      begin
        Result := False;
        nData := Format('������[ %s ]����Ч.', [FIn.FData]); Exit;
      end;

      {$IFDEF UseERP_K3}
      nCode := StringReplace(Fields[0].AsString, 'TH', '', [rfIgnoreCase]);
      nCode := Fields[1].AsString + '-' +
               Copy(FIn.FExtParam, Length(FIn.FExtParam) - 1, 2) + '-' + nCode;
      {$ENDIF}

      {$IFDEF RDHX}
      nCode := Trim(Fields[1].AsString);
      nCode := nCode + Date2Str(Now, False);;
      {$ENDIF}

      {$IFDEF ZZSJ}
      nCode := Fields[0].AsString;
      System.Delete(nCode, 1, Length('TH170707'));
      nCode := Date2Str(Now) + Fields[1].AsString + nCode;
      //�Ͻ�: ������ + ˮ�����κ� + ��ˮ��
      {$ENDIF}
    end;
  end;

  if not gCodePrinterManager.PrintCode(FIn.FExtParam, nCode, nStr) then
  begin
    Result := False;
    nData := nStr;
    Exit;
  end;

  nStr := '��ͨ��[ %s ]���ͷ�Υ����[ %s ]�ɹ�.';
  nStr := Format(nStr, [FIn.FExtParam, nCode]);
  WriteLog(nStr);
end;

//Date: 2014-10-01
//Parm: ͨ����[FIn.FData];�Ƿ�����[FIn.FExtParam]
//Desc: ��ָͣ��ͨ���������
function THardwareCommander.PrinterEnable(var nData: string): Boolean;
begin
  Result := True;
  gCodePrinterManager.PrinterEnable(FIn.FData, FIn.FExtParam = sFlag_Yes);
end;

function THardwareCommander.PrintFixCode(var nData: string): Boolean;
begin
  Result := True;
end;

//Date: 2014-10-01
//Parm: װ������[FIn.FData]
//Desc: ����װ������
function THardwareCommander.SaveDaiNum(var nData: string): Boolean;
var nStr,nLine,nTruck: string;
    nTask: Int64;
    nVal: Double;
    nPLine: PLineItem;
    nPTruck: PTruckItem;
    nInt,nPeer,nDai,nTotal: Integer;
begin
  nTask := gTaskMonitor.AddTask('BusinessCommander.SaveDaiNum', cTaskTimeoutLong);
  //to mon

  Result := True;
  FListA.Text := PackerDecodeStr(FIn.FData);

  with FListA do
  begin
    nStr := 'Select * From %s Where T_Bill=''%s''';
    nStr := Format(nStr, [sTable_ZTTrucks, Values['Bill']]);

    with gDBConnManager.WorkerQuery(FDBConn, nStr) do
    begin
      if RecordCount < 1 then Exit;
      //not valid

      nLine := FieldByName('T_Line').AsString;
      nTruck := FieldByName('T_Truck').AsString;
      //������Ϣ

      nVal := FieldByName('T_Value').AsFloat;
      nPeer := FieldByName('T_PeerWeight').AsInteger;

      nDai := StrToInt(Values['Dai']);
      nTotal := FieldByName('T_Total').AsInteger + nDai;

      if nPeer < 1 then nPeer := 1;
      nDai := Trunc(nVal / nPeer * 1000);
      //Ӧװ����

      if nDai >= nTotal then
      begin
        nInt := 0;
        nDai := nTotal;
      end else //δװ��
      begin
        nInt := nTotal - nDai;
      end; //��װ��
    end;

    nStr := 'Update %s Set T_Normal=%d,T_BuCha=%d,T_Total=%d Where T_Bill=''%s''';
    nStr := Format(nStr, [sTable_ZTTrucks, nDai, nInt, nTotal, Values['Bill']]);
    gDBConnManager.WorkerExec(FDBConn, nStr);
  end;

  gTaskMonitor.DelTask(nTask);
  nTask := gTaskMonitor.AddTask('BusinessCommander.SaveDaiNum2', cTaskTimeoutLong);

  with gTruckQueueManager do
  try
    SyncLock.Enter;
    nInt := GetLine(nLine);

    if nInt < 0 then Exit;
    nPLine := Lines[nInt];
    nInt := TruckInLine(nTruck, nPLine.FTrucks);

    if nInt < 0 then Exit;
    nPTruck := nPLine.FTrucks[nInt];

    nPTruck.FNormal := nDai;
    nPTruck.FBuCha  := nInt;
    nPTruck.FIsBuCha := nDai > 0;
  finally
    SyncLock.Leave;
    gTaskMonitor.DelTask(nTask);
  end;
end;

//Desc: ִ��SQL���
function THardwareCommander.ExecuteSQL(var nData: string): Boolean;
var nInt: Integer;
begin
  Result := True;
  nInt := gDBConnManager.WorkerExec(FDBConn, PackerDecodeStr(FIn.FData));
  FOut.FData := IntToStr(nInt);
end;

//Desc: ����������
function THardwareCommander.StartJS(var nData: string): Boolean;
begin
  FListA.Text := FIn.FData;
  Result := gMultiJSManager.AddJS(FListA.Values['Tunnel'],
            FListA.Values['Truck'], FListA.Values['Bill'],
            StrToInt(FListA.Values['DaiNum']), True);
  //xxxxx

  if not Result then
    nData := '����������ʧ��';
  //xxxxx
end;

//Desc: ��ͣ������
function THardwareCommander.PauseJS(var nData: string): Boolean;
begin
  Result := gMultiJSManager.PauseJS(FIn.FData);
  if not Result then
    nData := '��ͣ������ʧ��';
  //xxxxx
end;

//Desc: ֹͣ������
function THardwareCommander.StopJS(var nData: string): Boolean;
begin
  Result := gMultiJSManager.DelJS(FIn.FData);
  if not Result then
    nData := 'ֹͣ������ʧ��';
  //xxxxx
end;

//Desc: ������״̬
function THardwareCommander.JSStatus(var nData: string): Boolean;
begin
  gMultiJSManager.GetJSStatus(FListA);
  FOut.FData := FListA.Text;
  Result := True;
end;

//Date: 2014-10-01
//Parm: ͨ����[FIn.FData]
//Desc: ��ȡָ��ͨ���Ĺ�դ״̬
function THardwareCommander.TruckProbe_IsTunnelOK(var nData: string): Boolean;
begin
  Result := True;
  if not Assigned(gProberManager) then
  begin
    FOut.FData := sFlag_Yes;
    Exit;
  end;

  if gProberManager.IsTunnelOK(FIn.FData) then
       FOut.FData := sFlag_Yes
  else FOut.FData := sFlag_No;

  nData := Format('IsTunnelOK -> %s:%s', [FIn.FData, FOut.FData]);
  WriteLog(nData);
end;

//Date: 2014-10-01
//Parm: ͨ����[FIn.FData];����[FIn.FExtParam]
//Desc: ����ָ��ͨ��
function THardwareCommander.TruckProbe_TunnelOC(var nData: string): Boolean;
begin
  Result := True;
  if not Assigned(gProberManager) then Exit;

  if FIn.FExtParam = sFlag_Yes then
       gProberManager.OpenTunnel(FIn.FData)
  else gProberManager.CloseTunnel(FIn.FData);

  nData := Format('TunnelOC -> %s:%s', [FIn.FData, FIn.FExtParam]);
  WriteLog(nData);
end;

//Date: 2017/2/8
//Parm: ���������[FIn.FData];����������[FIn.FExtParam]
//Desc: �������򿪵�բ
function THardwareCommander.OpenDoorByReader(var nData: string): Boolean;
var nReader,nIn: string;
    nIdx, nInt: Integer;
    nRItem: PHYReaderItem;
begin
  Result := True;
  {$IFNDEF HYRFID201}
  Exit;
  //δ���õ��ӱ�ǩ������
  {$ENDIF}

  nIn := StringReplace(FIn.FData, 'V', 'H', [rfReplaceAll]);
  //�������������������滻�ɶ�Ӧ����ʵ������

  nInt := -1;
  for nIdx:=gHYReaderManager.Readers.Count-1 downto 0 do
  begin
    nRItem :=  gHYReaderManager.Readers[nIdx];

    if CompareText(nRItem.FID, nIn) = 0 then
    begin
      nInt := nIdx;
      Break;
    end;
  end;

  if nInt < 0 then Exit;
  //reader not exits

  nReader:= '';
  nRItem := gHYReaderManager.Readers[nInt];
  if FIn.FExtParam = sFlag_No then
  begin
    if Assigned(nRItem.FOptions) then
       nReader := nRItem.FOptions.Values['ExtReader'];
  end
  else nReader := nIn;

  if Trim(nReader) <> '' then
    gHYReaderManager.OpenDoor(Trim(nReader));
end;

//Date: 2018-02-27
//Parm: ͨ����[FIn.FData] ��������[FIn.FExt]
//Desc: ��ָ��ͨ������ʾ����������
function THardwareCommander.TruckProbe_ShowTxt(var nData: string): Boolean;
begin
  Result := True;
  if not Assigned(gProberManager) then Exit;

  gProberManager.ShowTxt(FIn.FData,FIn.FExtParam);

  nData := Format('ShowTxt -> %s:%s', [FIn.FData, FIn.FExtParam]);
  WriteLog(nData);
end;

function THardwareCommander.ShowLedText(var nData: string): Boolean;
var
  nTunnel, nStr:string;
begin
  nTunnel := FIn.FData;
  nStr := fin.FExtParam;
  gERelayManager.ShowTxt(nTunnel, nStr);
  Result := True;
end;

function THardwareCommander.LineClose(var nData: string): Boolean;
var
  nTunnel:string;
begin
  nTunnel := FIn.FData;
  if FIn.FExtParam = sFlag_No then
    gERelayManager.LineOpen(nTunnel)
  else
    gERelayManager.LineClose(nTunnel);
  Result := True;
end;

//Date: 2020-04-26
//Parm: ��λ[FIn.FData] ��������[FIn.FExt]
//Desc: �к� nTruck����ͨ������������Ƥ
function THardwareCommander.CallLineNextPTruck(var nData: string): Boolean;
var nIdx, nInt : Integer;
    nTunnel, nTruck, nZName, nStr, nVoiceCard : string;
    nPTruck, nNextPTruck: PTruckItem;
    nPLine : PLineItem;
    nlast  : Boolean;
    nOut: TWorkerBusinessCommand;
begin
  Result := True;             nVoiceCard:= 'TCC';

  FListA.Text := PackerDecodeStr(FIn.FData);

  nTunnel:= FListA.Values['Tunnel'];
  nZName := FListA.Values['TName'];
  nTruck := FListA.Values['Truck'];

  with gTruckQueueManager do
  try
    SyncLock.Enter;
    nIdx := GetLine(nTunnel);

    if nIdx < 0 then
    begin
      nData:= Format('CallLineNextPTruck��ͨ�� %s ��Ч.', [nTunnel]);
      WriteLog(nData);
      Exit;
    end;

    nPLine := Lines[nIdx];
    nInt := TruckInLine(nTruck, nPLine.FTrucks);
    if nInt < 0 then
    begin
      nData:= Format('CallLineNextPTruck������ %s ���� %s ������.', [nTruck, nPLine.FName]);
      WriteLog(nData);
      Exit;
    end;

    nIdx := nInt;
    if (nIdx < 0) or (nIdx = nPLine.FTrucks.Count - 1) then
    begin
      nlast:= True;
    end;

    IF not nlast then
    begin
      nNextPTruck := nPLine.FTrucks[nIdx+2];
      //next truck

      nZName:= StringReplace(nZName, '#', '��', [rfReplaceAll]);
      nZName:= StringReplace(nZName, '��', '', [rfReplaceAll]);
      nStr := '%s ���Ƥ�ء����� ' + nZName + '�� �ȴ�װ��';
      nStr := Format(nStr, [nNextPTruck.FTruck]);
    end
    else
    begin
      nStr := '���� %s ���޺�������';
      nStr := Format(nStr, [nTruck]);
      WriteLog(nStr);
      nStr:= '';
    end;

    try
      if not(gNetVoiceHelper=nil)And(nStr<>'') then
      begin
        gNetVoiceHelper.PlayVoice(nStr, nVoiceCard);
        //��������

        WriteLog(Format('CallLineNextPTruck ��������[%s %s]', [nVoiceCard ,nStr]));
      end;
    except
      on nErr: Exception do
      begin
        nStr := 'CallLineNextPTruck ����[ %s ]����ʧ��,����: %s';
        nStr := Format(nStr, [nVoiceCard, nErr.Message]);
        WriteLog(nStr);
      end;
    end;
  finally
    SyncLock.Leave;
  end;
end;


initialization
  gBusinessWorkerManager.RegisteWorker(THardwareCommander, sPlug_ModuleHD);
end.
