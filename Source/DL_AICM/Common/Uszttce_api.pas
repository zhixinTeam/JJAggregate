{*******************************************************************************
  ����: 289525016@163.com 2016-10-24
  ����: ����������ʵҵ���޹�˾����һ��������TTCE�������� �ͺ�KCDF-360
*******************************************************************************}
unit Uszttce_api;

interface
uses
  Classes,ExtCtrls;
const
  C_MacAddr:char=chr($0F);//������Ĭ�ϵ�ַ

  C_CMD_Position_CardPort:string='FC0';//����������
  C_CMD_Position_ReadCard:string='FC7';//����������λ��
  C_CMD_RecycleCard:string='CP'; //���տ�Ƭ

  C_MachineStatus_CardBoxEmpty:string='0018'; //�޿����������
  C_MachineStatus_Ready1:string='0004'; //���������ڴ�����3λ��
  C_MachineStatus_Ready2:string='0014'; //���������ڴ�����3λ��
  C_MachineStatus_OverlapedCard:string='0040'; //�ص���
  C_MaahineStatus_CloggedCard:string='0020'; //������
  C_MaahineStatus_RecycleBoxFull1:string='0133'; //��������
  C_MaahineStatus_RecycleBoxFull2:string='0132'; //��������
  C_MaahineStatus_ReadyForRead1:string='0003'; //�������������ڴ�����1-2λ��
  C_MaahineStatus_ReadyForRead2:string='0013'; //�������������ڴ�����1-2λ��
  C_MaahineStatus_Status_Error1:string='0016'; //�������������ڴ�����1-2λ��

  C_EMPTY_CARD_NO:string='000000000000';
type
  //�豸״̬
  TMachineStatus = record
    msCode:string;
    msDesc:string;
  end;

  TSzttceApi = class(TObject)
  private
    FFileName_K720:string;
    FFileName_Config:string;
    FLibModule:Integer;
    FComHandle:THandle;
    FPort:string;
    FRecordInfo:array[0..255] of Char;
    FStateInfo:array[0..3] of Char;
    FMachineStatus:TMachineStatus;
    FParentWnd:THandle;
    //��̬��汾��Ϣ
    //K720_GetSysVersion:function (ComHandle:THandle; strVersion:PChar):Integer;stdcall;
    //Ѱ��
    //K720_S50DetectCard:function(ComHandle:THandle;MacAddr:Char;RecordInfo:PChar):Integer;stdcall;
    //һ���ѯ��D1801״̬��Ϣ������3�ֽڵ�״̬��Ϣ
    //K720_Query:function(ComHandle:THandle;MacAddr:Char;StateInfo:PByte;RecordInfo:PChar):Integer;stdcall;
    //�򿪴��ڣ�Ĭ�ϵĲ�����"9600, n, 8, 1"
    K720_CommOpen:function (Port:PChar):THandle;stdcall;
    //�رյ�ǰ�򿪵Ĵ���
    K720_CommClose:function (ComHandle:THandle):Integer;stdcall;
    //����D1801�Ĳ�������
    K720_SendCmd:function (ComHandle:THandle; MacAddr:Char; p_Cmd:PChar; CmdLen:Integer; RecordInfo:PChar):Integer;stdcall;

    //��ȡ���к�
    K720_S50GetCardID:function(ComHandle:THandle;MacAddr:Char;CardID:PByte;RecordInfo:PChar):Integer;stdcall;

    //�߼���ѯ��D1801״̬��Ϣ������4�ֽڵ�״̬��Ϣ
    K720_SensorQuery :function(ComHandle:THandle;MacAddr:Char;StateInfo:PByte;RecordInfo:PChar):Integer;stdcall;

    //������Ƭ���к�
    function ParseCardNO(var nCardid: array of Byte):string;
    //�򿪴���
    function OpenComPort:Boolean;

    function ParseStateInfo:Boolean;
//    procedure WriteLog(const nMsg:string);

    function InitApiInterface:Boolean;
    //���տ�Ƭ
    function RecycleCard:Boolean;
    //�ȴ��豸����
    procedure WaitforIdle;
    function GetComPort:string;
  public
    ErrorCode:Integer;
    ErrorMsg:string;
    constructor Create;
    destructor Destroy; override;
    //���������ؿ���
    function IssueOneCard(var nCardno:string):Boolean;
    //�忨��������������˿�
    function ReadCardSerialNo(var nCardSerialNo:string):Boolean;
    
    //��ȡ������ǰ״̬
    function GetCurrentStatus(var nMachineStatus:TMachineStatus):Boolean;
    //�Ƿ�忨
    function IsInsertedCard:Boolean;

    function ResetMachine:Boolean;

    property ParentWnd:THandle read FParentWnd write FParentWnd;
  end;

