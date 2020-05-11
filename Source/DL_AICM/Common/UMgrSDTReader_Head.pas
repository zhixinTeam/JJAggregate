unit UMgrSDTReader_Head;

interface

uses
  SysUtils, Windows, Classes, Forms;

const
  DLL_SDTAPI = 'sdtapi.dll';
  DLL_WLTRS = 'WltRS.dll';

  cReader_OperateOK  = 144;
  cReader_FindCardOK = 159;

  cTry_Times          = 2;      //ѯ������


type
  TIdCardInfoWChar = packed record
    Name: array[0..14] of WideChar;
    Sex : array[0..0] of WideChar;
    Nation: array[0..1] of WideChar;
    BirthDay:array[0..7] of WideChar;
    Addr : array[0..34] of WideChar;
    IdSN : array[0..17] of WideChar;
    IssueOrgan: array[0..14] of WideChar;
    VaildBegin: array[0..7] of WideChar;
    VaildEnd : array[0..7] of WideChar;
    theNewestAddr: array[0..34] of WideChar;
  end;

//�鿴���ڵ�ǰ������
function SDT_GetCOMBaud(iPort: integer; puiBaudRate: Pinteger): integer;stdcall;External DLL_SDTAPI;
{iPort[in]��ʾ�˿ڣ�puiBaudRate[out]�޷���ָ�룬ָ����ͨ���ڵ�ǰ�����ʣ�����ֵ
0X90-�ɹ���0x1-�˿ڴ�ʧ��/�˿ںŲ��Ϸ���0x5�޷����SAM_V�Ĳ����ʣ����ڲ����á�}


function SDT_StetCOMBaud(iPort: integer; uiCurrBaud: integer; uiSetBaud: integer): integer;stdcall;External DLL_SDTAPI;
{iPort[in]��ʾ�˿�, uiCurrBaud[in]���ø�APIǰ�����õ�ҵ���ն���SAM_Vͨ�ŵĲ�����(����Ĭ��Ϊ115200)
uiCurrBaudֻ��Ϊ115200,57600,378400,19200,9600�����uiCurrBaud��ֵ������Щֵ֮һ����������0x21������������õĲ�һ����
��������0x02��ʾ�������õ���API���ɹ���uiSetBaud[in]��Ҫ���õ�SAM_V������,ֻ��Ϊ(ͬ��)��Щֵ�����������Щ��ֵ������Ҳͬ��
��������0x90-�ɹ���0x1-�˿ڴ�ʧ��/�˿ںŲ��Ϸ���0x2-��ʱ�����ò��ɹ���0x21-uiCurrBaud��uiSetBaud���������ֵ����}
//����SAM_V�Ĵ��ڵĲ�����

function SDT_OpenPort(iPort: integer): integer;stdcall;External DLL_SDTAPI;
{iPort[in]��ʾ�˿ںţ�1-16(ʮ����)Ϊ���ڣ�1001-1016(ʮ����)ΪUSB�ڣ�ȱʡ��һ��USB�豸�˿���1001��
��������0x90-�򿪶˿ڳɹ�,1-�򿪶˿�ʧ��/�˿ںŲ��Ϸ�}
//�򿪴���/USB

function SDT_ClosePort(iPort: integer): integer;stdcall;External DLL_SDTAPI;
{iPort[in]��ʾ�˿ںţ�����ֵ0x90-�رմ��ڳɹ���0x01-�˿ںŲ��Ϸ�}
//�رմ���/USB

function SDT_ResetSAM(iPort: integer; ilfOpen: integer): integer;stdcall;External DLL_SDTAPI;
{iPort[in]��ʾ�˿ںţ�Ŀǰ���ں�USBֻ֧��16�������ڣ�0001-0016��USB��1001-1016��
ilfOpen[in]��ʾ���ڸú����ڲ��򿪺͹رմ��ڣ���0��ʾ��API�����ڲ������˴򿪴��ں͹رմ��ں�����֮ǰ����Ҫ����
SDT_OpenPort��SDT_ClosePort
����ֵ0x90-�ɹ������� ʧ��}
//��SAM_V��λ

//������Ƶ���������ͨ���ֽ���
function SDT_SetMaxRFByte(iPort: integer;ucByte: Char;blfOpen: integer):integer;stdcall;External DLL_SDTAPI;
{iPort[in]��ʾ�˿ںţ�ucByte[in]�޷����ַ�,24-255����ʾ��Ƶ���������ͨ���ֽ�����ilfOpen[in]�μ�SDT_ResetSAM
����ֵ0x90-�ɹ�,����-ʧ��}

