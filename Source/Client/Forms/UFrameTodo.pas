{*******************************************************************************
  ����: dmzn@163.com 2017-08-06
  ����: ����������
*******************************************************************************}
unit UFrameTodo;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  UFrameNormal, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter, cxData,
  cxDataStorage, cxEdit, DB, cxDBData, cxContainer, dxLayoutControl,
  cxTextEdit, cxMaskEdit, cxButtonEdit, ADODB, cxLabel, UBitmapPanel,
  cxSplitter, cxGridLevel, cxClasses, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGrid,
  ComCtrls, ToolWin, Menus;

type
  TfFrameTodo = class(TfFrameNormal)
    EditSMemo: TcxTextEdit;
    dxLayout1Item4: TdxLayoutItem;
    EditDate: TcxButtonEdit;
    dxLayout1Item6: TdxLayoutItem;
    EditTruck: TcxButtonEdit;
    dxLayout1Item1: TdxLayoutItem;
    PMenu1: TPopupMenu;
    N1: TMenuItem;
    procedure BtnAddClick(Sender: TObject);
    procedure EditDatePropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure EditTruckPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure PMenu1Popup(Sender: TObject);
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
  ULibFun, UMgrControl, USysConst, USysDB, UDataModule, UFormBase,
  UFormDateFilter, UFormInputbox;

class function TfFrameTodo.FrameID: integer;
begin
  Result := cFI_FrameTodo;
end;

procedure TfFrameTodo.OnCreateFrame;
begin
  inherited;
  InitDateRange(Name, FStart, FEnd);
end;

procedure TfFrameTodo.OnDestroyFrame;
begin
  SaveDateRange(Name, FStart, FEnd);
  inherited;
end;

//------------------------------------------------------------------------------
//Desc: ���ݲ�ѯSQL
function TfFrameTodo.InitFormDataSQL(const nWhere: string): string;
begin
  EditDate.Text := Format('%s �� %s', [Date2Str(FStart), Date2Str(FEnd)]);
  Result := 'Select * From $ME ';

  if nWhere = '' then
       Result := Result + 'Where (E_Date>=''$S'' and E_Date <''$E'')'
  else Result := Result + 'Where (' + nWhere + ')';
  //xxxxx
  
  Result := MacroValue(Result, [MI('$ME', sTable_ManualEvent),
            MI('$S', Date2Str(FStart)), MI('$E', Date2Str(FEnd + 1))]);
  //xxxxx                                                                        )
end;

//Desc: ����
procedure TfFrameTodo.BtnAddClick(Sender: TObject);
var nParam: TFormCommandParam;
begin
  nParam.FCommand := cCmd_AddData;
  CreateBaseFormItem(cFI_FormTodoSend, PopedomItem, @nParam);

  if (nParam.FCommand = cCmd_ModalResult) and (nParam.FParamA = mrOK) then
  begin
    InitFormData('');
  end;
end;

//Desc: ����ɸѡ
procedure TfFrameTodo.EditDatePropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  if ShowDateFilterForm(FStart, FEnd) then InitFormData(FWhere);
end;

procedure TfFrameTodo.EditTruckPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  if Sender = EditTruck then
  begin
    EditTruck.Text := Trim(EditTruck.Text);
    if EditTruck.Text = '' then Exit;

    FWhere := '(E_Event Like ''%' + EditTruck.Text + '%'')';
    if Length(EditTruck.Text) < 5 then
      FWhere := '(E_Date>=''$S'' and E_Date <''$E'') And ' + FWhere;
    InitFormData(FWhere);
  end
end;

procedure TfFrameTodo.PMenu1Popup(Sender: TObject);
begin
  N1.Enabled := BtnEdit.Enabled;
end;

procedure TfFrameTodo.N1Click(Sender: TObject);
var nStr,nRS,nSQL: string;
begin
  if cxView1.DataController.GetSelectedCount > 0 then
  begin
    nRS := SQLQuery.FieldByName('E_Result').AsString;
    nStr := nRS;

    while True do
    begin
      if not ShowInputBox('�������µĴ�����:', '���', nStr, 12) then Exit;
      nStr := Trim(nStr);
      if (nStr <> '') and (nStr <> nRS) then Break;
    end;

    nSQL := 'Update %s Set E_Result=''%s'' Where R_ID=%s';
    nSQL := Format(nSQL, [sTable_ManualEvent, nStr,
            SQLQuery.FieldByName('R_ID').AsString]);
    FDM.ExecuteSQL(nSQL);

    nSQL := '�޸ı�ʶΪ[ %s ]���¼�,������:[ %s -> %s ]';
    nSQL := Format(nSQL, [SQLQuery.FieldByName('R_ID').AsString, nRS, nStr]);
    FDM.WriteSysLog(sFlag_CommonItem,
                    SQLQuery.FieldByName('E_Key').AsString, nSQL);
    //write log

    InitFormData(FWhere);
  end;
end;

initialization
  gControlManager.RegCtrl(TfFrameTodo, TfFrameTodo.FrameID);
end.