implementation
uses
  SysUtils,Windows,IniFiles;
{ TSzttceApi }

constructor TSzttceApi.Create;
var
  nPath,nPort:string;
begin
  nPath := ExtractFilePath(ParamStr(0));
  FFileName_K720 := nPath+'K720_Dll.dll';
  FFileName_Config := nPath+'com.ini';
  FComHandle := 0;
  nPort := GetComPort;
  if nPort='' then Exit;
  FPort := nPort;
  InitApiInterface;
  FParentWnd := 0;
  ErrorCode := 0;
  ErrorMsg := '';
end;

destructor TSzttceApi.Destroy;
begin
  if FComHandle<>0 then
  begin
    K720_CommClose(FComHandle);
  end;
  if FLibModule>32 then
  begin
    FreeLibrary(FLibModule);
  end;
  inherited;
end;

function TSzttceApi.GetComPort: string;
var
  nini:TIniFile;
begin
  Result := '';
  if not FileExists(FFileName_Config) then
  begin
    ErrorCode := 990;
    ErrorMsg := 'com�������ļ�['+FFileName_Config+']������';
    Exit;
  end;
  nini := TIniFile.Create(FFileName_Config);
  try
    Result := nini.ReadString('com','port','');
  finally
    nini.Free;
  end;
end;

function TSzttceApi.GetCurrentStatus(var nMachineStatus:TMachineStatus):Boolean ;
var
  nRet:Integer;
begin
  ZeroMemory(@FRecordInfo,SizeOf(FRecordInfo));
  ZeroMemory(@FStateInfo,SizeOf(FStateInfo));
  if not OpenComPort then Exit;
  nRet := K720_SensorQuery(FComHandle,C_MacAddr,@FStateInfo,@FRecordInfo);
  if nRet<>0 then
  begin
    ErrorCode := 1000;
    ErrorMsg := '��ѯ״̬ʧ��';
    Exit;
  end;
  Result := ParseStateInfo;
  nMachineStatus := FMachineStatus;
end;

function TSzttceApi.InitApiInterface: Boolean;
begin
  Result := False;
  if not FileExists(FFileName_K720) then
  begin
    ErrorCode := 1010;
    ErrorMsg := '��̬���ļ�[ '+FFileName_K720+' ]�����ڣ�';
    Exit;
  end;

  FLibModule := Loadlibrary(PChar(FFileName_K720));
  if (FLibModule<=32) then
  begin
    ErrorCode := 1020;
    ErrorMsg := '�������������ļ�[ '+FFileName_K720+' ]ʧ�ܣ�';
    Exit;
  end;

  //K720_GetSysVersion := GetProcAddress(FLibModule,'K720_GetSysVersion');
  K720_CommOpen := GetProcAddress(FLibModule,'K720_CommOpen');
  K720_CommClose := GetProcAddress(FLibModule,'K720_CommClose');
  K720_SendCmd := GetProcAddress(FLibModule,'K720_SendCmd');
  //K720_S50DetectCard := GetProcAddress(FLibModule,'K720_S50DetectCard');
  K720_S50GetCardID := GetProcAddress(FLibModule,'K720_S50GetCardID');
  //K720_Query := GetProcAddress(FLibModule,'K720_Query');
  K720_SensorQuery := GetProcAddress(FLibModule,'K720_SensorQuery');
  Result := True;
end;

function TSzttceApi.IsInsertedCard: Boolean;
begin
  Result := False;
  if not OpenComPort then Exit;
  GetCurrentStatus(FMachineStatus);
  Result := (FMachineStatus.msCode=C_MaahineStatus_ReadyForRead1) or (FMachineStatus.msCode=C_MaahineStatus_ReadyForRead2);
end;

function TSzttceApi.IssueOneCard(var nCardno: string): Boolean;
var
  nRet:Integer;
  nCardID:array[0..3] of Byte;
