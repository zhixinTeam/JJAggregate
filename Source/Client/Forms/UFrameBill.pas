{*******************************************************************************
  ����: dmzn@163.com 2009-6-22
  ����: �������
*******************************************************************************}
unit UFrameBill;

{$I Link.Inc}
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, UFrameNormal, cxStyles, cxCustomData, cxGraphics, cxFilter,
  cxData, cxDataStorage, cxEdit, DB, cxDBData, ADODB, cxContainer, cxLabel,
  dxLayoutControl, cxGridLevel, cxClasses, cxControls, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGrid,
  ComCtrls, ToolWin, cxTextEdit, cxMaskEdit, cxButtonEdit, Menus,
  UBitmapPanel, cxSplitter, cxLookAndFeels, cxLookAndFeelPainters,
  cxCheckBox, dxSkinsCore, dxSkinsDefaultPainters, dxSkinscxPCPainter,
  dxSkinsdxLCPainter, cxGridCustomPopupMenu, cxGridPopupMenu;

type
  TfFrameBill = class(TfFrameNormal)
    EditCus: TcxButtonEdit;
    dxLayout1Item1: TdxLayoutItem;
    EditCard: TcxButtonEdit;
    dxLayout1Item2: TdxLayoutItem;
    cxTextEdit1: TcxTextEdit;
    dxLayout1Item3: TdxLayoutItem;
    cxTextEdit2: TcxTextEdit;
    dxLayout1Item4: TdxLayoutItem;
    cxTextEdit4: TcxTextEdit;
    dxLayout1Item6: TdxLayoutItem;
    cxTextEdit3: TcxTextEdit;
    dxLayout1Item5: TdxLayoutItem;
    EditDate: TcxButtonEdit;
    dxLayout1Item7: TdxLayoutItem;
    PMenu1: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N4: TMenuItem;
    EditLID: TcxButtonEdit;
    dxLayout1Item8: TdxLayoutItem;
    N5: TMenuItem;
    Edit1: TcxTextEdit;
    dxLayout1Item9: TdxLayoutItem;
    N8: TMenuItem;
    N9: TMenuItem;
    dxLayout1Item10: TdxLayoutItem;
    CheckDelete: TcxCheckBox;
    N3: TMenuItem;
    N10: TMenuItem;
    N12: TMenuItem;
    N6: TMenuItem;
    N7: TMenuItem;
    N11: TMenuItem;
    N13: TMenuItem;
    N14: TMenuItem;
    procedure EditIDPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure BtnDelClick(Sender: TObject);
    procedure BtnAddClick(Sender: TObject);
    procedure EditDatePropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure N1Click(Sender: TObject);
    procedure N4Click(Sender: TObject);
    procedure N5Click(Sender: TObject);
    procedure CheckDeleteClick(Sender: TObject);
    procedure cxView1DblClick(Sender: TObject);
    procedure N3Click(Sender: TObject);
    procedure PMenu1Popup(Sender: TObject);
    procedure N10Click(Sender: TObject);
    procedure N12Click(Sender: TObject);
    procedure N6Click(Sender: TObject);
    procedure N7Click(Sender: TObject);
    procedure N14Click(Sender: TObject);
    procedure cxView1CustomDrawCell(Sender: TcxCustomGridTableView;
      ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
      var ADone: Boolean);
  protected
    FStart,FEnd: TDate;
    //ʱ������
    FUseDate: Boolean;
    //ʹ������
  private
    function IsHasPopedom(nMainID, nPopedom: string;var nHas:Boolean):Boolean;
    procedure OnCreateFrame; override;
    procedure OnDestroyFrame; override;
    function FilterColumnField: string; override;
    function InitFormDataSQL(const nWhere: string): string; override;
    procedure AfterInitFormData; override;
    {*��ѯSQL*}
  public
    { Public declarations }
    class function FrameID: integer; override;
  end;

implementation

{$R *.dfm}
uses
  ULibFun, UMgrControl, UDataModule, UFormBase, UFormInputbox, USysPopedom,
  USysConst, USysDB, USysBusiness, UFormDateFilter,ShellAPI,UFormWait;

//------------------------------------------------------------------------------
class function TfFrameBill.FrameID: integer;
begin
  Result := cFI_FrameBill;
end;

procedure TfFrameBill.OnCreateFrame;
begin
  inherited;
  FUseDate := True;
  InitDateRange(Name, FStart, FEnd);
  cxView1.OptionsSelection.MultiSelect := True;
end;

