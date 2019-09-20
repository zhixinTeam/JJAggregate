unit UFrameCarrier;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, UFrameNormal, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter, cxData,
  cxDataStorage, cxEdit, DB, cxDBData, cxContainer, ADODB, cxLabel,
  UBitmapPanel, cxSplitter, dxLayoutControl, cxGridLevel, cxClasses,
  cxGridCustomView, cxGridCustomTableView, cxGridTableView,
  cxGridDBTableView, cxGrid, ComCtrls, ToolWin, USysConst;

type
  TfFrameCarrier = class(TfFrameNormal)
    procedure BtnAddClick(Sender: TObject);
    procedure BtnEditClick(Sender: TObject);
    procedure BtnDelClick(Sender: TObject);
  private
    { Private declarations }
  protected
    function InitFormDataSQL(const nWhere: string): string; override;
    {*查询SQL*}
  public
    { Public declarations }
    class function FrameID: integer; override;
  end;

var
  fFrameCarrier: TfFrameCarrier;

implementation
  uses UMgrControl, USysDB, UFormBase, UDataModule, ULibFun;
{$R *.dfm}

procedure TfFrameCarrier.BtnAddClick(Sender: TObject);
var nP: TFormCommandParam;
begin
  nP.FCommand := cCmd_AddData;
  CreateBaseFormItem(cFI_FormCarrier, '', @nP);

  if (nP.FCommand = cCmd_ModalResult) and (nP.FParamA = mrOK) then
  begin
    InitFormData('');
  end;
end;

class function TfFrameCarrier.FrameID: integer;
begin
  Result := cFI_FrameCarrier;
end;

function TfFrameCarrier.InitFormDataSQL(const nWhere: string): string;
begin
  Result := 'Select * From ' + sTable_Carrier;
  if nWhere <> '' then
    Result := Result + ' Where (' + nWhere + ')';
end;

procedure TfFrameCarrier.BtnEditClick(Sender: TObject);
var nP: TFormCommandParam;
begin
  if cxView1.DataController.GetSelectedCount > 0 then
  begin
    nP.FCommand := cCmd_EditData;
    nP.FParamA := SQLQuery.FieldByName('R_ID').AsString;
    CreateBaseFormItem(cFI_FormCarrier, '', @nP);

    if (nP.FCommand = cCmd_ModalResult) and (nP.FParamA = mrOK) then
    begin
      InitFormData(FWhere);
    end;
  end;
end;

procedure TfFrameCarrier.BtnDelClick(Sender: TObject);
var nStr,nCarrier,nEvent: string;
begin
  if cxView1.DataController.GetSelectedCount > 0 then
  begin
    nCarrier := SQLQuery.FieldByName('S_Name').AsString;
    nStr    := Format('确定要删除承运商[ %s ]吗?', [nCarrier]);
    if not QueryDlg(nStr, sAsk) then Exit;

    nStr := 'Delete From %s Where R_ID=%s';
    nStr := Format(nStr, [sTable_Carrier, SQLQuery.FieldByName('R_ID').AsString]);

    FDM.ExecuteSQL(nStr);

    nEvent := '删除[ %s ]承运商信息.';
    nEvent := Format(nEvent, [nCarrier]);
    FDM.WriteSysLog(sFlag_CommonItem, nCarrier, nEvent);

    InitFormData(FWhere);
  end;
end;

initialization
  gControlManager.RegCtrl(TfFrameCarrier, TfFrameCarrier.FrameID);

end.
