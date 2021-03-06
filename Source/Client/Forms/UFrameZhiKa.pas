{*******************************************************************************
  作者: dmzn@163.com 2018-12-11
  描述: 办理纸卡
*******************************************************************************}
unit UFrameZhiKa;

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
  TfFrameZhiKa = class(TfFrameNormal)
    EditID: TcxButtonEdit;
    dxLayout1Item1: TdxLayoutItem;
    EditCID: TcxButtonEdit;
    dxLayout1Item2: TdxLayoutItem;
    cxTextEdit1: TcxTextEdit;
    dxLayout1Item3: TdxLayoutItem;
    cxTextEdit2: TcxTextEdit;
    dxLayout1Item4: TdxLayoutItem;
    cxTextEdit3: TcxTextEdit;
    dxLayout1Item5: TdxLayoutItem;
    cxTextEdit5: TcxTextEdit;
    dxLayout1Item7: TdxLayoutItem;
    PMenu1: TPopupMenu;
    N1: TMenuItem;
    EditDate: TcxButtonEdit;
    dxLayout1Item6: TdxLayoutItem;
    EditCode: TcxButtonEdit;
    dxLayout1Item8: TdxLayoutItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    N5: TMenuItem;
    N7: TMenuItem;
    N8: TMenuItem;
    N9: TMenuItem;
    N10: TMenuItem;
    N6: TMenuItem;
    N11: TMenuItem;
    procedure EditIDPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure BtnAddClick(Sender: TObject);
    procedure BtnEditClick(Sender: TObject);
    procedure BtnDelClick(Sender: TObject);
    procedure EditDatePropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure N1Click(Sender: TObject);
    procedure N4Click(Sender: TObject);
    procedure cxView1DblClick(Sender: TObject);
    procedure N8Click(Sender: TObject);
    procedure N10Click(Sender: TObject);
    procedure N11Click(Sender: TObject);
  private
    { Private declarations }
  protected
    FStart,FEnd: TDate;
    {*时间区间*}
    procedure OnCreateFrame; override;
    procedure OnDestroyFrame; override;
    {*基类函数*}
    function InitFormDataSQL(const nWhere: string): string; override;
    {*查询SQL*}
  public
    { Public declarations }
    class function FrameID: integer; override;
  end;

implementation

{$R *.dfm}
uses
  ULibFun, UMgrControl, UDataModule, UFormBase, USysConst, USysDB, USysBusiness,
  UFormCtrl, UFormDateFilter;

//------------------------------------------------------------------------------
class function TfFrameZhiKa.FrameID: integer;
begin
  Result := cFI_FrameZhiKa;
end;

procedure TfFrameZhiKa.OnCreateFrame;
begin
  inherited;
  InitDateRange(Name, FStart, FEnd);
  
  if FStart = FEnd then
  begin
    FStart := Date() - 90;
    //FEnd := Date() + 90;
  end;
end;

procedure TfFrameZhiKa.OnDestroyFrame;
begin
  SaveDateRange(Name, FStart, FEnd);
  inherited;
end;

//Desc: 数据查询SQL
function TfFrameZhiKa.InitFormDataSQL(const nWhere: string): string;
begin
  EditDate.Text := Format('%s 至 %s', [Date2Str(FStart), Date2Str(FEnd)]);
  
  Result := 'Select zk.*,sm.S_Name,sm.S_PY,cus.C_Name,cus.C_PY,' +
            'Z_Money-Z_MoneyUsed as Z_MoneyHas From $ZK zk ' +
            ' Left Join $SM sm On sm.S_ID=zk.Z_SaleMan ' +
            ' Left Join $Cus cus On cus.C_ID=zk.Z_Customer';
  //纸卡
  {$IFDEF AdminUseFL}
  if gSysParam.FIsAdmin then
  begin
    if nWhere = '' then
         Result := Result + ' Where (zk.Z_Date>=''$ST'' and zk.Z_Date <''$End'')' +
                   ' and (Z_InValid Is Null or Z_InValid<>''$Yes'')'
    else Result := Result + ' Where (' + nWhere + ')';
  end
  else
  begin
    if nWhere = '' then
         Result := Result + ' Where (zk.Z_Date>=''$ST'' and zk.Z_Date <''$End'')' +
                   ' and (Z_InValid Is Null or Z_InValid<>''$Yes'') '+
                   ' and (zk.Z_Customer in(select distinct C_ID from S_Customer where isnull(C_FL,'''') <> ''Y'' ))'
    else Result := Result + ' Where (' + nWhere + ') and (zk.Z_Customer in(select distinct C_ID from S_Customer where isnull(C_FL,'''') <> ''Y'' ))';
  end;
  {$ELSE}
    if nWhere = '' then
         Result := Result + ' Where (zk.Z_Date>=''$ST'' and zk.Z_Date <''$End'')' +
                   ' and (Z_InValid Is Null or Z_InValid<>''$Yes'')'
    else Result := Result + ' Where (' + nWhere + ')';
  {$ENDIF}

  Result := MacroValue(Result, [MI('$ZK', sTable_ZhiKa), 
             MI('$SM', sTable_Salesman),
             MI('$Cus', sTable_Customer), MI('$Yes', sFlag_Yes),
             MI('$ST', Date2Str(FStart)), MI('$End', Date2Str(FEnd + 1))]);
  //xxxxx