begin
  nCardno := '';
  Result := False;
  if not OpenComPort then Exit;
  GetCurrentStatus(FMachineStatus);
  if (FMachineStatus.msCode=c_MachineStatus_CardBoxEmpty)
    or (FMachineStatus.msCode=C_MachineStatus_OverlapedCard)
    or (FMachineStatus.msCode=C_MaahineStatus_RecycleBoxFull1)
    or (FMachineStatus.msCode=C_MaahineStatus_RecycleBoxFull2) then
  begin
    ErrorCode := StrToInt(FMachineStatus.msCode);
    ErrorMsg := FMachineStatus.msDesc;
    if FParentWnd<>0 then
    begin
      MessageBeep($FFFFFFFF);
      MessageBox(FParentWnd,PChar(ErrorMsg),'Error',0);
    end;
    Exit;
  end;

  //��λ
  if not ResetMachine then Exit;
//����������λ��
  ZeroMemory(@FRecordInfo,SizeOf(FRecordInfo));
  nRet := K720_SendCmd(FComHandle, C_MacAddr, PChar(C_CMD_Position_ReadCard), Length(C_CMD_Position_ReadCard),@FRecordInfo);
  if 0<>nRet then
  begin
    ErrorCode := 1040;
    ErrorMsg := '�������λ��ʧ��';
    Exit;
  end;
  Sleep(200);

  //��ȡ����
  ZeroMemory(@FRecordInfo,SizeOf(FRecordInfo));
  ZeroMemory(@nCardID,SizeOf(nCardID));
  nRet := K720_S50GetCardID(FComHandle,C_MacAddr,@nCardID,@FRecordInfo);
  if nRet=-107 then
  begin
    ResetMachine;
    ZeroMemory(@FRecordInfo,SizeOf(FRecordInfo));
    nRet := K720_S50GetCardID(FComHandle,C_MacAddr,@nCardID,@FRecordInfo);
  end;
  if 0<>nRet then
  begin
    ErrorCode := 1050;
    ErrorMsg := '��ȡ�����ʧ�ܣ�����ϵ�������Ա����';
  end;

  nCardno := ParseCardNO(nCardID);

  //��ȡ����ʧ�ܣ�˵����Ƭ��ʧЧ����ʼ����
  while nCardno=C_EMPTY_CARD_NO do
  begin
    ZeroMemory(@FRecordInfo,SizeOf(FRecordInfo));
//    Sleep(1000);
    if not RecycleCard then
    begin
      ErrorCode := 1060;
      ErrorMsg := '���տ�Ƭʧ��';
      Exit;
    end;
    GetCurrentStatus(FMachineStatus);
    if (FMachineStatus.msCode=c_MachineStatus_CardBoxEmpty)
      or (FMachineStatus.msCode=C_MachineStatus_OverlapedCard)
      or (FMachineStatus.msCode=C_MaahineStatus_RecycleBoxFull1)
      or (FMachineStatus.msCode=C_MaahineStatus_RecycleBoxFull2) then
    begin
      ErrorCode := StrToInt(FMachineStatus.msCode);
      ErrorMsg := FMachineStatus.msDesc;
      if FParentWnd<>0 then
      begin
        MessageBeep($FFFFFFFF);
        MessageBox(FParentWnd,PChar(ErrorMsg),'Error',0);
      end;
      Result := False;
      Exit;
    end;
    //���·���
    if IssueOneCard(nCardno) then
    begin
      Result := True;
      Exit;
    end;
  end;

  //�ƶ�������λ��
  ZeroMemory(@FRecordInfo,SizeOf(FRecordInfo));
  nRet := K720_SendCmd(FComHandle, C_MacAddr, PChar(C_CMD_Position_CardPort),Length(C_CMD_Position_CardPort),@FRecordInfo);
  if 0<>nRet then
  begin
    ErrorCode := 1070;
    ErrorMsg := '�ƶ�������λ��ʧ��';
    Exit;
  end;
  //��λ
  ZeroMemory(@FRecordInfo,SizeOf(FRecordInfo));
  nRet := K720_SendCmd(FComHandle, C_MacAddr, 'RS', 2,@FRecordInfo);
  WaitforIdle;
  Result := True;
end;

