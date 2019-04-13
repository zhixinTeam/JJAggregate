{*******************************************************************************
  作者: dmzn@163.com 2019-04-04
  描述: 微信相关业务和数据处理
*******************************************************************************}
unit UWorkerBussinessWechat;

{$I Link.Inc}
interface

uses
  Windows, Classes, Controls, SysUtils, DB, ADODB, NativeXml, UBusinessWorker,
  UBusinessPacker, UBusinessConst, UMgrDBConn, UMgrParam, UFormCtrl, USysLoger,
  ULibFun, USysDB, UMITConst, UMgrChannel, UWorkerBusiness, UObjectList, IdHTTP;

type
  TBusWorkerBusinessWechat = class(TMITDBWorker)
  private
    FListA,FListB,FListC: TStrings;
    {*字符列表*}
    FIn: TWorkerBusinessCommand;
    FOut: TWorkerBusinessCommand;
    {*输入输出*}
  protected
    procedure GetInOutData(var nIn,nOut: PBWDataBase); override;
    function DoDBWork(var nData: string): Boolean; override;
    {*基类方法*}
    procedure BuildDefaultXML(const nCode,nMsg: string);
    {*初始化XML*}
    function ParseRemoteIn(var nData: string): Boolean;
    function ParseRemoteOut(var nData: string): Boolean;
    {*解析输入*}
    function SQLQuery(var nData: string): Boolean;
    {*远程查询*}
    function GetCustomers(var nData: string): Boolean;
    {*已注册用户*}
    function ForMakeZhiKa(var nData: string): Boolean;
    function MakeZhiKa(var nData: string): Boolean;
    {*办理纸卡*}
  public
    constructor Create; override;
    destructor destroy; override;
    {*创建释放*}
    function GetFlagStr(const nFlag: Integer): string; override;
    class function FunctionName: string; override;
    {*基类方法*}
    class function CallRemote(const nAPI,nData: string;
     var nResult: string): Boolean;
    {*远程调用*}
    class function CallMe(const nCmd: Integer; const nData,nExt: string;
      var nResult: string): Boolean;
    {*本地调用*}
  end;

implementation

var
  gWXURLInited: Integer = 0;
  //初始化标记

class function TBusWorkerBusinessWechat.FunctionName: string;
begin
  Result := sBus_BusinessWechat;
end;

constructor TBusWorkerBusinessWechat.Create;
begin
  FListA := TStringList.Create;
  FListB := TStringList.Create;
  FListC := TStringList.Create;
  inherited;
end;

destructor TBusWorkerBusinessWechat.destroy;
begin
  FreeAndNil(FListA);
  FreeAndNil(FListB);
  FreeAndNil(FListC);
  inherited;
end;

function TBusWorkerBusinessWechat.GetFlagStr(const nFlag: Integer): string;
begin
  Result := inherited GetFlagStr(nFlag);

  case nFlag of
   cWorker_GetPackerName : Result := sBus_BusinessCommand;
  end;
end;

procedure TBusWorkerBusinessWechat.GetInOutData(var nIn,nOut: PBWDataBase);
begin
  nIn := @FIn;
  nOut := @FOut;

  FDataInNeedUnPack := False;
  FDataOutNeedPack := False;
  FDataOutNeedUnPack := False;
end;

procedure TBusWorkerBusinessWechat.BuildDefaultXML(const nCode,nMsg: string);
begin
  with FPacker.XMLBuilder do
  begin
    Clear;
    VersionString := '1.0';
    EncodingString := 'utf-8';

    XmlFormat := xfReadable; //xfCompact;
    Root.Name := 'DATA';
    //first node

    with Root.NodeNew('head') do
    begin
      NodeNew('errcode').ValueAsString := nCode;
      NodeNew('errmsg').ValueAsString := nMsg;
    end;
  end;
end;

//Date: 2019-04-09
//Parm: 输入XML
//Desc: 解析输入数据
function TBusWorkerBusinessWechat.ParseRemoteIn(var nData: string): Boolean;
var nNode: TXmlNode;
begin
  with FPacker.XMLBuilder do
  begin
    Result := True;
    ReadFromString(nData);
    nNode := Root.NodeByNameR('head');

    FIn.FCommand := StrToInt('$' + nNode.NodeByNameR('Command').ValueAsString);
    FIn.FData := nNode.NodeByNameR('Data').ValueAsString;

    nNode := nNode.NodeByName('Param');
    if Assigned(nNode) then
         FIn.FExtParam := nNode.ValueAsString
    else FIn.FExtParam := '';
  end;
end;

