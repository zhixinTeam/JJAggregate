{*******************************************************************************
  ����: dmzn@163.com 2019-11-01
  ����: �߼�ɸѡ
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
    FValid: Boolean;        //��Ч
    FSelected: Boolean;     //ѡ��
    FText: string;          //����
    FCharacter: string;     //ƴ��
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
    //��������
    function ActionNotEqual: Boolean;
    function ActionLike: Boolean;
    function ActionNotLike: Boolean;
    //ִ��ɸѡ
  public
    { Public declarations }
    class function FormID: integer; override;
  end;

var
  gFilterText: string = '';
  gFilterItems: TFilterDataItems;
  //ɸѡ����

function ShowAdvFilterForm(const nView: TcxGridTableView;
  const nColumn: TcxGridColumn; const nKind: TcxFilterOperatorKind): Boolean;
//��ں���

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
        dxGroup1.Caption := '�ų�����ѡ�е�����:';
        LoadFilterList('');
      end;
     foLike    : dxGroup1.Caption := '����������д������:';
     foNotLike : dxGroup1.Caption := '������������д������:';
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

//Desc: ����ʱɸѡ����
procedure TfFormAdvFilter.Edit1PropertiesChange(Sender: TObject);
begin
  if FFilterKind = foNotEqual then
    LoadFilterList(Edit1.Text);
  //xxxxx
end;

//Desc: �س�ʱѡ������
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

//Desc: ��д״̬
procedure TfFormAdvFilter.List1ClickCheck(Sender: TObject; AIndex: Integer;
  APrevState, ANewState: TcxCheckBoxState);
begin
  gFilterItems[List1.Items[AIndex].Tag].FSelected := ANewState = cbsChecked;
end;

//Desc: ȷ��ɸѡ
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

//Desc: �ų�
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
    ShowMsg('��ѡ��ɸѡ����', sHint);
  end else

  if nInt >= 20 then
  begin
    ShowMsg('�ų����ݹ���', sHint);
  end else
  begin
    Result := True;
  end;
end;

//Desc: ģ������
function TfFormAdvFilter.ActionLike: Boolean;
begin
  with FGridView.DataController.Filter.Root do
  begin
    gFilterText := Trim(Edit1.Text);
    AddItem(FColumn, foLike, '%' + gFilterText + '%', gFilterText);
    Result := True;
  end;
end;

//Desc: ģ���ų�
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
