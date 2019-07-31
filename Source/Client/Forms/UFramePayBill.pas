{*******************************************************************************
  作者: dmzn@163.com 2009-7-15
  描述: 发票记录
*******************************************************************************}
unit UFramePayBill;

{$I Link.inc}
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  UFrameNormal, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter, cxData,
  cxDataStorage, cxEdit, DB, cxDBData, cxContainer, dxLayoutControl,
  cxMaskEdit, cxButtonEdit, cxTextEdit, ADODB, cxLabel, UBitmapPanel,
  cxSplitter, cxGridLevel, cxClasses, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGrid,
  ComCtrls, ToolWin;

type
  TfFramePayBill = class(TfFrameNormal)
    cxTextEdit1: TcxTextEdit;
    dxLayout1Item1: TdxLayoutItem;
    EditID: TcxButtonEdit;
    dxLayout1Item2: TdxLayoutItem;
    cxTextEdit2: TcxTextEdit;
    dxLayout1Item4: TdxLayoutItem;
    EditDate: TcxButtonEdit;
    dxLayout1Item6: TdxLayoutItem;
    cxTextEdit4: TcxTextEdit;
    dxLayout1Item7: TdxLayoutItem;
    procedure EditDatePropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure EditTruckPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure BtnAddClick(Sender: TObject);
    procedure BtnDelClick(Sender: TObject);
  private
    { Private declarations }
  protected
    FStart,FEnd: TDate;
    //时间区间
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
  ULibFun, UMgrControl, USysConst, USysDB, UFormBase, UFormDateFilter,
  UDataModule;

//------------------------------------------------------------------------------
class function TfFramePayBill.FrameID: integer;
begin
  Result := cFI_FramePayBill;
end;

procedure TfFramePayBill.OnCreateFrame;
begin
  inherited;
  InitDateRange(Name, FStart, FEnd);
  BtnDel.Visible := True;
  BtnDel.Enabled := True;
end;

procedure TfFramePayBill.OnDestroyFrame;
begin
  SaveDateRange(Name, FStart, FEnd);
  inherited;
end;

function TfFramePayBill.InitFormDataSQL(const nWhere: string): string;
begin
  EditDate.Text := Format('%s 至 %s', [Date2Str(FStart), Date2Str(FEnd)]);
  
  Result := 'Select iom.*,sm.S_Name From $IOM iom ' +
            ' Left Join $SM sm On sm.S_ID=iom.F_SaleMan ' +
            'Where 1 = 1 ';
            
  if nWhere = '' then
       Result := Result + 'And (F_Date>=''$Start'' And F_Date <''$End'')'
  else Result := Result + 'And (' + nWhere + ')';

  Result := MacroValue(Result, [MI('$SM', sTable_Salesman),
            MI('$IOM', sTable_SysFaPiao),
            MI('$Start', Date2Str(FStart)), MI('$End', Date2Str(FEnd + 1))]);
end;

//------------------------------------------------------------------------------
//Desc: 发票
procedure TfFramePayBill.BtnAddClick(Sender: TObject);
var nP: TFormCommandParam;
begin
  nP.FParamA := '';
  CreateBaseFormItem(cFI_FormPayBill, '', @nP);

  if (nP.FCommand = cCmd_ModalResult) and (nP.FParamA = mrOK) then
  begin
    InitFormData;
  end;
end;

//Desc: 日期筛选
procedure TfFramePayBill.EditDatePropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  if ShowDateFilterForm(FStart, FEnd) then InitFormData(FWhere);
end;

//Desc: 执行查询
procedure TfFramePayBill.EditTruckPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  if Sender = EditID then
  begin
    EditID.Text := Trim(EditID.Text);
    if EditID.Text = '' then Exit;
    
    FWhere := '(F_CusID like ''%%%s%%'' Or F_CusName like ''%%%s%%'')';
    FWhere := Format(FWhere, [EditID.Text, EditID.Text]);
    InitFormData(FWhere);
  end else
end;

procedure TfFramePayBill.BtnDelClick(Sender: TObject);
var
  nStr : string;
begin
  inherited;
  if cxView1.DataController.GetSelectedCount < 1 then
  begin
    ShowMsg('请选择要删除的记录', sHint); Exit;
  end;

  if not QueryDlg('确定要对这条记录进行删除嘛？', sAsk) then Exit;

  nStr := 'Delete From %s where R_ID = ''%s'' ' ;
  nStr := Format(nStr, [sTable_SysFaPiao, SQLQuery.FieldByName('R_ID').AsString]);
  FDM.ExecuteSQL(nStr);
  InitFormData(FWhere);
  ShowMsg('发票记录已删除', sHint);
end;

initialization
  gControlManager.RegCtrl(TfFramePayBill, TfFramePayBill.FrameID);
end.
