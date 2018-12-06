{*******************************************************************************
  ����: juner11212436@163.com 2018-01-18
  ����: �������
*******************************************************************************}
unit UFrameAuditTruck;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls,
  IniFiles, UFrameNormal, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter, cxData,
  cxDataStorage, cxEdit, DB, cxDBData, cxContainer, cxTextEdit, Menus,
  dxLayoutControl, cxMaskEdit, cxButtonEdit, ADODB, cxLabel, UBitmapPanel,
  cxSplitter, cxGridLevel, cxClasses, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGrid,
  ComCtrls, ToolWin;

type
  TfFrameAuditTruck = class(TfFrameNormal)
    PMenu1: TPopupMenu;
    cxLevel2: TcxGridLevel;
    N1: TMenuItem;
    N16: TMenuItem;
    N2: TMenuItem;
    EditSerial: TcxButtonEdit;
    dxLayout1Item1: TdxLayoutItem;
    EditTruck: TcxButtonEdit;
    dxLayout1Item3: TdxLayoutItem;
    EditDate: TcxButtonEdit;
    dxLayout1Item2: TdxLayoutItem;
    cxTextEdit1: TcxTextEdit;
    dxLayout1Item6: TdxLayoutItem;
    cxTextEdit3: TcxTextEdit;
    dxLayout1Item7: TdxLayoutItem;
    cxTextEdit2: TcxTextEdit;
    dxLayout1Item4: TdxLayoutItem;
    cxLevel3: TcxGridLevel;
    N3: TMenuItem;
    N4: TMenuItem;
    N5: TMenuItem;
    procedure EditDatePropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure EditTruckPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure BtnAddClick(Sender: TObject);
    procedure cxGrid1ActiveTabChanged(Sender: TcxCustomGrid;
      ALevel: TcxGridLevel);
    procedure N2Click(Sender: TObject);
    procedure BtnRefreshClick(Sender: TObject);
    procedure BtnDelClick(Sender: TObject);
    procedure cxView1DblClick(Sender: TObject);
    procedure N1Click(Sender: TObject);
    procedure N3Click(Sender: TObject);
    procedure N4Click(Sender: TObject);
    procedure N5Click(Sender: TObject);
  private
    { Private declarations }
  protected
    FStart,FEnd: TDate;
    //ʱ������
    FStatus: Integer;
    procedure OnCreateFrame; override;
    procedure OnDestroyFrame; override;
    procedure OnLoadGridConfig(const nIni: TIniFile); override;
    procedure OnSaveGridConfig(const nIni: TIniFile); override;
    procedure OnInitFormData(var nDefault: Boolean; const nWhere: string = '';
     const nQuery: TADOQuery = nil); override;
    {*��ѯSQL*}
  public
    { Public declarations }
    class function FrameID: integer; override;
  end;

implementation

{$R *.dfm}
uses
  ULibFun, UMgrControl, USysBusiness, UBusinessConst, UFormBase, USysDataDict,
  UDataModule, UFormDateFilter, UForminputbox, USysConst, USysDB, USysGrid,
  UBusinessPacker, UFormWait;

//------------------------------------------------------------------------------
class function TfFrameAuditTruck.FrameID: integer;
begin
  Result := cFI_FrameAuditTruck;
end;

procedure TfFrameAuditTruck.OnCreateFrame;
begin
  inherited;
  InitDateRange(Name, FStart, FEnd);
end;

procedure TfFrameAuditTruck.OnDestroyFrame;
begin
  SaveDateRange(Name, FStart, FEnd);
  inherited;
end;

procedure TfFrameAuditTruck.OnLoadGridConfig(const nIni: TIniFile);
begin
  cxGrid1.ActiveLevel := cxLevel1;
  cxGrid1ActiveTabChanged(cxGrid1, cxGrid1.ActiveLevel);

  gSysEntityManager.BuildViewColumn(cxView1, 'MAIN_D11');
  InitTableView(Name, cxView1, nIni);
  FStatus := 0;
end;

procedure TfFrameAuditTruck.OnSaveGridConfig(const nIni: TIniFile);
begin
  SaveUserDefineTableView(Name, cxView1, nIni);
end;

procedure TfFrameAuditTruck.OnInitFormData(var nDefault: Boolean;
  const nWhere: string; const nQuery: TADOQuery);
var nStr: string;
begin
  nDefault := False;
  EditDate.Text := Format('%s �� %s', [Date2Str(FStart), Date2Str(FEnd)]);

  nStr := 'Select * From $AT ';
  //xxxxx

  if FWhere = '' then
       nStr := nStr + 'Where (A_Date>=''$S'' and A_Date<''$End'' )'
  else nStr := nStr + 'Where (' + FWhere + ')';

  nStr := nStr + ' and A_Status = ''$AS'' ';

  nStr := MacroValue(nStr, [MI('$AT', sTable_AuditTruck),
          MI('$AS', IntToStr(FStatus)),
          MI('$S', Date2Str(FStart)), MI('$End', Date2Str(FEnd + 1))]);
  FDM.QueryData(SQLQuery, nStr);
end;

//------------------------------------------------------------------------------
procedure TfFrameAuditTruck.cxGrid1ActiveTabChanged(Sender: TcxCustomGrid;
  ALevel: TcxGridLevel);
begin
  cxGrid1.ActiveLevel := ALevel;
  ALevel.GridView := cxView1;
  FStatus := ALevel.Tag;
  FWhere := '';
  InitFormData(FWhere);
