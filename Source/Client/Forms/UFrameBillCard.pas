{*******************************************************************************
  ����: dmzn@163.com 2012-04-07
  ����: ����ſ�
*******************************************************************************}
unit UFrameBillCard;

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
  TfFrameBillCard = class(TfFrameNormal)
    PMenu1: TPopupMenu;
    N1: TMenuItem;
    cxLevel2: TcxGridLevel;
    cxView2: TcxGridDBTableView;
    DataSource2: TDataSource;
    SQLNo1: TADOQuery;
    PMenu2: TPopupMenu;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    N5: TMenuItem;
    N6: TMenuItem;
    N7: TMenuItem;
    N8: TMenuItem;
    N9: TMenuItem;
    N10: TMenuItem;
    N11: TMenuItem;
    N12: TMenuItem;
    N13: TMenuItem;
    N14: TMenuItem;
    N15: TMenuItem;
    N16: TMenuItem;
    N17: TMenuItem;
    EditBill: TcxButtonEdit;
    dxLayout1Item1: TdxLayoutItem;
    EditTruck: TcxButtonEdit;
    dxLayout1Item3: TdxLayoutItem;
    EditCus: TcxButtonEdit;
    dxLayout1Item5: TdxLayoutItem;
    EditDate: TcxButtonEdit;
    dxLayout1Item2: TdxLayoutItem;
    cxTextEdit1: TcxTextEdit;
    dxLayout1Item6: TdxLayoutItem;
    cxTextEdit3: TcxTextEdit;
    dxLayout1Item7: TdxLayoutItem;
    cxTextEdit2: TcxTextEdit;
    dxLayout1Item4: TdxLayoutItem;
    procedure EditDatePropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure EditTruckPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure BtnAddClick(Sender: TObject);
    procedure cxGrid1ActiveTabChanged(Sender: TcxCustomGrid;
      ALevel: TcxGridLevel);
    procedure N2Click(Sender: TObject);
    procedure BtnRefreshClick(Sender: TObject);
    procedure N4Click(Sender: TObject);
    procedure N5Click(Sender: TObject);
    procedure N6Click(Sender: TObject);
    procedure N8Click(Sender: TObject);
    procedure PMenu1Popup(Sender: TObject);
    procedure N9Click(Sender: TObject);
    procedure N10Click(Sender: TObject);
    procedure N11Click(Sender: TObject);
    procedure N12Click(Sender: TObject);
    procedure N14Click(Sender: TObject);
    procedure N15Click(Sender: TObject);
    procedure BtnDelClick(Sender: TObject);
    procedure N17Click(Sender: TObject);
    procedure cxView2DblClick(Sender: TObject);
  private
    { Private declarations }
  protected
    FWhereNo: string;
    //δ������
    FStart,FEnd: TDate;
    //ʱ������
    FQueryHas,FQueryNo: Boolean;
    //��ѯ����
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
  UDataModule, UFormDateFilter, UForminputbox, USysConst, USysDB, USysGrid;

//------------------------------------------------------------------------------
class function TfFrameBillCard.FrameID: integer;
begin
  Result := cFI_FrameMakeCard;
end;

procedure TfFrameBillCard.OnCreateFrame;
begin
  inherited;
  FWhereNo := '';
  FQueryNo := True;
  FQueryHas := True;  
  InitDateRange(Name, FStart, FEnd);
end;

procedure TfFrameBillCard.OnDestroyFrame;
begin
  SaveDateRange(Name, FStart, FEnd);
  inherited;
end;

procedure TfFrameBillCard.OnLoadGridConfig(const nIni: TIniFile);
begin
  if BtnAdd.Enabled then
       BtnAdd.Tag := 10
  else BtnAdd.Tag := 0;

  if BtnEdit.Enabled then
       BtnEdit.Tag := 10
  else BtnEdit.Tag := 0;

  if BtnDel.Enabled then
       BtnDel.Tag := 10
  else BtnDel.Tag := 0;

  cxGrid1.ActiveLevel := cxLevel2;
  cxGrid1ActiveTabChanged(cxGrid1, cxGrid1.ActiveLevel);

  gSysEntityManager.BuildViewColumn(cxView2, 'MAIN_D06');
  InitTableView(Name, cxView2, nIni);
