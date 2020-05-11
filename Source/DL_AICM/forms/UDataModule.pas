{*******************************************************************************
  ����: dmzn@163.com 2012-5-3
  ����: ����ģ��
*******************************************************************************}
unit UDataModule;

interface

uses
  Windows, Graphics, SysUtils, Classes, dxPSGlbl, dxPSUtl, dxPSEngn,
  dxPrnPg, ULibFun, dxWrap, dxPrnDev, dxPSCompsProvider, dxPSFillPatterns,
  dxPSEdgePatterns, cxLookAndFeels, dxPSCore, dxPScxCommon, dxPScxGrid6Lnk,
  XPMan, dxLayoutLookAndFeels, cxEdit, ImgList, Controls, cxGraphics, DB,
  ADODB, dxBkgnd, dxPSPDFExportCore, dxPSPDFExport, cxDrawTextUtils,
  dxPSPrVwStd, dxPScxEditorProducers, dxPScxExtEditorProducers,
  dxPScxPageControlProducer, dxSkinsCore, dxSkinscxPCPainter,
  dxSkinsDefaultPainters;

type
  TFDM = class(TDataModule)
    ADOConn: TADOConnection;
    SQLQuery1: TADOQuery;
    SqlTemp: TADOQuery;
    SqlQuery: TADOQuery;
    Command: TADOQuery;
    dxPrinter1: TdxComponentPrinter;
    dxGridLink1: TdxGridReportLink;
    Qry_Cus: TADOQuery;
    Qry_Search: TADOQuery;
  private
    { Private declarations }
    function CheckQueryConnection(const nQuery: TADOQuery;
     const nUseBackdb: Boolean): Boolean;
  public
    { Public declarations }
    //��ѯ���ݿ�
    function QueryTemp(const nSQL:string;const nUseBackdb: Boolean = False):TDataSet;
    function ExecuteSQL(const nSQL: string; const nUseBackdb: Boolean = False): integer;
    function GetFieldMax(const nTable,nField: string): integer;
    function SaveDBImage(const nDS: TDataSet; const nFieldName: string;
      const nImage: string): Boolean; overload;
    function SaveDBImage(const nDS: TDataSet; const nFieldName: string;
      const nImage: TGraphic): Boolean; overload;
    procedure FillStringsData(const nList: TStrings; const nSQL: string;
      const nFieldLen: integer = 0; const nFieldFlag: string = '';
      const nExclude: TDynamicStrArray = nil);
    function GetSerialID2(const nPrefix,nTable,nKey,nField: string;
     const nFixID: Integer; const nIncLen: Integer = 3): string;
    function SQLServerNow: string;
    function QuerySQL(const nSQL: string; const nUseBackdb: Boolean = False): TDataSet;
    function QuerySQLx(const nSQL: string; const nUseBackdb: Boolean = False): TDataSet;
    function QuerySQLChk(const nSQL: string; const nUseBackdb: Boolean = False): TDataSet;
    procedure QueryData(const nQuery: TADOQuery; const nSQL: string;
     const nUseBackdb: Boolean = False);
  end;

var
  FDM: TFDM;

implementation
uses
  UFormCtrl,USysLoger;
{$R *.dfm}

procedure WriteLog(const nEvent: string);
begin
  gSysLoger.AddLog(TFDM, '����ģ��', nEvent);
end;

//Date: 2012-5-3
//Parm: SQL;�Ƿ񱣳�����
//Desc: ִ��SQL���ݿ��ѯ
function TFDM.CheckQueryConnection(const nQuery: TADOQuery;
  const nUseBackdb: Boolean): Boolean;
