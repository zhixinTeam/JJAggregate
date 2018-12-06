{*******************************************************************************
  作者: dmzn@163.com 2018-12-03
  描述: 销售价格周期
*******************************************************************************}
unit UFramePriceWeek;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, UFrameNormal, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter, cxData,
  cxDataStorage, cxEdit, DB, cxDBData, cxContainer, Menus, dxLayoutControl,
  cxTextEdit, cxMaskEdit, cxButtonEdit, ADODB, cxLabel, UBitmapPanel,
  cxSplitter, cxGridLevel, cxClasses, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGrid,
  ComCtrls, ToolWin;

type
  TfFramePriceWeek = class(TfFrameNormal)
    EditName: TcxButtonEdit;
    dxLayout1Item1: TdxLayoutItem;
    EditDesc: TcxTextEdit;
    dxLayout1Item3: TdxLayoutItem;
    EditSName: TcxTextEdit;
    dxLayout1Item7: TdxLayoutItem;
    EditDate: TcxButtonEdit;
    dxLayout1Item6: TdxLayoutItem;
    EditID: TcxButtonEdit;
    dxLayout1Item2: TdxLayoutItem;
    EditSID: TcxTextEdit;
    dxLayout1Item5: TdxLayoutItem;
    PMenu1: TPopupMenu;
    N1: TMenuItem;
    procedure EditIDPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure BtnAddClick(Sender: TObject);
    procedure BtnEditClick(Sender: TObject);
    procedure BtnDelClick(Sender: TObject);
    procedure EditDatePropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure cxView1FocusedRecordChanged(Sender: TcxCustomGridTableView;
      APrevFocusedRecord, AFocusedRecord: TcxCustomGridRecord;
      ANewItemRecordFocusingChanged: Boolean);
    procedure N1Click(Sender: TObject);
  private
    { Private declarations }
  protected
    FStart,FEnd: TDate;
    {*时间区间*}
    procedure OnCreateFrame; override;
    procedure OnDestroyFrame; override;
    {*基类函数*}
    function InitFormDataSQL(const nWhere: string): string; override;
    {*查询SQL*}
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
class function TfFramePriceWeek.FrameID: integer;
begin
  Result := cFI_FramePriceWeek;
end;

procedure TfFramePriceWeek.OnCreateFrame;
var nY,nM,nD: Word;
begin
  inherited;
  InitDateRange(Name, FStart, FEnd);

  if FStart = FEnd then
  begin
    DecodeDate(FStart, nY, nM, nD);
    FStart := EncodeDate(nY, 1, 1);
    FEnd := EncodeDate(nY+1, 1, 1) - 1;
  end;
end;

procedure TfFramePriceWeek.OnDestroyFrame;
begin
  SaveDateRange(Name, FStart, FEnd);
  inherited;
end;

//------------------------------------------------------------------------------
//Desc: 数据查询SQL
function TfFramePriceWeek.InitFormDataSQL(const nWhere: string): string;
begin
  EditDate.Text := Format('%s 至 %s', [DateTime2Str(FStart), DateTime2Str(FEnd)]);
  Result := 'Select * From $Week ';

  if nWhere = '' then
       Result := Result + 'Where (W_Date>=''$S'' and W_Date <''$E'') Or ' +
                                '(W_Begin>=''$S'' and W_Begin <''$E'')'
  else Result := Result + 'Where (' + nWhere + ')';

  Result := MacroValue(Result, [MI('$Week', sTable_PriceWeek),
            MI('$S', DateTime2Str(FStart)), MI('$E', DateTime2Str(FEnd + 1))]);
  //xxxxx
end;

//Desc: 添加
procedure TfFramePriceWeek.BtnAddClick(Sender: TObject);
var nParam: TFormCommandParam;
begin
  nParam.FCommand := cCmd_AddData;
  CreateBaseFormItem(cFI_FormPriceWeek, PopedomItem, @nParam);

  if (nParam.FCommand = cCmd_ModalResult) and (nParam.FParamA = mrOK) then
  begin
    InitFormData('');
  end;
end;

//Desc: 修改
procedure TfFramePriceWeek.BtnEditClick(Sender: TObject);
var nParam: TFormCommandParam;
begin
  if cxView1.DataController.GetSelectedCount < 1 then
  begin
    ShowMsg('请选择要编辑的记录', sHint); Exit;
  end;

  nParam.FCommand := cCmd_EditData;
  nParam.FParamA := SQLQuery.FieldByName('W_NO').AsString;
  CreateBaseFormItem(cFI_FormPriceWeek, PopedomItem, @nParam);

  if (nParam.FCommand = cCmd_ModalResult) and (nParam.FParamA = mrOK) then
  begin
    InitFormData(FWhere);
  end;
end;

//Desc: 删除
procedure TfFramePriceWeek.BtnDelClick(Sender: TObject);
var nStr,nID: string;
begin
  if cxView1.DataController.GetSelectedCount < 1 then
  begin
    ShowMsg('请选择要删除的记录', sHint); Exit;
  end;

  nID := SQLQuery.FieldByName('W_Name').AsString;
  nStr := Format('确定要删除名称为[ %s ]的记录吗?', [nID]);
  if not QueryDlg(nStr, sAsk) then Exit;

  nStr := 'Delete From %s Where W_NO=''%s''';
  nStr := Format(nStr, [sTable_PriceWeek, nID]);
  FDM.ExecuteSQL(nStr);

  InitFormData(FWhere);
  ShowMsg('记录已删除', sHint);
end;

//Desc: 执行查询
procedure TfFramePriceWeek.EditIDPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  if Sender = EditID then
  begin
    EditID.Text := Trim(EditID.Text);
    if EditID.Text = '' then Exit;

    FWhere := 'W_NO like ''%' + EditID.Text + '%''';
    InitFormData(FWhere);
  end else

  if Sender = EditName then
  begin
    EditName.Text := Trim(EditName.Text);
    if EditName.Text = '' then Exit;

    FWhere := 'W_Name like ''%' + EditName.Text + '%''';
    InitFormData(FWhere);
  end;
end;

//Desc: 日期筛选
procedure TfFramePriceWeek.EditDatePropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  if ShowDateFilterForm(FStart, FEnd, True) then InitFormData(FWhere);
end;

procedure TfFramePriceWeek.cxView1FocusedRecordChanged(
  Sender: TcxCustomGridTableView; APrevFocusedRecord,
  AFocusedRecord: TcxCustomGridRecord;
  ANewItemRecordFocusingChanged: Boolean);
begin
  if FShowDetailInfo and Assigned(APrevFocusedRecord) then
  begin
    EditSID.Text := SQLQuery.FieldByName('W_NO').AsString;
    EditSName.Text := SQLQuery.FieldByName('W_Name').AsString;
    EditDesc.Text := Format('%s 至 %s', [
            DateTime2Str(SQLQuery.FieldByName('W_Begin').AsDateTime),
            DateTime2Str(SQLQuery.FieldByName('W_End').AsDateTime)]);
  end;
end;

//Desc: 查看周期图
procedure TfFramePriceWeek.N1Click(Sender: TObject);
var nParam: TFormCommandParam;
begin
  nParam.FCommand := cCmd_ViewData;
  nParam.FParamA := FStart;
  nParam.FParamB := FEnd;
  CreateBaseFormItem(cFI_FormViewPriceWeek, PopedomItem, @nParam);
end;

initialization
  gControlManager.RegCtrl(TfFramePriceWeek, TfFramePriceWeek.FrameID);
end.
