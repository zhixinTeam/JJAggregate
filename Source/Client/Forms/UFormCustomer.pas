{*******************************************************************************
  ����: dmzn@163.com 2009-6-11
  ����: �ͻ�����
*******************************************************************************}
unit UFormCustomer;

{$I Link.Inc}
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  UDataModule, UFormBase, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, dxLayoutControl, cxCheckBox,
  cxLabel, StdCtrls, cxMaskEdit, cxDropDownEdit, cxMCListBox, cxMemo,
  cxTextEdit, cxButtonEdit;

type
  TfFormCustomer = class(TBaseForm)
    dxLayoutControl1Group_Root: TdxLayoutGroup;
    dxLayoutControl1: TdxLayoutControl;
    dxLayoutControl1Group1: TdxLayoutGroup;
    dxLayoutControl1Group2: TdxLayoutGroup;
    EditName: TcxTextEdit;
    dxLayoutControl1Item2: TdxLayoutItem;
    EditPhone: TcxTextEdit;
    dxLayoutControl1Item3: TdxLayoutItem;
    EditMemo: TcxMemo;
    dxLayoutControl1Item4: TdxLayoutItem;
    InfoList1: TcxMCListBox;
    dxLayoutControl1Item5: TdxLayoutItem;
    InfoItems: TcxComboBox;
    dxLayoutControl1Item6: TdxLayoutItem;
    EditInfo: TcxTextEdit;
    dxLayoutControl1Item7: TdxLayoutItem;
    BtnAdd: TButton;
    dxLayoutControl1Item8: TdxLayoutItem;
    BtnDel: TButton;
    dxLayoutControl1Item9: TdxLayoutItem;
    BtnOK: TButton;
    dxLayoutControl1Item10: TdxLayoutItem;
    BtnExit: TButton;
    dxLayoutControl1Item11: TdxLayoutItem;
    dxLayoutControl1Group5: TdxLayoutGroup;
    dxLayoutControl1Group4: TdxLayoutGroup;
    cxTextEdit1: TcxTextEdit;
    dxLayoutControl1Item12: TdxLayoutItem;
    cxTextEdit2: TcxTextEdit;
    dxLayoutControl1Item13: TdxLayoutItem;
    cxTextEdit3: TcxTextEdit;
    dxLayoutControl1Item14: TdxLayoutItem;
    cxTextEdit4: TcxTextEdit;
    dxLayoutControl1Item15: TdxLayoutItem;
    cxTextEdit5: TcxTextEdit;
    dxLayoutControl1Item16: TdxLayoutItem;
    EditBank: TcxComboBox;
    dxLayoutControl1Item17: TdxLayoutItem;
    cxTextEdit6: TcxTextEdit;
    dxLayoutControl1Item18: TdxLayoutItem;
    dxLayoutControl1Group6: TdxLayoutGroup;
    dxLayoutControl1Group7: TdxLayoutGroup;
    dxLayoutControl1Group8: TdxLayoutGroup;
    EditCredit: TcxTextEdit;
    dxLayoutControl1Item19: TdxLayoutItem;
    cxLabel1: TcxLabel;
    dxLayoutControl1Item20: TdxLayoutItem;
    dxLayoutControl1Group10: TdxLayoutGroup;
    EditSaleMan: TcxComboBox;
    dxLayoutControl1Item21: TdxLayoutItem;
    dxLayoutControl1Group12: TdxLayoutGroup;
    dxLayoutControl1Group11: TdxLayoutGroup;
    Check1: TcxCheckBox;
    dxLayoutControl1Item1: TdxLayoutItem;
    dxLayoutControl1Group13: TdxLayoutGroup;
    dxLayoutControl1Group3: TdxLayoutGroup;
    EditWX: TcxComboBox;
    dxLayoutControl1Item22: TdxLayoutItem;
    dxLayoutControl1Group14: TdxLayoutGroup;
    dxLayoutControl1Item23: TdxLayoutItem;
    EditArea: TcxButtonEdit;
    dxLayoutControl1Group9: TdxLayoutGroup;
    CheckFL: TcxCheckBox;
    dxLayoutControl1Item24: TdxLayoutItem;
    EditCarrier: TcxComboBox;
    dxLayoutControl1Item25: TdxLayoutItem;
    dxLayoutControl1Item26: TdxLayoutItem;
    Chk_VIP: TcxCheckBox;
    dxLayoutControl1Group16: TdxLayoutGroup;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure BtnAddClick(Sender: TObject);
    procedure BtnDelClick(Sender: TObject);
    procedure BtnOKClick(Sender: TObject);
    procedure BtnExitClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure EditAreaPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
    FCustomerID: string;
    //�ͻ���ʶ
    procedure InitFormData(const nID: string);
    //��������
    procedure GetData(Sender: TObject; var nData: string);
    function SetData(Sender: TObject; const nData: string): Boolean;
    //�������
  public
    { Public declarations }
    class function CreateForm(const nPopedom: string = '';
      const nParam: Pointer = nil): TWinControl; override;
    class function FormID: integer; override;
  end;