var nBackDBEnabled: Boolean;
begin
  {$IFDEF EnableDoubleDB}
  nBackDBEnabled := True;
  {$ELSE}
  nBackDBEnabled := False;
  {$ENDIF}

  Result := False;
  if not (nUseBackdb and nBackDBEnabled) then
  begin
    if not ADOConn.Connected then
      ADOConn.Connected := True;
    Result := ADOConn.Connected;

    if not Result then
      raise Exception.Create('���ݿ������ѶϿ�,����������ʧ��.');
    //xxxxx

    if nQuery.Connection <> ADOConn then
    begin
      nQuery.Close;
      nQuery.Connection := ADOConn;
    end;
  end;
  
  {$IFDEF EnableBackupDB}
  if not nUseBackdb then Exit;
  if (not nBackDBEnabled) and (IsEnableBackupDB <> gSysParam.FUsesBackDB) then
    raise Exception.Create('���ݿ�����쳣,�����µ�¼ϵͳ.');
  //xxxxx

  if gSysParam.FUsesBackDB then
  begin
    if not Conn_Bak.Connected then
      Conn_Bak.Connected := True;
    Result := Conn_Bak.Connected;

    if not Result then
      raise Exception.Create('���ݿ������ѶϿ�,����������ʧ��.');
    //xxxxx

    if nQuery.Connection <> Conn_Bak then
    begin
      nQuery.Close;
      nQuery.Connection := Conn_Bak;
    end;
  end;
  {$ENDIF}
end;

function TFDM.ExecuteSQL(const nSQL: string;
  const nUseBackdb: Boolean): integer;
var nStep: Integer;
    nException: string;
begin
  Result := -1;
  if not CheckQueryConnection(Command, nUseBackdb) then Exit;

  nException := '';
  nStep := 0;
  
  while nStep <= 2 do
  try
    if nStep = 1 then
    begin
      SqlTemp.Close;
      SqlTemp.Connection := Command.Connection;
      SqlTemp.SQL.Text := 'select 1';
      SqlTemp.Open;

      SqlTemp.Close;
      Break;
      //connection is ok
    end else

    if nStep = 2 then
    begin
      Command.Connection.Close;
      Command.Connection.Open;
    end; //reconnnect

    Command.Close;
    Command.SQL.Text := nSQL;
    Result := Command.ExecSQL;

    nException := '';
    Break;
  except
    on E:Exception do
    begin
      Inc(nStep);
      nException := E.Message;
      WriteLog(nException);
    end;
  end;

  if nException <> '' then
    raise Exception.Create(nException);
  //xxxxx
end;

procedure TFDM.FillStringsData(const nList: TStrings; const nSQL: string;
  const nFieldLen: integer; const nFieldFlag: string;
  const nExclude: TDynamicStrArray);
var nPos: integer;
    nStr,nPrefix: string;
begin
  nList.Clear;
  try
    nStr := nSQL;
    nPos := Pos('=', nSQL);

    if nPos > 1 then
    begin
      nPrefix := Copy(nSQL, 1, nPos - 1);
      System.Delete(nStr, 1, nPos);
    end else
    begin
      nPrefix := '';
    end;

    LoadDataToList(QueryTemp(nStr), nList, nPrefix, nFieldLen,
                                    nFieldFlag, nExclude);
  except
  end;
end;

function TFDM.GetFieldMax(const nTable, nField: string): integer;
begin
//
end;

function TFDM.GetSerialID2(const nPrefix, nTable, nKey, nField: string;
  const nFixID, nIncLen: Integer): string;
begin
//
end;

procedure TFDM.QueryData(const nQuery: TADOQuery; const nSQL: string;
  const nUseBackdb: Boolean);
var nStep: Integer;
    nException: string;
    nBookMark: Pointer;
