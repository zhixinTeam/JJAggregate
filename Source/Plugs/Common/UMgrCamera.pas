{*******************************************************************************
  ����: fendou116688@163.com 2016/8/5
  ����: Ӳ��¼�������
*******************************************************************************}
unit UMgrCamera;

interface

uses
  Windows, Classes, SysUtils, NativeXml, IdTCPConnection, IdTCPClient, IdGlobal,
  UWaitItem, USysLoger, ULibFun, HKVNetSDK;

const
  cPTMaxCameraTunnel  = 15;        //֧�ֵ������ͨ����
  cCameraRetry = 2;  
  cCameraXML = 'Camera.xml';
type
  PCameraHost = ^TCameraHost;
  TCameraHost = record
    FName   : string;              //����
    FID     : string;              //��ʶ
    FIP     : string;              //��ַ
    FPort   : Integer;             //�˿�
    FUser   : string;              //��¼��
    FPswd   : string;              //��¼����
    FLines  : TList;               //���б�
    FEnable : Boolean;             //�Ƿ�����
  end;

  PCameraLine = ^TCameraLine;
  TCameraLine = record
    FID     : string;              //��ʶ
    FPicSize: Integer;             //ͼ���С
    FPicQuality: Integer;          //ͼ������
    FCameraTunnels: array[0..cPTMaxCameraTunnel-1] of Byte;
                                   //����ͨ��
  end;

  PCameraFrameCapture = ^TCameraFrameCapture;
  TCameraFrameCapture = record
    FCaptureFix : string;
    FCaptureName: string;
    FCapturePath: string;
    FCameraLine: TCameraLine;
  end;
  //����ץ��

type
  TCameraControler = class;
  TCameraControlChannel = class(TThread)
  private
    FOwner: TCameraControler;
    //ӵ����
    FBuffer: TList;
    //����������
    FWaiter: TWaitObject;
    //�ȴ�����
    FLastSend: Int64;
  protected
    procedure DoExecute(nLogin: Integer);
    procedure Execute; override;
    //ִ���߳�
  public
    constructor Create(AOwner: TCameraControler);
    destructor Destroy; override;
    //�����ͷ�
    procedure Wakeup;
    procedure StopMe;
    //��ͣͨ��
  end;

  //----------------------------------------------------------------------------
  TCameraProc = procedure (const nPtr: Pointer);
  TCameraEvent = procedure (const nPtr: Pointer) of Object;

  TCameraControler = class(TObject)
  private
    FHost: PCameraHost;
    //����
    FData: TThreadList;
    //����
    FChannel: TCameraControlChannel;
    //ͨ��
    FOnProc: TCameraProc;
    FOnEvent: TCameraEvent;
    //�¼�����
  protected
    procedure ClearList(const nList: TList);
    //��������
  public
    constructor Create(const nHost: PCameraHost);
    destructor Destroy; override;
    //�����ͷ�
    procedure AddCommand(const nPtr: Pointer);
    //�������
    property Host: PCameraHost read FHost;
    property OnCameraProc: TCameraProc read FOnProc write FOnProc;
    property OnCameraEvent: TCameraEvent read FOnEvent write FOnEvent;
    //�������
  end;

  TCameraManager = class(TObject)
  private
    FFileName: string;
    //�����ļ�
    FFilePath: string;
    //�ļ�·��
    FHosts: TList;
    //�����б�
    FControler: array of TCameraControler;
    //���ƶ���
    FOnProc: TCameraProc;
    FOnEvent: TCameraEvent;
    //�¼�����
  protected
    procedure ClearHost(const nFree: Boolean);
    //������Դ
    function GetLine(const nLineID: string; var nHost: PCameraHost;
     var nLine: PCameraLine): Boolean;
    //����ͨ��
    function GetControler(const nHost: string): Integer;
    //��������
  public
    constructor Create;
    destructor Destroy; override;
    //�����ͷ�
    procedure LoadConfig(const nFile: string);
    //��ɾ����
    procedure ControlStart;
    procedure ControlStop;
    //��ͣ����
    procedure CapturePicture(const nLineID: string; const nFilePrefix:string;
      const nPath: string = '');
    //ץ��ͼƬ  
    property Hosts: TList read FHosts;
    //�������
    property OnCameraProc: TCameraProc read FOnProc write FOnProc;
    property OnCameraEvent: TCameraEvent read FOnEvent write FOnEvent;
    //�������
  end;