end;

//------------------------------------------------------------------------------
//Desc: 添加
procedure TfFrameZhiKa.BtnAddClick(Sender: TObject);
var nParam: TFormCommandParam;
begin
  nParam.FCommand := cCmd_AddData;
  CreateBaseFormItem(cFI_FormZhiKa, PopedomItem, @nParam);

  if (nParam.FCommand = cCmd_ModalResult) and (nParam.FParamA = mrOK) then
  begin
    InitFormData('');
  end;
end;

//Desc: 修改
procedure TfFrameZhiKa.BtnEditClick(Sender: TObject);
var nParam: TFormCommandParam;
begin
  if cxView1.DataController.GetSelectedCount < 1 then
  begin
    ShowMsg('请选择要编辑的记录', sHint); Exit;
  end;        

  nParam.FParamA := SQLQuery.FieldByName('Z_ID').AsString;
  nParam.FCommand := cCmd_EditData;
  CreateBaseFormItem(cFI_FormZhiKa, PopedomItem, @nParam);

  if (nParam.FCommand = cCmd_ModalResult) and (nParam.FParamA = mrOK) then
  begin
    InitFormData(FWhere);
  end;
end;

//Desc: 删除
procedure TfFrameZhiKa.BtnDelClick(Sender: TObject);
var nStr,nID: string;
begin
  if cxView1.DataController.GetSelectedCount < 1 then
  begin
    ShowMsg('请选择要删除的记录', sHint); Exit;
  end;

  nID := SQLQuery.FieldByName('Z_ID').AsString;
  nStr := 'Select Count(*) From %s Where L_ZhiKa=''%s''';
  nStr := Format(nStr, [sTable_Bill, nID]);

  with FDM.QueryTemp(nStr) do
  if Fields[0].AsInteger > 0 then
  begin
    ShowMsg('该纸卡不能删除', '已提货'); Exit;
  end;

  nStr := Format('确定要删除编号为[ %s ]的纸卡吗?', [nID]);
  if not QueryDlg(nStr, sAsk) then Exit;

  FDM.ADOConn.BeginTrans;
  try
    DeleteZhiKa(nID);
    FDM.ADOConn.CommitTrans;
    
    InitFormData(FWhere);
    ShowMsg('已成功删除记录', sHint);
  except
    FDM.ADOConn.RollbackTrans;
    ShowMsg('删除记录失败', '未知错误');
  end;
end;

//Desc: 执行查询
procedure TfFrameZhiKa.EditIDPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  if Sender = EditID then
  begin
    EditID.Text := Trim(EditID.Text);
    if EditID.Text = '' then Exit;

    FWhere := 'Z_ID like ''%' + EditID.Text + '%''';
    InitFormData(FWhere);
  end else

  if Sender = EditCID then
  begin
    EditCID.Text := Trim(EditCID.Text);
    if EditCID.Text = '' then Exit;

    FWhere := 'C_Name like ''%%%s%%'' Or C_PY like ''%%%s%%''';
    FWhere := Format(FWhere, [EditCID.Text, EditCID.Text]);
    InitFormData(FWhere);
  end else

  if Sender = EditCode then
  begin
    EditCode.Text := Trim(EditCode.Text);
    if EditCode.Text = '' then Exit;

    FWhere := 'Z_Password like ''%%%s%%''';
    FWhere := Format(FWhere, [EditCode.Text]);
    InitFormData(FWhere);
  end;
