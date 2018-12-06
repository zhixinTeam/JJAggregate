{*******************************************************************************
  ����: dmzn@163.com 2009-6-12
  ����: ҵ��Ա����
*******************************************************************************}
unit UFormSalesMan;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  UDataModule, cxGraphics, dxLayoutControl, cxButtonEdit, StdCtrls,
  cxMaskEdit, cxDropDownEdit, cxMCListBox, cxMemo, cxContainer, cxEdit,
  cxTextEdit, cxControls, UFormBase, cxCheckBox, cxLookAndFeels,
  cxLookAndFeelPainters;

type
  TfFormSalesMan = class(TBaseForm)
    dxLayoutControl1Group_Root: TdxLayoutGroup;
    dxLayoutControl1: TdxLayoutControl;
    dxLayoutControl1Group1: TdxLayoutGroup;
    dxLayoutControl1Group2: TdxLayoutGroup;
    EditName: TcxTextEdit;
    dxLayoutControl1Item2: TdxLayoutItem;
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
    cxTextEdit3: TcxTextEdit;
    dxLayoutControl1Item14: TdxLayoutItem;
    dxLayoutControl1Group9: TdxLayoutGroup;
    EditArea: TcxButtonEdit;
    dxLayoutControl1Item12: TdxLayoutItem;
    Check1: TcxCheckBox;
    dxLayoutControl1Item1: TdxLayoutItem;
    dxlytgrpLayoutControl1Group6: TdxLayoutGroup;
    dxLayoutControl1Group6: TdxLayoutGroup;
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
  private
    { Private declarations }
    FSalesManID: string;
    //ҵ��Ա��ʶ
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
  IniFiles, ULibFun, UMgrControl, UFormCtrl, UAdjustForm, UFormBaseInfo,
  USysBusiness, USysGrid, USysDB, USysConst;

var
  gForm: TfFormSalesMan = nil;
  //ȫ��ʹ��

class function TfFormSalesMan.CreateForm(const nPopedom: string;
  const nParam: Pointer): TWinControl;
var nP: PFormCommandParam;
begin
  Result := nil;
  if Assigned(nParam) then
       nP := nParam
  else Exit;

  case nP.FCommand of
   cCmd_AddData:
    with TfFormSalesMan.Create(Application) do
    begin
      FSalesManID := '';
      Caption := 'ҵ��Ա - ���';

      InitFormData('');
      nP.FCommand := cCmd_ModalResult;
      nP.FParamA := ShowModal;
      Free;
    end;
   cCmd_EditData:
    with TfFormSalesMan.Create(Application) do
    begin
      FSalesManID := nP.FParamA;
      Caption := 'ҵ��Ա - �޸�';

      InitFormData(FSalesManID);
      nP.FCommand := cCmd_ModalResult;
      nP.FParamA := ShowModal;
      Free;
    end;
   cCmd_ViewData:
    begin
      if not Assigned(gForm) then
      begin
        gForm := TfFormSalesMan.Create(Application);
        with gForm do
        begin
          Caption := 'ҵ��Ա - �鿴';
          FormStyle := fsStayOnTop;

          BtnOK.Visible := False;
          BtnAdd.Enabled := False;
          BtnDel.Enabled := False;
        end;
      end;

      with gForm  do
      begin
        FSalesManID := nP.FParamA;
        InitFormData(FSalesManID);
        if not Showing then Show;
      end;
    end;
   cCmd_FormClose:
    begin
      if Assigned(gForm) then FreeAndNil(gForm);
    end;
  end;
end;

class function TfFormSalesMan.FormID: integer;
begin
  Result := cFI_FormSaleMan;
end;

//------------------------------------------------------------------------------
procedure TfFormSalesMan.FormCreate(Sender: TObject);
var nIni: TIniFile;
begin
  nIni := TIniFile.Create(gPath + sFormConfig);
  try
    LoadFormConfig(Self, nIni);
    LoadMCListBoxConfig(Name, InfoList1, nIni);
  finally
    nIni.Free;
  end;

  ResetHintAllForm(Self, 'T', sTable_Salesman);
  //���ñ�����
end;

