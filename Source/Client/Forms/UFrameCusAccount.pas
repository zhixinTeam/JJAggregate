{*******************************************************************************
  作者: dmzn@163.com 2009-09-04
  描述: 客户账户查询
*******************************************************************************}
unit UFrameCusAccount;

{$I Link.Inc}
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
  TfFrameCusAccount = class(TfFrameNormal)
    cxTextEdit3: TcxTextEdit;
    dxLayout1Item5: TdxLayoutItem;
    cxTextEdit4: TcxTextEdit;
    dxLayout1Item7: TdxLayoutItem;
    EditCustomer: TcxButtonEdit;
    dxLayout1Item8: TdxLayoutItem;
    cxTextEdit5: TcxTextEdit;
    dxLayout1Item10: TdxLayoutItem;
    cxTextEdit1: TcxTextEdit;
    dxLayout1Item1: TdxLayoutItem;
    PMenu1: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    EditID: TcxButtonEdit;
    dxLayout1Item2: TdxLayoutItem;
    N4: TMenuItem;
    N5: TMenuItem;
    N6: TMenuItem;
    N7: TMenuItem;
    N8: TMenuItem;
    procedure N3Click(Sender: TObject);
    procedure EditIDPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure PMenu1Popup(Sender: TObject);
    procedure N4Click(Sender: TObject);
    procedure N6Click(Sender: TObject);
    procedure N7Click(Sender: TObject);
  private
    { Private declarations }
  protected
    function InitFormDataSQL(const nWhere: string): string; override;
    {*查询SQL*}
  public
    { Public declarations }
    class function FrameID: integer; override;
  end;

implementation

{$R *.dfm}
uses
  ULibFun, UMgrControl, USysConst, USysDB, UDataModule, USysBusiness, UFormDateFilter,
  UDataReport;

class function TfFrameCusAccount.FrameID: integer;
begin
  Result := cFI_FrameCusAccountQuery;
end;

function TfFrameCusAccount.InitFormDataSQL(const nWhere: string): string;
begin
  Result := 'Select ca.*,cus.*,S_Name as C_SaleName,' +
            '(A_InitMoney + A_InMoney-A_OutMoney-A_Compensation-A_FreezeMoney) As A_YuE ' +
            'From $CA ca ' +
            ' Left Join $Cus cus On cus.C_ID=ca.A_CID ' +
            ' Left Join $SM sm On sm.S_ID=cus.C_SaleMan ';
  //xxxxx
  {$IFDEF AdminUseFL}
  if gSysParam.FIsAdmin then
  begin
    if nWhere = '' then
         Result := Result + 'Where IsNull(C_XuNi, '''')<>''$Yes'''
    else Result := Result + 'Where (' + nWhere + ')';
  end
  else
  begin
    if nWhere = '' then
         Result := Result + 'Where IsNull(C_XuNi, '''')<>''$Yes'' and IsNull(C_FL, '''')<>''$Yes'' '
    else Result := Result + 'Where (' + nWhere + ') and (IsNull(C_FL, '''')<>''$Yes'') ';
  end;
  {$ELSE}
    if nWhere = '' then
         Result := Result + 'Where IsNull(C_XuNi, '''')<>''$Yes'''
    else Result := Result + 'Where (' + nWhere + ')';  
  {$ENDIF}

  Result := MacroValue(Result, [MI('$CA', sTable_CusAccount),
            MI('$Cus', sTable_Customer), MI('$SM', sTable_Salesman),
            MI('$Yes', sFlag_Yes)]);
  //xxxxx
end;

//Desc: 执行查询  
procedure TfFrameCusAccount.EditIDPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  if Sender = EditID then
  begin
    EditID.Text := Trim(EditID.Text);
    if EditID.Text = '' then Exit;

    FWhere := Format('C_ID like ''%%%s%%''', [EditID.Text]);
    InitFormData(FWhere);
  end else

  if Sender = EditCustomer then
  begin
    EditCustomer.Text := Trim(EditCustomer.Text);
    if EditCustomer.Text = '' then Exit;

    FWhere := 'C_PY like ''%%%s%%'' Or C_Name like ''%%%s%%''';
    FWhere := Format(FWhere, [EditCustomer.Text, EditCustomer.Text]);
    InitFormData(FWhere);
  end
end;

//------------------------------------------------------------------------------
procedure TfFrameCusAccount.PMenu1Popup(Sender: TObject);
begin
  {$IFDEF SyncRemote}
  N4.Visible := True;
  {$ELSE}
  N4.Visible := False;
  {$ENDIF}
  N6.Enabled := True;   // gSysParam.FIsAdmin;
end;

