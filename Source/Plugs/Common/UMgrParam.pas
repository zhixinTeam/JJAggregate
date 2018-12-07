{*******************************************************************************
  ����: dmzn@163.com 2012-3-2
  ����: MIT����������
*******************************************************************************}
unit UMgrParam;

interface

uses
  Windows, Classes, SysUtils, NativeXml, UBase64, UMgrDBConn, USAPConnection,
  USysLoger;

const
  cParamIDCharacters = ['a'..'z','A'..'Z','0'..'9','_',Char(VK_BACK)];
  //ID��ʶ�����ַ�

type
  PPerformParam = ^TPerformParam;
  TPerformParam = record
    FID               : string;
    FName             : string;              //������ʶ
    FPortTCP          : Integer;
    FPortHttp         : Integer;             //�����˿�
    FPoolSizeSAP      : Integer;
    FPoolSizeConn     : Integer;
    FPoolSizeBusiness : Integer;             //���ӳ�
    FPoolBehaviorConn : Integer;
    FPoolBehaviorBusiness : Integer;         //����ģʽ
    FMaxRecordCount   : Integer;             //����¼��
    FMonInterval      : Integer;             //�ػ����
    FEnable           : Boolean;             //�Ƿ�����
  end;

  TParamType = (ptPack, ptSAP, ptDB, ptPerform);
  //type

  PParamItemPack = ^TParamItemPack;
  TParamItemPack = record
    FID          : string;        //������ʶ
    FName        : string;
    FEnable      : Boolean;       //�Ƿ�����

    FNameSAP     : string;
    FSAP         : PSAPParam;     //sap
    FNameDB      : string;
    FDB          : PDBParam;      //db
    FNamePerform : string;
    FPerform     : PPerformParam; //����
  end;

  TParamManager = class(TObject)
  private
    FFileName   : string;         //�ļ���
    FModified   : Boolean;        //�Ƿ�Ķ�
    FPacks      : TList;          //������
    FItemSAP    : TList;
    FItemDB     : TList;
    FItemPerform: TList;          //������
    FActiveName : string;
    FActive     : PParamItemPack; //�������
    FURLRemote  : TStrings;
    FURLLocal   : TStrings;       //�����ַ
  protected
    procedure ClearList(var nList: TList; const nType: TParamType;
      const nFree: Boolean = True);
    //������Դ
    procedure ParamAction(const nIsRead: Boolean);
    //read or write
  public
    constructor Create(const nFile: string);
    destructor Destroy; override;
    //�����ͷ�
    function LoadParam(const nList: TStrings; nType: TParamType): Boolean;
    //load list
    procedure InitPack(var nItem: TParamItemPack);
    procedure AddPack(const nItem: TParamItemPack);
    procedure DelPack(const nID: string);
    function GetParamPack(const nID: string;
      const nActive: Boolean = False): PParamItemPack;
    //packet
    procedure InitSAP(var nParam: TSAPParam);
    procedure AddSAP(const nParam: TSAPParam);
    procedure DelSAP(const nID: string);
    function GetSAP(const nID: string): PSAPParam;
    //sap
    procedure InitDB(var nParam: TDBParam);
    procedure AddDB(const nParam: TDBParam);
    procedure DelDB(const nID: string);
    function GetDB(const nID: string): PDBParam;
    //database
    procedure InitPerform(var nParam: TPerformParam);
    procedure AddPerform(const nParam: TPerformParam);
    procedure DelPerform(const nID: string);
    function GetPerform(const nID: string): PPerformParam;
    //perform
    property ActiveParam: PParamItemPack read FActive;
    property FileName: string read FFileName;
    property URLRemote: TStrings read FURLRemote;
    property URLLocal: TStrings read FURLLocal;   
    property Modified: Boolean read FModified write FModified;
    //property 
  end;

var
  gParamManager: TParamManager = nil;
  //ȫ��ʹ��

implementation

procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(TParamManager, '����������', nEvent);
end;

constructor TParamManager.Create(const nFile: string);
begin
  FFileName := nFile;
  FModified := False;

  FActive := nil;
  FActiveName := '';
  FPacks := TList.Create;
  
  FItemSAP := TList.Create;
  FItemDB := TList.Create;
  FItemPerform := TList.Create;

  FURLRemote := TStringList.Create;
  FURLLocal := TStringList.Create; 
  ParamAction(True);
