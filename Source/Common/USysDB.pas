{*******************************************************************************
  作者: dmzn@163.com 2008-08-07
  描述: 系统数据库常量定义

  备注:
  *.自动创建SQL语句,支持变量:$Inc,自增;$Float,浮点;$Integer=sFlag_Integer;
    $Decimal=sFlag_Decimal;$Image,二进制流
*******************************************************************************}
unit USysDB;

{$I Link.inc}
interface

uses
  SysUtils, Classes;

const
  cSysDatabaseName: array[0..4] of String = (
     'Access', 'SQL', 'MySQL', 'Oracle', 'DB2');
  //db names

  cPrecision            = 100;
  {-----------------------------------------------------------------------------
   描述: 计算精度
   *.重量为吨的计算中,小数值比较或者相减运算时会有误差,所以会先放大,去掉
     小数位后按照整数计算.放大倍数由精度值确定.
  -----------------------------------------------------------------------------}

type
  TSysDatabaseType = (dtAccess, dtSQLServer, dtMySQL, dtOracle, dtDB2);
  //db types

  PSysTableItem = ^TSysTableItem;
  TSysTableItem = record
    FTable: string;
    FNewSQL: string;
  end;
  //系统表项

var
  gSysTableList: TList = nil;                        //系统表数组
  gSysDBType: TSysDatabaseType = dtSQLServer;        //系统数据类型