//��SAM_V����״̬���
function SDT_GetSAMStatus(iPort: integer;ilfOpen: integer):integer;stdcall;External DLL_SDTAPI;
{iPort[in]��ʾ�˿ںţ�ilfOpen�μ�SDT_ResetSAM
����ֵ0x90-SAM_V������0x60-�Լ�ʧ�ܣ����ܽ����������-����ʧ��}

//��ȡSAM_V�ı��
function SDT_GetSAMID(iPort: integer;pusSAMID: Pbyte;ilfOpen: integer):integer;stdcall;External DLL_SDTAPI;
{iPort[in]��ʾ�˿ںţ�pusSAMID[out]�޷����ַ���ָ��SAM_V��ţ�16�ֽڣ�
����ֵ0x90-�ɹ�������-ʧ��}


//��ȡSAM_V�ı��
function SDT_GetSAMIDToStr(iPort: integer;pusSAMID: Pbyte;ilfOpen: integer):integer;stdcall;External DLL_SDTAPI;
{iport[in]��ʾ�˿ںţ�pusSAMID[out]SAM_V���,ilfOpen[in]�������μ�SDT_ResetSAM
����ֵ0x90-�ɹ�������-ʧ��}

//��ʼ�ҿ�
function SDT_StartFindIDCard(iPort: integer; var pucManaInfo: Integer; ilfOpen: integer):integer;stdcall;External DLL_SDTAPI;
{iport[in]��ʾ�˿ںţ�pucManaInfo[out]�޷���ָ�룬֤/��оƬ����ţ�4���ֽڣ�ilfOpen[in]�μ�SDT_ResetSAM
����ֵ0x9f-�ҿ��ɹ���0x80-�ҿ�ʧ��}

//ѡ��
function SDT_SelectIDCard(iPort: integer; var pucManaMsg: integer;ilfOpen: integer):integer;stdcall;External DLL_SDTAPI;
{iPort[in]��ʾ�˿ںţ�pucManaMsg[out]�޷���ָ�룬֤/��оƬ���кţ�8���ֽڣ�ilfOpen[in]�μ�SDT_ResetSAM
����ֵ0x90-ѡ���ɹ���0x81-ѡ��ʧ��}


//��ȡ��������
function SDT_ReadMngInfo(iPort: integer;pucManageMsg: Pbyte;ilfOpen: integer):integer;stdcall;External DLL_SDTAPI;
{iPort[in]��ʾ�˿ںţ�pucManageMsg[out]�޷����ַ�ָ�룬�������ţ�28�ֽڣ�ilfOpen[in]
����ֵ0x90-�ɹ�������-��ʧ��}


//��ȡ֤/���̶���Ϣ
function SDT_ReadBaseMsg(iPort: integer;pucCHMsg: Pbyte; var puiCHMsgLen: Integer;pucPHMsg: Pbyte; var puiPHMsgLen: Integer;ilfOpen: integer):integer;stdcall;External DLL_SDTAPI;
{iPort[in]��ʾ�˿ںţ�pucCHMsg[out]ָ�������������Ϣ��puiCHMsgLen[out]ָ�������������Ϣ����
pucPHMsg[out]ָ���������Ƭ��Ϣ��puiPHMsgLen[out]ָ���������Ƭ��Ϣ���ȣ�ilfOpen[in]�μ�SDT_ResetSAM
����ֵ0x90-���̶���Ϣ�ɹ����������̶���Ϣʧ��}


//��ȡ׷����Ϣ
function SDT_ReadNewAppMsg(iPort: integer;pucAppMsg: Pbyte;puiAppMsgLen: Pinteger;ilfOpen: integer):integer;stdcall;External DLL_SDTAPI;
{iPort[in]��ʾ�˿ںţ�pucAppMsg[out]ָ�������׷����Ϣ��puiAppMsgLen[out]ָ�������׷����Ϣ���ȣ�ilfOpen[in]�μ�SDT_ResetSAM
����ֵ0x90-��ȡ׷����Ϣ�ɹ�������-��ȡ׷����Ϣʧ��}

