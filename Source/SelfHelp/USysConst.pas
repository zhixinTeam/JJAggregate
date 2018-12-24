{*******************************************************************************
  作者: dmzn@ylsoft.com 2007-10-09
  描述: 项目通用常,变量定义单元
*******************************************************************************}
unit USysConst;

interface

uses
  SysUtils, Classes, UBusinessConst, UBusinessWorker, UChannelChooser,
  UMgrChannel, UMgrTTCEDispenser, UClientWorker, UMITPacker, USysMAC,
  UDataModule, USysDB, USysLoger;

const
  cMakeBillLong     = 60;                            //开单时长(秒)
  cShowDlgLong      = 10;                            //显示框(秒)

  cBus_CheckCode    = 10;                            //检查提货码
  cBus_CheckValue   = 20;                            //检查提货量
  cBus_CheckTruck   = 21;                            //检查车牌号
  cBus_BillDone     = 22;                            //开单成功

type
  TSysParam = record
    FUserID     : string;                            //用户标识
    FUserName   : string;                            //当前用户
    FLocalIP    : string;                            //本机IP
    FLocalMAC   : string;                            //本机MAC
    FLocalName  : string;                            //本机名称
    
    FMITServURL : string;                            //业务服务
    FHardMonURL : string;                            //硬件守护
    FWechatURL  : string;                            //微信服务
  end;
  //系统参数

  TZhiKaItem = record
    FCode       : string;                            //提货代码
    FZhiKa      : string;                            //纸卡编号
    FCusID      : string;                            //客户编号
    FCusName    : string;                            //客户名称
    FMoney      : Double;                            //可用金额
    FCard       : string;                            //磁卡编号
    FBill       : string;                            //交货单号
  end;

  TStockItem = record
    FType: string;
    FStockNO: string;
    FStockName: string;
    FPrice: Double;
    FPriceIndex: Integer;
    FValue: Double;
    FSelecte: Boolean;
  end;

  TReaderType = (ptT800, pt8142);
  //表头类型

  TReaderItem = record
    FType: TReaderType;
    FPort: string;
    FBaud: string;
    FDataBit: Integer;
    FStopBit: Integer;
    FCheckMode: Integer;
  end;

  TShowDlg = procedure (nMsg: string; const nTag: Integer = 0;
    const nShow: Boolean = True) of object;
  //对话框
  
var
  gPath: string;                                     //程序所在路径
  gSysParam:TSysParam;                               //程序环境参数
  gReaderItem: TReaderItem;                          //读卡器配置项
  gShowDlg: TShowDlg;                                //弹出式对话框

  gZhiKa: TZhiKaItem;                                //当前纸卡信息
  gStockTypes: TStockTypeItems;                      //价格表
  gStockList: array of TStockItem;                   //可选物料列表

ResourceString
  sHint               = '提示';                      //对话框标题
  sWarn               = '警告';                      //==
  sAsk                = '询问';                      //询问对话框
  sError              = '未知错误';                  //错误对话框

  sDispenser          = 'AICM';                      //发卡机标识
  sConfigFile         = 'Config.Ini';                //主配置文件
  sFormConfig         = 'FormInfo.ini';              //窗体配置
  sDBConfig           = 'DBConn.ini';                //数据连接
  sCloseQuery         = '确定要退出程序吗?';         //主窗口退出

//------------------------------------------------------------------------------
procedure WriteLog(const nEvent: string);
//Desc: 记录日志
procedure InitSystemObject;
//初始化系统对象
function IsZhiKaValid(var nZhiKa,nHint: string;
 const nIsCode: Boolean = False): Boolean;
//纸卡是否有效
function GetZhikaValidMoney(nZhiKa: string): Double;
//纸卡可用金
function IsCustomerCreditValid(const nCusID: string): Boolean;
//验证nCusID是否有足够的钱,或信用没有过期
function LoadStockItemsPrice(const nCusID: string;
  var nItems: TStockTypeItems): Boolean;
//载入客户的价格清单
function SaveBill(const nBillData: string): string;
//保存交货单
function SaveBillCard(const nBill, nCard: string): Boolean;
//保存交货单磁卡

implementation