//------------------------------------------------------------------------------
const
  //自增字段
  sField_Access_AutoInc          = 'Counter';
  sField_SQLServer_AutoInc       = 'Integer IDENTITY (1,1) PRIMARY KEY';

  //小数字段
  sField_Access_Decimal          = 'Float';
  sField_SQLServer_Decimal       = 'Decimal(15, 5)';

  //图片字段
  sField_Access_Image            = 'OLEObject';
  sField_SQLServer_Image         = 'Image';

  //日期相关
  sField_SQLServer_Now           = 'getDate()';

  {*权限项*}
  sPopedom_Read       = 'A';                         //浏览
  sPopedom_Add        = 'B';                         //添加
  sPopedom_Edit       = 'C';                         //修改
  sPopedom_Delete     = 'D';                         //删除
  sPopedom_Preview    = 'E';                         //预览
  sPopedom_Print      = 'F';                         //打印
  sPopedom_Export     = 'G';                         //导出
  sPopedom_ViewPrice  = 'H';                         //查看单价

  {*数据库标识*}
  sFlag_DB_K3         = 'King_K3';                   //金蝶数据库
  sFlag_DB_NC         = 'YonYou_NC';                 //用友数据库

  {*相关标记*}
  sFlag_Yes           = 'Y';                         //是
  sFlag_No            = 'N';                         //否
  sFlag_Unknow        = 'U';                         //未知 
  sFlag_Enabled       = 'Y';                         //启用
  sFlag_Disabled      = 'N';                         //禁用

  sFlag_Integer       = 'I';                         //整数
  sFlag_Decimal       = 'D';                         //小数

  sFlag_ManualNo      = '%';                         //手动指定(非系统自动)
  sFlag_NotMatter     = '@';                         //无关编号(任意编号都可)
  sFlag_ForceDone     = '#';                         //强制完成(未完成前不换)
  sFlag_FixedNo       = '$';                         //指定编号(使用相同编号)

  sFlag_Provide       = 'P';                         //供应
  sFlag_Sale          = 'S';                         //销售
  sFlag_Returns       = 'R';                         //退货
  sFlag_Other         = 'O';                         //其它
  
  sFlag_TiHuo         = 'T';                         //自提
  sFlag_SongH         = 'S';                         //送货
  sFlag_XieH          = 'X';                         //运卸

  sFlag_Dai           = 'D';                         //袋装水泥
  sFlag_San           = 'S';                         //散装水泥

  sFlag_PriceLS       = 'L';                         //零售价
  sFlag_PriceQY       = 'Q';                         //区域价
  sFlag_PriceZY       = 'Z';                         //客户专用

  sFlag_BillNew       = 'N';                         //新单
  sFlag_BillEdit      = 'E';                         //修改
  sFlag_BillDel       = 'D';                         //删除
  sFlag_BillLading    = 'L';                         //提货中
  sFlag_BillPick      = 'P';                         //拣配
  sFlag_BillPost      = 'G';                         //过账
  sFlag_BillDone      = 'O';                         //完成

  sFlag_OrderNew       = 'N';                        //新单
  sFlag_OrderEdit      = 'E';                        //修改
  sFlag_OrderDel       = 'D';                        //删除
  sFlag_OrderPuring    = 'L';                        //送货中
  sFlag_OrderDone      = 'O';                        //完成
  sFlag_OrderAbort     = 'A';                        //废弃
  sFlag_OrderStop      = 'S';                        //终止

  sFlag_OrderCardL     = 'L';                        //临时
  sFlag_OrderCardG     = 'G';                        //固定

  sFlag_TypeShip      = 'S';                         //船运
  sFlag_TypeZT        = 'Z';                         //栈台
  sFlag_TypeVIP       = 'V';                         //VIP
  sFlag_TypeCommon    = 'C';                         //普通,订单类型

  sFlag_CardIdle      = 'I';                         //空闲卡
  sFlag_CardUsed      = 'U';                         //使用中
  sFlag_CardLoss      = 'L';                         //挂失卡
  sFlag_CardInvalid   = 'N';                         //注销卡

  sFlag_TruckNone     = 'N';                         //无状态车辆
  sFlag_TruckIn       = 'I';                         //进厂车辆
  sFlag_TruckOut      = 'O';                         //出厂车辆
  sFlag_TruckBFP      = 'P';                         //磅房皮重车辆
  sFlag_TruckBFM      = 'M';                         //磅房毛重车辆
  sFlag_TruckSH       = 'S';                         //送货车辆
  sFlag_TruckFH       = 'F';                         //放灰车辆
  sFlag_TruckZT       = 'Z';                         //栈台车辆
  sFlag_TruckXH       = 'X';                         //验收车辆

  sFlag_TJNone        = 'N';                         //未调价
  sFlag_TJing         = 'T';                         //调价中
  sFlag_TJOver        = 'O';                         //调价完成

  sFlag_PoundBZ       = 'B';                         //标准
  sFlag_PoundPZ       = 'Z';                         //皮重
  sFlag_PoundPD       = 'P';                         //配对
  sFlag_PoundCC       = 'C';                         //出厂(过磅模式)
  sFlag_PoundLS       = 'L';                         //临时

  sFlag_MoneyHuiKuan  = 'R';                         //回款入金
  sFlag_MoneyJiaCha   = 'C';                         //补缴价差
  sFlag_MoneyZhiKa    = 'Z';                         //纸卡回款
  sFlag_MoneyFanHuan  = 'H';                         //返还用户

  sFlag_InvNormal     = 'N';                         //正常发票
  sFlag_InvHasUsed    = 'U';                         //已用发票
  sFlag_InvInvalid    = 'V';                         //作废发票
  sFlag_InvRequst     = 'R';                         //申请开出
  sFlag_InvDaily      = 'D';                         //日常开出

  sFlag_ManualA       = 'A';                         //皮重预警(错误事件类型)
  sFlag_ManualB       = 'B';                         //皮重超出范围
  sFlag_ManualC       = 'C';                         //净重超出误差范围
  sFlag_ManualD       = 'D';                         //空车出厂
  sFlag_ManualE       = 'E';                         //车牌识别
  sFlag_ManualF       = 'F';                         //交货单余额不足

  sFlag_FactoryID     = 'FactoryID';                 //工厂编号
  sFlag_SysParam      = 'SysParam';                  //系统参数
  sFlag_EnableBakdb   = 'Uses_BackDB';               //备用库
  sFlag_ValidDate     = 'SysValidDate';              //有效期
  sFlag_ZhiKaVerify   = 'ZhiKaVerify';               //纸卡审核
  sFlag_ZKMinMoney    = 'ZhiKaMinMoney';             //纸卡最小金额
  sFlag_PrintZK       = 'PrintZK';                   //打印纸卡
  sFlag_PrintBill     = 'PrintStockBill';            //需打印订单
  sFlag_BillMinValue  = 'LimitBillMinValue';         //显示最小开单量
  sFlag_ViaBillCard   = 'ViaBillCard';               //直接制卡
  sFlag_PayCredit     = 'Pay_Credit';                //回款冲信用
  sFlag_CreditVerify  = 'CreditVerify';              //信用审核
  sFlag_VerifyTruckP  = 'VerifyTruckP';              //校验预置皮重
  sFlag_AutoIn        = 'Truck_AutoIn';              //自动进厂
  sFlag_AutoOut       = 'Truck_AutoOut';             //自动出厂
  sFlag_InTimeout     = 'InFactTimeOut';             //进厂超时(队列)
  sFlag_NoDaiQueue    = 'NoDaiQueue';                //袋装禁用队列
  sFlag_NoSanQueue    = 'NoSanQueue';                //散装禁用队列
  sFlag_DelayQueue    = 'DelayQueue';                //延迟排队(厂内)
  sFlag_PoundQueue    = 'PoundQueue';                //延迟排队(厂内依据过皮时间)
  sFlag_NetPlayVoice  = 'NetPlayVoice';              //使用网络语音播发
  sFlag_BatchAuto     = 'BatchAuto';                 //使用自动批次号

  sFlag_PDaiWuChaZ    = 'PoundDaiWuChaZ';            //袋装正误差
  sFlag_PDaiWuChaF    = 'PoundDaiWuChaF';            //袋装负误差
  sFlag_PDaiPercent   = 'PoundDaiPercent';           //按比例计算误差
  sFlag_PDaiWuChaStop = 'PoundDaiWuChaStop';         //误差时停止业务
  sFlag_PSanWuChaF    = 'PoundSanWuChaF';            //散装负误差
  sFlag_PoundWuCha    = 'PoundWuCha';                //过磅误差分组
  sFlag_PoundIfDai    = 'PoundIFDai';                //袋装是否过磅
  sFlag_NFStock       = 'NoFaHuoStock';              //现场无需发货
  sFlag_StrictSanVal  = 'StrictSanVal';              //严格控制散装超发
  sFlag_PEmpTWuCha    = 'EmpTruckWuCha';             //空车出厂误差
  sFlag_DefaultPValue = 'DefaultPValue';             //默认皮重
  sFlag_PValueWuCha   = 'PValueWuCha';               //皮重误差范围

  sFlag_WXFactory     = 'WXFactoryID';               //微信标识
  sFlag_WXServiceMIT  = 'WXServiceMIT';              //微信工厂服务
  sFlag_WXSrvRemote   = 'WXServiceRemote';           //微信远程服务

  sFlag_CommonItem    = 'CommonItem';                //公共信息
  sFlag_CardItem      = 'CardItem';                  //磁卡信息项
  sFlag_AreaItem      = 'AreaItem';                  //区域信息项
  sFlag_TruckItem     = 'TruckItem';                 //车辆信息项
  sFlag_TruckPrefix   = 'TruckPrefix';               //车牌前缀
  sFlag_CustomerItem  = 'CustomerItem';              //客户信息项
  sFlag_BankItem      = 'BankItem';                  //银行信息项
  sFlag_UserLogItem   = 'UserLogItem';               //用户登录项

  sFlag_StockItem     = 'StockItem';                 //水泥信息项
  sFlag_ContractItem  = 'ContractItem';              //合同信息项
  sFlag_SalesmanItem  = 'SalesmanItem';              //业务员信息项
  sFlag_ZhiKaItem     = 'ZhiKaItem';                 //纸卡信息项
  sFlag_BillItem      = 'BillItem';                  //提单信息项
  sFlag_TruckQueue    = 'TruckQueue';                //车辆队列

  sFlag_PaymentItem   = 'PaymentItem';               //付款方式信息项
  sFlag_PaymentItem2  = 'PaymentItem2';              //销售回款信息项
  sFlag_OrderItem     = 'OrderItem';                 //采购订单信息项

  sFlag_ProviderItem  = 'ProviderItem';              //供应商信息项
  sFlag_MaterailsItem = 'MaterailsItem';             //原材料信息项

  sFlag_HardSrvURL    = 'HardMonURL';
  sFlag_MITSrvURL     = 'MITServiceURL';             //服务地址

  sFlag_WXSrvURL      = 'WXServiceURL';
  sFlag_WXFactoryID   = 'WXFactoryID';               //微信服务

  sFlag_BusGroup      = 'BusFunction';               //业务编码组
  sFlag_BillNo        = 'Bus_Bill';                  //交货单号
  sFlag_PoundID       = 'Bus_Pound';                 //称重记录
  sFlag_Customer      = 'Bus_Customer';              //客户编号
  sFlag_SaleMan       = 'Bus_SaleMan';               //业务员编号
  sFlag_Contract      = 'Bus_Contract';              //合同编号
  sFlag_ZhiKa         = 'Bus_ZhiKa';                 //纸卡编号
  sFlag_PriceWeek     = 'Bus_PriceWeek';             //价格周期
  sFlag_InvWeek       = 'Bus_InvoiceWeek';           //结算周期
  sFlag_WeiXin        = 'Bus_WeiXin';                //微信映射编号
  sFlag_HYDan         = 'Bus_HYDan';                 //化验单号
  sFlag_ForceHint     = 'Bus_HintMsg';               //强制提示
  sFlag_Order         = 'Bus_Order';                 //采购单号
  sFlag_OrderDtl      = 'Bus_OrderDtl';              //采购单号
  sFlag_OrderBase     = 'Bus_OrderBase';             //采购申请单号

  sFlag_Departments   = 'Departments';               //部门列表
  sFlag_DepDaTing     = '大厅';                      //服务大厅
  sFlag_DepJianZhuang = '监装';                      //监装
  sFlag_DepBangFang   = '磅房';                      //磅房
  sFlag_DepHuaYan     = '化验室';                    //化验室

  sFlag_Solution_YN   = 'Y=通过;N=禁止';
  sFlag_Solution_YNI  = 'Y=通过;N=禁止;I=忽略';
  sFlag_Solution_OK   = 'O=知道了';

  sFlag_LSStock       = 'ls-sn-00';                  //零售水泥编号(预开)
  sFlag_LSCustomer    = 'ls-kh-00';                  //零售客户编号(预开)

  sFlag_WxItem        = 'WxItem';                    //微信相关
  sFlag_InOutBegin    = 'BeginTime';                 //进出厂查询起始时间
  sFlag_InOutEnd      = 'EndTime';                   //进出厂查询结束时间

  sFlag_TruckInNeedManu = 'TruckNeedManu';           //车牌识别需人工干预

  {*数据表*}
  sTable_Group        = 'Sys_Group';                 //用户组
  sTable_User         = 'Sys_User';                  //用户表
  sTable_Menu         = 'Sys_Menu';                  //菜单表
  sTable_Popedom      = 'Sys_Popedom';               //权限表
  sTable_PopItem      = 'Sys_PopItem';               //权限项
  sTable_Entity       = 'Sys_Entity';                //字典实体
  sTable_DictItem     = 'Sys_DataDict';              //字典明细

  sTable_SysDict      = 'Sys_Dict';                  //系统字典
  sTable_ExtInfo      = 'Sys_ExtInfo';               //附加信息
  sTable_SysLog       = 'Sys_EventLog';              //系统日志
  sTable_BaseInfo     = 'Sys_BaseInfo';              //基础信息
  sTable_SerialBase   = 'Sys_SerialBase';            //编码种子
  sTable_SerialStatus = 'Sys_SerialStatus';          //编号状态
  sTable_WorkePC      = 'Sys_WorkePC';               //验证授权
  sTable_Factorys     = 'Sys_Factorys';              //工厂列表
  sTable_ManualEvent  = 'Sys_ManualEvent';           //人工干预
  sTable_WeixinLog    = 'Sys_WeixinLog';             //微信日志

  sTable_PriceWeek    = 'S_PriceWeek';               //价格周期
  sTable_PriceRule    = 'S_PriceRule';               //价格规则
  sTable_Customer     = 'S_Customer';                //客户信息
  sTable_Salesman     = 'S_Salesman';                //业务人员

  sTable_ZhiKa        = 'S_ZhiKa';                   //纸卡数据
  sTable_ZhiKaDtl     = 'S_ZhiKaDtl';                //纸卡明细
  sTable_Card         = 'S_Card';                    //销售磁卡
  sTable_Bill         = 'S_Bill';                    //提货单
  sTable_BillBak      = 'S_BillBak';                 //已删交货单

  sTable_StockMatch   = 'S_StockMatch';              //品种映射
  sTable_StockParam   = 'S_StockParam';              //品种参数
  sTable_StockParamExt= 'S_StockParamExt';           //参数扩展
  sTable_StockRecord  = 'S_StockRecord';             //检验记录
  sTable_StockHuaYan  = 'S_StockHuaYan';             //开化验单
  sTable_StockBatcode = 'S_Batcode';                 //批次号
  sFlag_HYValue       = 'HYMaxValue';                //化验批次量

  sTable_Truck        = 'S_Truck';                   //车辆表
  sTable_TruckPlan    = 'S_TruckPlan';               //派车单
  sTable_ZTLines      = 'S_ZTLines';                 //装车道
  sTable_ZTTrucks     = 'S_ZTTrucks';                //车辆队列

  sTable_Provider     = 'P_Provider';                //客户表
  sTable_Materails    = 'P_Materails';               //物料表
  sTable_Order        = 'P_Order';                   //采购订单
  sTable_OrderBak     = 'P_OrderBak';                //已删除采购订单
  sTable_OrderBase    = 'P_OrderBase';               //采购申请订单
  sTable_OrderBaseBak = 'P_OrderBaseBak';            //已删除采购申请订单
  sTable_OrderDtl     = 'P_OrderDtl';                //采购订单明细
  sTable_OrderDtlBak  = 'P_OrderDtlBak';             //采购订单明细
  
  sTable_CusAccount   = 'Sys_CustomerAccount';       //客户账户
  sTable_InOutMoney   = 'Sys_CustomerInOutMoney';    //资金明细
  sTable_CusCredit    = 'Sys_CustomerCredit';        //客户信用
  sTable_SysShouJu    = 'Sys_ShouJu';                //收据记录

  sTable_PoundLog     = 'Sys_PoundLog';              //过磅数据
  sTable_PoundBak     = 'Sys_PoundBak';              //过磅作废
  sTable_Picture      = 'Sys_Picture';               //存放图片
  sTable_PoundDaiWC   = 'Sys_PoundDaiWuCha';         //包装误差
  sTable_SnapTruck    = 'Sys_SnapTruck';             //车辆抓拍记录

  {*新建表*}
  sSQL_NewSysDict = 'Create Table $Table(D_ID $Inc, D_Name varChar(15),' +
       'D_Desc varChar(30), D_Value varChar(50), D_Memo varChar(20),' +
       'D_ParamA $Float, D_ParamB varChar(50), D_ParamC varChar(50),' +
       'D_Index Integer Default 0)';
  {-----------------------------------------------------------------------------
   系统字典: SysDict
   *.D_ID: 编号
   *.D_Name: 名称
   *.D_Desc: 描述
   *.D_Value: 取值
   *.D_Memo: 相关信息
   *.D_ParamA: 浮点参数
   *.D_ParamB: 字符参数
   *.D_ParamC: 字符参数
   *.D_Index: 显示索引
  -----------------------------------------------------------------------------}
  
  sSQL_NewExtInfo = 'Create Table $Table(I_ID $Inc, I_Group varChar(20),' +
       'I_ItemID varChar(20), I_Item varChar(30), I_Info varChar(500),' +
       'I_ParamA $Float, I_ParamB varChar(50), I_Index Integer Default 0)';
  {-----------------------------------------------------------------------------
   扩展信息表: ExtInfo
   *.I_ID: 编号
   *.I_Group: 信息分组
   *.I_ItemID: 信息标识
   *.I_Item: 信息项
   *.I_Info: 信息内容
   *.I_ParamA: 浮点参数
   *.I_ParamB: 字符参数
   *.I_Memo: 备注信息
   *.I_Index: 显示索引
  -----------------------------------------------------------------------------}
  
  sSQL_NewSysLog = 'Create Table $Table(L_ID $Inc, L_Date DateTime,' +
       'L_Man varChar(32),L_Group varChar(20), L_ItemID varChar(20),' +
       'L_KeyID varChar(20), L_Event varChar(220))';
  {-----------------------------------------------------------------------------
   系统日志: SysLog
   *.L_ID: 编号
   *.L_Date: 操作日期
   *.L_Man: 操作人
   *.L_Group: 信息分组
   *.L_ItemID: 信息标识
   *.L_KeyID: 辅助标识
   *.L_Event: 事件
  -----------------------------------------------------------------------------}

  sSQL_NewBaseInfo = 'Create Table $Table(B_ID $Inc, B_Group varChar(15),' +
       'B_Text varChar(100), B_Py varChar(25), B_Memo varChar(50),' +
       'B_PID Integer, B_Index Float)';
  {-----------------------------------------------------------------------------
   基本信息表: BaseInfo
   *.B_ID: 编号
   *.B_Group: 分组
   *.B_Text: 内容
   *.B_Py: 拼音简写
   *.B_Memo: 备注信息
   *.B_PID: 上级节点
   *.B_Index: 创建顺序
  -----------------------------------------------------------------------------}

  sSQL_NewSerialBase = 'Create Table $Table(R_ID $Inc, B_Group varChar(15),' +
       'B_Object varChar(32), B_Prefix varChar(25), B_IDLen Integer,' +
       'B_Base Integer, B_Date DateTime)';
  {-----------------------------------------------------------------------------
   串行编号基数表: SerialBase
   *.R_ID: 编号
   *.B_Group: 分组
   *.B_Object: 对象
   *.B_Prefix: 前缀
   *.B_IDLen: 编号长
   *.B_Base: 基数
   *.B_Date: 参考日期
  -----------------------------------------------------------------------------}

  sSQL_NewSerialStatus = 'Create Table $Table(R_ID $Inc, S_Object varChar(32),' +
       'S_SerailID varChar(32), S_PairID varChar(32), S_Status Char(1),' +
       'S_Date DateTime)';
  {-----------------------------------------------------------------------------
   串行状态表: SerialStatus
   *.R_ID: 编号
   *.S_Object: 对象
   *.S_SerailID: 串行编号
   *.S_PairID: 配对编号
   *.S_Status: 状态(Y,N)
   *.S_Date: 创建时间
  -----------------------------------------------------------------------------}

  sSQL_NewWorkePC = 'Create Table $Table(R_ID $Inc, W_Name varChar(100),' +
       'W_MAC varChar(32), W_Factory varChar(32), W_Serial varChar(32),' +
       'W_Departmen varChar(32), W_ReqMan varChar(32), W_ReqTime DateTime,' +
       'W_RatifyMan varChar(32), W_RatifyTime DateTime,' +
       'W_PoundID varChar(50), W_MITUrl varChar(128), W_HardUrl varChar(128),' +
       'W_Valid Char(1))';
  {-----------------------------------------------------------------------------
   工作授权: WorkPC
   *.R_ID: 编号
   *.W_Name: 电脑名称
   *.W_MAC: MAC地址
   *.W_Factory: 工厂编号
   *.W_Departmen: 部门
   *.W_Serial: 编号
   *.W_ReqMan,W_ReqTime: 接入申请
   *.W_RatifyMan,W_RatifyTime: 批准
   *.W_PoundID:磅站编号
   *.W_MITUrl:业务服务
   *.W_HardUrl:硬件服务
   *.W_Valid: 有效(Y/N)
  -----------------------------------------------------------------------------}

  sSQL_NewFactorys = 'Create Table $Table(R_ID $Inc, F_ID varChar(32),' +
       'F_Name varChar(100), F_MITUrl varChar(128), F_HardUrl varChar(128),' +
       'F_WechatUrl varChar(128), F_DBConn varChar(500),' +
       'F_Valid Char(1), F_Index Integer)';
  {-----------------------------------------------------------------------------
   工厂列表: Factorys
   *.R_ID: 编号
   *.F_ID: 工厂编号
   *.F_Name: 工厂名称
   *.F_MITUrl: 中间件地址
   *.F_HardUrl: 硬件守护地址
   *.F_WechatUrl: 微信服务地址
   *.F_DBConn: 数据库连接配置
   *.F_Valid: 有效(Y/N)
   *.F_Index: 加载顺序
  -----------------------------------------------------------------------------}

  sSQL_NewManualEvent = 'Create Table $Table(R_ID $Inc, E_ID varChar(32),' +
       'E_From varChar(32), E_Key varChar(32), E_Event varChar(200), ' +
       'E_Solution varChar(100), E_Result varChar(12),E_Departmen varChar(32),' +
       'E_Date DateTime, E_ManDeal varChar(32), E_DateDeal DateTime, ' +
       'E_ParamA Integer, E_ParamB varChar(128), E_Memo varChar(512))';
  {-----------------------------------------------------------------------------
   人工干预事件: ManualEvent
   *.R_ID: 编号
   *.E_ID: 流水号
   *.E_From: 来源
   *.E_Key: 记录标识
   *.E_Event: 事件
   *.E_Solution: 处理方案(格式如: Y=通过;N=禁止) 
   *.E_Result: 处理结果(Y/N)
   *.E_Departmen: 处理部门
   *.E_Date: 发生时间
   *.E_ManDeal,E_DateDeal: 处理人
   *.E_ParamA: 附加参数, 整型
   *.E_ParamB: 附加参数, 字符串
   *.E_Memo: 备注信息
  -----------------------------------------------------------------------------}

  sSQL_NewSyncItem = 'Create Table $Table(R_ID $Inc, S_Table varChar(100),' +
       'S_Action Char(1), S_Record varChar(32), S_Param1 varChar(100),' +
       'S_Param2 $Float, S_Time DateTime)';
  {-----------------------------------------------------------------------------
   同步数据项: SyncItem
   *.R_ID: 编号
   *.S_Table: 表名称
   *.S_Action: 增删改(A,E,D)
   *.S_Record: 记录编号
   *.S_Param1,S_Param2: 参数
   *.S_Time: 时间
  -----------------------------------------------------------------------------}

  sSQL_NewStockMatch = 'Create Table $Table(R_ID $Inc, M_Group varChar(8),' +
       'M_ID varChar(20), M_Name varChar(80), M_Status Char(1))';
  {-----------------------------------------------------------------------------
   相似品种映射: StockMatch
   *.R_ID: 记录编号
   *.M_Group: 分组
   *.M_ID: 物料号
   *.M_Name: 物料名称
   *.M_Status: 状态
  -----------------------------------------------------------------------------}
  
  sSQL_NewSalesMan = 'Create Table $Table(R_ID $Inc, S_ID varChar(15),' +
       'S_Name varChar(30), S_PY varChar(30), S_Phone varChar(20),' +
       'S_Area varChar(50), S_InValid Char(1), S_Memo varChar(50))';
  {-----------------------------------------------------------------------------
   业务员表: SalesMan
   *.R_ID: 记录号
   *.S_ID: 编号
   *.S_Name: 名称
   *.S_PY: 简拼
   *.S_Phone: 联系方式
   *.S_Area:所在区域
   *.S_InValid: 已无效
   *.S_Memo: 备注
  -----------------------------------------------------------------------------}

  sSQL_NewPriceWeek = 'Create Table $Table(W_ID $Inc, W_NO varChar(15),' +
       'W_Name varChar(50), W_Begin DateTime, W_End DateTime,' +
       'W_EndUse Char(1), W_Man varChar(32), W_Date DateTime,' +
       'W_Valid Char(1), W_ValidTime DateTime, W_Memo varChar(50))';
  {-----------------------------------------------------------------------------
   价格周期: PriceWeek
   *.W_ID:记录编号
   *.W_NO:周期编号
   *.W_Name:名称
   *.W_Begin:开始
   *.W_End:结束
   *.W_EndUse:是否启用,若启用为临时价
   *.W_Man:创建人
   *.W_Date:创建时间
   *.W_Valid: 是否生效(Y/N)
   *.W_ValidTime: 生效时间
   *.W_Memo:备注信息
  -----------------------------------------------------------------------------}
  
  sSQL_NewPriceRule = 'Create Table $Table(R_ID $Inc, R_Week varChar(15),' +
       'R_Type varChar(5), R_Area varChar(50), R_Customer varChar(15),' +
       'R_StockNo varChar(20), R_StockName varChar(80), R_Price $Float,' +
       'R_Man varChar(32), R_Date DateTime)';
  {-----------------------------------------------------------------------------
   价格规则:PriceRule
   *.R_ID:记录编号
   *.R_Week: 所属周期
   *.R_Type: 类型
   *.R_Area: 所属区域
   *.R_Customer: 所属客户
   *.R_StockNo,R_StockName: 物料名称
   *.R_Price: 价格
   *.R_Man: 办理人
   *.R_Date: 办理时间
  -----------------------------------------------------------------------------}

  sSQL_NewCustomer = 'Create Table $Table(R_ID $Inc, C_ID varChar(15), ' +
       'C_Name varChar(80), C_PY varChar(80), C_Addr varChar(100), ' +
       'C_FaRen varChar(50), C_LiXiRen varChar(50), C_WeiXin varChar(50),' +
       'C_Phone varChar(15), C_Fax varChar(15), C_Tax varChar(32),' +
       'C_Bank varChar(35), C_Account varChar(18), C_SaleMan varChar(15),' +
       'C_Param varChar(32), C_Memo varChar(50), C_XuNi Char(1),' +
       'C_Area varChar(50), C_FL Char(1))';
  {-----------------------------------------------------------------------------
   客户信息表: Customer
   *.R_ID: 记录号
   *.C_ID: 编号
   *.C_Name: 名称
   *.C_PY: 拼音简写
   *.C_Addr: 地址
   *.C_FaRen: 法人
   *.C_LiXiRen: 联系人
   *.C_Phone: 电话
   *.C_WeiXin: 微信
   *.C_Fax: 传真
   *.C_Tax: 税号
   *.C_Bank: 开户行
   *.C_Account: 帐号
   *.C_SaleMan: 业务员
   *.C_Param: 备用参数
   *.C_Memo: 备注信息
   *.C_XuNi: 虚拟(临时)客户
   *.C_Area: 所属区域
   *.C_FL:  是否返利客户
  -----------------------------------------------------------------------------}
  
  sSQL_NewCusAccount = 'Create Table $Table(R_ID $Inc, A_CID varChar(15),' +
       'A_Used Char(1), A_InMoney Decimal(15,5) Default 0,' +
       'A_OutMoney Decimal(15,5) Default 0, A_DebtMoney Decimal(15,5) Default 0,' +
       'A_Compensation Decimal(15,5) Default 0,' +
       'A_InitMoney Decimal(15,5) Default 0,' +
       'A_FreezeMoney Decimal(15,5) Default 0,' +
       'A_CreditLimit Decimal(15,5) Default 0, A_Date DateTime)';
  {-----------------------------------------------------------------------------
   客户账户:CustomerAccount
   *.R_ID:记录编号
   *.A_CID:客户号
   *.A_Used:用途(供应,销售)
   *.A_InitMoney:初始额度
   *.A_InMoney:入金
   *.A_OutMoney:出金
   *.A_DebtMoney:欠款
   *.A_Compensation:补偿金
   *.A_FreezeMoney:冻结资金
   *.A_CreditLimit:信用额度
   *.A_Date:创建日期

   *.水泥销售账中
     A_InitMoney:客户初始账户金额
     A_InMoney:客户存入账户的金额
     A_OutMoney:客户实际花费的金额
     A_DebtMoney:还未支付的金额
     A_Compensation:由于差价退还给客户的金额
     A_FreezeMoney:已办纸卡但未进厂提货的金额
     A_CreditLimit:授信给用户的最高可欠款金额

     可用余额 = 期初 + 入金 + 信用额 - 出金 - 补偿金 - 已冻结
     消费总额 = 出金 + 欠款 + 已冻结
  -----------------------------------------------------------------------------}

  sSQL_NewInOutMoney = 'Create Table $Table(R_ID $Inc, M_SaleMan varChar(15),' +
       'M_CusID varChar(15), M_CusName varChar(80), ' +
       'M_Type Char(1), M_Payment varChar(20),' +
       'M_Money Decimal(15,5), M_ZID varChar(15), M_Date DateTime,' +
       'M_Man varChar(32), M_Memo varChar(200))';
  {-----------------------------------------------------------------------------
   出入金明细:CustomerInOutMoney
   *.M_ID:记录编号
   *.M_SaleMan:业务员
   *.M_CusID:客户号
   *.M_CusName:客户名
   *.M_Type:类型(补差,回款等)
   *.M_Payment:付款方式
   *.M_Money:缴纳金额
   *.M_ZID:纸卡号
   *.M_Date:操作日期
   *.M_Man:操作人
   *.M_Memo:描述

   *.水泥销售入金中
     金额 = 单价 x 数量 + 其它
  -----------------------------------------------------------------------------}

  sSQL_NewSysShouJu = 'Create Table $Table(R_ID $Inc ,S_Code varChar(15),' +
       'S_Sender varChar(100), S_Reason varChar(100), S_Money Decimal(15,5),' +
       'S_BigMoney varChar(50), S_Bank varChar(35), S_Man varChar(32),' +
       'S_Date DateTime, S_Memo varChar(50))';
  {-----------------------------------------------------------------------------
   收据明细:ShouJu
   *.R_ID:编号
   *.S_Code:记账凭单号码
   *.S_Sender:兹由(来源)
   *.S_Reason:交来(事务)
   *.S_Money:金额
   *.S_Bank:银行
   *.S_Man:出纳员
   *.S_Date:日期
   *.S_Memo:备注
  -----------------------------------------------------------------------------}

  sSQL_NewCusCredit = 'Create Table $Table(R_ID $Inc ,C_CusID varChar(15),' +
       'C_Money Decimal(15,5), C_Man varChar(32), C_Date DateTime, ' +
       'C_End DateTime, C_Verify Char(1) Default ''N'', C_VerMan varChar(32),' +
       'C_VerDate DateTime, C_Memo varChar(50))';
  {-----------------------------------------------------------------------------
   信用明细:CustomerCredit
   *.R_ID:编号
   *.C_CusID:客户编号
   *.C_Money:授信额
   *.C_Man:操作人
   *.C_Date:日期
   *.C_End: 有效期
   *.C_Verify: 已审核(Y/N)
   *.C_VerMan,C_VerDate: 审核
   *.C_Memo:备注
  -----------------------------------------------------------------------------}

  sSQL_NewZhiKa = 'Create Table $Table(R_ID $Inc, Z_ID varChar(15),' +
       'Z_Name varChar(100), Z_Card varChar(16), Z_Project varChar(100),' +
       'Z_Customer varChar(15), Z_SaleMan varChar(15), Z_Lading Char(1),' +
       'Z_ValidDays DateTime, Z_Password varChar(16),' + 
       'Z_Money $Float, Z_MoneyUsed $Float, Z_MoneyAll Char(1),' +
       'Z_Verified Char(1), Z_VerifyMan varChar(32), Z_VerifyDate DateTime,' +
       'Z_InValid Char(1), Z_Freeze Char(1),' +
       'Z_Man varChar(32), Z_Date DateTime, Z_Memo varChar(200))';
  {-----------------------------------------------------------------------------
   纸卡办理: ZhiKa
   *.R_ID:记录编号
   *.Z_ID:纸卡号
   *.Z_Name:纸卡名称
   *.Z_Card:磁卡号
   *.Z_Project:项目名称
   *.Z_Customer:客户编号
   *.Z_SaleMan:业务员
   *.Z_Lading:提货方式(自提,送货)
   *.Z_ValidDays:有效期
   *.Z_Password: 密码
   *.Z_Money:可用金
   *.Z_MoneyUsed: 已使用(出金)
   *.Z_MoneyAll: 使用全部
   *.Z_Verified:已审核
   *.Z_VerifyMan: 审核人
   *.Z_VerifyDate: 审核时间
   *.Z_InValid:已无效
   *.Z_Freeze:已冻结
   *.Z_Man:操作人
   *.Z_Date:创建时间
  -----------------------------------------------------------------------------}

  sSQL_NewZhiKaDtl = 'Create Table $Table(R_ID $Inc, D_ZID varChar(15),' +
       'D_Type Char(1), D_StockNo varChar(20), D_StockName varChar(80),' +
       'D_Price $Float, D_Value $Float, ' +
       'D_FLPrice $Float Default 0, D_YunFei $Float Default 0,' +
       'D_PPrice $Float, D_TPrice Char(1) Default ''Y'')';
  {-----------------------------------------------------------------------------
   纸卡明细:ZhiKaDtl
   *.R_ID:记录编号
   *.D_ZID:纸卡号
   *.D_Type:类型(袋,散)
   *.D_StockNo,D_StockName:水泥名称
   *.D_Price:单价
   *.D_Value:办理量
   *.D_FLPrice: 返利价
   *.D_YunFei: 运费单价
   *.D_PPrice:调价前单价
   *.D_TPrice:允许调价
  -----------------------------------------------------------------------------}

  sSQL_NewBill = 'Create Table $Table(R_ID $Inc, L_ID varChar(20),' +
       'L_Card varChar(16), L_ZhiKa varChar(15), L_Order varChar(20),' +
       'L_Project varChar(100), L_Area varChar(50),' +
       'L_CusID varChar(15), L_CusName varChar(80), L_CusPY varChar(80),' +
       'L_SaleID varChar(15), L_SaleMan varChar(32),' +
       'L_Type Char(1), L_StockNo varChar(20), L_StockName varChar(80),' +
       'L_Value $Float, L_Price $Float, L_ZKMoney Char(1),' +
       'L_Truck varChar(15), L_Status Char(1), L_NextStatus Char(1),' +
       'L_InTime DateTime, L_InMan varChar(32),' +
       'L_PValue $Float, L_PDate DateTime, L_PMan varChar(32),' +
       'L_MValue $Float, L_MDate DateTime, L_MMan varChar(32),' +
       'L_LadeTime DateTime, L_LadeMan varChar(32), ' +
       'L_LadeLine varChar(15), L_LineName varChar(32), ' +
       'L_DaiTotal Integer , L_DaiNormal Integer, L_DaiBuCha Integer,' +
       'L_OutFact DateTime, L_OutMan varChar(32),' +
       'L_Lading Char(1), L_IsVIP varChar(1), ' +
       'L_HYDan varChar(15), L_PrintHY Char(1),' +
       'L_EmptyOut Char(1) Default ''N'',' +
       'L_Man varChar(32), L_Date DateTime,' +
       'L_DelMan varChar(32), L_DelDate DateTime,' +
       'L_Seal varChar(100), L_PriceDesc varChar(100), L_Memo varChar(320))';
  {-----------------------------------------------------------------------------
   交货单表: Bill
   *.R_ID: 编号
   *.L_ID: 提单号
   *.L_Card: 磁卡号
   *.L_ZhiKa: 纸卡号
   *.L_Order: 订单号(备用)
   *.L_Area: 区域
   *.L_CusID,L_CusName,L_CusPY:客户
   *.L_SaleID,L_SaleMan:业务员
   *.L_Type: 类型(袋,散)
   *.L_StockNo: 物料编号
   *.L_StockName: 物料描述
   *.L_Value: 提货量
   *.L_Price: 提货单价
   *.L_ZKMoney: 纸卡限提(Y/N)
   *.L_Truck: 车船号
   *.L_Status,L_NextStatus:状态控制
   *.L_InTime,L_InMan: 进厂放行
   *.L_PValue,L_PDate,L_PMan: 称皮重
   *.L_MValue,L_MDate,L_MMan: 称毛重
   *.L_LadeTime,L_LadeMan: 发货时间,发货人
   *.L_LadeLine,L_LineName: 发货通道
   *.L_DaiTotal,L_DaiNormal,L_DaiBuCha:总装,正常,补差
   *.L_OutFact,L_OutMan: 出厂放行
   *.L_Lading: 提货方式(自提,送货)
   *.L_IsVIP: VIP单
   *.L_HYDan: 化验单
   *.L_PrintHY:自动打印化验单
   *.L_EmptyOut: 空车出厂标记
   *.L_Man:操作人
   *.L_Date:创建时间
   *.L_DelMan: 交货单删除人员
   *.L_DelDate: 交货单删除时间
   *.L_Seal: 封签号
   *.L_PriceDesc: 价格描述
   *.L_Memo: 动作备注
  -----------------------------------------------------------------------------}

  sSQL_NewCard = 'Create Table $Table(R_ID $Inc, C_Card varChar(16),' +
       'C_Card2 varChar(32), C_Card3 varChar(32),' +
       'C_Owner varChar(15), C_TruckNo varChar(15), C_Status Char(1),' +
       'C_Freeze Char(1), C_Used Char(1), C_UseTime Integer Default 0,' +
       'C_Man varChar(32), C_Date DateTime, C_Memo varChar(500))';
  {-----------------------------------------------------------------------------
   磁卡表:Card
   *.R_ID:记录编号
   *.C_Card:主卡号
   *.C_Card2,C_Card3:副卡号
   *.C_Owner:持有人标识
   *.C_TruckNo:提货车牌
   *.C_Used:用途(供应,销售,临时)
   *.C_UseTime:使用次数
   *.C_Status:状态(空闲,使用,注销,挂失)
   *.C_Freeze:是否冻结
   *.C_Man:办理人
   *.C_Date:办理时间
   *.C_Memo:备注信息
  -----------------------------------------------------------------------------}

  sSQL_NewTruck = 'Create Table $Table(R_ID $Inc, T_Truck varChar(15), ' +
       'T_PY varChar(15), T_Owner varChar(32), T_Phone varChar(15), T_Used Char(1), ' +
       'T_PrePValue $Float, T_PrePMan varChar(32), T_PrePTime DateTime, ' +
       'T_PrePUse Char(1), T_MinPVal $Float, T_MaxPVal $Float, ' +
       'T_MaxNet $Float Default 0, T_MaxNetIgnore Integer Default 0,' +
       'T_PValue $Float Default 0, T_PTime Integer Default 0,' +
       'T_PlateColor varChar(12),T_Type varChar(12), T_LastTime DateTime, ' +
       'T_Card varChar(32), T_CardUse Char(1), T_Card2 varChar(32),' +
       'T_NoVerify Char(1), T_Valid Char(1), T_VIPTruck Char(1), T_HasGPS Char(1))';
  {-----------------------------------------------------------------------------
   车辆信息:Truck
   *.R_ID: 记录号
   *.T_Truck: 车牌号
   *.T_PY: 车牌拼音
   *.T_Owner: 车主
   *.T_Phone: 联系方式
   *.T_Used: 用途(供应,销售)
   *.T_PrePValue: 预置皮重
   *.T_PrePMan: 预置司磅
   *.T_PrePTime: 预置时间
   *.T_PrePUse: 使用预置
   *.T_MinPVal: 历史最小皮重
   *.T_MaxPVal: 历史最大皮重
   *.T_MaxNet: 历史最大净重
   *.T_MaxNetIgnore: 可忽略最大净重次数
   *.T_PValue: 有效皮重
   *.T_PTime: 过皮次数
   *.T_PlateColor: 车牌颜色
   *.T_Type: 车型
   *.T_LastTime: 上次活动
   *.T_Card: 电子标签
   *.T_CardUse: 使用电子签(Y/N)
   *.T_NoVerify: 不校验时间
   *.T_Valid: 是否有效
   *.T_VIPTruck:是否VIP
   *.T_HasGPS:安装GPS(Y/N)

   有效平均皮重算法:
   T_PValue = (T_PValue * T_PTime + 新皮重) / (T_PTime + 1)
  -----------------------------------------------------------------------------}

  sSQL_NewTruckPlan = 'Create Table $Table(R_ID $Inc, P_Truck varChar(15), ' +
       'P_CusID varChar(15), P_Start DateTime, P_End DateTime,' +
       'P_Times Integer Default 0, P_Valid Char(1) Default ''U'',' +
       'P_Visible Char(1) Default ''Y'', P_Date DateTime, P_Man varChar(32))';
  {-----------------------------------------------------------------------------
   车辆信息:Truck
   *.R_ID: 记录号
   *.P_Truck: 车牌号
   *.P_CusID: 客户编号
   *.P_Start: 开始日期
   *.P_End: 结束日期
   *.P_Times: 有效次数
   *.P_Valid: 是否有效(U/Y/N)
   *.P_Visible: 在历史列表可见
   *.P_Date,P_Man: 办理人
  -----------------------------------------------------------------------------}

  sSQL_NewPoundLog = 'Create Table $Table(R_ID $Inc, P_ID varChar(15),' +
       'P_Type varChar(1), P_Order varChar(20), P_Card varChar(16),' +
       'P_Bill varChar(20), P_Truck varChar(15), P_CusID varChar(32),' +
       'P_CusName varChar(80), P_MID varChar(32),P_MName varChar(80),' +
       'P_MType varChar(10), P_LimValue $Float,' +
       'P_PValue $Float, P_PDate DateTime, P_PMan varChar(32), ' +
       'P_MValue $Float, P_MDate DateTime, P_MMan varChar(32), ' +
       'P_FactID varChar(32), P_PStation varChar(10), P_MStation varChar(10),' +
       'P_Direction varChar(10), P_PModel varChar(10), P_Status Char(1),' +
       'P_Valid Char(1), P_PrintNum Integer Default 1, P_KZValue $Float,' +
       'P_DelMan varChar(32), P_DelDate DateTime, P_Memo varChar(320))';
  {-----------------------------------------------------------------------------
   过磅记录: Materails
   *.P_ID: 编号
   *.P_Type: 类型(销售,供应,临时)
   *.P_Order: 订单号(供应)
   *.P_Bill: 交货单
   *.P_Truck: 车牌
   *.P_CusID: 客户号
   *.P_CusName: 物料名
   *.P_MID: 物料号
   *.P_MName: 物料名
   *.P_MType: 包,散等
   *.P_LimValue: 票重
   *.P_PValue,P_PDate,P_PMan: 皮重
   *.P_MValue,P_MDate,P_MMan: 毛重
   *.P_FactID: 工厂编号
   *.P_PStation,P_MStation: 称重磅站
   *.P_Direction: 物料流向(进,出)
   *.P_PModel: 过磅模式(标准,配对等)
   *.P_Status: 记录状态
   *.P_Valid: 是否有效
   *.P_PrintNum: 打印次数
   *.P_KZValue: 供应扣杂
   *.P_DelMan,P_DelDate: 删除记录
   *.P_Memo: 动作备注
  -----------------------------------------------------------------------------}

  sSQL_NewPicture = 'Create Table $Table(R_ID $Inc, P_ID varChar(15),' +
       'P_Name varChar(32), P_Mate varChar(80), P_Date DateTime, P_Picture Image)';
  {-----------------------------------------------------------------------------
   图片: Picture
   *.P_ID: 编号
   *.P_Name: 名称
   *.P_Mate: 物料
   *.P_Date: 时间
   *.P_Picture: 图片
  -----------------------------------------------------------------------------}

  sSQL_NewPoundDaiWC = 'Create Table $Table(R_ID $Inc,' +
       'P_DaiWuChaZ $Float, P_DaiWuChaF $Float, P_Start $Float, P_End $Float,' +
       'P_Percent Char(1), P_Station varChar(32))';
  {-----------------------------------------------------------------------------
   袋装误差范围: PoundDaiWuCha
   *.P_DaiWuChaZ: 正误差
   *.P_DaiWuChaF: 负误差
   *.P_Start: 起始范围
   *.P_End: 结束范围
   *.P_Percent: 按比例计算误差(Y、是;其它、否)
   *.P_Station: 磅站编号
  -----------------------------------------------------------------------------}

  sSQL_NewZTLines = 'Create Table $Table(R_ID $Inc, Z_ID varChar(15),' +
       'Z_Name varChar(32), Z_StockNo varChar(20), Z_Stock varChar(80),' +
       'Z_StockType Char(1), Z_PeerWeight Integer,' +
       'Z_QueueMax Integer, Z_VIPLine Char(1), Z_Valid Char(1), Z_Index Integer)';
  {-----------------------------------------------------------------------------
   装车线配置: ZTLines
   *.R_ID: 记录号
   *.Z_ID: 编号
   *.Z_Name: 名称
   *.Z_StockNo: 品种编号
   *.Z_Stock: 品名
   *.Z_StockType: 类型(袋,散)
   *.Z_PeerWeight: 袋重
   *.Z_QueueMax: 队列大小
   *.Z_VIPLine: VIP通道
   *.Z_Valid: 是否有效
   *.Z_Index: 顺序索引
  -----------------------------------------------------------------------------}

  sSQL_NewZTTrucks = 'Create Table $Table(R_ID $Inc, T_Truck varChar(15),' +
       'T_StockNo varChar(20), T_Stock varChar(80), T_Type Char(1),' +
       'T_Line varChar(15), T_Index Integer, ' +
       'T_InTime DateTime, T_InFact DateTime, T_InQueue DateTime,' +
       'T_InLade DateTime, T_VIP Char(1), T_Valid Char(1), T_Bill varChar(15),' +
       'T_Value $Float, T_PeerWeight Integer, T_Total Integer Default 0,' +
       'T_Normal Integer Default 0, T_BuCha Integer Default 0,' +
       'T_PDate DateTime, T_IsPound Char(1),T_HKBills varChar(200))';
  {-----------------------------------------------------------------------------
   待装车队列: ZTTrucks
   *.R_ID: 记录号
   *.T_Truck: 车牌号
   *.T_StockNo: 品种编号
   *.T_Stock: 品种名称
   *.T_Type: 品种类型(D,S)
   *.T_Line: 所在道
   *.T_Index: 顺序索引
   *.T_InTime: 入队时间
   *.T_InFact: 进厂时间
   *.T_InQueue: 上屏时间
   *.T_InLade: 提货时间
   *.T_VIP: 特权
   *.T_Bill: 提单号
   *.T_Valid: 是否有效
   *.T_Value: 提货量
   *.T_PeerWeight: 袋重
   *.T_Total: 总装袋数
   *.T_Normal: 正常袋数
   *.T_BuCha: 补差袋数
   *.T_PDate: 过磅时间
   *.T_IsPound: 需过磅(Y/N)
   *.T_HKBills: 合卡交货单列表
  -----------------------------------------------------------------------------}

  sSQL_NewOrderBase = 'Create Table $Table(R_ID $Inc, B_ID varChar(20),' +
       'B_Value $Float, B_SentValue $Float,B_RestValue $Float,' +
       'B_LimValue $Float, B_WarnValue $Float,B_FreezeValue $Float,' +
       'B_BStatus Char(1),B_Area varChar(50), B_Project varChar(100),' +
       'B_ProID varChar(32), B_ProName varChar(80), B_ProPY varChar(80),' +
       'B_SaleID varChar(32), B_SaleMan varChar(80), B_SalePY varChar(80),' +
       'B_StockType Char(1), B_StockNo varChar(32), B_StockName varChar(80),' +
       'B_Man varChar(32), B_Date DateTime,' +
       'B_DelMan varChar(32), B_DelDate DateTime, B_Memo varChar(500))';
  {-----------------------------------------------------------------------------
   采购申请单表: Order
   *.R_ID: 编号
   *.B_ID: 提单号
   *.B_Value,B_SentValue,B_RestValue:订单量，已发量，剩余量
   *.B_LimValue,B_WarnValue,B_FreezeValue:订单超发上限;订单预警量,订单冻结量
   *.B_BStatus: 订单状态
   *.B_Area,B_Project: 区域,项目
   *.B_ProID,B_ProName,B_ProPY:供应商
   *.B_SaleID,B_SaleMan,B_SalePY:业务员
   *.B_StockType: 类型(袋,散)
   *.B_StockNo: 原材料编号
   *.B_StockName: 原材料名称
   *.B_Man:操作人
   *.B_Date:创建时间
   *.B_DelMan: 采购申请单删除人员
   *.B_DelDate: 采购申请单删除时间
   *.B_Memo: 动作备注
  -----------------------------------------------------------------------------}

  sSQL_NewOrder = 'Create Table $Table(R_ID $Inc, O_ID varChar(20),' +
       'O_BID varChar(20),O_Card varChar(16), O_CType varChar(1),' +
       'O_Value $Float,O_Area varChar(50), O_Project varChar(100),' +
       'O_ProID varChar(32), O_ProName varChar(80), O_ProPY varChar(80),' +
       'O_SaleID varChar(32), O_SaleMan varChar(80), O_SalePY varChar(80),' +
       'O_Type Char(1), O_StockNo varChar(32), O_StockName varChar(80),' +
       'O_Truck varChar(15), O_OStatus Char(1),' +
       'O_Man varChar(32), O_Date DateTime,' +
       'O_KFValue varChar(16), O_KFLS varChar(32),' +
       'O_DelMan varChar(32), O_DelDate DateTime, O_Memo varChar(500))';
  {-----------------------------------------------------------------------------
   采购订单表: Order
   *.R_ID: 编号
   *.O_ID: 提单号
   *.O_BID: 采购申请单据号
   *.O_Card,O_CType: 磁卡号,磁卡类型(L、临时卡;G、固定卡)
   *.O_Value:订单量，
   *.O_OStatus: 订单状态
   *.O_Area,O_Project: 区域,项目
   *.O_ProID,O_ProName,O_ProPY:供应商
   *.O_SaleID,O_SaleMan:业务员
   *.O_Type: 类型(袋,散)
   *.O_StockNo: 原材料编号
   *.O_StockName: 原材料名称
   *.O_Truck: 车船号
   *.O_Man:操作人
   *.O_Date:创建时间
   *.O_KFValue:矿发数量
   *.O_KFLS:矿发流水
   *.O_DelMan: 采购单删除人员
   *.O_DelDate: 采购单删除时间
   *.O_Memo: 动作备注
  -----------------------------------------------------------------------------}

  sSQL_NewOrderDtl = 'Create Table $Table(R_ID $Inc, D_ID varChar(20),' +
       'D_OID varChar(20), D_PID varChar(20), D_Card varChar(16), ' +
       'D_Area varChar(50), D_Project varChar(100),D_Truck varChar(15), ' +
       'D_ProID varChar(32), D_ProName varChar(80), D_ProPY varChar(80),' +
       'D_SaleID varChar(32), D_SaleMan varChar(80), D_SalePY varChar(80),' +
       'D_Type Char(1), D_StockNo varChar(32), D_StockName varChar(80),' +
       'D_DStatus Char(1), D_Status Char(1), D_NextStatus Char(1),' +
       'D_InTime DateTime, D_InMan varChar(32),' +
       'D_PValue $Float, D_PDate DateTime, D_PMan varChar(32),' +
       'D_MValue $Float, D_MDate DateTime, D_MMan varChar(32),' +
       'D_YTime DateTime, D_YMan varChar(32), ' +
       'D_Value $Float,D_KZValue $Float, D_AKValue $Float,' +
       'D_YLine varChar(15), D_YLineName varChar(32), D_Unload varChar(80),' +
       'D_DelMan varChar(32), D_DelDate DateTime, D_YSResult Char(1), ' +
       'D_OutFact DateTime, D_OutMan varChar(32), D_Memo varChar(500))';
  {-----------------------------------------------------------------------------
   采购订单明细表: OrderDetail
   *.R_ID: 编号
   *.D_ID: 采购明细号
   *.D_OID: 采购单号
   *.D_PID: 磅单号
   *.D_Card: 采购磁卡号
   *.D_DStatus: 订单状态
   *.D_Area,D_Project: 区域,项目
   *.D_ProID,D_ProName,D_ProPY:供应商
   *.D_SaleID,D_SaleMan:业务员
   *.D_Type: 类型(袋,散)
   *.D_StockNo: 原材料编号
   *.D_StockName: 原材料名称
   *.D_Truck: 车船号
   *.D_Status,D_NextStatus: 状态
   *.D_InTime,D_InMan: 进厂放行
   *.D_PValue,D_PDate,D_PMan: 称皮重
   *.D_MValue,D_MDate,D_MMan: 称毛重
   *.D_YTime,D_YMan: 收货时间,验收人,
   *.D_Value,D_KZValue,D_AKValue: 收货量,验收扣除(明扣),暗扣
   *.D_YLine,D_YLineName: 收货通道
   *.D_UnLoad: 卸货地点/库房
   *.D_YSResult: 验收结果
   *.D_OutFact,D_OutMan: 出厂放行
  -----------------------------------------------------------------------------}

  sSQL_NewWXLog = 'Create Table $Table(R_ID $Inc, L_UserID varChar(50), ' +
       'L_MsgID varChar(20), L_Count Integer Default 0, L_Status varChar(1), ' +
       'L_Data Text, L_Result Text, L_Comment Text,' +
       'L_LastSend DateTime, L_Date DateTime)';
  {-----------------------------------------------------------------------------
   微信发送日志:WeixinLog
   *.R_ID:记录编号
   *.L_UserID: 接收者ID
   *.L_MsgID: 微信返回标识
   *.L_Count:发送次数
   *.L_Status:发送状态(N待发送,Y已发送)
   *.L_Data:微信数据
   *.L_Result:发送返回信息
   *.L_Comment:备注
   *.L_LastSend,L_Date: 发送,创建时间
  -----------------------------------------------------------------------------}

  sSQL_NewProvider = 'Create Table $Table(R_ID $Inc, P_ID varChar(32),' +
       'P_Name varChar(80),P_PY varChar(80), P_Phone varChar(20),' +
       'P_Saler varChar(32),p_WechartAccount varchar(32),P_Memo varChar(50))';
  {-----------------------------------------------------------------------------
   供应商: Provider
   *.P_ID: 编号
   *.P_Name: 名称
   *.P_PY: 拼音简写
   *.P_Phone: 联系方式
   *.p_WechartAccount：商城账号
   *.P_Saler: 业务员
   *.P_Memo: 备注
  -----------------------------------------------------------------------------}

  sSQL_NewMaterails = 'Create Table $Table(R_ID $Inc, M_ID varChar(32),' +
       'M_Name varChar(80),M_PY varChar(80),M_Unit varChar(20),M_Price $Float,' +
       'M_PrePValue Char(1), M_PrePTime Integer, M_Memo varChar(50), ' +
       'M_HasLs Char(1) Default ''N'', M_IsSale Char(1) Default ''N'')';
  {-----------------------------------------------------------------------------
   物料表: Materails
   *.M_ID: 编号
   *.M_Name: 名称
   *.M_PY: 拼音简写
   *.M_Unit: 单位
   *.M_PrePValue: 预置皮重
   *.M_PrePTime: 皮重时长(天)
   *.M_Memo: 备注
   *.M_IsSale: 销售品种
   *.M_HasLs: 是否生成矿发流水
  -----------------------------------------------------------------------------}

  sSQL_NewStockParam = 'Create Table $Table(P_ID varChar(15), P_Stock varChar(30),' +
       'P_Type Char(1), P_Name varChar(50), P_QLevel varChar(20), P_Memo varChar(50),' +
       'P_MgO varChar(20), P_SO3 varChar(20), P_ShaoShi varChar(20),' +
       'P_CL varChar(20), P_BiBiao varChar(20), P_ChuNing varChar(20),' +
       'P_ZhongNing varChar(20), P_AnDing varChar(20), P_XiDu varChar(20),' +
       'P_Jian varChar(20), P_ChouDu varChar(20), P_BuRong varChar(20),' +
       'P_YLiGai varChar(20), P_Water varChar(20), P_KuangWu varChar(20),' +
       'P_GaiGui varChar(20), P_3DZhe varChar(20), P_28Zhe varChar(20),' +
       'P_3DYa varChar(20), P_28Ya varChar(20))';
  {-----------------------------------------------------------------------------
   品种参数:StockParam
   *.P_ID:记录编号
   *.P_Stock:品名
   *.P_Type:类型(袋,散)
   *.P_Name:等级名
   *.P_QLevel:强度等级
   *.P_Memo:备注
   *.P_MgO:氧化镁
   *.P_SO3:三氧化硫
   *.P_ShaoShi:烧失量
   *.P_CL:氯离子
   *.P_BiBiao:比表面积
   *.P_ChuNing:初凝时间
   *.P_ZhongNing:终凝时间
   *.P_AnDing:安定性
   *.P_XiDu:细度
   *.P_Jian:碱含量
   *.P_ChouDu:稠度
   *.P_BuRong:不溶物
   *.P_YLiGai:游离钙
   *.P_Water:保水率
   *.P_KuangWu:硅酸盐矿物
   *.P_GaiGui:钙硅比
   *.P_3DZhe:3天抗折强度
   *.P_28DZhe:28抗折强度
   *.P_3DYa:3天抗压强度
   *.P_28DYa:28抗压强度
  -----------------------------------------------------------------------------}

  sSQL_NewStockRecord = 'Create Table $Table(R_ID $Inc, R_SerialNo varChar(15),' +
       'R_PID varChar(15),' +
       'R_SGType varChar(20), R_SGValue varChar(20),' +
       'R_HHCType varChar(20), R_HHCValue varChar(20),' +
       'R_MgO varChar(20), R_SO3 varChar(20), R_ShaoShi varChar(20),' +
       'R_CL varChar(20), R_BiBiao varChar(20), R_ChuNing varChar(20),' +
       'R_ZhongNing varChar(20), R_AnDing varChar(20), R_XiDu varChar(20),' +
       'R_Jian varChar(20), R_ChouDu varChar(20), R_BuRong varChar(20),' +
       'R_YLiGai varChar(20), R_Water varChar(20), R_KuangWu varChar(20),' +
       'R_GaiGui varChar(20),' +
       'R_3DZhe1 varChar(20), R_3DZhe2 varChar(20), R_3DZhe3 varChar(20),' +
       'R_28Zhe1 varChar(20), R_28Zhe2 varChar(20), R_28Zhe3 varChar(20),' +
       'R_3DYa1 varChar(20), R_3DYa2 varChar(20), R_3DYa3 varChar(20),' +
       'R_3DYa4 varChar(20), R_3DYa5 varChar(20), R_3DYa6 varChar(20),' +
       'R_28Ya1 varChar(20), R_28Ya2 varChar(20), R_28Ya3 varChar(20),' +
       'R_28Ya4 varChar(20), R_28Ya5 varChar(20), R_28Ya6 varChar(20),' +
       'R_Date DateTime, R_Man varChar(32))';
  {-----------------------------------------------------------------------------
   检验记录:StockRecord
   *.R_ID:记录编号
   *.R_SerialNo:水泥编号
   *.R_PID:品种参数
   *.R_SGType: 石膏种类
   *.R_SGValue: 石膏掺入量
   *.R_HHCType: 混合材料类
   *.R_HHCValue: 混合材掺入量
   *.R_MgO:氧化镁
   *.R_SO3:三氧化硫
   *.R_ShaoShi:烧失量
   *.R_CL:氯离子
   *.R_BiBiao:比表面积
   *.R_ChuNing:初凝时间
   *.R_ZhongNing:终凝时间
   *.R_AnDing:安定性
   *.R_XiDu:细度
   *.R_Jian:碱含量
   *.R_ChouDu:稠度
   *.R_BuRong:不溶物
   *.R_YLiGai:游离钙
   *.R_Water:保水率
   *.R_KuangWu:硅酸盐矿物
   *.R_GaiGui:钙硅比
   *.R_3DZhe1:3天抗折强度1
   *.R_3DZhe2:3天抗折强度2
   *.R_3DZhe3:3天抗折强度3
   *.R_28Zhe1:28抗折强度1
   *.R_28Zhe2:28抗折强度2
   *.R_28Zhe3:28抗折强度3
   *.R_3DYa1:3天抗压强度1
   *.R_3DYa2:3天抗压强度2
   *.R_3DYa3:3天抗压强度3
   *.R_3DYa4:3天抗压强度4
   *.R_3DYa5:3天抗压强度5
   *.R_3DYa6:3天抗压强度6
   *.R_28Ya1:28抗压强度1
   *.R_28Ya2:28抗压强度2
   *.R_28Ya3:28抗压强度3
   *.R_28Ya4:28抗压强度4
   *.R_28Ya5:28抗压强度5
   *.R_28Ya6:28抗压强度6
   *.R_Date:取样日期
   *.R_Man:录入人
  -----------------------------------------------------------------------------}

  sSQL_NewStockHuaYan = 'Create Table $Table(H_ID $Inc, H_No varChar(15),' +
       'H_Custom varChar(15), H_CusName varChar(80), H_SerialNo varChar(15),' +
       'H_Truck varChar(15), H_Value $Float, H_BillDate DateTime,' +
       'H_EachTruck Char(1), H_ReportDate DateTime, H_Reporter varChar(32))';
  {-----------------------------------------------------------------------------
   开化验单:StockHuaYan
   *.H_ID:记录编号
   *.H_No:化验单号
   *.H_Custom:客户编号
   *.H_CusName:客户名称
   *.H_SerialNo:水泥编号
   *.H_Truck:提货车辆
   *.H_Value:提货量
   *.H_BillDate:提货日期
   *.H_EachTruck: 随车开单
   *.H_ReportDate:报告日期
   *.H_Reporter:报告人
  -----------------------------------------------------------------------------}

  sSQL_NewStockBatcode = 'Create Table $Table(R_ID $Inc, B_Stock varChar(32),' +
       'B_Name varChar(80), B_Prefix varChar(5), B_UseYear Char(1),' +
       'B_Base Integer, B_Incement Integer, B_Length Integer, ' +
       'B_Value $Float, B_Low $Float, B_High $Float, B_Interval Integer,' +
       'B_AutoNew Char(1), B_UseDate Char(1), B_FirstDate DateTime,' +
       'B_LastDate DateTime, B_HasUse $Float Default 0, B_Batcode varChar(32))';
  {-----------------------------------------------------------------------------
   批次编码表: Batcode
   *.R_ID: 编号
   *.B_Stock: 物料号
   *.B_Name: 物料名
   *.B_Prefix: 前缀
   *.B_UseYear: 前缀后加两位年
   *.B_Base: 起始编码(基数)
   *.B_Incement: 编号增量
   *.B_Length: 编号长度
   *.B_Value:检测量
   *.B_Low,B_High:上下限(%)
   *.B_Interval: 编号周期(天)
   *.B_AutoNew: 元旦重置(Y/N)
   *.B_UseDate: 使用日期编码
   *.B_FirstDate: 首次使用时间
   *.B_LastDate: 上次基数更新时间
   *.B_HasUse: 已使用
   *.B_Batcode: 当前批次号
  -----------------------------------------------------------------------------}

