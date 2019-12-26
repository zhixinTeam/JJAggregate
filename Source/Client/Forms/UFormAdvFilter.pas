{*******************************************************************************
  作者: dmzn@163.com 2019-11-01
  描述: 高级筛选
*******************************************************************************}
unit UFormAdvFilter;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  StdCtrls, UFormNormal, cxGridTableView, cxFilter, cxGraphics, cxControls,
  cxLookAndFeels, cxLookAndFeelPainters, ImgList, cxContainer, cxCheckListBox,
  dxLayoutControl, cxEdit, cxTextEdit, cxCheckBox;

type
  TFilterDataItem = record
    FValid: Boolean;        //有效
    FSelected: Boolean;     //选中
    FText: string;          //内容
    FCharacter: string;     //拼音
  end;
  TFilterDataItems = array of TFilterDataItem;

  TfFormAdvFilter = class(TfFormNormal)
    List1: TcxCheckListBox;
    dxLayout1Item3: TdxLayoutItem;
    Image1: TcxImageList;
    Edit1: TcxTextEdit;
    dxLayout1Item4: TdxLayoutItem;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure BtnOKClick(Sender: TObject);
    procedure Edit1PropertiesChange(Sender: TObject);
    procedure Edit1KeyPress(Sender: TObject; var Key: Char);
    procedure List1ClickCheck(Sender: TObject; AIndex: Integer; APrevState,
      ANewState: TcxCheckBoxState);
  private
    { Private declarations }
    FGridView: TcxGridTableView;
    FColumn: TcxGridColumn;
    FFilterKind: TcxFilterOperatorKind;
    procedure LoadFilterList(const nFilter: string);
    //载入数据
    function ActionNotEqual: Boolean;
    function ActionLike: Boolean;
    function ActionNotLike: Boolean;
    //执行筛选
  public
    { Public declarations }
    class function FormID: integer; override;
  end;

var
  gFilterText: string = '';
  gFilterItems: TFilterDataItems;
  //筛选内容

function ShowAdvFilterForm(const nView: TcxGridTableView;
  const nColumn: TcxGridColumn; const nKind: TcxFilterOperatorKind): Boolean;
//入口函数

implementation

{$R *.dfm}
uses
  ULibFun, USysConst;

function ShowAdvFilterForm;
begin
  with TfFormAdvFilter.Create(Application) do
  begin
    FGridView := nView;
    FColumn := nColumn;
    FFilterKind := nKind;
    
    case FFilterKind of
     foNotEqual:
      begin
        dxGroup1.Caption := '排除以下选中的内容:';
        LoadFilterList('');
      end;
     foLike    : dxGroup1.Caption := '包含以下填写的内容:';
     foNotLike : dxGroup1.Caption := '不包含以下填写的内容:';
    end;

    Edit1.Text := gFilterText;
    Result := ShowModal = mrOk;
    Free;
  end;
end;

class function TfFormAdvFilter.FormID: integer;
begin
  Result := -1;
end;

procedure TfFormAdvFilter.FormCreate(Sender: TObject);
begin
  LoadFormConfig(Self);
end;

procedure TfFormAdvFilter.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  SaveFormConfig(Self);
end;

procedure TfFormAdvFilter.LoadFilterList(const nFilter: string);
var nIdx: Integer;
begin
  List1.Items.BeginUpdate;
  try
    List1.Items.Clear;
    for nIdx:=Low(gFilterItems) to High(gFilterItems) do
    begin
      if not gFilterItems[nIdx].FValid then Continue;
      //invalid

      if (nFilter <> '') and
         (Pos(nFilter, gFilterItems[nIdx].FText) < 1) and
         (Pos(nFilter, gFilterItems[nIdx].FCharacter) < 1) then Continue;
      //no match

      with List1.Items.Add do
      begin
        Text := gFilterItems[nIdx].FText;
        Tag := nIdx;

        if gFilterItems[nIdx].FSelected then
             State := cbsChecked
        else State := cbsUnchecked;
      end;
    end;
  finally
    List1.Items.EndUpdate;
  end;   
end;

//Desc: 输入时筛选数据
procedure TfFormAdvFilter.Edit1PropertiesChange(Sender: TObject);
begin
  if FFilterKind = foNotEqual then
    LoadFilterList(Edit1.Text);
  //xxxxx
end;

//Desc: 回车时选中首条
procedure TfFormAdvFilter.Edit1KeyPress(Sender: TObject; var Key: Char);
begin
  if (FFilterKind = foNotEqual) and (Key = Char(VK_RETURN)) then
  begin
    Key := #0;
    if List1.Items.Count > 1 then Exit;
    Edit1.SelectAll;

    with List1.Items[0] do
    begin
      if State = cbsChecked then
           State := cbsUnchecked
      else State := cbsChecked;

      gFilterItems[Tag].FSelected := State = cbsChecked;
    end;
  end;
end;

//Desc: 回写状态
procedure TfFormAdvFilter.List1ClickCheck(Sender: TObject; AIndex: Integer;
  APrevState, ANewState: TcxCheckBoxState);
begin
  gFilterItems[List1.Items[AIndex].Tag].FSelected := ANewState = cbsChecked;
end;

//Desc: 确认筛选
procedure TfFormAdvFilter.BtnOKClick(Sender: TObject);
var nBool: Boolean;
begin
  with FGridView.DataController.Filter.Root do
  begin
    Clear;
    //init

    case FFilterKind of
     foNotEqual : nBool := ActionNotEqual;
     foLike     : nBool := ActionLike;
     foNotLike  : nBool := ActionNotLike
     else Exit;
    end;

    if nBool then
    begin
      FGridView.DataController.Filter.Active := True;
      ModalResult := mrOk;
    end;
  end;
end;

//Desc: 排除
function TfFormAdvFilter.ActionNotEqual: Boolean;
var nIdx,nInt: Integer;
begin
  Result := False;
  nInt := 0;

  for nIdx:=Low(gFilterItems) to High(gFilterItems) do
  with gFilterItems[nIdx], FGridView.DataController.Filter.Root do
  begin
    if not (FValid and FSelected) then Continue;
    //invalid

    AddItem(FColumn, foNotEqual, FText, FText);
    Inc(nInt);
  end;

  if nInt = 0 then
  begin
    ShowMsg('请选择筛选内容', sHint);
  end else

  if nInt >= 20 then
  begin
    ShowMsg('排除内容过多', sHint);
  end else
  begin
    Result := True;
  end;
end;

//Desc: 模糊包含
function TfFormAdvFilter.ActionLike: Boolean;
begin
  with FGridView.DataController.Filter.Root do
  begin
    gFilterText := Trim(Edit1.Text);
    AddItem(FColumn, foLike, '%' + gFilterText + '%', gFilterText);
    Result := True;
  end;
end;

//Desc: 模糊排除
function TfFormAdvFilter.ActionNotLike: Boolean;
begin
  with FGridView.DataController.Filter.Root do
  begin
    gFilterText := Trim(Edit1.Text);
    AddItem(FColumn, foNotLike, '%' + gFilterText + '%', gFilterText);
    Result := True;
  end;
end;

end.