end;

destructor TParamManager.Destroy;
begin
  if FModified then
    ParamAction(False);
  //xxxxx

  ClearList(FPacks, ptPack);
  ClearList(FItemSAP, ptSAP);
  ClearList(FItemDB, ptDB);
  ClearList(FItemPerform, ptPerform);

  FreeAndNil(FURLRemote);
  FreeAndNil(FURLLocal);
  inherited;
end;

//Date: 2013-11-23
//Parm: �б�;����;�Ƿ��ͷ�
//Desc: ����nType���͵�nList�б�
procedure TParamManager.ClearList(var nList: TList; const nType: TParamType;
  const nFree: Boolean);
var nIdx: Integer;
begin
  for nIdx:=nList.Count - 1 downto 0 do
  begin
    case nType of
     ptPack      : Dispose(PParamItemPack(nList[nIdx]));
     ptSAP       : Dispose(PSAPParam(nList[nIdx]));
     ptDB        : Dispose(PDBParam(nList[nIdx]));
     ptPerform   : Dispose(PPerformParam(nList[nIdx]));
    end;

    nList.Delete(nIdx);
  end;

  if nFree then
    FreeAndNil(nList);
  //free list
end;

//Date: 2012-3-3
//Parm: �ļ���;��д���
//Desc: ���ļ���д����
procedure TParamManager.ParamAction(const nIsRead: Boolean);
var nStr: string;
    nIdx: Integer;
    nXML: TNativeXml;
    nNode,nTmp: TXmlNode;

    nDB: PDBParam;
    nSAP: PSAPParam;
    nPack: PParamItemPack;
    nPerform: PPerformParam;
