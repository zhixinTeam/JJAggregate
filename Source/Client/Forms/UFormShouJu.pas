{*******************************************************************************
  ����: dmzn@163.com 2010-3-16
  ����: �վݹ���
*******************************************************************************}
unit UFormShouJu;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  UFormNormal, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, cxDropDownEdit, cxMemo,
  cxButtonEdit, cxLabel, cxTextEdit, cxMaskEdit, cxCalendar,
  dxLayoutControl, StdCtrls;

type
  TfFormShouJu = class(TfFormNormal)
    dxLayout1Item3: TdxLayoutItem;
    EditDate: TcxDateEdit;
    dxLayout1Item4: TdxLayoutItem;
    EditMan: TcxTextEdit;
    dxLayout1Item5: TdxLayoutItem;
    cxLabel2: TcxLabel;
    dxLayout1Item6: TdxLayoutItem;
    EditID: TcxButtonEdit;
    dxLayout1Item7: TdxLayoutItem;
    EditName: TcxTextEdit;
    dxLayout1Item8: TdxLayoutItem;
    EditReason: TcxTextEdit;
    dxLayout1Item9: TdxLayoutItem;
    EditMoney: TcxTextEdit;
    dxLayout1Item10: TdxLayoutItem;
    cxLabel1: TcxLabel;
    dxLayout1Item11: TdxLayoutItem;
    EditBig: TcxTextEdit;
    dxLayout1Item12: TdxLayoutItem;
    EditMemo: TcxMemo;
    dxLayout1Group2: TdxLayoutGroup;
    dxLayout1Group3: TdxLayoutGroup;
    dxLayout1Group4: TdxLayoutGroup;
    dxLayout1Group5: TdxLayoutGroup;
    EditBank: TcxComboBox;
    dxLayout1Item13: TdxLayoutItem;
    dxLayout1Group6: TdxLayoutGroup;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure EditMoneyExit(Sender: TObject);
    procedure BtnOKClick(Sender: TObject);
    procedure EditIDPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
  private
    { Private declarations }
    FRecordID: string;
    FPrefixID: string;
    //ǰ׺���
    FIDLength: integer;
    //ǰ׺����
    procedure InitFormData(const nID: string);
    //��������
    procedure GetData(Sender: TObject; var nData: string);
    //��ȡ����
    function SetData(Sender: TObject; const nData: string): Boolean;
    //��������
  public
    { Public declarations }
    class function CreateForm(const nPopedom: string = '';
      const nParam: Pointer = nil): TWinControl; override;
    class function FormID: integer; override;
    function OnVerifyCtrl(Sender: TObject; var nHint: string): Boolean; override;
  end;

implementation

{$R *.dfm}
uses
  IniFiles, ULibFun, UFormCtrl, UAdjustForm, UFormBase, UMgrControl, USysGrid,
  USysDB, USysConst, USysBusiness, UDataModule;

var
  gForm: TfFormShouJu = nil;
  //ȫ��ʹ��

class function TfFormShouJu.CreateForm(const nPopedom: string;
  const nParam: Pointer): TWinControl;
var nP: PFormCommandParam;
begin
  Result := nil;
  if Assigned(nParam) then
       nP := nParam
  else Exit;

  case nP.FCommand of
   cCmd_AddData:
    with TfFormShouJu.Create(Application) do
    begin
      FRecordID := '';
      Caption := '�վ� - ���';

      EditName.Text := nP.FParamA;
      EditReason.Text := nP.FParamB;
      EditMoney.Text := nP.FParamC;
      EditMoneyExit(nil);

      InitFormData('');
      nP.FCommand := cCmd_ModalResult;
      nP.FParamA := ShowModal;
      Free;
    end;
   cCmd_EditData:
    with TfFormShouJu.Create(Application) do
    begin
      Caption := '�վ� - �޸�';
      FRecordID := nP.FParamA;

      InitFormData(FRecordID);
      nP.FCommand := cCmd_ModalResult;
      nP.FParamA := ShowModal;
      Free;
    end;
   cCmd_ViewData:
    begin
      if not Assigned(gForm) then
        gForm := TfFormShouJu.Create(Application);
      //xxxxx

      with gForm  do
      begin
        Caption := '�վ� - �鿴';
        FormStyle := fsStayOnTop;
        BtnOK.Visible := False;

        FRecordID := nP.FParamA;
        InitFormData(FRecordID);
        if not Showing then Show;
      end;
    end;
   cCmd_FormClose:
    begin
      if Assigned(gForm) then FreeAndNil(gForm);
    end;
  end;
end;