function TSzttceApi.OpenComPort: Boolean;
begin
  Result := False;
  if FComHandle>0 then
  begin
    Result := True;
    Exit;
  end;
  FComHandle := K720_CommOpen(PChar(FPort));
  if FComHandle=0 then
  begin
    ErrorCode := 1080;
    ErrorMsg := '�򿪴���['+FPort+']ʧ��';
    Exit;
  end;
  Result := True;
end;

function TSzttceApi.ParseCardNO(var nCardid: array of Byte): string;
var
  nIdx:Integer;
  nInt: Int64;
begin
  Result := '';
  for nIdx := High(nCardid) downto Low(nCardid) do
  begin
    Result := Result+IntToHex(nCardid[nIdx],2);
  end;
  nInt := StrToInt64('$' + Result);
  Result := IntToStr(nInt);
  Result := StringOfChar('0', 12 - Length(Result)) + Result;
end;

function TSzttceApi.ParseStateInfo: Boolean;
var
  nStr:string;
begin
  Result := True;
  nStr := Copy(StrPas(@FStateInfo),1,4);
  FMachineStatus.msCode := nStr;
  if nStr = '8000' then
  begin
    FMachineStatus.msDesc := '��������';
    Exit;
  end;
  if nStr='4000' then
  begin
    FMachineStatus.msDesc := '׼����ʧ��';
    Exit;
  end;
  if nStr='2000' then
  begin
    FMachineStatus.msDesc := '����׼����';
    Exit;
  end;
  if nStr='1000' then
  begin
    FMachineStatus.msDesc := '���ڷ���';
    Exit;
  end;
  if nStr='0800' then
  begin
    FMachineStatus.msDesc := '�����տ�';
    Exit;
  end;
  if nStr='0400' then
  begin
    FMachineStatus.msDesc := '��������';
    Exit;
  end;
  if nStr='0232' then
  begin
    FMachineStatus.msDesc := '��������';
    Exit;
  end;
  if nStr='0133' then
  begin
    FMachineStatus.msDesc := '�տ�����,����������Ƿ�����';
    Exit;
  end;
  if nStr='0132' then
  begin
    FMachineStatus.msDesc := '�տ�����,����������Ƿ�����';
    Exit;
  end;
  if nStr='0100' then
  begin
    FMachineStatus.msDesc := 'δ֪״̬';
    Exit;
  end;
  if nStr='0080' then
  begin
    FMachineStatus.msDesc := 'δ֪״̬';
    Exit;
  end;
  if nStr='0040' then
  begin
    FMachineStatus.msDesc := '�ص���';
    Exit;
  end;
  if nStr='0020' then
  begin
    FMachineStatus.msDesc := '������';
    Exit;
  end;
  if nStr='0018' then
  begin
    FMachineStatus.msDesc := '�����ѿ�';
    Exit;
  end;
  if nStr='0016' then
  begin
    FMachineStatus.msDesc := '���ڴ�����2-3λ��';
    Exit;
  end;
  if nStr='0014' then
  begin
    FMachineStatus.msDesc := '���ڴ�����3λ��';
    Exit;
  end;
  if nStr='0013' then
  begin
    FMachineStatus.msDesc := '���ڴ�����1-2λ��';
    Exit;
  end;
  if nStr='0010' then
  begin
    FMachineStatus.msDesc := '�����ѿ�';
    Exit;
  end;
  if nStr='0008' then
  begin
    FMachineStatus.msDesc := '�����ѿ�';
    Exit;
  end;
  if nStr='0004' then
  begin
    FMachineStatus.msDesc := '���ڴ�����3λ��';
    Exit;
  end;
  if nStr='0003' then
  begin
    FMachineStatus.msDesc := '���ڴ�����1-2λ��';
    Exit;
  end;
  if nStr='0002' then
  begin
    FMachineStatus.msDesc := '���ڴ�����2λ��';
    Exit;
  end;
  if nStr='0001' then
  begin
    FMachineStatus.msDesc := '���ڴ�����1λ��';
    Exit;
  end;
  Result := False;
  FMachineStatus.msCode := '9999';
  FMachineStatus.msDesc := 'δ֪״̬';
end;

function TSzttceApi.ReadCardSerialNo(var nCardSerialNo: string): Boolean;
var
  nRet:Integer;
  nCardID:array[0..3] of Byte;
