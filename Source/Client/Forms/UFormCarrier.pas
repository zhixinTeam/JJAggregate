{*******************************************************************************
  ����: dmzn@163.com 2014-11-25
  ����: �����̹���
*******************************************************************************}
unit UFormCarrier;

{$I Link.Inc}
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  UFormBase, UFormNormal, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, cxMaskEdit, cxDropDownEdit,
  cxTextEdit, dxLayoutControl, StdCtrls, cxCheckBox;

type
  TfFormCarrier = class(TfFormNormal)
    EditCarrier: TcxTextEdit;
    dxLayout1Item5: TdxLayoutItem;
    procedure BtnOKClick(Sender: TObject);
  protected
    { Protected declarations }
    FCarrier: string;
    procedure LoadFormData(const nID: string);
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

class function TfFormCarrier.CreateForm(const nPopedom: string;
  const nParam: Pointer): TWinControl;
var nP: PFormCommandParam;
begin
  Result := nil;
  if Assigned(nParam) then
       nP := nParam
  else Exit;
  
  with TfFormCarrier.Create(Application) do
  try
    if nP.FCommand = cCmd_AddData then
    begin
      Caption := '������ - ���';
      FCarrier := '';
    end;

    if nP.FCommand = cCmd_EditData then
    begin
      Caption := '������ - �޸�';
      FCarrier := nP.FParamA;
    end;

    LoadFormData(FCarrier); 
    nP.FCommand := cCmd_ModalResult;
    nP.FParamA := ShowModal;
  finally
    Free;
  end;
end;

class function TfFormCarrier.FormID: integer;
begin
  Result := cFI_FormCarrier;
end;

procedure TfFormCarrier.LoadFormData(const nID: string);
var nStr: string;
begin
  if nID <> '' then
  begin
    nStr := 'Select * From %s Where R_ID=%s';
    nStr := Format(nStr, [sTable_Carrier, nID]);
    FDM.QueryTemp(nStr);
  end;

  with FDM.SqlTemp do
  begin
    if (nID = '') or (RecordCount < 1) then
    begin
      Exit;
    end;

    EditCarrier.Text := FieldByName('S_Name').AsString;
  end;
end;

//Desc: ����
procedure TfFormCarrier.BtnOKClick(Sender: TObject);
var nStr,nCarrier,nU,nV,nP,nVip,nGps,nEvent: string;
begin
  nCarrier := UpperCase(Trim(EditCarrier.Text));
  if nCarrier = '' then
  begin
    ActiveControl := EditCarrier;
    ShowMsg('���������������', sHint);
    Exit;
  end;
  if FCarrier = '' then
  begin
    nStr := ' select S_Name from %s where S_Name = ''%s'' ';
    nStr := Format(nStr,[sTable_Carrier, nCarrier]);
    with FDM.QuerySQL(nStr) do
    begin
      if RecordCount>0 then
      begin
        ActiveControl := EditCarrier;
        ShowMsg('�Ѵ��ڴ˳�����', sHint);
        Exit;
      end;
    end;
  end;
  
  if FCarrier = '' then
       nStr := ''
  else nStr := SF('R_ID', FCarrier, sfVal);

  nStr := MakeSQLByStr([SF('S_Name', nCarrier)
          ], sTable_Carrier, nStr, FCarrier = '');
  FDM.ExecuteSQL(nStr);

  if FCarrier = '' then
        nEvent := '���[ %s ]��������Ϣ.'
  else  nEvent := '�޸�[ %s ]��������Ϣ.';
  nEvent := Format(nEvent, [nCarrier]);
  FDM.WriteSysLog(sFlag_CommonItem, nCarrier, nEvent);


  ModalResult := mrOk;
  ShowMsg('��������Ϣ����ɹ�', sHint);
end;

initialization
  gControlManager.RegCtrl(TfFormCarrier, TfFormCarrier.FormID);
end.
