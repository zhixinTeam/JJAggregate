{*******************************************************************************
  ����: dmzn@163.com 2018-12-14
  ����: �������
*******************************************************************************}
unit UFormBillAdjustNum;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  UFormNormal, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, ComCtrls, cxListView,
  cxDropDownEdit, cxTextEdit, cxMaskEdit, cxButtonEdit, cxMCListBox,
  dxLayoutControl, StdCtrls;

type
  TfFormBillAdjustNum = class(TfFormNormal)
    EditValue: TcxTextEdit;
    dxLayout1Item4: TdxLayoutItem;
    dxLayout1Item5: TdxLayoutItem;
    ListQuery: TcxListView;
    EditNewPrice: TcxTextEdit;
    dxLayout1Item3: TdxLayoutItem;
    EditNewValue: TcxTextEdit;
    dxLayout1Item6: TdxLayoutItem;
    EditPrice: TcxTextEdit;
    dxLayout1Item7: TdxLayoutItem;
    EditYFPrice: TcxTextEdit;
    dxLayout1Item8: TdxLayoutItem;
    EditNewYFPrice: TcxTextEdit;
    dxLayout1Item9: TdxLayoutItem;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure BtnOKClick(Sender: TObject);
  protected
    { Private declarations }
    FListA: TStrings;
    nL_Value,nL_Money,AL_Money: Double;
    nL_ID,nL_ZhiKa,nL_CusID,nL_CusName,nL_SaleID,nL_SaleMan,nL_Price,nl_YFPrice:string;
    ASaleID,ASaleMan,ACusID,ACusName,ACus_PY,ACus_Area,AL_ZhiKa,AL_Project:string;
    FShowPrice: Boolean;
    FIsHC : Boolean;  //�Ƿ���Ҫ���
    function CheckIF : Boolean;
    //��ʾ����
    procedure InitFormData(const nID: string);
    //��������
    procedure WriteOptionLog(const LID: string);
  public
    { Public declarations }
    class function CreateForm(const nPopedom: string = '';
      const nParam: Pointer = nil): TWinControl; override;
    class function FormID: integer; override;
  end;

implementation

{$R *.dfm}
uses
  DB, IniFiles, ULibFun, UFormBase, UMgrControl, UAdjustForm, UDataModule,
  USysPopedom, USysGrid, USysDB, USysConst, USysBusiness;

var
  gParam: PFormCommandParam = nil;
  //ȫ��ʹ��

class function TfFormBillAdjustNum.CreateForm(const nPopedom: string;
  const nParam: Pointer): TWinControl;
var
  nModifyStr: string;
begin
  Result := nil;
  if Assigned(nParam) then
    gParam := nParam
  else Exit;
  
  nModifyStr :=gParam.FParamA;

  with TfFormBillAdjustNum.Create(Application) do
  try
    Caption := '���������/����';

    FListA.Text := nModifyStr;
    InitFormData('');
    FShowPrice := gPopedomManager.HasPopedom(nPopedom, sPopedom_ViewPrice);
    
    gParam.FCommand := cCmd_ModalResult;
    gParam.FParamA := ShowModal;
  finally
    Free;
  end;
end;

class function TfFormBillAdjustNum.FormID: integer;
begin
  Result := cFI_FormBillAdjustNum;
end;

procedure TfFormBillAdjustNum.FormCreate(Sender: TObject);
begin
  FListA    := TStringList.Create;
  dxGroup1.AlignVert := avTop;
end;

procedure TfFormBillAdjustNum.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  ReleaseCtrlData(Self);
  FListA.Free;
end;

//------------------------------------------------------------------------------
procedure TfFormBillAdjustNum.InitFormData(const nID: string);
var
  nStr: string;