implementation

{$R *.dfm}
uses
  IniFiles, ULibFun, UMgrControl, UFormCtrl, UAdjustForm, USysBusiness,
  UFormBaseInfo, USysGrid, USysDB, USysConst;

var
  gForm: TfFormCustomer = nil;
  //ȫ��ʹ��

class function TfFormCustomer.CreateForm(const nPopedom: string;
  const nParam: Pointer): TWinControl;
var nP: PFormCommandParam;
begin
  Result := nil;
  if Assigned(nParam) then
       nP := nParam
  else Exit;

  case nP.FCommand of
   cCmd_AddData:
    with TfFormCustomer.Create(Application) do
    begin
      FCustomerID := '';
      Caption := '�ͻ� - ���';

      InitFormData('');
      nP.FCommand := cCmd_ModalResult;
      nP.FParamA := ShowModal;
      Free;
    end;
   cCmd_EditData:
    with TfFormCustomer.Create(Application) do
    begin
      FCustomerID := nP.FParamA;
      Caption := '�ͻ� - �޸�';

      InitFormData(FCustomerID);
      nP.FCommand := cCmd_ModalResult;
      nP.FParamA := ShowModal;
      Free;
    end;
   cCmd_ViewData:
    begin
      if not Assigned(gForm) then
      begin
        gForm := TfFormCustomer.Create(Application);
        with gForm do
        begin
          Caption := '�ͻ� - �鿴';
          FormStyle := fsStayOnTop;

          BtnOK.Visible := False;
          BtnAdd.Enabled := False;
          BtnDel.Enabled := False;
        end;
      end;

      with gForm  do
      begin
        FCustomerID := nP.FParamA;
        InitFormData(FCustomerID);
        if not Showing then Show;
      end;
    end;
   cCmd_FormClose:
    begin
      if Assigned(gForm) then FreeAndNil(gForm);
    end;
  end; 
end;

class function TfFormCustomer.FormID: integer;
begin
  Result := cFI_FormCustomer;
end;

//------------------------------------------------------------------------------
procedure TfFormCustomer.FormCreate(Sender: TObject);
var nIni: TIniFile;
begin
  {$IFNDEF MicroMsg}
  EditWX.Hint := '';
  EditWX.Visible := False; 
  {$ENDIF}

  {$IFDEF UseCarrier}
  dxLayoutControl1Item25.Visible := True;
  EditCarrier.Text := '';
  {$ELSE}
  dxLayoutControl1Item25.Visible := False;
  EditCarrier.Text := '';
  {$ENDIF}

  nIni := TIniFile.Create(gPath + sFormConfig);
  try
    LoadFormConfig(Self, nIni);
    LoadMCListBoxConfig(Name, InfoList1, nIni);
  finally
    nIni.Free;
  end;

  ResetHintAllForm(Self, 'T', sTable_Customer);
  //���ñ�����
  {$IFDEF AdminUseFL}
  if gSysParam.FIsAdmin then
  begin
    dxLayoutControl1Item24.Visible := True;
    dxLayoutControl1Item1.Visible  := False;
  end
  else
  begin
    dxLayoutControl1Item24.Visible := False;
    dxLayoutControl1Item1.Visible  := True;
  end;
  {$ELSE}
    dxLayoutControl1Item24.Visible := False;
    dxLayoutControl1Item1.Visible  := True;
  {$ENDIF}
end;

procedure TfFormCustomer.FormClose(Sender: TObject;
  var Action: TCloseAction);
var nIni: TIniFile;
begin
  nIni := TIniFile.Create(gPath + sFormConfig);
  try
    SaveFormConfig(Self, nIni);
    SaveMCListBoxConfig(Name, InfoList1, nIni);
  finally
    nIni.Free;
  end;

  gForm := nil;
  Action := caFree;
  ReleaseCtrlData(Self);
end;

procedure TfFormCustomer.BtnExitClick(Sender: TObject);
begin
  Close;
end;

procedure TfFormCustomer.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
 if Key = VK_ESCAPE then
  begin
    Key := 0; Close;
  end;
end;