//Desc: 记录日志
procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(TDispenserManager, '自助业务', nEvent);
end;

//初始化系统对象
procedure InitSystemObject;
var nStr: string;
begin
  gChannelManager := TChannelManager.Create;
  gChannelManager.ChannelMax := 20;
  gChannelChoolser := TChannelChoolser.Create('');
  gChannelChoolser.AutoUpdateLocal := False;
  //channel

  gDispenserManager := TDispenserManager.Create;
  gDispenserManager.LoadConfig(gPath + 'TTCE_K720.xml');
  gDispenserManager.StartDispensers;

  with gSysParam do
  begin
    FUserID := 'AICM';
    FLocalMAC   := MakeActionID_MAC;
    GetLocalIPConfig(FLocalName, FLocalIP);
  end;

  nStr := 'Select D_Value From %s Where D_Name=''%s''';
  nStr := Format(nStr, [sTable_SysDict, sFlag_MITSrvURL]);

  with FDM.SQLQuery(nStr) do
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

  with FDM.SQLQuery(nStr) do
   if RecordCount > 0 then
    gSysParam.FHardMonURL := Fields[0].AsString;
  //xxxxx
end;

//Date: 2014-09-05
//Parm: 命令;数据;参数;输出
//Desc: 调用中间件上的业务命令对象
function CallBusinessCommand(const nCmd: Integer; const nData,nExt: string;
  const nOut: PWorkerBusinessCommand; const nWarn: Boolean = True): Boolean;
var nIn: TWorkerBusinessCommand;
    nWorker: TBusinessWorkerBase;
begin
  nWorker := nil;
  try
    nIn.FCommand := nCmd;
    nIn.FData := nData;
    nIn.FExtParam := nExt;
    nIn.FBase.FParam := sParam_NoHintOnError;

    nWorker := gBusinessWorkerManager.LockWorker(sCLI_BusinessCommand);
    //get worker
    Result := nWorker.WorkActive(@nIn, nOut);

    if not Result then
    begin
      if nWarn then
        gShowDlg(nOut.FBase.FErrDesc);
      WriteLog(nOut.FBase.FErrDesc);
    end;
  finally
    gBusinessWorkerManager.RelaseWorker(nWorker);
  end;
end;

//Date: 2014-09-05
//Parm: 命令;数据;参数;输出
//Desc: 调用中间件上的销售单据对象
function CallBusinessSaleBill(const nCmd: Integer; const nData,nExt: string;
  const nOut: PWorkerBusinessCommand; const nWarn: Boolean = True): Boolean;
var nIn: TWorkerBusinessCommand;
    nWorker: TBusinessWorkerBase;
begin
  nWorker := nil;
  try
    nIn.FCommand := nCmd;
    nIn.FData := nData;
    nIn.FExtParam := nExt;
    nIn.FBase.FParam := sParam_NoHintOnError;

    nWorker := gBusinessWorkerManager.LockWorker(sCLI_BusinessSaleBill);
    //get worker
    Result := nWorker.WorkActive(@nIn, nOut);

    if not Result then
    begin
      if nWarn then
        gShowDlg(nOut.FBase.FErrDesc);
      WriteLog(nOut.FBase.FErrDesc);
    end;
  finally
    gBusinessWorkerManager.RelaseWorker(nWorker);
  end;
end;

//Date: 2014-10-01
//Parm: 命令;数据;参数;输出
//Desc: 调用中间件上的销售单据对象
function CallBusinessHardware(const nCmd: Integer; const nData,nExt: string;
  const nOut: PWorkerBusinessCommand; const nWarn: Boolean = True): Boolean;
var nIn: TWorkerBusinessCommand;
    nWorker: TBusinessWorkerBase;
begin
  nWorker := nil;
  try
    nIn.FCommand := nCmd;
    nIn.FData := nData;
    nIn.FExtParam := nExt;
    nIn.FBase.FParam := sParam_NoHintOnError;

    nWorker := gBusinessWorkerManager.LockWorker(sCLI_HardwareCommand);
    //get worker
    Result := nWorker.WorkActive(@nIn, nOut);

    if not Result then
    begin
      if nWarn then
        gShowDlg(nOut.FBase.FErrDesc);
      WriteLog(nOut.FBase.FErrDesc);
    end;
  finally
    gBusinessWorkerManager.RelaseWorker(nWorker);
  end;
