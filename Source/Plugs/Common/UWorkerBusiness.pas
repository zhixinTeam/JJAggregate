{*******************************************************************************
  作者: dmzn@163.com 2013-12-04
  描述: 模块业务对象
*******************************************************************************}
unit UWorkerBusiness;

{$I Link.Inc}
interface

uses
  Windows, Classes, Controls, DB, SysUtils, UBusinessWorker, UBusinessPacker,
  UBusinessConst, UMgrDBConn, UMgrParam, ZnMD5, ULibFun, UFormCtrl, UBase64,
  UCronTasks, USysLoger, USysDB, UMITConst;

type
  TBusWorkerQueryField = class(TBusinessWorkerBase)
  private
    FIn: TWorkerQueryFieldData;
    FOut: TWorkerQueryFieldData;
  public
    class function FunctionName: string; override;
    function GetFlagStr(const nFlag: Integer): string; override;
    function DoWork(var nData: string): Boolean; override;
    //执行业务
  end;

  TMITDBWorker = class(TBusinessWorkerBase)
  protected
    FErrNum: Integer;
    //错误码
    FDBConn: PDBWorker;
    //数据通道
    FDataIn,FDataOut: PBWDataBase;
    //入参出参
    FDataInNeedUnPack: Boolean;
    FDataOutNeedPack: Boolean;
    FDataOutNeedUnPack: Boolean;
    //需要解包
    procedure GetInOutData(var nIn,nOut: PBWDataBase); virtual; abstract;
    //出入参数
    function VerifyParamIn(var nData: string): Boolean; virtual;
    //验证入参
    function DoDBWork(var nData: string): Boolean; virtual; abstract;
    function DoAfterDBWork(var nData: string; nResult: Boolean): Boolean; virtual;
    //数据业务
  public
    function DoWork(var nData: string): Boolean; override;
    //执行业务
    procedure WriteLog(const nEvent: string);
    //记录日志
  end;

  TWorkerBusinessCommander = class(TMITDBWorker)
  private
    FListA,FListB,FListC: TStrings;
    //list
    FIn: TWorkerBusinessCommand;
    FOut: TWorkerBusinessCommand;
  protected
    procedure GetInOutData(var nIn,nOut: PBWDataBase); override;
    function DoDBWork(var nData: string): Boolean; override;
    //base funciton
    function GetCardUsed(var nData: string): Boolean;
    //获取卡片类型
    function Login(var nData: string):Boolean;
    function LogOut(var nData: string): Boolean;
    //登录注销，用于移动终端
    function GetServerNow(var nData: string): Boolean;
    //获取服务器时间
    function GetSerailID(var nData: string): Boolean;
    //获取串号
    function IsSystemExpired(var nData: string): Boolean;
    //系统是否已过期
    function ReloadPriceWeek(var nData: string): Boolean;
    //重载价格周期
    function MakeZhiKaPassword(var nData: string): Boolean;
    //生成纸卡密码
    function GetLadingStockItems(var nData: string;
      const nSelected: Boolean = True): Boolean;
    //可提货品种列表
    function CheckZhiKaValid(var nData: string): Boolean;
    //验证纸卡是否有效
    function GetCustomerValidMoney(var nData: string): Boolean;
    //获取客户可用金
    function GetCustomerPrice(var nData: string): Boolean;
    //获取客户价格清单
    function GetZhiKaValidMoney(var nData: string): Boolean;
    //获取纸卡可用金
    function GetZhiKaUsedMoney(var nData: string): Boolean;
    //获取纸卡已用金额
    function CustomerHasMoney(var nData: string): Boolean;
    //验证客户是否有钱
    function SaveTruck(var nData: string): Boolean;
    function UpdateTruck(var nData: string): Boolean;
    //保存车辆到Truck表
    function GetTruckPoundData(var nData: string): Boolean;
    function SaveTruckPoundData(var nData: string): Boolean;
    //存取车辆称重数据
    function GetStockBatcode(var nData: string): Boolean;
    //获取品种批次号
    function VerifySnapTruck(var nData: string): Boolean;
    //车牌比对
    function GetTruckType(var nData: string): Boolean;
    //获取车类型
  public
    constructor Create; override;
    destructor destroy; override;
    //new free
    function GetFlagStr(const nFlag: Integer): string; override;
    class function FunctionName: string; override;
    //base function
    class function CallMe(const nCmd: Integer; const nData,nExt: string;
      const nOut: PWorkerBusinessCommand): Boolean;
    //local call
  end;

implementation

class function TBusWorkerQueryField.FunctionName: string;
begin
  Result := sBus_GetQueryField;
end;

function TBusWorkerQueryField.GetFlagStr(const nFlag: Integer): string;
begin
  inherited GetFlagStr(nFlag);

  case nFlag of
   cWorker_GetPackerName : Result := sBus_GetQueryField;
  end;
end;

function TBusWorkerQueryField.DoWork(var nData: string): Boolean;
begin
  FOut.FData := '*';
  FPacker.UnPackIn(nData, @FIn);

  case FIn.FType of
   cQF_Bill: 
    FOut.FData := '*';
  end;

  Result := True;
  FOut.FBase.FResult := True;
  nData := FPacker.PackOut(@FOut);
end;

//------------------------------------------------------------------------------
//Date: 2012-3-13
//Parm: 如参数护具
//Desc: 获取连接数据库所需的资源
function TMITDBWorker.DoWork(var nData: string): Boolean;
begin
  Result := False;
  FDBConn := nil;

  with gParamManager.ActiveParam^ do
  try
    FDBConn := gDBConnManager.GetConnection(FDB.FID, FErrNum);
    if not Assigned(FDBConn) then
    begin
      nData := '连接数据库失败(DBConn Is Null).';
      Exit;
    end;

    if not FDBConn.FConn.Connected then
      FDBConn.FConn.Connected := True;
    //conn db

    FDataInNeedUnPack := True;
    FDataOutNeedPack := True;
    FDataOutNeedUnPack := True;

    GetInOutData(FDataIn, FDataOut);
    if FDataInNeedUnPack then
      FPacker.UnPackIn(nData, FDataIn);
    //xxxxx
    
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
      //xxxxx

      if FDataOutNeedPack then
        nData := FPacker.PackOut(FDataOut);
      //xxxxx

      {$IFDEF DEBUG}
      WriteLog('Fun: '+FunctionName+' OutData:'+ FPacker.PackOut(FDataOut, False));
      {$ENDIF}
    end else DoAfterDBWork(nData, False);
  finally
    gDBConnManager.ReleaseConnection(FDBConn);
  end;
end;

//Date: 2012-3-22
//Parm: 输出数据;结果
//Desc: 数据业务执行完毕后的收尾操作
function TMITDBWorker.DoAfterDBWork(var nData: string; nResult: Boolean): Boolean;
begin
  Result := True;
end;

//Date: 2012-3-18
//Parm: 入参数据
//Desc: 验证入参数据是否有效
function TMITDBWorker.VerifyParamIn(var nData: string): Boolean;
begin
  Result := True;
end;

//Desc: 记录nEvent日志
procedure TMITDBWorker.WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(TMITDBWorker, FunctionName, nEvent);
end;

