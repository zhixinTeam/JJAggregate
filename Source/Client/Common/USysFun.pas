{*******************************************************************************
  作者: dmzn@163.com 2007-10-09
  描述: 项目通用函数定义单元
*******************************************************************************}
unit USysFun;

interface

uses
  Windows, Classes, ComCtrls, Controls, Messages, Forms, SysUtils, IniFiles,
  ULibFun, USysConst, Registry, WinSpool, Graphics, Chart, GanttCh;

const
  WM_FrameChange = WM_User + $0027;
  
type
  TControlChangeState = (fsNew, fsFree, fsActive);
  TControlChangeEvent = procedure (const nName: string; const nCtrl: TWinControl;
    const nState: TControlChangeState) of object;
  //控件变动

procedure ShowMsgOnLastPanelOfStatusBar(const nMsg: string);
procedure StatusBarMsg(const nMsg: string; const nIdx: integer);
//在状态栏显示信息

procedure InitSystemEnvironment;
//初始化系统运行环境的变量
procedure LoadSysParameter(const nIni: TIniFile = nil);
//载入系统配置参数
function MakeFrameName(const nFrameID: integer): string;
//创建Frame名称

function ReplaceGlobalPath(const nStr: string): string;
//替换nStr中的全局路径

procedure LoadListViewColumn(const nWidths: string; const nLv: TListView);
//载入列表表头宽度
function MakeListViewColumnInfo(const nLv: TListView): string;
//组合列表表头宽度信息
procedure CombinListViewData(const nList: TStrings; nLv: TListView;
 const nAll: Boolean);
//组合选中的项的数据
procedure InitGanttStyle(const nChart: TChart; const nTitle: string);
//初始化甘特图表样式

function ParseCardNO(const nCard: string; const nHex: Boolean): string;
//格式化磁卡编号

implementation

//---------------------------------- 配置运行环境 ------------------------------
//Date: 2007-01-09
//Desc: 初始化运行环境
procedure InitSystemEnvironment;
begin
  Randomize;
  ShortDateFormat := 'YYYY-MM-DD';
  gPath := ExtractFilePath(Application.ExeName);
end;