begin
  nXML := nil;
  try
    nXML := TNativeXml.Create;
    //file object

    if nIsRead then
    begin
      nXML.LoadFromFile(FFileName);
      //load data

      if not (Assigned(nXML.Root.NodeByName('Param')) and
              Assigned(nXML.Root.NodeByName('Packs'))) then
      begin
        nStr := '�����ļ�[ %s ]δ�ҵ�"Param,Packs"�ڵ�,�޷�����.';
        WriteLog(Format(nStr, [ExtractFileName(FFileName)]));
        Exit;
      end;

      nNode := nXML.Root.NodeByName('Param').NodeByName('DBList');
      if Assigned(nNode) then
      begin
        for nIdx:=0 to nNode.NodeCount - 1 do
        begin
          New(nDB);
          FItemDB.Add(nDB);
          nTmp := nNode.Nodes[nIdx];

          with nDB^,nTmp do
          begin
            FID        := AttributeByName['ID'];
            FName      := AttributeByName['Name'];
            FHost      := NodeByName('Host').ValueAsString;
            FPort      := NodeByName('Port').ValueAsInteger;
            FDB        := NodeByName('DBName').ValueAsString;
            FUser      := NodeByName('User').ValueAsString;

            FPwd       := NodeByName('Password').ValueAsString;
            FPwd       := DecodeBase64(FPwd);
            FConn      := NodeByName('ConnStr').ValueAsString;
            FConn      := DecodeBase64(FConn);
            FEnable    := True;
            FNumWorker := NodeByName('WorkerNum').ValueAsInteger;
          end;
        end;
      end; //db

      nNode := nXML.Root.NodeByName('Param').NodeByName('SAPList');
      if Assigned(nNode) then
      begin
        for nIdx:=0 to nNode.NodeCount - 1 do
        begin
          New(nSAP);
          FItemSAP.Add(nSAP);
          nTmp := nNode.Nodes[nIdx];

          with nSAP^,nTmp do
          begin
            FID       := AttributeByName['ID'];
            FName     := AttributeByName['Name'];
            FHost     := NodeByName('Host').ValueAsString;
            FUser     := NodeByName('User').ValueAsString;
            FPwd      := NodeByName('Password').ValueAsString;
            FPwd      := DecodeBase64(FPwd);

            FSystem   := NodeByName('System').ValueAsString;
            FSysNum   := NodeByName('SysNum').ValueAsInteger;
            FClient   := NodeByName('Client').ValueAsString;
            FLang     := NodeByName('Lang').ValueAsString;
            FCodePage := NodeByName('CodePage').ValueAsString;
            FEnable   := True;
          end;
        end;
      end; //sap

      nNode := nXML.Root.NodeByName('Param').NodeByName('PerformList');
      if Assigned(nNode) then
      begin
        for nIdx:=0 to nNode.NodeCount - 1 do
        begin
          New(nPerform);
          FItemPerform.Add(nPerform);
          nTmp := nNode.Nodes[nIdx];

          with nPerform^,nTmp do
          begin
            FID               := AttributeByName['ID'];
            FName             := AttributeByName['Name'];
            FPortTCP          := NodeByName('PortTCP').ValueAsInteger;
            FPortHttp         := NodeByName('PortHttp').ValueAsInteger;
            FPoolSizeSAP      := NodeByName('PoolSizeSAP').ValueAsInteger;
            FPoolSizeConn     := NodeByName('PoolSizeConn').ValueAsInteger;
            FPoolSizeBusiness := NodeByName('PoolSizeBusiness').ValueAsInteger;

            FPoolBehaviorConn := NodeByName('PoolBehaviorConn').ValueAsInteger;
            FPoolBehaviorBusiness:= NodeByName('PoolBehaviorBus').ValueAsInteger;
            FMaxRecordCount   := NodeByName('MaxRecordCount').ValueAsInteger;
            FMonInterval      := NodeByName('MonInterval').ValueAsInteger;
            FEnable   := True;
          end;
        end;
      end; //perform

      nNode := nXML.Root.NodeByName('Packs');
      if Assigned(nNode) then
      begin
        for nIdx:=0 to nNode.NodeCount - 1 do
        begin
          New(nPack);
          FPacks.Add(nPack);
          nTmp := nNode.Nodes[nIdx];

          with nPack^,nTmp do
          begin
            FID          := AttributeByName['ID'];
            FName        := AttributeByName['Name'];
            FNameSAP     := NodeByName('SAP').ValueAsString;
            FSAP         := GetSAP(FNameSAP);
            FNameDB      := NodeByName('DB').ValueAsString;
            FDB          := GetDB(FNameDB);
            FNamePerform := NodeByName('Perform').ValueAsString;
            FPerform     := GetPerform(FNamePerform);
            FEnable      := True;
          end;
        end;
      end; //pack list

      nNode := nXML.Root.NodeByName('Param').NodeByName('URLRemote');
      if Assigned(nNode) then
      begin
        for nIdx:=0 to nNode.NodeCount - 1 do
        begin
          nStr := DecodeBase64(nNode[nIdx].ValueAsString);
          FURLRemote.Add(nStr);
        end;
      end; //remote url list

      nNode := nXML.Root.NodeByName('Param').NodeByName('URLLocal');
      if Assigned(nNode) then
      begin
        for nIdx:=0 to nNode.NodeCount - 1 do
        begin
          nStr := DecodeBase64(nNode[nIdx].ValueAsString);
          FURLLocal.Add(nStr);
        end;
      end; //local url list
    end else
    //--------------------------------------------------------------------------
    begin
      nXML.Root.Name := 'ParamPacks';
      nTmp := nXML.Root.NodeNew('Packs');

      for nIdx:=0 to FPacks.Count - 1 do
      begin
        nPack := FPacks[nIdx];
        if not nPack.FEnable then Continue;

        with nPack^,nTmp.NodeNew('Pack') do
        begin
          AttributeByName['ID'] := FID;
          AttributeByName['Name'] := FName;
          NodeNew('SAP').ValueAsString := FNameSAP;
          NodeNew('DB').ValueAsString  := FNameDB;
          NodeNew('Perform').ValueAsString := FNamePerform;
        end;
      end; //pack list

      nNode := nXML.Root.NodeNew('Param');
      nTmp := nNode.NodeNew('DBList');

      for nIdx:=0 to FItemDB.Count - 1 do
      begin
        nDB := FItemDB[nIdx];
        if not nDB.FEnable then Continue;

        with nDB^,nTmp.NodeNew('DB') do
        begin
          AttributeByName['ID'] := FID;
          AttributeByName['Name'] := FName;
          NodeNew('Host').ValueAsString := FHost;
          NodeNew('Port').ValueAsInteger := FPort;
          NodeNew('DBName').ValueAsString := FDB;
          NodeNew('User').ValueAsString := FUser;

          NodeNew('Password').ValueAsString := EncodeBase64(FPwd);
          NodeNew('ConnStr').ValueAsString := EncodeBase64(FConn);
          NodeNew('WorkerNum').ValueAsInteger := FNumWorker;
        end;
      end; //db list

      nTmp := nNode.NodeNew('SAPList');
      for nIdx:=0 to FItemSAP.Count - 1 do
      begin
        nSAP := FItemSAP[nIdx];
        if not nSAP.FEnable then Continue;

        with nSAP^,nTmp.NodeNew('SAP') do
        begin
          AttributeByName['ID'] := FID;
          AttributeByName['Name'] := FName;
          NodeNew('Host').ValueAsString := FHost;
          NodeNew('User').ValueAsString := FUser;
          NodeNew('Password').ValueAsString := EncodeBase64(FPwd);

          NodeNew('System').ValueAsString := FSystem;
          NodeNew('SysNum').ValueAsInteger := FSysNum;
          NodeNew('Client').ValueAsString := FClient;
          NodeNew('Lang').ValueAsString := FLang;
          NodeNew('CodePage').ValueAsString := FCodePage;
        end;
      end; //sap list

      nTmp := nNode.NodeNew('PerformList');
      for nIdx:=0 to FItemPerform.Count - 1 do
      begin
        nPerform := FItemPerform[nIdx];
        if not nPerform.FEnable then Continue;

        with nPerform^,nTmp.NodeNew('Perform') do
        begin
          AttributeByName['ID'] := FID;
          AttributeByName['Name'] := FName;
          NodeNew('PortTCP').ValueAsInteger := FPortTCP;
          NodeNew('PortHttp').ValueAsInteger := FPortHttp;
          NodeNew('PoolSizeSAP').ValueAsInteger := FPoolSizeSAP;
          NodeNew('PoolSizeConn').ValueAsInteger := FPoolSizeConn;
          NodeNew('PoolSizeBusiness').ValueAsInteger := FPoolSizeBusiness;

          NodeNew('PoolBehaviorConn').ValueAsInteger := Ord(FPoolBehaviorConn);
          NodeNew('PoolBehaviorBus').ValueAsInteger := Ord(FPoolBehaviorBusiness);
          NodeNew('MaxRecordCount').ValueAsInteger := FMaxRecordCount;
          NodeNew('MonInterval').ValueAsInteger := FMonInterval;
        end;
      end; //perform list

      nTmp := nNode.NodeNew('URLLocal');
      for nIdx:=0 to FURLLocal.Count - 1 do
        nTmp.NodeNew('URL').ValueAsString := EncodeBase64(FURLLocal[nIdx]);
      //xxxxx

      nTmp := nNode.NodeNew('URLRemote');
      for nIdx:=0 to FURLRemote.Count - 1 do
        nTmp.NodeNew('URL').ValueAsString := EncodeBase64(FURLRemote[nIdx]);
      //xxxxx

      nXML.VersionString := '1.0';
      nXML.EncodingString := 'gb2312';
      nXML.XmlFormat := xfReadable;
      
      nXML.SaveToFile(FFileName);
      FModified := False;
    end;
  finally
    nXML.Free;
  end;
