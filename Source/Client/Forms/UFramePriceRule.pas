{*******************************************************************************
  作者: dmzn@163.com 2018-12-06
  描述: 价格规则
*******************************************************************************}
unit UFramePriceRule;

{$I Link.Inc}
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
  TfFramePriceRule = class(TfFrameNormal)
    EditArea: TcxButtonEdit;
    dxLayout1Item1: TdxLayoutItem;
    EditName: TcxButtonEdit;
    dxLayout1Item2: TdxLayoutItem;
    cxTextEdit1: TcxTextEdit;
    dxLayout1Item3: TdxLayoutItem;
    cxTextEdit2: TcxTextEdit;
    dxLayout1Item4: TdxLayoutItem;
    cxTextEdit4: TcxTextEdit;
    dxLayout1Item6: TdxLayoutItem;
    PMenu1: TPopupMenu;
    N1: TMenuItem;
    dxLayout1Item7: TdxLayoutItem;
    EditDate: TcxButtonEdit;
    N2: TMenuItem;
    N3: TMenuItem;
    procedure EditIDPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure BtnAddClick(Sender: TObject);
    procedure BtnEditClick(Sender: TObject);
    procedure BtnDelClick(Sender: TObject);
    procedure N2Click(Sender: TObject);
    procedure PMenu1Popup(Sender: TObject);
    procedure EditDatePropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure N3Click(Sender: TObject);
  private
    { Private declarations }
    FStart,FEnd: TDate;
    {*时间区间*}
  protected
    procedure OnCreateFrame; override;
    procedure OnDestroyFrame; override;
    function InitFormDataSQL(const nWhere: string): string; override;
    {*查询SQL*}
  public
    { Public declarations }
    class function FrameID: integer; override;
  end;

implementation

{$R *.dfm}
uses
  ULibFun, UMgrControl, UBusinessConst, UFormBase, UDataModule, USysBusiness,
  UFormDateFilter, UFormPriceShow, USysConst, USysDB;

class function TfFramePriceRule.FrameID: integer;
begin
  Result := cFI_FramePriceRule;
end;

procedure TfFramePriceRule.OnCreateFrame;
begin
  inherited;
  InitDateRange(Name, FStart, FEnd);

  if FStart = FEnd then
  begin
    FStart := Date() - 90;
    FEnd := Date() + 90;
  end;
end;

procedure TfFramePriceRule.OnDestroyFrame;
begin
  SaveDateRange(Name, FStart, FEnd);
  inherited;
end;

//Desc: 数据查询SQL
function TfFramePriceRule.InitFormDataSQL(const nWhere: string): string;
begin
  EditDate.Text := Format('%s 至 %s', [Date2Str(FStart), Date2Str(FEnd)]);
  Result := 'Select pr.*,wk.*,C_Name From $PR pr ' +
            ' Left Join $WK wk On wk.W_NO=pr.R_Week ' +
            ' Left Join $CM cm On cm.C_ID=pr.R_Customer ' +
            'Where ((R_Date>=''$S'' and R_Date <''$E'') Or ' +
            ' (W_Valid=''$OK'' Or (W_Begin>=''$S'' and W_Begin <''$E'')))';
  //xxxxx

  if nWhere <> '' then
    Result := Result + ' And (' + nWhere + ')';
  //xxxxx

  Result := MacroValue(Result, [MI('$WK', sTable_PriceWeek),
            MI('$PR', sTable_PriceRule), MI('$CM', sTable_Customer),
            MI('$OK', sFlag_Yes),
            MI('$S', DateTime2Str(FStart)), MI('$E', DateTime2Str(FEnd + 1))]);
  //xxxxx
end;

//------------------------------------------------------------------------------
//Desc: 零售价
procedure TfFramePriceRule.BtnAddClick(Sender: TObject);
var nWeek: string;
    nParam: TFormCommandParam;
begin
  if cxView1.DataController.GetSelectedCount < 1 then
       nWeek := ''
  else nWeek := SQLQuery.FieldByName('R_Week').AsString;

  nParam.FCommand := cCmd_AddData;
  nParam.FParamA := nWeek;
  CreateBaseFormItem(cFI_FormPriceRetail, PopedomItem, @nParam);

  if (nParam.FCommand = cCmd_ModalResult) and (nParam.FParamA = mrOK) then
  begin
    InitFormData('');
  end;
