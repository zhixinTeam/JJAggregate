{*******************************************************************************
  ����: dmzn@ylsoft.com 2007-10-09
  ����: ��Ŀͨ�ó�,�������嵥Ԫ
*******************************************************************************}
unit USysConst;

interface

uses
  SysUtils, Classes, UBusinessConst, UBusinessWorker, UChannelChooser,
  UMgrChannel, UMgrTTCEDispenser, UClientWorker, UMITPacker, USysMAC,
  UDataModule, USysDB, USysLoger;

const
  cMakeBillLong     = 60;                            //����ʱ��(��)
  cShowDlgLong      = 10;                            //��ʾ��(��)

  cBus_CheckCode    = 10;                            //��������
  cBus_CheckValue   = 20;                            //��������
  cBus_CheckTruck   = 21;                            //��鳵�ƺ�
  cBus_BillDone     = 22;                            //�����ɹ�

type
  TSysParam = record
    FUserID     : string;                            //�û���ʶ
    FUserName   : string;                            //��ǰ�û�
    FLocalIP    : string;                            //����IP
    FLocalMAC   : string;                            //����MAC
    FLocalName  : string;                            //��������
    
    FMITServURL : string;                            //ҵ�����
    FHardMonURL : string;                            //Ӳ���ػ�
    FWechatURL  : string;                            //΢�ŷ���
  end;
  //ϵͳ����

  TZhiKaItem = record
    FCode       : string;                            //�������
    FZhiKa      : string;                            //ֽ�����
    FCusID      : string;                            //�ͻ����
    FCusName    : string;                            //�ͻ�����
    FMoney      : Double;                            //���ý��
    FCard       : string;                            //�ſ����
    FBill       : string;                            //��������
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
  //��ͷ����

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
  //�Ի���
  
var
  gPath: string;                                     //��������·��
  gSysParam:TSysParam;                               //���򻷾�����
  gReaderItem: TReaderItem;                          //������������
  gShowDlg: TShowDlg;                                //����ʽ�Ի���

  gZhiKa: TZhiKaItem;                                //��ǰֽ����Ϣ
  gStockTypes: TStockTypeItems;                      //�۸��
  gStockList: array of TStockItem;                   //��ѡ�����б�

ResourceString
  sHint               = '��ʾ';                      //�Ի������
  sWarn               = '����';                      //==
  sAsk                = 'ѯ��';                      //ѯ�ʶԻ���
  sError              = 'δ֪����';                  //����Ի���

  sDispenser          = 'AICM';                      //��������ʶ
  sConfigFile         = 'Config.Ini';                //�������ļ�
  sFormConfig         = 'FormInfo.ini';              //��������
  sDBConfig           = 'DBConn.ini';                //��������
  sCloseQuery         = 'ȷ��Ҫ�˳�������?';         //�������˳�

//------------------------------------------------------------------------------
procedure WriteLog(const nEvent: string);
//Desc: ��¼��־
procedure InitSystemObject;
//��ʼ��ϵͳ����
function IsZhiKaValid(var nZhiKa,nHint: string;
 const nIsCode: Boolean = False): Boolean;
//ֽ���Ƿ���Ч
function GetZhikaValidMoney(nZhiKa: string): Double;
//ֽ�����ý�
function IsCustomerCreditValid(const nCusID: string): Boolean;
//��֤nCusID�Ƿ����㹻��Ǯ,������û�й���
function LoadStockItemsPrice(const nCusID: string;
  var nItems: TStockTypeItems): Boolean;
//����ͻ��ļ۸��嵥
function SaveBill(const nBillData: string): string;
//���潻����
function SaveBillCard(const nBill, nCard: string): Boolean;
//���潻�����ſ�

implementation

//Desc: ��¼��־
procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(TDispenserManager, '����ҵ��', nEvent);
end;

//��ʼ��ϵͳ����
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
//Parm: ����;����;����;���
//Desc: �����м���ϵ�ҵ���������
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
//Parm: ����;����;����;���
//Desc: �����м���ϵ����۵��ݶ���
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
//Parm: ����;����;����;���
//Desc: �����м���ϵ����۵��ݶ���
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
//Parm: ����;����;����;�����ַ;���
//Desc: �����м���ϵ����۵��ݶ���
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
//Parm: ֽ����[in,out];��ʾ��Ϣ[out]�ͻ����[out];�������
//Desc: ��֤nZhiKa�Ƿ���Ч
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
//Parm: ֽ����
//Desc: ��ȡnZhiKa�Ŀ��ý�
function GetZhikaValidMoney(nZhiKa: string): Double;
var nOut: TWorkerBusinessCommand;
begin
  if CallBusinessCommand(cBC_GetZhiKaMoney, nZhiKa, '', @nOut) then
       Result := StrToFloat(nOut.FData)
  else Result := 0;
end;

//Date: 2014-09-14
//Parm: �ͻ����
//Desc: ��֤nCusID�Ƿ����㹻��Ǯ,������û�й���
function IsCustomerCreditValid(const nCusID: string): Boolean;
var nOut: TWorkerBusinessCommand;
begin
  if CallBusinessCommand(cBC_CustomerHasMoney, nCusID, '', @nOut) then
       Result := nOut.FData = sFlag_Yes
  else Result := False;
end;

//Date: 2018-12-14
//Parm: �ͻ����;�۸��嵥
//Desc: ����nCusID�ͻ���ǰ�ļ۸��嵥
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
//Parm: ��������
//Desc: ���潻����,���ؽ��������б�
function SaveBill(const nBillData: string): string;
var nOut: TWorkerBusinessCommand;
begin
  if CallBusinessSaleBill(cBC_SaveBills, nBillData, '', @nOut) then
       Result := nOut.FData
  else Result := '';
end;

//Date: 2014-09-17
//Parm: ��������;�ſ�
//Desc: ��nBill.nCard
function SaveBillCard(const nBill, nCard: string): Boolean;
var nOut: TWorkerBusinessCommand;
begin
  Result := CallBusinessSaleBill(cBC_SaveBillCard, nBill, nCard, @nOut);
end;

end.