//------------------------------------------------------------------------------
class function TWorkerBusinessCommander.FunctionName: string;
begin
  Result := sBus_BusinessCommand;
end;

constructor TWorkerBusinessCommander.Create;
begin
  FListA := TStringList.Create;
  FListB := TStringList.Create;
  FListC := TStringList.Create;
  inherited;
end;

destructor TWorkerBusinessCommander.destroy;
begin
  FreeAndNil(FListA);
  FreeAndNil(FListB);
  FreeAndNil(FListC);
  inherited;
end;

function TWorkerBusinessCommander.GetFlagStr(const nFlag: Integer): string;
begin
  Result := inherited GetFlagStr(nFlag);

  case nFlag of
   cWorker_GetPackerName : Result := sBus_BusinessCommand;
  end;
end;

procedure TWorkerBusinessCommander.GetInOutData(var nIn,nOut: PBWDataBase);
begin
  nIn := @FIn;
  nOut := @FOut;
  FDataOutNeedUnPack := False;
end;

//Date: 2014-09-15
//Parm: 命令;数据;参数;输出
//Desc: 本地调用业务对象
class function TWorkerBusinessCommander.CallMe(const nCmd: Integer;
  const nData, nExt: string; const nOut: PWorkerBusinessCommand): Boolean;
var nStr: string;
    nIn: TWorkerBusinessCommand;
    nPacker: TBusinessPackerBase;
    nWorker: TBusinessWorkerBase;
begin
  nPacker := nil;
  nWorker := nil;
  try
    nIn.FCommand := nCmd;
    nIn.FData := nData;
    nIn.FExtParam := nExt;

    nPacker := gBusinessPackerManager.LockPacker(sBus_BusinessCommand);
    nPacker.InitData(@nIn, True, False);
    //init
    
    nStr := nPacker.PackIn(@nIn);
    nWorker := gBusinessWorkerManager.LockWorker(FunctionName);
    //get worker

    Result := nWorker.WorkActive(nStr);
    if Result then
         nPacker.UnPackOut(nStr, nOut)
    else nOut.FData := nStr;
  finally
    gBusinessPackerManager.RelasePacker(nPacker);
    gBusinessWorkerManager.RelaseWorker(nWorker);
  end;
end;

//Date: 2012-3-22
//Parm: 输入数据
//Desc: 执行nData业务指令
function TWorkerBusinessCommander.DoDBWork(var nData: string): Boolean;
begin
  with FOut.FBase do
  begin
    FResult := True;
    FErrCode := 'S.00';
    FErrDesc := '业务执行成功.';
  end;

  case FIn.FCommand of
   cBC_GetCardUsed         : Result := GetCardUsed(nData);
   cBC_ServerNow           : Result := GetServerNow(nData);
   cBC_GetSerialNO         : Result := GetSerailID(nData);
   cBC_IsSystemExpired     : Result := IsSystemExpired(nData);
   cBC_ReloadPriceWeek     : Result := ReloadPriceWeek(nData);

   cBC_MakeZhiKaPassword   : Result := MakeZhiKaPassword(nData);
   cBC_GetLadingStockItems : Result := GetLadingStockItems(nData);
   cBC_CheckzhiKaValid     : Result := CheckZhiKaValid(nData);
   cBC_GetCustomerMoney    : Result := GetCustomerValidMoney(nData);
   cBC_GetCustomerPrice    : Result := GetCustomerPrice(nData);
   cBC_GetZhiKaMoney       : Result := GetZhiKaValidMoney(nData);
   cBC_GetZhiKaMoneyUsed   : Result := GetZhiKaUsedMoney(nData);
   cBC_CustomerHasMoney    : Result := CustomerHasMoney(nData);
   cBC_SaveTruckInfo       : Result := SaveTruck(nData);
   cBC_UpdateTruckInfo     : Result := UpdateTruck(nData);
   cBC_GetTruckPoundData   : Result := GetTruckPoundData(nData);
   cBC_SaveTruckPoundData  : Result := SaveTruckPoundData(nData);
   cBC_UserLogin           : Result := Login(nData);
   cBC_UserLogOut          : Result := LogOut(nData);
   cBC_GetStockBatcode     : Result := GetStockBatcode(nData);
   cBC_VerifySnapTruck     : Result := VerifySnapTruck(nData);

   cBC_GetTruckType        : Result := GetTruckType(nData);
   else
    begin
      Result := False;
      nData := '无效的业务代码(Invalid Command).';
    end;
  end;
end;

//Date: 2014-09-05
//Desc: 获取卡片类型：销售S;采购P;其他O
function TWorkerBusinessCommander.GetCardUsed(var nData: string): Boolean;
var nStr: string;
begin
  Result := False;

  nStr := 'Select C_Used From %s Where C_Card=''%s'' ' +
          'or C_Card3=''%s'' or C_Card2=''%s''';
  nStr := Format(nStr, [sTable_Card, FIn.FData, FIn.FData, FIn.FData]);
  //card status

  with gDBConnManager.WorkerQuery(FDBConn, nStr) do
  begin
    if RecordCount<1 then
    begin
      nData := '磁卡[ %s ]信息不存在.';
      nData := Format(nData, [FIn.FData]);
      Exit;
    end;

    FOut.FData := Fields[0].AsString;
    Result := True;
  end;
end;

//------------------------------------------------------------------------------
//Date: 2015/9/9
//Parm: 用户名，密码；返回用户数据
//Desc: 用户登录
function TWorkerBusinessCommander.Login(var nData: string): Boolean;
var nStr: string;
begin
  Result := False;

  FListA.Clear;
  FListA.Text := PackerDecodeStr(FIn.FData);
  if FListA.Values['User']='' then Exit;
  //未传递用户名

  nStr := 'Select U_Password From %s Where U_Name=''%s''';
  nStr := Format(nStr, [sTable_User, FListA.Values['User']]);
  //card status

  with gDBConnManager.WorkerQuery(FDBConn, nStr) do
  begin
    if RecordCount<1 then Exit;

    nStr := Fields[0].AsString;
    if nStr<>FListA.Values['Password'] then Exit;
    {
    if CallMe(cBC_ServerNow, '', '', @nOut) then
         nStr := PackerEncodeStr(nOut.FData)
    else nStr := IntToStr(Random(999999));

    nInfo := FListA.Values['User'] + nStr;
    //xxxxx

    nStr := 'Insert into $EI(I_Group, I_ItemID, I_Item, I_Info) ' +
            'Values(''$Group'', ''$ItemID'', ''$Item'', ''$Info'')';
    nStr := MacroValue(nStr, [MI('$EI', sTable_ExtInfo),
            MI('$Group', sFlag_UserLogItem), MI('$ItemID', FListA.Values['User']),
            MI('$Item', PackerEncodeStr(FListA.Values['Password'])),
            MI('$Info', nInfo)]);
    gDBConnManager.WorkerExec(FDBConn, nStr);  }

    Result := True;
  end;