end;

//Desc: 区域价
procedure TfFramePriceRule.BtnEditClick(Sender: TObject);
var nWeek,nArea: string;
    nParam: TFormCommandParam;
begin
  if cxView1.DataController.GetSelectedCount < 1 then
  begin
    nWeek := '';
    nArea := '';
  end else
  begin
    nWeek := SQLQuery.FieldByName('R_Week').AsString;
    nArea := SQLQuery.FieldByName('R_Area').AsString;
  end;

  nParam.FCommand := cCmd_AddData;
  nParam.FParamA := nWeek;
  nParam.FParamB := nArea;

  CreateBaseFormItem(cFI_FormPriceArea, PopedomItem, @nParam);
  if (nParam.FCommand = cCmd_ModalResult) and (nParam.FParamA = mrOK) then
  begin
    InitFormData('');
  end;
end;

//Desc: 专用价
procedure TfFramePriceRule.BtnDelClick(Sender: TObject);
var nWeek,nCusID,nCusName: string;
    nParam: TFormCommandParam;
begin
  if cxView1.DataController.GetSelectedCount < 1 then
  begin
    nWeek := '';
    nCusID := '';
    nCusName := '';
  end else
  begin
    nWeek := SQLQuery.FieldByName('R_Week').AsString;
    nCusID := SQLQuery.FieldByName('R_Customer').AsString;
    nCusName := SQLQuery.FieldByName('C_Name').AsString;
  end;

  nParam.FCommand := cCmd_AddData;
  nParam.FParamA := nWeek;
  nParam.FParamB := nCusID;
  nParam.FParamC := nCusName;

  CreateBaseFormItem(cFI_FormPriceCustomer, PopedomItem, @nParam);
  if (nParam.FCommand = cCmd_ModalResult) and (nParam.FParamA = mrOK) then
  begin
    InitFormData('');
  end;
end;

procedure TfFramePriceRule.EditDatePropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  if ShowDateFilterForm(FStart, FEnd, False) then InitFormData(FWhere);
end;

//Desc: 执行查询
procedure TfFramePriceRule.EditIDPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  if Sender = EditArea then
  begin
    EditArea.Text := Trim(EditArea.Text);
    if EditArea.Text = '' then Exit;

    FWhere := 'R_Area like ''%' + EditArea.Text + '%''';
    InitFormData(FWhere);
  end else

  if Sender = EditName then
  begin
    EditName.Text := Trim(EditName.Text);
    if EditName.Text = '' then Exit;

    FWhere := 'C_Name like ''%%%s%%'' Or C_PY like ''%%%s%%''';
    FWhere := Format(FWhere, [EditName.Text, EditName.Text]);
    InitFormData(FWhere);
  end;
end;

//------------------------------------------------------------------------------
procedure TfFramePriceRule.PMenu1Popup(Sender: TObject);
begin

end;

//Desc: 查看周期图
procedure TfFramePriceRule.N2Click(Sender: TObject);
var nParam: TFormCommandParam;
begin
  nParam.FCommand := cCmd_ViewData;
  nParam.FParamA := FStart;
  nParam.FParamB := FEnd;
  CreateBaseFormItem(cFI_FormViewPriceWeek, PopedomItem, @nParam);
end;

//Desc: 查看价格单
procedure TfFramePriceRule.N3Click(Sender: TObject);
var nStr: string;
    nTypes: TStockTypeItems;
    nParam: TFormCommandParam;
begin
  nStr := SQLQuery.FieldByName('R_Customer').AsString;
  if nStr = '' then
  begin
    nParam.FCommand := cCmd_GetData;
    nParam.FParamA := '';
    CreateBaseFormItem(cFI_FormGetCustom, PopedomItem, @nParam);

    if (nParam.FCommand = cCmd_ModalResult) and (nParam.FParamA = mrOK) then
         nStr := nParam.FParamB
    else Exit;
  end;

  if LoadStockItemsPrice(nStr, nTypes) then
    ShowPriceViewForm(nTypes);
  //xxxxx
end;

initialization
  gControlManager.RegCtrl(TfFramePriceRule, TfFramePriceRule.FrameID);
end.