class function TfFormShouJu.FormID: integer;
begin
  Result := cFI_FormShouJu;
end;

procedure TfFormShouJu.FormCreate(Sender: TObject);
var nIni: TIniFile;
begin
  nIni := TIniFile.Create(gPath + sFormConfig);
  try
    LoadFormConfig(Self, nIni);
    FPrefixID := nIni.ReadString(Name, 'IDPrefix', 'SJ');
    FIDLength := nIni.ReadInteger(Name, 'IDLength', 8);
  finally
    nIni.Free;
  end;

  ResetHintAllForm(Self, 'T', sTable_SysShouJu);
  //���ñ�����
end;

procedure TfFormShouJu.FormClose(Sender: TObject;
  var Action: TCloseAction);
var nIni: TIniFile;
begin
  nIni := TIniFile.Create(gPath + sFormConfig);
  try
    SaveFormConfig(Self, nIni);
  finally
    nIni.Free;
  end;

  gForm := nil;
  Action := caFree;
end;

//------------------------------------------------------------------------------
procedure TfFormShouJu.GetData(Sender: TObject; var nData: string);
begin
  if Sender = EditDate then
  begin
    nData := DateTime2Str(EditDate.Date);
  end;
end;

function TfFormShouJu.SetData(Sender: TObject; const nData: string): Boolean;
begin
  Result := False;

  if Sender = EditDate then
  begin
    EditDate.Date := Str2DateTime(nData);
    Result := True;
  end;
end;

procedure TfFormShouJu.InitFormData(const nID: string);
var nStr: string;
begin
  EditDate.Date := Now;
  EditMan.Text := gSysParam.FUserID;

  if EditBank.Properties.Items.Count < 1 then
    LoadSysDictItem(sFlag_BankItem, EditBank.Properties.Items);
  //xxxxx
  
  if nID = '' then
  begin
    EditIDPropertiesButtonClick(nil, 0);
  end else
  begin
    nStr := 'Select * From %s Where R_ID=%s';
    nStr := Format(nStr, [sTable_SysShouJu, nID]);
    LoadDataToCtrl(FDM.QueryTemp(nStr), Self, '', SetData);
  end;
end;

//------------------------------------------------------------------------------
function SmallTOBig(small: real): string;
var
  SmallMonth, BigMonth: string;
  wei1, qianwei1: string[2];
  qianwei, dianweizhi, qian: integer;
  fs_bj: boolean;
begin
  if small < 0 then
    fs_bj := True
  else
    fs_bj := False;
  small      := abs(small);
  {------- �޸Ĳ�����ֵ����ȷ -------}
  {С������λ�ã���Ҫ�Ļ�Ҳ���ԸĶ�-2ֵ}
  qianwei    := -2;
  {ת���ɻ�����ʽ����Ҫ�Ļ�С�����Ӷ༸����}
  Smallmonth := formatfloat('0.00', small);
  {---------------------------------}
  dianweizhi := pos('.', Smallmonth);{С�����λ��}
  {ѭ��Сд���ҵ�ÿһλ����Сд���ұ�λ�õ����}
  for qian := length(Smallmonth) downto 1 do
  begin
    {��������Ĳ���С����ͼ���}
    if qian <> dianweizhi then
    begin
      {λ���ϵ���ת���ɴ�д}
      case StrToInt(Smallmonth[qian]) of
        1: wei1 := 'Ҽ';
        2: wei1 := '��';
        3: wei1 := '��';
        4: wei1 := '��';
        5: wei1 := '��';
        6: wei1 := '½';
        7: wei1 := '��';
        8: wei1 := '��';
        9: wei1 := '��';
        0: wei1 := '��';
      end;
      {�жϴ�дλ�ã����Լ�������real���͵����ֵ}
      case qianwei of
        -3: qianwei1 := '��';
        -2: qianwei1 := '��';
        -1: qianwei1 := '��';
        0: qianwei1  := 'Ԫ';
        1: qianwei1  := 'ʰ';
        2: qianwei1  := '��';
        3: qianwei1  := 'Ǫ';
        4: qianwei1  := '��';
        5: qianwei1  := 'ʰ';
        6: qianwei1  := '��';
        7: qianwei1  := 'Ǫ';
        8: qianwei1  := '��';
        9: qianwei1  := 'ʰ';
        10: qianwei1 := '��';
        11: qianwei1 := 'Ǫ';
      end;
      inc(qianwei);
      BigMonth := wei1 + qianwei1 + BigMonth;{��ϳɴ�д���}
    end;
  end;

  BigMonth := StringReplace(BigMonth, '��ʰ', '��', [rfReplaceAll]);
  BigMonth := StringReplace(BigMonth, '���', '��', [rfReplaceAll]);
  BigMonth := StringReplace(BigMonth, '��Ǫ', '��', [rfReplaceAll]);
  BigMonth := StringReplace(BigMonth, '������', '', [rfReplaceAll]);
  BigMonth := StringReplace(BigMonth, '���', '��', [rfReplaceAll]);
  BigMonth := StringReplace(BigMonth, '���', '', [rfReplaceAll]);
  BigMonth := StringReplace(BigMonth, '����', '��', [rfReplaceAll]);
  BigMonth := StringReplace(BigMonth, '����', '��', [rfReplaceAll]);
  BigMonth := StringReplace(BigMonth, '����', '��', [rfReplaceAll]);
  BigMonth := StringReplace(BigMonth, '����', '��', [rfReplaceAll]);
  BigMonth := StringReplace(BigMonth, '����', '��', [rfReplaceAll]);
  BigMonth := StringReplace(BigMonth, '��Ԫ', 'Ԫ', [rfReplaceAll]);
  BigMonth := StringReplace(BigMonth, '����', '��', [rfReplaceAll]);
  BigMonth := BigMonth + '��';
  BigMonth := StringReplace(BigMonth, '����', '��', [rfReplaceAll]);

  if BigMonth = 'Ԫ��' then
    BigMonth := '��Ԫ��';
  if copy(BigMonth, 1, 2) = 'Ԫ' then
    BigMonth := copy(BigMonth, 3, length(BigMonth) - 2);
  if copy(BigMonth, 1, 2) = '��' then
    BigMonth := copy(BigMonth, 3, length(BigMonth) - 2);
  if fs_bj = True then
    SmallTOBig := '- ' + BigMonth
  else
    SmallTOBig := BigMonth;