end;
//------------------------------------------------------------------------------
//Date: 2015/9/9
//Parm: 用户名；验证数据
//Desc: 用户注销
function TWorkerBusinessCommander.LogOut(var nData: string): Boolean;
//var nStr: string;
begin
  {nStr := 'delete From %s Where I_ItemID=''%s''';
  nStr := Format(nStr, [sTable_ExtInfo, PackerDecodeStr(FIn.FData)]);
  //card status

  
  if gDBConnManager.WorkerExec(FDBConn, nStr)<1 then
       Result := False
  else Result := True;     }

  Result := True;
end;

//Date: 2014-09-05
//Desc: 获取服务器当前时间
function TWorkerBusinessCommander.GetServerNow(var nData: string): Boolean;
var nStr: string;
begin
  nStr := 'Select ' + sField_SQLServer_Now;
  //sql

  with gDBConnManager.WorkerQuery(FDBConn, nStr) do
  begin
    FOut.FData := DateTime2Str(Fields[0].AsDateTime);
    Result := True;
  end;
end;

//Date: 2012-3-25
//Desc: 按规则生成序列编号
function TWorkerBusinessCommander.GetSerailID(var nData: string): Boolean;
var nInt: Integer;
    nStr,nP,nB: string;
begin
  FDBConn.FConn.BeginTrans;
  try
    Result := False;
    FListA.Text := FIn.FData;
    //param list

    nStr := 'Update %s Set B_Base=B_Base+1 ' +
            'Where B_Group=''%s'' And B_Object=''%s''';
    nStr := Format(nStr, [sTable_SerialBase, FListA.Values['Group'],
            FListA.Values['Object']]);
    gDBConnManager.WorkerExec(FDBConn, nStr);

    nStr := 'Select B_Prefix,B_IDLen,B_Base,B_Date,%s as B_Now From %s ' +
            'Where B_Group=''%s'' And B_Object=''%s''';
    nStr := Format(nStr, [sField_SQLServer_Now, sTable_SerialBase,
            FListA.Values['Group'], FListA.Values['Object']]);
    //xxxxx

    with gDBConnManager.WorkerQuery(FDBConn, nStr) do
    begin
      if RecordCount < 1 then
      begin
        nData := '没有[ %s.%s ]的编码配置.';
        nData := Format(nData, [FListA.Values['Group'], FListA.Values['Object']]);

        FDBConn.FConn.RollbackTrans;
        Exit;
      end;

      nP := FieldByName('B_Prefix').AsString;
      nB := FieldByName('B_Base').AsString;
      nInt := FieldByName('B_IDLen').AsInteger;

      if FIn.FExtParam = sFlag_Yes then //按日期编码
      begin
        nStr := Date2Str(FieldByName('B_Date').AsDateTime, False);
        //old date

        if (nStr <> Date2Str(FieldByName('B_Now').AsDateTime, False)) and
           (FieldByName('B_Now').AsDateTime > FieldByName('B_Date').AsDateTime) then
        begin
          nStr := 'Update %s Set B_Base=1,B_Date=%s ' +
                  'Where B_Group=''%s'' And B_Object=''%s''';
          nStr := Format(nStr, [sTable_SerialBase, sField_SQLServer_Now,
                  FListA.Values['Group'], FListA.Values['Object']]);
          gDBConnManager.WorkerExec(FDBConn, nStr);

          nB := '1';
          nStr := Date2Str(FieldByName('B_Now').AsDateTime, False);
          //now date
        end;

        System.Delete(nStr, 1, 2);
        //yymmdd
        nInt := nInt - Length(nP) - Length(nStr) - Length(nB);
        FOut.FData := nP + nStr + StringOfChar('0', nInt) + nB;
      end else
      begin
        nInt := nInt - Length(nP) - Length(nB);
        nStr := StringOfChar('0', nInt);
        FOut.FData := nP + nStr + nB;
      end;
    end;

    FDBConn.FConn.CommitTrans;
    Result := True;
  except
    FDBConn.FConn.RollbackTrans;
    raise;
  end;
end;

//Date: 2014-09-05
//Desc: 验证系统是否已过期
function TWorkerBusinessCommander.IsSystemExpired(var nData: string): Boolean;
var nStr: string;
    nDate: TDate;
    nInt: Integer;
begin
  nDate := Date();
  //server now

  nStr := 'Select D_Value,D_ParamB From %s ' +
          'Where D_Name=''%s'' and D_Memo=''%s''';
  nStr := Format(nStr, [sTable_SysDict, sFlag_SysParam, sFlag_ValidDate]);

  with gDBConnManager.WorkerQuery(FDBConn, nStr) do
  if RecordCount > 0 then
  begin
    nStr := 'dmzn_stock_' + Fields[0].AsString;
    nStr := MD5Print(MD5String(nStr));

    if nStr = Fields[1].AsString then
      nDate := Str2Date(Fields[0].AsString);
    //xxxxx
  end;

  nInt := Trunc(nDate - Date());
  Result := nInt > 0;

  if nInt <= 0 then
  begin
    nStr := '系统已过期 %d 天,请联系管理员!!';
    nData := Format(nStr, [-nInt]);
    Exit;
  end;

  FOut.FData := IntToStr(nInt);
  //last days

  if nInt <= 7 then
  begin
    nStr := Format('系统在 %d 天后过期', [nInt]);
    FOut.FBase.FErrDesc := nStr;
    FOut.FBase.FErrCode := sFlag_ForceHint;
  end;
end;

//Desc: 重新加载价格周期
function TWorkerBusinessCommander.ReloadPriceWeek(var nData: string): Boolean;
begin
  gTaskManager.ReloadPriceWeeks;
  Result := True;
end;

//Desc: 生成纸卡提货密码
function TWorkerBusinessCommander.MakeZhiKaPassword(var nData: string): Boolean;
const
  cMaxLen = 6;
var nStr: string;
    nIdx,nLen: Integer;
begin
  while True do
  begin
    nStr := MD5Print(MD5String(DateTimeSerial()));
    FOut.FData := '';
    nLen := Length(nStr);

    for nIdx:=1 to nLen do
     if nStr[nIdx] in ['0'..'9'] then
      FOut.FData := FOut.FData + nStr[nIdx];
    //only number

    nLen := Length(FOut.FData);
    if nLen < cMaxLen then Continue;
    nIdx := Random(nLen);

    if nLen - nIdx < cMaxLen - 1 then nIdx := nLen - (cMaxLen - 1);
    if nIdx < 1 then nIdx := 1;
    FOut.FData := UpperCase(Copy(FOut.FData, nIdx, cMaxLen));

    nStr := 'Select Count(*) From %s ' +
            'Where Z_Password=''%s'' And Z_InValid=''%s''';
    nStr := Format(nStr, [sTable_ZhiKa, FOut.FData, sFlag_No]);

    with gDBConnManager.WorkerQuery(FDBConn, nStr) do
      if Fields[0].AsInteger < 1 then Break;
    //编号可用
  end;

  Result := True;
end;

//Desc: 获取可提货品种列表
function TWorkerBusinessCommander.GetLadingStockItems(var nData: string;
  const nSelected: Boolean): Boolean;
var nStr: string;
    nIdx: Integer;
    nItems: TStockTypeItems;
