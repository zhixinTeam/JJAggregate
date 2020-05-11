unit UMgrKCDF360;

interface

const
  cKCDF720_DLL = 'K720_Dll.dll';

  function K720_GetSysVersion(nHandle: Cardinal; nVersion:PAnsiChar):Integer; stdcall;
    External cKCDF720_DLL name'K720_GetSysVersion';

//  ����:	�򿪴��ڣ�Ĭ�ϵĲ�����"9600, n, 8, 1"
//  ����:	[in]*nPort			Ҫ�򿪵Ĵ��ڣ������com1����nPort �洢"COM1"
//  ����ֵ:	��ȷ���ش��ڵľ��������=0
  function K720_CommOpen(nPort:string):Cardinal; stdcall;
    External cKCDF720_DLL name'K720_CommOpen';

//  ���ܣ�	�رյ�ǰ�򿪵Ĵ���
//  ������	[in]nHandle		Ҫ�رյĴ��ڵľ��
//  ����ֵ��	��ȷ=0������=��0
  function K720_CommClose(nHandle: Cardinal):Integer; stdcall;
    External cKCDF720_DLL name'K720_CommClose';

//  ���ܣ�	��ȡK720�����İ汾��Ϣ����ӦЭ����"GV"��������
//  ����[in]nHandle		�Ѿ��򿪵Ĵ��ڵľ��
//      [in]nAddr		�����ĵ�ַ����Чȡֵ��0��15��
//      [out]nVersion		������İ汾��Ϣ����ȡ�ɹ���洢�汾��Ϣ��
//  �� "TTCE_K720_V2.**"
//  ����ֵ��	��ȷ=0������=��0
  function K720_GetVersion(nHandle: Cardinal; nAddr: Integer; nVersion:PAnsiChar):Integer; stdcall;
    External cKCDF720_DLL name'K720_GetVersion';

//  ���ܣ�	�߼���ѯ��D1801״̬��Ϣ������4�ֽڵ�״̬��Ϣ����ӦЭ����"AP"����ָ��
//  ����[in]nHandle		�Ѿ��򿪵Ĵ��ڵľ��
//      [in]nAddr		�����ĵ�ַ����Чȡֵ��0��15��
//      [out]nStatus		�洢D1801״̬��Ϣ������4���ֽڣ��������K720��ͨѶЭ��
//      [out]nRecord	�洢���������ͨѶ��¼
//
//  ����ֵ��	��ȷ=0������=��0
  function K720_SensorQuery(nHandle: Cardinal; nAddr: Integer;
    nStatus: PAnsiChar; nRecord:PAnsiChar):Integer; stdcall;
    External cKCDF720_DLL name'K720_SensorQuery';

//  ���ܣ�	����D1801�Ĳ�������
//  ����[in]nHandle		�Ѿ��򿪵Ĵ��ڵľ��
//      [in]nAddr		�����ĵ�ַ����Чȡֵ��0��15��
//      [in]nCmd		�洢�����ַ���
//      [in]nCmdLen		�����ַ����ڵĳ���
//      [out]nRecord	�洢���������ͨѶ��¼
//
//  ����ֵ��	��ȷ=0������=��0
//  ��ע��	�˺�������ִ���������£�
//    K720_SendCmd(ComHandle, MacAddr, "DC", 2)	��������ȡ��λ�ã�
//    K720_SendCmd(ComHandle, MacAddr, "CP", 2)	�տ�
//    K720_SendCmd(ComHandle, MacAddr, "RS", 2)	��λ
//    K720_SendCmd(ComHandle, MacAddr, "BE", 2)	������������٣����գ�����������ᱨ����
//    K720_SendCmd(ComHandle, MacAddr, "BD", 2)	ֹͣ����������
//    K720_SendCmd(ComHandle, MacAddr, "CS0", 3)	���û���ͨѶΪ������1200bps
//    K720_SendCmd(ComHandle, MacAddr, "CS1", 3)	���û���ͨѶΪ������2400bps
//    K720_SendCmd(ComHandle, MacAddr, "CS2", 3)	���û���ͨѶΪ������4800bps
//    K720_SendCmd(ComHandle, MacAddr, "CS3", 3)	���û���ͨѶΪ������9600bps
//    K720_SendCmd(ComHandle, MacAddr, "CS4", 3)	���û���ͨѶΪ������19200bps
//    K720_SendCmd(ComHandle, MacAddr, "CS5", 3)	���û���ͨѶΪ������38400bps
//    K720_SendCmd(ComHandle, MacAddr, "FC6", 3)	������������2
//    K720_SendCmd(ComHandle, MacAddr, "FC7", 3)	����������λ��
//    K720_SendCmd(ComHandle, MacAddr, "FC8", 3)	ǰ�˽���
//    K720_SendCmd(ComHandle, MacAddr, "FC0", 3)	������ȡ��λ��
//    K720_SendCmd(ComHandle, MacAddr, "FC4", 3)	������������
//    K720_SendCmd(ComHandle, MacAddr, "LPX",3)	��������Ƶ��,����X=1-14��ʾ1����˸X��
//                        X=15-28,��ʾ(X-13)����˸1��
//    ����ʹ�ñ�׼��9600�Ĳ�����ͨѶ����������̫�ͣ�����Ӱ������ͺͽ���
  function K720_SendCmd(nHandle: Cardinal; nAddr: Integer;
    nCmd: string; nCmdLen: Integer; nRecord:PAnsiChar):Integer; stdcall;
    External cKCDF720_DLL name'K720_SendCmd';

