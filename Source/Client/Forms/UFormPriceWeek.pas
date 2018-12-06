{*******************************************************************************
  作者: dmzn@163.com 2018-12-03
  描述: 销售价格周期
*******************************************************************************}
unit UFormPriceWeek;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, UFormNormal, dxLayoutControl, StdCtrls, cxControls, cxMemo,
  cxButtonEdit, cxLabel, cxTextEdit, cxContainer, cxEdit, cxMaskEdit,
  cxDropDownEdit, cxCalendar, cxGraphics, cxLookAndFeels,
  cxLookAndFeelPainters, cxCheckBox;

type
  TfFormPriceWeek = class(TfFormNormal)
    dxLayout1Item4: TdxLayoutItem;
    EditName: TcxTextEdit;
    dxLayout1Item12: TdxLayoutItem;
    EditMemo: TcxMemo;
    EditStart: TcxDateEdit;
    dxLayout1Item3: TdxLayoutItem;
    EditEnd: TcxDateEdit;
    dxLayout1Item5: TdxLayoutItem;
    Check1: TcxCheckBox;
    dxLayout1Item6: TdxLayoutItem;
    dxLayout1Group2: TdxLayoutGroup;
    Check2: TcxCheckBox;
    dxLayout1Item7: TdxLayoutItem;
    cxLabel1: TcxLabel;
    dxLayout1Item8: TdxLayoutItem;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure BtnOKClick(Sender: TObject);
    procedure Check2PropertiesChange(Sender: TObject);
  private
    { Private declarations }
    FRecordID: string;
    //记录编号
    procedure InitFormData(const nID: string);
    //载入数据
    function SetData(Sender: TObject; const nData: string): Boolean;
    //设置数据
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
  ULibFun, UFormBase, UMgrControl, UDataModule, UFormCtrl, USysDB, USysConst,
  USysBusiness;

class function TfFormPriceWeek.CreateForm(const nPopedom: string;
  const nParam: Pointer): TWinControl;
var nP: PFormCommandParam;
begin
  Result := nil;
  if Assigned(nParam) then
       nP := nParam
  else Exit;

  case nP.FCommand of
   cCmd_AddData:
    with TfFormPriceWeek.Create(Application) do
    begin
      Caption := '价格周期 - 添加';
      FRecordID := '';
      InitFormData(FRecordID);

      nP.FCommand := cCmd_ModalResult;
      nP.FParamA := ShowModal;
      Free;
    end;
   cCmd_EditData:
    with TfFormPriceWeek.Create(Application) do
    begin
      Caption := '价格周期 - 修改';
      FRecordID := nP.FParamA;
      InitFormData(FRecordID);

      nP.FCommand := cCmd_ModalResult;
      nP.FParamA := ShowModal;
      Free;
    end;
  end;
end;

class function TfFormPriceWeek.FormID: integer;
begin
  Result := cFI_FormPriceWeek;
end;

procedure TfFormPriceWeek.FormCreate(Sender: TObject);
begin
  LoadFormConfig(Self);
end;

procedure TfFormPriceWeek.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  SaveFormConfig(Self);
  Action := caFree;
end;

//------------------------------------------------------------------------------
function TfFormPriceWeek.SetData(Sender: TObject; const nData: string): Boolean;
begin
  Result := False;

  if Sender = EditStart then
  begin
    EditStart.Date := Str2DateTime(nData);
    Result := True;
  end else

  if Sender = EditEnd then
  begin
    EditEnd.Date := Str2DateTime(nData);
    Result := True;

    Check2.Checked := EditEnd.Date < gSysParam.FMaxDate;
    EditEnd.Enabled := Check2.Checked;
  end else

  if Sender = Check1 then
  begin
    Check1.Checked := nData = sFlag_Yes;
    Result := True;
  end;
end;

procedure TfFormPriceWeek.InitFormData(const nID: string);
var nStr: string;
begin
  ActiveControl := EditName;
  
  if nID = '' then
  begin
    EditStart.Date := Date() + 1;
    EditEnd.Date := gSysParam.FMaxDate;

    Check1.Checked := True;
    Check2.Checked := False;
    EditEnd.Enabled := False;
  end else
  begin
    nStr := 'Select * From %s Where W_NO=''%s''';
    nStr := Format(nStr, [sTable_PriceWeek, nID]);
    LoadDataToCtrl(FDM.QueryTemp(nStr), Self, '', SetData);
  end;
end;

procedure TfFormPriceWeek.Check2PropertiesChange(Sender: TObject);
begin
  if ActiveControl <> Check2 then Exit;
  //非认为操作不予处理

  if Check2.Checked then
  begin
    EditEnd.Enabled := True;
    EditEnd.Date := Date() + 7;
  end else
  begin
    EditEnd.Enabled := False;
    EditEnd.Date := gSysParam.FMaxDate;
  end;
end;

function TfFormPriceWeek.OnVerifyCtrl(Sender: TObject;
  var nHint: string): Boolean;
var nStr: string;
begin
  Result := True;

  if Sender = EditName then
  begin
    EditName.Text := Trim(EditName.Text);
    Result := EditName.Text <> '';
    nHint := '请填写有效的名称';
  end else

  if Sender = EditStart then
  begin
    Result := EditStart.Date <= EditEnd.Date;
    nHint := '结束日期应大于开始日期';
    if not Result then Exit;

    if not Check2.Checked then Exit;
    nStr := 'Select Count(*) From %s Where W_Valid=''%s'' And ' +
            '(W_Begin<=''%s'' and W_End>''%s'')';
    nStr := Format(nStr, [sTable_PriceWeek, sFlag_Yes,
            DateTime2Str(EditEnd.Date), DateTime2Str(EditEnd.Date)]);
    //临时价结束时,有可用的长期价
    
    with FDM.QueryTemp(nStr) do
    if RecordCount > 0 then
    begin
      Result := Fields[0].AsInteger > 0;
      if Result then Exit;

      nStr := '本周期结束后没有可用的价格,会导致客户无法提货.' + #13#10 +
              '请修改"开始、结束"日期后再保存.';
      ShowDlg(nStr, sHint);
    end;
  end;
end;

//Desc: 保存
procedure TfFormPriceWeek.BtnOKClick(Sender: TObject);
var nStr,nID: string;
begin
  if not IsDataValid then Exit;

  if FRecordID = '' then
       nID := GetSerialNo(sFlag_BusGroup, sFlag_PriceWeek, False)
  else nID := FRecordID;

  if nID = '' then Exit;
  nStr := MakeSQLByStr([SF('W_Name', EditName.Text),
          SF('W_Begin', EditStart.Date, sfDateTime),
          SF('W_End', EditEnd.Date, sfDateTime),
          SF('W_Memo', EditMemo.Text),
          SF('W_Man', gSysParam.FUserID),
          SF('W_Date', FDM.SQLServerNow, sfVal),

          SF_IF([SF('W_Valid', sFlag_Yes),
                 SF('W_Valid', sFlag_No)], Check1.Checked),
          SF_IF([SF('W_NO', nID), ''], FRecordID = '')
          ], sTable_PriceWeek, SF('W_NO', FRecordID), FRecordID = '');
  //xxxxx

  FDM.ExecuteSQL(nStr);
  ModalResult := mrOK;
  ShowMsg('记录保存成功', sHint);
end;

initialization
  gControlManager.RegCtrl(TfFormPriceWeek, TfFormPriceWeek.FormID);
end.