//Date: 2007-09-13
//Desc: 载入系统配置参数
procedure LoadSysParameter(const nIni: TIniFile = nil);
var nTmp: TIniFile;
begin
  if Assigned(nIni) then
       nTmp := nIni
  else nTmp := TIniFile.Create(gPath + sConfigFile);

  try
    with gSysParam, nTmp do
    begin
      FProgID := ReadString(sConfigSec, 'ProgID', sProgID);
      //程序标识决定以下所有参数
      FAppTitle := ReadString(FProgID, 'AppTitle', sAppTitle);
      FMainTitle := ReadString(FProgID, 'MainTitle', sMainCaption);
      FHintText := ReadString(FProgID, 'HintText', '');
      FCopyRight := ReadString(FProgID, 'CopyRight', '');
      FRecMenuMax := ReadInteger(FProgID, 'MaxRecent', cRecMenuMax);

      FIconFile := ReadString(FProgID, 'IconFile', gPath + 'Icons\Icon.ini');
      FIconFile := StringReplace(FIconFile, '$Path\', gPath, [rfIgnoreCase]);
      FPoundLEDTxt:= ReadString(FProgID, 'PoundLEDDefaultTxt', '  金耀华夏   九润神州');

      FProberUser := 0;
      FVoiceUser := 0;

      FIsManual := False;
      //手动称重
      FAutoPound := False;
      //自动称重
      
      FPicBase := 0;
      FPicPath := gPath + sCameraDir;
    end;
  finally
    if not Assigned(nIni) then nTmp.Free;
  end;
end;

//Desc: 依据FrameID生成组件名
function MakeFrameName(const nFrameID: integer): string;
begin
  Result := 'Frame' + IntToStr(nFrameID);
end;

//Desc: 替换nStr中的全局路径
function ReplaceGlobalPath(const nStr: string): string;
var nPath: string;
begin
  nPath := gPath;
  if Copy(nPath, Length(nPath), 1) = '\' then
    System.Delete(nPath, Length(nPath), 1);
  Result := StringReplace(nStr, '$Path', nPath, [rfReplaceAll, rfIgnoreCase]);
end;

//------------------------------------------------------------------------------
//Desc: 在全局状态栏最后一个Panel上显示nMsg消息
procedure ShowMsgOnLastPanelOfStatusBar(const nMsg: string);
begin
  if Assigned(gStatusBar) and (gStatusBar.Panels.Count > 0) then
  begin
    gStatusBar.Panels[gStatusBar.Panels.Count - 1].Text := nMsg;
    Application.ProcessMessages;
  end;
end;

//Desc: 在索引nIdx的Panel上显示nMsg消息
procedure StatusBarMsg(const nMsg: string; const nIdx: integer);
begin
  if Assigned(gStatusBar) and (gStatusBar.Panels.Count > nIdx) and
     (nIdx > -1) then
  begin
    gStatusBar.Panels[nIdx].Text := nMsg;
    gStatusBar.Panels[nIdx].Width := gStatusBar.Canvas.TextWidth(nMsg) + 20;
    Application.ProcessMessages;
  end;
end;

//------------------------------------------------------------------------------
//Date: 2007-11-30
//Parm: 宽度信息;列表
//Desc: 载入nList的表头宽度
procedure LoadListViewColumn(const nWidths: string; const nLv: TListView);
var nList: TStrings;
    i,nCount: integer;
begin
  if nLv.Columns.Count > 0 then
  begin
    nList := TStringList.Create;
    try
      if SplitStr(nWidths, nList, nLv.Columns.Count, ';') then
      begin
        nCount := nList.Count - 1;
        for i:=0 to nCount do
         if IsNumber(nList[i], False) then
          nLv.Columns[i].Width := StrToInt(nList[i]);
      end;
    finally
      nList.Free;
    end;
  end;
end;

//Date: 2007-11-30
//Parm: 列表
//Desc: 组合nLv的表头宽度信息
function MakeListViewColumnInfo(const nLv: TListView): string;
var i,nCount: integer;
begin
  Result := '';
  nCount := nLv.Columns.Count - 1;

  for i:=0 to nCount do
  if i = nCount then
       Result := Result + IntToStr(nLv.Columns[i].Width)
  else Result := Result + IntToStr(nLv.Columns[i].Width) + ';';
end;

//Date: 2007-11-30
//Parm: 列表;列表;是否全部组合
//Desc: 组合nLv中的信息,填充到nList中
procedure CombinListViewData(const nList: TStrings; nLv: TListView;
 const nAll: Boolean);
var i,nCount: integer;
begin
  nList.Clear;
  nCount := nLv.Items.Count - 1;

  for i:=0 to nCount do
  if nAll or nLv.Items[i].Selected then
  begin
    nList.Add(nLv.Items[i].Caption + sLogField +
      CombinStr(nLv.Items[i].SubItems, sLogField));
    //combine items's data
  end;
end;

//Date: 2018-12-04
//Parm: 图表
//Desc: 初始化甘特图表样式
procedure InitGanttStyle(const nChart: TChart; const nTitle: string);
var nIdx: Integer;

    //Desc: 默认字体
    procedure DefaultFont(const nFont: TFont);
    begin
      with nFont do
      begin
        Charset := GB2312_CHARSET;
        Size := 9;
        Name := '宋体';
      end;
    end;
begin
  with nChart do
  begin
    BevelOuter := bvNone;
    BackColor := clWhite;
    Color := clWhite;

    with BottomAxis do
    begin
      Axis.Visible := False;
      DateTimeFormat := 'yyyy-MM-dd hh:mm:ss';
      //Grid.Visible := False;

      LabelsMultiLine := True;
      DefaultFont(LabelsFont);
    end;

    Frame.Color := clSkyBlue;
    LeftAxis.Visible := False;
    Legend.Visible := False;

    DefaultFont(Title.Font);
    Title.Text.Text := nTitle;
    View3D := False;
    View3DWalls := False;

    for nIdx:=SeriesCount - 1 downto 0 do
    begin
      if Series[nIdx] is TGanttSeries then
      with Series[nIdx] as TGanttSeries do
      begin
        Marks.Visible := True;
        //Marks.Positions :=
        DefaultFont(Marks.Font);
      end;
    end;
  end;
end;

//Date: 2012-4-22
//Parm: 16位卡号数据
//Desc: 格式化nCard为标准卡号
function ParseCardNO(const nCard: string; const nHex: Boolean): string;
var nInt: Int64;
    nIdx: Integer;
begin
  if nHex then
  begin
    Result := '';
    for nIdx:=1 to Length(nCard) do
      Result := Result + IntToHex(Ord(nCard[nIdx]), 2);
    //xxxxx
  end else Result := nCard;

  nInt := StrToInt64('$' + Result);
  Result := IntToStr(nInt);
  Result := StringOfChar('0', 12 - Length(Result)) + Result;
end;

end.