//------------------------------------------------------------------------------
// 数据查询
//------------------------------------------------------------------------------
  sQuery_SysDict = 'Select D_ID, D_Value, D_Memo, D_ParamA, ' +
         'D_ParamB From $Table Where D_Name=''$Name'' Order By D_Index ASC';
  {-----------------------------------------------------------------------------
   从数据字典读取数据
   *.$Table:数据字典表
   *.$Name:字典项名称
  -----------------------------------------------------------------------------}

  sQuery_ExtInfo = 'Select I_ID, I_Item, I_Info From $Table Where ' +
         'I_Group=''$Group'' and I_ItemID=''$ID'' Order By I_Index Desc';
  {-----------------------------------------------------------------------------
   从扩展信息表读取数据
   *.$Table:扩展信息表
   *.$Group:分组名称
   *.$ID:信息标识
  -----------------------------------------------------------------------------}

function CardStatusToStr(const nStatus: string): string;
//磁卡状态
function TruckStatusToStr(const nStatus: string): string;
//车辆状态
function BillTypeToStr(const nType: string): string;
//订单类型
function PostTypeToStr(const nPost: string): string;
//岗位类型

implementation

//Desc: 将nStatus转为可读内容
function CardStatusToStr(const nStatus: string): string;
begin
  if nStatus = sFlag_CardIdle then Result := '空闲' else
  if nStatus = sFlag_CardUsed then Result := '正常' else
  if nStatus = sFlag_CardLoss then Result := '挂失' else
  if nStatus = sFlag_CardInvalid then Result := '注销' else Result := '未知';