end;

//------------------------------------------------------------------------------
//Date: 2012-3-5
//Parm: ������
//Desc: ��ʼ��nItem
procedure TParamManager.InitPack(var nItem: TParamItemPack);
begin
  with nItem do
  begin
    FNameSAP := '';
    FSAP := nil;
    FNameDB := '';
    FDB := nil;
    FNamePerform := '';
    FPerform := nil;
  end;
end;

//Date: 2012-3-3
//Parm: ������
//Desc: ���nItem��ϵͳ��
procedure TParamManager.AddPack(const nItem: TParamItemPack);
var nP: PParamItemPack;
begin
  nP := GetParamPack(nItem.FID);
  if not Assigned(nP) then
  begin
    New(nP);
    FPacks.Add(nP);
  end;

  nP^ := nItem;
  nP.FEnable := True;
  FModified := True;
end;

procedure TParamManager.DelPack(const nID: string);
var nP: PParamItemPack;
begin
  nP := GetParamPack(nID);
  if Assigned(nP) then
  begin
    nP.FEnable := False;
    FModified := True;
  end;
end;

//------------------------------------------------------------------------------
//Date: 2012-3-3
//Parm: ��ʶ
//Desc: ��ȡ��ʶΪnID�����ܲ���
function TParamManager.GetPerform(const nID: string): PPerformParam;
var nIdx: Integer;
    nP: PPerformParam;