//Desc: 快捷菜单
procedure TfFrameCusAccount.N3Click(Sender: TObject);
begin
  case TComponent(Sender).Tag of
   10: FWhere := Format('C_XuNi=''%s''', [sFlag_Yes]);
   20: FWhere := '1=1';
  end;

  InitFormData(FWhere);
end;

procedure TfFrameCusAccount.N4Click(Sender: TObject);
var nStr: string;
    nVal,nCredit: Double;
begin
  if cxView1.DataController.GetSelectedCount > 0 then
  begin
    nStr := SQLQuery.FieldByName('A_CID').AsString;
    nVal := GetCustomerValidMoney(nStr, False, @nCredit);

    nStr := '客户当前可用金额如下:' + #13#10#13#10 +
            '*.客户名称: %s ' + #13#10 +
            '*.资金余额: %.2f 元' + #13#10 +
            '*.信用金额: %.2f 元' + #13#10;
    nStr := Format(nStr, [SQLQuery.FieldByName('C_Name').AsString, nVal, nCredit]);
    ShowDlg(nStr, sHint);
  end;
end;

//Desc: 校正客户资金
procedure TfFrameCusAccount.N6Click(Sender: TObject);
var nStr,nCID: string;
    nVal: Double;
begin
  if cxView1.DataController.GetSelectedCount < 1 then Exit;
  
  //校正出金
  nStr := ' update Sys_CustomerAccount set A_OutMoney = L_Money From( ' +
    ' Select Sum(L_Money) L_Money, L_CusID from ( ' +
    ' select isnull(L_Value,0) * isnull(L_Price,0) as L_Money, L_CusID from S_Bill ' +
    ' where L_OutFact Is not Null ) t Group by L_CusID) b where A_CID = b.L_CusID ';
  FDM.ExecuteSQL(nStr);

  //校正冻结资金
  nStr := ' update Sys_CustomerAccount set A_FreezeMoney = L_Money From( ' +
    ' Select Sum(L_Money) L_Money, L_CusID from ( ' +
    ' select isnull(L_Value,0) * isnull(L_Price,0) as L_Money, L_CusID from S_Bill ' +
    ' where L_OutFact Is  Null ) t Group by L_CusID) b where A_CID = b.L_CusID ';
  FDM.ExecuteSQL(nStr);

  //校正冻结资金
  nStr := ' update Sys_CustomerAccount set A_FreezeMoney = 0  where ' +
    ' A_CID  not in (select L_CusID from S_Bill    ' +
    ' where L_OutFact Is Null Group by L_CusID ) ';
  FDM.ExecuteSQL(nStr);

  InitFormData(FWhere);
  ShowMsg('校正完毕', sHint);

//  nCID := SQLQuery.FieldByName('A_CID').AsString;
//
//  nStr := 'Select Sum(L_Money) from (' +
//          '  select L_Value * L_Price as L_Money from %s' +
//          '  where L_OutFact Is not Null And L_CusID = ''%s'') t';
//  nStr := Format(nStr, [sTable_Bill, nCID]);
//
//  with FDM.QuerySQL(nStr) do
//  begin
//    nVal := Float2Float(Fields[0].AsFloat, cPrecision, True);
//    nStr := 'Update %s Set A_OutMoney=%.2f Where A_CID=''%s''';
//    nStr := Format(nStr, [sTable_CusAccount, nVal, nCID]);
//    FDM.ExecuteSQL(nStr);
//  end;
//
//  nStr := 'Select Sum(L_Money) from (' +
//          '  select L_Value * L_Price as L_Money from %s' +
//          '  where L_OutFact Is Null And L_CusID = ''%s'') t';
//  nStr := Format(nStr, [sTable_Bill, nCID]);
//
//  with FDM.QuerySQL(nStr) do
//  begin
//    nVal := Float2Float(Fields[0].AsFloat, cPrecision, True);
//    nStr := 'Update %s Set A_FreezeMoney=%.2f Where A_CID=''%s''';
//    nStr := Format(nStr, [sTable_CusAccount, nVal, nCID]);
//    FDM.ExecuteSQL(nStr);
//  end;
end;

procedure TfFrameCusAccount.N7Click(Sender: TObject);
var
  nStr, nCID, nCName,nCDate : string;
  FStart,FEnd: TDate;
  nLastInMoney, nLastOutMoney, nLastYSMoney : Double;
  nInMoney, nOutMoney, nYSMoney : Double;
  nParam: TReportParamItem;
  nSus: Boolean;
