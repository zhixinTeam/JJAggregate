{*******************************************************************************
  作者: dmzn@163.com 2010-3-14
  描述: 装车线管理
*******************************************************************************}
unit UFormZTLine;

{$I Link.Inc}
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  UFormNormal, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, cxMaskEdit, cxDropDownEdit,
  cxLabel, cxCheckBox, cxTextEdit, dxLayoutControl, StdCtrls, dxSkinsCore,
  dxSkinsDefaultPainters, dxSkinsdxLCPainter;

type
  TfFormZTLine = class(TfFormNormal)
    EditName: TcxTextEdit;
    dxLayout1Item5: TdxLayoutItem;
    EditID: TcxTextEdit;
    LayItem1: TdxLayoutItem;
    EditMax: TcxTextEdit;
    dxLayout1Item4: TdxLayoutItem;
    CheckValid: TcxCheckBox;
    dxLayout1Item7: TdxLayoutItem;
    EditStockName: TcxTextEdit;
    dxLayout1Item8: TdxLayoutItem;
    dxLayout1Group2: TdxLayoutGroup;
    dxLayout1Group3: TdxLayoutGroup;
    cxLabel2: TcxLabel;
    dxLayout1Item10: TdxLayoutItem;
    dxLayout1Group4: TdxLayoutGroup;
    EditPeer: TcxTextEdit;
    dxLayout1Item19: TdxLayoutItem;
    dxLayout1Item20: TdxLayoutItem;
    cxLabel4: TcxLabel;
    dxLayout1Group9: TdxLayoutGroup;
    EditStockID: TcxComboBox;
    dxLayout1Item21: TdxLayoutItem;
    EditType: TcxComboBox;
    dxLayout1Item3: TdxLayoutItem;
    dxLayout1Item22: TdxLayoutItem;
    cxLabel5: TcxLabel;
    dxLayout1Group10: TdxLayoutGroup;
    dxLayout1Group12: TdxLayoutGroup;
    dxlytmLayout1Item6: TdxLayoutItem;
    edt_Waiting: TcxTextEdit;
    dxLayout1Group5: TdxLayoutGroup;
    dxlytmLayout1Item61: TdxLayoutItem;
    cxlbl1: TcxLabel;
    dxLayout1Group6: TdxLayoutGroup;
    procedure BtnOKClick(Sender: TObject);
    procedure EditStockIDPropertiesChange(Sender: TObject);
  protected
    { Protected declarations }
    FID: string;
    //标识
    procedure InitFormData(const nID: string);
    procedure GetData(Sender: TObject; var nData: string);
    function SetData(Sender: TObject; const nData: string): Boolean;
    //数据处理
    procedure WriteOptionLog;
  public
    { Public declarations }
    function OnVerifyCtrl(Sender: TObject; var nHint: string): Boolean; override;
    class function CreateForm(const nPopedom: string = '';
      const nParam: Pointer = nil): TWinControl; override;
    class function FormID: integer; override;
  end;

function ShowAddZTLineForm: Boolean;
function ShowEditZTLineForm(const nID: string): Boolean;
//入口函数

implementation

{$R *.dfm}
uses
  IniFiles, ULibFun, UMgrControl, UDataModule, UFormInputbox, USysGrid,
  UFormCtrl, USysDB, USysConst ,USysLoger;

type
  TLineStockItem = record
    FID   : string;
    FName : string;
  end;

  TLineOldItem = record
    FID        : string;
    FName      : string;
    FStockNO   : string;
    FStockName : string;
    FType      : string;
    FQueueMax  : string;
    FPeer      : string;
    FValid     : Boolean;
  end;

var
  gStockItems: array of TLineStockItem;
  //品种列表
   gCheckValid: boolean;
  //通道钩选属性
  gOldLine: TLineOldItem;
  //原始通道配置

function ShowAddZTLineForm: Boolean;
begin
  with TfFormZTLine.Create(Application) do
  try
    FID := '';
    Caption := '装车线 - 添加';

    InitFormData('');
    Result := ShowModal = mrOk;
  finally
    Free;
  end;
end;

function ShowEditZTLineForm(const nID: string): Boolean;
begin
  with TfFormZTLine.Create(Application) do
  try
    FID := nID;
    Caption := '装车线 - 修改';

    InitFormData(nID);
    Result := ShowModal = mrOk;
  finally
    Free;
  end;
end;

class function TfFormZTLine.FormID: integer;
begin
  Result := cFI_FormZTLine;
end;

class function TfFormZTLine.CreateForm(const nPopedom: string;
  const nParam: Pointer): TWinControl;
begin
  Result := nil;
end;

//------------------------------------------------------------------------------
procedure TfFormZTLine.InitFormData(const nID: string);
var nStr: string;
    nIdx: Integer;