//Date: 2019-04-09
//Parm: 输入XML
//Desc: 解析返回数据数据
function TBusWorkerBusinessWechat.ParseRemoteOut(var nData: string): Boolean;
var nNode: TXmlNode;
begin
  with FPacker.XMLBuilder do
  begin
    ReadFromString(nData);
    nNode := Root.NodeByNameR('head');

    Result := nNode.NodeByNameR('errcode').ValueAsString = '0';
    if not Result then
      nData := nNode.NodeByNameR('errmsg').ValueAsString;
    //xxxxx
  end;
end;

//Date: 2019-04-09
//Parm: 命令;数据;参数;输出
//Desc: 本地调用业务对象
class function TBusWorkerBusinessWechat.CallMe(const nCmd: Integer;
  const nData, nExt: string; var nResult: string): Boolean;
var nWorker: TBusinessWorkerBase;
begin
  nWorker := nil;
  try
    nWorker := gBusinessWorkerManager.LockWorker(FunctionName);
    nResult := '<xml><head><command>%s</command><data>%s</data>' +
               '<param>%s</param></head></xml>';
    //xxxxx
    
    nResult := Format(nResult, [IntToHex(nCmd, 2),
               EscapeString(nData), EscapeString(nExt)]);
    Result := nWorker.WorkActive(nResult);
  finally
    gBusinessWorkerManager.RelaseWorker(nWorker);
  end;
end;

//Date: 2015-03-03
//Desc: 创建对象
function NewPool(const nClass: TClass): TObject;
begin
  Result := nil;
  if nClass = TIdHTTP then Result := TIdHTTP.Create(nil) else
  if nClass = TStrings then Result := TStringList.Create() else
  if nClass = TStringStream then Result := TStringStream.Create('');
end;

//Date: 2015-03-03
//Desc: 释放对象
procedure FreePool(const nObject: TObject);
begin
  if nObject is TIdHTTP then TIdHTTP(nObject).Free else
  if nObject is TStringList then TStringList(nObject).Free else
  if nObject is TStringStream then TStringStream(nObject).Free;
end;

//Date: 2019-04-09
//Parm: 函数;数据
//Desc: 调用远程nAPI执行业务
class function TBusWorkerBusinessWechat.CallRemote(const nAPI,
 nData: string; var nResult: string): Boolean;
var nList: TStrings;
    nChannel: TIdHTTP;
    nStream: TStringStream;
    nPList,nPStream,nPChannel: PObjectPoolItem;
begin
  nPList := nil;
  nPStream := nil;
  nPChannel := nil;
  try
    if InterlockedExchange(gWXURLInited, 10) < 1 then
    begin
      gObjectPoolManager.RegClass(TIdHTTP, NewPool, FreePool);
      gObjectPoolManager.RegClass(TStrings, NewPool, FreePool);
      gObjectPoolManager.RegClass(TStringStream, NewPool, FreePool);
    end; //reg pool

    nPList := gObjectPoolManager.LockObject(TStrings);
    nPChannel := gObjectPoolManager.LockObject(TIdHTTP);
    nPStream := gObjectPoolManager.LockObject(TStringStream);

    nList := nPList.FObject as TStrings;
    nChannel := nPChannel.FObject as TIdHTTP;
    nStream := nPStream.FObject as TStringStream;
    
    nList.Text := nData;
    nStream.Size := 0;
    nChannel.Post(gSysParam.FWXServiceURL + nAPI, nList, nStream);

    nResult := nStream.DataString;
    Result := True;
  except
    on nErr: Exception do
    begin
      Result := False;
      nResult := nErr.Message;
    end;
  end;

  gObjectPoolManager.ReleaseObject(nPList);
  gObjectPoolManager.ReleaseObject(nPStream);
  gObjectPoolManager.ReleaseObject(nPChannel);
end;

//------------------------------------------------------------------------------
//Date: 2019-04-09
//Parm: 输入数据
//Desc: 执行nData业务指令
function TBusWorkerBusinessWechat.DoDBWork(var nData: string): Boolean;
begin
  try
    ParseRemoteIn(nData);
    //解析输入
    BuildDefaultXML('0', 'ok');
    //初始化输出

    case FIn.FCommand of
      cBC_WX_SQLQuery        : Result := SQLQuery(nData);
      cBC_WX_GetCustomers    : Result := GetCustomers(nData);
      cBC_WX_ForMakeZhiKa    : Result := ForMakeZhiKa(nData);
      cBC_WX_MakeZhiKa       : Result := MakeZhiKa(nData)
     else
      begin
        Result := False;
        nData := '无效的业务代码(Code: %d Invalid Command).';
        nData := Format(nData, [FIn.FCommand]);
      end;
    end;
  except
    on nErr: Exception do
    begin
      Result := False;
      nData := nErr.Message;
    end;
  end;

  if not Result then
    BuildDefaultXML(IntToStr(FIn.FCommand), nData);
  nData := #10#13 + FPacker.XMLBuilder.WriteToString; //远程结果