begin
  nCardSerialNo := '';
  Result := False;
  if not OpenComPort then Exit;
  GetCurrentStatus(FMachineStatus);
  if (FMachineStatus.msCode=c_MachineStatus_CardBoxEmpty) then
  begin
    ErrorCode := 1108;
    ErrorMsg := 'δ�忨';
    Exit;
  end;
  if (FMachineStatus.msCode<>C_MaahineStatus_ReadyForRead1) and (FMachineStatus.msCode<>C_MaahineStatus_ReadyForRead2) then
  begin
    ErrorCode := 1109;
    ErrorMsg := '�豸����״̬δ����';
    Exit;
  end;
  //��ȡ����
  ZeroMemory(@FRecordInfo,SizeOf(FRecordInfo));
  ZeroMemory(@nCardID,SizeOf(nCardID));
  nRet := K720_S50GetCardID(FComHandle,C_MacAddr,@nCardID,@FRecordInfo);
  if nRet=-107 then
  begin
    ResetMachine;
    ZeroMemory(@FRecordInfo,SizeOf(FRecordInfo));
    nRet := K720_S50GetCardID(FComHandle,C_MacAddr,@nCardID,@FRecordInfo);
  end;
  if 0<>nRet then
  begin
    ErrorCode := 1110;
    ErrorMsg := '��ȡ�����к�ʧ��';
    ZeroMemory(@FRecordInfo,SizeOf(FRecordInfo));
  end;
  nCardSerialNo := ParseCardNO(nCardID);

  //��ȡ������ϣ���ʼ�˿�
  ZeroMemory(@FRecordInfo,SizeOf(FRecordInfo));
  nRet := K720_SendCmd(FComHandle, C_MacAddr, PChar(C_CMD_Position_CardPort),Length(C_CMD_Position_CardPort),@FRecordInfo);
  if 0<>nRet then
  begin
    ErrorCode := 1140;
    ErrorMsg := '���￨��λ��ʧ��';
    Exit;
  end;
  Sleep(500);
  //��һ�ſ��ڴ�����2-3��λ�ã���Ҫ����
  GetCurrentStatus(FMachineStatus);
  if (FMachineStatus.msCode=C_MaahineStatus_Status_Error1) then
  begin
    if not RecycleCard then
    begin
      ErrorCode := 1139;
      ErrorMsg := '���տ�Ƭʧ��';
      Exit;
    end;
  end;
//  FTimerStatus.Enabled := True;
  Result := True;
end;

function TSzttceApi.RecycleCard: Boolean;
var
  nRet :Integer;
begin
  Result := False;
  if not OpenComPort then Exit;
  ZeroMemory(@FRecordInfo,SizeOf(FRecordInfo));
  nRet := K720_SendCmd(FComHandle, C_MacAddr, PChar(C_CMD_RecycleCard),Length(C_CMD_RecycleCard),@FRecordInfo);
  if nRet<>0 then
  begin
    ErrorCode := 1150;
    ErrorMsg := '���տ�Ƭʧ��';
    Exit;
  end;
  Result := True;
end;

//procedure TSzttceApi.WriteLog(const nMsg: string);
//var
//  nfilename:string;
//  nstrs:TStringList;
//begin
//  nfilename := ExtractFilePath(ParamStr(0))+'SzttceApi.log';
//  nstrs := TStringList.Create;
//  try
//    if FileExists(nfilename) then
//    begin
//      nstrs.LoadFromFile(nfilename);
//    end;
//    nstrs.Add(nMsg);
//    nstrs.SaveToFile(nfilename);
//  finally
//    nstrs.Free;
//  end;
//end;

function TSzttceApi.ResetMachine:Boolean;
var
  nRet :integer;
begin
  Result := False;
  //��λ
  ZeroMemory(@FRecordInfo,SizeOf(FRecordInfo));
  nRet := K720_SendCmd(FComHandle, C_MacAddr, 'RS', 2,@FRecordInfo);
  if 0<>nRet then
  begin
    ErrorCode := 1030;
    ErrorMsg := '��������λʧ��';
    Exit;
  end;
  Result := True;
end;

procedure TSzttceApi.WaitforIdle;
begin
  while True do
  begin
    GetCurrentStatus(FMachineStatus);
    if (FMachineStatus.msCode=c_MachineStatus_Ready1) or (FMachineStatus.msCode=c_MachineStatus_Ready2) or (FMachineStatus.msCode=c_MachineStatus_CardBoxEmpty) then Break;
    Sleep(10);
  end;
end;

end.
