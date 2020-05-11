{*******************************************************************************
  ����: dmzn@163.com 2009-6-25
  ����: ��Ԫģ��

  ��ע: ����ģ������ע������,ֻҪUsesһ�¼���.
*******************************************************************************}
unit USysModule;

{$I Link.Inc}
interface

uses
  UClientWorker;

procedure InitSystemObject;
procedure RunSystemObject;
procedure FreeSystemObject;

implementation

uses
  UMgrChannel, UChannelChooser, UDataModule, USysDB, USysMAC, SysUtils,
  USysLoger, USysConst,UMemDataPool,USysFun,UMgrTTCEDispenser;      //UMgrK720Reader

//Desc: ��ʼ��ϵͳ����
procedure InitSystemObject;
begin
  gPath := ExtractFilePath(ParamStr(0));
  if not Assigned(gSysLoger) then
    gSysLoger := TSysLoger.Create(gPath + sLogDir);
  //system loger

  if not Assigned(gMemDataManager) then
    gMemDataManager := TMemDataManager.Create;
  //Memory Manager

  gChannelManager := TChannelManager.Create;
  gChannelManager.ChannelMax := 20;
  gChannelChoolser := TChannelChoolser.Create(gPath+sConfigFile);
  gChannelChoolser.AutoUpdateLocal := False;
  //channel

//  gMgrK720Reader := TK720ReaderManager.Create;
//  gMgrK720Reader.LoadConfig(gPath + 'K720Reader.XML');

  {$IFDEF HardMon}
  gDispenserManager := TDispenserManager.Create;
  gDispenserManager.LoadConfig(gPath + 'TTCE_K720.xml');
  {$ENDIF}
end;

//Desc: ����ϵͳ����
procedure RunSystemObject;
var nStr: string;
begin
  {$IFDEF HardMon}
  //gMgrK720Reader.StartReader;
  gDispenserManager.StartDispensers;
  //����������
  {$ENDIF}

  with gSysParam do
  begin
    FLocalMAC   := MakeActionID_MAC;
    GetLocalIPConfig(FLocalName, FLocalIP);
  end;

  nStr := 'Select W_Factory,W_Serial From %s ' +
          'Where W_MAC=''%s'' And W_Valid=''%s''';
  nStr := Format(nStr, [sTable_WorkePC, gSysParam.FLocalMAC, sFlag_Yes]);

  with FDM.QueryTemp(nStr) do
  if RecordCount > 0 then
  begin
    gSysParam.FFactNum := Fields[0].AsString;
    gSysParam.FSerialID := Fields[1].AsString;
  end;

  nStr := 'select d_value from %s where d_name=''%s''';
  nStr := Format(nStr, [sTable_SysDict,'FactoryId']);
  with FDM.QueryTemp(nStr) do
  if RecordCount > 0 then
  begin
    gSysParam.FFactory := Fields[0].AsString;
  end;

  nStr := 'select d_value from %s where d_Memo=''%s''';
  nStr := Format(nStr, [sTable_SysDict,sFlag_WXServiceMIT]);
  with FDM.QueryTemp(nStr) do
  if RecordCount > 0 then
  begin
    gSysParam.FWechatURL := Fields[0].AsString;
  end;

  //----------------------------------------------------------------------------
  with gSysParam do
  begin
    FPoundDaiZ := 0;
    FPoundDaiF := 0;
    FPoundSanF := 0;
    FDaiWCStop := False;
    FDaiPercent := False;
  end;

  nStr := 'Select D_Value,D_Memo From %s Where D_Name=''%s''';
  nStr := Format(nStr, [sTable_SysDict, sFlag_PoundWuCha]);

  with FDM.QueryTemp(nStr) do
  if RecordCount > 0 then
  begin
    First;

    while not Eof do
    begin
      nStr := Fields[1].AsString;
      if nStr = sFlag_PDaiWuChaZ then
        gSysParam.FPoundDaiZ := Fields[0].AsFloat;
      //xxxxx

      if nStr = sFlag_PDaiWuChaF then
        gSysParam.FPoundDaiF := Fields[0].AsFloat;
      //xxxxx

      if nStr = sFlag_PDaiPercent then
        gSysParam.FDaiPercent := Fields[0].AsString = sFlag_Yes;
      //xxxxx

      if nStr = sFlag_PDaiWuChaStop then
        gSysParam.FDaiWCStop := Fields[0].AsString = sFlag_Yes;
      //xxxxx

      if nStr = sFlag_PSanWuChaF then
        gSysParam.FPoundSanF := Fields[0].AsFloat;

      Next;
    end;

    with gSysParam do
    begin
      FPoundDaiZ_1 := FPoundDaiZ;
      FPoundDaiF_1 := FPoundDaiF;
      //backup wucha value

      FAutoClose_Mintue:= 30;
    end;
  end;

  //----------------------------------------------------------------------------
  nStr := 'Select D_Value From %s Where D_Name=''%s''';
  nStr := Format(nStr, [sTable_SysDict, sFlag_MITSrvURL]);

  with FDM.QueryTemp(nStr) do
  if RecordCount > 0 then
  begin
    First;

    while not Eof do
    begin
      gChannelChoolser.AddChannelURL(Fields[0].AsString);
      Next;
    end;

    {$IFNDEF DEBUG}
    //gChannelChoolser.StartRefresh;
    {$ENDIF}//update channel
  end;

  nStr := 'Select D_Value From %s Where D_Name=''%s''';
  nStr := Format(nStr, [sTable_SysDict, sFlag_HardSrvURL]);

  with FDM.QueryTemp(nStr) do
  if RecordCount > 0 then
  begin
    gSysParam.FHardMonURL := Fields[0].AsString;
  end;
  LoadSysParameter(nil);
end;

//Desc: �ͷ�ϵͳ����
procedure FreeSystemObject;
begin
  {$IFDEF HardMon}
  gDispenserManager.StopDispensers;
  {$ENDIF}

  FreeAndNil(gSysLoger);
  gSysParam.FQCReportFR3Map.Free;
end;

end.
