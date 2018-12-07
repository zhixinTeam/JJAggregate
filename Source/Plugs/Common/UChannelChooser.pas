{*******************************************************************************
  ����: dmzn@163.com 2012-03-10
  ����: ��Чѡ����Чҵ��ͨ��,ƽ�⸺��

  ��ע:
  *.ͨ��ÿ12���Ӹ���һ��,��Ӧ������Ϊ��ѡ.
  *.��ͨ����24Сʱ������Ӧ,��û���������ظõ�ַ����Ϣ,��ɾ��.
*******************************************************************************}
unit UChannelChooser;

interface

uses
  Windows, Classes, ComCtrls, SysUtils, SyncObjs, IniFiles, UWaitItem,
  UMgrChannel, UBusinessConst, UBusinessWorker, UBusinessPacker,
  MIT_Service_Intf, ULibFun;

type
  TChannelChoolser = class;
  TChannelRefresher = class(TThread)
  private
    FOwner: TChannelChoolser;
    //ӵ����
    FWaiter: TWaitObject;
    //�ȴ�����
  protected
    procedure Execute; override;
    //ˢ��ͨ��
  public
    constructor Create(AOwner: TChannelChoolser);
    destructor Destroy; override;
    //�����ͷ�
    procedure StopMe;
    //ֹͣ�߳�
  end;

  TChannelURLItem = record
    FSrvURL: string;       //�����ַ
    FLastAct: TDateTime;   //�ϴλ
    FEnable: Boolean;      //�Ƿ���Ч
  end;

  TChannelChoolser = class(Tobject)
  private
    FFileName: string;
    //�����ļ�
    FModified: Boolean;
    //�Ķ����
    FIsValid: Boolean;
    //������Ч
    FFirstOne: string;
    FActiveOne: string;
    //����ͨ��
    FWaiter: TWaitObject;
    //�ȴ�����
    FLastCheck: Int64;
    FNumChecker: Integer;
    //̽���߳�
    FRefresher: TChannelRefresher;
    //�����߳�
    FLockOuter: TCriticalSection;
    FLockInner: TCriticalSection;
    //ͬ����
    FAutoLocalList: Boolean;
    FURLs: array of TChannelURLItem;
    //ͨ���б�
    function URLValid(const nURL: string): Boolean;
    function URLExists(const nURL: string): Integer;
    //ͨ���Ѵ���
  public
    constructor Create(const nFileName: string);
    destructor Destroy; override;
    //�����ͷ�
    procedure RWData(const nRead: Boolean; const nFile:string);
    //��д����
    procedure AddChanels(const nURL: string; const nFlag: string = #13#10);
    procedure AddChannelURL(const nURL: string);
    //���ͨ��
    function GetChannelURL: string;
    //��ȡͨ��
    procedure StartRefresh;
    procedure StopRefresh;
    //��ͣ����
    property FileName: string read FFileName;
    property ChannelValid: Boolean read FIsValid;
    property ActiveURL: string read FActiveOne write FActiveOne;
    property AutoUpdateLocal: Boolean read FAutoLocalList write FAutoLocalList;
    //�������
  end;

var
  gChannelChoolser: TChannelChoolser = nil;
  //ȫ��ʹ��

implementation

const
  cSystem = 'System';
  cSrvURL = 'ServiceURL';

type
  TChannelChecker = class(TThread)
  private
    FOwner: TChannelChoolser;
    //ӵ����
    FChannelURL: string;
    //ͨ����ַ
  protected
    procedure Execute; override;
    //̽��ͨ��
    procedure SetURLStatus(const nActive: Boolean);
    //����״̬
  public
    constructor Create(AOwner: TChannelChoolser; nURL: string);
    destructor Destroy; override;
    //�����ͷ�
  end;

constructor TChannelChecker.Create(AOwner: TChannelChoolser; nURL: string);
begin
  inherited Create(False);
  FreeOnTerminate := True;

  FOwner := AOwner;
  FChannelURL := nURL;
  InterlockedIncrement(FOwner.FNumChecker);
end;

destructor TChannelChecker.Destroy;
begin
  inherited;

  with FOwner do
  try
    FLockInner.Enter;
    if (FFirstOne = '') and (FNumChecker <= 1) then
    begin
      FIsValid := False;
      FWaiter.Wakeup;
    end; //the last one
  finally
    FLockInner.Leave;
  end;

  InterlockedDecrement(FOwner.FNumChecker);
  //for counter
end;

//Date: 2012-3-10
//Parm: �״̬
//Desc: ����nActive����ͨ��״̬
procedure TChannelChecker.SetURLStatus(const nActive: Boolean);
var nIdx: Integer;
begin
  with FOwner do
  try
    FLockInner.Enter;
    //sync lock

    for nIdx:=Low(FURLs) to High(FURLs) do
    with FURLs[nIdx] do
    begin
      if FSrvURL <> FChannelURL then Continue;

      if nActive then
      begin
        FEnable := True;
        FLastAct := Now();
      end else

      if Now() - FLastAct >= 1 then
      begin
        FEnable := False;
        FModified := True;
      end;
    end;
  finally
    FLockInner.Leave;
  end;
end;

procedure TChannelChecker.Execute;
var nStr: string;
    nIdx: Integer;
    nList: TStrings;
    nChannel: PChannelItem;
begin
  nList:= nil;
  nChannel := nil;

  with FOwner do
  try
    nChannel := gChannelManager.LockChannel(cBus_Channel_Connection);
    if not Assigned(nChannel) then Exit;

    with nChannel^ do
    try
      if not Assigned(FChannel) then
        FChannel := CoSrvConnection.Create(FMsg, FHttp);
      //xxxxx

      FHttp.TargetURL := FChannelURL;
      if not ISrvConnection(FChannel).Action(sSys_SweetHeart, nStr) then Exit;
      SetURLStatus(True);
    except
      SetURLStatus(False);
      Exit;
    end;

    FLockInner.Enter;
    try
      if FFirstOne = '' then
      begin
        FFirstOne := FChannelURL;
        FIsValid := True;
        FWaiter.Wakeup;
      end;
    finally
      FLockInner.Leave;
    end;

    if FAutoLocalList and (nStr <> '') then
    begin
      nStr := PackerDecodeStr(nStr);
      nList := TStringList.Create;
      nList.Text := nStr;

      for nIdx:=0 to nList.Count - 1 do
        AddChannelURL(nList[nIdx]);
      //xxxxx
    end;
  finally
    nList.Free;
    gChannelManager.ReleaseChannel(nChannel);
    //release channel
  end;
end;

//------------------------------------------------------------------------------
constructor TChannelRefresher.Create(AOwner: TChannelChoolser);
begin
  inherited Create(False);
  FreeOnTerminate := False;

  FOwner := AOwner;
  FWaiter := TWaitObject.Create;
  FWaiter.Interval := 1000 * 60 * 12;
end;

destructor TChannelRefresher.Destroy;
begin
  FWaiter.Free;
  inherited;
end;

procedure TChannelRefresher.StopMe;
begin
  Terminate;
  FWaiter.Wakeup;

  WaitFor;
  Free;
end;

procedure TChannelRefresher.Execute;
begin
  while not Terminated do
  try
    FWaiter.EnterWait;
    if Terminated then Exit;

    FOwner.GetChannelURL;
    //to refresh
  except
    //ignor any error
  end;
end;

//------------------------------------------------------------------------------
constructor TChannelChoolser.Create(const nFileName: string);
begin
  FLastCheck := 0;
  FNumChecker := 0;
  FAutoLocalList := True;

  FIsValid := True;
  FModified := False;
  FFileName := nFileName;

  FWaiter := TWaitObject.Create;   
  FLockInner := TCriticalSection.Create;
  FLockOuter := TCriticalSection.Create;

  FRefresher := nil;
  RWData(True, FFileName);
end;

destructor TChannelChoolser.Destroy;
begin
  StopRefresh;
  //stop

  while FNumChecker > 0 do ;
  //wait for checker free

  if FModified then
    RWData(False, FFileName);
  //save data

  FWaiter.Free;
  FLockInner.Free;
  FLockOuter.Free;
  inherited;
end;

//Date: 2012-3-10
//Parm: ��д;�ļ�
//Desc: ��д�����б��ļ�
procedure TChannelChoolser.RWData(const nRead: Boolean; const nFile: string);
var nStr,nTag: string;
    nIni: TIniFile;
    nIdx,nLen: Integer;
begin
  if nFile = '' then Exit;
  nIni := TIniFile.Create(nFile);

  with nIni do
  try
    FLockInner.Enter;
    //to lock
    
    if nRead then
    begin
      SetLength(FURLs, 0);
      FActiveOne := ReadString(cSystem, 'Active', '');

      nIdx := ReadInteger(cSystem, 'Number', 0);
      Dec(nIdx);

      while nIdx >= 0 do
      try
        nTag := '_' + IntToStr(nIdx);
        nStr := ReadString(cSrvURL, 'URL' + nTag, '');
        if (not URLValid(nStr)) or (URLExists(nStr) > -1) then Continue;
        
        nLen := Length(FURLs);
        SetLength(FURLs, nLen + 1);

        with FURLs[nLen] do
        begin
          FSrvURL := nStr;
          FEnable := True;

          nStr := ReadString(cSrvURL, 'Act' + nTag, DateTime2Str(Now));
          FLastAct := Str2DateTime(nStr);
        end;
      finally
        Dec(nIdx);
      end;

      if nFile = FFileName then
        FModified := False;
      //xxxxx
    end else
    begin
      EraseSection(cSrvURL);
      nLen := 0;

      for nIdx:=Low(FURLs) to High(FURLs) do
      begin
        if not FURLs[nIdx].FEnable then Continue;
        nStr := '_' + IntToStr(nLen);
        Inc(nLen);

        WriteString(cSrvURL, 'URL' + nStr, FURLs[nIdx].FSrvURL);
        WriteString(cSrvURL, 'Act' + nStr, DateTime2Str(FURLs[nIdx].FLastAct));
      end;

      WriteString(cSystem, 'Active', FActiveOne);
      WriteInteger(cSystem, 'Number', Length(FURLs));

      if nFile = FFileName then
        FModified := False;
      //xxxxx
    end;
  finally
    FLockInner.Leave;
    nIni.Free;
  end;
end;

//Date: 2012-3-11
//Parm: �����ַ
//Desc: ����nURL��ʽ�Ƿ�Ϸ�
function TChannelChoolser.URLValid(const nURL: string): Boolean;
var nStr: string;
begin
  nStr := LowerCase(Copy(nURL, 1, 7));
  Result := nStr = 'http://';
end;

//Date: 2012-3-10
//Parm: �����ַ
//Desc: ���nURL�Ƿ��Ѵ���
function TChannelChoolser.URLExists(const nURL: string): Integer;
var nIdx: Integer;
begin
  Result := -1;

  for nIdx:=Low(FURLs) to High(FURLs) do
  if CompareText(nURL, FURLs[nIdx].FSrvURL) = 0 then
  begin
    Result := nIdx;
    Break;
  end;
end;

//Date: 2012-3-10
//Parm: �����ַ
//Desc: ���һ��Զ�̷����ַ
procedure TChannelChoolser.AddChannelURL(const nURL: string);
var nLen: Integer;
begin
  if not URLValid(nURL) then Exit;
  //invalid url

  FLockInner.Enter;
  try
    nLen := URLExists(nURL);
    if nLen < 0 then
    begin
      nLen := Length(FURLs);
      SetLength(FURLs, nLen + 1);
      FURLs[nLen].FSrvURL := nURL;
    end;

    with FURLs[nLen] do
    begin
      FEnable := True;
      FLastAct := Now;

      if FActiveOne = '' then
        FActiveOne := nURL;
      FModified := True;
    end;
  finally
    FLockInner.Leave;
  end;
end;

//Date: 2012-5-28
//Parm: ��ַ�б�;�ָ��
//Desc: �����nFlagΪ��ǵ�nURL��ַ�б�
procedure TChannelChoolser.AddChanels(const nURL, nFlag: string);
var nIdx: Integer;
    nList: TStrings;
begin
  nList := TStringList.Create;
  try
    if nFlag = #13#10 then
         nList.Text := nURL
    else nList.Text := StringReplace(nURL, nFlag, #13#10, [rfReplaceAll]);

    for nIdx:=0 to nList.Count - 1 do
      AddChannelURL(nList[nIdx]);
    //xxxxx
  finally
    nList.Free;
  end;
end;

//Desc: ʹ�ö��߳�̽����õķ����ַ
function TChannelChoolser.GetChannelURL: string;
var nIdx,nNum: Integer;
begin
  FLockOuter.Enter;
  try
    Result := FActiveOne;
    if FNumChecker > 0 then Exit;
    if GetTickCount - FLastCheck < 60 * 1000 then Exit;

    FLockInner.Enter;
    try
      nNum := 0;
      FFirstOne := '';

      for nIdx:=Low(FURLs) to High(FURLs) do
      if FURLs[nIdx].FEnable then
      begin
        TChannelChecker.Create(Self, FURLs[nIdx].FSrvURL);
        Inc(nNum);
      end;
    finally
      FLockInner.Leave;
    end;

    if nNum > 0 then
    begin
      FWaiter.EnterWait;
      //wait check result

      FLockInner.Enter;
      try
        if (FFirstOne <> '') and
           (CompareText(FFirstOne, FActiveOne) <> 0) then
        begin
          FActiveOne := FFirstOne;
          Result := FFirstOne;
          FModified := True;
        end;
      finally
        FLockInner.Leave;
      end;
    end;

    FLastCheck := GetTickCount;
  finally
    FLockOuter.Leave;
  end;
end;

procedure TChannelChoolser.StartRefresh;
begin
  if not Assigned(FRefresher) then
   if Length(FURLs) > 0 then
    FRefresher := TChannelRefresher.Create(Self);
  //xxxxx
end;

procedure TChannelChoolser.StopRefresh;
begin
  if Assigned(FRefresher) then
  begin
    FRefresher.StopMe;
    FRefresher := nil;
  end;

  while FNumChecker > 0 do
    Sleep(1);
  //wait for release
end;

initialization
  gChannelChoolser := nil;
finalization
  FreeAndNil(gChannelChoolser);
end.


