{*******************************************************************************
����: fendou116688@163.com 2016/6/3
����: ���֤����������Ԫ
*******************************************************************************}
unit UMgrSDTReader;

interface

uses
  Windows, SysUtils, Classes, Forms, Graphics, NativeXml, UWaitItem, ULibFun,
  USysLoger, JclUnicode, UMgrSDTReader_Head, SyncObjs, IdGlobal;

type
  PSDTReaderItem = ^TSDTReaderItem;
  TSDTReaderItem = record
    FID: string;            //��ʶ
    FName: string;          //����
    FIsUSB: Boolean;        //�Ƿ�USB�˿�
    FEnabled: Boolean;      //�Ƿ�����
    FIfOpen: Integer;       //�ӿ��ڲ��򿪹رն˿�
    FImgEnable: Boolean;    //�Ƿ�����ͼƬ

    FPort: Integer;         //�˿ں�
    FBaud: Integer;         //������
    FMaxBytes: Integer;     //���ͨѶ�ֽ�
    FOpenPortRtn: Integer;  //�˿��Ƿ��
  end;

  TIdCardInfoStr = record
    FName: string;                        //����
    FSex : string;                        //�Ա�

    FNation: string;                      //����
    FBirthDay:string;                     //����
    FAddr : string;                       //��ַ
    FIdSN : string;                       //֤����

    FIssueOrgan: string;                  //סַ
    FVaildBegin: string;                  //��Ч��ͷ
    FVaildEnd  : string;                  //��Ч��β
    FtheNewestAddr: string;               //�µ�ַ
  end;

  TSDTReaderManager = class;
  TSDTReaderThread = class(TThread)
  private
    FOwner: TSDTReaderManager;
    //ӵ����
    FWaiter: TWaitObject;
    //�ȴ�����
    FNowItem: PSDTReaderItem;
    //��ǰ����
  protected
    procedure Execute; override;
    //ִ���߳�
    procedure ReadCard(nRead: PSDTReaderItem);
    //�����֤��
    procedure UnPackIDCardInfo(var nCardStr: TIdCardInfoStr;
      nCardWChar: TIdCardInfoWChar);
    //ת�����֤��Ϣ  
  public
    constructor Create(AOwner: TSDTReaderManager);
    destructor Destroy; override;
    //�����ͷ�
    procedure StopMe;
    //ֹͣ�߳�
  end;

  TSDTProc  = procedure (const nCard: TIdCardInfoStr;const nReader: TSDTReaderItem);
  TSDTEvent = procedure (const nCard: TIdCardInfoStr;const nReader: TSDTReaderItem) of Object;
  //�����¼�
  TIMGProc  = procedure (const nFile: string; const nReader: TSDTReaderItem);
  TIMGEvent = procedure (const nFile: string; const nReader: TSDTReaderItem) of Object;
  //��Ƭ�¼�

  TSDTReaderManager = class(TObject)
  private
    FReaders: TList;
    //�������б�
    FTempDir: string;
    //��ʱĿ¼
    FReader: TSDTReaderThread;
    //�����߳�
    FSyncLock: TCriticalSection;
    //�ٽ���Դ
    FSDTProc: TSDTProc;
    FSDTEvent: TSDTEvent;
    //�¼����
    FIMGProc: TIMGProc;
    FIMGEvent: TIMGEvent;
    //�¼����
  protected
    procedure ClearList(const nFree: Boolean);
    //������Դ
  public
    constructor Create;
    destructor Destroy; override;
    //�����ͷ�
    procedure LoadConfig(const nFile: string);
    procedure StartReader;
    procedure StopReader;
    //��ͣ����
    property Readers: TList read FReaders;
    property TempDir: string read FTempDir write FTempDir;
    //�������
    property OnSDTProc: TSDTProc read FSDTProc write FSDTProc;
    property OnSDTEvent: TSDTEvent read FSDTEvent write FSDTEvent;
    property OnIMGProc: TIMGProc read FIMGProc write FIMGProc;
    property OnIMGEvent: TIMGEvent read FIMGEvent write FIMGEvent;
    //�¼����
  end;

var
  gSDTReaderManager: TSDTReaderManager = nil;
  //ȫ��ʹ��

implementation

//------------------------------------------------------------------------------
procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(TSDTReaderManager, '���֤������������', nEvent);
end;

