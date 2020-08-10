unit UFormBillPriceModify;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, UFormNormal, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, dxSkinsCore, dxSkinsDefaultPainters, UFormBase,
  dxSkinsdxLCPainter, dxLayoutControl, StdCtrls, cxContainer, cxEdit,
  cxTextEdit, cxDropDownEdit, cxMaskEdit, cxCalendar, cxLabel;

type
  TfFormBillPriceModify = class(TfFormNormal)
    dxLayout1Item3: TdxLayoutItem;
    EditStart: TcxDateEdit;
    dxLayout1Item4: TdxLayoutItem;
    EditEnd: TcxDateEdit;
    edt_StockName: TcxComboBox;
    dxlytmLayout1Item5: TdxLayoutItem;
    dxlytmLayout1Item51: TdxLayoutItem;
    edt_CusName: TcxTextEdit;
    dxlytmLayout1Item52: TdxLayoutItem;
    edt_CusID: TcxTextEdit;
    dxlytmLayout1Item53: TdxLayoutItem;
    edt_Price: TcxTextEdit;
    dxlytmLayout1Item55: TdxLayoutItem;
    cxlbl1: TcxLabel;
    dxlytmLayout1Item56: TdxLayoutItem;
    edt_StockNo: TcxTextEdit;
    dxlytmLayout1Item57: TdxLayoutItem;
    cxlbl2: TcxLabel;
    dxlytmLayout1Item54: TdxLayoutItem;
    cxlbl3: TcxLabel;
    dxLayout1Group2: TdxLayoutGroup;
    procedure edt_StockNamePropertiesChange(Sender: TObject);
    procedure edt_CusNameKeyPress(Sender: TObject; var Key: Char);
    procedure BtnOKClick(Sender: TObject);
  private
    { Private declarations }
    procedure InitFormData(const nID: string);
    //��������
  public
    class function CreateForm(const nPopedom: string = '';
      const nParam: Pointer = nil): TWinControl; override;
    class function FormID: integer; override;
  end;

var
  fFormBillPriceModify: TfFormBillPriceModify;

implementation

{$R *.dfm}

uses
  IniFiles, ULibFun, UMgrControl, UFormCtrl, UAdjustForm, USysBusiness,
  UFormBaseInfo, USysGrid, USysDB, USysConst, UDataModule;

class function TfFormBillPriceModify.CreateForm(const nPopedom: string;
  const nParam: Pointer): TWinControl;
var nP: PFormCommandParam;
begin
  Result := nil;

  with TfFormBillPriceModify.Create(Application) do
  begin
    InitFormData('');

    ShowModal;
    Free;
  end;
end;

class function TfFormBillPriceModify.FormID: integer;
begin
  Result:= cFI_FormBillPriceModify;
end;

procedure TfFormBillPriceModify.InitFormData(const nID: string);
var nStr: string;
begin
  LoadSysDictItem(sFlag_StockItem, edt_StockName.Properties.Items);
  
  EditStart.Date:= Now;
  EditEnd.Date  := Now;
  edt_CusID.Text:= '';      edt_CusName.Text:= '';
  edt_StockNo.Text:= '';
  edt_Price.Text  := '';
end;

function GetStockItemNo(nName:string): string;
var nStr: string;
begin
  Result:= '';
  nStr := 'Select * From $T Where D_Name=''$N'' and D_Value=''$M''';
  nStr := MacroValue(nStr, [MI('$T', sTable_SysDict), MI('$N', sFlag_StockItem),
                            MI('$M', nName) ]);
  //xxxxx

  with FDM.QueryTemp(nStr) do
  if RecordCount > 0 then
       Result := FieldByName('D_ParamB').AsString;
end;

procedure TfFormBillPriceModify.edt_StockNamePropertiesChange(
  Sender: TObject);
begin
  edt_StockNo.Text:= GetStockItemNo( edt_StockName.Text);
end;

procedure TfFormBillPriceModify.edt_CusNameKeyPress(Sender: TObject;
  var Key: Char);
var nP: TFormCommandParam;
begin
  if Key = Char(VK_RETURN) then
  begin
    Key := #0;

    nP.FParamA := edt_CusName.Text;
    CreateBaseFormItem(cFI_FormGetCustom, '', @nP);

    if (nP.FCommand = cCmd_ModalResult) and (nP.FParamA = mrOK) and
       (nP.FParamB <> edt_CusID.Text) then
    begin
      edt_CusID.Text  := nP.FParamB;
      edt_CusName.Text := nP.FParamC;
    end;
  end;
