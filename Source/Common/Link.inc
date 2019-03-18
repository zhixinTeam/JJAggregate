//----------------------------------- 通用 -------------------------------------
{$DEFINE DEBUG}
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
{.$DEFINE ClientMon}
//进程守护客户端

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

{$DEFINE GLKY}
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
{$ENDIF}