constructor TSDTReaderThread.Create(AOwner: TSDTReaderManager);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FOwner := AOwner;

  FWaiter := TWaitObject.Create;
  FWaiter.Interval := 5 * 10;
end;

destructor TSDTReaderThread.Destroy;
begin
  FWaiter.Free;
  inherited;
end;

//Desc: ֹͣ(�ⲿ����)
procedure TSDTReaderThread.StopMe;
begin
  Terminate;
  FWaiter.Wakeup;

  WaitFor;
  Free;
end;

procedure TSDTReaderThread.Execute;
var nIdx: Integer;
begin
  while not Terminated do
  try
    FWaiter.EnterWait;
    if Terminated then Break;

    with FOwner do
    begin
      FSyncLock.Enter;
      try
        for nIdx := 0 to FReaders.Count - 1 do
        begin
          FNowItem := FReaders[nIdx];
          if not FNowItem.FEnabled then Continue;

          ReadCard(FNowItem);
        end;  
      finally
        FSyncLock.Leave;
      end;
    end;
  except
    on E: Exception do
    begin
      WriteLog(E.Message);
    end;
  end;
end;

procedure TSDTReaderThread.ReadCard(nRead: PSDTReaderItem);
var nErr: string;
    nFS: TFileStream;
    nCardInfoStr: TIdCardInfoStr;
    nCardInfoWC:TIdCardInfoWChar;
    nRet, nIdx, nMInfo, nSNO: Integer;
    nIDInfo, nWLTInfo: array [0..2048] of Byte;
begin
  with nRead^ do
  begin
    if Terminated then Exit;

    if FIsUSB then
    begin
      if (FPort < 1001) or (FPort > 1016)  then
      begin
        for nIdx := 1001 to 1016 do
        begin
          FOpenPortRtn:= SDT_OpenPort(nIdx);
          if FOpenPortRtn = cReader_OperateOK then
          begin
            FPort:= nIdx;
            break;
          end;
        end;
      end else

      begin
        FOpenPortRtn:= SDT_OpenPort(FPort);
      end;
    end else

    begin
      if (FPort < 0) or (FPort > 16) then
      begin
        for nIdx := 1 to 16 do     //����1-16
        begin
          FOpenPortRtn:= SDT_OpenPort(nIdx);
          if FOpenPortRtn = cReader_OperateOK then
          begin
            FPort:= nIdx;
            break;
          end;
        end;
      end else

      begin
        FOpenPortRtn:= SDT_OpenPort(FPort);
      end;
    end;

    if FOpenPortRtn <> cReader_OperateOK then
    begin
      nErr := ERROR_ICREADER_OPEN_PORT;
      {$IFDEF DEBUG}
      WriteLog(nErr);
      {$ENDIF}
      Exit;
    end;

    //�����ҿ�
    for nIdx := 0 to cTry_Times -1 do
    begin
      nRet:= SDT_StartFindIDCard(FPort, nMInfo, FIfOpen);

      if nRet = cReader_FindCardOK then Break;
    end;  

//    if nRet <> cReader_FindCardOK then
//    begin
//      SDT_ClosePort(FPort);
//      nErr := TIP_ICREADER_NO_CARD;
//      {$IFDEF DEBUG}
//      WriteLog(nErr);
//      {$ENDIF}
//      Exit;
//    end;

    //ѡ��
    for nIdx := 0 to cTry_Times -1 do
    begin
      nRet:= SDT_SelectIDCard(FPort, nSNO, FIfOpen);

      if nRet = cReader_OperateOK then Break;
    end;  

//    if nRet <> cReader_OperateOK then
//    begin
//      SDT_ClosePort(FPort);
//      nErr := TIP_ICREADER_READ_FAILED;
//      {$IFDEF DEBUG}
//      WriteLog(nErr);
//      {$ENDIF}
//      Exit;
//    end;

    if FOwner.TempDir = '' then FOwner.TempDir := 'D:\���֤�����б�\';
    if not DirectoryExists(FOwner.TempDir) then
      ForceDirectories(FOwner.TempDir);

    //ע�⣬������û�������Ӧ�ó���ǰĿ¼�Ķ�дȨ��
    if FileExists(FOwner.TempDir + TIP_FILE_TXT) then
      DeleteFile(FOwner.TempDir + TIP_FILE_TXT);
    if FileExists(FOwner.TempDir + TIP_FILE_BMP) then
      DeleteFile(FOwner.TempDir + TIP_FILE_BMP);
    if FileExists(FOwner.TempDir + TIP_FILE_WLT) then
      DeleteFile(FOwner.TempDir + TIP_FILE_WLT);

