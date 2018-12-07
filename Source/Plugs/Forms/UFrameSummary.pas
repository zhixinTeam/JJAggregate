{*******************************************************************************
  ����: dmzn@163.com 2013-11-27
  ����: ����ժҪ
*******************************************************************************}
unit UFrameSummary;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  UDataModule, UFrameBase, ExtCtrls, Grids, ValEdit, UZnValueList;

{$I Link.Inc}
type
  TfFrameSummary = class(TfFrameBase)
    ListSummary: TZnValueList;
    TimerMon: TTimer;
    procedure TimerMonTimer(Sender: TObject);
  private
    { Private declarations }
    FSummaryChanged: Boolean;
    procedure NewSummaryItem(const nKey,nFlag: string;
     nImage: Integer = cIcon_Key);
    procedure UpdateItem(const nFlag,nValue: string;
     nImage: Integer = cIcon_Value);
    procedure UpdateSummary(const nNewItem: Boolean);
    //����ժҪ
    procedure LoadConfig(const nLoad: Boolean);
    //��������
  public
    { Public declarations }
    procedure OnCreateFrame; override;
    procedure OnDestroyFrame; override;
    class function FrameID: integer; override;
  end;

implementation

{$R *.dfm}

uses
  ULibFun, IniFiles, UMgrControl, UMgrDBConn, USAPConnection, UMgrParam,
  UROModule, USmallFunc, USysLoger, UMITConst;

//Desc: ��¼��־
procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(TfFrameSummary, '����ʱժҪ', nEvent);
end;

class function TfFrameSummary.FrameID: integer;
begin
  Result := cFI_FrameSummary;
end;

procedure TfFrameSummary.OnCreateFrame;
begin
  inherited;
  Name := MakeFrameName(FrameID);
  ListSummary.DoubleBuffered := True;

  LoadConfig(True);
  UpdateSummary(True);
end;

//Desc: ˢ�·���״̬
procedure TfFrameSummary.OnDestroyFrame;
begin
  inherited;
  LoadConfig(False);
end;

procedure TfFrameSummary.LoadConfig(const nLoad: Boolean);
var nIni: TIniFile;
begin
  nIni := TIniFile.Create(gPath + sFormConfig);
  try
    if nLoad then
    begin
      ListSummary.ColWidths[0] := nIni.ReadInteger(Name, 'ListCol0', 100);
    end else
    begin
      nIni.WriteInteger(Name, 'ListCol0', ListSummary.ColWidths[0]);
    end;
  finally
    nIni.Free;
  end;
end;

//------------------------------------------------------------------------------
procedure TfFrameSummary.TimerMonTimer(Sender: TObject);
begin
  {$IFNDEF DEBUG}
  if not Application.Active then Exit;
  {$ENDIF}

  if Parent.Controls[Parent.ControlCount - 1] = Self then
    UpdateSummary(False);
  //xxxxx
end;

//Desc: ����б���
procedure TfFrameSummary.NewSummaryItem(const nKey, nFlag: string;
  nImage: Integer);
var nPic: PZnVLPicture;
begin
  nPic := ListSummary.AddPicture(nKey, '', nFlag);
  if nImage < 0 then
    nImage := FDM.BaseIconRandomIndex;
  //xxxxx

  nPic.FKey.FLoop := 1;
  nPic.FKey.FIcon := TBitmap.Create;
  FDM.ImageBase.GetBitmap(nImage, nPic.FKey.FIcon);

  nPic.FValue.FLoop := 1;
  nPic.FValue.FIcon := TBitmap.Create;
end;

//Desc: �����б�������
procedure TfFrameSummary.UpdateItem(const nFlag,nValue: string;
  nImage: Integer);
var nData: PZnVLData;
    nPic: PZnVLPicture;
begin
  nData := ListSummary.FindData(nFlag);
  nPic := nData.FData;

  if nImage < 0 then
    nImage := FDM.BaseIconRandomIndex;
  //xxxx

  if (nPic.FValue.FText <> nValue) or (nPic.FValue.FFlag <> nImage) then
  begin
    FSummaryChanged := True;
    nPic.FValue.FText := nValue;

    if nPic.FValue.FFlag <> nImage then
    begin
      nPic.FValue.FFlag := nImage;
      FDM.ImageBase.GetBitmap(nImage, nPic.FValue.FIcon);
    end;
  end;