procedure TfFrameBill.OnDestroyFrame;
begin
  SaveDateRange(Name, FStart, FEnd);
  inherited;
end;

//Desc: ���ݲ�ѯSQL
function TfFrameBill.InitFormDataSQL(const nWhere: string): string;
var nStr: string;
begin
  FEnableBackDB := True;

  EditDate.Text := Format('%s �� %s', [Date2Str(FStart), Date2Str(FEnd)]);

  Result := 'Select * From $Bill ';
  //�����
  {$IFDEF AdminUseFL}
  if gSysParam.FIsAdmin then
  begin
    if (nWhere = '') or FUseDate then
    begin
      Result := Result + 'Where (L_Date>=''$ST'' and L_Date <''$End'')';
      nStr := ' And ';
    end else nStr := ' Where ';

    if nWhere <> '' then
      Result := Result + nStr + '(' + nWhere + ')';
    //xxxxx
  end
  else
  begin
    if (nWhere = '') or FUseDate then
    begin
      Result := Result + 'Where (L_Date>=''$ST'' and L_Date <''$End'') and (L_CusID in(select distinct C_ID from S_Customer where isnull(C_FL,'''') <> ''Y'' ))';
      nStr := ' And ';
    end else nStr := ' Where ';

    if nWhere <> '' then
      Result := Result + nStr + '(' + nWhere + ') and (L_CusID in(select distinct C_ID from S_Customer where isnull(C_FL,'''') <> ''Y'' )) ';
    //xxxxx
  end;
  {$ELSE}
    if (nWhere = '') or FUseDate then
    begin
      Result := Result + 'Where (L_Date>=''$ST'' and L_Date <''$End'')';
      nStr := ' And ';
    end else nStr := ' Where ';

    if nWhere <> '' then
      Result := Result + nStr + '(' + nWhere + ')';  
  {$ENDIF}

  Result := MacroValue(Result, [
            MI('$ST', Date2Str(FStart)), MI('$End', Date2Str(FEnd + 1))]);
  //xxxxx

  if CheckDelete.Checked then
       Result := MacroValue(Result, [MI('$Bill', sTable_BillBak)])
  else Result := MacroValue(Result, [MI('$Bill', sTable_Bill)]);

  Result:= Result + ' Order By R_ID Desc ';
end;

procedure TfFrameBill.AfterInitFormData;
begin
  FUseDate := True;
end;

function TfFrameBill.FilterColumnField: string;
begin
  if gPopedomManager.HasPopedom(PopedomItem, sPopedom_ViewPrice) then
       Result := ''
  else Result := 'L_Price';
end;

//Desc: ִ�в�ѯ
procedure TfFrameBill.EditIDPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  if Sender = EditLID then
  begin
    EditLID.Text := Trim(EditLID.Text);
    if EditLID.Text = '' then Exit;

    FUseDate := Length(EditLID.Text) <= 3;
    FWhere := 'L_ID like ''%' + EditLID.Text + '%''';
    InitFormData(FWhere);
  end else

  if Sender = EditCus then
  begin
    EditCus.Text := Trim(EditCus.Text);
    if EditCus.Text = '' then Exit;

    FWhere := 'L_CusPY like ''%%%s%%'' Or L_CusName like ''%%%s%%''';
    FWhere := Format(FWhere, [EditCus.Text, EditCus.Text]);
    InitFormData(FWhere);
  end else

  if Sender = EditCard then
  begin
    EditCard.Text := Trim(EditCard.Text);
    if EditCard.Text = '' then Exit;

    FUseDate := Length(EditCard.Text) <= 3;
    FWhere := Format('L_Truck like ''%%%s%%''', [EditCard.Text]);
    InitFormData(FWhere);
  end;
end;

//Desc: δ��ʼ����������
procedure TfFrameBill.N4Click(Sender: TObject);
begin
  case TComponent(Sender).Tag of
   10: FWhere := Format('(L_Status=''%s'')', [sFlag_BillNew]);
   20: FWhere := 'L_OutFact Is Null'
   else Exit;
  end;

  FUseDate := False;
  InitFormData(FWhere);
end;

//Desc: ����ɸѡ
procedure TfFrameBill.EditDatePropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  if ShowDateFilterForm(FStart, FEnd) then InitFormData('');
end;

//Desc: ��ѯɾ��
procedure TfFrameBill.CheckDeleteClick(Sender: TObject);
begin
  InitFormData('');
end;