end;

//Desc: ���ݱ��
procedure TfFormShouJu.EditIDPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
var nID: integer;
begin
  nID := FDM.GetFieldMax(sTable_SysShouJu, 'R_ID') + 1;
  EditID.Text := FDM.GetSerialID2(FPrefixID, sTable_SysShouJu, 'R_ID', 'S_Code', nID);
end;

procedure TfFormShouJu.EditMoneyExit(Sender: TObject);
begin
  if IsNumber(EditMoney.Text, True) then
       EditBig.Text := SmallTOBig(StrToFloat(EditMoney.Text))
  else EditBig.Text := '';
end;

//Desc: ��֤����
function TfFormShouJu.OnVerifyCtrl(Sender: TObject; var nHint: string): Boolean;
var nStr: string;
begin
  Result := True;

  if Sender = EditID then
  begin
    Result := Trim(EditID.Text) <> '';
    nHint := '����д��Ч��ƾ������';
    if not Result then Exit;

    nStr := 'Select Count(*) From %s Where S_Code=''%s''';
    nStr := Format(nStr, [sTable_SysShouJu, EditID.Text]);

    if FRecordID <> '' then
      nStr := nStr + ' And R_ID<>' + FRecordID;
    //xxxxx

    Result := FDM.QueryTemp(nStr).Fields[0].AsInteger < 1;
    nHint := '��ƾ�������Ѿ�����';
  end else

  if Sender = EditMoney then
  begin
    Result := IsNumber(EditMoney.Text, True);
    nHint := '����д��Ч�Ľ��';
  end;
end;

//Desc: ����
procedure TfFormShouJu.BtnOKClick(Sender: TObject);
var nStr: string;
begin
  if not IsDataValid then Exit;

  if FRecordID = '' then
  begin
    nStr := MakeSQLByForm(Self, sTable_SysShouJu, '', True, GetData);
  end else
  begin
    nStr := 'R_ID=' + FRecordID;
    nStr := MakeSQLByForm(Self, sTable_SysShouJu, nStr, False, GetData);
  end;

  FDM.ADOConn.BeginTrans;
  try
    FDM.ExecuteSQL(nStr);
    if FRecordID = '' then
         nStr := IntToStr(FDM.GetFieldMax(sTable_SysShouJu, 'R_ID'))
    else nStr := FRecordID;

    FDM.ADOConn.CommitTrans;
    PrintShouJuReport(nStr, True);

    ModalResult := mrOK;
    ShowMsg('�����ѱ���', sHint);
  except
    FDM.ADOConn.RollbackTrans;
    ShowMsg('���ݱ���ʧ��', sError);
  end;
end;

initialization
  gControlManager.RegCtrl(TfFormShouJu, TfFormShouJu.FormID);
end.
