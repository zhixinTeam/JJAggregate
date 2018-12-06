{*******************************************************************************
  ����: dmzn@163.com 2017-01-11
  ����: ������ϸ
*******************************************************************************}
unit UFrameQuerySaleTotal;

{$I Link.inc}
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  UFrameNormal, IniFiles, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter, cxData,
  cxDataStorage, cxEdit, DB, cxDBData, cxContainer, Menus, dxLayoutControl,
  StdCtrls, cxRadioGroup, cxMaskEdit, cxButtonEdit, cxTextEdit, ADODB,
  cxLabel, UBitmapPanel, cxSplitter, cxGridLevel, cxClasses,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, ComCtrls, ToolWin;

type
  TfFrameSaleDetailTotal = class(TfFrameNormal)
    cxtxtdt1: TcxTextEdit;
    dxLayout1Item5: TdxLayoutItem;
    EditDate: TcxButtonEdit;
    dxLayout1Item6: TdxLayoutItem;
    EditCustomer: TcxButtonEdit;
    dxLayout1Item8: TdxLayoutItem;
    cxtxtdt2: TcxTextEdit;
    dxLayout1Item1: TdxLayoutItem;
    pmPMenu1: TPopupMenu;
    mniN1: TMenuItem;
    cxtxtdt4: TcxTextEdit;
    dxLayout1Item3: TdxLayoutItem;
    Radio1: TcxRadioButton;
    dxLayout1Item2: TdxLayoutItem;
    Radio2: TcxRadioButton;
    dxLayout1Item4: TdxLayoutItem;
    cxLabel1: TcxLabel;
    dxLayout1Item7: TdxLayoutItem;
    procedure EditDatePropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure EditTruckPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure mniN1Click(Sender: TObject);
  private
    { Private declarations }
  protected
    FStart,FEnd: TDate;
    FTimeS,FTimeE: TDate;
    //ʱ������
    FJBWhere: string;
    //��������
    FValue,FMoney: Double;
    //���۲�����
    procedure OnCreateFrame; override;
    procedure OnDestroyFrame; override;
    procedure OnLoadGridConfig(const nIni: TIniFile); override;
    function FilterColumnField: string; override;
    function InitFormDataSQL(const nWhere: string): string; override;
    //��ѯSQL
    procedure SummaryItemsGetText(Sender: TcxDataSummaryItem;
      const AValue: Variant; AIsFooter: Boolean; var AText: String);
    //����ժҪ
  public
    { Public declarations }
    class function FrameID: integer; override;
  end;

implementation

{$R *.dfm}
uses
  ULibFun, UMgrControl, UFormDateFilter, USysPopedom, USysBusiness,
  UBusinessConst, USysConst, USysDB;

class function TfFrameSaleDetailTotal.FrameID: integer;
begin
  Result := cFI_FrameSaleTotalQuery;
end;

procedure TfFrameSaleDetailTotal.OnCreateFrame;
begin
  inherited;
  FTimeS := Str2DateTime(Date2Str(Now) + ' 00:00:00');
  FTimeE := Str2DateTime(Date2Str(Now) + ' 00:00:00');

  FJBWhere := '';
  InitDateRange(Name, FStart, FEnd);
end;

procedure TfFrameSaleDetailTotal.OnDestroyFrame;
begin
  SaveDateRange(Name, FStart, FEnd);
  inherited;
end;

procedure TfFrameSaleDetailTotal.OnLoadGridConfig(const nIni: TIniFile);
var i,nCount: Integer;
begin
  with cxView1.DataController.Summary do
  begin
    nCount := FooterSummaryItems.Count - 1;
    for i:=0 to nCount do
      FooterSummaryItems[i].OnGetText := SummaryItemsGetText;
    //���¼�

    nCount := DefaultGroupSummaryItems.Count - 1;
    for i:=0 to nCount do
      DefaultGroupSummaryItems[i].OnGetText := SummaryItemsGetText;
    //���¼�
  end;

  inherited;
end;