end;

//Desc: 查看内容
procedure TfFrameZhiKa.cxView1DblClick(Sender: TObject);
var nParam: TFormCommandParam;
begin
  if cxView1.DataController.GetSelectedCount > 0 then
  begin
    nParam.FCommand := cCmd_ViewData;
    nParam.FParamA := SQLQuery.FieldByName('Z_ID').AsString;
    CreateBaseFormItem(cFI_FormZhiKa, PopedomItem, @nParam);
  end;
end;

//Desc: 日期筛选
procedure TfFrameZhiKa.EditDatePropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  if ShowDateFilterForm(FStart, FEnd) then InitFormData('');
end;

//Desc: 打印纸卡
procedure TfFrameZhiKa.N1Click(Sender: TObject);
var nStr: string;
begin
  if cxView1.DataController.GetSelectedCount > 0 then
  begin
    nStr := SQLQuery.FieldByName('Z_ID').AsString;
    PrintZhiKaReport(nStr, False);
  end;
end;

//Desc: 快捷查询
procedure TfFrameZhiKa.N4Click(Sender: TObject);
begin
  case TComponent(Sender).Tag of
    10: FWhere := Format('Z_Freeze=''%s''', [sFlag_Yes]);
    20: FWhere := Format('Z_InValid=''%s''', [sFlag_Yes]);
    30: FWhere := '1=1';
  end;

  InitFormData(FWhere);
end;

//Desc: 冻结
procedure TfFrameZhiKa.N8Click(Sender: TObject);
var nStr,nFlag,nMsg: string;
begin
  if cxView1.DataController.GetSelectedCount > 0 then
  begin
    case TComponent(Sender).Tag of
     10:
       if SQLQuery.FieldByName('Z_Freeze').AsString <> sFlag_Yes then
       begin
         nFlag := sFlag_Yes; nMsg := '纸卡已成功冻结';
       end else Exit;
     20:
       if SQLQuery.FieldByName('Z_Freeze').AsString = sFlag_Yes then
       begin
         nFlag := sFlag_No; nMsg := '冻结已成功解除';
       end else Exit;
    end;

    nStr := 'Update %s Set Z_Freeze=''%s'' Where Z_ID=''%s''';
    nStr := Format(nStr, [sTable_ZhiKa, nFlag, SQLQuery.FieldByName('Z_ID').AsString]);

    FDM.ExecuteSQL(nStr);
    InitFormData(FWhere);
    ShowMsg(nMsg, sHint);
  end;
end;

//Desc: 审核
procedure TfFrameZhiKa.N10Click(Sender: TObject);
var nStr: string;
begin
  if cxView1.DataController.GetSelectedCount > 0 then
  begin
    nStr := SF('Z_ID', SQLQuery.FieldByName('Z_ID').AsString);
    nStr := MakeSQLByStr([SF('Z_Verified', sFlag_Yes),
            SF('Z_VerifyMan', gSysParam.FUserID),
            SF('Z_VerifyDate', sField_SQLServer_Now, sfVal)
            ], sTable_ZhiKa, nStr, False);
    FDM.ExecuteSQL(nStr);
    
    InitFormData(FWhere);
    ShowMsg('审核完毕', sHint);
  end;
end;

//一键校正纸卡金额
procedure TfFrameZhiKa.N11Click(Sender: TObject);
var nStr: string;
begin
  if cxView1.DataController.GetSelectedCount > 0 then
  begin
    nStr := ' update S_ZhiKa set Z_MoneyUsed = L_Money From( ' +
      ' Select Sum(L_Money) L_Money, L_ZhiKa from ( ' +
      ' select isnull(L_Value,0) * isnull(L_Price,0) as L_Money, L_ZhiKa from S_Bill ' +
      ' where L_OutFact Is not Null ) t Group by L_ZhiKa) b where Z_ID = b.L_ZhiKa ';

    FDM.ExecuteSQL(nStr);

    InitFormData(FWhere);
    ShowMsg('校正完毕', sHint);
  end;
end;

initialization
  gControlManager.RegCtrl(TfFrameZhiKa, TfFrameZhiKa.FrameID);
end.
