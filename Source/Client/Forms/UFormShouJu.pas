{*******************************************************************************
  作者: dmzn@163.com 2010-3-16
  描述: 收据管理
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
    //前缀编号
    FIDLength: integer;
    //前缀长度
    procedure InitFormData(const nID: string);
    //载入数据
    procedure GetData(Sender: TObject; var nData: string);
    //获取数据
    function SetData(Sender: TObject; const nData: string): Boolean;
    //设置数据
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
  //全局使用

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
      Caption := '收据 - 添加';

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
      Caption := '收据 - 修改';
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
        Caption := '收据 - 查看';
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
  //重置表名称
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
//Desc: 单据编号
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

//Desc: 验证数据
function TfFormShouJu.OnVerifyCtrl(Sender: TObject; var nHint: string): Boolean;
var nStr: string;
begin
  Result := True;

  if Sender = EditID then
  begin
    Result := Trim(EditID.Text) <> '';
    nHint := '请填写有效的凭单号码';
    if not Result then Exit;

    nStr := 'Select Count(*) From %s Where S_Code=''%s''';
    nStr := Format(nStr, [sTable_SysShouJu, EditID.Text]);

    if FRecordID <> '' then
      nStr := nStr + ' And R_ID<>' + FRecordID;
    //xxxxx

    Result := FDM.QueryTemp(nStr).Fields[0].AsInteger < 1;
    nHint := '该凭单号码已经存在';
  end else

  if Sender = EditMoney then
  begin
    Result := IsNumber(EditMoney.Text, True);
    nHint := '请填写有效的金额';
  end;
end;

//Desc: 保存
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
    ShowMsg('单据已保存', sHint);
  except
    FDM.ADOConn.RollbackTrans;
    ShowMsg('单据保存失败', sError);
  end;
end;

initialization
  gControlManager.RegCtrl(TfFormShouJu, TfFormShouJu.FormID);
end.
