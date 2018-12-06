{*******************************************************************************
  ����: dmzn@163.com 2012-03-26
  ����: �������Ȳ�ѯ
*******************************************************************************}
unit UFrameQueryDiapatch;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  UFrameNormal, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, cxStyles, cxCustomData, cxFilter, cxData,
  cxDataStorage, cxEdit, DB, cxDBData, cxContainer, cxMaskEdit,
  cxButtonEdit, dxLayoutControl, cxTextEdit, Menus, ADODB, cxLabel,
  UBitmapPanel, cxSplitter, cxGridLevel, cxClasses, cxGridCustomView,
  cxGridCustomTableView, cxGridTableView, cxGridDBTableView, cxGrid,
  ComCtrls, ToolWin;

type
  TfFrameQueryDispatch = class(TfFrameNormal)
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N5: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    N6: TMenuItem;
    N7: TMenuItem;
    N8: TMenuItem;
    N9: TMenuItem;
    N10: TMenuItem;
    N11: TMenuItem;
    cxTextEdit5: TcxTextEdit;
    dxLayout1Item2: TdxLayoutItem;
    cxTextEdit1: TcxTextEdit;
    dxLayout1Item1: TdxLayoutItem;
    cxTextEdit2: TcxTextEdit;
    dxLayout1Item3: TdxLayoutItem;
    cxTextEdit3: TcxTextEdit;
    dxLayout1Item4: TdxLayoutItem;
    EditTruck: TcxButtonEdit;
    dxLayout1Item5: TdxLayoutItem;
    N12: TMenuItem;
    procedure EditTruckPropertiesButtonClick(Sender: TObject;
      AButtonIndex: Integer);
    procedure N1Click(Sender: TObject);
    procedure N2Click(Sender: TObject);
    procedure N3Click(Sender: TObject);
    procedure N6Click(Sender: TObject);
    procedure N9Click(Sender: TObject);
    procedure N11Click(Sender: TObject);
    procedure N12Click(Sender: TObject);
  private
    { Private declarations }
  protected
    procedure OnLoadPopedom; override;
    function InitFormDataSQL(const nWhere: string): string; override;
    {*��ѯSQL*}
    procedure SetTruckQueue(const nFirst: Boolean);
    //�������
  public
    { Public declarations }
    class function FrameID: integer; override;
  end;

implementation

{$R *.dfm}
uses
  ULibFun, UMgrControl, USysConst, USysDB, UDataModule, USysPopedom,
  UFormInputbox;

class function TfFrameQueryDispatch.FrameID: integer;
begin
  Result := cFI_FrameDispatchQuery;
end;

procedure TfFrameQueryDispatch.OnLoadPopedom;
begin
  inherited;
  N1.Enabled := BtnAdd.Enabled;
  N2.Enabled := BtnEdit.Enabled;
  {$IFDEF SpecialControl}
  N3.Enabled := True;
  {$ELSE}
  N3.Enabled := BtnEdit.Enabled;
  {$ENDIF}
  N7.Enabled := BtnEdit.Enabled;
end;

function TfFrameQueryDispatch.InitFormDataSQL(const nWhere: string): string;
begin
  Result := ' Select zt.*,Z_Name,L_CusID,L_CusName,L_Status,L_Value,L_LadeTime ' +
            'From $ZT zt ' +
            ' Left Join $ZL zl On zl.Z_ID=zt.T_Line ' +
            ' Left Join $Bill b On b.L_ID=zt.T_Bill ';
  //xxxxx

  if nWhere <> '' then
    Result := Result + ' Where (' + nWhere + ')';
  //xxxx
  
  Result := MacroValue(Result, [MI('$ZT', sTable_ZTTrucks),
            MI('$ZL', sTable_ZTLines), MI('$Bill', sTable_Bill)]);
  //xxxxx
end;

//Desc: ִ�в�ѯ
procedure TfFrameQueryDispatch.EditTruckPropertiesButtonClick(Sender: TObject;
  AButtonIndex: Integer);
begin
  if Sender = EditTruck then
  begin
    EditTruck.Text := Trim(EditTruck.Text);
    if EditTruck.Text = '' then Exit;

    FWhere := Format('zt.T_Truck like ''%%%s%%''', [EditTruck.Text]);
    InitFormData(FWhere);
  end;
end;

//------------------------------------------------------------------------------
//Date: 2012-4-26
//Parm: �Ƿ����
//Desc: �������
procedure TfFrameQueryDispatch.SetTruckQueue(const nFirst: Boolean);
var nDate: TDateTime;
    nStr,nTruck,nStock: string;