var
  gCameraManager: TCameraManager = nil;
  //ȫ��ʹ��

implementation

procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(TCameraManager, 'Ӳ��¼���������', nEvent);
end;

constructor TCameraManager.Create;
begin
  FHosts := TList.Create;
  SetLength(FControler, 0);
end;

destructor TCameraManager.Destroy;
begin
  ControlStop;
  ClearHost(True);
  inherited;
end;

procedure TCameraManager.ClearHost(const nFree: Boolean);
var i,nIdx: Integer;
    nHost: PCameraHost;
begin
  for nIdx:=FHosts.Count - 1 downto 0 do
  begin
    nHost := FHosts[nIdx];
    for i:=nHost.FLines.Count - 1 downto 0 do
    begin
      Dispose(PCameraLine(nHost.FLines[i]));
      nHost.FLines.Delete(i);
    end;

    nHost.FLines.Free;
    Dispose(nHost);
    FHosts.Delete(nIdx);
  end;

  if nFree then FHosts.Free;
end;

function TCameraManager.GetControler(const nHost: string): Integer;
var nIdx: Integer;
begin
  Result := -1;

  for nIdx:=Low(FControler) to High(FControler) do
  if CompareText(nHost, FControler[nIdx].FHost.FID) = 0 then
  begin
    Result := nIdx;
    Break;
  end;
end;

//Desc: ��������
procedure TCameraManager.ControlStart;
var nIdx,nLen: Integer;
    nHost: PCameraHost;
begin
  if Length(FControler) > 0 then Exit;

  for nIdx:=0 to FHosts.Count - 1 do
  begin
    nHost := FHosts[nIdx];
    if not nHost.FEnable then Continue;
    //δ���õĲ�����

    nLen := Length(FControler);
    SetLength(FControler, nLen + 1);
    FControler[nLen] := TCameraControler.Create(FHosts[nIdx]);

    FControler[nLen].OnCameraProc := FOnProc;
    FControler[nLen].OnCameraEvent:= FOnEvent;
    //��ʼ���¼�����
  end;
end;

//Desc: ֹͣ����
procedure TCameraManager.ControlStop;
var nIdx: Integer;
begin
  for nIdx:=Low(FControler) to High(FControler) do
   if Assigned(FControler) then
    FControler[nIdx].Free;
  SetLength(FControler, 0);
end;

procedure TCameraManager.CapturePicture(const nLineID: string;
  const nFilePrefix:string; const nPath: string);
var nData: PCameraFrameCapture;
    nHost: PCameraHost;
    nLine: PCameraLine;
    nIdx: Integer;
    nP: string;
begin
  if nPath <> '' then
       nP := nPath
  else nP := FFilePath;
  if not DirectoryExists(nP) then ForceDirectories(nP);

  if GetLine(nLineID, nHost, nLine) then
  begin
    nIdx := GetControler(nHost.FID);
    if nIdx < 0 then Exit;

    New(nData);
    nData.FCaptureFix  := nFilePrefix;
    nData.FCameraLine  := nLine^;
    nData.FCapturePath := nP;   
    
    FControler[nIdx].AddCommand(nData);
  end;  
end;    

function TCameraManager.GetLine(const nLineID: string; var nHost: PCameraHost;
  var nLine: PCameraLine): Boolean;
var i,nIdx: Integer;
begin
  Result := False;

  for nIdx:=FHosts.Count - 1 downto 0 do
  begin
    nHost := FHosts[nIdx];

    for i:=nHost.FLines.Count - 1 downto 0 do
    begin
      nLine := nHost.FLines[i];
      if CompareText(nLineID, nLine.FID) = 0 then
      begin
        Result := True;
        Exit;
      end;
    end;
  end;
end;

//Date��2014-6-18
//Parm��ͨ��;��ַ�ַ���,����: 1,2,3
//Desc����nStr��,����nLine.FCameraTunnels�ṹ��
procedure SplitCameraTunnel(const nLine: PCameraLine; const nStr: string);
var nIdx: Integer;
    nList: TStrings;