end;

procedure TfFrameBillCard.OnSaveGridConfig(const nIni: TIniFile);
begin
  SaveUserDefineTableView(Name, cxView2, nIni);
end;

procedure TfFrameBillCard.OnInitFormData(var nDefault: Boolean;
  const nWhere: string; const nQuery: TADOQuery);
var nStr: string;
begin
  nDefault := False;
  EditDate.Text := Format('%s �� %s', [Date2Str(FStart), Date2Str(FEnd)]);

  if FQueryHas then
  begin
    nStr := 'Select bc.*,L_ID,L_CusID,L_CusName,L_Truck From $BC bc ' +
            ' Left Join $Bill b On b.L_Card=bc.C_Card ';
    //xxxxx

    if FWhere = '' then
         nStr := nStr + 'Where (C_Date>=''$S'' and C_Date<''$End'')'
    else nStr := nStr + 'Where (' + FWhere + ')';

    nStr := MacroValue(nStr, [MI('$BC', sTable_Card),
            MI('$Bill', sTable_Bill),
            MI('$S', Date2Str(FStart)), MI('$End', Date2Str(FEnd + 1))]);
    FDM.QueryData(SQLQuery, nStr);
  end;

  if not FQueryNo then Exit;
  nStr := 'Select * From $Bill Where (L_Card Is Null)';

  if FWhereNo = '' then
       nStr := nStr + ' And (L_Date>=''$S'' and L_Date<''$End'')'
  else nStr := nStr + ' And (' + FWhereNo + ')';

  nStr := MacroValue(nStr, [MI('$Bill', sTable_Bill),
          MI('$S', Date2Str(FStart)), MI('$End', Date2Str(FEnd + 1))]);
  //xxxxx

  FDM.QueryData(SQLNo1, nStr);
end;

//------------------------------------------------------------------------------
procedure TfFrameBillCard.cxGrid1ActiveTabChanged(Sender: TcxCustomGrid;
  ALevel: TcxGridLevel);
begin
  BtnEdit.Enabled := (BtnEdit.Tag > 0) and (cxGrid1.ActiveView = cxView1);
  BtnDel.Enabled := (BtnDel.Tag > 0) and (cxGrid1.ActiveView = cxView1);
end;

//Desc: ˢ��
procedure TfFrameBillCard.BtnRefreshClick(Sender: TObject);
begin
  FWhere := '';
  FWhereNo := '';
  FQueryNo := True;
  FQueryHas := True;
  InitFormData(FWhere);
end;

//Desc: ����
procedure TfFrameBillCard.BtnAddClick(Sender: TObject);
var nBill,nTruck: string;
begin
  if BtnAdd.Enabled then
  begin
    nBill := '';
    nTruck := '';
  end else Exit;

  if cxGrid1.ActiveView = cxView2 then
  begin
    if cxView2.DataController.GetSelectedCount < 1 then
    begin
      ShowMsg('��ѡ��Ҫ�쿨�ļ�¼', sHint); Exit;
    end;

    nBill := SQLNo1.FieldByName('L_ID').AsString;
    nTruck := SQLNo1.FieldByName('L_Truck').AsString;
  end;

  if SetBillCard(nBill, nTruck, False) then
  begin
    FQueryNo := cxGrid1.ActiveView = cxView2;
    FQueryHas := True;
    InitFormData(FWhere);
  end;
end;