begin
  nStr := 'Select D_Value,D_Memo,D_ParamB From %s ' +
          'Where D_Name=''%s'' Order By D_Index ASC';
  nStr := Format(nStr, [sTable_SysDict, sFlag_StockItem]);
  
  with gDBConnManager.WorkerQuery(FDBConn, nStr) do
  begin
    SetLength(nItems, RecordCount);
    if RecordCount > 0 then
    begin
      nIdx := 0;
      First;

      while not Eof do
      begin
        with nItems[nIdx] do
        begin
          FType := FieldByName('D_Memo').AsString;
          FName := FieldByName('D_Value').AsString;
          FID := FieldByName('D_ParamB').AsString;

          FParam := '';
          FPrice := 0;
          FSelected := nSelected;
        end;

        Next;
        Inc(nIdx);
      end;
    end;
  end;

  Result := Length(nItems) > 0;
  if Result then
       FOut.FData := CombineTypeItmes(nItems)
  else nData := Format('未配置[ %s.%s ]字典项', [sTable_SysDict, sFlag_StockItem]);
end;

//Date: 2018-12-14
//Parm: 纸卡号[FIn.FData];是否取货码[FIn.FExtParam]
//Desc: 验证纸卡号是否有效
function TWorkerBusinessCommander.CheckZhiKaValid(var nData: string): Boolean;
var nStr: string;
begin
  if FIn.FExtParam = sFlag_Yes then //取货码
  begin
    nStr := 'Select Top 1 Z_ID,Z_Customer,Z_InValid,Z_Freeze,Z_ValidDays,' +
            'Z_Verified,%s as Z_Now From %s ' +
            'Where Z_Password=''%s'' Order By R_ID DESC';
    nStr := Format(nStr, [sField_SQLServer_Now, sTable_ZhiKa, FIn.FData]);
  end else
  begin
    nStr := 'Select Z_ID,Z_Customer,Z_InValid,Z_Freeze,Z_ValidDays,' +
            'Z_Verified,%s as Z_Now From %s Where Z_ID=''%s''';
    nStr := Format(nStr, [sField_SQLServer_Now, sTable_ZhiKa, FIn.FData]);
  end;

  Result := False;
  with gDBConnManager.WorkerQuery(FDBConn, nStr) do
  begin
    if RecordCount < 1 then
    begin
      if FIn.FExtParam = sFlag_Yes then
           nStr := '提货码[ %s ]无效'
      else nStr := '纸卡[ %s ]已丢失';

      nData := Format(nStr, [FIn.FData]);
      Exit;
    end;

    nStr := FieldByName('Z_ID').AsString;
    if FieldByName('Z_InValid').AsString = sFlag_Yes then
    begin
      nData := Format('纸卡[ %s ]已无效', [nStr]);
      Exit;
    end;

    if FieldByName('Z_Freeze').AsString = sFlag_Yes then
    begin
      nData := Format('纸卡[ %s ]已被冻结', [nStr]);
      Exit;
    end;

    if FieldByName('Z_Verified').AsString = sFlag_No then
    begin
      nData := Format('纸卡[ %s ]未审核', [nStr]);
      Exit;
    end;

    if FieldByName('Z_ValidDays').AsDateTime <=
       FieldByName('Z_Now').AsDateTime then
    begin
      nData := Format('纸卡[ %s ]已过期', [nStr]);
      Exit;
    end;

    FOut.FData := nStr;
    FOut.FExtParam := FieldByName('Z_Customer').AsString;
    Result := True;
  end;
end;

//Date: 2018-12-13
//Parm: 客户号[FIn.FData];使用信用[FIn.FExtParam]
//Desc: 获取指定客户的可用金额
function TWorkerBusinessCommander.GetCustomerValidMoney(var nData: string): Boolean;
var nStr: string;
    nUseCredit: Boolean;
    nVal,nCredit,nHasUsed: Double;
begin
  Result := True;
  nUseCredit := False;
  
  if FIn.FExtParam = sFlag_Yes then
  begin
    nStr := 'Select MAX(C_End) From %s ' +
            'Where C_CusID=''%s'' and C_Money>=0 and C_Verify=''%s''';
    nStr := Format(nStr, [sTable_CusCredit, FIn.FData, sFlag_Yes]);

    with gDBConnManager.WorkerQuery(FDBConn, nStr) do
      nUseCredit := (Fields[0].AsDateTime > Str2Date('2000-01-01')) and
                    (Fields[0].AsDateTime > Now());
    //信用未过期
  end;

  nStr := 'Select Sum(Z_Money) From %s ' +
          'Where Z_Customer=''%s'' and Z_InValid=''%s'' and Z_Money>0';
  nStr := Format(nStr, [sTable_ZhiKa, FIn.FData, sFlag_No]);

  with gDBConnManager.WorkerQuery(FDBConn, nStr) do
    nHasUsed := Fields[0].AsFloat;
  //有效纸卡占用金额

  nStr := 'Select Sum(L_Value*L_Price) as L_Money ' +
          'From %s Where L_ZhiKa In (Select Z_ID From %s ' +
          'Where Z_Customer=''%s'' and Z_InValid=''%s'' And Z_Money>0)';
  nStr := Format(nStr, [sTable_Bill, sTable_ZhiKa, FIn.FData, sFlag_No]);

  with gDBConnManager.WorkerQuery(FDBConn, nStr) do
    nHasUsed := nHasUsed - Fields[0].AsFloat;
  nHasUsed := Float2Float(nHasUsed, cPrecision, True);
  //由于有效纸卡的出金和冻结金已从纸卡占用金额中扣除,需要补偿

  nStr := 'Select * From %s Where A_CID=''%s''';
  nStr := Format(nStr, [sTable_CusAccount, FIn.FData]);
  with gDBConnManager.WorkerQuery(FDBConn, nStr) do
  begin
    if RecordCount < 1 then
    begin
      nData := Format('编号为[ %s ]的客户账户不存在.', [FIn.FData]);
      Result := False;
      Exit;
    end;

    nVal := FieldByName('A_InitMoney').AsFloat + FieldByName('A_InMoney').AsFloat -
            FieldByName('A_OutMoney').AsFloat -
            FieldByName('A_Compensation').AsFloat -
            FieldByName('A_FreezeMoney').AsFloat;
    nVal := Float2Float(nVal, cPrecision, False);

    nCredit := FieldByName('A_CreditLimit').AsFloat;
    nCredit := Float2Float(nCredit, cPrecision, False);

    if nUseCredit then
      nVal := nVal + nCredit;
    nVal := nVal - nHasUsed;

    FOut.FData := FloatToStr(nVal);
    FOut.FExtParam := FloatToStr(nCredit);
  end;
end;

//Date: 2018-12-16
//Parm: 客户号[FIn.FData];默认选中
//Desc: 生成客户当前的价格表
function TWorkerBusinessCommander.GetCustomerPrice(var nData: string): Boolean;
var nStr,nArea: string;
    nIdx: Integer;
    nItems: TStockTypeItems;
