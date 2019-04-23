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
  ULibFun, USysDB, UMITConst, UMgrChannel, UWorkerBusiness, UObjectList,
  IdGlobal, IdStream, IdHTTP, IdMultipartFormData, UWXMessager, ZnMD5;

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
    function RemoteSQLQuery(var nData: string): Boolean;
    {*远程查询*}
    function SQLExecute(var nData: string): Boolean;
    {*远程写入*}
    function GetCustomers(var nData: string): Boolean;
    function GetCustomersByID(var nData: string): Boolean;
    {*已注册用户*}
    function ForMakeZhiKa(var nData: string): Boolean;
    function MakeZhiKa(var nData: string): Boolean;
    {*办理纸卡*}
    function ChangeZhiKaPwd(var nData: string): Boolean;
    {*修改密码*}
    function BindAccount(var nData: string): Boolean;
    function UnbindAccount(var nData: string): Boolean;
    {*绑定解绑*}
    function SendWXMessage(var nData: string): Boolean;
    {*发送消息*}
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
var nStr: string;
    nIdx: Integer;
    nNode: TXmlNode;
begin
  with FPacker.XMLBuilder do
  begin
    Result := True;
    {$IFDEF DEBUG}WriteLog('WX Recv-Base64:' + nData);{$ENDIF}
    nData := UTF8Decode( DecodeBase64(nData) );
    {$IFDEF DEBUG}WriteLog('WX Recv:' + nData);{$ENDIF}

    ReadFromString(nData);
    nNode := Root.NodeByNameR('head');
    FIn.FCommand := StrToInt('$' + nNode.NodeByNameR('Command').ValueAsString);
    FIn.FData := nNode.NodeByNameR('Data').ValueAsString;

    nNode := nNode.NodeByName('ExtParam');
    if Assigned(nNode) then
         FIn.FExtParam := nNode.ValueAsString
    else FIn.FExtParam := '';

    if FIn.FCommand = cBC_WX_SQLExecute then //验证加密信息
    begin
      if Length(FIn.FExtParam) < 32 then
      begin
        nData := '验证信息无效';
        Result := False;
        Exit;
      end;

      nIdx := 0;
      while nIdx < 3 do
      begin
        case nIdx of
         0: nStr := Date2Str(Date());     //今天
         1: nStr := Date2Str(Date() + 1); //明天
         2: nStr := Date2Str(Date() - 1); //昨天
        end;

        Inc(nIdx);
        nStr := StringReplace(nData, FIn.FExtParam, nStr + '_WXService', []);
        nStr := MD5Print(MD5String(nStr));

        WriteLog(nStr + ' ' + FIn.FExtParam);
        if nStr = FIn.FExtParam then Exit;
        //通过验证
      end;

      Result := False;
      nData := '信息验证失败,操作已取消';
    end;
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
var nStr: string;
    nWorker: TBusinessWorkerBase;
begin
  nWorker := nil;
  try
    nWorker := gBusinessWorkerManager.LockWorker(FunctionName);
    nResult := '<xml><head><command>%s</command><data>%s</data>' +
               '<ExtParam>%s</ExtParam></head></xml>';
    //xxxxx

    if nCmd = cBC_WX_SQLExecute then
         nStr := Date2Str(Date()) + '_WXService'
    else nStr := EscapeString(nExt);
    nResult := Format(nResult, [IntToHex(nCmd, 2), EscapeString(nData), nStr]);

    if nCmd = cBC_WX_SQLExecute then
      nResult := StringReplace(nResult, nStr, MD5Print(MD5String(nResult)), []);
    //xxxxx

    {$IFDEF DEBUG}
    nResult := nData;
    {$ELSE}
    nResult := EncodeBase64(UTF8Encode(nResult));
    {$ENDIF}
    Result := nWorker.WorkActive(nResult);
  finally
    gBusinessWorkerManager.RelaseWorker(nWorker);
  end;
end;

//------------------------------------------------------------------------------
type
  TIdFormDataStream = class(TIdMultiPartFormDataStream)
  protected
    function IdRead(var VBuffer: TIdBytes; AOffset,
     ACount: Longint): Longint; override;
  end;