begin
  dxGroup1.AlignVert := avTop;

  nStr := 'select *, L_Price*L_Value L_Money From %s where L_ID = ''%s'' ';
  nStr := Format(nStr,[sTable_Bill,FListA.Strings[0]]);

  with FDM.QueryTemp(nStr) do
  begin
    if RecordCount < 1 then Exit;

    with ListQuery.Items.Add do
    begin
      Caption := FieldByName('L_ID').AsString;
      SubItems.Add(FieldByName('L_Zhika').AsString);
      SubItems.Add(FieldByName('L_SaleMan').AsString);
      SubItems.Add(FieldByName('L_CusName').AsString);
      SubItems.Add(FieldByName('L_Price').AsString);
      SubItems.Add(FieldByName('L_Truck').AsString);
      SubItems.Add(FieldByName('L_Value').AsString);
      ImageIndex := cItemIconIndex;
    end;

    EditValue.Text    := FieldByName('L_Value').AsString;
    EditPrice.Text    := FieldByName('L_Price').AsString;
    EditYFPrice.Text  := FloatToStr(FieldByName('L_YFPrice').AsFloat);
    nL_ID             := FieldByName('L_ID').AsString;
    nL_ZhiKa          := FieldByName('L_ZhiKa').AsString;
    nL_CusID          := FieldByName('L_CusID').AsString;
    nL_CusName        := FieldByName('L_CusName').AsString;
    nL_SaleID         := FieldByName('L_SaleID').AsString;
    nL_SaleMan        := FieldByName('L_SaleMan').AsString;
    nL_Price          := FieldByName('L_Price').AsString;
    nl_YFPrice        := FieldByName('L_YFPrice').AsString;
    nL_Value          := FieldByName('L_Value').AsFloat;
    nL_Money          := FieldByName('L_Money').AsFloat;
    nL_Money          := Float2Float(nL_Money, cPrecision, True);
  end;
end;

procedure TfFormBillAdjustNum.BtnOKClick(Sender: TObject);
var
  nStr, nSQL: string;
  nValue : Double;
  nNewPrice, nNewValue : Double;
begin
  if not CheckIF then Exit;

//  if FIsHC then
//  begin
  nSQL := 'Select * From %s Where L_ID=''%s'' ';
  nSQL := Format(nSQL, [sTable_Bill, nL_ID]);
  with FDM.QueryTemp(nSQL) do
  if (RecordCount > 0) and (FieldByName('L_Value').AsFloat > 0) then
  begin
    nValue := 0 - FieldByName('L_Value').AsFloat;
    //��������¼
    nStr := ' insert Into %s(L_ID,L_ZhiKa,L_CusID,L_CusName,L_CusPY,L_SaleID,L_SaleMan,L_StockNo,L_StockName,L_Value,L_Price,L_ZKMoney, '
      +' L_Truck,L_Status,L_NextStatus,L_InTime,L_InMan,L_PValue,L_PDate,L_PMan,L_MValue,L_MDate,L_MMan,L_LadeTime, '
      +' L_LadeMan,L_OutFact,L_OutMan,L_Man,L_Date,L_Memo,L_KDValue,L_YFPrice,L_Carrier) values '
      +' (''%s'',''%s'',''%s'',''%s'',''%s'',''%s'',''%s'',''%s'',''%s'',%f, %f,''%s'',''%s'',''%s'',''%s'',%s, '
      +'  ''%s'',%f,%s,''%s'',%f,%s,''%s'',%s,''%s'',''%s'',''%s'',''%s'',%s,''%s'',%f,%f,''%s'')';

    nStr := Format(nStr, [sTable_Bill, 'CH'+nL_ID, FieldByName('L_ZhiKa').AsString,
            FieldByName('L_CusID').AsString,FieldByName('L_CusName').AsString,FieldByName('L_CusPY').AsString,
            FieldByName('L_SaleID').AsString,FieldByName('L_SaleMan').AsString,FieldByName('L_StockNo').AsString,
            FieldByName('L_StockName').AsString,nValue,FieldByName('L_Price').AsFloat,
            FieldByName('L_ZKMoney').AsString,FieldByName('L_Truck').AsString,FieldByName('L_Status').AsString,
            FieldByName('L_NextStatus').AsString,FDM.SQLServerNow,FieldByName('L_InMan').AsString,
            FieldByName('L_PValue').AsFloat,FDM.SQLServerNow,FieldByName('L_PMan').AsString,
            FieldByName('L_MValue').AsFloat,FDM.SQLServerNow,FieldByName('L_MMan').AsString,
            FDM.SQLServerNow,FieldByName('L_LadeMan').AsString,FieldByName('L_OutFact').AsString,
            FieldByName('L_OutMan').AsString,FieldByName('L_Man').AsString,FDM.SQLServerNow,
            '����¼', FieldByName('L_KDValue').AsFloat,FieldByName('L_YFPrice').AsFloat,
            FieldByName('L_Carrier').AsString
            ]);
    FDM.ExecuteSQL(nStr);
    //�������۵�����ļ�¼
    nStr := ' insert Into %s(L_ID,L_ZhiKa,L_CusID,L_CusName,L_CusPY,L_SaleID,L_SaleMan,L_StockNo,L_StockName,L_Value,L_Price,L_ZKMoney, '
      +' L_Truck,L_Status,L_NextStatus,L_InTime,L_InMan,L_PValue,L_PDate,L_PMan,L_MValue,L_MDate,L_MMan,L_LadeTime, '
      +' L_LadeMan,L_OutFact,L_OutMan,L_Man,L_Date,L_Memo,L_KDValue,L_YFPrice,L_Carrier) values '
      +' (''%s'',''%s'',''%s'',''%s'',''%s'',''%s'',''%s'',''%s'',''%s'',%f, %f,''%s'',''%s'',''%s'',''%s'',%s, '
      +'  ''%s'',%f,%s,''%s'',%f,%s,''%s'',%s,''%s'',''%s'',''%s'',''%s'',%s,''%s'',%f,%f,''%s'')';

    nStr := Format(nStr, [sTable_Bill, 'TZ'+nL_ID, FieldByName('L_ZhiKa').AsString,
            FieldByName('L_CusID').AsString,FieldByName('L_CusName').AsString,FieldByName('L_CusPY').AsString,
            FieldByName('L_SaleID').AsString,FieldByName('L_SaleMan').AsString,FieldByName('L_StockNo').AsString,
            FieldByName('L_StockName').AsString,StrToFloat(Trim(EditNewValue.Text)),StrToFloat(Trim(EditNewPrice.Text)),
            FieldByName('L_ZKMoney').AsString,FieldByName('L_Truck').AsString,FieldByName('L_Status').AsString,
            FieldByName('L_NextStatus').AsString,FDM.SQLServerNow,FieldByName('L_InMan').AsString,
            FieldByName('L_PValue').AsFloat,FDM.SQLServerNow,FieldByName('L_PMan').AsString,
            FieldByName('L_MValue').AsFloat,FDM.SQLServerNow,FieldByName('L_MMan').AsString,
            FDM.SQLServerNow,FieldByName('L_LadeMan').AsString,FieldByName('L_OutFact').AsString,
            FieldByName('L_OutMan').AsString,FieldByName('L_Man').AsString,FDM.SQLServerNow,
            '����/������¼', FieldByName('L_KDValue').AsFloat,StrToFloat(Trim(EditNewYFPrice.Text)),
            FieldByName('L_Carrier').AsString]);
    FDM.ExecuteSQL(nStr);

    nStr := ' update %s set L_Memo=''%s'' where L_ID = ''%s'' ';
    nStr := Format(nStr, [sTable_Bill, '�ѵ���/����', nL_ID]);

    FDM.ExecuteSQL(nStr);
  end;
