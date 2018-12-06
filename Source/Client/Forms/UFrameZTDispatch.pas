{*******************************************************************************
  ����: dmzn@163.com 2012-3-26
  ����: ջ̨�Ŷӳ�������
*******************************************************************************}
unit UFrameZTDispatch;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  USysBusiness, UFrameBase, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxContainer, cxEdit, Menus, dxorgchr, cxLabel,
  UBitmapPanel, ComCtrls, ToolWin, ExtCtrls;

type
  TfFrameZTDispatch = class(TBaseFrame)
    ToolBar1: TToolBar;
    BtnAdd: TToolButton;
    S1: TToolButton;
    BtnRefresh: TToolButton;
    BtnPrint: TToolButton;
    S3: TToolButton;
    BtnExit: TToolButton;
    TitlePanel1: TZnBitmapPanel;
    TitleBar: TcxLabel;
    dxChart1: TdxOrgChart;
    Bevel1: TBevel;
    PMenu1: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    N5: TMenuItem;
    N6: TMenuItem;
    procedure ToolBar1AdvancedCustomDraw(Sender: TToolBar;
      const ARect: TRect; Stage: TCustomDrawStage;
      var DefaultDraw: Boolean);
    procedure BtnExitClick(Sender: TObject);
    procedure BtnRefreshClick(Sender: TObject);
    procedure dxChart1Collapsing(Sender: TObject; Node: TdxOcNode;
      var Allow: Boolean);
    procedure dxChart1Expanded(Sender: TObject; Node: TdxOcNode);
    procedure N1Click(Sender: TObject);
    procedure PMenu1Popup(Sender: TObject);
    procedure BtnAddClick(Sender: TObject);
    procedure N3Click(Sender: TObject);
    procedure N5Click(Sender: TObject);
    procedure BtnPrintClick(Sender: TObject);
  private
    { Private declarations }
    FLastRefresh: Int64;
    //�ϴ�ˢ��
    FBarImage: TBitmap;
    //������
    FLines: TZTLineItems;
    FTrucks: TZTTruckItems;
    //��������
    procedure RefreshData(const nRefreshLine: Boolean);
    //ˢ�¶���
    function FindNode(const nID: string): TdxOcNode;
    //�����ڵ�
    procedure InitZTLineItem(const nNode: TdxOcNode);
    procedure InitZTTruckItem(const nNode: TdxOcNode);
    //�ڵ���
  public
    { Public declarations }
    function FrameTitle: string; override;
    procedure OnCreateFrame; override;
    procedure OnLoadPopedom; override;
    procedure OnDestroyFrame; override;
    class function FrameID: integer; override;
  end;

implementation

{$R *.dfm}
uses
  IniFiles, ULibFun, UMgrControl, UFormWait, UFormZTLine, UFormZTMode,
  USysDB, USysConst, USysFun, USysPopedom, UDataModule, USysLoger;

class function TfFrameZTDispatch.FrameID: integer;
begin
  Result := cFI_FrameZTDispatch;
end;

function TfFrameZTDispatch.FrameTitle: string;
begin
  Result := TitleBar.Caption;
end;

procedure TfFrameZTDispatch.OnCreateFrame;
var nStr: string;
    nIni: TIniFile;
begin
  nIni := TIniFile.Create(gPath + sFormConfig);
  try
    nStr := gPath + sImageDir + 'title.bmp';
    nStr := ReplaceGlobalPath(nIni.ReadString(Name, 'TitleImage', nStr));
    if FileExists(nStr) then TitlePanel1.LoadBitmap(nStr);

    nStr := gPath + sImageDir + 'bar.bmp';
    nStr := ReplaceGlobalPath(nIni.ReadString(Name, 'BarImage', nStr));
    if FileExists(nStr) then
    begin
      FBarImage := TBitmap.Create;
      FBarImage.LoadFromFile(nStr);
    end else FBarImage := nil;
  finally
    nIni.Free;
  end;
end;

procedure TfFrameZTDispatch.OnDestroyFrame;
begin
  FreeAndNil(FBarImage);
end;

procedure TfFrameZTDispatch.OnLoadPopedom;
begin
  BtnAdd.Enabled := gPopedomManager.HasPopedom(PopedomItem, sPopedom_Add);
  BtnPrint.Enabled := gPopedomManager.HasPopedom(PopedomItem, sPopedom_Print);
end;

