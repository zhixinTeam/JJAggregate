{*******************************************************************************
  作者: dmzn@163.com 2018-12-21
  描述: 派车计划
*******************************************************************************}
unit UFormTruckPlan;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  UFormBase, UFormNormal, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, cxMaskEdit, cxDropDownEdit,
  cxTextEdit, dxLayoutControl, StdCtrls, cxCheckBox, cxLabel, cxMemo,
  cxCalendar, cxButtonEdit, cxListBox, Menus;

type
  TfFormTruckPlan = class(TfFormNormal)
    EditCus: TcxButtonEdit;
    dxLayout1Item3: TdxLayoutItem;
    EditBegin: TcxDateEdit;
    dxLayout1Item4: TdxLayoutItem;
    EditEnd: TcxDateEdit;
    dxLayout1Item5: TdxLayoutItem;
    EditTrucks: TcxMemo;
    dxLayout1Item6: TdxLayoutItem;
    ListHistory: TcxListBox;
    dxLayout1Item7: TdxLayoutItem;
    dxLayout1Group3: TdxLayoutGroup;
    EditTruck: TcxTextEdit;
    dxLayout1Item8: TdxLayoutItem;
    dxLayout1Group2: TdxLayoutGroup;
    PMenu1: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    N5: TMenuItem;
    N6: TMenuItem;
    procedure BtnOKClick(Sender: TObject);
    procedure EditCusPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure EditTruckPropertiesChange(Sender: TObject);
    procedure EditTruckKeyPress(Sender: TObject; var Key: Char);
    procedure N1Click(Sender: TObject);
    procedure N3Click(Sender: TObject);
    procedure N4Click(Sender: TObject);
    procedure EditTrucksDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure EditTrucksDragDrop(Sender, Source: TObject; X, Y: Integer);
  protected
    { Protected declarations }
    FCusID,FCusName: string;
    FPlanID: string;
    FTruckHistory: TStrings;
    procedure LoadFormData(const nID: string);
    procedure LoadTruckHistorData(const nAll: Boolean);
    procedure LoadTruckHistoryList;
    function OnVerifyCtrl(Sender: TObject; var nHint: string): Boolean; override;
  public
    { Public declarations }
    class function CreateForm(const nPopedom: string = '';
      const nParam: Pointer = nil): TWinControl; override;
    class function FormID: integer; override;
  end;

implementation

{$R *.dfm}
uses
  ULibFun, UMgrControl, UDataModule, UFormCtrl, USysDB, USysConst;

class function TfFormTruckPlan.CreateForm(const nPopedom: string;
  const nParam: Pointer): TWinControl;
var nP: PFormCommandParam;
begin
  Result := nil;
  if Assigned(nParam) then
       nP := nParam
  else Exit;

  with TfFormTruckPlan.Create(Application) do
  try
    if nP.FCommand = cCmd_AddData then
    begin
      Caption := '车辆 - 添加';
      FPlanID := '';
    end;

    if nP.FCommand = cCmd_EditData then
    begin
      Caption := '车辆 - 修改';
      FPlanID := nP.FParamA;
    end;

    FTruckHistory := TStringList.Create;
    LoadFormData(FPlanID);
    nP.FCommand := cCmd_ModalResult;
    nP.FParamA := ShowModal;
  finally
    FTruckHistory.Free;
    Free;
  end;
end;

class function TfFormTruckPlan.FormID: integer;
begin
  Result := cFI_FormTruckPlan;
end;

procedure TfFormTruckPlan.LoadFormData(const nID: string);
var nStr: string;
begin
  if nID = '' then
  begin
    FCusID := '';
    FCusName := '';
    EditBegin.Date := Date();
    EditEnd.Date := Date() + 1;
  end;

  if nID <> '' then
  begin
    nStr := 'Select tp.*,C_Name From %s tp ' +
            ' Left Join %s On C_ID=P_CusID ' +
            'Where tp.R_ID=%s';
    nStr := Format(nStr, [sTable_TruckPlan, sTable_Customer, nID]);

    with FDM.QueryTemp(nStr) do
    begin
      BtnOK.Enabled := RecordCount > 0;
      if not BtnOK.Enabled then
      begin
        ShowMsg('派车记录已无效', sHint);
        Exit;
      end;

      FCusID := FieldByName('P_CusID').AsString;
      FCusName := FieldByName('C_Name').AsString;
      EditCus.Text := Format('%s.%s', [FCusID, FCusName]);
      EditCus.Enabled := False;

      EditBegin.Date := FieldByName('P_Start').AsDateTime;
      EditEnd.Date := FieldByName('P_End').AsDateTime;
      EditTrucks.Text := FieldByName('P_Truck').AsString;
    end;
  end;