begin
  Result := nil;

  for nIdx:=FItemPerform.Count - 1 downto 0 do
  begin
    nP := FItemPerform[nIdx];
    if nP.FEnable and (CompareText(nID, nP.FID) = 0) then
    begin
      Result := nP;
      Break;
    end;
  end;
end;

//Date: 2012-3-5
//Parm: ����
//Desc: ��ʼ��nItem����
procedure TParamManager.InitPerform(var nParam: TPerformParam);
begin
  with nParam do
  begin
    FPortTCP := 8081;
    FPortHttp := 8082;

    FPoolSizeSAP := 1;
    FPoolSizeConn := 10;
    FPoolSizeBusiness := 20;

    FPoolBehaviorConn := 1; //pbWait
    FPoolBehaviorBusiness := 2; //pbCreateAdditional

    FMaxRecordCount := 1000;
    FMonInterval := 2000;
  end;
end;

//Date: 2012-3-3
//Parm: ����
//Desc: ���nItem����
procedure TParamManager.AddPerform(const nParam: TPerformParam);
var nP: PPerformParam;
begin
  nP := GetPerform(nParam.FID);
  if not Assigned(nP) then
  begin
    New(nP);
    FItemPerform.Add(nP);
  end;

  nP^ := nParam;
  nP.FEnable := True;
  FModified := True;
end;

//Date: 2012-3-3
//Parm: ��ʶ
//Desc: ɾ����ʶΪnID�����ܲ���
procedure TParamManager.DelPerform(const nID: string);
var nP: PPerformParam;
begin
  nP := GetPerform(nID);
  if Assigned(nP) then
  begin
    nP.FEnable := False;
    FModified := True;
  end;
end;

//------------------------------------------------------------------------------
//Date: 2012-3-3
//Parm: ��ʶ
//Desc: ��ȡ��ʶΪnID�Ĳ�����
function TParamManager.GetSAP(const nID: string): PSAPParam;
var nIdx: Integer;
    nP: PSAPParam;
begin
  Result := nil;

  for nIdx:=FItemSAP.Count - 1 downto 0 do
  begin
    nP := FItemSAP[nIdx];
    if nP.FEnable and (CompareText(nID, nP.FID) = 0) then
    begin
      Result := nP;
      Break;
    end;
  end;
end;

//Date: 2012-3-5
//Parm: ����
//Desc: ��ʼ��nParam����
procedure TParamManager.InitSAP(var nParam: TSAPParam);
begin
  with nParam do
  begin
    FHost := '127.0.0.1';
    FUser := 'UserName';
    FPwd  := '';

    FSystem   := 'SYS';
    FSysNum   := 09;
    FClient   := '120';
    FLang     := 'ZH';
    FCodePage := '8400';
  end;
end;

//Date: 2012-3-3
//Parm: ����
//Desc: ���SAP����
procedure TParamManager.AddSAP(const nParam: TSAPParam);
var nP: PSAPParam;
begin
  nP := GetSAP(nParam.FID);
  if not Assigned(nP) then
  begin
    New(nP);
    FItemSAP.Add(nP);
  end;

  nP^ := nParam;
  nP.FEnable := True;
  FModified := True;
end;

//Date: 2012-3-3
//Parm: ��ʶ
//Desc: ɾ����ʶΪnID��SAP����
procedure TParamManager.DelSAP(const nID: string);
var nP: PSAPParam;
begin
  nP := GetSAP(nID);
  if Assigned(nP) then
  begin
    nP.FEnable := False;
    FModified := True;
  end;