begin
  nList := TStringList.Create;
  try
    for nIdx:=Low(nLine.FCameraTunnels) to High(nLine.FCameraTunnels) do
      nLine.FCameraTunnels[nIdx] := MAXBYTE;
    //Ĭ��ֵ

    SplitStr(nStr, nList, 0 , ',');
    if nList.Count < 1 then Exit;

    nIdx := nList.Count - 1;
    if nIdx > High(nLine.FCameraTunnels) then
      nIdx := High(nLine.FCameraTunnels);
    //���߽�

    while nIdx>=Low(nLine.FCameraTunnels) do
    begin
      nLine.FCameraTunnels[nIdx] := StrToInt(nList[nIdx]);
      Dec(nIdx);
    end;
  finally
    nList.Free;
  end;
end;

//Date: 2012-4-24
//Parm: �����ļ�
//Desc: ��ȡ�̵�������
procedure TCameraManager.LoadConfig(const nFile: string);
var nStr : string;
    i,nIdx: Integer;
    nXML: TNativeXml;
    nHost: PCameraHost;
    nLine: PCameraLine;
    nNode,nTmp: TXmlNode;
begin
  FFileName := nFile;
  FFilePath := ExtractFilePath(FFileName) + 'Cameras\';
  //xxxxx

  nXML := TNativeXml.Create;
  try
    ClearHost(False);
    nXML.LoadFromFile(nFile);
    
    for nIdx:=0 to nXML.Root.NodeCount - 1 do
    begin
      nTmp := nXML.Root.Nodes[nIdx];
      New(nHost);
      FHosts.Add(nHost);

      with nHost^ do
      begin
        FName := nTmp.AttributeByName['name'];
        nNode := nTmp.NodeByName('param');

        FID := nNode.NodeByName('id').ValueAsString;
        FIP := nNode.NodeByName('ip').ValueAsString;
        FPort := nNode.NodeByName('port').ValueAsInteger;

        FUser := nNode.NodeByName('user').ValueAsString;
        FPswd := nNode.NodeByName('password').ValueAsString;
        FEnable := nNode.NodeByName('enable').ValueAsString <> 'N';
        FLines := TList.Create;
      end;

      nTmp := nTmp.NodeByName('lines');
      for i:=0 to nTmp.NodeCount - 1 do
      begin
        nNode := nTmp.Nodes[i];
        New(nLine);
        nHost.FLines.Add(nLine);

        with nLine^ do
        begin
          FID := nNode.NodeByName('id').ValueAsString;
          FPicSize := nNode.NodeByName('picsize').ValueAsInteger;
          FPicQuality := nNode.NodeByName('picquality').ValueAsInteger;

          nStr := nNode.NodeByName('tunnel').ValueAsString;
          SplitCameraTunnel(nLine, nStr);
        end;
      end;
    end;
  finally
    nXML.Free;
  end;
end;

//------------------------------------------------------------------------------
constructor TCameraControler.Create(const nHost: PCameraHost);
begin
  FHost := nHost;
  FData := TThreadList.Create;
  FChannel := TCameraControlChannel.Create(Self);
end;

destructor TCameraControler.Destroy;
var nList: TList;
begin
  FChannel.StopMe;
  nList := FData.LockList;
  try
    ClearList(nList);
  finally
    FData.UnlockList;
  end;

  FData.Free;
  inherited;
end;

procedure TCameraControler.AddCommand(const nPtr: Pointer);
begin
  FData.LockList.Add(nPtr);
  FData.UnlockList;
  FChannel.Wakeup;
end;

//Desc: ��������
procedure TCameraControler.ClearList(const nList: TList);
var nIdx: Integer;
begin
  for nIdx:=nList.Count - 1 downto 0 do
  begin
    nList.Delete(nIdx);
  end;
end;

//------------------------------------------------------------------------------
constructor TCameraControlChannel.Create(AOwner: TCameraControler);
begin
  inherited Create(False);
  FreeOnTerminate := False;

  FOwner := AOwner;
  FBuffer := TList.Create;
  
  FWaiter := TWaitObject.Create;
  FWaiter.Interval := 3 * 1000;
end;

destructor TCameraControlChannel.Destroy;
begin
  FWaiter.Free;

  FOwner.ClearList(FBuffer);
  FBuffer.Free;
  inherited;
end;

procedure TCameraControlChannel.Wakeup;
begin
  FWaiter.Wakeup;
end;

procedure TCameraControlChannel.StopMe;
begin
  Terminate;
  FWaiter.Wakeup;

  WaitFor;
  Free;
end;

procedure TCameraControlChannel.Execute;
var nList: TList;
    nStr: string;
    nInfo: TNET_DVR_DEVICEINFO;
    nIdx,nNum,nLogin,nErr: Integer;
