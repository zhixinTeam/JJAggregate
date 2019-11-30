//----------------------------------- 通用 -------------------------------------
{.$DEFINE DEBUG}
//调试模式

{.$DEFINE TrialVersion}
//试用版本

{$DEFINE UseReport}
//报表支持

{.$DEFINE RandomID}
//使用随机编号

{$DEFINE cxLibrary42}
//Ver4.2编译环境

{.$DEFINE EnableBackupDB}
//备用数据库支持
{.$DEFINE EnableDoubleDB}
//双数据库支持

//---------------------------------- 中间件 ------------------------------------
{$DEFINE HardMon}
//编译硬件守护

{.$DEFINE GenRODL}
//生成RODL资源

{$DEFINE COM_MIT}
//定义系统模式

//通用中间件
{$IFDEF COM_MIT}
  {$DEFINE DBPool}
  //启用数据库支持
  {.$DEFINE ChannelPool}
  //启用通道支持
  {.$DEFINE AutoChannel}
  //启用通道平衡
  {.$DEFINE SAP}
  //启用SAP支持
  {.$DEFINE ClientMon}
  //支持守护服务
{$ENDIF}

//--------------------------------- 特定系统 -----------------------------------
{.$DEFINE COMMON}
//通用版本

{$DEFINE JZQY}
//特定系统

//金九骨料
{$IFDEF JJGL}
  {$DEFINE COMMON}
  {$DEFINE HYRFID201}
  //华益读头
  {$DEFINE TTCEM100}
  //自动收卡票箱
  {$DEFINE MITTruckProber}
  //车检由中间件控制
  {$DEFINE MultiReplay}
  //计数器应答模式
  {.$DEFINE TruckInNow}
  //开单后即进厂
  {.$DEFINE PrintHeGeZheng}
  {.$DEFINE PrintHuaYanDan}
  //随车开单时打合格证、化验单
  {.$DEFINE AutoPoundInManual}
  //自动称重人工干预异常
  {$DEFINE DaiStepWuCha}
  //包装阶梯误差
  {.$DEFINE NoCheckOnPayment}
  //退款时不校验资金余额
  {$DEFINE MicroMsg}
  //使用微信
  {$DEFINE WxShowCusMoney}
  //微信端显示客户金额
  {$DEFINE CastMoney}
  //对吨位及金额小数位后2位四舍五入
  {$DEFINE CapturePictureEx}
  //磅房抓拍模式扩展
{$ENDIF}

//国联矿业
{$IFDEF GLKY}
  {$DEFINE COMMON}
  {$DEFINE HYRFID201}
  //华益读头
  {$DEFINE TTCEM100}
  //自动收卡票箱
  {$DEFINE MITTruckProber}
  //车检由中间件控制
  {$DEFINE ReverseTrafficLight}
  //反转红绿灯控制信号
  {.$DEFINE NoCheckOnPayment}
  //退款时不校验资金余额
  {$DEFINE MicroMsg}
  //使用微信
  {$DEFINE WxShowCusMoney}
  //微信端显示客户金额
  {$DEFINE CastMoney}
  //对吨位及金额小数位后2位四舍五入
  {$DEFINE CapturePictureEx}
  //磅房抓拍模式扩展
  {$DEFINE BasisWeight}
  //启用定量装车
  {$DEFINE BasisWeightWithPM}
  //库底计量: 定量装车时过皮毛中
  {$DEFINE RemoteSnap}
  //进厂车牌识别
  {$DEFINE SendStatusToDCS}
  //发送通道状态至DCS
{$ENDIF}

//当阳城堡
{$IFDEF DYCB}
  {$DEFINE COMMON}
  {$DEFINE HYRFID201}
  //华益读头
  {$DEFINE TTCEM100}
  //自动收卡票箱
  {$DEFINE MITTruckProber}
  //车检由中间件控制
  {$DEFINE ProberShow}
  //车检发送小屏
  {.$DEFINE ReverseTrafficLight}
  //反转红绿灯控制信号
  {.$DEFINE NoCheckOnPayment}
  //退款时不校验资金余额
  {.$DEFINE MicroMsg}
  //使用微信
  {.$DEFINE WxShowCusMoney}
  //微信端显示客户金额
  {$DEFINE CastMoney}
  //对吨位及金额小数位后2位四舍五入
  {$DEFINE CapturePictureEx}
  //磅房抓拍模式扩展
  {$DEFINE BasisWeight}
  //启用定量装车
  {$DEFINE BasisWeightWithPM}
  //库底计量: 定量装车时过皮毛中
  {$DEFINE UseERelayPLC}
  //使用车捡由PLC控制
  {$DEFINE TruckInNow}
  //开单立即进厂,需要采用厂内排队模式 
  {$DEFINE HKVDVR} 
  //保存皮毛重时进行抓拍
  {$DEFINE TruckAutoIn} 
  //自动进厂
  {$DEFINE BasisWeightTruckProber} 
  //定量装车使用车检
  {$DEFINE AdminUseFL} 
  //管理员组使用返利
  {$DEFINE UseCarrier} 
  //使用承运商
  {$DEFINE UseERelayPLCSC} 
  //判断手持机是否放到位
{$ENDIF}

//焦作千叶新材料
{$IFDEF JZQY}
  {$DEFINE COMMON}
  {$DEFINE HYRFID201}
  //华益读头
  {$DEFINE TTCEM100}
  //自动收卡票箱
  {$DEFINE MITTruckProber}
  //车检由中间件控制
  {$DEFINE ProberShow}
  //车检发送小屏
  {.$DEFINE ReverseTrafficLight}
  //反转红绿灯控制信号
  {.$DEFINE NoCheckOnPayment}
  //退款时不校验资金余额
  {.$DEFINE MicroMsg}
  //使用微信
  {.$DEFINE WxShowCusMoney}
  //微信端显示客户金额
  {$DEFINE CastMoney}
  //对吨位及金额小数位后2位四舍五入
  {$DEFINE CapturePictureEx}
  //磅房抓拍模式扩展
  {$DEFINE BasisWeight}
  //启用定量装车
  {$DEFINE BasisWeightWithPM}
  //库底计量: 定量装车时过皮毛中
  {$DEFINE UseERelayPLC}
  //使用车捡由PLC控制
  {.$DEFINE TruckInNow}
  //开单立即进厂,需要采用厂内排队模式 
  {$DEFINE HKVDVR} 
  //保存皮毛重时进行抓拍
  {$DEFINE TruckAutoIn} 
  //自动进厂
  {$DEFINE BasisWeightTruckProber} 
  //定量装车使用车检
  {$DEFINE AdminUseFL} 
  //管理员组使用返利
  {$DEFINE UseCarrier}
  //使用承运商
  {$DEFINE SendTrukTypeToPLC}
  //发送车辆型号到PLC
{$ENDIF}