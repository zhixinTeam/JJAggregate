{*******************************************************************************
  ����: dmzn@163.com 2013-11-27
  ����: ����ϵͳ���
*******************************************************************************}
unit UFramePlugs;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  UDataModule, UFrameBase, ExtCtrls, Grids, ValEdit, UZnValueList, Menus;

{$I Link.Inc}
type
  TfFramePlugs = class(TfFrameBase)
    ListPlugs: TZnValueList;
    PMenu1: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    procedure N1Click(Sender: TObject);
    procedure N3Click(Sender: TObject);
    procedure PMenu1Popup(Sender: TObject);
  private
    { Private declarations }
    procedure NewPlugItem(const nKey,nFlag: string;
     nImage: Integer = cIcon_Key);
    procedure UpdateItem(const nFlag,nValue: string;
     nImage: Integer = -1);
    procedure UpdatePlugList;
    //����ժҪ
    procedure LoadConfig(const nLoad: Boolean);
    //��������
  public
    { Public declarations }
    procedure OnCreateFrame; override;
    procedure OnDestroyFrame; override;
    class function FrameID: integer; override;
  end;

implementation

{$R *.dfm}

uses
  ULibFun, IniFiles, UMgrPlug, UMgrControl, USmallFunc, UMITConst;

class function TfFramePlugs.FrameID: integer;
begin
  Result := cFI_FramePlugs;
end;

procedure TfFramePlugs.OnCreateFrame;
begin
  inherited;
  Name := MakeFrameName(FrameID);
  ListPlugs.DoubleBuffered := True;

  LoadConfig(True);
  UpdatePlugList;
end;

//Desc: ˢ�·���״̬
procedure TfFramePlugs.OnDestroyFrame;
begin
  inherited;
  LoadConfig(False);
end;

procedure TfFramePlugs.LoadConfig(const nLoad: Boolean);
var nIni: TIniFile;
begin
  nIni := TIniFile.Create(gPath + sFormConfig);
  try
    if nLoad then
    begin
      ListPlugs.ColWidths[0] := nIni.ReadInteger(Name, 'ListCol0', 100);
    end else
    begin
      nIni.WriteInteger(Name, 'ListCol0', ListPlugs.ColWidths[0]);
    end;
  finally
    nIni.Free;
  end;
end;

//------------------------------------------------------------------------------
//Desc: ����б���
procedure TfFramePlugs.NewPlugItem(const nKey, nFlag: string;
  nImage: Integer);
var nPic: PZnVLPicture;
begin
  nPic := ListPlugs.AddPicture(nKey, '', nFlag);
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
procedure TfFramePlugs.UpdateItem(const nFlag,nValue: string;
  nImage: Integer);
var nData: PZnVLData;
    nPic: PZnVLPicture;
begin
  nData := ListPlugs.FindData(nFlag);
  nPic := nData.FData;

  if nImage < 0 then
    nImage := FDM.BaseIconRandomIndex;
  //xxxx

  if (nPic.FValue.FText <> nValue) or (nPic.FValue.FFlag <> nImage) then
  begin
    nPic.FValue.FText := nValue;
    if nPic.FValue.FFlag <> nImage then
    begin
      nPic.FValue.FFlag := nImage;
      FDM.ImageBase.GetBitmap(nImage, nPic.FValue.FIcon);
    end;
  end;
end;

//------------------------------------------------------------------------------
//Desc: Ȩ��
procedure TfFramePlugs.PMenu1Popup(Sender: TObject);
begin
  N1.Enabled := gSysParam.FIsAdmin;
  N3.Enabled := gSysParam.FIsAdmin;
end;

//Desc: �����б�
procedure TfFramePlugs.UpdatePlugList;
var nStr: string;
    i,nIdx: Integer;
    nPlugs: TPlugModuleInfos;

    function ItemFlag(const nInc: Byte): string;
    begin
      Result := nStr + IntToStr(nIdx);
      Inc(nIdx, nInc);
    end;
begin
  ListPlugs.ClearAll;
  ListPlugs.TitleCaptions.Clear;
  nPlugs := gPlugManager.GetModuleInfoList;

  for i:=Low(nPlugs) to High(nPlugs) do
  with nPlugs[i] do
  begin
    nIdx := 1;
    nStr := Format('p_%d_', [i]);
    ListPlugs.AddData(IntToStr(i+1) + '.' + FModuleName, '', nil, nStr, vtGroup);

    NewPlugItem('��ʶ', ItemFlag(0));
    UpdateItem(ItemFlag(1), FModuleID);

    NewPlugItem('����', ItemFlag(0));
    UpdateItem(ItemFlag(1), FModuleName);

    NewPlugItem('����', ItemFlag(0));
    UpdateItem(ItemFlag(1), FModuleAuthor);

    NewPlugItem('�汾', ItemFlag(0));
    UpdateItem(ItemFlag(1), FModuleVersion);

    NewPlugItem('����', ItemFlag(0));
    UpdateItem(ItemFlag(1), FModuleDesc);

    NewPlugItem('����', ItemFlag(0));
    UpdateItem(ItemFlag(1), DateTime2Str(FModuleBuildTime));

    NewPlugItem('�ļ�', ItemFlag(0));
    UpdateItem(ItemFlag(1), FModuleFile);
  end;
end;

//Desc: ж��
procedure TfFramePlugs.N1Click(Sender: TObject);
var nStr,nExt: string;
    nPos: Integer;
    nData: PZnVLData;
begin
  nData := ListPlugs.GetSelectData();
  if not Assigned(nData) then Exit;

  nStr := nData.FFlag;
  nPos := StrPosR('_', nStr);
  System.Delete(nStr, nPos + 1, Length(nStr) - nPos);

  nData := ListPlugs.FindData(nStr + '1');
  if not Assigned(nData) then Exit;

  nStr := PZnVLPicture(nData.FData).FValue.FText;
  nExt := ExtractFileExt(gPlugManager.GetModuleInfo(nStr).FModuleFile);

  if LowerCase(nExt) = '.dll' then
  begin
    gPlugManager.UnloadPlug(nStr);
    UpdatePlugList;
  end else
  begin
    ShowMsg('�ؼ�����޷�ж��', sHint);
  end;
end;

//Desc: ����
procedure TfFramePlugs.N3Click(Sender: TObject);
begin
  gPlugManager.LoadPlugsInDirectory(gPath + sPlugDir);
  UpdatePlugList;
end;

initialization
  gControlManager.RegCtrl(TfFramePlugs, TfFramePlugs.FrameID);
end.
