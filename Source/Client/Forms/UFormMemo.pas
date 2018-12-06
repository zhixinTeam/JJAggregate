{*******************************************************************************
  作者: dmzn@163.com 2010-4-13
  描述: 处理备注信息
*******************************************************************************}
unit UFormMemo;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, UFormNormal, cxContainer, cxEdit, cxTextEdit, cxMemo,
  dxLayoutControl, StdCtrls, cxControls, cxGraphics, cxLookAndFeels,
  cxLookAndFeelPainters;

type
  TfFormMemo = class(TfFormNormal)
    Memo1: TcxMemo;
    dxLayout1Item3: TdxLayoutItem;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  protected
    { Protected declarations }
    FSQL: string;
    FMinLength: Integer;
    procedure GetSaveSQLList(const nList: TStrings); override;
    function OnVerifyCtrl(Sender: TObject; var nHint: string): Boolean; override;
  public
    { Public declarations }
    class function CreateForm(const nPopedom: string = '';
      const nParam: Pointer = nil): TWinControl; override;
    class function FormID: integer; override;
  end;

implementation

{$R *.dfm}
uses
  ULibFun, UMgrControl, USysDB, USysConst, UFormBase;

var
  gForm: TfFormMemo = nil;
  //全局使用

//------------------------------------------------------------------------------
class function TfFormMemo.CreateForm(const nPopedom: string;
  const nParam: Pointer): TWinControl;
var nP: PFormCommandParam;
begin
  Result := nil;
  if Assigned(nParam) then
       nP := nParam
  else Exit;

  case nP.FCommand of
   cCmd_AddData:
    with TfFormMemo.Create(Application) do
    begin
      Caption := '备注 - 添加';
      Memo1.Text := nP.FParamA;
      Memo1.Properties.MaxLength := nP.FParamB;

      nP.FCommand := cCmd_ModalResult;
      nP.FParamA := ShowModal;
      if nP.FParamA = mrOK then
        nP.FParamB := Memo1.Text;
      Free;
    end;
   cCmd_EditData:
    with TfFormMemo.Create(Application) do
    begin
      Caption := '备注 - 更新';
      Memo1.Text := nP.FParamA;
      Memo1.Properties.MaxLength := nP.FParamB;

      FSQL := nP.FParamC;
      if not VarIsEmpty(nP.FParamD) then
        FMinLength := nP.FParamD;
      //xxxxx
      
      nP.FCommand := cCmd_ModalResult;
      nP.FParamA := ShowModal;
      Free;
    end;
   cCmd_ViewData:
    begin
      if not Assigned(gForm) then
      begin
        gForm := TfFormMemo.Create(Application);
        with gForm do
        begin
          Caption := '备注 - 查看';
          FormStyle := fsStayOnTop;
          
          Memo1.Properties.ReadOnly := True;
          BtnOK.Visible := False;
        end;
      end;

      with gForm  do
      begin
        Memo1.Text := nP.FParamA;
        if not Showing then Show;
      end;
    end;
   cCmd_FormClose:
    begin
      if Assigned(gForm) then FreeAndNil(gForm);
    end;
  end;
end;

class function TfFormMemo.FormID: integer;
begin
  Result := cFI_FormMemo;
end;

procedure TfFormMemo.FormCreate(Sender: TObject);
begin
  inherited;
  FMinLength := 0;
  LoadFormConfig(Self);
end;

procedure TfFormMemo.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  inherited;
  SaveFormConfig(Self);

  gForm := nil;
  Action := caFree;
end;

procedure TfFormMemo.GetSaveSQLList(const nList: TStrings);
begin
  nList.Text := MacroValue(FSQL, [MI('$Memo', Trim(Memo1.Text))]);
end;

function TfFormMemo.OnVerifyCtrl(Sender: TObject;
  var nHint: string): Boolean;
begin
  Result := True;
  if Sender = Memo1 then
  begin
    Result := (FMinLength < 1) or (FMinLength <= Length(Memo1.Text));
    nHint := '请填写备注信息';
  end;
end;

initialization
  gControlManager.RegCtrl(TfFormMemo, TfFormMemo.FormID);
end.
