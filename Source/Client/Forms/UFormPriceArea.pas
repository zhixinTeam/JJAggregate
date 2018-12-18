{*******************************************************************************
  作者: dmzn@163.com 2018-12-09
  描述: 区域价
*******************************************************************************}
unit UFormPriceArea;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, UFormNormal, dxLayoutControl, StdCtrls, cxControls, cxMemo,
  cxButtonEdit, cxLabel, cxTextEdit, cxContainer, cxEdit, cxMaskEdit,
  cxDropDownEdit, cxCalendar, cxGraphics, cxLookAndFeels,
  cxLookAndFeelPainters, cxCheckBox, ComCtrls, cxListView, Menus,
  cxButtons, cxGroupBox;

type
  TfFormPriceArea = class(TfFormNormal)
    dxLayout1Item4: TdxLayoutItem;
    EditBegin: TcxTextEdit;
    cxLabel1: TcxLabel;
    dxLayout1Item8: TdxLayoutItem;
    EditWeek: TcxComboBox;
    dxLayout1Item6: TdxLayoutItem;
    EditEnd: TcxTextEdit;
    dxLayout1Item3: TdxLayoutItem;
    dxLayout1Group2: TdxLayoutGroup;
    cxLabel2: TcxLabel;
    dxLayout1Item5: TdxLayoutItem;
    List1: TcxListView;
    dxLayout1Item7: TdxLayoutItem;
    PanelPrice: TcxGroupBox;
    BtnYes: TcxButton;
    BtnNo: TcxButton;
    EditStock: TcxTextEdit;
    cxLabel3: TcxLabel;
    cxLabel4: TcxLabel;
    EditArea: TcxButtonEdit;
    dxLayout1Item9: TdxLayoutItem;
    EditPrice: TcxButtonEdit;
    Check1: TcxCheckBox;
    dxLayout1Item10: TdxLayoutItem;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure BtnOKClick(Sender: TObject);
    procedure List1DblClick(Sender: TObject);
    procedure BtnNoClick(Sender: TObject);
    procedure BtnYesClick(Sender: TObject);
    procedure EditWeekPropertiesChange(Sender: TObject);
    procedure List1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure EditAreaPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure EditPricePropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
  private
    { Private declarations }
    FActiveWeek: Integer;
    FDefaultWeek,FDefaultArea: string;
    //xxxx
    FModalResult: TModalResult;
    procedure InitFormData(const nID: string);
    //载入数据
    procedure ShowPriceEditor(const nShow: Boolean);
    //编辑价格
    procedure LoadStockList;
    //物料列表
  public
    { Public declarations }
    class function CreateForm(const nPopedom: string = '';
      const nParam: Pointer = nil): TWinControl; override;
    class function FormID: integer; override;
  end;

implementation

{$R *.dfm}
uses
  ULibFun, UBusinessConst, UFormBase, UMgrControl, UDataModule, UFormCtrl,
  UFormBaseInfo, USysDB, USysConst, USysGrid, USysBusiness;

type
  TPriceWeek = record
    FID : string;
    FName: string;
    FBegin: TDateTime;
    FEnd: TDateTime;
    FChanged: Boolean;
  end;

var
  gStockTypes: TStockTypeItems;
  gPriceWeeks: array of TPriceWeek;

class function TfFormPriceArea.CreateForm(const nPopedom: string;
  const nParam: Pointer): TWinControl;
var nP: PFormCommandParam;
begin
  Result := nil;
  if Assigned(nParam) then
       nP := nParam
  else nP := nil;

  with TfFormPriceArea.Create(Application) do
  begin
    if Assigned(nP) then
    begin
      FDefaultWeek := nP.FParamA;
      FDefaultArea := nP.FParamB;
    end else
    begin
      FDefaultWeek := '';
      FDefaultArea := '';
    end;

    Caption := '区域价 - 管理';
    FModalResult := mrNone;

    InitFormData('');
    ShowModal;

    if Assigned(nP) then
    begin
      nP.FCommand := cCmd_ModalResult;
      nP.FParamA := FModalResult;
    end;
    Free;
  end;
end;

class function TfFormPriceArea.FormID: integer;
begin
  Result := cFI_FormPriceArea;
end;

procedure TfFormPriceArea.FormCreate(Sender: TObject);
begin
  PanelPrice.Visible := False;
  LoadFormConfig(Self);
  LoadcxListViewConfig(Name, List1);
end;

procedure TfFormPriceArea.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  SavecxListViewConfig(Name, List1);
  SaveFormConfig(Self);
  Action := caFree;
end;