end;

procedure TfFormBillPriceModify.BtnOKClick(Sender: TObject);
var nStr,nHint,nSTime,nETime,nCusID,nMID:string;
    nPrice:Double;
begin
  nSTime:= DateTime2Str(EditStart.Date);
  nETime:= DateTime2Str(EditEnd.Date);
  nCusID:= Trim(edt_CusID.Text);
  nMID  := Trim(edt_StockNo.Text);
  nPrice:= StrToFloatDef(Trim(edt_Price.Text), 0);

  if nSTime>nETime then
  begin
    ShowMsg('��ʼʱ����С�ڽ���ʱ��', '��ʾ');
    Exit;
  end;

  if nMID='' then
  begin
    ShowMsg('��ѡ��Ʒ��', '��ʾ');
    Exit;
  end;

  if nCusID='' then
  begin
    ShowMsg('��ѡ��ͻ�', '��ʾ');
    Exit;
  end;

  if nPrice<=0 then
  begin
    ShowMsg('��������Ч����', '��ʾ');
    Exit;
  end;

  nHint :='��ȷ��������Ϣ: ' + #13#10#13#10 +
          '��ʼʱ��: '+ nSTime + #13#10 +
          '����ʱ��: '+ nETime + #13#10 +
          'Ʒ������: '+ edt_StockName.Text + #13#10 +
          '�ͻ�����: '+ edt_CusName.Text + #13#10 +
          '�����ۼ�: '+ FloatToStr(nPrice) +' Ԫ/��'+ #13#10 +
             #13#10#13#10 +
          'ȷ�Ϻ󽫶Է��������ѳ������ݽ��м۸������ʱ��Ч,Ҫ������?  ';
  if not QueryDlg(nHint, sAsk, Handle) then Exit;

  FDM.ADOConn.BeginTrans;
  try
    //�����ѳ�������
    nStr := ' UPDate S_Bill Set L_Price= %g  '+
            ' Where (L_OutFact>= ''%s'' And L_OutFact< ''%s'') ' +
                'And L_CusID=''%s'' And L_StockNo=''%s'' ';
    nStr:= Format(nStr, [ nPrice, nSTime,nETime,nCusID,nMID] );
    FDM.ExecuteSQL(nStr);

    nStr:= StringReplace(nStr, '''', '', [rfReplaceAll]);
    FDM.WriteSysLog(sFlag_BillItem, '', nStr, False);

    //У������
    nStr := ' update Sys_CustomerAccount set A_OutMoney = L_Money From( ' +
                  ' Select Sum(L_Money) L_Money, L_CusID from ( ' +
                  ' select isnull(L_Value,0) * isnull(L_Price,0) as L_Money, L_CusID from S_Bill ' +
                  ' where L_OutFact Is not Null ) t Group by L_CusID) b where A_CID = b.L_CusID ';
    FDM.ExecuteSQL(nStr);

    //У�������ʽ�
    nStr := ' update Sys_CustomerAccount set A_FreezeMoney = L_Money From( ' +
                  ' Select Sum(L_Money) L_Money, L_CusID from ( ' +
                  ' select isnull(L_Value,0) * isnull(L_Price,0) as L_Money, L_CusID from S_Bill ' +
                  ' where L_OutFact Is  Null ) t Group by L_CusID) b where A_CID = b.L_CusID ';
    FDM.ExecuteSQL(nStr);

    //У�������ʽ�
    nStr := ' update Sys_CustomerAccount set A_FreezeMoney = 0  where ' +
                  ' A_CID  not in (select L_CusID from S_Bill    ' +
                  ' where L_OutFact Is Null Group by L_CusID ) ';
    FDM.ExecuteSQL(nStr);
    
    FDM.ADOConn.CommitTrans;
  except
    on nErr: Exception do
    begin
      FDM.ADOConn.RollbackTrans;
      ShowDlg('����ʧ�ܣ�'+nErr.Message, sHint);
    end;
  end;
end;

initialization
  gControlManager.RegCtrl(TfFormBillPriceModify, TfFormBillPriceModify.FormID);

end.
