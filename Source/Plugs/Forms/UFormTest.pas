unit UFormTest;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, UFormBase, StdCtrls, ExtCtrls, IdBaseComponent, IdComponent,
  IdTCPConnection, IdTCPClient, IdHTTP, IdGlobalProtocols;

type
  TBaseForm1 = class(TBaseForm)
    Memo1: TMemo;
    Panel1: TPanel;
    Button1: TButton;
    Edit1: TEdit;
    IdHTTP1: TIdHTTP;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
    FListA,FListB: TStrings;
  public
    { Public declarations }
    class function CreateForm(const nPopedom: string = '';
      const nParam: Pointer = nil): TFormCreateResult; override;
    class function FormID: integer; override;
    function ServerNow: string;
    function GetSerialNo(const nGroup,nObject: string): string;
    function IsSystemExpired: string;
    function WXQueryData(const nSQL: string): string;
  end;

implementation

{$R *.dfm}
uses
  UBusinessWorker, UBusinessPacker, UBusinessConst, UMgrControl, UMgrDBConn,
  UPlugConst, USysDB, ULibFun, UWorkerBussinessWechat, UMgrChannel, UBase64,
  IdGlobal, HTTPApp, NativeXml;
  
var
  gForm: TBaseForm1 = nil;

class function TBaseForm1.CreateForm(const nPopedom: string;
  const nParam: Pointer): TFormCreateResult;
begin
  if not Assigned(gForm) then
    gForm := TBaseForm1.Create(Application);
  //xxxxx
  
  Result.FFormItem := gForm;
  gForm.Show;
end;

class function TBaseForm1.FormID: integer;
begin
  Result := cFI_FormTest1;
end;

procedure TBaseForm1.FormCreate(Sender: TObject);
begin
  FListA := TStringList.Create;
  FListB := TStringList.Create;
end;

procedure TBaseForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  gForm := nil;
  FListA.Free;
  FListB.Free;
end;

//------------------------------------------------------------------------------
function CallBusinessCommand(const nCmd: Integer; const nData,nParma: string;
  const nOut: PWorkerBusinessCommand): Boolean;
var nStr: string;
    nIn: TWorkerBusinessCommand;
    nPack: TBusinessPackerBase;
    nWorker: TBusinessWorkerBase;
begin
  nPack := nil;
  nWorker := nil;
  try
    nPack := gBusinessPackerManager.LockPacker(sBus_BusinessCommand);
    nWorker := gBusinessWorkerManager.LockWorker(sBus_BusinessCommand);

    nIn.FCommand := nCmd;
    nIn.FData := nData;
    nIn.FExtParam := nParma;
    nStr := nPack.PackIn(@nIn);

    Result := nWorker.WorkActive(nStr);
    if not Result then
    begin
      ShowDlg(nStr, sWarn);
      Exit;
    end;

    nPack.UnPackOut(nStr, nOut);
  finally
    gBusinessPackerManager.RelasePacker(nPack);
    gBusinessWorkerManager.RelaseWorker(nWorker);
  end;
end;

function CallBusinessBills(const nCmd: Integer; const nData,nParma: string;
  const nOut: PWorkerBusinessCommand): Boolean;
var nStr: string;
    nIn: TWorkerBusinessCommand;
    nPack: TBusinessPackerBase;
    nWorker: TBusinessWorkerBase;
begin
  nPack := nil;
  nWorker := nil;
  try
    nPack := gBusinessPackerManager.LockPacker(sBus_BusinessCommand);
    nWorker := gBusinessWorkerManager.LockWorker(sBus_BusinessSaleBill);

    nIn.FCommand := nCmd;
    nIn.FData := nData;
    nIn.FExtParam := nParma;
    nStr := nPack.PackIn(@nIn);

    Result := nWorker.WorkActive(nStr);
    if not Result then
    begin
      ShowDlg(nStr, sWarn);
      Exit;
    end;

    nPack.UnPackOut(nStr, nOut);
  finally
    gBusinessPackerManager.RelasePacker(nPack);
    gBusinessWorkerManager.RelaseWorker(nWorker);
  end;
end;

function CallBusinessWechat(const nCmd: Integer; const nData,nParma: string;
  const nOut: PWorkerBusinessCommand): Boolean;
var nStr: string;
    nWorker: TBusinessWorkerBase;
begin
  nWorker := nil;
  try
    nWorker := gBusinessWorkerManager.LockWorker(sBus_BusinessWechat);
    nStr := '<xml><head><command>%s</command><data>%s</data>' +
            '<param>%s</param></head></xml>';
    nStr := Format(nStr, [IntToHex(nCmd, 2), nData, nParma]);

    Result := nWorker.WorkActive(nStr);
    nOut.FData := nStr;
  finally
    gBusinessWorkerManager.RelaseWorker(nWorker);
  end;
end;

//------------------------------------------------------------------------------
function TBaseForm1.GetSerialNo(const nGroup,nObject: string): string;
var nOut: TWorkerBusinessCommand;
begin
  FListA.Values['Group'] := nGroup;
  FListA.Values['Object'] := nObject;

  if CallBusinessCommand(cBC_GetSerialNO, FListA.Text, sFlag_Yes, @nOut) then
    Result := nOut.FData;
  //xxxxx
end;

function TBaseForm1.ServerNow: string;
var nOut: TWorkerBusinessCommand;
begin
  if CallBusinessCommand(cBC_ServerNow, '', '', @nOut) then
    Result := nOut.FData;
  //xxxxx
end;

function TBaseForm1.IsSystemExpired: string;
var nOut: TWorkerBusinessCommand;
begin
  if CallBusinessCommand(cBC_IsSystemExpired, '', '', @nOut) then
    Result := nOut.FData;
  //xxxxx
end;

function TBaseForm1.WXQueryData(const nSQL: string): string;
var nOut: TWorkerBusinessCommand;
begin
  TBusWorkerBusinessWechat.CallMe(cBC_WX_MakeZhiKa, nSQL, '', Result);
  Result := UnEscapeStringANSI(Result);
end;

//------------------------------------------------------------------------------
procedure TBaseForm1.Button1Click(Sender: TObject);
begin
  Memo1.Text := WXQueryData(Edit1.Text);
end;

procedure TBaseForm1.Button2Click(Sender: TObject);
var nStr: string;
begin
  TBusWorkerBusinessWechat.CallRemote('apiQuerySql', Edit1.Text, nStr);
  Memo1.Text := nStr;
end;

initialization
  gControlManager.RegCtrl(TBaseForm1, TBaseForm1.FormID);
end.