//------------------------------------------------------------------------------
//Desc: �������
procedure TfFrameBill.BtnAddClick(Sender: TObject);
var nP: TFormCommandParam;
begin
  CreateBaseFormItem(cFI_FormBill, PopedomItem, @nP);
  if (nP.FCommand = cCmd_ModalResult) and (nP.FParamA = mrOK) then
  begin
    InitFormData('');
  end;
end;

//Desc: ɾ��
procedure TfFrameBill.BtnDelClick(Sender: TObject);
var nStr: string;
    nP: TFormCommandParam;
begin
  if cxView1.DataController.GetSelectedCount < 1 then
  begin
    ShowMsg('��ѡ��Ҫɾ���ļ�¼', sHint); Exit;
  end;
  
  nStr := 'ȷ��Ҫɾ�����Ϊ[ %s ]�ĵ�����?';
  nStr := Format(nStr, [SQLQuery.FieldByName('L_ID').AsString]);
  if not QueryDlg(nStr, sAsk) then Exit;

  with nP do
  begin
    nStr := SQLQuery.FieldByName('L_ID').AsString;
    nStr := Format('����дɾ��[ %s ]���ݵ�ԭ��', [nStr]);

    FCommand := cCmd_EditData;
    FParamA := nStr;
    FParamB := 320;
    FParamD := 10;

    nStr := SQLQuery.FieldByName('R_ID').AsString;
    FParamC := 'Update %s Set L_Memo=''$Memo'' Where R_ID=%s';
    FParamC := Format(FParamC, [sTable_Bill, nStr]);

    CreateBaseFormItem(cFI_FormMemo, '', @nP);
    if (FCommand <> cCmd_ModalResult) or (FParamA <> mrOK) then Exit;
  end;

  if DeleteBill(SQLQuery.FieldByName('L_ID').AsString) then
  begin
    InitFormData(FWhere);
    ShowMsg('�������ɾ��', sHint);
  end;
end;

//
function TfFrameBill.IsHasPopedom(nMainID, nPopedom: string;var nHas:Boolean):Boolean;
var nStr:string;
begin
  nHas:= false;
  
  nStr := 'Select * From %s Left Join Sys_Popedom ON U_Group=P_GROUP ' +
          'Where U_Name=''%s'' And P_ITEM=''%s'' And P_POPEDOM like ''%%'+nPopedom+'%%''  ';
  nStr := Format(nStr, [sTable_User, gSysParam.FUserID,nMainID]);

  with FDM.QueryTemp(nStr)  do
  begin
    // ��ѯ�Ƿ���Ȩ��
    nHas:= (RecordCount > 0);
  end;
end;

procedure TfFrameBill.PMenu1Popup(Sender: TObject);
var nHasKW:Boolean;
begin
  N3.Enabled := (cxView1.DataController.GetSelectedCount > 0) and
                (gPopedomManager.HasPopedom(sPopedom_ViewPrice, PopedomItem));
  //xxxxx
  IsHasPopedom('MAIN_D06', 'C', nHasKW);
  N12.Enabled := gSysParam.FIsAdmin or (nHasKW);
  N6.Enabled  := gSysParam.FIsAdmin;
  N7.Enabled  := gSysParam.FIsAdmin;
end;

//Desc: ��ӡ�����
procedure TfFrameBill.N1Click(Sender: TObject);
var nStr: string;
begin
  if cxView1.DataController.GetSelectedCount > 0 then
  begin
    nStr := SQLQuery.FieldByName('L_ID').AsString;
    PrintBillReport(nStr, False);
  end;
end;

//Desc: �޸�δ�������ƺ�
procedure TfFrameBill.N5Click(Sender: TObject);
var nStr,nTruck: string;
begin
  if cxView1.DataController.GetSelectedCount > 0 then
  begin
    nStr := SQLQuery.FieldByName('L_Truck').AsString;
    nTruck := nStr;
    if not ShowInputBox('�������µĳ��ƺ���:', '�޸�', nTruck, 15) then Exit;

    if (nTruck = '') or (nStr = nTruck) then Exit;
    //��Ч��һ��

    nStr := SQLQuery.FieldByName('L_ID').AsString;
    if ChangeLadingTruckNo(nStr, nTruck) then
    begin
      nStr := '�޸ĳ��ƺ�[ %s -> %s ].';
      nStr := Format(nStr, [SQLQuery.FieldByName('L_Truck').AsString, nTruck]);
      FDM.WriteSysLog(sFlag_BillItem, SQLQuery.FieldByName('L_ID').AsString, nStr, False);

      InitFormData(FWhere);
      ShowMsg('���ƺ��޸ĳɹ�', sHint);
    end;
  end;
