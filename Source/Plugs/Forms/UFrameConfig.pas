{*******************************************************************************
  ����: dmzn@163.com 2013-12-03
  ����: ���������趨
*******************************************************************************}
unit UFrameConfig;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  UDataModule, UFrameBase, Grids, ValEdit, UZnValueList, ExtCtrls;

type
  TfFrameConfig = class(TfFrameBase)
    ListConfig: TZnValueList;
    procedure ListConfigDblClick(Sender: TObject);
  private
    { Private declarations }
    FConfigChanged: Boolean;
    //���ñ䶯
    FFlagIndex: Integer;
    FFlagPrefix: string;
    function ItemFlag: string;
    //��Ŀ��ʶ
    procedure NewConfigItem(const nKey,nFlag: string;
     nImage: Integer = cIcon_Key);
    procedure UpdateItem(const nFlag,nValue: string;
     nImage: Integer = -1);
    procedure UpdateConfig(const nNewItem: Boolean);
    //��������
    procedure LoadConfig(const nLoad: Boolean);
    procedure UpdateListTitle;
    //��������
  public
    { Public declarations }
    procedure OnCreateFrame; override;
    procedure OnDestroyFrame; override;
    function DealCommand(Sender: TObject; const nCmd: Integer;
     const nParamA: Pointer; const nParamB: Integer): Integer; override;
    class function FrameID: integer; override;
  end;

implementation

{$R *.dfm}
uses
  IniFiles, ULibFun, UMgrControl, UFormInputbox, UFormCheckbox,
  UMITConst, USmallFunc;

class function TfFrameConfig.FrameID: integer;
begin
  Result := cFI_FrameConfig;
end;

procedure TfFrameConfig.OnCreateFrame;
begin
  inherited;
  Name := MakeFrameName(FrameID);
  ListConfig.DoubleBuffered := True;

  UpdateListTitle;
  LoadConfig(True);
  
  UpdateConfig(True);
  UpdateConfig(False);
end;

procedure TfFrameConfig.OnDestroyFrame;
begin
  inherited;
  LoadConfig(False);
end;

procedure TfFrameConfig.LoadConfig(const nLoad: Boolean);
var nIni: TIniFile;
begin
  nIni := TIniFile.Create(gPath + sFormConfig);
  try
    if nLoad then
    begin
      ListConfig.ColWidths[0] := nIni.ReadInteger(Name, 'ListCol0', 100);
    end else
    begin
      nIni.WriteInteger(Name, 'ListCol0', ListConfig.ColWidths[0]);
    end;
  finally
    nIni.Free;
  end;
end;

function TfFrameConfig.DealCommand(Sender: TObject; const nCmd: Integer;
  const nParamA: Pointer; const nParamB: Integer): Integer;
begin 
  if nCmd = cCmd_AdminChanged then
    UpdateListTitle;
  Result := -1;
end;

procedure TfFrameConfig.UpdateListTitle;
begin
  if gSysParam.FIsAdmin then
  begin
    ListConfig.TitleCaptions[0] := '����״̬';
    ListConfig.TitleCaptions[1] := '˫����������б༭';
    ListConfig.DisplayOptions := ListConfig.DisplayOptions + [doColumnTitles];
  end else
  begin
    ListConfig.DisplayOptions := ListConfig.DisplayOptions - [doColumnTitles];
  end;

  ListConfig.Invalidate;
end;

//------------------------------------------------------------------------------
//Desc: ����б���
procedure TfFrameConfig.NewConfigItem(const nKey, nFlag: string;
  nImage: Integer);
var nPic: PZnVLPicture;
begin
  nPic := ListConfig.AddPicture(nKey, '', nFlag);
  if nImage < 0 then
    nImage := FDM.BaseIconRandomIndex;
  //xxxxx

  nPic.FKey.FLoop := 1;
  nPic.FKey.FIcon := TBitmap.Create;
  FDM.ImageBase.GetBitmap(nImage, nPic.FKey.FIcon);

  nPic.FValue.FLoop := 1;
  nPic.FValue.FIcon := TBitmap.Create;