//Desc ɾ��
procedure TfFrameBillCard.BtnDelClick(Sender: TObject);
var nStr,nSQL: string;
begin
  if cxView1.DataController.GetSelectedCount < 1 then
  begin
    ShowMsg('��ѡ��Ҫɾ���Ĵſ�', sHint); Exit;
  end;

  nStr := SQLQuery.FieldByName('C_Status').AsString;
  if (nStr <> sFlag_CardIdle) and (nStr <> sFlag_CardInvalid) then
  begin
    ShowMsg('���л�ע��������ɾ��', sHint); Exit;
  end;

  nStr := SQLQuery.FieldByName('C_Freeze').AsString;
  if nStr = sFlag_Yes then
  begin
    ShowMsg('�ÿ��Ѿ�������', sHint); Exit;
  end;

  nSQL := 'ȷ��Ҫ�Կ�[ %s ]ִ��ɾ��������?';
  nStr := SQLQuery.FieldByName('C_Card').AsString;

  nSQL := Format(nSQL, [nStr]);
  if not QueryDlg(nSQL, sAsk) then Exit;

  nSQL := 'Delete From %s Where C_Card=''%s''';
  nSQL := Format(nSQL, [sTable_Card, nStr]);
  FDM.ExecuteSQL(nSQL);

  InitFormData(FWhere);
  ShowMsg('ɾ�������ɹ�', sHint);
end;

//Desc: ��ݲ˵�
procedure TfFrameBillCard.N2Click(Sender: TObject);
begin
  BtnAddClick(nil);
end;

//Desc: ˫������Ƭ
procedure TfFrameBillCard.cxView2DblClick(Sender: TObject);
begin
  if cxView2.DataController.GetSelectedCount > 0 then BtnAddClick(nil);
end;

//Desc: ����ɸѡ
procedure TfFrameBillCard.EditDatePropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  if ShowDateFilterForm(FStart, FEnd) then InitFormData(FWhere);
end;

//Desc: ִ�в�ѯ
procedure TfFrameBillCard.EditTruckPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  if Sender = EditCus then
  begin
    EditCus.Text := Trim(EditCus.Text);
    if EditCus.Text = '' then Exit;

    FWhere := 'L_CusPY like ''%%%s%%'' or L_CusName like ''%%%s%%''' ;
    FWhere := Format(FWhere, [EditCus.Text, EditCus.Text]);
    FWhereNo := FWhere;
    
    FQueryNo := True;
    FQueryHas := True;
    InitFormData(FWhere);

    if SQLNo1.RecordCount > 0 then
      cxGrid1.ActiveLevel := cxLevel2 else
    if SQLQuery.RecordCount > 0 then
      cxGrid1.ActiveLevel := cxLevel1;
    //xxxxxx
  end else

  if Sender = EditBill then
  begin
    EditBill.Text := Trim(EditBill.Text);
    if EditBill.Text = '' then Exit;

    FQueryNo := True;
    FQueryHas := True;

    FWhere := 'L_ID like ''%' + EditBill.Text + '%''';
    FWhereNo := FWhere;
    InitFormData(FWhere);

    if SQLNo1.RecordCount > 0 then
      cxGrid1.ActiveLevel := cxLevel2 else
    if SQLQuery.RecordCount > 0 then
      cxGrid1.ActiveLevel := cxLevel1;
    //xxxxxx
  end else
  
  if Sender = EditTruck then
  begin
    EditTruck.Text := Trim(EditTruck.Text);
    if EditTruck.Text = '' then Exit;

    FQueryNo := True;
    FQueryHas := True;

    FWhere := 'L_Truck like ''%' + EditTruck.Text + '%''';
    FWhereNo := FWhere;
    InitFormData(FWhere);

    if SQLNo1.RecordCount > 0 then
      cxGrid1.ActiveLevel := cxLevel2 else
    if SQLQuery.RecordCount > 0 then
      cxGrid1.ActiveLevel := cxLevel1;
    //xxxxxx
  end;
end;