begin
  Result := GetLadingStockItems(nData, False);
  if not Result then Exit;
  AnalyseTypeItems(FOut.FData, nItems);

  nStr := 'Select C_Area From %s Where C_ID=''%s''';
  nStr := Format(nStr, [sTable_Customer, FIn.FData]);

  with gDBConnManager.WorkerQuery(FDBConn, nStr) do
  begin
    if RecordCount < 1 then
    begin
      Result := False;
      nData := Format('客户[ %s ]已丢失', [FIn.FData]);
      Exit;
    end;

    nArea := Trim(Fields[0].AsString);
  end;

  nStr := 'Select W_NO,W_Name,R_ID,R_Type,R_Area,R_Customer,R_StockNo,' +
          'R_Price From %s,%s Where W_Valid=''%s'' And W_NO=R_Week ' +
          'Order By R_StockNo ASC,W_Begin DESC,R_Price DESC';
  nStr := Format(nStr, [sTable_PriceWeek, sTable_PriceRule, sFlag_Yes]);
  //价格倒序:同品种高价优先.

  with gDBConnManager.WorkerQuery(FDBConn, nStr) do
  begin
    if RecordCount < 1 then
    begin
      Result := False;
      nData := '当前没有生效的价格表';
      Exit;
    end;

    for nIdx:=Low(nItems) to High(nItems) do
    with nItems[nIdx] do
    begin
      First;
      while not Eof do //扫描专用价
      begin
        if (FieldByName('R_StockNo').AsString = FID) and
           (FieldByName('R_Type').AsString = sFlag_PriceZY) and
           (FieldByName('R_Customer').AsString = FIn.FData) then
        begin
          FSelected := True;
          FPrice := FieldByName('R_Price').AsFloat;

          FParam := Format('周期:[ %s,%s ] 记录:[ %s ] 类型:[ 客户专用 ]', [
            FieldByName('W_NO').AsString, FieldByName('W_Name').AsString,
            FieldByName('R_ID').AsString]);
          Break;
        end;

        Next;
      end;

      if FSelected then Continue;
      //专用价生效

      if nArea <> '' then
      begin
        First;
        while not Eof do //扫描区域价
        begin
          if (FieldByName('R_StockNo').AsString = FID) and
             (FieldByName('R_Type').AsString = sFlag_PriceQY) and
             (FieldByName('R_Area').AsString = nArea) then
          begin
            FSelected := True;
            FPrice := FieldByName('R_Price').AsFloat;

            FParam := Format('周期:[ %s,%s ] 记录:[ %s ] 类型:[ %s区域价 ]', [
              FieldByName('W_NO').AsString, FieldByName('W_Name').AsString,
              FieldByName('R_ID').AsString, nArea]);
            Break;
          end;

          Next;
        end;
      end;

      if FSelected then Continue;
      //区域价生效

      First;
      while not Eof do //扫描零售价
      begin
        if (FieldByName('R_StockNo').AsString = FID) and
           (FieldByName('R_Type').AsString = sFlag_PriceLS) then
        begin
          FSelected := True;
          FPrice := FieldByName('R_Price').AsFloat;

          FParam := Format('周期:[ %s,%s ] 记录:[ %s ] 类型:[ 零售价 ]', [
              FieldByName('W_NO').AsString, FieldByName('W_Name').AsString,
              FieldByName('R_ID').AsString]);
          Break;
        end;

        Next;
      end;
    end;
  end;

  FOut.FData := CombineTypeItmes(nItems);
  //合并价格表
end;

//Date: 2018-12-13
//Parm: 纸卡号[FIn.FData]
//Desc: 获取指定纸卡的可用金额
function TWorkerBusinessCommander.GetZhiKaValidMoney(var nData: string): Boolean;
var nStr: string;
    nMoney: Double;
begin
  nStr := 'Select Z_Money,Z_MoneyUsed,Z_MoneyAll,Z_Customer,Z_InValid From %s ' +
          'Where Z_ID=''%s''';
  nStr := Format(nStr, [sTable_ZhiKa, FIn.FData]);
  
  with gDBConnManager.WorkerQuery(FDBConn, nStr) do
  begin
    if RecordCount < 1 then
    begin
      nData := Format('编号为[ %s ]的纸卡不存在.', [FIn.FData]);
      Result := False;
      Exit;
    end;

    nStr := FieldByName('Z_MoneyAll').AsString;
    if nStr = sFlag_Yes then
    begin
      FIn.FData := FieldByName('Z_Customer').AsString;
      FIn.FExtParam := sFlag_Yes; //use credit
      Result := GetCustomerValidMoney(nData);

      if Result then
        FOut.FExtParam := sFlag_No;
      Exit;
    end; //不限提,计算客户可用金
                     
    if FieldByName('Z_InValid').AsString = sFlag_Yes then //已无效
    begin
      FOut.FData := '0';
      FOut.FExtParam := sFlag_Yes; //限提

      Result := True;
      Exit;
    end;

    nMoney := FieldByName('Z_Money').AsFloat;
    //纸卡资金总额
    GetZhiKaUsedMoney(nData);
    //纸卡已用金额

    FOut.FData := FloatToStr(nMoney - StrToFloat(FOut.FData));
    FOut.FExtParam := sFlag_Yes; //限提
    Result := True;
  end;
end;

//Date: 2018-12-13
//Parm: 纸卡号[FIn.FData]
//Desc: 获取纸卡已用金额
function TWorkerBusinessCommander.GetZhiKaUsedMoney(var nData: string): Boolean;
var nStr: string;
    nVal,nAll: Double;
begin
  Result := True;
  FOut.FData := '0';
  FOut.FExtParam := '0';
  
  nStr := 'Select Sum(L_Money) As Money,L_OutFact From (' +
    'Select L_Value*L_Price as L_Money,(Case When L_OutFact Is Null ' +
    'Then 0 Else 1 End) as L_OutFact From %s ' +
    'Where L_ZhiKa=''%s'') t Group By L_OutFact';
  nStr := Format(nStr, [sTable_Bill, FIn.FData]);

  with gDBConnManager.WorkerQuery(FDBConn, nStr) do
  if RecordCount > 0 then
  begin
    nAll := 0;
    First;
    
    while not Eof do
    begin
      nVal := Float2Float(Fields[0].AsFloat, cPrecision, True);
      if FieldByName('L_OutFact').AsInteger < 1 then
        FOut.FExtParam := FloatToStr(nVal);
      //冻结金

      nAll := nAll + nVal;
      Next;
    end;

    FOut.FData := FloatToStr(nAll);
    //总额:冻结金 + 出金
  end;
end;

//Date: 2014-09-05
//Desc: 验证客户是否有钱,以及信用是否过期
function TWorkerBusinessCommander.CustomerHasMoney(var nData: string): Boolean;
var nStr,nName: string;
    nM,nC: Double;