begin
  ResetHintAllForm(Self, 'T', sTable_ZTLines);
  //重置表名称

  if nID <> '' then
  begin
    EditID.Properties.ReadOnly := True;
    nStr := 'Select * From %s Where Z_ID=''%s''';
    nStr := Format(nStr, [sTable_ZTLines, nID]);

    if FDM.QueryTemp(nStr).RecordCount > 0 then
    begin
      EditStockID.Text := FDM.SqlTemp.FieldByName('Z_StockNo').AsString;
      LoadDataToCtrl(FDM.SqlTemp, Self, '', SetData);
    end;
  end;

  nStr := 'Select D_Value,D_ParamB From %s Where D_Name=''%s''';
  nStr := Format(nStr, [sTable_SysDict, sFlag_StockItem]);

  EditStockID.Properties.Items.Clear;
  SetLength(gStockItems, 0);

  with FDM.QueryTemp(nStr) do
  begin
    if RecordCount < 1 then Exit;
    SetLength(gStockItems, RecordCount);

    nIdx := 0;
    First;

    while not Eof do
    begin
      with gStockItems[nIdx] do
      begin
        FID := Fields[1].AsString;
        FName := Fields[0].AsString;
        EditStockID.Properties.Items.AddObject(FID + '.' + FName, Pointer(nIdx));
      end;

      Inc(nIdx);
      Next;
    end;
  end;

  //记录通道属性
  gOldLine.FID        := EditID.Text;
  gOldLine.FName      := EditName.Text;
  gOldLine.FStockNO   := EditStockID.Text;
  gOldLine.FStockName := EditStockName.Text;
  gOldLine.FType      := EditType.Text;
  gOldLine.FQueueMax  := EditMax.Text;
  gOldLine.FPeer      := EditPeer.Text;
  gOldLine.FValid     := CheckValid.Checked = True;

  {$IFNDEF LineWaitingCtl}
  dxlytmLayout1Item6.Visible:= False;
  dxlytmLayout1Item61.Visible:= False;
  edt_Waiting.Hint:= '';
  {$ENDIF}
end;

procedure TfFormZTLine.EditStockIDPropertiesChange(Sender: TObject);
var nIdx: Integer;
begin
  if (not EditStockID.Focused) or (EditStockID.ItemIndex < 0) then Exit;
  nIdx := Integer(EditStockID.Properties.Items.Objects[EditStockID.ItemIndex]);
  EditStockName.Text := gStockItems[nIdx].FName;
end;

function TfFormZTLine.SetData(Sender: TObject; const nData: string): Boolean;
begin
  Result := False;

  if Sender = EditType then
  begin
    Result := True;
    if nData = sFlag_TypeVIP then
      EditType.ItemIndex := 1 else
    if nData = sFlag_TypeZT then
      EditType.ItemIndex := 2 else
    if nData = sFlag_TypeShip then
      EditType.ItemIndex := 3
    else EditType.ItemIndex := 0;
  end else
  
  if Sender = CheckValid then
  begin
    Result := True;
    CheckValid.Checked := nData <> sFlag_No;
  end;
end;

procedure TfFormZTLine.GetData(Sender: TObject; var nData: string);
begin
  if Sender = EditType then
  begin
    case EditType.ItemIndex of
     0: nData := sFlag_TypeCommon;
     1: nData := sFlag_TypeVIP;
     2: nData := sFlag_TypeZT;
     3: nData := sFlag_TypeShip else nData := sFlag_TypeCommon;
    end;
  end else

  if Sender = CheckValid then
  begin
    if CheckValid.Checked   then
    begin
      nData := sFlag_Yes;
      gCheckValid := true;
    end else
    begin
      nData := sFlag_No;
      gCheckValid := false;
    end;
  end;
end;

function TfFormZTLine.OnVerifyCtrl(Sender: TObject; var nHint: string): Boolean;
var nVal: Integer;
begin
  Result := True;

  if Sender = EditID then
  begin
    EditID.Text := Trim(EditID.Text);
    Result := EditID.Text <> '';
    nHint := '请填写有效编号';
  end else

  if Sender = EditName then
  begin
    EditName.Text := Trim(EditName.Text);
    Result := EditName.Text <> '';
    nHint := '请填写有效名称';
  end else

  if Sender = EditStockID then
  begin
    Result := EditStockID.ItemIndex >= 0;
    nHint := '请选择品种';
  end else

  if Sender = EditMax then
  begin
    Result := IsNumber(EditMax.Text, False);
    nHint := '队列数为大于零的整数';
    if not Result then Exit;

    nVal := StrToInt(EditMax.Text);
    Result := (nVal > 0) and (nVal <= 50);
    nHint := '队列数在1-50之间'
  end else

  if Sender = EditPeer then
  begin
    Result := IsNumber(EditPeer.Text, False) and (StrToInt(EditPeer.Text) > 0);
    nHint := '袋重为大于0的整数';
    if not Result then Exit;
  end;
end;

procedure TfFormZTLine.BtnOKClick(Sender: TObject);
var nIdx: Integer;
    nList: TStrings;
    nStr,nEvent: string;
