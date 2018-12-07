{*******************************************************************************
  作者: dmzn@163.com 2018-12-03
  描述: 查看价格周期
*******************************************************************************}
unit UFormPriceView;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, UFormNormal, dxLayoutControl, StdCtrls, cxControls, cxMemo,
  cxButtonEdit, cxLabel, cxTextEdit, cxContainer, cxEdit, cxMaskEdit,
  cxDropDownEdit, cxCalendar, cxGraphics, cxLookAndFeels,
  cxLookAndFeelPainters, cxCheckBox, ExtCtrls, TeeProcs, TeEngine, Chart,
  Series, GanttCh;

type
  TWeekItem = record
    FName: string;
    FDateStart: TDateTime;
    FDateEnd: TDateTime;
    FLimited: Boolean;
  end;
  TWeekItems = array of TWeekItem;

  TfFormPriceView = class(TfFormNormal)
    cxLabel1: TcxLabel;
    dxLayout1Item8: TdxLayoutItem;
    Chart1: TChart;
    dxLayout1Item3: TdxLayoutItem;
    Series1: TGanttSeries;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Chart1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
  private
    { Private declarations }
    FStart,FEnd: TDateTime;
    FItems: TWeekItems;
    procedure InitFormData();
    //载入数据
  public
    { Public declarations }
    class function CreateForm(const nPopedom: string = '';
      const nParam: Pointer = nil): TWinControl; override;
    class function FormID: integer; override;
  end;

implementation

{$R *.dfm}
uses
  ULibFun, UFormBase, UMgrControl, UDataModule, UFormCtrl, USysDB, USysConst,
  USysBusiness, USysFun;

class function TfFormPriceView.CreateForm(const nPopedom: string;
  const nParam: Pointer): TWinControl;
var nP: PFormCommandParam;
begin
  Result := nil;
  if Assigned(nParam) then
       nP := nParam
  else Exit;

  with TfFormPriceView.Create(Application) do
  begin
    Caption := '价格周期 - 查看';
    FStart := nP.FParamA;
    FEnd := nP.FParamB;

    InitFormData();
    ShowModal;
    Free;
  end;
end;

class function TfFormPriceView.FormID: integer;
begin
  Result := cFI_FormViewPriceWeek;
end;

procedure TfFormPriceView.FormCreate(Sender: TObject);
begin
  LoadFormConfig(Self);
  InitGanttStyle(Chart1, '价格周期');
end;

procedure TfFormPriceView.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  SaveFormConfig(Self);
  Action := caFree;
end;

procedure TfFormPriceView.InitFormData();
var nStr: string;
    nMax: TDateTime;
    i,nIdx: Integer;
begin
  Series1.Clear;
  SetLength(FItems, 0);

  nStr := 'Select W_Name,W_Begin,W_End,W_EndUse From $PW ' +
          'Where (W_Date>=''$S'' and W_Date <''$E'') Or ' +
          '      (W_Begin>=''$S'' and W_Begin <''$E'') ' +
          'Order By W_Begin ASC';
  nStr := MacroValue(nStr, [MI('$PW', sTable_PriceWeek), MI('$F', sFlag_Yes),
          MI('$S', DateTime2Str(FStart)), MI('$E', DateTime2Str(FEnd + 1))]);
  //xxxxx

  with FDM.QueryTemp(nStr) do
  if RecordCount > 0 then
  begin
    SetLength(FItems, RecordCount);
    nIdx := 0;
    First;

    while not Eof do
    begin
      with FItems[nIdx] do
      begin
        FName := FieldByName('W_Name').AsString;
        FDateStart := FieldByName('W_Begin').AsDateTime;
        FDateEnd := FieldByName('W_End').AsDateTime;
        FLimited := FieldByName('W_EndUse').AsString = sFlag_Yes;
      end;

      Next;
      Inc(nIdx);
    end;
  end;

  for nIdx:=Low(FItems) to High(FItems) do
  begin
    if FItems[nIdx].FDateEnd < gSysParam.FMaxDate then Continue;
    //临时价格

    for i:=nIdx+1 to High(FItems) do
    begin
      if FItems[i].FDateEnd < gSysParam.FMaxDate then Continue;
      //临时价格

      FItems[nIdx].FDateEnd := FItems[i].FDateStart;
      //下一个开始是上一个结束
      Break;
    end;
  end;

  nMax := FEnd;
  for i:=Low(FItems) to High(FItems) do
  begin
    if FItems[i].FLimited then
    begin
      if FItems[i].FDateEnd > nMax then
        nMax := FItems[i].FDateEnd;
      //xxxxx
    end else
    begin
      if FItems[i].FDateStart > nMax then
        nMax := FItems[i].FDateStart;
      //xxxxx
    end;
  end;

  i := 0;
  for nIdx:=Low(FItems) to High(FItems) do
  with FItems[nIdx] do
  begin
    if FDateEnd > nMax then
      FDateEnd := nMax + 20;
    //xxxxx

    if FItems[i].FLimited then
         Series1.AddGanttColor(FDateStart, FDateEnd, i, FName, clSkyBlue)
    else Series1.AddGanttColor(FDateStart, FDateEnd, i, FName, clMoneyGreen);
    Inc(i);
  end;
end;

procedure TfFormPriceView.Chart1MouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var nIdx: Integer;
begin
  nIdx := Series1.GetCursorValueIndex;
  if nIdx >= 0 then
  begin
    dxGroup1.Caption := '名称:' + Series1.ValueMarkText[nIdx] + ' ' +
                        '时间:' + DateTime2Str(Series1.XScreenToValue(X));
  end else
  begin
    dxGroup1.Caption := DateTime2Str(Series1.XScreenToValue(X));
  end;
end;

initialization
  gControlManager.RegCtrl(TfFormPriceView, TfFormPriceView.FormID);
end.