begin
  if cxView1.DataController.GetSelectedCount > 0 then
  begin
    if nFirst then
    begin
      nStr := 'ȷ��Ҫ������[ %s ]���������?' + #13#10 +
              '�ó������Ƚ���.';
    end else
    begin
      nStr := 'ȷ��Ҫ������[ %s ]�����β��?' + #13#10 +
              '�ó������½��������Ŷ�.';
    end;

    nTruck := SQLQuery.FieldByName('T_Truck').AsString;
    nStr := Format(nStr, [nTruck]);
    if not QueryDlg(nStr, sAsk) then Exit;

    if nFirst then
    begin
      nStr := 'Select Min(T_InTime),%s As T_Now From %s Where T_StockNo=''%s''';
    end else
    begin
      nStr := 'Select Max(T_InTime),%s As T_Now From %s Where T_StockNo=''%s''';
    end;

    nStock := SQLQuery.FieldByName('T_StockNo').AsString;
    nStr := Format(nStr, [sField_SQLServer_Now, sTable_ZTTrucks, nStock]);

    with FDM.QueryTemp(nStr) do
    if RecordCount > 0 then
    begin
      nDate := Fields[0].AsDateTime;
      if nFirst then
           nDate := nDate - StrToTime('00:00:02')
      else nDate := nDate + StrToTime('00:00:02');
    end else
    begin
      nDate := Fields[0].AsDateTime;
    end;

    nStr := 'Update %s Set T_InTime=''%s'',T_Valid=''%s'',T_Line='''' ' +
            'Where T_Truck=''%s''';
    nStr := Format(nStr, [sTable_ZTTrucks, DateTime2Str(nDate), sFlag_Yes,
            nTruck]);
    //xxxxx

    FDM.ExecuteSQL(nStr);
    if nFirst then
    begin
      nStr := SQLQuery.FieldByName('T_Truck').AsString;
      FDM.WriteSysLog(sFlag_TruckQueue, nStr, '�����������.');
    end;

    InitFormData(FWhere);
    ShowMsg('������', sHint);
  end;
end;

//Desc: �����
procedure TfFrameQueryDispatch.N1Click(Sender: TObject);
begin
  SetTruckQueue(True);
end;

//Desc: ���β
procedure TfFrameQueryDispatch.N2Click(Sender: TObject);
begin
  SetTruckQueue(False);
end;

//Desc: ����װ��
procedure TfFrameQueryDispatch.N3Click(Sender: TObject);
var nStr,nLine,nTmp: string;
begin
  if cxView1.DataController.GetSelectedCount < 1 then
  begin
    ShowMsg('��ѡ����', sHint);
    Exit;
  end;

  nStr := SQLQuery.FieldByName('T_Line').AsString;
  nLine := nStr;
  if not ShowInputBox('�������µ�װ��ͨ����:', sHint, nLine, 15) then Exit;

  nLine := UpperCase(Trim(nLine));
  if (nLine = '') or (CompareText(nStr, nLine) = 0) then Exit;
  //null or same

  nStr := 'Select Z_StockNo,Z_Stock From %s Where Z_ID=''%s''';
  nStr := Format(nStr, [sTable_ZTLines, nLine]);

  with FDM.QueryTemp(nStr) do
  begin
    if RecordCount < 1 then
    begin
      ShowMsg('��Ч��ͨ�����', sHint);
      Exit;
    end;

    nTmp := SQLQuery.FieldByName('T_StockNo').AsString;
    if Fields[0].AsString <> nTmp then
    begin
      nStr := 'ͨ��[ %s ]��ˮ��Ʒ�����װƷ�ֲ�һ��,��������:' + #13#10#13#10 +
              '��.ͨ��Ʒ��: %s' + #13#10 +
              '��.��װƷ��: %s' + #13#10#13#10 +
              'ȷ��Ҫ����������?';
      nStr := Format(nStr, [nLine, Fields[1].AsString, nTmp]);
      if not QueryDlg(nStr,sAsk) then Exit;
    end;
  end;

  nStr := 'Update %s Set T_Line=''%s'' Where R_ID=%s';
  nStr := Format(nStr, [sTable_ZTTrucks, nLine,
          SQLQuery.FieldByName('R_ID').AsString]);
  FDM.ExecuteSQL(nStr);

  nTmp := SQLQuery.FieldByName('T_Line').AsString;
  if nTmp = '' then nTmp := '��';

  nStr := 'ָ��װ����[ %s ]->[ %s ]';
  nStr := Format(nStr, [nTmp, nLine]);

  nTmp := SQLQuery.FieldByName('T_Truck').AsString;
  FDM.WriteSysLog(sFlag_TruckQueue, nTmp, nStr);
  InitFormData(FWhere);
end;