end;

procedure TfFormTruckPlan.EditCusPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
var nP: TFormCommandParam;
begin
  nP.FParamA := FCusName;
  CreateBaseFormItem(cFI_FormGetCustom, '', @nP);
  if (nP.FCommand <> cCmd_ModalResult) or (nP.FParamA <> mrOK) then Exit;

  FCusID := nP.FParamB;
  FCusName := nP.FParamC;
  EditCus.Text := Format('%s.%s', [FCusID, FCusName]);
  ActiveControl := EditTruck;

  LoadTruckHistorData(False);
  LoadTruckHistoryList;
end;

procedure TfFormTruckPlan.LoadTruckHistorData(const nAll: Boolean);
var nStr: string;
    nTag: Integer;
begin
  FTruckHistory.Clear;
  EditTruck.Text := '';
  
  if nAll then
  begin
    nStr := 'Select distinct P_Truck,P_Visible From %s Where P_CusID=''%s'' ' +
            'Order By P_Truck ASC';
    nStr := Format(nStr, [sTable_TruckPlan, FCusID]);
  end else
  begin
    nStr := 'Select distinct P_Truck,P_Visible From %s Where P_CusID=''%s'' And ' +
            'P_Visible<>''%s'' Order By P_Truck ASC';
    nStr := Format(nStr, [sTable_TruckPlan, FCusID, sFlag_No]);
  end;

  with FDM.QueryTemp(nStr) do
  if RecordCount > 0 then
  begin
    First;
    while not Eof do
    begin
      if Fields[1].AsString = sFlag_No then
           nTag := 10
      else nTag := 20;

      nStr := UpperCase(Trim(Fields[0].AsString));
      FTruckHistory.AddObject(nStr, Pointer(nTag));
      Next;
    end;
  end;
end;

procedure TfFormTruckPlan.LoadTruckHistoryList;
var nStr,nTag: string;
    nIdx: Integer;
begin
  ListHistory.Clear;
  nStr := UpperCase(Trim(EditTruck.Text));

  for nIdx:=0 to FTruckHistory.Count-1 do
  if (nStr = '') or (Pos(nStr, FTruckHistory[nIdx]) > 0) then
  begin
    if Integer(FTruckHistory.Objects[nIdx]) = 10 then
         nTag := '(x)'
    else nTag := '';
    ListHistory.Items.AddObject(FTruckHistory[nIdx] + nTag, Pointer(nIdx));
  end;
end;

procedure TfFormTruckPlan.EditTruckKeyPress(Sender: TObject; var Key: Char);
var nIdx: Integer;
begin
  if Key = Char(VK_Return) then
  begin
    Key := #0;
    if ListHistory.Items.Count < 1 then Exit;

    nIdx := Integer(ListHistory.Items.Objects[0]);
    if EditTrucks.Lines.IndexOf(FTruckHistory[nIdx]) < 0 then
      EditTrucks.Lines.Add(FTruckHistory[nIdx]);
    EditTruck.SelectAll;
  end;
end;

procedure TfFormTruckPlan.EditTruckPropertiesChange(Sender: TObject);
begin
  LoadTruckHistoryList();
end;

procedure TfFormTruckPlan.EditTrucksDragOver(Sender, Source: TObject; X,
  Y: Integer; State: TDragState; var Accept: Boolean);
begin
  if Source = ListHistory then
    Accept := True;
  //xxxxx
end;

procedure TfFormTruckPlan.EditTrucksDragDrop(Sender, Source: TObject; X,
  Y: Integer);
var nIdx: Integer;
begin
  if ListHistory.ItemIndex < 0 then Exit;
  nIdx := Integer(ListHistory.Items.Objects[ListHistory.ItemIndex]);

  if EditTrucks.Lines.IndexOf(FTruckHistory[nIdx]) < 0 then
    EditTrucks.Lines.Add(FTruckHistory[nIdx]);
  //xxxxx
