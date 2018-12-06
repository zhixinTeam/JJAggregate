{*******************************************************************************
  ����: dmzn@163.com 2017-01-05
  ����: �����¼�
*******************************************************************************}
unit UFormTodoSend;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  UDataModule, UFormNormal, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, ComCtrls, ImgList, DB, ADODB,
  ExtCtrls, cxGroupBox, cxRadioGroup, cxMemo, cxTextEdit, cxListView,
  cxLabel, dxLayoutControl, StdCtrls, cxMaskEdit, cxDropDownEdit;

type
  TfFormTodoSend = class(TfFormNormal)
    EditPart: TcxComboBox;
    dxLayout1Item3: TdxLayoutItem;
    EditEvent: TcxMemo;
    dxLayout1Item4: TdxLayoutItem;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure BtnOKClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    class function CreateForm(const nPopedom: string = '';
      const nParam: Pointer = nil): TWinControl; override;
    class function FormID: integer; override;
  end;

implementation

{$R *.dfm}

uses
  IniFiles, ULibFun, UMgrControl, UFormBase, UFormCtrl, USysDB, USysConst;

class function TfFormTodoSend.CreateForm(const nPopedom: string;
  const nParam: Pointer): TWinControl;
var nP: PFormCommandParam;
begin
  if Assigned(nParam) then
       nP := nParam
  else nP := nil;
  
  Result := nil;
  with TfFormTodoSend.Create(Application) do
  try
    Caption := '�����¼�';
    if Assigned(nP) then
    begin
      nP.FCommand := cCmd_ModalResult;
      nP.FParamA := ShowModal;
    end else ShowModal;
  finally
    Free;
  end;
end;

class function TfFormTodoSend.FormID: integer;
begin
  Result := cFI_FormTodoSend;
end;

procedure TfFormTodoSend.FormCreate(Sender: TObject);
begin
  with EditPart.Properties do
  begin
    Items.Clear;
    Items.Add('ȫ��');
    Items.Add(sFlag_DepDaTing); 
    Items.Add(sFlag_DepBangFang);
    Items.Add(sFlag_DepJianZhuang);
  end;

  LoadFormConfig(Self);
end;

procedure TfFormTodoSend.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SaveFormConfig(Self);
end;

procedure TfFormTodoSend.BtnOKClick(Sender: TObject);
var nStr: string;
begin
  if EditPart.ItemIndex < 0 then
  begin
    ActiveControl := EditPart;
    ShowMsg('��ѡ����', sHint);
    Exit;
  end;

  EditEvent.Text := Trim(EditEvent.Text);
  if EditEvent.Text = '' then
  begin
    ActiveControl := EditEvent;
    ShowMsg('����д�¼�', sHint);
    Exit;
  end;

  if EditPart.ItemIndex > 0 then
       nStr := EditPart.Text
  else nStr := sFlag_Departments;

  nStr := MakeSQLByStr([
          SF('E_ID', Date2Str(Now,False) + Time2Str(Now,False)),
          SF('E_From', gSysParam.FDepartment),
          SF('E_Key', gSysParam.FUserID), SF('E_Event', EditEvent.Text),
          SF('E_Solution', 'Y=֪����'),
          SF('E_Departmen', nStr),
          SF('E_Date', sField_SQLServer_Now, sfVal)], sTable_ManualEvent, '', True);
  FDM.ExecuteSQL(nStr);

  ModalResult := mrOk;
  ShowMsg('���ͳɹ�', sHint);
end;

initialization
  gControlManager.RegCtrl(TfFormTodoSend, TfFormTodoSend.FormID);
end.
