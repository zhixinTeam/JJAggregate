{*******************************************************************************
  ����: dmzn@163.com 2015-01-16
  ����: ���ε�������
*******************************************************************************}
unit UFrameBatcodeJ;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  UFrameNormal, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter, cxData,
  cxDataStorage, cxEdit, DB, cxDBData, cxContainer, Menus, dxLayoutControl,
  cxMaskEdit, cxButtonEdit, cxTextEdit, ADODB, cxLabel, UBitmapPanel,
  cxSplitter, cxGridLevel, cxClasses, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGrid,
  ComCtrls, ToolWin;

type
  TfFrameBatcode = class(TfFrameNormal)
    cxTextEdit1: TcxTextEdit;
    dxLayout1Item1: TdxLayoutItem;
    EditName: TcxButtonEdit;
    dxLayout1Item2: TdxLayoutItem;
    cxTextEdit2: TcxTextEdit;
    dxLayout1Item4: TdxLayoutItem;
    cxTextEdit3: TcxTextEdit;
    dxLayout1Item3: TdxLayoutItem;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    procedure EditNamePropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure BtnAddClick(Sender: TObject);
    procedure BtnEditClick(Sender: TObject);
    procedure BtnDelClick(Sender: TObject);
    procedure N1Click(Sender: TObject);
  private
    { Private declarations }
  protected
    function InitFormDataSQL(const nWhere: string): string; override;
    {*��ѯSQL*}
  public
    { Public declarations }
    class function FrameID: integer; override;
  end;

implementation

{$R *.dfm}
uses
  ULibFun, UMgrControl, USysBusiness, USysConst, USysDB, UDataModule, UFormBase;

class function TfFrameBatcode.FrameID: integer;
begin
  Result := cFI_FrameBatch;
end;

function TfFrameBatcode.InitFormDataSQL(const nWhere: string): string;
begin
  Result := 'Select * From ' + sTable_StockBatcode;
  if nWhere <> '' then
    Result := Result + ' Where (' + nWhere + ')';
  Result := Result + ' Order By B_Name';
end;

//Desc: ���
procedure TfFrameBatcode.BtnAddClick(Sender: TObject);
var nP: TFormCommandParam;
begin
  nP.FCommand := cCmd_AddData;
  CreateBaseFormItem(cFI_FormBatch, '', @nP);

  if (nP.FCommand = cCmd_ModalResult) and (nP.FParamA = mrOK) then
  begin
    InitFormData('');
  end;
end;

//Desc: �޸�
procedure TfFrameBatcode.BtnEditClick(Sender: TObject);
var nP: TFormCommandParam;
begin
  if cxView1.DataController.GetSelectedCount > 0 then
  begin
    nP.FCommand := cCmd_EditData;
    nP.FParamA := SQLQuery.FieldByName('R_ID').AsString;
    CreateBaseFormItem(cFI_FormBatch, '', @nP);

    if (nP.FCommand = cCmd_ModalResult) and (nP.FParamA = mrOK) then
    begin
      InitFormData(FWhere);
    end;
  end;
end;

//Desc: ɾ��
procedure TfFrameBatcode.BtnDelClick(Sender: TObject);
var nStr: string;
begin
  if cxView1.DataController.GetSelectedCount > 0 then
  begin
    nStr := SQLQuery.FieldByName('B_Name').AsString;
    nStr := Format('ȷ��Ҫɾ������[ %s ]������������?', [nStr]);
    if not QueryDlg(nStr, sAsk) then Exit;

    nStr := 'Delete From %s Where R_ID=%s';
    nStr := Format(nStr, [sTable_StockBatcode, SQLQuery.FieldByName('R_ID').AsString]);

    FDM.ExecuteSQL(nStr);
    InitFormData(FWhere);
  end;
end;

//Desc: ��ѯ
procedure TfFrameBatcode.EditNamePropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  if Sender = EditName then
  begin
    EditName.Text := Trim(EditName.Text);
    if EditName.Text = '' then Exit;

    FWhere := Format('B_Name Like ''%%%s%%''', [EditName.Text]);
    InitFormData(FWhere);
  end;
end;

//Desc: У����ǰ����ʹ����
procedure TfFrameBatcode.N1Click(Sender: TObject);
var nSQL, nCode: string;
    nVal: Double;
begin
  inherited;
  if cxView1.DataController.GetSelectedCount > 0 then
  begin
    nCode := SQLQuery.FieldByName('B_Batcode').AsString;

    nSQL := 'Select Sum(L_Value) From %s Where L_HYDan=''%s''';
    nSQL := Format(nSQL, [sTable_Bill, nCode]);
    with FDM.QuerySQL(nSQL) do
    if RecordCount > 0 then
    begin
      nVal := Fields[0].AsFloat;

      nSQL := 'Update %s Set B_HasUse=%.2f Where B_Batcode=''%s''';
      nSQL := Format(nSQL, [sTable_StockBatcode, nVal, nCode]);
      FDM.ExecuteSQL(nSQL);
    end;
    //У��Ϊ��ǰ����ʹ�õ�������        

    InitFormData('');
  end;
end;

initialization
  gControlManager.RegCtrl(TfFrameBatcode, TfFrameBatcode.FrameID);
end.
