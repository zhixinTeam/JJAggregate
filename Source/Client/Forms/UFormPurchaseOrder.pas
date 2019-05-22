{*******************************************************************************
  ����: fendou116688@163.com 2015/9/19
  ����: ����ɹ������󶨴ſ�
*******************************************************************************}
unit UFormPurchaseOrder;

{$I Link.Inc}
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  UFormNormal, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, cxMaskEdit, cxButtonEdit,
  cxTextEdit, dxLayoutControl, StdCtrls, cxDropDownEdit, cxLabel;

type
  TfFormPurchaseOrder = class(TfFormNormal)
    dxGroup2: TdxLayoutGroup;
    EditValue: TcxTextEdit;
    dxLayout1Item8: TdxLayoutItem;
    EditMate: TcxTextEdit;
    dxLayout1Item9: TdxLayoutItem;
    EditID: TcxTextEdit;
    dxLayout1Item5: TdxLayoutItem;
    EditProvider: TcxTextEdit;
    dxlytmLayout1Item3: TdxLayoutItem;
    dxGroupLayout1Group2: TdxLayoutGroup;
    EditSalesMan: TcxTextEdit;
    dxlytmLayout1Item6: TdxLayoutItem;
    EditProject: TcxTextEdit;
    dxlytmLayout1Item7: TdxLayoutItem;
    EditArea: TcxTextEdit;
    dxlytmLayout1Item8: TdxLayoutItem;
    EditTruck: TcxButtonEdit;
    dxlytmLayout1Item12: TdxLayoutItem;
    EditCardType: TcxComboBox;
    dxLayout1Item3: TdxLayoutItem;
    dxLayout1Group2: TdxLayoutGroup;
    cxLabel1: TcxLabel;
    dxLayout1Item4: TdxLayoutItem;
    dxLayout1Group4: TdxLayoutGroup;
    EditKFValue: TcxTextEdit;
    dxLayout1Item6: TdxLayoutItem;
    EditKFLS: TcxTextEdit;
    dxLayout1Item7: TdxLayoutItem;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure BtnOKClick(Sender: TObject);
    procedure EditLadingKeyPress(Sender: TObject; var Key: Char);
    procedure EditTruckPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
  protected
    { Protected declarations }
    FCardData, FListA: TStrings;
    //��Ƭ����
    FNewBillID: string;
    //���ᵥ��
    FBuDanFlag: string;
    //�������
    procedure InitFormData;
    //��ʼ������
  public
    { Public declarations }
    class function CreateForm(const nPopedom: string = '';
      const nParam: Pointer = nil): TWinControl; override;
    class function FormID: integer; override;
    function OnVerifyCtrl(Sender: TObject; var nHint: string): Boolean; override;
  end;

implementation

{$R *.dfm}
uses
  ULibFun, DB, IniFiles, UMgrControl, UAdjustForm, UFormBase, UBusinessPacker,
  UDataModule, USysBusiness, USysDB, USysGrid, USysConst;

var
  gForm: TfFormPurchaseOrder = nil;
  //ȫ��ʹ��

class function TfFormPurchaseOrder.CreateForm(const nPopedom: string;
  const nParam: Pointer): TWinControl;
var nStr: string;
    nP: PFormCommandParam;