//------------------------------------------------------------------------------
procedure TfFormPriceArea.InitFormData(const nID: string);
var nStr: string;
    nIdx,nInt: Integer;
begin
  List1.Clear;
  EditWeek.Properties.Items.Clear;
  FActiveWeek := -1;

  EditArea.Text := FDefaultArea;
  nInt := 0;
  SetLength(gPriceWeeks, 0);

  nStr := 'Select W_NO,W_Name,W_Begin,W_End From %s ' +
          'Where W_Valid=''%s'' Or W_Begin>=%s Order By W_NO ASC';
  nStr := Format(nStr, [sTable_PriceWeek, sFlag_Yes, sField_SQLServer_Now]);
  //生效或即将生效

  with FDM.QueryTemp(nStr) do
  if RecordCount > 0 then
  begin
    SetLength(gPriceWeeks, RecordCount);
    nIdx := 0;
    First;

    while not Eof do
    begin
      with gPriceWeeks[nIdx] do
      begin
        FID    := FieldByName('W_NO').AsString;
        FName  := FieldByName('W_Name').AsString;
        FBegin := FieldByName('W_Begin').AsDateTime;
        FEnd   := FieldByName('W_End').AsDateTime;
      end;

      Inc(nIdx);
      Next;
    end;
  end;

  for nIdx:=Low(gPriceWeeks) to High(gPriceWeeks) do
  with EditWeek.Properties,gPriceWeeks[nIdx] do
  begin
    Items.AddObject(Format('%s.%s', [FID, FName]), Pointer(nIdx));
    if FID = FDefaultWeek then
      nInt := Items.Count - 1;
    //xxxxx
  end;

  if EditWeek.Properties.Items.Count > 0 then
    EditWeek.ItemIndex := nInt;
  //default
end;

procedure TfFormPriceArea.EditAreaPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
var nBool: Boolean;
begin
  nBool := True;
  EditArea.Text := Trim(ShowBaseInfoEditForm(nBool, nBool, '区域', 'MAIN_B01',
                   sFlag_AreaItem).FText);
  //xxxxx

  if EditArea.Text <> '' then
    EditWeekPropertiesChange(nil);
  //xxxxx
end;

procedure TfFormPriceArea.EditWeekPropertiesChange(Sender: TObject);
var nStr: string;
    nIdx: Integer;
begin
  if EditWeek.ItemIndex < 0 then
  begin
    if EditWeek.ItemIndex < 0 then
    begin
      EditBegin.Clear;
      EditEnd.Clear;
    end;

    FActiveWeek := -1;
    Exit;
  end;

  List1.Items.Clear;
  FActiveWeek := Integer(EditWeek.Properties.Items.Objects[EditWeek.ItemIndex]);
  
  with gPriceWeeks[FActiveWeek] do
  begin
    EditBegin.Text := DateTime2Str(FBegin);
    EditEnd.Text := DateTime2Str(FEnd);

    FChanged := False;
    if EditArea.Text = '' then Exit;
    GetLadingStockItems(gStockTypes);
                      
    nStr := 'Select R_StockNo,R_Price From %s ' +
            'Where R_Type=''%s'' And R_Week=''%s'' And R_Area=''%s''';
    nStr := Format(nStr, [sTable_PriceRule, sFlag_PriceQY, FID, EditArea.Text]);
  end;

  with FDM.QueryTemp(nStr) do
  if RecordCount > 0 then
  begin
    First;
    while not Eof do
    begin
      nStr := FieldByName('R_StockNo').AsString;
      for nIdx:=Low(gStockTypes) to High(gStockTypes) do
      with gStockTypes[nIdx] do
      begin
        if CompareText(FID, nStr) = 0 then
          FPrice := FieldByName('R_Price').AsFloat;
        //xxxxx
      end;
      
      Next;
    end;
  end;
  LoadStockList;
end;

procedure TfFormPriceArea.LoadStockList;
var nStr: string;
    nIdx: Integer;
begin
  List1.Items.BeginUpdate;
  try
    if Assigned(List1.Selected) then
         nStr := List1.Selected.Caption
    else nStr := '';
    List1.Items.Clear;

    for nIdx:=Low(gStockTypes) to High(gStockTypes) do
    with List1.Items.Add,gStockTypes[nIdx] do
    begin
      Data := Pointer(nIdx);
      Caption := FID;
      SubItems.Add(FName);
      SubItems.Add(Format('%.2f', [FPrice]));

      if FID = nStr then
        Selected := True;
      //xxxxx
    end;
  finally
    List1.Items.EndUpdate;
  end;
end;