function TIdFormDataStream.IdRead(var VBuffer: TIdBytes;
 AOffset, ACount: Longint): Longint;
var
  LTotalRead: Integer;
  LCount: Integer;
  LBufferCount: Integer;
  LRemaining : Integer;
  LItem: TIdFormDataField;
begin
  if not FInitialized then begin
    FInitialized := True;
    FCurrentItem := 0;
    SetLength(FInternalBuffer, 0);
  end;

  LTotalRead := 0;
  LBufferCount := 0;

  while (LTotalRead < ACount) and ((FCurrentItem < FFields.Count) or
   (Length(FInternalBuffer) > 0)) do begin
    if (Length(FInternalBuffer) = 0) and not Assigned(FInputStream) then begin
      LItem := FFields.Items[FCurrentItem];
      AppendString(FInternalBuffer, LItem.FormatField, -1, TIdTextEncoding.UTF8);

      if Assigned(LItem.FieldObject) then begin
        if (LItem.FieldObject is TStream) then begin
          FInputStream := TStream(LItem.FieldObject);
          FInputStream.Position := 0;
        end else begin
          if (LItem.FieldObject is TStrings) then begin
            AppendString(FInternalBuffer, TStrings(LItem.FieldObject).Text,
              -1, TIdTextEncoding.UTF8);
            Inc(FCurrentItem);
          end;
        end;
      end else begin
        Inc(FCurrentItem);
      end;
    end;

    if Length(FInternalBuffer) > 0 then begin
      if Length(FInternalBuffer) > (ACount - LBufferCount) then begin
        LCount := ACount - LBufferCount;
      end else begin
        LCount := Length(FInternalBuffer);
      end;

      if LCount > 0 then begin
        LRemaining := Length(FInternalBuffer) - LCount;
        CopyTIdBytes(FInternalBuffer, 0, VBuffer, LBufferCount, LCount);
        if LRemaining > 0 then begin
          CopyTIdBytes(FInternalBuffer, LCount, FInternalBuffer, 0, LRemaining);
        end;
        SetLength(FInternalBuffer, LRemaining);
        LBufferCount := LBufferCount + LCount;
        FPosition := FPosition + LCount;
        LTotalRead := LTotalRead + LCount;
      end;
    end;

    if Assigned(FInputStream) and (LTotalRead < ACount) then begin
      LCount := TIdStreamHelper.ReadBytes(FInputStream,VBuffer,
        ACount - LTotalRead, LBufferCount);
      if LCount < (ACount - LTotalRead) then begin
        FInputStream.Position := 0;
        FInputStream := nil;
        Inc(FCurrentItem);
        SetLength(FInternalBuffer, 0);
        AppendString(FInternalBuffer, #13#10);
      end;

      LBufferCount := LBufferCount + LCount;
      LTotalRead := LTotalRead + LCount;
      FPosition := FPosition + LCount;
    end;

    if FCurrentItem = FFields.Count then begin
      AppendString(FInternalBuffer, PrepareStreamForDispatch,
        -1, TIdTextEncoding.UTF8);
      Inc(FCurrentItem);
    end;
  end;
  Result := LTotalRead;
end;

//Date: 2015-03-03
//Desc: 创建对象
function NewPool(const nClass: TClass): TObject;
begin
  Result := nil;
  if nClass = TIdHTTP then Result := TIdHTTP.Create(nil);
end;

//Date: 2015-03-03
//Desc: 释放对象
procedure FreePool(const nObject: TObject);
begin
  if nObject is TIdHTTP then TIdHTTP(nObject).Free;
end;

//Date: 2019-04-09
//Parm: 函数;数据
//Desc: 调用远程nAPI执行业务
class function TBusWorkerBusinessWechat.CallRemote(const nAPI,
 nData: string; var nResult: string): Boolean;
var nChannel: TIdHTTP;
    nPChannel: PObjectPoolItem;
    nStream: TIdFormDataStream;
begin
  nStream := nil;
  nPChannel := nil;
  try
    if InterlockedExchange(gWXURLInited, 10) < 1 then
    begin
      gObjectPoolManager.RegClass(TIdHTTP, NewPool, FreePool);
    end; //reg pool

    nPChannel := gObjectPoolManager.LockObject(TIdHTTP);
    nChannel := nPChannel.FObject as TIdHTTP;

    nStream := TIdFormDataStream.Create;
    nStream.AddFormField('requestParameters', EncodeBase64(nData));
    nResult := nChannel.Post(gSysParam.FWXServiceURL + nAPI, nStream);
    Result := True;
  except
    on nErr: Exception do
    begin
      Result := False;
      nResult := nErr.Message;
    end;
  end;

  nStream.Free;
  gObjectPoolManager.ReleaseObject(nPChannel);
end;

//------------------------------------------------------------------------------
//Date: 2019-04-09
//Parm: 输入数据
//Desc: 执行nData业务指令
function TBusWorkerBusinessWechat.DoDBWork(var nData: string): Boolean;
begin
  Result := False;
  try
    try
      Result := ParseRemoteIn(nData); //解析输入
      if not Result then Exit;
      BuildDefaultXML('0', 'ok');     //初始化输出

      case FIn.FCommand of
       cBC_WX_SQLQuery        : Result := SQLQuery(nData);
       cBC_WX_SQLExecute      : Result := SQLExecute(nData);
       cBC_WX_GetCustomers    : Result := GetCustomers(nData);
       cBC_WX_ForMakeZhiKa    : Result := ForMakeZhiKa(nData);
       cBC_WX_MakeZhiKa       : Result := MakeZhiKa(nData);
       cBC_WX_ChangeZhiKaPwd  : Result := ChangeZhiKaPwd(nData);
       cBC_WX_BindAccount     : Result := BindAccount(nData);
       cBC_WX_UnbindAccount   : Result := UnbindAccount(nData);
       cBC_WX_SendWXMessage   : Result := SendWXMessage(nData)
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
  finally
    if not Result then
    begin
      WriteLog(nData);
      BuildDefaultXML(IntToStr(FIn.FCommand), nData);
    end;

    nData := #10#13 + FPacker.XMLBuilder.WriteToString;
    //远程结果
  end;
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
  WriteLog('RemoteQuery:' + FIn.FData);
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

//Date: 2019-04-16
//Parm: SQL语句
//Desc: 在远程执行SQL查询
function TBusWorkerBusinessWechat.RemoteSQLQuery(var nData: string): Boolean;
begin
  nData := Format('<?xml version="1.0" encoding="UTF-8"?>' +
    '<xml><head><methodComand>ZX1005</methodComand></head>' +
    '<data><querySql>%s</querySql></data></xml>', [EscapeString(nData)]);
  //xxxxx

  Result := CallRemote('provideInterface', nData, nData);
  if not Result then Exit;

  Result := ParseRemoteOut(nData);
  if not Result then Exit;
end;

//Date: 2019-04-13
//Parm: SQL语句[FIn.FParam];加密结果[FIn.FExtParam]
//Desc: 验证加密是否有效,然后执行远程发送的写操作.
function TBusWorkerBusinessWechat.SQLExecute(var nData: string): Boolean;
const
  cGood: array[0..2] of string = ('insert', 'update', 'delete');
var nStr: string;
    nIdx: Integer;
    nBool: Boolean;
begin
  Result := False;
  WriteLog('RemoteQuery:' + FIn.FData);
  FIn.FData := TrimLeft(FIn.FData);

  nIdx := Pos(' ', FIn.FData);
  if nIdx < 2 then
  begin
    nData := '无效的查询语句';
    Exit;
  end;

  nStr := Copy(FIn.FData, 1, nIdx - 1);
  nStr := LowerCase(nStr);
  nBool := False;
  
  for nIdx:=Low(cGood) to High(cGood) do
  if cGood[nIdx] = nStr then
  begin
    nBool := True;
    Break;
  end;

  if not nBool then
  begin
    nData := '权限不足';
    Exit;
  end;

  nIdx := gDBConnManager.WorkerExec(FDBConn, FIn.FData);
  Result := True;

  with FPacker.XMLBuilder.Root.NodeNew('Result') do
  begin
    NodeNew('Rows').ValueAsInteger := nIdx;
    NodeNew('SQL').ValueAsString := FIn.FData;
  end;
end;

//Date: 2019-04-11
//Parm: 无
//Desc: 获取本厂已注册的微信用户
function TBusWorkerBusinessWechat.GetCustomers(var nData: string): Boolean;
begin
  nData := 'SELECT IC.real_name,IC.phone,IC.serial_no FROM info_customer IC ' +
    ' LEFT JOIN info_factory IFC ON IC.factory_id = IFC.factory_id ' +
    'WHERE IFC.factory_unique_code=''%s'' AND IC.status=1 AND IFC.status=1';
  //xxxxx
  
  nData := Format(nData, [gSysParam.FWXFactoryID]);
  Result := RemoteSQLQuery(nData);
end;

//Date: 2019-04-18
//Parm: 无
//Desc: 获取本厂已注册的微信用户
function TBusWorkerBusinessWechat.GetCustomersByID(var nData: string): Boolean;
begin
  nData := '<?xml version="1.0" encoding="UTF-8"?><xml>' +
    '<head><methodComand>ZX1001</methodComand></head><data>' +
    '<factoryUniqueCode>%s</factoryUniqueCode></data></xml>';
  nData := Format(nData, [gSysParam.FWXFactoryID]);

  Result := CallRemote('provideInterface', nData, nData);
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

//Date: 2019-04-18
//Parm: 创单数据[FIn.FData]
//Desc: 创建新纸卡
function TBusWorkerBusinessWechat.MakeZhiKa(var nData: string): Boolean;
var nStr,nCID,nSMan,nZID,nPwd: string;
    nIdx: Integer;
    nVal: Double;
    nNode: TXmlNode;
    nOut: TWorkerBusinessCommand;
begin
  with FPacker.XMLBuilder do
  begin
    Result := False;
    ReadFromString(FIn.FData);
    
    nNode := Root.NodeByNameR('head');
    nCID := nNode.NodeByNameR('clientNo').ValueAsString;
    nStr := nNode.NodeByNameR('unlimitedAmount').ValueAsString;

    if CompareText(nStr, 'yes') <> 0 then //纸卡限额
    begin
      nVal := nNode.NodeByNameR('paperCardAmount').ValueAsFloat;
      nVal := Float2Float(nVal, cPrecision, True);
      if nVal <= 0 then
      begin
        nData := '纸卡金额无效';
        Exit;
      end;   

      if not TWorkerBusinessCommander.CallMe(cBC_GetCustomerMoney, nCID,
        sFlag_Yes, @nOut) then  //get customer valid money,include credit
      begin
        nData := nOut.FData;
        Exit;
      end;

      if FloatRelation(nVal, StrToFloat(nOut.FData), rtGreater) then
      begin
        nData := '客户资金余额不足';
        Exit;
      end;
    end;

    nStr := 'Select C_SaleMan From %s Where C_ID=''%s''';
    nStr := Format(nStr, [sTable_Customer, nCID]);
    with gDBConnManager.WorkerQuery(FDBConn, nStr) do
    begin
      if RecordCount < 1 then
      begin
        nData := '客户信息已丢失';
        Exit;
      end;

      nSMan := FieldByName('C_SaleMan').AsString;
    end;

    nNode := Root.NodeByNameR('Items');
    if nNode.NodeCount > 0 then //纸卡明细
    begin
      nStr := 'Select D_Memo,D_ParamB From %s Where D_Name=''%s''';
      nStr := Format(nStr, [sTable_SysDict, sFlag_StockItem]);
      with gDBConnManager.WorkerQuery(FDBConn, nStr) do
      begin
        if RecordCount < 1 then
        begin
          nData := '基础物料信息丢失';
          Exit;
        end;
          
        for nIdx:=nNode.NodeCount-1 downto 0 do
        with nNode.Nodes[nIdx] do
        begin
          nStr := NodeByNameR('materialNo').ValueAsString;
          First;

          while not Eof do
          begin
            if FieldByName('D_ParamB').AsString = nStr then //物料号匹配
            begin
              NodeNew('materialType').ValueAsString := FieldByName('D_Memo').AsString;
              Break;
            end;
            
            Next;
          end;
        end;
      end;
    end;

    with FListC do
    begin
      Clear;
      Values['Group'] := sFlag_BusGroup;
      Values['Object'] := sFlag_ZhiKa;
    end;

    Result := TWorkerBusinessCommander.CallMe(cBC_GetSerialNO, FListC.Text,
      sFlag_No, @nOut);
    //new zhika id
    if not Result then 
    begin
      nData := nOut.FData;
      Exit;
    end else nZID := nOut.FData;

    Result := TWorkerBusinessCommander.CallMe(cBC_MakeZhiKaPassword, '', '', @nOut);
    if not Result then //new zhika password
    begin
      nData := nOut.FData;
      Exit;
    end else nPwd := nOut.FData;

    //--------------------------------------------------------------------------
    with Root.NodeByNameR('head') do
    nStr := MakeSQLByStr([
      SF('Z_Name', Trim(NodeByNameR('cardName').ValueAsString)),
      SF('Z_Project', Trim(NodeByNameR('entryName').ValueAsString)),
      SF('Z_Lading', sFlag_TiHuo),
      SF('Z_InValid', sFlag_No),
      SF('Z_ValidDays', NodeByNameR('termOfValidity').ValueAsString),
      SF('Z_Password', nOut.FData),
      SF('Z_Money', NodeByNameR('paperCardAmount').ValueAsString, sfVal),
     
      SF('Z_ID', nZID),
      SF('Z_Customer', nCID),
      SF('Z_SaleMan', nSMan),
      SF('Z_MoneyUsed', 0, sfVal),
      SF('Z_Freeze', sFlag_No),
      SF('Z_Man', '微信办理'),
      SF('Z_Date', sField_SQLServer_Now, sfVal),

      SF_IF([SF('Z_MoneyAll', sFlag_Yes), SF('Z_MoneyAll', sFlag_No)],
        CompareText(NodeByNameR('unlimitedAmount').ValueAsString, 'yes') = 0),
      //all money
      SF('Z_Verified', sFlag_Yes)
      ], sTable_ZhiKa, '', True);
    FListA.Text := nStr;

    nNode := Root.NodeByNameR('Items');
    for nIdx:=nNode.NodeCount-1 downto 0 do
    with nNode.Nodes[nIdx] do
    begin
      nStr := MakeSQLByStr([SF('D_ZID', nZID),
              SF('D_Type', NodeByNameR('materialType').ValueAsString),
              SF('D_StockNo', NodeByNameR('materialNo').ValueAsString),
              SF('D_StockName', NodeByNameR('materialName').ValueAsString),
              SF('D_Price', 0, sfVal),
              SF('D_Value', 0, sfVal),
              SF('D_FLPrice', 0, sfVal),
              SF('D_YunFei', 0, sfVal),
              SF('D_PPrice', 0, sfVal),
              SF('D_TPrice', sFlag_Yes)
              ], sTable_ZhiKaDtl, '', True);
      FListA.Add(nStr);
    end;

    FDBConn.FConn.BeginTrans;
    try
      for nIdx:=0 to FListA.Count-1 do
        gDBConnManager.WorkerExec(FDBConn, FListA[nIdx]);
      FDBConn.FConn.CommitTrans;

      Result := True;
      BuildDefaultXML('0', 'ok');
      Root.NodeNew('ZhiKa').ValueAsString := nZID;
    except
      FDBConn.FConn.RollbackTrans;
      raise;
    end;  
  end;
end;

//Date: 2019-04-18
//Parm: 纸卡号[FIn.FData]
//Desc: 修改纸卡密码,返回新密码
function TBusWorkerBusinessWechat.ChangeZhiKaPwd(var nData: string): Boolean;
var nStr: string;
    nOut: TWorkerBusinessCommand;
begin
  Result := TWorkerBusinessCommander.CallMe(cBC_MakeZhiKaPassword, '', '', @nOut);
  if not Result then
  begin
    nData := nOut.FData;
    Exit;
  end;

  nStr := 'Select Count(*) From %s Where Z_ID=''%s''';
  nStr := Format(nStr, [sTable_ZhiKa, FIn.FData]);

  with gDBConnManager.WorkerQuery(FDBConn, nStr) do
  if Fields[0].AsInteger <> 1 then
  begin
    Result := False;
    nData := '单据号无效';
    Exit;
  end;

  nStr := 'Update %s Set Z_Password=''%s'' Where Z_ID=''%s''';
  nStr := Format(nStr, [sTable_ZhiKa, nOut.FData, FIn.FData]);
  gDBConnManager.WorkerExec(FDBConn, nStr);

  with FPacker.XMLBuilder.Root do
  begin
    NodeNew('NewPassword').ValueAsString := nOut.FData;
  end;
end;

//Date: 2019-04-18
//Desc: 绑定商城账户
function TBusWorkerBusinessWechat.BindAccount(var nData: string): Boolean;
begin
  nData := '<?xml version="1.0" encoding="UTF-8"?>' +
    '<xml><head><methodComand>ZX1002</methodComand></head><data>' +
    '<clientNo>$CusID</clientNo><clientName>$CusName</clientName>' +
    '<factoryUniqueCode>$Code</factoryUniqueCode>' +
    '<serialNo>$No</serialNo><type>$Type</type></data></xml>';
  //xxxxx

  FListA.Text := DecodeBase64(FIn.FData);
  nData := MacroValue(nData, [MI('$CusID', FListA.Values['CusID']),
    MI('$CusName', EscapeString(FListA.Values['CusName'])),
    MI('$Code', gSysParam.FWXFactoryID),
    MI('$Type', FListA.Values['Type']),
    MI('$No', FListA.Values['SerialNo'])]);
  //xxxxx

  Result := CallRemote('provideInterface', nData, nData);
  if not Result then Exit;

  Result := ParseRemoteOut(nData);
  if not Result then Exit;

  nData := 'Update %s Set C_Phone=''%s'',C_WeiXin=''%s'',C_LiXiRen=''%s'' ' +
           'Where C_ID=''%s''';
  //xxxxx

  nData := Format(nData, [sTable_Customer, FListA.Values['Phone'],
    FListA.Values['SerialNo'], FListA.Values['RealName'],
    FListA.Values['CusID']]);
  gDBConnManager.WorkerExec(FDBConn, nData);
end;

//Date: 2019-04-18
//Desc: 解除商城绑定
function TBusWorkerBusinessWechat.UnbindAccount(var nData: string): Boolean;
begin
  nData := '<?xml version="1.0" encoding="UTF-8"?>' +
    '<xml><head><methodComand>ZX1003</methodComand></head><data>' +
    '<clientNo>$CusID</clientNo>' +
    '<factoryUniqueCode>$Code</factoryUniqueCode></data></xml>';
  //xxxxx

  FListA.Text := DecodeBase64(FIn.FData);
  nData := MacroValue(nData, [MI('$CusID', FListA.Values['CusID']),
    MI('$Code', gSysParam.FWXFactoryID)]);
  //xxxxx

  Result := CallRemote('provideInterface', nData, nData);
  if not Result then Exit;

  Result := ParseRemoteOut(nData);
  if not Result then Exit;

  nData := 'Update %s Set C_WeiXin='''' Where C_ID=''%s''';
  nData := Format(nData, [sTable_Customer, FListA.Values['CusID']]);
  gDBConnManager.WorkerExec(FDBConn, nData);
end;

//Date: 2019-04-18
//Desc: 推送微信消息
function TBusWorkerBusinessWechat.SendWXMessage(var nData: string): Boolean;
var nStr: string;
    nIdx: Integer;
begin
  if FIn.FExtParam = sFlag_Yes then //使用交货单号发送
  begin
    nStr := AdjustListStrFormat(FIn.FData, '''', True, ',');
    nData := 'Select Z_Name,C_WeiXin,L_ID,L_CusID,L_CusName,L_StockName,' +
      'L_Value,L_Truck,L_Status From %s ' +
      ' Left Join %s On Z_ID=L_ZhiKa ' +
      ' Left Join %s On C_ID=L_CusID ' +
      'Where L_ID In (%s)';
    nData := Format(nData, [sTable_Bill, sTable_ZhiKa, sTable_Customer, nStr]);

    with gDBConnManager.WorkerQuery(FDBConn, nData) do
    if RecordCount > 0 then
    begin
      FListB.Clear;
      FListC.Clear;
      First;

      while not Eof do
      begin
        with FListC do
        begin
          nStr := FieldByName('L_Status').AsString;
          if nStr = sFlag_TruckNone then nStr := '2' else
          if nStr = sFlag_TruckIn then nStr := '3' else
          if nStr = sFlag_TruckOut then nStr := '4' else
          begin
            Next;
            Continue;
          end;

          Values['SerialNo'] := FieldByName('C_WeiXin').AsString;
          Values['Key']      := nStr;
          Values['SName']    := FieldByName('L_StockName').AsString;
          Values['ZName']    := FieldByName('Z_Name').AsString;
          Values['Bill']     := FieldByName('L_ID').AsString;
          Values['Truck']    := FieldByName('L_Truck').AsString;
          Values['Value']    := FieldByName('L_Value').AsString;
          Values['CName']    := FieldByName('L_CusName').AsString;
          Values['CusID']    := FieldByName('L_CusID').AsString;

          FListB.Add(EncodeBase64(FListC.Text));
        end;

        Next;
      end;

      FIn.FExtParam := sFlag_No; //准备发送
      for nIdx:=FListB.Count-1 downto 0 do
      begin
        FIn.FData := FListB[nIdx];
        SendWXMessage(nData);
      end;
    end;

    Result := True;
    Exit;
  end;

  nData := '<?xml version="1.0" encoding="UTF-8"?>' +
    '<xml><head><methodComand>ZX1004</methodComand></head><data>' +
    '<serialNo>$No</serialNo><msgEventKey>$Key</msgEventKey>' +
    '<factoryUniqueCode>$Code</factoryUniqueCode>' +
    '<l_StockName>$SName</l_StockName><z_Name>$ZName</z_Name>' +
    '<l_Id>$Bill</l_Id><l_Truck>$Truck</l_Truck>' +
    '<l_value>$Value</l_value><c_Name>$CName</c_Name></data></xml>';
  //xxxxx

  FListA.Text := DecodeBase64(FIn.FData);
  nData := MacroValue(nData, [MI('$No', FListA.Values['SerialNo']),
    MI('$Key',    FListA.Values['Key']),
    MI('$SName',  EscapeString(FListA.Values['SName'])),
    MI('$ZName',  EscapeString(FListA.Values['ZName'])),
    MI('$Bill',   FListA.Values['Bill']),
    MI('$Truck',  EscapeString(FListA.Values['Truck'])),
    MI('$Value',  FListA.Values['Value']),
    MI('$CName',  EscapeString(FListA.Values['CName'])),
    MI('$Code', gSysParam.FWXFactoryID)]);
  //xxxxx

  nStr := Format('%s_%s', [FListA.Values['Bill'], FListA.Values['Key']]);
  nData := MakeSQLByStr([SF('L_UserID', FListA.Values['CusID']),
    SF('L_MsgID', nStr),
    SF('L_Count', 0, sfVal),
    SF('L_Status', sFlag_No),
    SF('L_Data', gDBConnManager.EncodeSQL(nData, True)),
    SF('L_Date', sField_SQLServer_Now, sfVal)
    ], sTable_WeixinLog, '', True);
  gDBConnManager.WorkerExec(FDBConn, nData);

  gWXMessager.SendNow();
  Result := True;
end;

initialization
  gBusinessWorkerManager.RegisteWorker(TBusWorkerBusinessWechat, sPlug_ModuleBus);
end.