begin
  FIn.FExtParam := sFlag_No;
  Result := GetCustomerValidMoney(nData);
  if not Result then Exit;

  nM := StrToFloat(FOut.FData);
  FOut.FData := sFlag_Yes;
  if nM > 0 then Exit;

  nStr := 'Select C_Name From %s Where C_ID=''%s''';
  nStr := Format(nStr, [sTable_Customer, FIn.FData]);

  with gDBConnManager.WorkerQuery(FDBConn, nStr) do
  begin
    if RecordCount > 0 then
         nName := Fields[0].AsString
    else nName := '已删除';
  end;

  nC := StrToFloat(FOut.FExtParam);
  if (nC <= 0) or (nC + nM <= 0) then
  begin
    nData := Format('客户[ %s ]的资金余额不足.', [nName]);
    Result := False;
    Exit;
  end;

  nStr := 'Select MAX(C_End) From %s ' +
          'Where C_CusID=''%s'' and C_Money>=0 and C_Verify=''%s''';
  nStr := Format(nStr, [sTable_CusCredit, FIn.FData, sFlag_Yes]);

  with gDBConnManager.WorkerQuery(FDBConn, nStr) do
  if (Fields[0].AsDateTime > Str2Date('2000-01-01')) and
     (Fields[0].AsDateTime <= Now()) then
  begin
    nData := Format('客户[ %s ]的信用已过期.', [nName]);
    Result := False;
  end;
end;

//Date: 2014-10-02
//Parm: 车牌号[FIn.FData];
//Desc: 保存车辆到sTable_Truck表
function TWorkerBusinessCommander.SaveTruck(var nData: string): Boolean;
var nStr: string;
begin
  Result := True;
  FIn.FData := UpperCase(FIn.FData);
  
  nStr := 'Select Count(*) From %s Where T_Truck=''%s''';
  nStr := Format(nStr, [sTable_Truck, FIn.FData]);
  //xxxxx

  with gDBConnManager.WorkerQuery(FDBConn, nStr) do
  if Fields[0].AsInteger < 1 then
  begin
    nStr := 'Insert Into %s(T_Truck, T_PY) Values(''%s'', ''%s'')';
    nStr := Format(nStr, [sTable_Truck, FIn.FData, GetPinYinOfStr(FIn.FData)]);
    gDBConnManager.WorkerExec(FDBConn, nStr);
  end;
end;

//Date: 2016-02-16
//Parm: 车牌号(Truck); 表字段名(Field);数据值(Value)
//Desc: 更新车辆信息到sTable_Truck表
function TWorkerBusinessCommander.UpdateTruck(var nData: string): Boolean;
var nStr: string;
    nValInt: Integer;
    nValFloat: Double;
begin
  Result := True;
  FListA.Text := FIn.FData;

  if FListA.Values['Field'] = 'T_PValue' then
  begin
    nStr := 'Select T_PValue, T_PTime From %s Where T_Truck=''%s''';
    nStr := Format(nStr, [sTable_Truck, FListA.Values['Truck']]);

    with gDBConnManager.WorkerQuery(FDBConn, nStr) do
    if RecordCount > 0 then
    begin
      nValInt := Fields[1].AsInteger;
      nValFloat := Fields[0].AsFloat;
    end else Exit;

    nValFloat := nValFloat * nValInt + StrToFloatDef(FListA.Values['Value'], 0);
    nValFloat := nValFloat / (nValInt + 1);
    nValFloat := Float2Float(nValFloat, cPrecision);

    nStr := 'Update %s Set T_PValue=%.2f, T_PTime=T_PTime+1 Where T_Truck=''%s''';
    nStr := Format(nStr, [sTable_Truck, nValFloat, FListA.Values['Truck']]);
    gDBConnManager.WorkerExec(FDBConn, nStr);
  end;
end;

//Date: 2014-09-25
//Parm: 车牌号[FIn.FData]
//Desc: 获取指定车牌号的称皮数据(使用配对模式,未称重)
function TWorkerBusinessCommander.GetTruckPoundData(var nData: string): Boolean;
var nStr: string;
    nPound: TLadingBillItems;