end;

//Date: 2019-04-04
//Parm: SQL语句[FIn.FParam]
//Desc: 执行远程发起的数据查询
function TBusWorkerBusinessWechat.SQLQuery(var nData: string): Boolean;
const
  cBad: array[0..7] of string = ('create', 'insert', 'update', 'delete',
    'drop', 'alter', 'into', 'sys_user');
var nStr: string;
    nBool: Boolean;
    nIdx,nInt: Integer;
    nNode,nTmp: TXmlNode;
begin
  Result := False;
  nBool := True;
  SplitStr(FIn.FData, FListA, 0, #32);

  for nIdx:=0 to FListA.Count - 1 do
  begin
    if nBool then
    begin
      nStr := Trim(FListA[nIdx]);
      if nStr <> '' then
      begin
        if CompareText(nStr, 'select') <> 0 then
        begin
          nData := '无效的查询语句';
          Exit;
        end;

        nBool := False;
      end;
    end else
    begin
      nStr := LowerCase(Trim(FListA[nIdx]));
      for nInt:=Low(cBad) to High(cBad) do
       if cBad[nInt] = nStr then
       begin
         nData := '权限不足';
         Exit;
       end;
    end;
  end;

  with gDBConnManager.WorkerQuery(FDBConn, FIn.FData),FPacker.XMLBuilder do
  begin
    if RecordCount < 1 then
    begin
      nData := '未查询到数据';
      Exit;
    end;

    Result := True;
    nNode := Root.NodeNew('items');
    nInt := FieldCount - 1;
    
    First;
    while not Eof do
    begin
      nTmp := nNode.NodeNew('item');
      for nIdx:=0 to nInt do
        nTmp.NodeNew(Fields[nIdx].FieldName).ValueAsString := Fields[nIdx].AsString;
      Next;
    end;
  end;
end;

//Date: 2019-04-11
//Parm: 无
//Desc: 获取本厂已注册的微信用户
function TBusWorkerBusinessWechat.GetCustomers(var nData: string): Boolean;
begin
  nData := 'sql=SELECT IC.real_name,IC.phone,IC.serial_no FROM info_customer IC ' +
    'LEFT JOIN info_factory IFC ON IC.factory_id = IFC.factory_id ' +
    'WHERE IFC.factory_unique_code=''%s'' AND IC.status=1 AND IFC.status=1';
  nData := Format(nData, [gSysParam.FWXFactoryID]);

  Result := CallRemote('apiQuerySql', nData, nData);
  if not Result then Exit;

  Result := ParseRemoteOut(nData);
  if not Result then Exit;
end;

//Date: 2019-04-12
//Parm: 客户号
//Desc: 获取指定客户办理纸卡前的准备数据
function TBusWorkerBusinessWechat.ForMakeZhiKa(var nData: string): Boolean;
var nStr: string;
    nNode: TXmlNode;
    nOut: TWorkerBusinessCommand;
begin
  Result := TWorkerBusinessCommander.CallMe(cBC_GetCustomerMoney, FIn.FData,
    sFlag_Yes, @nOut);
  //customer money

  if not Result then
  begin
    nData := nOut.FData;
    Exit;
  end;

  with FPacker.XMLBuilder.Root do
  begin
    NodeNew('ValidMoney').ValueAsFloat := StrToFloat(nOut.FData);
    nNode := NodeNew('StockItems');
  end;

  nStr := 'Select D_ParamB,D_Value From %s Where D_Name=''%s''';
  nStr := Format(nStr, [sTable_SysDict, sFlag_StockItem]);

  with gDBConnManager.WorkerQuery(FDBConn, nStr) do
  if RecordCount > 0 then
  begin
    First;
    while not Eof do
    begin
      with nNode.NodeNew('Item') do
      begin
        NodeNew('ID').ValueAsString := Fields[0].AsString;
        NodeNew('Name').ValueAsString := Fields[1].AsString;
      end;

      Next;
    end;
  end;
end;

function TBusWorkerBusinessWechat.MakeZhiKa(var nData: string): Boolean;
begin

end;

initialization
  gBusinessWorkerManager.RegisteWorker(TBusWorkerBusinessWechat, sPlug_ModuleBus);
end.