//------------------------------------------------------------------------------
function TfFrameSaleDetailTotal.InitFormDataSQL(const nWhere: string): string;
begin
  FEnableBackDB := True;
  EditDate.Text := Format('%s �� %s', [Date2Str(FStart), Date2Str(FEnd)]);

  {$IFDEF CastMoney}
  if Radio1.Checked then
  begin
    Result := 'select L_SaleID,L_SaleMan,L_CusID,L_CusName,L_CusPY,' +
              'CAST(Sum(L_Value) as decimal(38, 2)) as L_Value,' +
              'CAST(Sum(L_Value * L_Price) as decimal(38, 2)) as L_Money ' +
              'From $Bill ';
    //xxxxx
  end else
  begin
    Result := 'select L_SaleID,L_SaleMan,L_CusID,L_CusName,L_CusPY,L_Type,' +
              'L_StockNo,L_StockName,CAST(Sum(L_Value) as decimal(38, 2)) as L_Value,' +
              'CAST(Sum(L_Value * L_Price) as decimal(38, 2)) as L_Money From $Bill ';
    //xxxxx
  end;
  {$ELSE}
  if Radio1.Checked then
  begin
    Result := 'select L_SaleID,L_SaleMan,L_CusID,L_CusName,L_CusPY,' +
              'Sum(L_Value) as L_Value,Sum(L_Value * L_Price) as L_Money ' +
              'From $Bill ';
    //xxxxx
  end else
  begin
    Result := 'select L_SaleID,L_SaleMan,L_CusID,L_CusName,L_CusPY,L_Type,' +
              'L_StockNo,L_StockName,Sum(L_Value) as L_Value,' +
              'Sum(L_Value * L_Price) as L_Money From $Bill ';
    //xxxxx
  end;
  {$ENDIF}

  if FJBWhere = '' then
  begin
    Result := Result + 'Where (L_OutFact>=''$S'' and L_OutFact <''$End'')';

    if nWhere <> '' then
      Result := Result + ' And (' + nWhere + ')';
    //xxxxx
  end else
  begin
    Result := Result + ' Where (' + FJBWhere + ')';
  end;

  if Radio1.Checked then
  begin
    Result := Result + ' Group By L_SaleID,L_SaleMan,L_CusID,L_CusName,L_CusPY';
  end else
  begin
    Result := Result + ' Group By L_SaleID,L_SaleMan,L_CusID,L_CusName,L_CusPY,' +
              'L_Type,L_StockNo,L_StockName';
    //xxxxx
  end;

  Result := MacroValue(Result, [MI('$Bill', sTable_Bill),
            MI('$S', Date2Str(FStart)), MI('$End', Date2Str(FEnd + 1))]);
  //xxxxx

  Result := 'Select *,(case L_Value when 0 then 0 else convert(decimal(15,2),' +
            'L_Money/L_Value) end) as L_Price From (' + Result + ') t';
  //�������
end;

//Desc: �����ֶ�
function TfFrameSaleDetailTotal.FilterColumnField: string;
begin
  if gPopedomManager.HasPopedom(PopedomItem, sPopedom_ViewPrice) then
       Result := ''
  else Result := 'L_Price;L_Money';
end;

//Desc: ����ɸѡ
procedure TfFrameSaleDetailTotal.EditDatePropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  if ShowDateFilterForm(FStart, FEnd) then InitFormData(FWhere);
end;

//Desc: ִ�в�ѯ
procedure TfFrameSaleDetailTotal.EditTruckPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  if Sender = EditCustomer then
  begin
    EditCustomer.Text := Trim(EditCustomer.Text);
    if EditCustomer.Text = '' then Exit;

    FWhere := 'L_CusPY like ''%%%s%%'' Or L_CusName like ''%%%s%%''';
    FWhere := Format(FWhere, [EditCustomer.Text, EditCustomer.Text]);
    InitFormData(FWhere);
  end;
end;

//Desc: ʱ��β�ѯ
procedure TfFrameSaleDetailTotal.mniN1Click(Sender: TObject);
begin
  if ShowDateFilterForm(FTimeS, FTimeE, True) then
  try
    FJBWhere := '(L_OutFact>=''%s'' and L_OutFact <''%s'')';
    FJBWhere := Format(FJBWhere, [DateTime2Str(FTimeS), DateTime2Str(FTimeE),
                sFlag_BillPick, sFlag_BillPost]);
    InitFormData('');
  finally
    FJBWhere := '';
  end;
end;

//Desc: �������
procedure TfFrameSaleDetailTotal.SummaryItemsGetText(
  Sender: TcxDataSummaryItem; const AValue: Variant; AIsFooter: Boolean;
  var AText: String);
var nStr: string;
begin
  nStr := TcxGridDBColumn(TcxGridTableSummaryItem(Sender).Column).DataBinding.FieldName;
  try
    if CompareText(nStr, 'L_Value') = 0 then FValue := SplitFloatValue(AText);
    if CompareText(nStr, 'L_Money') = 0 then FMoney := SplitFloatValue(AText);

    if CompareText(nStr, 'L_Price') = 0 then
    begin
      if FValue = 0 then
           AText := '����: 0.00Ԫ'
      else AText := Format('����: %.2fԪ', [Round(FMoney / FValue * cPrecision) / cPrecision]);
    end;
  except
    //ignor any error
  end;
end;

initialization
  gControlManager.RegCtrl(TfFrameSaleDetailTotal, TfFrameSaleDetailTotal.FrameID);
end.