//  ���ܣ�	S70 ��Ѱ��
//  ����[in]nHandle	 �Ѿ��򿪵Ĵ��ڵľ�
//      [in]nAddr		�����ĵ�ַ����Чȡֵ��0��15��
//      [out]nRecrod	�洢���������ͨѶ��¼
//  ����ֵ�� ��ȷ=0������=�� 0

  function K720_S70DetectCard(nHandle: Cardinal; nAddr: Integer; nRecrod:PAnsiChar):Integer; stdcall;
    External cKCDF720_DLL name'K720_S70DetectCard';

//  ���ܣ�	S70 ����ȡ ID ��
//  ������[in]nHandle			�Ѿ��򿪵Ĵ��ڵľ��
//        [in]nAddr           ������ַ������ȡֵ(0-15)
//        [out]nCardID			�洢��ȡ�� ��Ƭ ID ��
//        [out]nRecord		�洢���������ͨѶ��¼
//  ����ֵ�� ��ȷ=0������=�� 0

  function K720_S70GetCardID(nHandle: Cardinal; nAddr: Integer;
    nCardID: PAnsiChar; nRecord:PAnsiChar):Integer; stdcall;
    External cKCDF720_DLL name'K720_S70GetCardID';

//  ���ܣ�	S50 ��Ѱ��
//  ����[in]nHandle	 �Ѿ��򿪵Ĵ��ڵľ�
//      [in]nAddr		�����ĵ�ַ����Чȡֵ��0��15��
//      [out]nRecrod	�洢���������ͨѶ��¼
//  ����ֵ�� ��ȷ=0������=�� 0

  function K720_S50DetectCard(nHandle: Cardinal; nAddr: Integer; nRecrod:PAnsiChar):Integer; stdcall;
    External cKCDF720_DLL name'K720_S50DetectCard';

//  ����S50 ��ȡ���к�
//  ����[in]ComHandle                 �Ѿ��򿪵Ĵ��ڵľ��
//      [in]MacAddr           ������ַ������ȡֵ(0-15)
//      [out]_CardID		�洢��Ƭ��� [out]RecrodInfo	 �洢���������ͨѶ��¼
//  ����ֵ�� ��ȷ=0������=�� 0

  function K720_S50GetCardID(nHandle: Cardinal; nAddr: Integer;
    nCardID: PAnsiChar; nRecord:PAnsiChar):Integer; stdcall;
    External cKCDF720_DLL name'K720_S50GetCardID';

//  ���ܣ�	��ȡ�����Լ����տ�����
//  ����[in]nHandle		�Ѿ��򿪵Ĵ��ڵľ��
//      [in]nAddr		�����ĵ�ַ����Чȡֵ��0��15��
//      [out]nData		�洢�������ݣ�ǰʮ���ֽڼ�¼�����������һ���ֽڼ�¼���տ�����
//      [out]nRecord	�洢���������ͨѶ��¼
//
//  ����ֵ��	��ȷ=0������=��0

  function K720_GetCountSum(nHandle: Cardinal; nAddr: Integer;
    nData: PAnsiChar; nRecord:PAnsiChar):Integer; stdcall;
    External cKCDF720_DLL name'K720_GetCountSum';

//  ���ܣ�	�����������
//  ����[in]nHandle		�Ѿ��򿪵Ĵ��ڵľ��
//      [in]nAddr		�����ĵ�ַ����Чȡֵ��0��15��
//      [out]nRecord	�洢���������ͨѶ��¼
//
//  ����ֵ��	��ȷ=0������=��0

  function K720_ClearSendCount(nHandle: Cardinal; nAddr: Integer;
    nRecord:PAnsiChar):Integer; stdcall;
    External cKCDF720_DLL name'K720_ClearSendCount';

//  ���ܣ�	������տ�����
//  ����[in]nHandle		�Ѿ��򿪵Ĵ��ڵľ��
//      [in]nAddr		�����ĵ�ַ����Чȡֵ��0��15��
//      [out]nRecord	�洢���������ͨѶ��¼
//
//  ����ֵ��	��ȷ=0������=��0
  function K720_ClearRecycleCount(nHandle: Cardinal; nAddr: Integer;
    nRecord:PAnsiChar):Integer; stdcall;
    External cKCDF720_DLL name'K720_ClearRecycleCount';

implementation

end.
