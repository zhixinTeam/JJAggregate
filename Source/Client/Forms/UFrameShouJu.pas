{*******************************************************************************
  ����: dmzn@163.com 2009-6-15
  ����: ����ֽ��
*******************************************************************************}
unit UFrameShouJu;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  UFrameNormal, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter, cxData,
  cxDataStorage, cxEdit, DB, cxDBData, cxContainer, Menus, dxLayoutControl,
  cxTextEdit, cxMaskEdit, cxButtonEdit, ADODB, cxLabel, UBitmapPanel,
  cxSplitter, cxGridLevel, cxClasses, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGrid,
  ComCtrls, ToolWin;

type
  TfFrameShouJu = class(TfFrameNormal)
    EditID: TcxButtonEdit;
    dxLayout1Item1: TdxLayoutItem;
    EditCode: TcxButtonEdit;
    dxLayout1Item2: TdxLayoutItem;
    EditSCode: TcxTextEdit;
    dxLayout1Item3: TdxLayoutItem;
    EditSMemo: TcxTextEdit;
    dxLayout1Item4: TdxLayoutItem;
    EditSID: TcxTextEdit;
    dxLayout1Item7: TdxLayoutItem;
    PMenu1: TPopupMenu;
    N1: TMenuItem;
    EditDate: TcxButtonEdit;
    dxLayout1Item6: TdxLayoutItem;
    procedure EditIDPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure BtnAddClick(Sender: TObject);
    procedure BtnEditClick(Sender: TObject);
    procedure BtnDelClick(Sender: TObject);
    procedure BtnExitClick(Sender: TObject);
    procedure EditDatePropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure cxView1FocusedRecordChanged(Sender: TcxCustomGridTableView;
      APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
      ANewItemRecordFocusingChanged: Boolean);
    procedure cxView1DblClick(Sender: TObject);
    procedure N1Click(Sender: TObject);
  private
    { Private declarations }
  protected
    FStart,FEnd: TDate;
    {*ʱ������*}
    procedure OnCreateFrame; override;
    procedure OnDestroyFrame; override;
    {*���ຯ��*}
    function InitFormDataSQL(const nWhere: string): string; override;
    {*��ѯSQL*}
  public
    { Public declarations }
    class function FrameID: integer; override;
  end;

implementation

{$R *.dfm}
uses
  ULibFun, UMgrControl, USysConst, USysDB, UDataModule, UFormBase, USysBusiness,
  UFormDateFilter;

//------------------------------------------------------------------------------
class function TfFrameShouJu.FrameID: integer;
begin
  Result := cFI_FrameShouJu;
end;

procedure TfFrameShouJu.OnCreateFrame;
begin
  inherited;
  InitDateRange(Name, FStart, FEnd);
end;

procedure TfFrameShouJu.OnDestroyFrame;
begin
  SaveDateRange(Name, FStart, FEnd);
  inherited;
end;

//Desc: �ر�
procedure TfFrameShouJu.BtnExitClick(Sender: TObject);
var nParam: TFormCommandParam;
begin
  if not IsBusy then
  begin
    nParam.FCommand := cCmd_FormClose;
    CreateBaseFormItem(cFI_FormShouJu, '', @nParam); Close;
  end;
end;

//------------------------------------------------------------------------------
//Desc: ���ݲ�ѯSQL
function TfFrameShouJu.InitFormDataSQL(const nWhere: string): string;
begin
  EditDate.Text := Format('%s �� %s', [Date2Str(FStart), Date2Str(FEnd)]);
  Result := 'Select * From $SJ ';

  if nWhere = '' then
       Result := Result + 'Where (S_Date>=''$S'' and S_Date <''$E'')'
  else Result := Result + 'Where (' + nWhere + ')';
  
  Result := MacroValue(Result, [MI('$SJ', sTable_SysShouJu),
            MI('$S', Date2Str(FStart)), MI('$E', Date2Str(FEnd + 1))]);
  //xxxxx                                                                        )
end;

//Desc: ���
procedure TfFrameShouJu.BtnAddClick(Sender: TObject);
var nParam: TFormCommandParam;
begin
  nParam.FCommand := cCmd_AddData;
  CreateBaseFormItem(cFI_FormShouJu, PopedomItem, @nParam);

  if (nParam.FCommand = cCmd_ModalResult) and (nParam.FParamA = mrOK) then
  begin
    InitFormData('');
  end;