procedure TfFrameZTDispatch.BtnExitClick(Sender: TObject);
begin
  Close(); 
end;

//------------------------------------------------------------------------------
//Desc: ���ƹ���������
procedure TfFrameZTDispatch.ToolBar1AdvancedCustomDraw(Sender: TToolBar;
  const ARect: TRect; Stage: TCustomDrawStage; var DefaultDraw: Boolean);
var nRect: TRect;
begin
  if (not Assigned(FBarImage)) or (FBarImage.Width < 1) then Exit;
  nRect := Rect(ARect.Left, ARect.Top, 0, ARect.Bottom);

  while nRect.Right < ARect.Right do
  begin
    nRect.Right := nRect.Left + FBarImage.Width;
    ToolBar1.Canvas.StretchDraw(nRect, FBarImage);
    nRect.Left := nRect.Left + FBarImage.Width;
  end;
end;

procedure TfFrameZTDispatch.dxChart1Collapsing(Sender: TObject;
  Node: TdxOcNode; var Allow: Boolean);
begin
  Allow := Node.Level = 0;
end;

procedure TfFrameZTDispatch.dxChart1Expanded(Sender: TObject;
  Node: TdxOcNode);
begin
  if Node.Level = 0 then Node.Expand(True);
end;

//------------------------------------------------------------------------------
//Desc: ˢ�½���
procedure TfFrameZTDispatch.BtnRefreshClick(Sender: TObject);
begin
  if GetTickCount - FLastRefresh >= 1.5 * 1000 then
       RefreshData(False)
  else ShowMsg('�벻ҪƵ��ˢ��', sHint);
end;

//Desc: ���װ����
procedure TfFrameZTDispatch.BtnAddClick(Sender: TObject);
begin
  if ShowAddZTLineForm then RefreshData(True);
end;

//Desc: �޸�װ����
procedure TfFrameZTDispatch.N1Click(Sender: TObject);
var nInt: Integer;
    nStr: string;
begin
  nInt := Integer(dxChart1.Selected.Data);
  nStr := FLines[nInt].FID;

  if ShowEditZTLineForm(nStr) then
    RefreshData(True);
  //xxxxx
end;

//Desc: ģʽ����
procedure TfFrameZTDispatch.BtnPrintClick(Sender: TObject);
begin
  ShowZTModeForm;
end;

//Desc: Ȩ�޿���
procedure TfFrameZTDispatch.PMenu1Popup(Sender: TObject);
var nInt: Integer;
begin
  N1.Enabled := gPopedomManager.HasPopedom(PopedomItem, sPopedom_Edit) and
                Assigned(dxChart1.Selected) and (dxChart1.Selected.Level = 0);
  //����Ա�޸�ͨ��

  N3.Enabled := Assigned(dxChart1.Selected) and (dxChart1.Selected.Level > 0);
  //�Ƴ�����

  N5.Enabled := gPopedomManager.HasPopedom(PopedomItem, sPopedom_Edit) and
                Assigned(dxChart1.Selected) and (dxChart1.Selected.Level = 0);
  N6.Enabled := N5.Enabled;
  //�������ͣ

  if Assigned(dxChart1.Selected) then
  begin
    nInt := Integer(dxChart1.Selected.Data);
    N5.Checked := FLines[nInt].FPrinterOK;
    N6.Checked := not N5.Checked;
  end;
end;

//------------------------------------------------------------------------------
//Desc: ������ʶΪnID�ļ�¼
function TfFrameZTDispatch.FindNode(const nID: string): TdxOcNode;
var nIdx: Integer;
    nP: TdxOcNode;
begin
  Result := nil;
  nP := dxChart1.GetFirstNode;

  while Assigned(nP) do
  begin
    nIdx := Integer(nP.Data);
    //��������

    if nP.Level = 0 then
    begin
      if CompareText(nID, FLines[nIdx].FID) = 0 then
      begin
        Result := nP;
        Exit;
      end;
    end else
    begin
      if CompareText(nID, FTrucks[nIdx].FTruck) = 0 then
      begin
        Result := nP;
        Exit;
      end;
    end;

    nP := nP.GetNext;
  end;
end;

//Desc: ����װ���߽ڵ���
procedure TfFrameZTDispatch.InitZTLineItem(const nNode: TdxOcNode);
var nInt: Integer;
begin
  nNode.Width := 75;
  nNode.Height := 32;

  nInt := Integer(nNode.Data);
  with FLines[nInt] do
  begin
    nNode.Text := FName;
    if FValid then
         nNode.Color := clWhite
    else nNode.Color := clSilver;
  end;