end;

//Desc: �鿴�۸�����
procedure TfFrameBill.N3Click(Sender: TObject);
var nP: TFormCommandParam;
begin
  nP.FCommand := cCmd_ViewData;
  nP.FParamA := SQLQuery.FieldByName('L_PriceDesc').AsString;
  CreateBaseFormItem(cFI_FormMemo, '', @nP);
end;

procedure TfFrameBill.cxView1DblClick(Sender: TObject);
var nStr: string;
    nP: TFormCommandParam;
begin
  if (not CheckDelete.Checked) or
     (cxView1.DataController.GetSelectedCount < 1) then Exit;
  //ֻ�޸�ɾ����¼�ı�ע��Ϣ

  with nP do
  begin
    FCommand := cCmd_EditData;
    FParamA := SQLQuery.FieldByName('L_Memo').AsString;
    FParamB := 320;
    FParamD := 10;

    nStr := SQLQuery.FieldByName('R_ID').AsString;
    FParamC := 'Update %s Set L_Memo=''$Memo'' Where R_ID=%s';
    FParamC := Format(nP.FParamC, [sTable_BillBak, nStr]);

    CreateBaseFormItem(cFI_FormMemo, '', @nP);
    if (nP.FCommand = cCmd_ModalResult) and (nP.FParamA = mrOK) then
      InitFormData(FWhere);
    //display
  end;
end;

procedure TfFrameBill.N10Click(Sender: TObject);
var nStr,nID,nDir: string;
    nPic: TPicture;
begin
  if cxView1.DataController.GetSelectedCount < 1 then
  begin
    ShowMsg('��ѡ��Ҫ�鿴�ļ�¼', sHint);
    Exit;
  end;

  nID := SQLQuery.FieldByName('L_ID').AsString;
  nDir := gSysParam.FPicPath + nID + '\';

  if DirectoryExists(nDir) then
  begin
    ShellExecute(GetDesktopWindow, 'open', PChar(nDir), nil, nil, SW_SHOWNORMAL);
    Exit;
  end else ForceDirectories(nDir);

  nPic := nil;
  nStr := 'Select * From %s Where P_ID=''%s''';
  nStr := Format(nStr, [sTable_Picture, nID]);

  ShowWaitForm(ParentForm, '��ȡͼƬ', True);
  try
    with FDM.QueryTemp(nStr) do
    begin
      if RecordCount < 1 then
      begin
        ShowMsg('���γ�����ץ��', sHint);
        Exit;
      end;

      nPic := TPicture.Create;
      First;

      While not eof do
      begin
        nStr := nDir + Format('%s_%s.jpg', [FieldByName('P_ID').AsString,
                FieldByName('R_ID').AsString]);
        //xxxxx

        FDM.LoadDBImage(FDM.SqlTemp, 'P_Picture', nPic);
        nPic.SaveToFile(nStr);
        Next;
      end;
    end;

    ShellExecute(GetDesktopWindow, 'open', PChar(nDir), nil, nil, SW_SHOWNORMAL);
    //open dir
  finally
    nPic.Free;
    CloseWaitForm;
    FDM.SqlTemp.Close;
  end;
end;

procedure TfFrameBill.N12Click(Sender: TObject);
var
  nID   : string;
  nList : TStrings;
  nP: TFormCommandParam;
begin
  inherited;
  if cxView1.DataController.GetSelectedCount < 1 then
  begin
    ShowMsg('��ѡ��Ҫ����ļ�¼', sHint);
    Exit;
  end;
  if (Trim(SQLQuery.FieldByName('L_OutFact').AsString) = '') then
  begin
    ShowMsg('�����δ����,��������', sHint);
    Exit;
  end;
  
  nID := SQLQuery.FieldByName('L_ID').AsString;

  nList := TStringList.Create;
  try
    nList.Add(nID);

    nP.FCommand := cCmd_EditData;
    nP.FParamA := nList.Text;
    CreateBaseFormItem(cFI_FormBillKW, '', @nP);

    if (nP.FCommand = cCmd_ModalResult) and (nP.FParamA = mrOK) then
    begin
      InitFormData(FWhere);
    end;

  finally
    nList.Free;
  end;
end;

procedure TfFrameBill.N6Click(Sender: TObject);
var
  i : Integer;
  nValue: Double;
  nStr,nLID:   string;
