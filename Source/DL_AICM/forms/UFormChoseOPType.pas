unit UFormChoseOPType;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Buttons, StdCtrls, jpeg, ExtCtrls;

type
  TFormChoseOPType = class(TForm)
    btn3: TSpeedButton;
    btn1: TSpeedButton;
    img1: TImage;
    tmrClose: TTimer;
    procedure btn3Click(Sender: TObject);
    procedure btn1Click(Sender: TObject);
    procedure tmrCloseTimer(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    nClose : Integer;
    nOrderType:string;
  end;

var
  FormChoseOPType: TFormChoseOPType;

implementation

{$R *.dfm}

uses  uZXNewCard, UFormMain, UFormBillCardHandl, uZXNewPurchaseCard, UFormPurCardHandl;



procedure TFormChoseOPType.btn3Click(Sender: TObject);
begin
  if nOrderType='Sale' then
  begin
    if not Assigned(fFormNewCard) then
    begin
      fFormNewCard := TfFormNewCard.Create(nil);
      fFormNewCard.SetControlsClear;
    end;
    Close;
    fFormNewCard.BringToFront;
    fFormNewCard.Left := fFormMain.Left;
    fFormNewCard.Top := fFormMain.Top;
    fFormNewCard.Width := fFormMain.Width;
    fFormNewCard.Height := fFormMain.Height;
    fFormNewCard.PrintHY.Visible := False;
    fFormNewCard.Show;
  end
  else
  begin
    if not Assigned(fFormNewPurchaseCard) then
    begin
      fFormNewPurchaseCard := TfFormNewPurchaseCard.Create(nil);
      fFormNewPurchaseCard.SetControlsClear;
    end;
    Close;
    fFormNewPurchaseCard.BringToFront;
    fFormNewPurchaseCard.Left := fFormMain.Left;
    fFormNewPurchaseCard.Top := fFormMain.Top;
    fFormNewPurchaseCard.Width := fFormMain.Width;
    fFormNewPurchaseCard.Height := fFormMain.Height;
    fFormNewPurchaseCard.Show;
  end;
end;

procedure TFormChoseOPType.btn1Click(Sender: TObject);
begin
  if nOrderType='Sale' then
  begin
    if not Assigned(FormBillCardHandl) then
    begin
      FormBillCardHandl := TFormBillCardHandl.Create(nil);
    end;
    FormBillCardHandl.SetControlsClear;
    FormBillCardHandl.BringToFront;
    FormBillCardHandl.Left := fFormMain.Left;
    FormBillCardHandl.Top := fFormMain.Top;
    FormBillCardHandl.Width := fFormMain.Width;
    FormBillCardHandl.Height := fFormMain.Height;
    FormBillCardHandl.Show;
  end
  else
  begin
    if not Assigned(FormPurCardHandl) then
    begin
      FormPurCardHandl := TFormPurCardHandl.Create(nil);
    end;
    FormPurCardHandl.BringToFront;
    FormPurCardHandl.Left := fFormMain.Left;
    FormPurCardHandl.Top := fFormMain.Top;
    FormPurCardHandl.Width := fFormMain.Width;
    FormPurCardHandl.Height := fFormMain.Height;
    FormPurCardHandl.Show;
  end;
  Close;
end;

procedure TFormChoseOPType.tmrCloseTimer(Sender: TObject);
begin
  if nClose<=10 then
  begin
    nClose:= nClose + 1;
    Exit;
  end;
  nClose:= 0;     tmrClose.Enabled:= False;
  Close;
end;

procedure TFormChoseOPType.FormShow(Sender: TObject);
begin
  tmrClose.Enabled:= True;
end;

end.