end;

//Desc: 将nStatus转为可识别的内容
function TruckStatusToStr(const nStatus: string): string;
begin
  if nStatus = sFlag_TruckIn then Result := '进厂' else
  if nStatus = sFlag_TruckOut then Result := '出厂' else
  if nStatus = sFlag_TruckBFP then Result := '称皮重' else
  if nStatus = sFlag_TruckBFM then Result := '称毛重' else
  if nStatus = sFlag_TruckSH then Result := '送货中' else
  if nStatus = sFlag_TruckXH then Result := '验收处' else
  if nStatus = sFlag_TruckFH then Result := '放灰处' else
  if nStatus = sFlag_TruckZT then Result := '栈台' else Result := '未进厂';
end;

//Desc: 交货单类型转为可识别内容
function BillTypeToStr(const nType: string): string;
begin
  if nType = sFlag_TypeShip then Result := '船运' else
  if nType = sFlag_TypeZT   then Result := '栈台' else
  if nType = sFlag_TypeVIP  then Result := 'VIP' else Result := '普通';
end;

//Desc: 将岗位转为可识别内容
function PostTypeToStr(const nPost: string): string;
begin
  if nPost = sFlag_TruckIn   then Result := '门卫进厂' else
  if nPost = sFlag_TruckOut  then Result := '门卫出厂' else
  if nPost = sFlag_TruckBFP  then Result := '磅房称皮' else
  if nPost = sFlag_TruckBFM  then Result := '磅房称重' else
  if nPost = sFlag_TruckFH   then Result := '散装放灰' else
  if nPost = sFlag_TruckZT   then Result := '袋装栈台' else Result := '厂外';