//  end
//  else
//  begin
//    if (StrToFloatDef(Trim(EditNewPrice.Text),0) = StrToFloatDef(Trim(EditPrice.Text),0)) then
//    begin
//      nNewPrice := StrToFloatDef(Trim(EditNewPrice.Text),0);
//      nNewValue := StrToFloatDef(Trim(EditNewValue.Text),0) - StrToFloatDef(Trim(EditValue.Text),0);
//    end
//    else if (StrToFloatDef(Trim(EditNewValue.Text),0) = StrToFloatDef(Trim(EditValue.Text),0)) then
//    begin
//      nNewPrice :=  StrToFloatDef(Trim(EditNewPrice.Text),0) -StrToFloatDef(Trim(EditPrice.Text),0);
//      nNewValue :=  StrToFloatDef(Trim(EditNewValue.Text),0);
//    end;
//    nSQL := 'Select * From %s Where L_ID=''%s'' ';
//    nSQL := Format(nSQL, [sTable_Bill, nL_ID]);
//    with FDM.QueryTemp(nSQL) do
//    if (RecordCount > 0) then
//    begin
//      //�������۵��������¼
//      nStr := ' insert Into %s(L_ID,L_ZhiKa,L_CusID,L_CusName,L_CusPY,L_SaleID,L_SaleMan,L_StockNo,L_StockName,L_Value,L_Price,L_ZKMoney, '
//        +' L_Truck,L_Status,L_NextStatus,L_InTime,L_InMan,L_PValue,L_PDate,L_PMan,L_MValue,L_MDate,L_MMan,L_LadeTime, '
//        +' L_LadeMan,L_OutFact,L_OutMan,L_Man,L_Date,L_Memo,L_KDValue) values '
//        +' (''%s'',''%s'',''%s'',''%s'',''%s'',''%s'',''%s'',''%s'',''%s'',%f, %f,''%s'',''%s'',''%s'',''%s'',%s, '
//        +'  ''%s'',%f,%s,''%s'',%f,%s,''%s'',%s,''%s'',''%s'',''%s'',''%s'',%s,''%s'',%f)';
//
//      nStr := Format(nStr, [sTable_Bill, 'TZ'+nL_ID, FieldByName('L_ZhiKa').AsString,
//              FieldByName('L_CusID').AsString,FieldByName('L_CusName').AsString,FieldByName('L_CusPY').AsString,
//              FieldByName('L_SaleID').AsString,FieldByName('L_SaleMan').AsString,FieldByName('L_StockNo').AsString,
//              FieldByName('L_StockName').AsString,nNewValue,nNewPrice,
//              FieldByName('L_ZKMoney').AsString,FieldByName('L_Truck').AsString,FieldByName('L_Status').AsString,
//              FieldByName('L_NextStatus').AsString,FDM.SQLServerNow,FieldByName('L_InMan').AsString,
//              FieldByName('L_PValue').AsFloat,FDM.SQLServerNow,FieldByName('L_PMan').AsString,
//              FieldByName('L_MValue').AsFloat,FDM.SQLServerNow,FieldByName('L_MMan').AsString,
//              FDM.SQLServerNow,FieldByName('L_LadeMan').AsString,FieldByName('L_OutFact').AsString,
//              FieldByName('L_OutMan').AsString,FieldByName('L_Man').AsString,FDM.SQLServerNow,
//              '����/������¼', FieldByName('L_KDValue').AsFloat]);
//      FDM.ExecuteSQL(nStr);
//
//      nStr := ' update %s set L_Memo=''%s'' where L_ID = ''%s'' ';
//      nStr := Format(nStr, [sTable_Bill, '�ѵ���/����', nL_ID]);
//
//      FDM.ExecuteSQL(nStr);
//    end;
//  end;
  //����/������У���ʽ�
  CheckAllCusMoney;

  ModalResult := mrOk;

  nStr := '���۵������';
  ShowMsg(nStr, sHint);