begin
  inherited;
  if cxView1.DataController.GetSelectedCount < 1 then
  begin
    ShowMsg('��ѡ��Ҫ���ļ�¼', sHint);
    Exit;
  end;
  if not QueryDlg('ȷ��Ҫ��ѡ�е����м�¼���г���', sAsk) then Exit;
  with cxView1.Controller do
  begin
    for i:=0 to SelectedRowCount-1   do
    begin
      SelectedRows[i].Focused:=True;
      if (Trim(SQLQuery.FieldByName('L_OutFact').AsString) = '') then
      begin
        if SelectedRowCount = 1 then
        begin
          ShowMsg('�����δ����,��������', sHint);
          Exit;
        end
        else
          Continue;
      end;
      if Pos('���',SQLQuery.FieldByName('L_Memo').AsString) > 0 then
      begin
        if SelectedRowCount = 1 then
        begin
          ShowMsg('������ѳ��', sHint);
          Exit;
        end
        else
          Continue;
      end;
      nLID := SQLQuery.FieldByName('L_ID').AsString;
      if SQLQuery.FieldByName('L_Value').AsFloat > 0 then
      begin
        nValue := 0 - SQLQuery.FieldByName('L_Value').AsFloat;

        nStr := ' insert Into %s(L_ID,L_ZhiKa,L_CusID,L_CusName,L_CusPY,L_SaleID,L_SaleMan,L_StockNo,L_StockName,L_Value,L_Price,L_ZKMoney, '
          +' L_Truck,L_Status,L_NextStatus,L_InTime,L_InMan,L_PValue,L_PDate,L_PMan,L_MValue,L_MDate,L_MMan,L_LadeTime, '
          +' L_LadeMan,L_OutFact,L_OutMan,L_Man,L_Date,L_Memo,L_KDValue,L_YFPrice,L_Carrier) values '
          +' (''%s'',''%s'',''%s'',''%s'',''%s'',''%s'',''%s'',''%s'',''%s'',%f,%f,''%s'',''%s'',''%s'',''%s'',%s, '
          +'  ''%s'',%f,%s,''%s'',%f,%s,''%s'',%s,''%s'',%s,''%s'',''%s'',%s,''%s'',%f,%f,''%s'')';

        nStr := Format(nStr, [sTable_Bill, 'CH'+nLID, SQLQuery.FieldByName('L_ZhiKa').AsString,
                SQLQuery.FieldByName('L_CusID').AsString,SQLQuery.FieldByName('L_CusName').AsString,SQLQuery.FieldByName('L_CusPY').AsString,
                SQLQuery.FieldByName('L_SaleID').AsString,SQLQuery.FieldByName('L_SaleMan').AsString,SQLQuery.FieldByName('L_StockNo').AsString,
                SQLQuery.FieldByName('L_StockName').AsString,nValue,SQLQuery.FieldByName('L_Price').AsFloat,
                SQLQuery.FieldByName('L_ZKMoney').AsString,SQLQuery.FieldByName('L_Truck').AsString,SQLQuery.FieldByName('L_Status').AsString,
                SQLQuery.FieldByName('L_NextStatus').AsString,FDM.SQLServerNow,SQLQuery.FieldByName('L_InMan').AsString,
                SQLQuery.FieldByName('L_PValue').AsFloat,FDM.SQLServerNow,SQLQuery.FieldByName('L_PMan').AsString,
                SQLQuery.FieldByName('L_MValue').AsFloat,FDM.SQLServerNow,SQLQuery.FieldByName('L_MMan').AsString,
                FDM.SQLServerNow,SQLQuery.FieldByName('L_LadeMan').AsString,FDM.SQLServerNow,
                SQLQuery.FieldByName('L_OutMan').AsString,SQLQuery.FieldByName('L_Man').AsString,FDM.SQLServerNow,
                '����¼', SQLQuery.FieldByName('L_KDValue').AsFloat,SQLQuery.FieldByName('L_YFPrice').AsFloat,
                SQLQuery.FieldByName('L_Carrier').AsString]);
        FDM.ExecuteSQL(nStr);

        nStr := ' update %s set L_Memo=''%s'' where L_ID = ''%s'' ';
        nStr := Format(nStr, [sTable_Bill, '�ѳ��', nLID]);

        FDM.ExecuteSQL(nStr);
      end;
    end;
    if cxView1.DataController.GetSelectedCount > 0 then
    begin
        //����У���ʽ�
        CheckAllCusMoney;
        InitFormData(FWhere);
        ShowMsg('��������ɹ���', sHint);
    end;
  end;