end;

//------------------------------------------------------------------------------
//Desc: 添加系统表项
procedure AddSysTableItem(const nTable,nNewSQL: string);
var nP: PSysTableItem;
begin
  New(nP);
  gSysTableList.Add(nP);

  nP.FTable := nTable;
  nP.FNewSQL := nNewSQL;
end;

//Desc: 系统表
procedure InitSysTableList;
begin
  gSysTableList := TList.Create;

  AddSysTableItem(sTable_SysDict, sSQL_NewSysDict);
  AddSysTableItem(sTable_ExtInfo, sSQL_NewExtInfo);
  AddSysTableItem(sTable_SysLog, sSQL_NewSysLog);

  AddSysTableItem(sTable_BaseInfo, sSQL_NewBaseInfo);
  AddSysTableItem(sTable_SerialBase, sSQL_NewSerialBase);
  AddSysTableItem(sTable_SerialStatus, sSQL_NewSerialStatus);
  AddSysTableItem(sTable_StockMatch, sSQL_NewStockMatch);
  AddSysTableItem(sTable_WorkePC, sSQL_NewWorkePC);
  AddSysTableItem(sTable_Factorys, sSQL_NewFactorys);
  AddSysTableItem(sTable_ManualEvent, sSQL_NewManualEvent);
  AddSysTableItem(sTable_WeixinLog, sSQL_NewWXLog);

  AddSysTableItem(sTable_PriceWeek, sSQL_NewPriceWeek);
  AddSysTableItem(sTable_PriceRule, sSQL_NewPriceRule);
  AddSysTableItem(sTable_Customer, sSQL_NewCustomer);
  AddSysTableItem(sTable_Salesman, sSQL_NewSalesMan);

  AddSysTableItem(sTable_CusAccount, sSQL_NewCusAccount);
  AddSysTableItem(sTable_InOutMoney, sSQL_NewInOutMoney);
  AddSysTableItem(sTable_CusCredit, sSQL_NewCusCredit);
  AddSysTableItem(sTable_SysShouJu, sSQL_NewSysShouJu);

  AddSysTableItem(sTable_ZhiKa, sSQL_NewZhiKa);
  AddSysTableItem(sTable_ZhiKaDtl, sSQL_NewZhiKaDtl);
  AddSysTableItem(sTable_Card, sSQL_NewCard);
  AddSysTableItem(sTable_Bill, sSQL_NewBill);
  AddSysTableItem(sTable_BillBak, sSQL_NewBill);

  AddSysTableItem(sTable_Truck, sSQL_NewTruck);
  AddSysTableItem(sTable_TruckPlan, sSQL_NewTruckPlan);
  AddSysTableItem(sTable_ZTLines, sSQL_NewZTLines);
  AddSysTableItem(sTable_ZTTrucks, sSQL_NewZTTrucks);
  AddSysTableItem(sTable_PoundLog, sSQL_NewPoundLog);
  AddSysTableItem(sTable_PoundBak, sSQL_NewPoundLog);
  AddSysTableItem(sTable_Picture, sSQL_NewPicture);
  AddSysTableItem(sTable_PoundDaiWC, sSQL_NewPoundDaiWC);
  AddSysTableItem(sTable_Provider, ssql_NewProvider);
  AddSysTableItem(sTable_Materails, sSQL_NewMaterails);

  AddSysTableItem(sTable_StockParam, sSQL_NewStockParam);
  AddSysTableItem(sTable_StockParamExt, sSQL_NewStockRecord);
  AddSysTableItem(sTable_StockRecord, sSQL_NewStockRecord);
  AddSysTableItem(sTable_StockHuaYan, sSQL_NewStockHuaYan);
  AddSysTableItem(sTable_StockBatcode, sSQL_NewStockBatcode);

  AddSysTableItem(sTable_Order, sSQL_NewOrder);
  AddSysTableItem(sTable_OrderBak, sSQL_NewOrder);
  AddSysTableItem(sTable_OrderDtl, sSQL_NewOrderDtl);
  AddSysTableItem(sTable_OrderDtlBak, sSQL_NewOrderDtl);
  AddSysTableItem(sTable_OrderBase, sSQL_NewOrderBase);
  AddSysTableItem(sTable_OrderBaseBak, sSQL_NewOrderBase);
end;

//Desc: 清理系统表
procedure ClearSysTableList;
var nIdx: integer;
begin
  for nIdx:= gSysTableList.Count - 1 downto 0 do
  begin
    Dispose(PSysTableItem(gSysTableList[nIdx]));
    gSysTableList.Delete(nIdx);
  end;

  FreeAndNil(gSysTableList);
end;

initialization
  InitSysTableList;
finalization
  ClearSysTableList;
end.