begin
  inherited;
  if cxView1.DataController.GetSelectedCount < 1 then Exit;

  nCID   := SQLQuery.FieldByName('A_CID').AsString;
  nCName := SQLQuery.FieldByName('C_NAME').AsString;
  FStart := IncMonth(Now,-1);
  FEnd   := Now;
  if ShowDateFilterForm(FStart, FEnd) then
  begin
    nCDate := Date2CH(FormatDateTime('YYYYMMDD', FStart))+'至'
             +Date2CH(FormatDateTime('YYYYMMDD', FEnd));
    nStr := ' Select Sum(L_Money) from (' +
            ' select L_Value * L_Price as L_Money from %s' +
            ' where L_OutFact Is not Null And L_CusID = ''%s'' and L_OutFact < ''%s'') t';
    nStr := Format(nStr, [sTable_Bill, nCID, Date2Str(FStart)]);

    with FDM.QuerySQL(nStr) do
    begin
      nLastOutMoney := Float2Float(Fields[0].AsFloat, cPrecision, True);
    end;

    nStr := ' Select Sum(M_Money) from %s ' +
            ' where M_CusID = ''%s'' and M_Date < ''%s'' ';
    nStr := Format(nStr, [sTable_InOutMoney, nCID, Date2Str(FStart)]);
    with FDM.QuerySQL(nStr) do
    begin
      nLastInMoney := Float2Float(Fields[0].AsFloat, cPrecision, True);
    end;
    //上期应收款余额
    nLastYSMoney := nLastOutMoney - nLastInMoney;


    nStr := ' Select Sum(L_Money) from (' +
            ' select L_Value * L_Price as L_Money from %s' +
            ' where L_OutFact Is not Null And L_CusID = ''%s'' and L_OutFact >= ''%s'' and L_OutFact < ''%s'') t';
    nStr := Format(nStr, [sTable_Bill, nCID, Date2Str(FStart),Date2Str(FEnd + 1)]);

    with FDM.QuerySQL(nStr) do
    begin
      //本期应收账款
      nOutMoney := Float2Float(Fields[0].AsFloat, cPrecision, True);
    end;

    nStr := ' Select Sum(M_Money) from %s ' +
            ' where M_CusID = ''%s'' and M_Date >= ''%s'' and M_Date < ''%s'' ';
    nStr := Format(nStr, [sTable_InOutMoney, nCID, Date2Str(FStart),Date2Str(FEnd + 1)]);
    with FDM.QuerySQL(nStr) do
    begin
      //本期收到客户款项
      nInMoney := Float2Float(Fields[0].AsFloat, cPrecision, True);
    end;
    //本期应收款余额
    nYSMoney := nOutMoney - nInMoney + nLastYSMoney ;

    nStr := ' Select Sum(L_Value) L_Value, Sum(L_Value * L_Price) L_Money, L_StockName, L_Price from %s ' +
            ' where L_OutFact Is not Null And L_CusID = ''%s'' and L_OutFact >= ''%s'' and L_OutFact < ''%s'' ' +
            ' Group By L_StockName, L_Price ';

    nStr := Format(nStr, [sTable_Bill, nCID, Date2Str(FStart),Date2Str(FEnd + 1)]);

    if FDM.QueryTemp(nStr).RecordCount < 1 then Exit;

    nStr := gPath + sReportDir + 'CBReport.fr3';
    if not FDR.LoadReportFile(nStr) then
    begin
      nStr := '无法正确加载报表文件';
      ShowMsg(nStr, sHint); Exit;
    end;

    nParam.FName  := 'UserName';
    nParam.FValue := gSysParam.FUserID;
    FDR.AddParamItem(nParam);

    nParam.FName  := 'Company';
    nParam.FValue := gSysParam.FHintText;
    FDR.AddParamItem(nParam);

    nParam.FName  := 'CusName';
    nParam.FValue := nCName;
    FDR.AddParamItem(nParam);

    nParam.FName  := 'CusDate';
    nParam.FValue := nCDate;
    FDR.AddParamItem(nParam);

    nParam.FName  := 'LastYSMoney';
    nParam.FValue := FloatToStr(nLastYSMoney);
    FDR.AddParamItem(nParam);

    nParam.FName  := 'YSSumMoney';
    nParam.FValue := FloatToStr(nOutMoney);
    FDR.AddParamItem(nParam);

    nParam.FName  := 'InOutMoney';
    nParam.FValue := FloatToStr(nInMoney);
    FDR.AddParamItem(nParam);

    nParam.FName  := 'YSMoney';
    nParam.FValue := FloatToStr(nYSMoney);
    FDR.AddParamItem(nParam);

    FDR.Dataset1.DataSet := FDM.SqlTemp;
    FDR.ShowReport;
    nSus := FDR.PrintSuccess;
  end;
end;

initialization
  gControlManager.RegCtrl(TfFrameCusAccount, TfFrameCusAccount.FrameID);
end.