//------------------------------------------------------------------------------
//Desc: ��������
function TfFormCustomer.SetData(Sender: TObject; const nData: string): Boolean;
begin
  Result := False;
  if Sender = Check1 then
  begin
    Result := True;
    Check1.Checked := nData = sFlag_Yes;
  end
  else if Sender = CheckFL then
  begin
    Result := True;
    CheckFL.Checked := nData = sFlag_Yes;
  end
  else if Sender = Chk_VIP then
  begin
    Result := True;
    Chk_VIP.Checked := nData = sFlag_Yes;
  end;
end;

//Date: 2009-6-2
//Parm: ��Ӧ�̱��
//Desc: ����nID��Ӧ�̵���Ϣ������
procedure TfFormCustomer.InitFormData(const nID: string);
var nStr: string;
begin
  LoadSysDictItem(sFlag_CustomerItem, InfoItems.Properties.Items);
  LoadSysDictItem(sFlag_BankItem, EditBank.Properties.Items);
  
  if EditSaleMan.Properties.Items.Count < 1 then
    LoadSaleMan(EditSaleMan.Properties.Items);
  //xxxxx

  {nStr := 'M_ID=Select M_ID,M_WXName From %s Order By M_ID DESC';
  nStr := Format(nStr, [sTable_WeixinMatch]);

  FDM.FillStringsData(EditWX.Properties.Items, nStr, 6, '.');
  AdjustStringsItem(EditWX.Properties.Items, False);}

  if nID <> '' then
  begin
    nStr := 'Select cus.*,A_CreditLimit From %s cus' +
            ' Left Join %s On A_CID=C_ID ' +
            'Where C_ID=''%s''';
    nStr := Format(nStr, [sTable_Customer, sTable_CusAccount, nID]);
    LoadDataToCtrl(FDM.QueryTemp(nStr), Self, '', SetData);

    InfoList1.Clear;
    nStr := MacroValue(sQuery_ExtInfo, [MI('$Table', sTable_ExtInfo),
                       MI('$Group', sFlag_CustomerItem), MI('$ID', nID)]);
    //��չ��Ϣ

    with FDM.QueryTemp(nStr) do
    if RecordCount > 0 then
    begin
      First;

      while not Eof do
      begin
        nStr := FieldByName('I_Item').AsString + InfoList1.Delimiter +
                FieldByName('I_Info').AsString;
        InfoList1.Items.Add(nStr);
        
        Next;
      end;
    end;
  end;
end;

//Desc: ѡ������
procedure TfFormCustomer.EditAreaPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
var nBool: Boolean;
begin
  nBool := True;
  EditArea.Text := ShowBaseInfoEditForm(nBool, nBool, '����', 'MAIN_B01',
                   sFlag_AreaItem).FText;
  //xxxxx
end;

//Desc: �����Ϣ
procedure TfFormCustomer.BtnAddClick(Sender: TObject);
begin
  InfoItems.Text := Trim(InfoItems.Text);
  if InfoItems.Text = '' then
  begin
    InfoItems.SetFocus;
    ShowMsg('����д �� ѡ����Ч����Ϣ��', sHint); Exit;
  end;

  EditInfo.Text := Trim(EditInfo.Text);
  if EditInfo.Text = '' then
  begin
    EditInfo.SetFocus;
    ShowMsg('����д��Ч����Ϣ����', sHint); Exit;
  end;

  InfoList1.Items.Add(InfoItems.Text + InfoList1.Delimiter + EditInfo.Text);
end;

//Desc: ɾ����Ϣ��
procedure TfFormCustomer.BtnDelClick(Sender: TObject);
var nIdx: integer;
begin
  if InfoList1.ItemIndex < 0 then
  begin
    ShowMsg('��ѡ��Ҫɾ��������', sHint); Exit;
  end;

  nIdx := InfoList1.ItemIndex;
  InfoList1.Items.Delete(InfoList1.ItemIndex);

  if nIdx >= InfoList1.Count then Dec(nIdx);
  InfoList1.ItemIndex := nIdx;
  ShowMsg('��Ϣ����ɾ��', sHint);
end;

//Desc: ��ȡ����
procedure TfFormCustomer.GetData(Sender: TObject; var nData: string);
begin
  if Sender = Check1 then
  begin
    if Check1.Checked then
         nData := sFlag_Yes
    else nData := sFlag_No;
  end
  else if Sender = CheckFL then
  begin
    if CheckFL.Checked then
        nData  := sFlag_Yes
    else nData := sFlag_No;
  end
  else if Sender = Chk_VIP then
  begin
    if Chk_VIP.Checked then
         nData := sFlag_Yes
    else nData := sFlag_No;
  end;