//Desc: ��ѯȫ��δ����
procedure TfFrameBillCard.N4Click(Sender: TObject);
begin
  FQueryNo := True;
  FQueryHas := False;

  FWhereNo := '1=1';
  InitFormData(FWhere);
end;

//Desc: ��Ч�ſ�
procedure TfFrameBillCard.N5Click(Sender: TObject);
begin
  FQueryNo := False;
  FQueryHas := True;

  FWhere := 'L_ID Is Null';
  InitFormData(FWhere);
end;

//Desc: ȫ���ſ�
procedure TfFrameBillCard.N6Click(Sender: TObject);
begin
  FQueryNo := False;
  FQueryHas := True;

  FWhere := '1=1';
  InitFormData(FWhere);
end;

//Desc: ����ſ�
procedure TfFrameBillCard.N8Click(Sender: TObject);
begin
  FQueryNo := False;
  FQueryHas := True;

  FWhere := 'C_Freeze=''%s''';
  FWhere := Format(FWhere, [sFlag_Yes]);
  InitFormData(FWhere);
end;

//------------------------------------------------------------------------------
//Desc: ���Ʋ˵���
procedure TfFrameBillCard.PMenu1Popup(Sender: TObject);
var nStr: string;
    i,nCount: integer;
begin
  nCount := PMenu1.Items.Count - 1;
  for i:=0 to nCount do
    PMenu1.Items[i].Enabled := False;
  //xxxxx
  
  N1.Enabled := True;
  N17.Enabled := cxView1.DataController.GetSelectedCount > 0;
  //��ע��Ϣ

  if (cxView1.DataController.GetSelectedCount > 0) and BtnAdd.Enabled then
  begin
    nStr := SQLQuery.FieldByName('C_Status').AsString;
    N9.Enabled := nStr = sFlag_CardUsed;
    //ʹ���еĿ����Թ�ʧ
    N10.Enabled := nStr = sFlag_CardLoss;
    //�ѹ�ʧ�����Խ��ʧ
    N11.Enabled := nStr = sFlag_CardLoss;
    //�ѹ�ʧ�����Բ��쿨
    N12.Enabled := nStr <> sFlag_CardInvalid;
    //����ʱ����
  end;

  if (cxView1.DataController.GetSelectedCount > 0) and BtnEdit.Enabled then
  begin
    nStr := SQLQuery.FieldByName('C_Freeze').AsString;
    N14.Enabled := nStr <> sFlag_Yes;   //����
    N15.Enabled := nStr = sFlag_Yes;    //���
  end;
end;

//Desc: ��ʧ�ſ�
procedure TfFrameBillCard.N9Click(Sender: TObject);
var nStr,nSQL: string;
begin
  nSQL := 'ȷ��Ҫ�Կ�[ %s ]ִ�й�ʧ������?';
  nStr := SQLQuery.FieldByName('C_Card').AsString;

  nSQL := Format(nSQL, [nStr]);
  if not QueryDlg(nSQL, sAsk) then Exit;

  nSQL := 'Update %s Set C_Status=''%s'' Where C_Card=''%s''';
  nSQL := Format(nSQL, [sTable_Card, sFlag_CardLoss, nStr]);
  FDM.ExecuteSQL(nSQL);

  InitFormData(FWhere);
  ShowMsg('��ʧ�����ɹ�', sHint);
end;

//Desc: �����ʧ
procedure TfFrameBillCard.N10Click(Sender: TObject);
var nStr,nSQL: string;
begin
  nSQL := 'ȷ��Ҫ�Կ�[ %s ]ִ�н����ʧ������?';
  nStr := SQLQuery.FieldByName('C_Card').AsString;

  nSQL := Format(nSQL, [nStr]);
  if not QueryDlg(nSQL, sAsk) then Exit;

  nSQL := 'Update %s Set C_Status=''%s'' Where C_Card=''%s''';
  nSQL := Format(nSQL, [sTable_Card, sFlag_CardUsed, nStr]);
  FDM.ExecuteSQL(nSQL);

  InitFormData(FWhere);
  ShowMsg('�����ʧ�����ɹ�', sHint);
