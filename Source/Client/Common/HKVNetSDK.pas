{*******************************************************************************
  ����: dmzn@163.com 2014-03-07
  ����: ��������HCNetSDK.dllͷ�ļ�
*******************************************************************************}
unit HKVNetSDK;

interface

uses
  Windows, Classes, HKVConst;

const
  cNetSDK  = 'HCNetSDK.dll';
  
type
  PIPItems = ^TIPItems;
  TIPItems = array[0..15, 0..15] of Char;

  {�豸��Ϣ}
  PNET_DVR_DEVICEINFO = ^TNET_DVR_DEVICEINFO;
  {$EXTERNALSYM NET_DVR_DEVICEINFO}
  NET_DVR_DEVICEINFO = Record
    sSerialNumber: Array[0..SERIALNO_LEN - 1] of Char ;  //���к�
    byAlarmInPortNum: BYTE ;	 //DVR�����������
    byAlarmOutPortNum: BYTE ;	 //DVR�����������
    byDiskNum: BYTE;	         //DVR Ӳ�̸���
    byDVRType: BYTE;	         //DVR����,
    byChanNum: BYTE;	         //DVR ͨ������
    byStartChan: BYTE;	       //��ʼͨ����,����DVS-1,DVR - 1
  end;
  TNET_DVR_DEVICEINFO = NET_DVR_DEVICEINFO;

  //ͼƬ����
  PNET_DVR_JPEGPARA = ^LPNET_DVR_JPEGPARA;
  {$EXTERNALSYM NET_DVR_JPEGPARA}
  NET_DVR_JPEGPARA = Record
    wPicSize: WORD;	             // 0=CIF, 1=QCIF, 2=D1 */
  	wPicQuality: WORD;	         // ͼƬ����ϵ�� 0-��� 1-�Ϻ� 2-һ�� */
  end;
  LPNET_DVR_JPEGPARA = NET_DVR_JPEGPARA;

function NET_DVR_Init: Boolean; stdcall; external cNetSDK;
function NET_DVR_Cleanup: Boolean; stdcall; external cNetSDK;
function NET_DVR_GetLastError():LongWord; stdcall; external cNetSDK;

function NET_DVR_Login(IPAddr: PChar;wDVRPort: WORD;UserName: PChar;PassWord: PChar;
  lpDeviceInfo: PNET_DVR_DEVICEINFO): longint; stdcall; external cNetSDK;
{���ܣ�ע���û���Ӳ��¼���}

function NET_DVR_Logout(LoginID: longint): Integer; stdcall;external cNetSDK;
{���ܣ�ע���û��˳�Ӳ��¼���}
function NET_DVR_CaptureJPEGPicture(LoginID: longint; lChannel: longint;
 lpJpegPara: PNET_DVR_JPEGPARA; sPicFileName: PChar):Boolean; stdcall;external cNetSDK;
{���ܣ�JPEG��ͼ}

implementation

end.