end;

//Desc: ��������
procedure TfFormCustomer.BtnOKClick(Sender: TObject);
var nList: TStrings;
    i,nCount,nPos: integer;
    nStr,nSQL,nTmp,nID: string;
begin
  EditName.Text := Trim(EditName.Text);
  if EditName.Text = '' then
  begin
    EditName.SetFocus;
    ShowMsg('����д�ͻ�����', sHint); Exit;
  end;

  nStr := 'Select Count(*) From %s Where C_Name=''%s''';
  nStr := Format(nStr, [sTable_Customer, EditName.Text]);

  if FCustomerID <> '' then
    nStr := nStr + Format(' And C_ID<>''%S''', [FCustomerID]);
  //xxxxx

  with FDM.QueryTemp(nStr) do
  if Fields[0].AsInteger > 0 then
  begin
    nStr := '�ͻ�[ %s ]�Ѵ���!!' + #13#10#13#10 +
            '�ͻ��������ܻᵼ�»ؿ�쿨�Ȳ�������,Ҫ������?';
    nStr := Format(nStr, [EditName.Text]);
    if not QueryDlg(nStr, sAsk, Handle) then Exit;
  end;

  nList := TStringList.Create;
  nList.Text := SF('C_PY', GetPinYinOfStr(EditName.Text));

  if FCustomerID = '' then
  begin
    nID := GetSerialNo(sFlag_BusGroup, sFlag_Customer, False);
    if nID = '' then Exit;
    
    nList.Add(SF('C_ID', nID));
    nSQL := MakeSQLByForm(Self, sTable_Customer, '', True, GetData, nList);
  end else
  begin
    nID := FCustomerID;
    nStr := 'C_ID=''' + FCustomerID + '''';
    nSQL := MakeSQLByForm(Self, sTable_Customer, nStr, False, GetData, nList);
  end;

  nList.Free;
  FDM.ADOConn.BeginTrans;
  try
    FDM.ExecuteSQL(nSQL);
    nSQL := 'Select Count(*) From %s Where A_CID=''%s''';
    nSQL := Format(nSQL, [sTable_CusAccount, nID]);

    if FDM.QueryTemp(nSQL).Fields[0].AsInteger < 1 then
    begin
      nSQL := 'Insert Into %s(A_CID,A_Date) Values(''%s'', %s)';
      nSQL := Format(nSQL, [sTable_CusAccount, nID, FDM.SQLServerNow]);
      FDM.ExecuteSQL(nSQL);
    end;

    if FCustomerID <> '' then
    begin
      nSQL := 'Delete From %s Where I_Group=''%s'' and I_ItemID=''%s''';
      nSQL := Format(nSQL, [sTable_ExtInfo, sFlag_CustomerItem, nID]);
      FDM.ExecuteSQL(nSQL);
    end;

    nCount := InfoList1.Items.Count - 1;
    for i:=0 to nCount do
    begin
      nStr := InfoList1.Items[i];
      nPos := Pos(InfoList1.Delimiter, nStr);

      nTmp := Copy(nStr, 1, nPos - 1);
      System.Delete(nStr, 1, nPos + Length(InfoList1.Delimiter) - 1);

      nSQL := 'Insert Into %s(I_Group, I_ItemID, I_Item, I_Info) ' +
              'Values(''%s'', ''%s'', ''%s'', ''%s'')';
      nSQL := Format(nSQL, [sTable_ExtInfo, sFlag_CustomerItem, nID, nTmp, nStr]);
      FDM.ExecuteSQL(nSQL);
    end;

    FDM.ADOConn.CommitTrans;
    ModalResult := mrOK;
    ShowMsg('�����ѱ���', sHint);
  except
    FDM.ADOConn.RollbackTrans;
    ShowMsg('���ݱ���ʧ��', 'δ֪ԭ��');
  end;
end;

procedure TfFormCustomer.FormShow(Sender: TObject);
var
  nStr: string;
begin
  inherited;
  if EditCarrier.Properties.Items.Count < 1 then
  begin
    nStr := 'Select S_Name From %s ';
    nStr := Format(nStr, [sTable_Carrier]);

    with FDM.QueryTemp(nStr) do
    if RecordCount > 0 then
    begin
      First;
      while not Eof do
      begin
        EditCarrier.Properties.Items.Add(FieldByName('S_Name').AsString);
        Next;
      end;
    end;
  end;
end;

initialization
  gControlManager.RegCtrl(TfFormCustomer, TfFormCustomer.FormID);
end.