end;

//Desc: ����ſ�
procedure TfFrameBillCard.N11Click(Sender: TObject);
var nBill,nTruck: string;
begin
  nBill := SQLQuery.FieldByName('L_ID').AsString;
  nTruck := SQLQuery.FieldByName('L_Truck').AsString;

  if SetBillCard(nBill, nTruck, False) then
  begin
    InitFormData(FWhere);
    ShowMsg('���������ɹ�', sHint);
  end;
end;

//Desc: ע���ſ�
procedure TfFrameBillCard.N12Click(Sender: TObject);
var nStr,nCard: string;
begin
  nCard := SQLQuery.FieldByName('C_Card').AsString;
  nStr := Format('ȷ��Ҫ�Կ�[ %s ]ִ������������?', [nCard]);
  if not QueryDlg(nStr, sAsk) then Exit;

  if LogoutBillCard(nCard) then
  begin
    InitFormData(FWhere);
    ShowMsg('ע�������ɹ�', sHint);
  end;
end;

//Desc: ����ſ�
procedure TfFrameBillCard.N14Click(Sender: TObject);
var nStr,nSQL: string;
begin
  nSQL := 'ȷ��Ҫ�Կ�[ %s ]ִ�ж��������?';
  nStr := SQLQuery.FieldByName('C_Card').AsString;

  nSQL := Format(nSQL, [nStr]);
  if not QueryDlg(nSQL, sAsk) then Exit;

  nSQL := 'Update %s Set C_Freeze=''%s'' Where C_Card=''%s''';
  nSQL := Format(nSQL, [sTable_Card, sFlag_Yes, nStr]);
  FDM.ExecuteSQL(nSQL);

  InitFormData(FWhere);
  ShowMsg('��������ɹ�', sHint);
end;

//Desc: �������
procedure TfFrameBillCard.N15Click(Sender: TObject);
var nStr,nSQL: string;
begin
  nSQL := 'ȷ��Ҫ�Կ�[ %s ]ִ�н�����������?';
  nStr := SQLQuery.FieldByName('C_Card').AsString;

  nSQL := Format(nSQL, [nStr]);
  if not QueryDlg(nSQL, sAsk) then Exit;

  nSQL := 'Update %s Set C_Freeze=''%s'' Where C_Card=''%s''';
  nSQL := Format(nSQL, [sTable_Card, sFlag_No, nStr]);
  FDM.ExecuteSQL(nSQL);

  InitFormData(FWhere);
  ShowMsg('�����������ɹ�', sHint);
end;

//Desc: �޸ı�ע
procedure TfFrameBillCard.N17Click(Sender: TObject);
var nStr: string;
    nP: TFormCommandParam;
begin
  if BtnEdit.Enabled then
  begin
    nP.FCommand := cCmd_EditData;
    nP.FParamA := SQLQuery.FieldByName('C_Memo').AsString;
    nP.FParamB := 500;

    nStr := SQLQuery.FieldByName('R_ID').AsString;
    nP.FParamC := 'Update %s Set C_Memo=''$Memo'' Where R_ID=%s';
    nP.FParamC := Format(nP.FParamC, [sTable_Card, nStr]);

    CreateBaseFormItem(cFI_FormMemo, '', @nP);
    if (nP.FCommand = cCmd_ModalResult) and (nP.FParamA = mrOK) then
      InitFormData(FWhere);
    //xxxxx
  end else
  begin
    nP.FCommand := cCmd_ViewData;
    nP.FParamA := SQLQuery.FieldByName('C_Memo').AsString;
    CreateBaseFormItem(cFI_FormMemo, '', @nP);
  end;;
end;

initialization
  gControlManager.RegCtrl(TfFrameBillCard, TfFrameBillCard.FrameID);
end.