end;

//------------------------------------------------------------------------------
procedure TfFormTruckPlan.N1Click(Sender: TObject);
var nIdx,nInt: Integer;
begin
  for nIdx:=0 to ListHistory.Count-1 do
  begin
    nInt := Integer(ListHistory.Items.Objects[nIdx]);
    if EditTrucks.Lines.IndexOf(FTruckHistory[nInt]) < 0 then
      EditTrucks.Lines.Add(FTruckHistory[nInt]);
    //xxxxx
  end;
end;

procedure TfFormTruckPlan.N3Click(Sender: TObject);
begin
  case TComponent(Sender).Tag of
   10:
    begin
      N3.Checked := True;
      LoadTruckHistorData(False);
    end;
   20:
    begin
      N6.Checked := True;
      LoadTruckHistorData(True);
    end;
  end;

  LoadTruckHistoryList();
end;

procedure TfFormTruckPlan.N4Click(Sender: TObject);
var nStr,nTag: string;
    nIdx: Integer;
begin
  if ListHistory.ItemIndex < 0 then Exit;
  case TComponent(Sender).Tag of
   10: nTag := sFlag_No;
   20: nTag := sFlag_Yes;
  end;

  nIdx := Integer(ListHistory.Items.Objects[ListHistory.ItemIndex]);
  nStr := 'Update %s Set P_Visible=''%s'' Where P_CusID=''%s'' And ' +
          'P_Truck=''%s''';
  nStr := Format(nStr, [sTable_TruckPlan, nTag, FCusID, FTruckHistory[nIdx]]);
  FDM.ExecuteSQL(nStr);

  LoadTruckHistorData(N6.Checked);
  LoadTruckHistoryList();
end;

//------------------------------------------------------------------------------
function TfFormTruckPlan.OnVerifyCtrl(Sender: TObject;
  var nHint: string): Boolean;
begin
  Result := True;
  if Sender = EditCus then
  begin
    Result := FCusID <> '';
    nHint := '请选择客户';
  end else

  if Sender = EditBegin then
  begin
    Result := (FPlanID <> '') or (EditBegin.Date >= Date());
    nHint := '生效日期不能小于今天';
  end else

  if Sender = EditEnd then
  begin
    Result := (FPlanID <> '') or (EditEnd.Date > EditBegin.Date);
    nHint := '失效日期需大于生效日期';
  end else

  if Sender = EditTrucks then
  begin
    Result := EditTrucks.Lines.Count > 0;
    nHint := '请输入车牌号';
  end;
end;

//Desc: 保存
procedure TfFormTruckPlan.BtnOKClick(Sender: TObject);
var nStr,nValid: string;
    nIdx: Integer;
begin
  if not IsDataValid then Exit;
  nValid := sFlag_Unknow;
  if (EditBegin.Date >= EditEnd.Date) or (EditEnd.Date <= Date()) then
    nValid := sFlag_No;
  //无效态

  if (EditBegin.Date = Date()) and (EditBegin.Date < EditEnd.Date) then
    nValid := sFlag_Yes;
  //有效态

  for nIdx:=0 to EditTrucks.Lines.Count-1 do
  begin
    nStr := Trim(EditTrucks.Lines[nIdx]);
    if nStr = '' then Continue;
    nStr := UpperCase(nStr);

    nStr := MakeSQLByStr([SF('P_Truck', nStr),
            SF('P_Start', Date2Str(EditBegin.Date)),
            SF('P_End', Date2Str(EditEnd.Date)),
            SF('P_Valid', nValid),
            SF('P_Times', '1', sfVal),

            SF_IF([SF('P_CusID', FCusID), ''], FPlanID=''),
            SF_IF([SF('P_Man', gSysParam.FUserID), ''], FPlanID=''),
            SF_IF([SF('P_Date', sField_SQLServer_Now, sfVal), ''], FPlanID='')
            ], sTable_TruckPlan, SF('R_ID', FPlanID), FPlanID='');
    FDM.ExecuteSQL(nStr);
  end;

  ModalResult := mrOk;
  ShowMsg('派车成功', sHint);
end;

initialization
  gControlManager.RegCtrl(TfFormTruckPlan, TfFormTruckPlan.FormID);
end.
