//----------------------------------- ͨ�� -------------------------------------
{.$DEFINE DEBUG}
//����ģʽ

{.$DEFINE TrialVersion}
//���ð汾

{$DEFINE UseReport}
//����֧��

{.$DEFINE RandomID}
//ʹ��������

{$DEFINE cxLibrary42}
//Ver4.2���뻷��

{.$DEFINE EnableBackupDB}
//�������ݿ�֧��
{.$DEFINE EnableDoubleDB}
//˫���ݿ�֧��

//---------------------------------- �м�� ------------------------------------
{.$DEFINE ClientMon}
//�����ػ��ͻ���

{$DEFINE HardMon}
//����Ӳ���ػ�

{.$DEFINE GenRODL}
//����RODL��Դ

{$DEFINE COM_MIT}
//����ϵͳģʽ

//ͨ���м��
{$IFDEF COM_MIT}
  {$DEFINE DBPool}
  //�������ݿ�֧��
  {.$DEFINE ChannelPool}
  //����ͨ��֧��
  {.$DEFINE AutoChannel}
  //����ͨ��ƽ��
  {.$DEFINE SAP}
  //����SAP֧��
  {.$DEFINE ClientMon}
  //֧���ػ�����
{$ENDIF}

//--------------------------------- �ض�ϵͳ -----------------------------------
{.$DEFINE COMMON}
//ͨ�ð汾

{$DEFINE JJGL}
//�ض�ϵͳ

//��Ź���
{$IFDEF JJGL}
  {$DEFINE COMMON}
  {$DEFINE HYRFID201}
  //�����ͷ
  {$DEFINE TTCEM100}
  //�Զ��տ�Ʊ��
  {$DEFINE MITTruckProber}
  //�������м������
  {$DEFINE TruckProberEx}
  //�����դ״̬�ж���չ(�˿�������ʱ����ͬʱ����MITTruckProber����)
  {$DEFINE MultiReplay}
  //������Ӧ��ģʽ
  {$DEFINE PrintHYEach}
  //�泵�����鵥
  {.$DEFINE PrintHeGeZheng}
  {$DEFINE PrintHuaYanDan}
  //�泵����ʱ��ϸ�֤�����鵥
  {$DEFINE BatchInHYOfBill}
  //���α����ڻ��鵥�ֶ�
  {$DEFINE SanPreHK}
  //ɢװ����ʱԤ�Ͽ�
  {.$DEFINE AutoPoundInManual}
  //�Զ������˹���Ԥ�쳣
  {$DEFINE DaiStepWuCha}
  //��װ�������
  {$DEFINE NoShowPriceChange}
  //����ʾ�۸������ʾ
  {.$DEFINE NoCheckOnPayment}
  //�˿�ʱ��У���ʽ����
  {$DEFINE MicroMsg}
  //ʹ��΢��
  {$DEFINE UseCustomertMoney}
  //������ʹ�ÿͻ�������
  {$DEFINE PrintHY}
  //������ӡ���鵥
  {$DEFINE SaveHyDanEvent}
  //�������ͻ��鵥�¼�
  {$DEFINE ForceEleCard}
  //ǿ�Ƴ������������õ��ӱ�ǩ
  {$DEFINE WxShowCusMoney}
  //΢�Ŷ���ʾ�ͻ����
  {$DEFINE KuangFa}
  //����Ϣ
  {$DEFINE CastMoney}
  //�Զ�λ�����С��λ��2λ��������
  {$DEFINE NoCheckOrderValue}
  //������ԭ���Ͽ�������鶩��ʣ����
  {$DEFINE ProberShow}
  //���췢��С��
  {$DEFINE SpecialControl}
  //��������Ҫ��
  {$DEFINE FixLoad}
  //���ƷŻ�
  {$DEFINE OrderNoMulCard}
  //�ɹ���ֹһ���൥
  {$DEFINE CapturePictureEx}
  //����ץ��ģʽ��չ
{$ENDIF}