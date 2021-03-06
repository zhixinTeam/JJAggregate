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

{$DEFINE JJGL3}
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


//重庆金九骨料3期
{$IFDEF JJGL3}
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
  {.$DEFINE BasisWeightWithPM}
  //库底计量: 定量装车时过皮毛中
  {$DEFINE UseERelayPLC}
  //使用车捡由PLC控制
  {.$DEFINE TruckInNow}
  //开单立即进厂,需要采用厂内排队模式 
  {$DEFINE HKVDVR} 
  //保存皮毛重时进行抓拍
  {.$DEFINE TruckAutoIn} 
  //自动进厂
  {.$DEFINE BasisWeightTruckProber} 
  //定量装车使用车检
  {.$DEFINE AdminUseFL} 
  //管理员组使用返利
  {.$DEFINE UseCarrier}
  //使用承运商
  {.$DEFINE SendTrukTypeToPLC}
  //发送车辆型号到PLC
  {$DEFINE UseBXFontLED}
  //票箱6KE小屏
  {$DEFINE OpenBackWhenError}
  //过磅失败抬后杆
  {$DEFINE QueuePoundPChk}
  //过皮检查车道容量、待装车数量
  {$DEFINE LineNeedOPenDoor} 
  //库底车道华裔读卡器抬杆
  {$DEFINE SaveBillStatusFH} 
  //装车更新放灰状态
  {$DEFINE LineVoice} 
  //车道语音
  {$DEFINE CallLineNextPTruck} 
  //当前车过毛重时，叫号第三辆车过皮
  {$DEFINE AICMOnleSale} 
  //自助机只显示销售办卡
  {$DEFINE TruckNoChkHZ} 
  //开单车牌检查是否有前缀
  {$DEFINE PoundAutoEmptyOutChk} 
  //自动称重空车出厂判定支持
  {$DEFINE BuDanCanChoseDateTime} 
  //销售补单可指定日期
  {$DEFINE ReturnsBill} 
  //销售退货支持
  {$DEFINE UseBigFontSize} 
  //销售退货支持
  {$DEFINE PaymentChoseTime} 
  //收款可指定日期
  {$DEFINE LineWaitingCtl} 
  //单车道待装车辆控制，设定后，过皮时根据设定控制可过皮待装车辆
  {$DEFINE EnableABDB} 
  //AB库支持
  {$DEFINE OutTimeCreateBillChk} 
  //出厂N分钟内禁止开单
  {$DEFINE FixLoad} 
  //出厂N分钟内禁止开单
  {$DEFINE 02NReaderCloseERela} 
  //近距离读卡器拔卡关闭继电器
{$ENDIF}