//�����������֤��Ϣ���浽�ļ�
function SDT_ReadBaseMsgToFile(iPortID: Integer; fileName1: PAnsiChar; var puiCHMsgLen: Integer; fileName2: PAnsiChar; var puiPHMsgLen: Integer; iIfOpen: Integer): Integer; stdcall; external DLL_SDTAPI name 'SDT_ReadBaseMsgToFile';

//��Ƭ���뺯��
function GetBmp(Wlt_File: PChar;intf: integer):integer;stdcall;External DLL_WLTRS;
{Wlt_File-wlt�ļ�����intf�Ķ��豸ͨѶ�ӿ�����(1-RS-232C,2-USB)
����ֵ������*.bmp�����·�����Ϣ:1-��Ƭ������ȷ��0-����sdtapi.dll����,-1-��Ƭ�������-2-wlt�ļ���׺����
-3-wlt�ļ��򿪴���-4-wlt�ļ���ʽ����-5-���δ��Ȩ��-6-�豸���Ӵ���}

function EthnicNoToName(ANo: string): string;
function GetBmp_ByFile(nFile: string; nFlag: Integer=2): Integer;
function ReadICCard(var ACardInfo: TIdCardInfoWChar; var AErrMsg: string): Boolean;

resourcestring
  //�����ļ�
  TIP_FILE_TXT = 'wz.txt';
  TIP_FILE_BMP = 'wz.bmp';
  TIP_FILE_WLT = 'wz.wlt';

  //��ʾ��Ϣ
  TIP_OK    = '����ɹ�';
  TIP_TITLE = '��ʾ';
  TIP_ICREADER_RESET_FAILED = '�豸��λʧ�ܣ�';
  TIP_ICREADER_NO_CARD = 'δ�ſ����߿�δ�źã������·ſ���';
  TIP_ICREADER_READ_FAILED = '����ʧ�ܣ�';
  TIP_ICREADER_CALL_DLL_FAILED = '����sdtapi.dll����';
  TIP_ICREADER_CALL_WLTDLL_FAILED = '����WltRS.dll����';
  TIP_ICREADER_CALL_GetBmp_FAILED = '��ȡ����GetBmp����';
  TIP_ICREADER_PICTURE_DECODE_FAILED = '��Ƭ�������';
  TIP_ICREADER_WLT_FILE_EXTEND_FAILED = 'wlt�ļ���׺����';
  TIP_ICREADER_WLT_FILE_OPEN_FAILED = 'wlt�ļ��򿪴���';
  TIP_ICREADER_WLT_FILE_FORMAT_FAILED = 'wlt�ļ���ʽ����';
  TIP_ICREADER_NO_LICENSE = '���δ��Ȩ��';
  TIP_ICREADER_DEVICE_FAILED = '�豸���Ӵ���';
  TIP_PRINT_NO_CARD_FOUND = 'δ�ҵ����֤�����Ϣ���뽫֤�����������Ϻ����ԣ�';
  TIP_ICREADER_SAVE_SUCCESS = '����ɹ��������Ϣ���Զ�¼�뱾�����ݿ⣡';
  TIP_ICREADER_BLACK_CARD_FOUND = '���ֺ������ڰ�������Ա��';
  ERROR_ICREADER_OPEN_PORT = '�˿ڴ�ʧ�ܣ�������Ӧ�Ķ˿ڻ����������Ӷ�������';

var
  LstEthnic: TStrings;

implementation

function GetBmp_ByFile(nFile: string; nFlag: Integer=2): Integer;
var nHandle: Cardinal;
    nFunc:function(Wlt_File: PChar;intf: integer):integer;
begin
  nHandle := LoadLibrary(DLL_WLTRS);
  try
    if nHandle <> 0 then
    begin
      @nFunc:=GetProcAddress(nHandle, 'GetBmp');
      if Assigned(@nFunc) then
           Result := nFunc(PChar(nFile), nFlag)
      else Result := -8;
    end else Result := -7;
  finally
    FreeLibrary(nHandle);
  end;
end;

function EthnicNoToName(ANo: string): string;
begin
  Result:= LstEthnic.Values[ANo];
end;

function FormatDateStr(AValue: string): string;
begin
  Result:= Copy(AValue, 1, 4) + '-' +
  Copy(AValue, 5, 2) + '-' +
  Copy(AValue, 7, 2);
end;