begin
  if not IsDataValid then Exit;

  nList := TStringList.Create;
  try
    nIdx := Integer(EditStockID.Properties.Items.Objects[EditStockID.ItemIndex]);
    nList.Add(Format('Z_StockNo=''%s''', [gStockItems[nIdx].FID]));
    //ext fields

    if FID = '' then
    begin
      nStr := MakeSQLByForm(Self, sTable_ZTLines, '', True, GetData, nList);
    end else
    begin
      nStr := Format('Z_ID=''%s''', [FID]);
      nStr := MakeSQLByForm(Self, sTable_ZTLines, nStr, False, GetData, nList);
    end;
  finally
    nList.Free;
  end;

  FDM.ExecuteSQL(nStr);
  ModalResult := mrOk;

  //--------------
//  if   gCheckValid = false then
//  begin
//       nEvent := '通道 [ %s ] 关闭';
//       nEvent := Format(nEvent, [EditID.Text]);
//       FDM.WriteSysLog(sFlag_TruckQueue, 'UFromZTline', nEvent);
//  end;
//  if   gCheckValid = true  then
//  begin
//       nEvent := '通道 [ %s ] 开启';
//       nEvent := Format(nEvent, [EditID.Text]);
//       FDM.WriteSysLog(sFlag_TruckQueue, 'UFromZTline',nEvent);
//  end;
  WriteOptionLog;
  //--写入操作通道日志
  ShowMsg('通道已保存,请等待刷新', sHint);
end;

procedure TfFormZTLine.WriteOptionLog;
var nEvent: string;
begin
  nEvent := '';

  if FID = '' then//add
  begin
    nEvent := '添加通道,通道编号[ %s ],通道名称[ %s ],品种编号[ %s ],' +
              '品种名称[ %s ],栈台类型[ %s ],队列容量[ %s ],单袋重量[ %s ],' +
              '是否启用[ %s ]';
    if gCheckValid = false then
    begin
      nEvent := Format(nEvent, [EditID.Text, EditName.Text, EditStockID.Text,
                                EditStockName.Text, EditType.Text, EditMax.Text,
                                EditPeer.Text,'否']);
    end;
    if gCheckValid = true  then
    begin
      nEvent := Format(nEvent, [EditID.Text, EditName.Text, EditStockID.Text,
                                EditStockName.Text, EditType.Text, EditMax.Text,
                                EditPeer.Text,'是']);
    end;
  end
  else//modify
  begin
    if gOldLine.FID <> EditID.Text then
    begin
      nEvent := nEvent + '通道编号由 [ %s ] --> [ %s ];';
      nEvent := Format(nEvent, [gOldLine.FID, EditID.Text]);
    end;
    if gOldLine.FName <> EditName.Text then
    begin
      nEvent := nEvent + '通道名称由 [ %s ] --> [ %s ];';
      nEvent := Format(nEvent, [gOldLine.FName, EditName.Text]);
    end;
    if gOldLine.FStockNO <> EditStockID.Text then
    begin
      nEvent := nEvent + '品种编号由 [ %s ] --> [ %s ];';
      nEvent := Format(nEvent, [gOldLine.FStockNO, EditStockID.Text]);
    end;
    if gOldLine.FStockName <> EditStockName.Text then
    begin
      nEvent := nEvent + '品种名称由 [ %s ] --> [ %s ];';
      nEvent := Format(nEvent, [gOldLine.FStockName, EditStockName.Text]);
    end;
    if gOldLine.FType <> EditType.Text then
    begin
      nEvent := nEvent + '栈台类型由 [ %s ] --> [ %s ];';
      nEvent := Format(nEvent, [gOldLine.FType, EditType.Text]);
    end;
    if gOldLine.FQueueMax <> EditMax.Text then
    begin
      nEvent := nEvent + '队列容量由 [ %s ] --> [ %s ];';
      nEvent := Format(nEvent, [gOldLine.FQueueMax, EditMax.Text]);
    end;
    if gOldLine.FPeer <> EditPeer.Text then
    begin
      nEvent := nEvent + '单袋重量由 [ %s ] --> [ %s ];';
      nEvent := Format(nEvent, [gOldLine.FPeer, EditPeer.Text]);
    end;
    if gOldLine.FValid <> gCheckValid then
    begin
      if gCheckValid then
      begin
        nEvent := nEvent + '通道状态由 [ 关闭 ] --> [ 启用 ];';
      end
      else
      begin
        nEvent := nEvent + '通道状态由 [ 启用 ] --> [ 关闭 ];';
      end;
    end;

    if nEvent <> '' then
    begin
      nEvent := '通道 [ %s ] 参数已被修改:' + nEvent;
      nEvent := Format(nEvent, [gOldLine.FID]);
    end;
  end;

  if nEvent <> '' then
  begin
    FDM.WriteSysLog(sFlag_TruckQueue, EditID.Text, nEvent);
  end;
end;

initialization
  gControlManager.RegCtrl(TfFormZTLine, TfFormZTLine.FormID);
end.
