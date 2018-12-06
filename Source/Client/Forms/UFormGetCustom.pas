{*******************************************************************************
  ����: dmzn@163.com 2010-3-9
  ����: ѡ��ͻ�
*******************************************************************************}
unit UFormGetCustom;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, UFormNormal, cxGraphics, cxContainer, cxEdit, cxTextEdit,
  cxMaskEdit, cxDropDownEdit, dxLayoutControl, StdCtrls, cxControls,
  ComCtrls, cxListView, cxButtonEdit, cxLabel;

type
  TfFormGetCustom = class(TfFormNormal)
    EditSMan: TcxComboBox;
    dxLayout1Item3: TdxLayoutItem;
    EditCustom: TcxComboBox;
    dxLayout1Item4: TdxLayoutItem;
    EditCus: TcxButtonEdit;
    dxLayout1Item5: TdxLayoutItem;
    ListCustom: TcxListView;
    dxLayout1Item6: TdxLayoutItem;
    dxLayout1Group2: TdxLayoutGroup;
    cxLabel1: TcxLabel;
    dxLayout1Item7: TdxLayoutItem;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure BtnOKClick(Sender: TObject);
    procedure ListCustomKeyPress(Sender: TObject; var Key: Char);
    procedure EditCIDPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure EditSManPropertiesEditValueChanged(Sender: TObject);
    procedure EditCustomPropertiesEditValueChanged(Sender: TObject);
    procedure ListCustomDblClick(Sender: TObject);
  private
    { Private declarations }
    FCusID,FCusName: string;
    //�ͻ���Ϣ
    FSaleMan: string;
    //ҵ��Ա
    procedure InitFormData(const nID: string);
    //��ʼ������
    function QueryCustom(const nType: Byte): Boolean;
    //��ѯ�ͻ�
    procedure GetResult;
    //��ȡ���
  public
    { Public declarations }
    class function CreateForm(const nPopedom: string = '';
      const nParam: Pointer = nil): TWinControl; override;
    class function FormID: integer; override;
  end;

implementation

{$R *.dfm}

uses
  IniFiles, ULibFun, UMgrControl, UAdjustForm, UFormCtrl, UFormBase, USysGrid,
  USysDB, USysConst, USysBusiness, UDataModule;

class function TfFormGetCustom.CreateForm(const nPopedom: string;
  const nParam: Pointer): TWinControl;
var nP: PFormCommandParam;
begin
  Result := nil;
  if Assigned(nParam) then
       nP := nParam
  else Exit;

  with TfFormGetCustom.Create(Application) do
  begin
    Caption := 'ѡ��ͻ�';
    InitFormData(nP.FParamA);

    nP.FCommand := cCmd_ModalResult;
    nP.FParamA := ShowModal;

    if nP.FParamA = mrOK then
    begin
      nP.FParamB := FCusID;
      nP.FParamC := FCusName;
      nP.FParamD := FSaleMan;
    end;
    Free;
  end;
end;

class function TfFormGetCustom.FormID: integer;
begin
  Result := cFI_FormGetCustom;
end;

procedure TfFormGetCustom.FormCreate(Sender: TObject);
var nIni: TIniFile;
begin
  nIni := TIniFile.Create(gPath + sFormConfig);
  try
    LoadFormConfig(Self, nIni);
    LoadcxListViewConfig(Name, ListCustom, nIni);
  finally
    nIni.Free;
  end;
end;

procedure TfFormGetCustom.FormClose(Sender: TObject;
  var Action: TCloseAction);
var nIni: TIniFile;
begin
  nIni := TIniFile.Create(gPath + sFormConfig);
  try
    SaveFormConfig(Self, nIni);
    SavecxListViewConfig(Name, ListCustom, nIni);
  finally
    nIni.Free;
  end;

  ReleaseCtrlData(Self);
end;

//------------------------------------------------------------------------------
//Desc: ��ʼ����������
procedure TfFormGetCustom.InitFormData(const nID: string);
var nStr: string;
begin
  if EditSMan.Properties.Items.Count < 1 then
  begin
    nStr := 'S_ID=Select S_ID,S_PY,S_Name From %s ' +
            'Where S_InValid<>''%s'' Order By S_PY';
    nStr := Format(nStr, [sTable_Salesman, sFlag_Yes]);

    FDM.FillStringsData(EditSMan.Properties.Items, nStr, -1,
                        '.', DSA(['S_ID']));
    AdjustStringsItem(EditSMan.Properties.Items, False);
    EditSMan.Properties.Items.Insert(0, '');
  end;

  if nID <> '' then
  begin
    EditCus.Text := nID;
    if QueryCustom(10) then ActiveControl := ListCustom;
  end else ActiveControl := EditSMan;