begin
  SetLength(nPound, 1);
  FillChar(nPound[0], SizeOf(TLadingBillItem), #0);

  nStr := 'Select * From %s Where P_Truck=''%s'' And ' +
          'P_MValue Is Null And P_PModel=''%s''';
  nStr := Format(nStr, [sTable_PoundLog, FIn.FData, sFlag_PoundPD]);

  with gDBConnManager.WorkerQuery(FDBConn, nStr),nPound[0] do
  begin
    if RecordCount > 0 then
    begin
      FCusID      := FieldByName('P_CusID').AsString;
      FCusName    := FieldByName('P_CusName').AsString;
      FTruck      := FieldByName('P_Truck').AsString;

      FType       := FieldByName('P_MType').AsString;
      FStockNo    := FieldByName('P_MID').AsString;
      FStockName  := FieldByName('P_MName').AsString;

      with FPData do
      begin
        FStation  := FieldByName('P_PStation').AsString;
        FValue    := FieldByName('P_PValue').AsFloat;
        FDate     := FieldByName('P_PDate').AsDateTime;
        FOperator := FieldByName('P_PMan').AsString;
      end;  

      FFactory    := FieldByName('P_FactID').AsString;
      FPModel     := FieldByName('P_PModel').AsString;
      FPType      := FieldByName('P_Type').AsString;
      FPoundID    := FieldByName('P_ID').AsString;

      FStatus     := sFlag_TruckBFP;
      FNextStatus := sFlag_TruckBFM;
      FSelected   := True;
    end else
    begin
      FTruck      := FIn.FData;
      FPModel     := sFlag_PoundPD;

      FStatus     := '';
      FNextStatus := sFlag_TruckBFP;
      FSelected   := True;
    end;
  end;

  FOut.FData := CombineBillItmes(nPound);
  Result := True;
end;

//Date: 2014-09-25
//Parm: 称重数据[FIn.FData]
//Desc: 获取指定车牌号的称皮数据(使用配对模式,未称重)
function TWorkerBusinessCommander.SaveTruckPoundData(var nData: string): Boolean;
var nStr,nSQL: string;
    nPound: TLadingBillItems;
    nOut: TWorkerBusinessCommand;
begin
  AnalyseBillItems(FIn.FData, nPound);
  //解析数据

  with nPound[0] do
  begin
    if FPoundID = '' then
    begin
      TWorkerBusinessCommander.CallMe(cBC_SaveTruckInfo, FTruck, '', @nOut);
      //保存车牌号

      FListC.Clear;
      FListC.Values['Group'] := sFlag_BusGroup;
      FListC.Values['Object'] := sFlag_PoundID;

      if not CallMe(cBC_GetSerialNO,
            FListC.Text, sFlag_Yes, @nOut) then
        raise Exception.Create(nOut.FData);
      //xxxxx

      FPoundID := nOut.FData;
      //new id

      if FPModel = sFlag_PoundLS then
           nStr := sFlag_Other
      else nStr := sFlag_Provide;

      nSQL := MakeSQLByStr([
              SF('P_ID', FPoundID),
              SF('P_Type', nStr),
              SF('P_Truck', FTruck),
              SF('P_CusID', FCusID),
              SF('P_CusName', FCusName),
              SF('P_MID', FStockNo),
              SF('P_MName', FStockName),
              SF('P_MType', sFlag_San),
              SF('P_PValue', FPData.FValue, sfVal),
              SF('P_PDate', sField_SQLServer_Now, sfVal),
              SF('P_PMan', FIn.FBase.FFrom.FUser),
              SF('P_FactID', FFactory),
              SF('P_PStation', FPData.FStation),
              SF('P_Direction', '进厂'),
              SF('P_PModel', FPModel),
              SF('P_Status', sFlag_TruckBFP),
              SF('P_Valid', sFlag_Yes),
              SF('P_PrintNum', 1, sfVal)
              ], sTable_PoundLog, '', True);
      gDBConnManager.WorkerExec(FDBConn, nSQL);
    end else
    begin
      nStr := SF('P_ID', FPoundID);
      //where

      if FNextStatus = sFlag_TruckBFP then
      begin
        nSQL := MakeSQLByStr([
                SF('P_PValue', FPData.FValue, sfVal),
                SF('P_PDate', sField_SQLServer_Now, sfVal),
                SF('P_PMan', FIn.FBase.FFrom.FUser),
                SF('P_PStation', FPData.FStation),
                SF('P_MValue', FMData.FValue, sfVal),
                SF('P_MDate', DateTime2Str(FMData.FDate)),
                SF('P_MMan', FMData.FOperator),
                SF('P_MStation', FMData.FStation)
                ], sTable_PoundLog, nStr, False);
        //称重时,由于皮重大,交换皮毛重数据
      end else
      begin
        nSQL := MakeSQLByStr([
                SF('P_MValue', FMData.FValue, sfVal),
                SF('P_MDate', sField_SQLServer_Now, sfVal),
                SF('P_MMan', FIn.FBase.FFrom.FUser),
                SF('P_MStation', FMData.FStation)
                ], sTable_PoundLog, nStr, False);
        //xxxxx
      end;

      gDBConnManager.WorkerExec(FDBConn, nSQL);
    end;

    FOut.FData := FPoundID;
    Result := True;
  end;
end;

//Date: 2016-02-24
//Parm: 物料编号[FIn.FData];预扣减量[FIn.ExtParam];
//Desc: 按规则生成指定品种的批次编号
function TWorkerBusinessCommander.GetStockBatcode(var nData: string): Boolean;
var nStr,nP: string;
    nNew: Boolean;
    nInt,nInc: Integer;
    nVal,nPer: Double;

    //生成新批次号
    function NewBatCode: string;
    begin
      nStr := 'Select * From %s Where B_Stock=''%s''';
      nStr := Format(nStr, [sTable_StockBatcode, FIn.FData]);

      with gDBConnManager.WorkerQuery(FDBConn, nStr) do
      begin
        nP := FieldByName('B_Prefix').AsString;
        nStr := FieldByName('B_UseYear').AsString;

        if nStr = sFlag_Yes then
        begin
          nStr := Copy(Date2Str(Now()), 3, 2);
          nP := nP + nStr;
          //前缀后两位年份
        end;

        nStr := FieldByName('B_Base').AsString;
        nInt := FieldByName('B_Length').AsInteger;
        nInt := nInt - Length(nP + nStr);

        if nInt > 0 then
             Result := nP + StringOfChar('0', nInt) + nStr
        else Result := nP + nStr;

        nStr := '物料[ %s.%s ]将立即使用批次号[ %s ],请通知化验室确认已采样.';
        nStr := Format(nStr, [FieldByName('B_Stock').AsString,
                              FieldByName('B_Name').AsString, Result]);
        //xxxxx

        FOut.FBase.FErrCode := sFlag_ForceHint;
        FOut.FBase.FErrDesc := nStr;
      end;

      nStr := MakeSQLByStr([SF('B_Batcode', Result),
                SF('B_FirstDate', sField_SQLServer_Now, sfVal),
                SF('B_HasUse', 0, sfVal),
                SF('B_LastDate', sField_SQLServer_Now, sfVal)
                ], sTable_StockBatcode, SF('B_Stock', FIn.FData), False);
      gDBConnManager.WorkerExec(FDBConn, nStr);
    end;
begin
  Result := True;
  FOut.FData := '';
  
  nStr := 'Select D_Value From %s Where D_Name=''%s''';
  nStr := Format(nStr, [sTable_SysDict, sFlag_BatchAuto]);
  
  with gDBConnManager.WorkerQuery(FDBConn, nStr) do
  if RecordCount > 0 then
  begin
    nStr := Fields[0].AsString;
    if nStr <> sFlag_Yes then Exit;
  end  else Exit;
  //默认不使用批次号

  Result := False; //Init
  nStr := 'Select *,%s as ServerNow From %s Where B_Stock=''%s''';
  nStr := Format(nStr, [sField_SQLServer_Now, sTable_StockBatcode, FIn.FData]);

  with gDBConnManager.WorkerQuery(FDBConn, nStr) do
  begin
    if RecordCount < 1 then
    begin
      nData := '物料[ %s ]未配置批次号规则.';
      nData := Format(nData, [FIn.FData]);
      Exit;
    end;

    FOut.FData := FieldByName('B_Batcode').AsString;
    nInc := FieldByName('B_Incement').AsInteger;
    nNew := False;

    if FieldByName('B_UseDate').AsString = sFlag_Yes then
    begin
      nP := FieldByName('B_Prefix').AsString;
      nStr := Date2Str(FieldByName('ServerNow').AsDateTime, False);

      nInt := FieldByName('B_Length').AsInteger;
      nInt := Length(nP + nStr) - nInt;

      if nInt > 0 then
      begin
        System.Delete(nStr, 1, nInt);
        FOut.FData := nP + nStr;
      end else
      begin
        nStr := StringOfChar('0', -nInt) + nStr;
        FOut.FData := nP + nStr;
      end;

      nNew := True;
    end;

    if (not nNew) and (FieldByName('B_AutoNew').AsString = sFlag_Yes) then      //元旦重置
    begin
      nStr := Date2Str(FieldByName('ServerNow').AsDateTime);
      nStr := Copy(nStr, 1, 4);
      nP := Date2Str(FieldByName('B_LastDate').AsDateTime);
      nP := Copy(nP, 1, 4);

      if nStr <> nP then
      begin
        nStr := 'Update %s Set B_Base=1 Where B_Stock=''%s''';
        nStr := Format(nStr, [sTable_StockBatcode, FIn.FData]);
        
        gDBConnManager.WorkerExec(FDBConn, nStr);
        FOut.FData := NewBatCode;
        nNew := True;
      end;
    end;

    if not nNew then //编号超期
    begin
      nStr := Date2Str(FieldByName('ServerNow').AsDateTime);
      nP := Date2Str(FieldByName('B_FirstDate').AsDateTime);

      if (Str2Date(nP) > Str2Date('2000-01-01')) and
         (Str2Date(nStr) - Str2Date(nP) > FieldByName('B_Interval').AsInteger) then
      begin
        nStr := 'Update %s Set B_Base=B_Base+%d Where B_Stock=''%s''';
        nStr := Format(nStr, [sTable_StockBatcode, nInc, FIn.FData]);

        gDBConnManager.WorkerExec(FDBConn, nStr);
        FOut.FData := NewBatCode;
        nNew := True;
      end;
    end;

    if not nNew then //编号超发
    begin
      nVal := FieldByName('B_HasUse').AsFloat + StrToFloat(FIn.FExtParam);
      //已使用+预使用
      nPer := FieldByName('B_Value').AsFloat * FieldByName('B_High').AsFloat / 100;
      //可用上限

      if nVal >= nPer then //超发
      begin
        nStr := 'Update %s Set B_Base=B_Base+%d Where B_Stock=''%s''';
        nStr := Format(nStr, [sTable_StockBatcode, nInc, FIn.FData]);

        gDBConnManager.WorkerExec(FDBConn, nStr);
        FOut.FData := NewBatCode;
      end else
      begin
        nPer := FieldByName('B_Value').AsFloat * FieldByName('B_Low').AsFloat / 100;
        //提醒
      
        if nVal >= nPer then //超发提醒
        begin
          nStr := '物料[ %s.%s ]即将更换批次号,请通知化验室准备取样.';
          nStr := Format(nStr, [FieldByName('B_Stock').AsString,
                                FieldByName('B_Name').AsString]);
          //xxxxx

          FOut.FBase.FErrCode := sFlag_ForceHint;
          FOut.FBase.FErrDesc := nStr;
        end;
      end;
    end;
  end;

  if FOut.FData = '' then
    FOut.FData := NewBatCode;
  //xxxxx

  Result := True;
  FOut.FBase.FResult := True;
end;

//Date: 2017-12-2
//Parm: 车牌号(Truck); 交货单号(Bill);岗位(Pos)
//Desc: 抓拍比对
function TWorkerBusinessCommander.VerifySnapTruck(var nData: string): Boolean;
var nStr: string;
    nTruck, nBill, nPos, nSnapTruck, nEvent, nDept, nPicName: string;
    nUpdate, nNeedManu: Boolean;
begin
  Result := False;
  FListA.Text := FIn.FData;
  nSnapTruck:= '';
  nEvent:= '' ;
  nNeedManu := False;

  nTruck := FListA.Values['Truck'];
  nBill  := FListA.Values['Bill'];
  nPos   := FListA.Values['Pos'];
  nDept  := FListA.Values['Dept'];

  nStr := 'Select D_Value From %s Where D_Name=''%s'' and D_Memo=''%s''';
  nStr := Format(nStr, [sTable_SysDict, sFlag_TruckInNeedManu,nPos]);
  //xxxxx

  with gDBConnManager.WorkerQuery(FDBConn, nStr) do
  begin
    if RecordCount > 0 then
    begin
      nNeedManu := FieldByName('D_Value').AsString = sFlag_Yes;
    end;
  end;
  WriteLog('车牌识别:'+'岗位:'+nPos+'事件接收部门:'+nDept);

  nData := '车辆[ %s ]车牌识别失败';
  nData := Format(nData, [nTruck]);
  FOut.FData := nData;
  //default

  nStr := 'Select * From %s Where S_ID=''%s'' order by R_ID desc ';
  nStr := Format(nStr, [sTable_SnapTruck, nPos]);
  //xxxxx

  with gDBConnManager.WorkerQuery(FDBConn, nStr) do
  begin
    if RecordCount < 1 then
    begin
      if not nNeedManu then
        Result := True;
      nData := '车辆[ %s ]抓拍异常';
      nData := Format(nData, [nTruck]);
      FOut.FData := nData;
      Exit;
    end;

    nPicName := '';

    First;

    while not Eof do
    begin
      nSnapTruck := FieldByName('S_Truck').AsString;
      if nPicName = '' then//默认取最新一次抓拍
        nPicName := FieldByName('S_PicName').AsString;
      if Pos(nTruck,nSnapTruck) > 0 then
      begin
        Result := True;
        nPicName := FieldByName('S_PicName').AsString;
        //取得匹配成功的图片路径

        nData := '车辆[ %s ]识别成功';
        nData := Format(nData, [nTruck,nSnapTruck]);
        FOut.FData := nData;
        Exit;
      end;
      //车牌识别成功
      Next;
    end;
  end;

  nStr := 'Select * From %s Where E_ID=''%s''';
  nStr := Format(nStr, [sTable_ManualEvent, nBill+sFlag_ManualE]);

  with gDBConnManager.WorkerQuery(FDBConn, nStr) do
  begin
    if RecordCount > 0 then
    begin
      if FieldByName('E_Result').AsString = 'N' then
      begin
        nData := '车辆[ %s ]车牌识别失败,抓拍车牌号:[ %s ],管理员禁止进厂';
        nData := Format(nData, [nTruck,nSnapTruck]);
        FOut.FData := nData;
        Exit;
      end;
      if FieldByName('E_Result').AsString = 'Y' then
      begin
        Result := True;
        nData := '车辆[ %s ]车牌识别失败,抓拍车牌号:[ %s ],管理员允许';
        nData := Format(nData, [nTruck,nSnapTruck]);
        FOut.FData := nData;
        Exit;
      end;
      nUpdate := True;
    end
    else
    begin
      nData := '车辆[ %s ]车牌识别失败,抓拍车牌号:[ %s ]';
      nData := Format(nData, [nTruck,nSnapTruck]);
      FOut.FData := nData;
      nUpdate := False;
      if not nNeedManu then
      begin
        Result := True;
        Exit;
      end;
    end;
  end;

  nEvent := '车辆[ %s ]车牌识别失败,抓拍车牌号:[ %s ]';
  nEvent := Format(nEvent, [nTruck,nSnapTruck]);

  nStr := SF('E_ID', nBill+sFlag_ManualE);
  nStr := MakeSQLByStr([
          SF('E_ID', nBill+sFlag_ManualE),
          SF('E_Key', nPicName),
          SF('E_From', nDept),
          SF('E_Result', 'Null', sfVal),

          SF('E_Event', nEvent),
          SF('E_Solution', sFlag_Solution_YN),
          SF('E_Departmen', nDept),
          SF('E_Date', sField_SQLServer_Now, sfVal)
          ], sTable_ManualEvent, nStr, (not nUpdate));
  //xxxxx
  gDBConnManager.WorkerExec(FDBConn, nStr);
end;

//Date: 2019-11-26
//Parm: 车牌号(Truck)
//Desc: 获取车辆类型
function TWorkerBusinessCommander.GetTruckType(var nData: string): Boolean;
var nStr: string;
    nTruck, nBill, nPos, nSnapTruck, nEvent, nDept, nPicName: string;
    nUpdate, nNeedManu: Boolean;
begin
  Result := False;
  FListA.Text := FIn.FData;
  nSnapTruck:= '';
  nEvent:= '' ;
  nNeedManu := False;

  nTruck := FListA.Values['Truck'];

  nStr := 'Select * From %s Where T_Truck=''%s'' ';
  nStr := Format(nStr, [sTable_Truck, nTruck]);
  //xxxxx

  with gDBConnManager.WorkerQuery(FDBConn, nStr) do
  begin
    if RecordCount > 0 then
    begin
      FOut.FData:= FieldByName('T_Type').AsString;
      FOut.FData:= StringReplace(FOut.FData, '型', '', [rfReplaceAll]);
      Result := True;
    end;
  end;
  WriteLog('车辆:'+nTruck+' 型号:'+FOut.FData);
end;


initialization
  gBusinessWorkerManager.RegisteWorker(TBusWorkerQueryField, sPlug_ModuleBus);
  gBusinessWorkerManager.RegisteWorker(TWorkerBusinessCommander, sPlug_ModuleBus);
end.