end;

//Desc: �����б�������
procedure TfFrameConfig.UpdateItem(const nFlag,nValue: string;
  nImage: Integer);
var nData: PZnVLData;
    nPic: PZnVLPicture;
begin
  nData := ListConfig.FindData(nFlag);
  nPic := nData.FData;

  if nImage < 0 then
    nImage := FDM.BaseIconRandomIndex;
  //xxxx

  if (nPic.FValue.FText <> nValue) or (nPic.FValue.FFlag <> nImage) then
  begin
    FConfigChanged := True;
    nPic.FValue.FText := nValue;

    if nPic.FValue.FFlag <> nImage then
    begin
      nPic.FValue.FFlag := nImage;
      FDM.ImageBase.GetBitmap(nImage, nPic.FValue.FIcon);
    end;
  end;
end;

function TfFrameConfig.ItemFlag: string;
begin
  Result := FFlagPrefix + IntToStr(FFlagIndex);
  Inc(FFlagIndex);
end;

procedure TfFrameConfig.UpdateConfig(const nNewItem: Boolean);
begin
  if nNewItem then
  begin
    FFlagIndex := 1;
    FFlagPrefix := 'sys_config';

    ListConfig.AddData('��������', '', nil, FFlagPrefix, vtGroup);
    NewConfigItem('��¼����', ItemFlag, cIcon_Anchor);
    NewConfigItem('��¼����', ItemFlag, cIcon_Timer);
    NewConfigItem('�Զ�����', ItemFlag, cIcon_Star);

    Exit;
  end;

  FConfigChanged := False;
  FFlagIndex := 1;
  FFlagPrefix := 'sys_config';

  UpdateItem(ItemFlag, StringOfChar('*', Length(gSysParam.FAdminPwd)));
  UpdateItem(ItemFlag, IntToStr(gSysParam.FAdminKeep) + '��');

  if gSysParam.FAutoMin then
       UpdateItem(ItemFlag, '���������з���')
  else UpdateItem(ItemFlag, '�ֶ����з���');

  if FConfigChanged then
    ListConfig.Invalidate;
  //refresh
end;

procedure TfFrameConfig.ListConfigDblClick(Sender: TObject);
var nStr: string;
    nData: PZnVLData;
begin
  if not gSysParam.FIsAdmin then Exit;
  nData := ListConfig.GetSelectData();
  if not Assigned(nData) then Exit;

  FFlagIndex := 1;
  FFlagPrefix := 'sys_config';

  if nData.FFlag = ItemFlag then
  begin
    nStr := gSysParam.FAdminPwd;
    //old password
    
    if ShowInputPWDBox('������������:', '�޸�����', nStr) then
    begin
      gSysParam.FAdminPwd := nStr;
      UpdateConfig(False);
      ShowMsg('����������Ч', sHint);
    end;
  end;

  if nData.FFlag = ItemFlag then
  begin
    nStr := IntToStr(gSysParam.FAdminKeep);
    //old keeplong

    while ShowInputBox('�������µ�ʱ��(��λ��):', '��¼����', nStr) do
    begin
      if IsNumber(nStr, False) and (StrToInt(nStr) > 0) then
      begin
        gSysParam.FAdminKeep := StrToInt(nStr);
        UpdateConfig(False);
        
        ShowMsg('��ʱ������Ч', sHint);
        Break;
      end else ShowMsg('��������Ч����ֵ', sHint);
    end;
  end;

  if nData.FFlag = ItemFlag then
  begin
    nStr := '�����ó�������ʱ�ķ���״̬:';
    //xxxxx
    
    if ShowCheckbox(nStr, '��������', '�Զ�����', gSysParam.FAutoMin) then
    begin
      UpdateConfig(False);
      ShowMsg('���趨����Ч', sHint);
    end;
  end;
end;

initialization
  gControlManager.RegCtrl(TfFrameConfig, TfFrameConfig.FrameID);
end.