function ReadICCard(var ACardInfo: TIdCardInfoWChar; var AErrMsg: string): Boolean;
var
  iPort: Integer;
  intOpenPortRtn: Integer;
  bUsbPort: Boolean;
  EdziPortID: Integer;
  iRet: Integer;
  pucIIN: Integer;
  EdziIfOpen: Integer;
  pucSN: Integer;
  puiCHMsgLen: Integer;
  puiPHMsgLen: Integer;
  fs: TFileStream;
begin
  AErrMsg:= '';
  //Result:= False;
  bUsbPort:= False;
  EdziIfOpen:= 1;
  EdziPortID:= 0;
  puiCHMsgLen:= 0;
  puiPHMsgLen:= 0;
  //���usb�ڵĻ������ӣ������ȼ��usb
  for iPort := 1001 to 1016 do
  begin
    intOpenPortRtn:= SDT_OpenPort(iPort);
    if intOpenPortRtn = 144 then
    begin
      EdziPortID:= iPort;
      bUsbPort:= true;
      break;
    end;
  end;

  //��⴮�ڵĻ�������
  if not bUsbPort then
  begin
    for iPort := 1 to 2 do
    begin
      intOpenPortRtn:= SDT_OpenPort(iPort);
      if intOpenPortRtn = 144 then
      begin
        EdziPortID:= iPort;
        bUsbPort:= False;
        Break;
      end;
    end;
  end;

  if intOpenPortRtn <> 144 then
  begin
    AErrMsg:= ERROR_ICREADER_OPEN_PORT;
    Result:= False;
    Exit;
  end;
  //�����ҿ�
  iRet:= SDT_StartFindIDCard(EdziPortID, pucIIN, EdziIfOpen);
  if iRet <> 159 then
  begin
    iRet:= SDT_StartFindIDCard(EdziPortID, pucIIN, EdziIfOpen);//���ҿ�
    if iRet <> 159 then
    begin
      SDT_ClosePort(EdziPortID);
      AErrMsg:= TIP_ICREADER_NO_CARD;
      Result:= False;
      Exit;
    end;
  end;
  //ѡ��
  iRet:= SDT_SelectIDCard(EdziPortID, pucSN, EdziIfOpen);
  if iRet <> 144 then
  begin
    iRet:= SDT_SelectIDCard(EdziPortID, pucSN, EdziIfOpen);
    if iRet <> 144 then
    begin
      SDT_ClosePort(EdziPortID);
      AErrMsg:= TIP_ICREADER_READ_FAILED;
      Result:= False;
      Exit;
    end;
  end;

  //ע�⣬������û�������Ӧ�ó���ǰĿ¼�Ķ�дȨ��
  if FileExists('wz.txt') then SysUtils.DeleteFile('wz.txt');
  if FileExists('zp.bmp') then SysUtils.DeleteFile('zp.bmp');
  if FileExists('zp.wlt') then SysUtils.DeleteFile('zp.wlt');

  iRet:= SDT_ReadBaseMsgToFile(EdziPortID, PAnsiChar(AnsiString('wz.txt')), puiCHMsgLen, PAnsiChar(AnsiString('zp.wlt')), puiPHMsgLen, 1);
  if iRet <> 144 then
  begin
    SDT_ClosePort(EdziPortID);
    AErrMsg:= TIP_ICREADER_READ_FAILED;
    Result:= False;
    Exit;
  end;

  SDT_ClosePort(EdziPortID);
  //�ر�

  //���������Ƭ��ע�⣬�����C�̸�Ŀ¼��û�л��߳��̵���Ȩ�ļ�Termb.Lic����Ƭ��������ʧ��
  if bUsbPort then
    iRet:= GetBmp_ByFile(PAnsiChar(AnsiString('zp.wlt')), 2)
  else
    iRet:= GetBmp_ByFile(PAnsiChar(AnsiString('zp.wlt')), 1);

  case iRet of
    0:
    begin
    //Application.MessageBox(TIP_ICREADER_CALL_DLL_FAILED);
    end;
    1: //����
    begin
    end;
    -1:
    begin
    //Application.MessageBox(TIP_ICREADER_PICTURE_DECODE_FAILED);
    end;
    -2:
    begin
    //Application.MessageBox(TIP_ICREADER_WLT_FILE_EXTEND_FAILED);
    end;
    -3:
    begin
    //Application.ShowMessage(TIP_ICREADER_WLT_FILE_OPEN_FAILED);
    end;
    -4:
    begin
    //Application.MessageBox(TIP_ICREADER_WLT_FILE_FORMAT_FAILED);
    end;
    -5:
    begin
    //Application.MessageBox(TIP_ICREADER_NO_LICENSE);
    end;
    -6:
    begin
    //Application.MessageBox(TIP_ICREADER_DEVICE_FAILED);
    end;
  end;

  fs:= TFileStream.Create('wz.txt', fmOpenRead);
  fs.Position:= 0;
  fs.Read(ACardInfo ,SizeOf(ACardInfo));
  fs.Free;
  //
  // ���� ��AnsiString(idCardInfo.Name);
  // �Ա� �� if AnsiString(idCardInfo.Sex)= '1' then �Ա�:= '��' else �Ա�:= 'Ů';
  // ���� �� EthnicNoToName(AnsiString(idCardInfo.Nation));
  // ���������գ� FormatDateStr(AnsiString(idCardInfo.BirthDay));
  // סַ�� Address:= Trim(AnsiString(idCardInfo.Addr));
  //���֤���룺 Id:= Trim(AnsiString(idCardInfo.IdSN));
  //��֤������ Place:= Trim(AnsiString(idCardInfo.IssueOrgan));
  //��Ч���ڿ�ʼ ValidDateStart:= FormatDateStr(AnsiString(idCardInfo.VaildBegin));
  //��Ч���ڽ��� if Trim(AnsiString(idCardInfo.VaildEnd)) = '����' then
  // ValidDateEnd:= FormatDateTime('yyyy-MM-dd', MaxDateTime)
  // else
  // ValidDateEnd:= FormatDateStr(AnsiString(idCardInfo.VaildEnd));
  //
  Result:= True;
