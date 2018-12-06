{*******************************************************************************
  作者: dmzn 2008-9-20
  描述: 公司信息
*******************************************************************************}
unit UFormAuditTruck;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  UDataModule, StdCtrls, ExtCtrls, dxLayoutControl, cxContainer, cxEdit,
  cxTextEdit, cxControls, cxMemo, UFormBase, cxGraphics, cxLookAndFeels,
  cxLookAndFeelPainters, cxImage, jpeg, DB, cxMaskEdit, cxDropDownEdit;

type
  TfFormAuditTruck = class(TBaseForm)
    dxLayoutControl1Group_Root: TdxLayoutGroup;
    dxLayoutControl1: TdxLayoutControl;
    dxLayoutControl1Group1: TdxLayoutGroup;
    EditType: TcxTextEdit;
    dxLayoutControl1Item1: TdxLayoutItem;
    EditTruck: TcxTextEdit;
    dxLayoutControl1Item2: TdxLayoutItem;
    EditMemo: TcxMemo;
    dxLayoutControl1Item6: TdxLayoutItem;
    BtnExit: TButton;
    dxLayoutControl1Item7: TdxLayoutItem;
    BtnOK: TButton;
    dxLayoutControl1Item8: TdxLayoutItem;
    dxLayoutControl1Group2: TdxLayoutGroup;
    ImageTruck: TcxImage;
    dxLayoutControl1Item9: TdxLayoutItem;
    EditResult: TcxComboBox;
    dxLayoutControl1Item3: TdxLayoutItem;
    procedure BtnOKClick(Sender: TObject);
  private
    { Private declarations }
    FTruckID: string;
    //车辆标识
    procedure InitFormData;
    {*初始化界面*}
  public
    { Public declarations }
    class function CreateForm(const nPopedom: string = '';
      const nParam: Pointer = nil): TWinControl; override;
    class function FormID: integer; override;
  end;

implementation

{$R *.dfm}
uses
  IniFiles, ULibFun, UMgrControl, USysConst, USysDB, USysPopedom, UFormWait,
  USysBusiness, UBusinessPacker;

//------------------------------------------------------------------------------
class function TfFormAuditTruck.CreateForm(const nPopedom: string;
  const nParam: Pointer): TWinControl;
var nP: PFormCommandParam;
begin
  Result := nil;
  if Assigned(nParam) then
       nP := nParam
  else Exit;

  with TfFormAuditTruck.Create(Application) do
  begin
    nP.FCommand := cCmd_ModalResult;
    FTruckID := nP.FParamA;
    case nP.FParamB of
      1:
      begin
        EditResult.ItemIndex := 1;
        EditResult.Enabled := False;
      end;
      2:
      begin
        EditResult.ItemIndex := 0;
        EditResult.Enabled := False;
      end;
    end;
    InitFormData;
    BtnOK.Enabled := gPopedomManager.HasPopedom(nPopedom, sPopedom_Edit);

    ShowModal;
    Free;
  end;
end;

class function TfFormAuditTruck.FormID: integer;
begin
  Result := cFI_FormAuditTruck;
end;

//Desc: 初始化界面数据
procedure TfFormAuditTruck.InitFormData;
var nStr: string;
    nStream: TMemoryStream;
    nField: TField;
    nJpg: TjpegImage;
begin
  ShowWaitForm(Self, '下载图片', True);
  try
    if DownLoadPic(PackerEncodeStr(FTruckID)) <> sFlag_Yes then
    begin
      CloseWaitForm;
      ShowMsg('下载图片失败', sHint);
      Exit;
    end;
  except
    CloseWaitForm;
    ShowMsg('下载图片失败', sHint);
    Exit;
  end;

  nStr := 'Select * From %s Where A_ID=''%s''';
  nStr := Format(nStr, [sTable_AuditTruck, FTruckID]);

  ShowWaitForm(Self, '读取图片', True);
  try
    with FDM.QueryTemp(nStr) do
    begin
      if RecordCount < 1 then
      begin
        ShowMsg('读取图片失败', sHint);
        Exit;
      end;

      nJpg:=TJPEGImage.Create;
      First;

      While not eof do
      begin
        EditType.Text := FieldByName('A_Serial').AsString;
        EditTruck.Text := FieldByName('A_Truck').AsString;
        EditMemo.Text := FieldByName('A_Memo').AsString;
        nStream := nil;
        try
          nField := FindField('A_License');
          if not (Assigned(nField) and (nField is TBlobField)) then
          begin
            Next;
            Continue;
          end;

          nStream := TMemoryStream.Create;
          TBlobField(nField).SaveToStream(nStream);

          nStream.Position:=0;
          nJpg.LoadFromStream(nStream);
          ImageTruck.Picture.Assign(nJpg);

          FreeAndNil(nStream);
        except
          on E : Exception do
          begin
            ShowHintMsg(E.Message,sHint);
            if Assigned(nStream) then nStream.Free;
          end;
        end;
        Next;
      end;
    end;
  finally
    if Assigned(nJpg) then nJpg.Free;
    CloseWaitForm;
    FDM.SqlTemp.Close;
  end;
end;

//Desc: 保存
procedure TfFormAuditTruck.BtnOKClick(Sender: TObject);
var nList: TStrings;
    nStr: string;
begin
  nList := TStringList.Create;

  try
    with nList do
    begin
      Clear;
      Values['ID']   := FTruckID;
      Values['Status']  := IntToStr(EditResult.ItemIndex+1);
      Values['Memo']    := EditMemo.Text;
      Values['Man']  := gSysParam.FUserID;
      Values['Type']     := '-1';
    end;

    if UpLoadAuditTruck(PackerEncodeStr(nList.Text)) <> sFlag_Yes then Exit;
    //call remote

    nStr := 'update %s set A_Status=''%s'', A_Memo= ''%s'',' +
            ' A_Date= %s where A_ID=''%s''';
    nStr := Format(nStr,[sTable_AuditTruck, IntToStr(EditResult.ItemIndex+1),
                         EditMemo.Text, sField_SQLServer_Now, FTruckID]);
    FDM.ExecuteSQL(nStr);

    ModalResult := mrOK;
    ShowMsg('审核结果保存成功',sHint);
  finally
    nList.Free;
  end;
end;

initialization
  gControlManager.RegCtrl(TfFormAuditTruck, TfFormAuditTruck.FormID);
end.