begin
  FLastSend := 0;
  //init
  
  nNum := 0;
  nLogin := -1;
  //init counter
  
  while not Terminated do
  try
    FWaiter.EnterWait;
    if Terminated then Exit;

    try
      NET_DVR_Init;

      with FOwner.FHost^ do
      begin
        for nIdx:=1 to cCameraRetry do
        begin
          nLogin := NET_DVR_Login(PChar(FIP), FPort, PChar(FUser),
                    PChar(FPswd), @nInfo);
          //to login

          nErr := NET_DVR_GetLastError;
          if nErr = 0 then break;

          if nIdx = cCameraRetry then
          begin
            nStr := '��¼�����[ %s.%d ]ʧ��,������: %d';
            nStr := Format(nStr, [FIP, FPort, nErr]);
            WriteLog(nStr);
            Continue;
          end;
        end;

        if nLogin < 0 then Continue;
      end;
    except
      WriteLog(Format('����[ %s ]ʧ��.', [FOwner.FHost.FIP]));
      NET_DVR_Cleanup();
      Continue;
    end;

    nList := FOwner.FData.LockList;
    try
      if nList.Count > 0 then
        nNum := 0;
      //start counter

      for nIdx:=0 to nList.Count - 1 do
        FBuffer.Add(nList[nIdx]);
      nList.Clear;
    finally
      FOwner.FData.UnlockList;
    end;

    try
      DoExecute(nLogin);
      FOwner.ClearList(FBuffer);
      nNum := 0;
    except

      Inc(nNum);
      if nNum >= 2 then
      begin
        FOwner.ClearList(FBuffer);
        nNum := 0;
      end;

      raise;
      //throw exception
    end;
  except
    on E:Exception do
    begin
      NET_DVR_Cleanup();
      WriteLog(Format('Host:[ %s ] %s', [FOwner.FHost.FID, E.Message]));
    end;
  end;
end;

function MakePicName(const nCapture: PCameraFrameCapture;
  const nIdx: Integer): string;
begin
  while True do
  begin
    Result := Format('%s%s_%d.jpg', [nCapture.FCapturePath,
              nCapture.FCaptureFix, nIdx]);
    if not FileExists(Result) then Exit;

    DeleteFile(Result);
  end;
end;

procedure TCameraControlChannel.DoExecute(nLogin: Integer);
var nStr: string;
    nPic: NET_DVR_JPEGPARA;
    nIdx, nInt, i, nErr: Integer;
    nCapture: PCameraFrameCapture;
begin
  if nLogin < 0 then
  begin
    NET_DVR_Cleanup();
    Exit;
  end;
  //δ��¼

  try
    for nIdx:=FBuffer.Count - 1 downto 0 do
    begin
      nCapture := FBuffer[nIdx];

      nPic.wPicSize := nCapture.FCameraLine.FPicSize;
      nPic.wPicQuality := nCapture.FCameraLine.FPicQuality;

      for i:=Low(nCapture.FCameraLine.FCameraTunnels) to
             High(nCapture.FCameraLine.FCameraTunnels) do
      begin
        if nCapture.FCameraLine.FCameraTunnels[i] = MaxByte then continue;
        //invalid

        for nInt:=1 to cCameraRetry do
        begin
          nCapture.FCaptureName := MakePicName(nCapture,
            nCapture.FCameraLine.FCameraTunnels[i]);
          //file path

          NET_DVR_CaptureJPEGPicture(nLogin, nCapture.FCameraLine.FCameraTunnels[i],
                                     @nPic, PChar(nCapture.FCaptureName));
          //capture pic

          nErr := NET_DVR_GetLastError;
          if nErr = 0 then
          begin
            if Assigned(FOwner.OnCameraProc) then
              FOwner.OnCameraProc(nCapture);

            if Assigned(FOwner.OnCameraEvent) then
              FOwner.OnCameraEvent(nCapture);

            Break;
          end;

          if nIdx = cCameraRetry then
          begin
            nStr := 'ץ��ͼ��[ %s ]ʧ��,������: %d';
            nStr := Format(nStr, [nCapture.FCameraLine.FID, nErr]);
            WriteLog(nStr);
          end;
        end;
      end;
    end;
  finally
    if nLogin > -1 then
      NET_DVR_Logout(nLogin);
    NET_DVR_Cleanup();
  end;
end;

initialization
  gCameraManager := TCameraManager.Create;
finalization
  FreeAndNil(gCameraManager);
end.