//    nRet := SDT_ReadBaseMsgToFile(FPort,
//            PAnsiChar(FOwner.TempDir + TIP_FILE_TXT), nMInfo,
//            PAnsiChar(FOwner.TempDir + TIP_FILE_WLT), nSNO, 1);

    FillChar(nIDInfo, SizeOf(nIDInfo), #0);
    FillChar(nWLTInfo, SizeOf(nWLTInfo), #0);
    nRet := SDT_ReadBaseMsg(FPort, @nIDInfo, nMInfo, @nWLTInfo, nSNO, 1);
    if nRet <> cReader_OperateOK then
    begin
      SDT_ClosePort(FPort);
      nErr := TIP_ICREADER_READ_FAILED;
      {$IFDEF DEBUG}
      WriteLog(nErr);
      {$ENDIF}
      Exit;
    end;

    SDT_ClosePort(FPort);
    //�رն˿�
//
//    nFS := TFileStream.Create(FOwner.TempDir + TIP_FILE_TXT, fmOpenRead);
//    try
//      nFS.Position:= 0;
//      nFS.Read(nCardInfoWC ,SizeOf(TIdCardInfoWChar));
//    finally
//      FreeAndNil(nFS);
//    end;
    if FImgEnable then
    begin
      try
        nFS := TFileStream.Create(FOwner.TempDir + TIP_FILE_WLT, fmCreate);

        nFS.Write(nWLTInfo, nSNO);
      finally
        FreeAndNil(nFS);
      end;
    end;

    Move(nIDInfo, nCardInfoWC, nMInfo);
    UnPackIDCardInfo(nCardInfoStr, nCardInfoWC);
    //ת�����֤��Ϣ

    if Assigned(FOwner.OnSDTProc) then
      FOwner.OnSDTProc(nCardInfoStr, nRead^);

    if Assigned(FOwner.OnSDTEvent) then
      FOwner.OnSDTEvent(nCardInfoStr, nRead^);

    if FImgEnable then
    try
      case FIsUSB of
      True : nRet := GetBmp(PChar(FOwner.TempDir + TIP_FILE_WLT), 2);
      False: nRet := GetBmp(PChar(FOwner.TempDir + TIP_FILE_WLT), 1);
      end;
      //ע�⣬�����C�̸�Ŀ¼��û�л��߳��̵���Ȩ�ļ�Termb.Lic����Ƭ��������ʧ��

      case nRet of
      0: nErr := TIP_ICREADER_CALL_DLL_FAILED;
      1: nErr := TIP_OK;
      -1: nErr := TIP_ICREADER_PICTURE_DECODE_FAILED;
      -2: nErr := TIP_ICREADER_WLT_FILE_EXTEND_FAILED;
      -3: nErr := TIP_ICREADER_WLT_FILE_OPEN_FAILED;
      -4: nErr := TIP_ICREADER_WLT_FILE_FORMAT_FAILED;
      -5: nErr := TIP_ICREADER_NO_LICENSE;
      -6: nErr := TIP_ICREADER_DEVICE_FAILED;
      -7: nErr := TIP_ICREADER_CALL_WLTDLL_FAILED;
      -8: nErr := TIP_ICREADER_CALL_GetBmp_FAILED;
      end;

      if nRet <> 1 then
      begin
        {$IFDEF DEBUG}
        WriteLog(nErr);
        {$ENDIF}
        Exit;
      end;

      if Assigned(FOwner.OnIMGProc) then
        FOwner.OnIMGProc(FOwner.TempDir + TIP_FILE_BMP, nRead^);

      if Assigned(FOwner.OnIMGEvent) then
        FOwner.OnIMGEvent(FOwner.TempDir + TIP_FILE_BMP, nRead^);
    except
      on E: Exception do
      begin
        WriteLog(E.Message);
      end;
    end;
  end;
end;

procedure TSDTReaderThread.UnPackIDCardInfo(var nCardStr: TIdCardInfoStr;
  nCardWChar: TIdCardInfoWChar);
begin
  with nCardStr, nCardWChar do
  begin
    FName := AnsiString(Name);
    //����

    if AnsiString(Sex)= '1' then
         FSex := '��'
    else FSex := 'Ů';
    //�Ա�

    FNation := EthnicNoToName(AnsiString(Nation));
    //����
    FBirthDay:= Trim(AnsiString(BirthDay));
    //����������
    FAddr   := Trim(AnsiString(Addr));
    //סַ
    FIdSN   := Trim(AnsiString(IdSN));
    //���֤����

    FIssueOrgan:= Trim(AnsiString(IssueOrgan));
    //��֤����
    FVaildBegin:= Trim(AnsiString(VaildBegin));
    //��Ч���ڿ�ʼ
    if Trim(AnsiString(VaildEnd)) = '����' then
         FVaildEnd:= FormatDateTime('yyyy-MM-dd', MaxDateTime)
    else FVaildEnd:= Trim(AnsiString(VaildEnd));
    //��Ч���ڽ���
  end;
end;    

//------------------------------------------------------------------------------
constructor TSDTReaderManager.Create;
begin
  FReaders := TList.Create;
  FSyncLock := TCriticalSection.Create;
end;

destructor TSDTReaderManager.Destroy;
begin
  StopReader;
  ClearList(True);
  FSyncLock.Free;
  inherited;
end;

procedure TSDTReaderManager.ClearList(const nFree: Boolean);
var nIdx: Integer;
begin
  for nIdx:=FReaders.Count - 1 downto 0 do
  begin
    Dispose(PSDTReaderItem(FReaders[nIdx]));
    FReaders.Delete(nIdx);
  end;

  if nFree then FreeAndNil(FReaders);
end;

procedure TSDTReaderManager.StartReader;
begin
  if not Assigned(FReader) then
    FReader := TSDTReaderThread.Create(Self);
  FReader.FWaiter.Wakeup;
end;

procedure TSDTReaderManager.StopReader;
begin
  if Assigned(FReader) then
    FReader.StopMe;
  FReader := nil;
end;

//------------------------------------------------------------------------------
//Desc: ��ȡnFile
procedure TSDTReaderManager.LoadConfig(const nFile: string);
var nIdx: Integer;
    nItem: TSDTReaderItem;
    nReader: PSDTReaderItem;
    nXML: TNativeXml;
    nNode,nTmp: TXmlNode;
begin
  nXML := TNativeXml.Create;
  try
    ClearList(False);
    nXML.LoadFromFile(nFile);
    
    for nIdx:=0 to nXML.Root.NodeCount - 1 do
    with nItem do
    begin
      nNode := nXML.Root.Nodes[nIdx];
      FID := nNode.AttributeByName['ID'];
      FName := nNode.AttributeByName['Name'];

      nTmp := nNode.FindNode('IsUSB');
      if Assigned(nTmp) then
           FIsUSB := nTmp.ValueAsString <> 'N'
      else FIsUSB := True;

      nTmp := nNode.FindNode('enable');
      if Assigned(nTmp) then
           FEnabled := nTmp.ValueAsString <> 'N'
      else FEnabled := True;

      nTmp := nNode.FindNode('port');
      if Assigned(nTmp) then
           FPort := nTmp.ValueAsInteger
      else FPort := 0;

      nTmp := nNode.FindNode('baud');
      if Assigned(nTmp) then
           FBaud := nTmp.ValueAsInteger
      else FBaud := 9600;

      nTmp := nNode.FindNode('MaxBytes');
      if Assigned(nTmp) then
           FMaxBytes := nTmp.ValueAsInteger
      else FMaxBytes := 9600;

      nTmp := nNode.FindNode('IfOpen');
      if Assigned(nTmp) then
           FIfOpen := nTmp.ValueAsInteger
      else FIfOpen := 1;

      nTmp := nNode.FindNode('IMGEnable');
      if Assigned(nTmp) then
           FImgEnable := nTmp.ValueAsString = 'Y'
      else FImgEnable := False;

      New(nReader);
      FReaders.Add(nReader);
      nReader^ := nItem;
    end;
  finally
    nXML.Free;
  end;
end;

initialization
  gSDTReaderManager := TSDTReaderManager.Create;
finalization
  FreeAndNil(gSDTReaderManager);
end.