end;

//Desc: ���ó����ڵ���
procedure TfFrameZTDispatch.InitZTTruckItem(const nNode: TdxOcNode);
var nInt: Integer;
begin
  nNode.Width := 75;
  nNode.Height := 32;
  
  nInt := Integer(nNode.Data);
  with FTrucks[nInt] do
  begin
    nNode.Text := FTruck;
    nNode.Shape := shRoundRect;

    if FInFact then
    begin
      if FIsRun then
           nNode.Color := clGreen
      else nNode.Color := clSkyBlue;
    end else nNode.Color := clSilver;
  end;
end;

//Desc: ��ȡnNode���һ���ڵ�
function GetLastChild(const nNode: TdxOcNode): TdxOcNode;
var nTmp: TdxOcNode;
begin
  Result := nNode.GetFirstChild;
  if not Assigned(Result) then
    Result := nNode;
  //xxxxx

  while Assigned(Result) do
  begin
    nTmp := Result.GetFirstChild;
    if Assigned(nTmp) then
         Result := nTmp
    else Break;
  end;
end;

//Desc: ˢ������
procedure TfFrameZTDispatch.RefreshData(const nRefreshLine: Boolean);
var nIdx: Integer;
    nP: TdxOcNode;
begin
  ShowWaitForm(ParentForm, '��ȡ����');
  try
    if not LoadTruckQueue(FLines, FTrucks, nRefreshLine) then Exit;
    FLastRefresh := GetTickCount;
  finally
    CloseWaitForm;
  end;

  dxChart1.BeginUpdate;
  try
    dxChart1.Clear;
    for nIdx:=Low(FLines) to High(FLines) do
    begin
      nP := dxChart1.AddChild(nil, Pointer(nIdx));
      InitZTLineItem(nP);
    end;

    for nIdx:=Low(FTrucks) to High(FTrucks) do
    begin
      nP := FindNode(FTrucks[nIdx].FLine);
      if not Assigned(nP) then Continue;

      nP := dxChart1.AddChild(GetLastChild(nP), Pointer(nIdx));
      InitZTTruckItem(nP);
    end;
  finally
    dxChart1.FullExpand;
    dxChart1.EndUpdate;
  end;
end;

//Desc: ���Ӳ���
procedure TfFrameZTDispatch.N3Click(Sender: TObject);
var nStr,nEvent: string;
begin
  with FTrucks[Integer(dxChart1.Selected.Data)] do
  begin
    nStr := 'Update %s Set T_Valid=''%s'' Where T_Bill=''%s'' ';
    nStr := Format(nStr, [sTable_ZTTrucks, sFlag_No, FBill]);

    FDM.ExecuteSQL(nStr);

    nStr := FBill;
    nEvent := '������[ %s ]�Ƴ�����.';
    nEvent := Format(nEvent, [FBill]);
    FDM.WriteSysLog(sFlag_TruckQueue, nStr, nEvent);

    RefreshData(False);
    ShowMsg('���ӳɹ�', sHint);
  end;
end;

//Desc: ��ͣ�����
procedure TfFrameZTDispatch.N5Click(Sender: TObject);
var nStr: string;
    nInt: Integer;
    nMenu: TMenuItem; 
begin
  nMenu := Sender as TMenuItem;
  nInt := Integer(dxChart1.Selected.Data);
  nStr :=  FLines[nInt].FName;

  if nMenu.Tag = 10 then
  begin
    if QueryDlg('ȷ��Ҫ����['+ nstr +']װ�����������', '��ʾ') then
    begin
      FLines[nInt].FPrinterOK := nMenu.Tag = 10;
      PrinterEnable(FLines[nInt].FID, FLines[nInt].FPrinterOK);
    end;
  end;

  if nMenu.Tag =  20 then
  begin
    if QueryDlg('ȷ��Ҫ�ر�['+ nstr +']װ�����������', '��ʾ') then
    begin
      FLines[nInt].FPrinterOK := nMenu.Tag = 10;
      PrinterEnable(FLines[nInt].FID,FLines[nInt].FPrinterOK);
    end;
  end;
end;

initialization
  gControlManager.RegCtrl(TfFrameZTDispatch, TfFrameZTDispatch.FrameID);
end.