end;

//------------------------------------------------------------------------------
//Date: 2012-3-3
//Parm: ��ʶ
//Desc: ��ȡ��ʶΪnID��DB����
function TParamManager.GetDB(const nID: string): PDBParam;
var nIdx: Integer;
    nP: PDBParam;
begin
  Result := nil;

  for nIdx:=FItemDB.Count - 1 downto 0 do
  begin
    nP := FItemDB[nIdx];
    if nP.FEnable and (CompareText(nID, nP.FID) = 0) then
    begin
      Result := nP;
      Break;
    end;
  end;
end;

//Date: 2012-3-5
//Parm: ����
//Desc: ��ʼ��nParam����
procedure TParamManager.InitDB(var nParam: TDBParam);
begin
  with nParam do
  begin
    FHost := '127.0.0.1';
    FPort := 1433;
    FDB   := 'DBName';
    FUser := 'sa';
    FPwd  := '';
    FConn := 'Provider=SQLOLEDB.1;Password=$Pwd;Persist Security Info=True;' +
             'User ID=$User;Initial Catalog=$DBName;Data Source=$Host';
    FNumWorker := 20;
  end;
end;

//Date: 2012-3-3
//Parm: ����
//Desc: ������ݿ����
procedure TParamManager.AddDB(const nParam: TDBParam);
var nP: PDBParam;
begin
  nP := GetDB(nParam.FID);
  if not Assigned(nP) then
  begin
    New(nP);
    FItemDB.Add(nP);
  end;

  nP^ := nParam;
  nP.FEnable := True;
  FModified := True;
end;

//Date: 2012-3-3
//Parm: ��ʶ
//Desc: ɾ����ʶΪnID�����ݿ���
procedure TParamManager.DelDB(const nID: string);
var nP: PDBParam;
begin
  nP := GetDB(nID);
  if Assigned(nP) then
  begin
    nP.FEnable := False;
    FModified := True;
  end;
end;

//------------------------------------------------------------------------------
//Date: 2012-3-3
//Parm: �б�;����
//Desc: ��ȡnType���͵Ĳ������б�
function TParamManager.LoadParam(const nList: TStrings;
  nType: TParamType): Boolean;
var nIdx: Integer;
begin
  nList.Clear;

  case nType of
   ptPack:
    begin
      for nIdx:=0 to FPacks.Count - 1 do
       if PParamItemPack(FPacks[nIdx]).FEnable then
        nList.Add(PParamItemPack(FPacks[nIdx]).FID);
    end;
   ptSAP:
    begin
      for nIdx:=0 to FItemSAP.Count - 1 do
       if PSAPParam(FItemSAP[nIdx]).FEnable then
        nList.Add(PSAPParam(FItemSAP[nIdx]).FID);
    end;
   ptDB:
    begin
      for nIdx:=0 to FItemDB.Count - 1 do
       if PDBParam(FItemDB[nIdx]).FEnable then
        nList.Add(PDBParam(FItemDB[nIdx]).FID);
    end;
   ptPerform:
    begin
      for nIdx:=0 to FItemPerform.Count - 1 do
       if PPerformParam(FItemPerform[nIdx]).FEnable then
        nList.Add(PPerformParam(FItemPerform[nIdx]).FID);
    end;
  end;

  Result := nList.Count > 0;
end;

//Date: 2012-3-3
//Parm: ������ʶ;�Ƿ񼤻�
//Desc: ��ȡ��ʶΪnID�Ĳ�����
function TParamManager.GetParamPack(const nID: string;
  const nActive: Boolean): PParamItemPack;
var nIdx: Integer;
    nP: PParamItemPack;
begin
  Result := nil;

  for nIdx:=FPacks.Count - 1 downto 0 do
  begin
    nP := FPacks[nIdx];
    if nP.FEnable and (CompareText(nID, nP.FID) = 0) then
    begin
      Result := nP;
      Break;
    end;
  end;

  if nActive then
  begin
    FActive := Result;
    if Assigned(Result) then
      FActiveName := FActive.FID;
    //xxxxx
  end;
end;

initialization
  gParamManager := nil;
finalization
  FreeAndNil(gParamManager);
end.