procedure TfFormSalesMan.FormClose(Sender: TObject;
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
end;

procedure TfFormSalesMan.BtnExitClick(Sender: TObject);
begin
  Close;
end;

procedure TfFormSalesMan.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
 if Key = VK_ESCAPE then
  begin
    Key := 0; Close;
  end;
end;

//------------------------------------------------------------------------------
//Decc: ��ȡ����
procedure TfFormSalesMan.GetData(Sender: TObject; var nData: string);
begin
  if Sender = Check1 then
  begin
    if Check1.Checked then
         nData := sFlag_Yes
    else nData := sFlag_No;
  end;
end;

//Desc: ��������
function TfFormSalesMan.SetData(Sender: TObject; const nData: string): Boolean;
begin
  Result := False;
  if Sender = Check1 then
  begin
    Result := True;
    Check1.Checked := nData = sFlag_Yes;
  end;
end;

//Date: 2009-6-2
//Parm: ҵ��Ա���
//Desc: ����nIDҵ��Ա����Ϣ������
procedure TfFormSalesMan.InitFormData(const nID: string);
var nStr: string;
begin
  if InfoItems.Properties.Items.Count < 1 then
  begin
    InfoItems.Clear;
    nStr := MacroValue(sQuery_SysDict, [MI('$Table', sTable_SysDict),
                                        MI('$Name', sFlag_SalesmanItem)]);
    //�����ֵ���ҵ��Ա��Ϣ��

    with FDM.QueryTemp(nStr) do
    begin
      First;

      while not Eof do
      begin
        InfoItems.Properties.Items.Add(FieldByName('D_Value').AsString);
        Next;
      end;
    end;
  end;

  if nID <> '' then
  begin
    nStr := 'Select * From %s Where S_ID=''%s''';
    nStr := Format(nStr, [sTable_Salesman, nID]);
    LoadDataToCtrl(FDM.QueryTemp(nStr), Self, '', SetData);

    InfoList1.Clear;
    nStr := MacroValue(sQuery_ExtInfo, [MI('$Table', sTable_ExtInfo),
                       MI('$Group', sFlag_SalesmanItem), MI('$ID', nID)]);
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

//Desc: �����Ϣ
procedure TfFormSalesMan.BtnAddClick(Sender: TObject);
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
procedure TfFormSalesMan.BtnDelClick(Sender: TObject);
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

//Desc: ѡ������
procedure TfFormSalesMan.EditAreaPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
var nBool: Boolean;
begin
  nBool := True;
  EditArea.Text := ShowBaseInfoEditForm(nBool, nBool, '����','MAIN_B01',
                   sFlag_AreaItem).FText;
  //xxxxx
end;

//Desc: ��������
procedure TfFormSalesMan.BtnOKClick(Sender: TObject);
var nList: TStrings;
    i,nCount,nPos: integer;
    nStr,nSQL,nTmp,nID: string;
begin
  EditName.Text := Trim(EditName.Text);
  if EditName.Text = '' then
  begin
    EditName.SetFocus;
    ShowMsg('����дҵ��Ա����', sHint); Exit;
  end;

  nList := TStringList.Create;
  nList.Text := Format('S_PY=''%s''', [GetPinYinOfStr(EditName.Text)]);

  if FSalesManID = '' then
  begin
    nID := GetSerialNo(sFlag_BusGroup, sFlag_SaleMan, False);
    if nID = '' then Exit;
    
    nList.Add(SF('S_ID', nID));
    nSQL := MakeSQLByForm(Self, sTable_Salesman, '', True, GetData, nList);
  end else
  begin
    nID := FSalesManID;
    nStr := SF('S_ID', nID);
    nSQL := MakeSQLByForm(Self, sTable_Salesman, nStr, False, GetData, nList);
  end;

  nList.Free;
  FDM.ADOConn.BeginTrans;
  try
    FDM.ExecuteSQL(nSQL);
    //xxxxx
    
    if FSalesManID <> '' then
    begin
      nSQL := 'Delete From %s Where I_Group=''%s'' and I_ItemID=''%s''';
      nSQL := Format(nSQL, [sTable_ExtInfo, sFlag_SalesmanItem, FSalesManID]);
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
      nSQL := Format(nSQL, [sTable_ExtInfo, sFlag_SalesmanItem, nID, nTmp, nStr]);
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

initialization
  gControlManager.RegCtrl(TfFormSalesMan, TfFormSalesMan.FormID);
end.