end;

procedure TfFrameBill.N7Click(Sender: TObject);
var
  nID   : string;
  nList : TStrings;
  nP: TFormCommandParam;
begin
  inherited;
  if cxView1.DataController.GetSelectedCount < 1 then
  begin
    ShowMsg('��ѡ��Ҫ����/�����ļ�¼', sHint);
    Exit;
  end;
  if (Trim(SQLQuery.FieldByName('L_OutFact').AsString) = '') then
  begin
    ShowMsg('�����δ����,���������/����', sHint);
    Exit;
  end;
  
  nID := SQLQuery.FieldByName('L_ID').AsString;

  nList := TStringList.Create;
  try
    nList.Add(nID);

    nP.FCommand := cCmd_EditData;
    nP.FParamA := nList.Text;
    CreateBaseFormItem(cFI_FormBillAdjustNum, '', @nP);

    if (nP.FCommand = cCmd_ModalResult) and (nP.FParamA = mrOK) then
    begin
      InitFormData(FWhere);
    end;
  finally
    nList.Free;
  end;
end;

procedure TfFrameBill.N14Click(Sender: TObject);
var nParam: TFormCommandParam;
    nStr,nLID,nZhiKa,nCusID,nCusName,nMID,nMName,nTruck,nValue:string;
begin
  if cxView1.DataController.GetSelectedCount > 0 then
  begin
    nLID := SQLQuery.FieldByName('L_ID').AsString;

    nStr := 'Select * From %s Where L_RetBillNo=''%s''';
    nStr := Format(nStr, [sTable_Bill, nLID ]);
    with FDM.QueryTemp(nStr) do
    begin
      if RecordCount>0 then
      begin
        nStr := '����� %s ���˻�����ֹ�ٴ��˻�.';
        ShowMsg(Format(nStr, [ nLID ]), '��ʾ');
        Exit;
      end;
    end;

    if (SQLQuery.FieldByName('L_EmptyOut').AsString=sFlag_Yes) then
    begin
      ShowMsg('����� ' + nLID + ' Ϊ�ճ����������������˻�', '��ʾ');
      Exit;
    end;

    if (SQLQuery.FieldByName('L_IsReturns').AsString=sFlag_Yes) then
    begin
      ShowMsg('����� ' + nLID + ' Ϊ�˻�������ֹ�˲���', '��ʾ');
      Exit;
    end;
                                                                   
    if (SQLQuery.FieldByName('L_Status').AsString<>sFlag_TruckOut) then
    begin
      ShowMsg('������δ���������˻�', '��ʾ');
      Exit;
    end;

    nLID     := SQLQuery.FieldByName('L_ID').AsString;
    //nStockGID:= SQLQuery.FieldByName('Grid').AsString +'��'+SQLQuery.FieldByName('G_Name').AsString;
    nZhiKa   := SQLQuery.FieldByName('L_Zhika').AsString;
    nCusID   := SQLQuery.FieldByName('L_CusID').AsString;
    nCusName := SQLQuery.FieldByName('L_CusName').AsString;
    nMID     := SQLQuery.FieldByName('L_StockNo').AsString;
    nMName   := SQLQuery.FieldByName('L_StockName').AsString;
    nTruck   := SQLQuery.FieldByName('L_Truck').AsString;
    nValue   := SQLQuery.FieldByName('L_Value').AsString;
    //*************
    nStr := Format('%s,%s,%s,%s,%s,%s,%s,%s', [nLID,nZhiKa,nCusID,nCusName,nMID,nMName,nTruck,nValue]);
    nParam.FParamA := StringReplace(nStr, ' ', '@', [rfReplaceAll]);
    CreateBaseFormItem(cFI_FormBillReturns, PopedomItem, @nParam);
    ///
  end;
end;

procedure TfFrameBill.cxView1CustomDrawCell(Sender: TcxCustomGridTableView;
  ACanvas: TcxCanvas; AViewInfo: TcxGridTableDataCellViewInfo;
  var ADone: Boolean);
begin
  inherited;
//  {$IFDEF UseBigFontSize}
//  if (AViewInfo.GridRecord.Values[TcxGridDBTableView(Sender).GetColumnByFieldName('L_Status').Index])<>'O' then
//      ACanvas.Canvas.Font.Color := $00A5FF  ;  //$C0C0C0;
//  {$ENDIF}

end;

initialization
  gControlManager.RegCtrl(TfFrameBill, TfFrameBill.FrameID);
end.