end;

//Desc: �޸�
procedure TfFrameShouJu.BtnEditClick(Sender: TObject);
var nParam: TFormCommandParam;
begin
  if cxView1.DataController.GetSelectedCount < 1 then
  begin
    ShowMsg('��ѡ��Ҫ�༭�ļ�¼', sHint); Exit;
  end;

  nParam.FCommand := cCmd_EditData;
  nParam.FParamA := SQLQuery.FieldByName('R_ID').AsString;
  CreateBaseFormItem(cFI_FormShouJu, PopedomItem, @nParam);

  if (nParam.FCommand = cCmd_ModalResult) and (nParam.FParamA = mrOK) then
  begin
    InitFormData(FWhere);
  end;
end;

//Desc: ɾ��
procedure TfFrameShouJu.BtnDelClick(Sender: TObject);
var nStr,nID: string;
begin
  if cxView1.DataController.GetSelectedCount < 1 then
  begin
    ShowMsg('��ѡ��Ҫɾ���ļ�¼', sHint); Exit;
  end;

  nID := SQLQuery.FieldByName('S_Code').AsString;
  nStr := Format('ȷ��Ҫɾ��ƾ����Ϊ[ %s ]���վ���?', [nID]);

  if QueryDlg(nStr, sAsk) then
  begin
    nID := SQLQuery.FieldByName('R_ID').AsString;
    nStr := 'Delete From %s Where R_ID=''%s''';
    nStr := Format(nStr, [sTable_SysShouJu, nID]);

    FDM.ExecuteSQL(nStr);
    InitFormData(FWhere);
    ShowMsg('�վ���ɾ��', sHint);
  end;
end;

//Desc: �鿴��ϸ
procedure TfFrameShouJu.cxView1DblClick(Sender: TObject);
var nParam: TFormCommandParam;
begin
  if cxView1.DataController.GetSelectedCount > 0 then
  begin
    nParam.FCommand := cCmd_ViewData;
    nParam.FParamA := SQLQuery.FieldByName('R_ID').AsString;
    CreateBaseFormItem(cFI_FormShouJu, PopedomItem, @nParam);
  end;
end;

//Desc: ִ�в�ѯ
procedure TfFrameShouJu.EditIDPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  if Sender = EditID then
  begin
    EditID.Text := Trim(EditID.Text);
    if EditID.Text = '' then Exit;

    FWhere := 'R_ID like ''%' + EditID.Text + '%''';
    InitFormData(FWhere);
  end else

  if Sender = EditCode then
  begin
    EditCode.Text := Trim(EditCode.Text);
    if EditCode.Text = '' then Exit;

    FWhere := 'S_Code like ''%' + EditCode.Text + '%''';
    InitFormData(FWhere);
  end;
end;

//Desc: ����ɸѡ
procedure TfFrameShouJu.EditDatePropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  if ShowDateFilterForm(FStart, FEnd) then InitFormData(FWhere);
end;

procedure TfFrameShouJu.cxView1FocusedRecordChanged(
  Sender: TcxCustomGridTableView; APrevFocusedRecord,
  AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
var nStr: string;
begin
  if FShowDetailInfo and Assigned(APrevFocusedRecord) then
  begin
    nStr := SQLQuery.FieldByName('R_ID').AsString;
    EditSID.Text := StringOfChar('0', cShouJuIDLength - Length(nStr)) + nStr;
    
    EditSCode.Text := SQLQuery.FieldByName('S_Code').AsString;
    EditSMemo.Text := '����:' + SQLQuery.FieldByName('S_Sender').AsString + ' ' +
                    '����:' + SQLQuery.FieldByName('S_Reason').AsString + ' ' +
                    '���:' + SQLQuery.FieldByName('S_Money').AsString + ' Ԫ';
  end;
end;

//Desc: ��ӡ�վ�
procedure TfFrameShouJu.N1Click(Sender: TObject);
var nStr: string;
begin
  if cxView1.DataController.GetSelectedCount > 0 then
  begin
    nStr := SQLQuery.FieldByName('R_ID').AsString;
    PrintShouJuReport(nStr, False);
  end;
end;

initialization
  gControlManager.RegCtrl(TfFrameShouJu, TfFrameShouJu.FrameID);
end.
