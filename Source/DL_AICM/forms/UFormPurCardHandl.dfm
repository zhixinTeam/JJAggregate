object FormPurCardHandl: TFormPurCardHandl
  Left = 502
  Top = 103
  BorderStyle = bsNone
  Caption = #21407#26009#25163#24037#24320#21333
  ClientHeight = 796
  ClientWidth = 1101
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = #23435#20307
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnShow = FormShow
  DesignSize = (
    1101
    796)
  PixelsPerInch = 96
  TextHeight = 12
  object lbl1: TLabel
    Left = 13
    Top = 15
    Width = 158
    Height = 31
    Caption = #35831#36755#20837#35746#21333#21495' :'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -24
    Font.Name = #24494#36719#38597#40657
    Font.Style = [fsBold]
    ParentFont = False
  end
  object lbl9: TLabel
    Left = 57
    Top = 112
    Width = 103
    Height = 38
    Caption = #20379#24212#21830' :'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -29
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    ParentFont = False
  end
  object lbl_ProName: TLabel
    Left = 181
    Top = 112
    Width = 243
    Height = 38
    Caption = '                           '
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clHighlight
    Font.Height = -29
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    ParentFont = False
  end
  object lbl8: TLabel
    Left = 28
    Top = 170
    Width = 132
    Height = 38
    Caption = #21407#26009#21517#31216' :'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -29
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    ParentFont = False
  end
  object lbl_MName: TLabel
    Left = 181
    Top = 170
    Width = 243
    Height = 38
    Caption = '                           '
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clHighlight
    Font.Height = -29
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    ParentFont = False
  end
  object lbl7: TLabel
    Left = 28
    Top = 232
    Width = 132
    Height = 38
    Caption = #25910#36135#20844#21496' :'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -29
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    ParentFont = False
  end
  object lbl6: TLabel
    Left = 23
    Top = 348
    Width = 132
    Height = 38
    Caption = #24320#21333#21544#25968' :'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -29
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    ParentFont = False
  end
  object lbl4: TLabel
    Left = 23
    Top = 398
    Width = 132
    Height = 38
    Caption = #36710#29260#21495#30721' :'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -29
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    ParentFont = False
  end
  object lbl2: TLabel
    Left = 25
    Top = 289
    Width = 132
    Height = 38
    Caption = #25215#36816#20844#21496' :'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -29
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    ParentFont = False
  end
  object lbl_Company: TLabel
    Left = 180
    Top = 232
    Width = 243
    Height = 38
    Caption = '                           '
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clHighlight
    Font.Height = -29
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    ParentFont = False
  end
  object lbl_TranCmp: TLabel
    Left = 181
    Top = 289
    Width = 243
    Height = 38
    Caption = '                           '
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clHighlight
    Font.Height = -29
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    ParentFont = False
  end
  object edt1: TEdit
    Left = 186
    Top = 17
    Width = 311
    Height = 33
    BevelEdges = [beBottom]
    BevelKind = bkFlat
    BevelOuter = bvRaised
    BiDiMode = bdLeftToRight
    BorderStyle = bsNone
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -24
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    ParentBiDiMode = False
    ParentFont = False
    TabOrder = 0
  end
  object btn1: TButton
    Left = 516
    Top = 16
    Width = 137
    Height = 35
    Caption = #26597#25214
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -24
    Font.Name = #24494#36719#38597#40657
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 1
    OnClick = btn1Click
  end
  object dbgrd1: TDBGrid
    Left = 982
    Top = 73
    Width = 1066
    Height = 431
    Anchors = [akLeft, akTop, akRight]
    Ctl3D = False
    DataSource = Ds_Mx1
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -24
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs, dgRowSelect, dgConfirmDelete, dgCancelOnExit]
    ParentCtl3D = False
    ParentFont = False
    ReadOnly = True
    TabOrder = 2
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -21
    TitleFont.Name = #24494#36719#38597#40657
    TitleFont.Style = []
    Visible = False
    OnCellClick = dbgrd1CellClick
    Columns = <
      item
        Expanded = False
        FieldName = 'B_ID'
        Title.Caption = #21512#21516#32534#21495
        Width = 187
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'B_ProName'
        Title.Caption = #20379#24212#21830#21517#31216
        Width = 516
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'B_StockName'
        Title.Caption = #21407#26009#21517#31216
        Width = 226
        Visible = True
      end>
  end
  object cbb_Company: TcxComboBox
    Left = 973
    Top = 530
    ParentFont = False
    Properties.DropDownListStyle = lsFixedList
    Properties.ItemHeight = 28
    Style.BorderColor = clWindowFrame
    Style.BorderStyle = ebsSingle
    Style.Color = clBtnFace
    Style.Font.Charset = DEFAULT_CHARSET
    Style.Font.Color = clWindowText
    Style.Font.Height = -27
    Style.Font.Name = #23435#20307
    Style.Font.Style = []
    Style.TextColor = clMenuHighlight
    Style.ButtonStyle = btsDefault
    Style.PopupBorderStyle = epbsSingle
    Style.IsFontAssigned = True
    StyleDisabled.BorderColor = clMenuHighlight
    StyleDisabled.BorderStyle = ebsSingle
    StyleDisabled.Color = clCream
    StyleDisabled.ButtonStyle = btsDefault
    TabOrder = 3
    Visible = False
    Width = 494
  end
  object edt_Value: TcxTextEdit
    Left = 181
    Top = 351
    ParentFont = False
    Properties.ReadOnly = False
    Style.BorderColor = clWindowFrame
    Style.BorderStyle = ebsSingle
    Style.Font.Charset = DEFAULT_CHARSET
    Style.Font.Color = clWindowText
    Style.Font.Height = -27
    Style.Font.Name = #23435#20307
    Style.Font.Style = []
    Style.IsFontAssigned = True
    TabOrder = 4
    Text = '0'
    OnKeyPress = edt_ValueKeyPress
    Width = 181
  end
  object btnOK: TButton
    Left = 441
    Top = 389
    Width = 260
    Height = 49
    Caption = #30830#35748#26080#35823#24182#21150#21345
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -24
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    ParentFont = False
    TabOrder = 5
    OnClick = btnOKClick
  end
  object btnExit: TButton
    Left = 713
    Top = 389
    Width = 116
    Height = 49
    Caption = #21462#28040
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -24
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    ParentFont = False
    TabOrder = 6
    OnClick = btnExitClick
  end
  object cbb_TruckNo: TcxComboBox
    Left = 181
    Top = 401
    ParentFont = False
    Properties.ItemHeight = 25
    Properties.Items.Strings = (
      #28189'CK'
      #28189'D'
      #28189'K'
      #28189'A'
      #24029
      #36149
      #35947
      #26187
      #20864
      #38485)
    Style.BorderColor = clWindowFrame
    Style.BorderStyle = ebsSingle
    Style.Color = clBtnFace
    Style.Font.Charset = DEFAULT_CHARSET
    Style.Font.Color = clWindowText
    Style.Font.Height = -27
    Style.Font.Name = #23435#20307
    Style.Font.Style = []
    Style.TextColor = clWindowText
    Style.ButtonStyle = btsDefault
    Style.PopupBorderStyle = epbsSingle
    Style.IsFontAssigned = True
    StyleDisabled.BorderColor = clMenuHighlight
    StyleDisabled.BorderStyle = ebsSingle
    StyleDisabled.Color = clCream
    StyleDisabled.ButtonStyle = btsDefault
    TabOrder = 7
    Width = 179
  end
  object cbb_TranCmp: TcxComboBox
    Left = 973
    Top = 576
    ParentFont = False
    Properties.ItemHeight = 28
    Properties.OnChange = cbb_TranCmpPropertiesChange
    Style.BorderColor = clWindowFrame
    Style.BorderStyle = ebsSingle
    Style.Color = clBtnFace
    Style.Font.Charset = DEFAULT_CHARSET
    Style.Font.Color = clWindowText
    Style.Font.Height = -27
    Style.Font.Name = #23435#20307
    Style.Font.Style = []
    Style.TextColor = clMenuHighlight
    Style.ButtonStyle = btsDefault
    Style.PopupBorderStyle = epbsSingle
    Style.IsFontAssigned = True
    StyleDisabled.BorderColor = clMenuHighlight
    StyleDisabled.BorderStyle = ebsSingle
    StyleDisabled.Color = clCream
    StyleDisabled.ButtonStyle = btsDefault
    TabOrder = 8
    Visible = False
    Width = 494
  end
  object Ds_Mx1: TDataSource
    DataSet = CltDs_1
    Left = 708
    Top = 15
  end
  object Qry_1: TADOQuery
    DataSource = Ds_Mx1
    Parameters = <>
    Left = 742
    Top = 15
  end
  object CltDs_1: TClientDataSet
    Aggregates = <>
    Params = <>
    ProviderName = 'dtstprvdr1'
    Left = 782
    Top = 15
  end
  object dtstprvdr1: TDataSetProvider
    DataSet = Qry_1
    Left = 810
    Top = 15
  end
  object TimerAutoClose: TTimer
    Enabled = False
    Left = 850
    Top = 14
  end
  object Qry_2: TADOQuery
    Parameters = <>
    Left = 742
    Top = 53
  end
end