procedure TfFormPriceArea.ShowPriceEditor(const nShow: Boolean);
begin
  dxLayout1.Enabled := not nShow;
  PanelPrice.Visible := nShow;

  if nShow then
  begin
    dxLayout1.Enabled := False;
    PanelPrice.Visible := True;

    EditPrice.SetFocus;
    EditPrice.SelectAll;
  end else
  begin
    dxLayout1.Enabled := True;
    PanelPrice.Visible := False;
    List1.SetFocus;
  end;
end;

procedure TfFormPriceArea.List1DblClick(Sender: TObject);
begin
  if Assigned(List1.Selected) then
  begin
    with gStockTypes[Integer(List1.Selected.Data)] do
    begin
      EditStock.Text := FName;
      EditPrice.Text := Format('%.2f', [FPrice]);
    end;

    ShowPriceEditor(True);
  end;
end;

procedure TfFormPriceArea.BtnNoClick(Sender: TObject);
begin
  ShowPriceEditor(False);
end;

procedure TfFormPriceArea.BtnYesClick(Sender: TObject);
var nIdx: Integer;
    nVal: Double;
begin
  if IsNumber(EditPrice.Text, True) then
  begin
    nVal := StrToFloat(EditPrice.Text);
    nVal := Float2Float(nVal, cPrecision);

    if nVal < 0 then
    begin
      ShowMsg('价格不能为负值', sHint);
      Exit;
    end;

    ShowPriceEditor(False);
    nIdx := Integer(List1.Selected.Data);
    if gStockTypes[nIdx].FPrice = nVal then Exit;
    
    gStockTypes[nIdx].FPrice := nVal;
    List1.Selected.SubItems[1] := Format('%.2f', [nVal]);
    gPriceWeeks[FActiveWeek].FChanged := True;
  end;
end;

procedure TfFormPriceArea.List1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Key := 0;
    List1DblClick(nil);
  end;
end;

procedure TfFormPriceArea.EditPricePropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
var nIdx: Integer;
begin
  EditPrice.Text := '0';
  EditPrice.SelectAll;

  if AButtonIndex = 0 then
  begin
    for nIdx:=Low(gStockTypes) to High(gStockTypes) do
      gStockTypes[nIdx].FPrice := 0;
    //xxxxx
    
    LoadStockList;
    gPriceWeeks[FActiveWeek].FChanged := True;
  end;
end;

//Desc: 保存
procedure TfFormPriceArea.BtnOKClick(Sender: TObject);
var nStr: string;
    nIdx: Integer;
begin
  if FActiveWeek < 0 then
  begin
    ShowMsg('价格周期无效', sHint);
    Exit;
  end;

  if not gPriceWeeks[FActiveWeek].FChanged then
  begin
    if not Check1.Checked then
      ModalResult := mrOk;
    Exit;
  end;

  if EditArea.Text = '' then
  begin
    ShowMsg('区域名称无效', sHint);
    Exit;
  end;

  FDM.ADOConn.BeginTrans;
  try
    nStr := 'Delete From %s Where R_Week=''%s'' And R_Type=''%s'' And ' +
            'R_Area=''%s''';
    nStr := Format(nStr, [sTable_PriceRule, gPriceWeeks[FActiveWeek].FID,
            sFlag_PriceQY, EditArea.Text]);
    FDM.ExecuteSQL(nStr); //clear first

    for nIdx:=Low(gStockTypes) to High(gStockTypes) do
    with gStockTypes[nIdx] do
    begin
      if FPrice <= 0 then Continue;
      //invalid price

      nStr := MakeSQLByStr([SF('R_Week', gPriceWeeks[FActiveWeek].FID),
              SF('R_Type', sFlag_PriceQY),
              SF('R_Area', EditArea.Text),
              SF('R_StockNo', FID),
              SF('R_StockName', FName),
              SF('R_Price', FPrice, sfVal),
              SF('R_Man', gSysParam.FUserID),
              SF('R_Date', sField_SQLServer_Now, sfVal)
              ], sTable_PriceRule, '', True);
      FDM.ExecuteSQL(nStr);
    end;

    FDM.ADOConn.CommitTrans;
    FModalResult := mrOk;
    
    if Check1.Checked then
         ShowMsg('保存成功', sHint)
    else ModalResult := mrOk;
  except
    on nErr: Exception do
    begin
      FDM.ADOConn.RollbackTrans;
      ShowDlg(nErr.Message, sError);
    end;
  end;  
end;

initialization
  gControlManager.RegCtrl(TfFormPriceArea, TfFormPriceArea.FormID);
end.