end;

//Desc: �����б�
procedure TfFrameSummary.UpdateSummary(const nNewItem: Boolean);
var nStr: string;
    nIdx: Integer;

    function ItemFlag: string;
    begin
      Result := nStr + IntToStr(nIdx);
      Inc(nIdx);
    end;
begin
  if nNewItem then
  begin
    ListSummary.TitleCaptions.Clear;
    //Ĭ�ϱ�ͷ

    nIdx := 1;
    nStr := 'srv_status';
    
    ListSummary.AddData('������Ϣ', '', nil, nStr, vtGroup);
    NewSummaryItem('����״̬', ItemFlag);
    NewSummaryItem('��������', ItemFlag);
    NewSummaryItem('HTTP״̬', ItemFlag);
    NewSummaryItem('HTTP�˿�', ItemFlag);
    NewSummaryItem('HTTP����', ItemFlag);
    NewSummaryItem('HTTP�', ItemFlag);
    NewSummaryItem('HTTP��ֵ', ItemFlag);
    NewSummaryItem('TCP.״̬', ItemFlag);
    NewSummaryItem('TCP.�˿�', ItemFlag);
    NewSummaryItem('TCP.����', ItemFlag);
    NewSummaryItem('TCP.�', ItemFlag);
    NewSummaryItem('TCP.��ֵ', ItemFlag);
    NewSummaryItem('��������', ItemFlag);
    NewSummaryItem('ҵ������', ItemFlag);
    NewSummaryItem('�������', ItemFlag);

    {$IFDEF DBPool}
    nIdx := 1;
    nStr := 'db_status';

    ListSummary.AddData('DB���ӳ�', '', nil, nStr, vtGroup);
    NewSummaryItem('��������', ItemFlag);
    NewSummaryItem('�������', ItemFlag);
    NewSummaryItem('���Ӳ���', ItemFlag);
    NewSummaryItem('���ӷ���', ItemFlag);
    NewSummaryItem('���Ӷ���', ItemFlag);
    NewSummaryItem('��������', ItemFlag);
    NewSummaryItem('���鸴��', ItemFlag);
    NewSummaryItem('��ǰ����', ItemFlag);
    NewSummaryItem('���з�ֵ', ItemFlag);
    NewSummaryItem('��ֵʱ��', ItemFlag);
    {$ENDIF}

    {$IFDEF SAP}
    nIdx := 1;
    nStr := 'sap_status';

    ListSummary.AddData('SAP���ӳ�', '', nil, nStr, vtGroup);
    NewSummaryItem('��������', ItemFlag);
    NewSummaryItem('�������', ItemFlag);
    NewSummaryItem('���Ӳ���', ItemFlag);
    NewSummaryItem('���Ӷ���', ItemFlag);
    NewSummaryItem('��������', ItemFlag);
    NewSummaryItem('���Ӵ���', ItemFlag);
    NewSummaryItem('���ö���', ItemFlag);
    NewSummaryItem('��ǰ����', ItemFlag);
    NewSummaryItem('���ӷ�ֵ', ItemFlag);
    NewSummaryItem('��ֵʱ��', ItemFlag);
    NewSummaryItem('���ӷ�ֵ', ItemFlag);
    NewSummaryItem('��ֵʱ��', ItemFlag);
    {$ENDIF}

    Exit;
  end;

  FSummaryChanged := False;
  //update flag
  
  with ROModule.LockModuleStatus^ do
  try
    nIdx := 1;
    nStr := 'srv_status';

    if FSrvTCP or FSrvHttp then
         UpdateItem(ItemFlag, '������', cIcon_Run)
    else UpdateItem(ItemFlag, '�ر�', cIcon_Stop);

    if gSysParam.FParam = '' then
         UpdateItem(ItemFlag, '��')
    else UpdateItem(ItemFlag, gSysParam.FParam);

    if FSrvHttp then
         UpdateItem(ItemFlag, '������', cIcon_Run)
    else UpdateItem(ItemFlag, '�ر�', cIcon_Stop);

    with gParamManager do
    begin
      if Assigned(ActiveParam) and Assigned(ActiveParam.FPerform) then
           UpdateItem(ItemFlag, IntToStr(ActiveParam.FPerform.FPortHttp))
      else UpdateItem(ItemFlag, 'δ֪');
    end;

    UpdateItem(ItemFlag, Format('%d ��', [FNumHttpTotal]));
    UpdateItem(ItemFlag, Format('%d ��', [FNumHttpActive]));
    UpdateItem(ItemFlag, Format('%d ��', [FNumHttpMax]));

    if FSrvTCP then
         UpdateItem(ItemFlag, '������', cIcon_Run)
    else UpdateItem(ItemFlag, '�ر�', cIcon_Stop);

    with gParamManager do
    begin
      if Assigned(ActiveParam) and Assigned(ActiveParam.FPerform) then
           UpdateItem(ItemFlag, IntToStr(ActiveParam.FPerform.FPortTCP))
      else UpdateItem(ItemFlag, 'δ֪');
    end;

    UpdateItem(ItemFlag, Format('%d ��', [FNumTCPTotal]));
    UpdateItem(ItemFlag, Format('%d ��', [FNumTCPActive]));
    UpdateItem(ItemFlag, Format('%d ��', [FNumTCPMax]));
    
    UpdateItem(ItemFlag, Format('%d ��', [FNumConnection]));
    UpdateItem(ItemFlag, Format('%d ��', [FNumBusiness]));
    UpdateItem(ItemFlag, Format('%d ��', [FNumActionError]));
  finally
    ROModule.ReleaseStatusLock;
  end;

  {$IFDEF DBPool}
  with gDBConnManager.Status do
  begin
    nIdx := 1;
    nStr := 'db_status';

    UpdateItem(ItemFlag, Format('%d ��', [FNumObjRequest]));
    UpdateItem(ItemFlag, Format('%d ��', [FNumObjRequestErr]));
    UpdateItem(ItemFlag, Format('%d ��', [FNumConnParam]));
    UpdateItem(ItemFlag, Format('%d ��', [FNumConnItem]));
    UpdateItem(ItemFlag, Format('%d ��', [FNumConnObj]));

    UpdateItem(ItemFlag, Format('%d ��', [FNumObjConned]));
    UpdateItem(ItemFlag, Format('%d ��', [FNumObjReUsed]));
    UpdateItem(ItemFlag, Format('%d ��', [FNumObjWait]));
    UpdateItem(ItemFlag, Format('%d ��', [FNumWaitMax]));
    UpdateItem(ItemFlag, Format('%s', [DateTime2Str(FNumMaxTime)]));
  end;
  {$ENDIF}

  {$IFDEF SAP}
  with gSAPConnectionManager.Status do
  begin
    nIdx := 1;
    nStr := 'sap_status';

    UpdateItem(ItemFlag, Format('%d ��', [FNumConnRequest]));
    UpdateItem(ItemFlag, Format('%d ��', [FNumRequestErr]));
    UpdateItem(ItemFlag, Format('%d ��', [FNumConnParam]));
    UpdateItem(ItemFlag, Format('%d ��', [FNumConnItem]));
    UpdateItem(ItemFlag, Format('%d ��', [FNumConned]));
    UpdateItem(ItemFlag, Format('%d ��', [FNumConnTotal]));

    UpdateItem(ItemFlag, Format('%d ��', [FNumReUsed]));
    UpdateItem(ItemFlag, Format('%d ��', [FNumWait]));
    UpdateItem(ItemFlag, Format('%d ��', [FNumConnMax]));
    UpdateItem(ItemFlag, Format('%s', [DateTime2Str(FTimeConnMax)]));
    UpdateItem(ItemFlag, Format('%d ��', [FNumWaitMax]));
    UpdateItem(ItemFlag, Format('%s', [DateTime2Str(FTimeWaitMax)]));
  end;
  {$ENDIF}

  if FSummaryChanged then
    ListSummary.Invalidate;
  //refresh
end;

initialization
  gControlManager.RegCtrl(TfFrameSummary, TfFrameSummary.FrameID);
end.
