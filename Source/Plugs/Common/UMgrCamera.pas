{*******************************************************************************
  作者: fendou116688@163.com 2016/8/5
  描述: 硬盘录像机控制
*******************************************************************************}
unit UMgrCamera;

interface

uses
  Windows, Classes, SysUtils, NativeXml, IdTCPConnection, IdTCPClient, IdGlobal,
  UWaitItem, USysLoger, ULibFun, HKVNetSDK;

const
  cPTMaxCameraTunnel  = 15;        //支持的摄像机通道数
  cCameraRetry = 2;  
  cCameraXML = 'Camera.xml';
type
  PCameraHost = ^TCameraHost;
  TCameraHost = record
    FName   : string;              //名称
    FID     : string;              //标识
    FIP     : string;              //地址
    FPort   : Integer;             //端口
    FUser   : string;              //登录名
    FPswd   : string;              //登录密码
    FLines  : TList;               //道列表
    FEnable : Boolean;             //是否启用
  end;

  PCameraLine = ^TCameraLine;
  TCameraLine = record
    FID     : string;              //标识
    FPicSize: Integer;             //图像大小
    FPicQuality: Integer;          //图像质量
    FCameraTunnels: array[0..cPTMaxCameraTunnel-1] of Byte;
                                   //摄像通道
  end;

  PCameraFrameCapture = ^TCameraFrameCapture;
  TCameraFrameCapture = record
    FCaptureFix : string;
    FCaptureName: string;
    FCapturePath: string;
    FCameraLine: TCameraLine;
  end;
  //车辆抓拍

type
  TCameraControler = class;
  TCameraControlChannel = class(TThread)
  private
    FOwner: TCameraControler;
    //拥有者
    FBuffer: TList;
    //待发送数据
    FWaiter: TWaitObject;
    //等待对象
    FLastSend: Int64;
  protected
    procedure DoExecute(nLogin: Integer);
    procedure Execute; override;
    //执行线程
  public
    constructor Create(AOwner: TCameraControler);
    destructor Destroy; override;
    //创建释放
    procedure Wakeup;
    procedure StopMe;
    //启停通道
  end;

  //----------------------------------------------------------------------------
  TCameraProc = procedure (const nPtr: Pointer);
  TCameraEvent = procedure (const nPtr: Pointer) of Object;

  TCameraControler = class(TObject)
  private
    FHost: PCameraHost;
    //主机
    FData: TThreadList;
    //数据
    FChannel: TCameraControlChannel;
    //通道
    FOnProc: TCameraProc;
    FOnEvent: TCameraEvent;
    //事件定义
  protected
    procedure ClearList(const nList: TList);
    //清理数据
  public
    constructor Create(const nHost: PCameraHost);
    destructor Destroy; override;
    //创建释放
    procedure AddCommand(const nPtr: Pointer);
    //添加数据
    property Host: PCameraHost read FHost;
    property OnCameraProc: TCameraProc read FOnProc write FOnProc;
    property OnCameraEvent: TCameraEvent read FOnEvent write FOnEvent;
    //属性相关
  end;

  TCameraManager = class(TObject)
  private
    FFileName: string;
    //配置文件
    FFilePath: string;
    //文件路径
    FHosts: TList;
    //主机列表
    FControler: array of TCameraControler;
    //控制对象
    FOnProc: TCameraProc;
    FOnEvent: TCameraEvent;
    //事件定义
  protected
    procedure ClearHost(const nFree: Boolean);
    //清理资源
    function GetLine(const nLineID: string; var nHost: PCameraHost;
     var nLine: PCameraLine): Boolean;
    //检索通道
    function GetControler(const nHost: string): Integer;
    //检索对象
  public
    constructor Create;
    destructor Destroy; override;
    //创建释放
    procedure LoadConfig(const nFile: string);
    //增删主机
    procedure ControlStart;
    procedure ControlStop;
    //启停控制
    procedure CapturePicture(const nLineID: string; const nFilePrefix:string;
      const nPath: string = '');
    //抓拍图片  
    property Hosts: TList read FHosts;
    //属性相关
    property OnCameraProc: TCameraProc read FOnProc write FOnProc;
    property OnCameraEvent: TCameraEvent read FOnEvent write FOnEvent;
    //属性相关
  end;

var
  gCameraManager: TCameraManager = nil;
  //全局使用

implementation

procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(TCameraManager, '硬盘录像机管理器', nEvent);
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

//Desc: 启动控制
procedure TCameraManager.ControlStart;
var nIdx,nLen: Integer;
    nHost: PCameraHost;
begin
  if Length(FControler) > 0 then Exit;

  for nIdx:=0 to FHosts.Count - 1 do
  begin
    nHost := FHosts[nIdx];
    if not nHost.FEnable then Continue;
    //未启用的不启动

    nLen := Length(FControler);
    SetLength(FControler, nLen + 1);
    FControler[nLen] := TCameraControler.Create(FHosts[nIdx]);

    FControler[nLen].OnCameraProc := FOnProc;
    FControler[nLen].OnCameraEvent:= FOnEvent;
    //初始化事件对象
  end;
end;

//Desc: 停止控制
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

//Date：2014-6-18
//Parm：通道;地址字符串,类似: 1,2,3
//Desc：将nStr拆开,放入nLine.FCameraTunnels结构中
procedure SplitCameraTunnel(const nLine: PCameraLine; const nStr: string);
var nIdx: Integer;
    nList: TStrings;
begin
  nList := TStringList.Create;
  try
    for nIdx:=Low(nLine.FCameraTunnels) to High(nLine.FCameraTunnels) do
      nLine.FCameraTunnels[nIdx] := MAXBYTE;
    //默认值

    SplitStr(nStr, nList, 0 , ',');
    if nList.Count < 1 then Exit;

    nIdx := nList.Count - 1;
    if nIdx > High(nLine.FCameraTunnels) then
      nIdx := High(nLine.FCameraTunnels);
    //检查边界

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
//Parm: 配置文件
//Desc: 读取继电器配置
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

//Desc: 清理数据
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
            nStr := '登录摄像机[ %s.%d ]失败,错误码: %d';
            nStr := Format(nStr, [FIP, FPort, nErr]);
            WriteLog(nStr);
            Continue;
          end;
        end;

        if nLogin < 0 then Continue;
      end;
    except
      WriteLog(Format('连接[ %s ]失败.', [FOwner.FHost.FIP]));
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
  //未登录

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
            nStr := '抓拍图像[ %s ]失败,错误码: %d';
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