end;

//Desc: ˢ��
procedure TfFrameAuditTruck.BtnRefreshClick(Sender: TObject);
begin
  InitFormData(FWhere);
end;

//Desc: ����
procedure TfFrameAuditTruck.BtnAddClick(Sender: TObject);
var nParam: TFormCommandParam;
begin
  if cxView1.DataController.GetSelectedCount < 1 then
  begin
    ShowMsg('��ѡ��Ҫ��˵ļ�¼', sHint); Exit;
  end;

  nParam.FCommand := cCmd_AddData;
  nParam.FParamA := SQLQuery.FieldByName('A_ID').AsString;
  nParam.FParamB := FStatus;
  CreateBaseFormItem(cFI_FormAuditTruck, PopedomItem, @nParam);

  InitFormData(FWhere);
end;

//Desc ɾ��
procedure TfFrameAuditTruck.BtnDelClick(Sender: TObject);
var nStr,nSQL: string;
begin
  if cxView1.DataController.GetSelectedCount < 1 then
  begin
    ShowMsg('��ѡ��Ҫɾ���ĳ���', sHint); Exit;
  end;

  nSQL := 'ȷ��Ҫ�Գ���[ %s ]ִ��ɾ��������?';
  nStr := SQLQuery.FieldByName('A_Truck').AsString;

  nSQL := Format(nSQL, [nStr]);
  if not QueryDlg(nSQL, sAsk) then Exit;

  nSQL := 'Delete From %s Where A_ID=''%s''';
  nSQL := Format(nSQL, [sTable_AuditTruck, SQLQuery.FieldByName('A_ID').AsString]);
  FDM.ExecuteSQL(nSQL);

  InitFormData(FWhere);
  ShowMsg('ɾ�������ɹ�', sHint);
end;

//Desc: ��ݲ˵�
procedure TfFrameAuditTruck.N2Click(Sender: TObject);
begin
  BtnAddClick(nil);
end;

//Desc: ˫����˳���
procedure TfFrameAuditTruck.cxView1DblClick(Sender: TObject);
begin
  if cxView1.DataController.GetSelectedCount > 0 then BtnAddClick(nil);
end;

//Desc: ����ɸѡ
procedure TfFrameAuditTruck.EditDatePropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  if ShowDateFilterForm(FStart, FEnd) then InitFormData(FWhere);
end;

//Desc: ִ�в�ѯ
procedure TfFrameAuditTruck.EditTruckPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  if Sender = EditSerial then
  begin
    EditSerial.Text := Trim(EditSerial.Text);
    if EditSerial.Text = '' then Exit;

    FWhere := ' A_Serial like ''%%%s%%''' ;
    FWhere := Format(FWhere, [EditSerial.Text, EditSerial.Text]);

    InitFormData(FWhere);
  end else

  if Sender = EditTruck then
  begin
    EditTruck.Text := Trim(EditTruck.Text);
    if EditTruck.Text = '' then Exit;

    FWhere := 'A_Truck like ''%' + EditTruck.Text + '%''';

    InitFormData(FWhere);
  end;
end;

procedure TfFrameAuditTruck.N1Click(Sender: TObject);
var nStr: string;
begin
  ShowWaitForm('��ȡ΢��'+ CxGrid1.ActiveLevel.Caption+'�����Ϣ', True);
  try
    nStr := PackerEncodeStr(IntToStr(FStatus));
    getAuditTruck(nStr);
    InitFormData('');
  finally
    CloseWaitForm;
  end;
end;

procedure TfFrameAuditTruck.N3Click(Sender: TObject);
var nList: TStrings;
begin
  nList := TStringList.Create;

  try
    with nList do
    begin
      Clear;
      Values['ID']   := SQLQuery.FieldByName('A_ID').AsString;
      Values['Status']  := '1';
      Values['Memo']    := '';
      Values['Man']  := gSysParam.FUserID;
      Values['Type']     := '1';
    end;

    if UpLoadAuditTruck(PackerEncodeStr(nList.Text)) <> sFlag_Yes then Exit;
    //call remote

    ShowMsg('�������ڿ��ɹ�',sHint);
  finally
    nList.Free;
  end;
end;

procedure TfFrameAuditTruck.N4Click(Sender: TObject);
var nList: TStrings;
begin
  nList := TStringList.Create;

  try
    with nList do
    begin
      Clear;
      Values['ID']   := SQLQuery.FieldByName('A_ID').AsString;
      Values['Status']  := '1';
      Values['Memo']    := '';
      Values['Man']  := gSysParam.FUserID;
      Values['Type']     := '0';
    end;

    if UpLoadAuditTruck(PackerEncodeStr(nList.Text)) <> sFlag_Yes then Exit;
    //call remote

    ShowMsg('ȡ���������ڿ��ɹ�',sHint);
  finally
    nList.Free;
  end;
end;

procedure TfFrameAuditTruck.N5Click(Sender: TObject);
var nStr: string;
begin
  nStr := SQLQuery.FieldByName('A_Truck').AsString;
  nStr := GetshoporderbyTruck(PackerEncodeStr(nStr));
  //call remote
  nStr := PackerDecodeStr(nStr);
  ShowMsg(nStr,sHint);
end;

initialization
  gControlManager.RegCtrl(TfFrameAuditTruck, TfFrameAuditTruck.FrameID);
end.