end;

//Date: 2017-10-26
//Parm: 命令;数据;参数;服务地址;输出
//Desc: 调用中间件上的销售单据对象
function CallBusinessWechat(const nCmd: Integer; const nData,nExt,nSrvURL: string;
  const nOut: PWorkerWebChatData; const nWarn: Boolean = True): Boolean;
var nIn: TWorkerWebChatData;
    nWorker: TBusinessWorkerBase;
begin
  nWorker := nil;
  try
    nIn.FCommand := nCmd;
    nIn.FData := nData;
    nIn.FExtParam := nExt;
    nIn.FRemoteUL := nSrvURL;
    nIn.FBase.FParam := sParam_NoHintOnError;

    nWorker := gBusinessWorkerManager.LockWorker(sCLI_BusinessWebchat);
    //get worker
    Result := nWorker.WorkActive(@nIn, nOut);

    if not Result then
    begin
      if nWarn then
        gShowDlg(nOut.FBase.FErrDesc);
      WriteLog(nOut.FBase.FErrDesc);
    end;
  finally
    gBusinessWorkerManager.RelaseWorker(nWorker);
  end;
end;

//------------------------------------------------------------------------------
//Date: 2018-12-14
//Parm: 纸卡号[in,out];提示信息[out]客户编号[out];是提货码
//Desc: 验证nZhiKa是否有效
function IsZhiKaValid(var nZhiKa,nHint: string;
 const nIsCode: Boolean): Boolean;
var nStr: string;
    nOut: TWorkerBusinessCommand;
begin
  if nIsCode then
       nStr := sFlag_Yes
  else nStr := sFlag_No;

  Result := CallBusinessCommand(cBC_CheckZhiKaValid, nZhiKa, nStr, @nOut);
  if Result then
  begin
    nZhiKa := nOut.FData;
    nHint := nOut.FExtParam;
  end else nHint := nOut.FBase.FErrDesc;
end;

//Date: 2014-09-14
//Parm: 纸卡号
//Desc: 获取nZhiKa的可用金
function GetZhikaValidMoney(nZhiKa: string): Double;
var nOut: TWorkerBusinessCommand;
begin
  if CallBusinessCommand(cBC_GetZhiKaMoney, nZhiKa, '', @nOut) then
       Result := StrToFloat(nOut.FData)
  else Result := 0;
end;

//Date: 2014-09-14
//Parm: 客户编号
//Desc: 验证nCusID是否有足够的钱,或信用没有过期
function IsCustomerCreditValid(const nCusID: string): Boolean;
var nOut: TWorkerBusinessCommand;
begin
  if CallBusinessCommand(cBC_CustomerHasMoney, nCusID, '', @nOut) then
       Result := nOut.FData = sFlag_Yes
  else Result := False;
end;

//Date: 2018-12-14
//Parm: 客户编号;价格清单
//Desc: 载入nCusID客户当前的价格清单
function LoadStockItemsPrice(const nCusID: string;
  var nItems: TStockTypeItems): Boolean;
var nOut: TWorkerBusinessCommand;
begin
  Result := CallBusinessCommand(cBC_GetCustomerPrice, nCusID, '', @nOut);
  if Result then
       AnalyseTypeItems(nOut.FData, nItems)
  else SetLength(nItems, 0);
end;

//Date: 2014-09-15
//Parm: 开单数据
//Desc: 保存交货单,返回交货单号列表
function SaveBill(const nBillData: string): string;
var nOut: TWorkerBusinessCommand;
begin
  if CallBusinessSaleBill(cBC_SaveBills, nBillData, '', @nOut) then
       Result := nOut.FData
  else Result := '';
end;

//Date: 2014-09-17
//Parm: 交货单号;磁卡
//Desc: 绑定nBill.nCard
function SaveBillCard(const nBill, nCard: string): Boolean;
var nOut: TWorkerBusinessCommand;
begin
  Result := CallBusinessSaleBill(cBC_SaveBillCard, nBill, nCard, @nOut);
end;

end.