begin
  Result := nil;
  if GetSysValidDate < 1 then Exit;

  if not Assigned(nParam) then
  begin
    New(nP);
    FillChar(nP^, SizeOf(TFormCommandParam), #0);
  end else nP := nParam;

  try
    CreateBaseFormItem(cFI_FormGetPOrderBase, nPopedom, nP);
    if (nP.FCommand <> cCmd_ModalResult) or (nP.FParamA <> mrOK) then Exit;
    nStr := nP.FParamB;
  finally
    if not Assigned(nParam) then Dispose(nP);
  end;

  with TfFormPurchaseOrder.Create(Application) do
  try
    Caption := '���ɹ���';
    ActiveControl := EditTruck;

    FCardData.Text := PackerDecodeStr(nStr);
    InitFormData;

    if Assigned(nParam) then
    with PFormCommandParam(nParam)^ do
    begin
      FCommand := cCmd_ModalResult;
      FParamA := ShowModal;

      if FParamA = mrOK then
           FParamB := FNewBillID
      else FParamB := '';
    end else ShowModal;
  finally
    Free;
  end;
end;

class function TfFormPurchaseOrder.FormID: integer;
begin
  Result := cFI_FormOrder;
end;

procedure TfFormPurchaseOrder.FormCreate(Sender: TObject);
begin
  FListA    := TStringList.Create;
  FCardData := TStringList.Create;
  AdjustCtrlData(Self);
  LoadFormConfig(Self);
  {$IFDEF KuangFa}
  dxLayout1Item6.Visible := True;
  dxLayout1Item7.Visible := True;
  {$ELSE}
  dxLayout1Item6.Visible := False;
  dxLayout1Item7.Visible := False;
  {$ENDIF}
end;

procedure TfFormPurchaseOrder.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SaveFormConfig(Self);
  ReleaseCtrlData(Self);

  FListA.Free;
  FCardData.Free;
end;

//Desc: �س���
procedure TfFormPurchaseOrder.EditLadingKeyPress(Sender: TObject; var Key: Char);
var nP: TFormCommandParam;
begin
  if Key = Char(VK_RETURN) then
  begin
    Key := #0;

    if Sender = EditValue then
         BtnOK.Click
    else Perform(WM_NEXTDLGCTL, 0, 0);
  end;

  if (Sender = EditTruck) and (Key = Char(VK_SPACE)) then
  begin
    Key := #0;
    nP.FParamA := EditTruck.Text;
    CreateBaseFormItem(cFI_FormGetTruck, '', @nP);

    if (nP.FCommand = cCmd_ModalResult) and(nP.FParamA = mrOk) then
      EditTruck.Text := nP.FParamB;
    EditTruck.SelectAll;
  end;
end;

procedure TfFormPurchaseOrder.EditTruckPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
var nChar: Char;
begin
  nChar := Char(VK_SPACE);
  EditLadingKeyPress(EditTruck, nChar);
end;

//------------------------------------------------------------------------------
procedure TfFormPurchaseOrder.InitFormData;
begin
  with FCardData do
  begin
    EditID.Text       := Values['SQ_ID'];
    EditProvider.Text := Values['SQ_ProName'];
    EditMate.Text     := Values['SQ_StockName'];
    EditSalesMan.Text := Values['SQ_SaleName'];
    EditArea.Text     := Values['SQ_Area'];
    EditProject.Text  := Values['SQ_Project'];
    //EditValue.Text    := Values['SQ_RestValue'];
    EditValue.Text    := '0.00';
  end;
end;

function TfFormPurchaseOrder.OnVerifyCtrl(Sender: TObject; var nHint: string): Boolean;
var nVal: Double;
begin
  Result := True;

  if Sender = EditTruck then
  begin
    Result := Length(EditTruck.Text) > 2;
    nHint := '���ƺų���Ӧ����2λ';
  end else

  if Sender = EditValue then
  begin
    Result := IsNumber(EditValue.Text, True);
    nHint := '����д��Ч�İ�����';
    if not Result then Exit;

    nVal := StrToFloat(EditValue.Text);
    Result := FloatRelation(nVal, StrToFloat(FCardData.Values['SQ_RestValue']),
              rtLE);
    nHint := '�ѳ����������';
  end;
end;

//Desc: ����
procedure TfFormPurchaseOrder.BtnOKClick(Sender: TObject);
var nOrder, nCardType: string;
begin
  if not IsDataValid then Exit;
  //check valid
  {$IFDEF KuangFa}
  if IfStockHasLs(FCardData.Values['SQ_StockNo']) then
  begin
    if not IsNumber(EditKFValue.Text, True) then
    begin
      EditKFValue.SetFocus;
      ShowMsg('����д��Ч�Ŀ�����',sHint);
      Exit;
    end;

    if StrToFloat(EditKFValue.Text) < 0 then
    begin
      EditKFValue.SetFocus;
      ShowMsg('������������ڵ���0',sHint);
      Exit;
    end;

    if Trim(EditKFLS.Text) = '' then
    begin
      EditKFLS.SetFocus;
      ShowMsg('����д����ˮ',sHint);
      Exit;
    end;
  end;
  {$ENDIF}

  {$IFDEF ForceEleCard}
  {$IFDEF XXCJ}
  if not IsEleCardVaidEx(EditTruck.Text) then
  {$ELSE}
  if not IsEleCardVaid(EditTruck.Text) then
  {$ENDIF}
  begin
    ShowMsg('����δ������ӱ�ǩ����ӱ�ǩδ���ã�����ϵ����Ա', sHint); Exit;
  end;
  {$ENDIF}

  {$IFDEF OrderNoMulCard}
  if IFHasOrder(EditTruck.Text) then
  begin
    ShowMsg('��������δ��ɵĲɹ���,�޷�����,����ϵ����Ա',sHint);
    Exit;
  end;
  {$ENDIF}

  with FListA do
  begin
    Clear;
    Values['SQID']          := FCardData.Values['SQ_ID'];

    Values['Area']          := FCardData.Values['SQ_Area'];
    Values['Truck']         := Trim(EditTruck.Text);
    Values['Project']       := FCardData.Values['SQ_Project'];

    nCardType               := GetCtrlData(EditCardType);
    Values['CardType']      := nCardType;

    Values['SaleID']        := FCardData.Values['SQ_SaleID'];
    Values['SaleMan']       := FCardData.Values['SQ_SaleName'];

    Values['ProviderID']    := FCardData.Values['SQ_ProID'];
    Values['ProviderName']  := FCardData.Values['SQ_ProName'];

    Values['StockNO']       := FCardData.Values['SQ_StockNo'];
    Values['StockName']     := FCardData.Values['SQ_StockName'];
    if nCardType='L' then
          Values['Value']   := EditValue.Text
    else  Values['Value']   := '0.00';

    Values['KFValue']       := Trim(EditKFValue.Text);
    Values['KFLS']          := Trim(EditKFLS.Text);
  end;

  nOrder := SaveOrder(PackerEncodeStr(FListA.Text));
  if nOrder='' then Exit;

  if nCardType = 'L' then
    PrintRCOrderReport(nOrder, True);
  //��ʱ����ʾ��ӡ�볧

  SetOrderCard(nOrder, FListA.Values['Truck'], True);
  //����ſ�

  ModalResult := mrOK;
  ShowMsg('�ɹ���������ɹ�', sHint);
end;

initialization
  gControlManager.RegCtrl(TfFormPurchaseOrder, TfFormPurchaseOrder.FormID);
end.