end;

initialization
  LstEthnic:= TStringList.Create;
  with LstEthnic do
  begin
    Add('01' + '=' + '����');
    Add('02' + '=' + '�ɹ���');
    Add('03' + '=' + '����');
    Add('04' + '=' + '����');
    Add('05' + '=' + 'ά�����');
    Add('06' + '=' + '����');
    Add('07' + '=' + '����');
    Add('08' + '=' + '׳��');
    Add('09' + '=' + '������');
    Add('10' + '=' + '������');
    Add('11' + '=' + '����');
    Add('12' + '=' + '����');
    Add('13' + '=' + '����');
    Add('14' + '=' + '����');
    Add('15' + '=' + '������');
    Add('16' + '=' + '������');
    Add('17' + '=' + '��������');
    Add('18' + '=' + '����');
    Add('19' + '=' + '����');
    Add('20' + '=' + '������');
    Add('21' + '=' + '����');
    Add('22' + '=' + '���');
    Add('23' + '=' + '��ɽ��');
    Add('24' + '=' + '������');
    Add('25' + '=' + 'ˮ��');
    Add('26' + '=' + '������');
    Add('27' + '=' + '������');
    Add('28' + '=' + '������');
    Add('29' + '=' + '�¶�������');
    Add('30' + '=' + '����');
    Add('31' + '=' + '�ﺲ����');
    Add('32' + '=' + '������');
    Add('33' + '=' + 'Ǽ��');
    Add('34' + '=' + '������');
    Add('35' + '=' + '������');
    Add('36' + '=' + 'ë����');
    Add('37' + '=' + '������');
    Add('38' + '=' + '������');
    Add('39' + '=' + '������');
    Add('40' + '=' + '������');
    Add('41' + '=' + '��������');
    Add('42' + '=' + 'ŭ��');
    Add('43' + '=' + '���α����');
    Add('44' + '=' + '����˹��');
    Add('45' + '=' + '���¿���');
    Add('46' + '=' + '�°���');
    Add('47' + '=' + '������');
    Add('48' + '=' + 'ԣ����');
    Add('49' + '=' + '����');
    Add('50' + '=' + '��������');
    Add('51' + '=' + '������');
    Add('52' + '=' + '���״���');
    Add('53' + '=' + '������');
    Add('54' + '=' + '�Ű���');
    Add('55' + '=' + '�����');
    Add('56' + '=' + '��ŵ��');
    Add('57' + '=' + '����');
    Add('98' + '=' + '������뼮');
  end;
finalization
  LstEthnic.Free;
end.
//������׼����sdtapi.dll WltRS.dll WltRS.lic �������ļ�,����ͬĿ¼��
