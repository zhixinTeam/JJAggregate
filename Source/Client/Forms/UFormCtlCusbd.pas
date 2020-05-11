unit UFormCtlCusbd;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, UFormNormal, cxGraphics, cxControls, cxLookAndFeels,
  cxLookAndFeelPainters, dxSkinsCore, dxSkinsDefaultPainters,
  dxSkinsdxLCPainter, cxContainer, cxEdit, ComCtrls, cxListView,
  cxTextEdit, cxMaskEdit, cxDropDownEdit, dxLayoutControl, StdCtrls;

type
  TSearchType = (stCustomer, stTruck);

  TfFormCtlCusbd = class(TfFormNormal)
    dxlytmLayout1Item3: TdxLayoutItem;
    EditContent: TcxComboBox;
    dxlytmLayout1Item31: TdxLayoutItem;
    ListCustom: TcxListView;
    dxlytmLayout1Item32: TdxLayoutItem;
    btn1: TButton;
    dxLayout1Group2: TdxLayoutGroup;
    procedure cbbEditCustomPropertiesEditValueChanged(Sender: TObject);
    procedure btn1Click(Sender: TObject);
    procedure BtnOKClick(Sender: TObject);
  private
    { Private declarations }
    FType : TSearchType;
    FCustomer, FTruck, FSearchContent:string;
    Finit : Boolean;
  private
    function QueryCustom(const nType: TSearchType): Boolean;
  public
    { Public declarations }
    class function CreateForm(const nPopedom: string = '';
      const nParam: Pointer = nil): TWinControl; override;
    class function FormID: integer; override;
  end;

var
  fFormCtlCusbd: TfFormCtlCusbd;

implementation

{$R *.dfm}

uses
  IniFiles, ULibFun, UMgrControl, UAdjustForm, UFormCtrl, UFormBase, USysGrid,
  USysDB, USysConst, USysBusiness, UDataModule;


class function TfFormCtlCusbd.CreateForm(const nPopedom: string;
  const nParam: Pointer): TWinControl;
var nP: PFormCommandParam;
begin
  Result := nil;
  if Assigned(nParam) then
       nP := nParam
  else Exit;

  with TfFormCtlCusbd.Create(Application) do
  begin
    nP.FCommand := cCmd_ModalResult;
    Finit:= True;

    if nP.FParamC='Customer' then
    begin
      FCustomer:= nP.FParamB;
      EditContent.Text:= nP.FParamB;
      FType:= stCustomer;
    end
    else
    begin
      FTruck:= nP.FParamB;
      EditContent.Text:= nP.FParamB;
      FType:= stTruck;
    end;
    QueryCustom(FType);
    Finit:= False;
    nP.FParamA := ShowModal;

    Free;
  end;
end;

//Date: 2019-3-1
//Parm: 查询类型(按客户; 按车牌)
//Desc: 按指定类型查询车辆客户绑定情况
function TfFormCtlCusbd.QueryCustom(const nType: TSearchType): Boolean;
var nStr,nWhere: string;
begin
  Result := False;
  nWhere := '';
  ListCustom.Items.Clear;

  nStr:= 'UPDate %s Set T_CName=C_Name From %s Where T_CID=C_ID And T_CName<>C_Name';
  nStr:= Format(nStr, [sTable_TruckCus, sTable_Customer]);
  FDM.ExecuteSQL(nStr);

  case FType of

    stCustomer:
      begin
        nWhere := 'T_CID=''$CID'' And (T_Truck Like ''%$SechContent%'') ';
      end;

    stTruck   :
      begin
        nWhere := 'T_Truck=''$Truck'' And (T_CName Like ''%$SechContent%'' or T_CID=''$SechContent'') ';
      end;

  end;

  nStr := 'Select * From $TRCus ';
  if nWhere <> '' then
    nStr := nStr + ' Where (' + nWhere + ')';
  nStr := nStr + ' Order By T_CID';

  nStr := MacroValue(nStr, [MI('$TRCus', sTable_TruckCus), MI('$Truck', FTruck),
                            MI('$CID', FCustomer), MI('$SechContent', FSearchContent)]);
  //xxxxx

  with FDM.QueryTemp(nStr) do
  if RecordCount > 0 then
  begin
    First;

    while not Eof do
    with ListCustom.Items.Add do
    begin
      case FType of

        stTruck :
          begin
            ListCustom.Column[1].Caption:= '客户编号';
            ListCustom.Column[1].Width:= 70;
            ListCustom.Column[2].Width:= 290;

            Caption := FieldByName('R_ID').AsString;
            SubItems.Add(FieldByName('T_CID').AsString);
            SubItems.Add(FieldByName('T_CName').AsString);
            SubItems.Add( DateTime2Str(FieldByName('T_InValidTime').AsDateTime) );
          end;

        stCustomer :
          begin
            ListCustom.Column[2].Width:= 270;
            ListCustom.Column[1].Caption:= '车牌号';

            Caption := FieldByName('R_ID').AsString;
            SubItems.Add(FieldByName('T_Truck').AsString);
            SubItems.Add(FieldByName('T_CName').AsString);
            SubItems.Add( DateTime2Str(FieldByName('T_InValidTime').AsDateTime) );
          end;

      end;
      ImageIndex := cItemIconIndex;
      Next;
    end;

    ListCustom.ItemIndex := 0;
    Result := True;
  end;
end;

procedure TfFormCtlCusbd.cbbEditCustomPropertiesEditValueChanged(
  Sender: TObject);
begin
  if Finit then Exit;
  FSearchContent:= GetCtrlData(EditContent);
  QueryCustom(FType);
end;

class function TfFormCtlCusbd.FormID: integer;
begin
  Result := cFI_FormCtlCusbd;
end;

procedure TfFormCtlCusbd.btn1Click(Sender: TObject);
begin
  QueryCustom(FType);
end;

procedure TfFormCtlCusbd.BtnOKClick(Sender: TObject);
var nStr, nRId:string;
begin
  if ListCustom.ItemIndex > -1 then
  begin
    nRId:= ListCustom.Selected.Caption;
    nStr:= ' Delete %s Where R_ID=%s ';
    nStr:= Format(nStr, [sTable_TruckCus, nRId]);
    //xxxxxx

    FDM.ExecuteSQL(nStr);
    ModalResult := mrOk;
  end
  else ShowMsg('请选择要解除绑定关系的客户记录', sHint);
end;

initialization
  gControlManager.RegCtrl(TfFormCtlCusbd, TfFormCtlCusbd.FormID);


end.