end;

//Date: 2010-3-9
//Parm: ��ѯ����(10: ������;20: ����Ա)
//Desc: ��ָ�����Ͳ�ѯ��ͬ
function TfFormGetCustom.QueryCustom(const nType: Byte): Boolean;
var nStr,nWhere: string;
begin
  Result := False;
  nWhere := '';
  ListCustom.Items.Clear;

  if nType = 10 then
  begin
    nWhere := 'C_PY Like ''%$ID%'' or C_Name Like ''%$ID%'' or C_ID=''$ID''';
  end else

  if nType = 20 then
  begin
    if (EditSMan.ItemIndex < 1) and (EditCustom.ItemIndex < 1) then Exit;
    //�޲�ѯ����

    if EditSMan.ItemIndex > 0 then
      nWhere := 'C_SaleMan=''$SID''';
    //xxxxx

    if EditCustom.ItemIndex > 0 then
    begin
      if nWhere <> '' then
        nWhere := nWhere + ' And ';
      nWhere := nWhere + 'C_ID=''$CID''';
    end;
  end;

  nStr := 'Select cus.*,S_Name From $Cus cus ' +
          ' Left Join $SM sm On sm.S_ID=cus.C_SaleMan';
  if nWhere <> '' then
    nStr := nStr + ' Where (' + nWhere + ')';
  nStr := nStr + ' Order By C_PY';

  nStr := MacroValue(nStr, [MI('$Cus', sTable_Customer),
          MI('$SM', sTable_Salesman), MI('$SID', GetCtrlData(EditSMan)),
          MI('$CID', GetCtrlData(EditCustom)), MI('$ID', EditCus.Text)]);
  //xxxxx

  with FDM.QueryTemp(nStr) do
  if RecordCount > 0 then
  begin
    First;

    while not Eof do
    with ListCustom.Items.Add do
    begin
      Caption := FieldByName('C_ID').AsString;
      SubItems.Add(FieldByName('S_Name').AsString);
      SubItems.Add(FieldByName('C_Name').AsString);
      SubItems.Add(FieldByName('C_SaleMan').AsString);

      ImageIndex := cItemIconIndex;
      Next;
    end;

    ListCustom.ItemIndex := 0;
    Result := True;
  end;
end;

procedure TfFormGetCustom.EditCIDPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  EditCus.Text := Trim(EditCus.Text);
  if (EditCus.Text <> '') and QueryCustom(10) then ListCustom.SetFocus;
end;

//Desc: ҵ��Ա���,��ȡ��ؿͻ�
procedure TfFormGetCustom.EditSManPropertiesEditValueChanged(
  Sender: TObject);
var nStr: string;
begin
  if EditSMan.ItemIndex > 0 then
  begin
    AdjustStringsItem(EditCustom.Properties.Items, True);
    nStr := 'C_ID=Select C_ID,C_Name From %s Where C_SaleMan=''%s''';
    nStr := Format(nStr, [sTable_Customer, GetCtrlData(EditSMan)]);

    FDM.FillStringsData(EditCustom.Properties.Items, nStr, -1, '.');
    AdjustStringsItem(EditCustom.Properties.Items, False);
  end;

  if QueryCustom(20) then ListCustom.SetFocus;
end;

procedure TfFormGetCustom.EditCustomPropertiesEditValueChanged(
  Sender: TObject);
begin
  if QueryCustom(20) then ListCustom.SetFocus;
end;

//Desc: ��ȡ���
procedure TfFormGetCustom.GetResult;
begin
  with ListCustom.Selected do
  begin
    FCusID := Caption;
    FCusName := SubItems[1];
    FSaleMan := SubItems[2];
  end;
end;

procedure TfFormGetCustom.ListCustomKeyPress(Sender: TObject;
  var Key: Char);
begin
  if Key = #13 then
  begin
    Key := #0;
    if ListCustom.ItemIndex > -1 then
    begin
      GetResult; ModalResult := mrOk;
    end;
  end;
end;

procedure TfFormGetCustom.ListCustomDblClick(Sender: TObject);
begin
  if ListCustom.ItemIndex > -1 then
  begin
    GetResult; ModalResult := mrOk;
  end;
end;

procedure TfFormGetCustom.BtnOKClick(Sender: TObject);
begin
  if ListCustom.ItemIndex > -1 then
  begin
    GetResult; ModalResult := mrOk;
  end else ShowMsg('���ڲ�ѯ�����ѡ��', sHint);
end;

initialization
  gControlManager.RegCtrl(TfFormGetCustom, TfFormGetCustom.FormID);
end.