end;

procedure TfFormBillAdjustNum.WriteOptionLog(const LID: string);
var nEvent: string;
begin
  nEvent := '';

  try
    nEvent := nEvent + '�۸��� [ %s ] --> [ %s ];';
    nEvent := Format(nEvent, [nL_Price, EditNewPrice.Text]);

    nEvent := nEvent + '������ [ %s ] --> [ %s ];';
    nEvent := Format(nEvent, [nL_Value, EditNewValue.Text]);

    nEvent := nEvent + '�˷Ѽ۸��� [ %s ] --> [ %s ];';
    nEvent := Format(nEvent, [nl_YFPrice, EditNewYFPrice.Text]);

    if nEvent <> '' then
    begin
      nEvent := '����� [ %s ] ��¼�ѱ��޸�:' + nEvent;
      nEvent := Format(nEvent, [LID]);
    end;
    if nEvent <> '' then
    begin
      FDM.WriteSysLog(sFlag_BillItem, LID, nEvent);
    end;
  except
  end;
end;

function TfFormBillAdjustNum.CheckIF: Boolean;
begin
  Result := False;
  FIsHC  := True;

  if StrToFloatDef(Trim(EditNewYFPrice.Text),0) = 0 then
    EditNewYFPrice.Text := '0';
    
  if StrToFloatDef(Trim(EditNewPrice.Text),0) <= 0 then
  begin
    ShowMsg('������ļ۸���Ҫ������', sHint);
    Exit;
  end;
  if StrToFloatDef(Trim(EditNewValue.Text),0) <= 0 then
  begin
    ShowMsg('�������������Ҫ������', sHint);
    Exit;
  end;
  if StrToFloatDef(Trim(EditNewYFPrice.Text),0) < 0 then
  begin
    ShowMsg('��������˷Ѽ۸���Ҫ���ڵ�����', sHint);
    Exit;
  end;
  if (StrToFloatDef(Trim(EditNewPrice.Text),0)    = StrToFloatDef(Trim(EditPrice.Text),0))
    and (StrToFloatDef(Trim(EditNewValue.Text),0) = StrToFloatDef(Trim(EditValue.Text),0)) then
  begin
    ShowMsg('�۸��������δ�仯,�������/����', sHint);
    Exit;
  end;
//  if (StrToFloatDef(Trim(EditNewPrice.Text),0) <> StrToFloatDef(Trim(EditPrice.Text),0))
//    and (StrToFloatDef(Trim(EditNewValue.Text),0) <> StrToFloatDef(Trim(EditValue.Text),0)) then
//    FIsHC := True
//  else
//    FIsHC := False;

  Result := True;
end;

initialization
  gControlManager.RegCtrl(TfFormBillAdjustNum, TfFormBillAdjustNum.FormID);
end.
