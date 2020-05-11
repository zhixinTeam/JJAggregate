program DL_AICM;

uses
  Forms,
  USysModule,
  UMITPacker,
  UDataModule in 'forms\UDataModule.pas' {FDM: TDataModule},
  UFormMain in 'forms\UFormMain.pas' {fFormMain},
  uReadCardThread in 'uReadCardThread.pas',
  UFormChoseOPType in 'forms\UFormChoseOPType.pas' {FormChoseOPType},
  UFormBillCardHandl in 'forms\UFormBillCardHandl.pas' {FormBillCardHandl};

{$R *.res}

begin
  Application.Initialize;
  InitSystemObject;
  Application.CreateForm(TFDM, FDM);
  Application.CreateForm(TfFormMain, fFormMain);
  Application.CreateForm(TFormChoseOPType, FormChoseOPType);
  Application.CreateForm(TFormBillCardHandl, FormBillCardHandl);
  Application.Run;
end.