//Desc: ��ѯ�ó�ǰ�滹�ж��ٳ���
procedure TfFrameQueryDispatch.N6Click(Sender: TObject);
var nStr,nTruck,nStock,nDate: string;
begin
  if cxView1.DataController.GetSelectedCount > 0 then
  begin
    nTruck := SQLQuery.FieldByName('T_Truck').AsString;
    nStock := SQLQuery.FieldByName('T_StockNo').AsString;
    nDate := SQLQuery.FieldByName('T_InTime').AsString;

    nStr := 'Select Count(*) From $TB Where T_InFact Is Null And ' +
            'T_Valid=''$Yes'' And T_StockNo=''$SN'' And T_InTime<''$IT''';
    nStr := MacroValue(nStr, [MI('$TB', sTable_ZTTrucks),
            MI('$Yes', sFlag_Yes), MI('$SN', nStock),
            MI('$IT', nDate)]);
    //xxxxx

    with FDM.QueryTemp(nStr) do
    begin
      nStr := '����[ %s ]ǰ�滹��[ %d ]�����ȴ�����.';
      nStr := Format(nStr, [nTruck, Fields[0].AsInteger]);
      ShowDlg(nStr, sHint);
    end;
  end;
end;

//Desc: �������������
procedure TfFrameQueryDispatch.N9Click(Sender: TObject);
var nStr,nFlag,nEvent: string;
begin
  if cxView1.DataController.GetSelectedCount > 0 then
  begin
    case TComponent(Sender).Tag of
     10:
      begin
        nFlag := sFlag_Yes;
        nEvent := '������[ %s ]��Ӳ���.';
      end;
     20:
      begin
        nFlag := sFlag_No;
        nEvent := '������[ %s ]�Ƴ�����.';
      end;
    end;

    nStr := 'Update %s Set T_Valid=''%s'' Where T_Bill=''%s''';
    nStr := Format(nStr, [sTable_ZTTrucks, nFlag,
            SQLQuery.FieldByName('T_Bill').AsString]);
    FDM.ExecuteSQL(nStr);

    nStr := SQLQuery.FieldByName('T_Truck').AsString;
    nEvent := Format(nEvent, [SQLQuery.FieldByName('T_Bill').AsString]);

    FDM.WriteSysLog(sFlag_TruckQueue, nStr, nEvent);
    InitFormData(FWhere);
  end;
end;

//Desc: ��������
procedure TfFrameQueryDispatch.N11Click(Sender: TObject);
var nStr: string;
    nInt: Integer;
begin
  if cxView1.DataController.GetSelectedCount > 0 then
  begin
    nStr := 'ϵͳ�������������������Ľ�����: ' + #13#10#13#10 +
            ' ��.�������ѳ���.' + #13#10 +
            ' ��.����������Ч.' + #13#10#13#10 +
            '�ò������������Ӷ�����ֱ��ɾ��,Ҫ������?' + #32#32;
    if not QueryDlg(nStr, sAsk) then Exit;

    nStr := 'Delete From $ZT Where R_ID In (' +
            'Select zt.R_ID From $ZT zt ' +
            ' Left Join $Bill b On b.L_ID=zt.T_Bill ' +
            'Where (IsNull(L_OutFact,'''') <> '''') Or (L_ID Is Null))';
    //has out or not exists

    nStr := MacroValue(nStr, [MI('$ZT', sTable_ZTTrucks),
            MI('$Bill', sTable_Bill)]);
    nInt := FDM.ExecuteSQL(nStr);

    nStr := Format('�������,��[ %d ]�Ž���������.', [nInt]);
    FDM.WriteSysLog(sFlag_TruckQueue, sFlag_TruckQueue, nStr);

    InitFormData(FWhere);
    ShowMsg('�������', sHint);
  end;
end;

procedure TfFrameQueryDispatch.N12Click(Sender: TObject);
var nStr,nLadeTime,nTmp: string;
begin
  if cxView1.DataController.GetSelectedCount < 1 then
  begin
    ShowMsg('��ѡ����', sHint);
    Exit;
  end;

  nLadeTime := SQLQuery.FieldByName('L_LadeTime').AsString;

  if nLadeTime = '' then
  begin
    ShowMsg('������δˢ��', sHint);
    Exit;
  end;

  nStr := '����ˢ��ʱ��Ϊ:[%s],ȷ��Ҫ������?';
  nStr := Format(nStr, [nLadeTime]);

  if not QueryDlg(nStr,sAsk) then Exit;

  nLadeTime := FormatDateTime('yyyy-mm-dd hh:mm:ss.zzz', Now);

  nStr := 'Update %s Set L_LadeTime=''%s'' Where L_ID=''%s''';
  nStr := Format(nStr, [sTable_Bill, nLadeTime,
          SQLQuery.FieldByName('T_Bill').AsString]);
  FDM.ExecuteSQL(nStr);

  ShowMsg('�������', sHint);
  InitFormData(FWhere);
end;

initialization
  gControlManager.RegCtrl(TfFrameQueryDispatch, TfFrameQueryDispatch.FrameID);
end.