begin
  if not CheckQueryConnection(nQuery, nUseBackdb) then Exit;
  nException := '';
  nStep := 0;

  while nStep <= 2 do
  try
    if nStep = 1 then
    begin
      SqlTemp.Close;
      SqlTemp.Connection := nQuery.Connection;
      SqlTemp.SQL.Text := 'select 1';
      SqlTemp.Open;

      SqlTemp.Close;
      Break;
      //connection is ok
    end else

    if nStep = 2 then
    begin
      nQuery.Connection.Close;
      nQuery.Connection.Open;
    end; //reconnnect

    nQuery.DisableControls;
    nBookMark := nQuery.GetBookmark;
    try
      nQuery.Close;
      nQuery.SQL.Text := nSQL;
      nQuery.Open;
                 
      nException := '';
      nStep := 3;
      //delay break loop

      if nQuery.BookmarkValid(nBookMark) then
        nQuery.GotoBookmark(nBookMark);
    finally
      nQuery.FreeBookmark(nBookMark);
      nQuery.EnableControls;
    end;
  except
    on E:Exception do
    begin
      Inc(nStep);
      nException := E.Message;
      WriteLog(nException+' SQl:'+ nSQL);
    end;
  end;

  if nException <> '' then
    raise Exception.Create(nException);
  //xxxxx
end;

function TFDM.QuerySQLx(const nSQL: string;
  const nUseBackdb: Boolean): TDataSet;
var nInt: Integer;
begin
  Result := nil;
  nInt := 0;

  while nInt < 2 do
  try
    if not ADOConn.Connected then
      ADOConn.Connected := True;
    //xxxxx

    Qry_Cus.Close;
    Qry_Cus.SQL.Text := nSQL;
    Qry_Cus.Open;

    Result := Qry_Cus;
    Exit;
  except
    ADOConn.Connected := False;
    Inc(nInt);
  end;
end;

function TFDM.QuerySQLChk(const nSQL: string; const nUseBackdb: Boolean): TDataSet;
var nInt: Integer;
begin
  Result := nil;
  nInt := 0;

  while nInt < 2 do
  try
    if not ADOConn.Connected then
      ADOConn.Connected := True;
    //xxxxx

    Qry_Search.Close;
    Qry_Search.SQL.Text := nSQL;
    Qry_Search.Open;

    Result := Qry_Search;
    Exit;
  except
    ADOConn.Connected := False;
    Inc(nInt);
  end;
end;

function TFDM.QuerySQL(const nSQL: string;
  const nUseBackdb: Boolean): TDataSet;
var nInt: Integer;
begin
  Result := nil;
  nInt := 0;

  while nInt < 2 do
  try
    if not ADOConn.Connected then
      ADOConn.Connected := True;
    //xxxxx

    SQLQuery1.Close;
    SQLQuery1.SQL.Text := nSQL;
    SQLQuery1.Open;

    Result := SQLQuery1;
    Exit;
  except
    ADOConn.Connected := False;
    Inc(nInt);
  end;
end;

function TFDM.QueryTemp(const nSQL:string;const nUseBackdb: Boolean): TDataSet;
var nStep: Integer;
    nException: string;
begin
  Result := nil;
  if not CheckQueryConnection(SQLTemp, nUseBackdb) then Exit;

  nException := '';
  nStep := 0;

  while nStep <= 2 do
  try
    if nStep = 1 then
    begin
      SQLTemp.Close;
      SQLTemp.SQL.Text := 'select 1';
      SQLTemp.Open;

      SQLTemp.Close;
      Break;
      //connection is ok
    end else

    if nStep = 2 then
    begin
      SQLTemp.Connection.Close;
      SQLTemp.Connection.Open;
    end; //reconnnect

    SQLTemp.Close;
    SQLTemp.SQL.Text := nSQL;
    SQLTemp.Open;

    Result := SQLTemp;
    nException := '';
    Break;
  except
    on E:Exception do
    begin
      Inc(nStep);
      nException := E.Message;
      WriteLog(nException);
    end;
  end;

  if nException <> '' then
    raise Exception.Create(nException);
  //xxxxx
end;

function TFDM.SaveDBImage(const nDS: TDataSet; const nFieldName,
  nImage: string): Boolean;
begin
//
end;

function TFDM.SaveDBImage(const nDS: TDataSet; const nFieldName: string;
  const nImage: TGraphic): Boolean;
begin
//
end;

function TFDM.SQLServerNow: string;
begin
//
end;

end.
