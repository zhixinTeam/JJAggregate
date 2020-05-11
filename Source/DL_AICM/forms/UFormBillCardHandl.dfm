object FormBillCardHandl: TFormBillCardHandl
  Left = 447
  Top = 86
  BorderStyle = bsNone
  Caption = #33258#21161#30003#35831#21150#21345
  ClientHeight = 778
  ClientWidth = 964
  Color = clMenuHighlight
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = #24494#36719#38597#40657
  Font.Style = []
  OldCreateOrder = False
  OnShow = FormShow
  DesignSize = (
    964
    778)
  PixelsPerInch = 96
  TextHeight = 17
  object lbl1: TLabel
    Left = 13
    Top = 38
    Width = 205
    Height = 48
    Caption = #36755#20837#25552#36135#30721' :'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -37
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    ParentFont = False
  end
  object lbl2: TLabel
    Left = 235
    Top = 127
    Width = 351
    Height = 57
    Caption = '                           '
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -43
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    ParentFont = False
  end
  object lbl3: TLabel
    Left = 235
    Top = 217
    Width = 351
    Height = 57
    Caption = '                           '
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -43
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    ParentFont = False
  end
  object lbl4: TLabel
    Left = 18
    Top = 310
    Width = 195
    Height = 57
    Caption = #36873#25321#32440#21345' :'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -43
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    ParentFont = False
  end
  object lbl5: TLabel
    Left = 18
    Top = 402
    Width = 195
    Height = 57
    Caption = #39592#26009#21697#31181' :'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -43
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    ParentFont = False
  end
  object lbl6: TLabel
    Left = 18
    Top = 497
    Width = 195
    Height = 57
    Caption = #24320#21333#21544#25968' :'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -43
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    ParentFont = False
  end
  object lbl7: TLabel
    Left = 18
    Top = 588
    Width = 195
    Height = 57
    Caption = #36710#29260#21495#30721' :'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -43
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    ParentFont = False
  end
  object lbl8: TLabel
    Left = 18
    Top = 218
    Width = 195
    Height = 57
    Caption = #23458#25143#21517#31216' :'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -43
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    ParentFont = False
  end
  object lbl9: TLabel
    Left = 18
    Top = 124
    Width = 195
    Height = 57
    Caption = #23458#25143#32534#21495' :'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -43
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    ParentFont = False
  end
  object lbl10: TLabel
    Left = 433
    Top = 514
    Width = 136
    Height = 36
    Caption = '                 '
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -27
    Font.Name = #24494#36719#38597#40657
    Font.Style = [fsBold]
    ParentFont = False
  end
  object lbl_ZhiKa: TLabel
    Left = 236
    Top = 314
    Width = 351
    Height = 57
    Caption = '                           '
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -43
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    ParentFont = False
  end
  object lbl_Close: TLabel
    Left = 882
    Top = 19
    Width = 117
    Height = 57
    Anchors = [akTop, akRight]
    Caption = '         '
    Color = clMenuHighlight
    Font.Charset = DEFAULT_CHARSET
    Font.Color = 2474495
    Font.Height = -43
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    ParentColor = False
    ParentFont = False
  end
  object edt1: TEdit
    Left = 232
    Top = 41
    Width = 331
    Height = 47
    BevelEdges = [beBottom]
    BevelKind = bkFlat
    BevelOuter = bvRaised
    BiDiMode = bdLeftToRight
    BorderStyle = bsNone
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -35
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    ParentBiDiMode = False
    ParentFont = False
    TabOrder = 0
    OnKeyPress = edt1KeyPress
  end
  object btn1: TButton
    Left = 587
    Top = 39
    Width = 208
    Height = 51
    Caption = #26597#25214
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -29
    Font.Name = #24494#36719#38597#40657
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 1
    OnClick = btn1Click
  end
  object cbb_Stocks: TcxComboBox
    Left = 236
    Top = 416
    ParentFont = False
    Properties.DropDownListStyle = lsFixedList
    Properties.DropDownRows = 6
    Properties.ItemHeight = 35
    Properties.OnEditValueChanged = cbb_StocksPropertiesEditValueChanged
    Style.BorderColor = clWindowFrame
    Style.BorderStyle = ebsSingle
    Style.Color = clBtnFace
    Style.Font.Charset = DEFAULT_CHARSET
    Style.Font.Color = clWindowText
    Style.Font.Height = -35
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
    TabOrder = 2
    Width = 314
  end
  object edt_Value: TcxTextEdit
    Left = 235
    Top = 509
    ParentFont = False
    Properties.ReadOnly = False
    Style.BorderColor = clWindowFrame
    Style.BorderStyle = ebsSingle
    Style.Font.Charset = DEFAULT_CHARSET
    Style.Font.Color = clWindowText
    Style.Font.Height = -35
    Style.Font.Name = #23435#20307
    Style.Font.Style = []
    Style.IsFontAssigned = True
    TabOrder = 3
    OnKeyPress = edt_ValueKeyPress
    Width = 156
  end
  object btnOK: TButton
    Left = 408
    Top = 702
    Width = 261
    Height = 53
    Caption = #30830#35748#26080#35823#24182#21150#21345
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -27
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    ParentFont = False
    TabOrder = 4
    OnClick = btnOKClick
  end
  object btnBtnExit: TButton
    Left = 679
    Top = 702
    Width = 117
    Height = 53
    Caption = #21462#28040
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -27
    Font.Name = #24494#36719#38597#40657
    Font.Style = []
    ParentFont = False
    TabOrder = 5
    OnClick = btnBtnExitClick
  end
  object cbb_TruckNo: TcxComboBox
    Left = 235
    Top = 607
    ParentFont = False
    Properties.ItemHeight = 35
    Properties.Items.Strings = (
      #28189'D'
      #28189'C'
      #28189'K'
      #28189'A'
      #24029
      #36149
      #35947
      #26187
      #20864
      #38485)
    Properties.OnEditValueChanged = cbb_StocksPropertiesEditValueChanged
    Style.BorderColor = clWindowFrame
    Style.BorderStyle = ebsSingle
    Style.Color = clBtnFace
    Style.Font.Charset = DEFAULT_CHARSET
    Style.Font.Color = clWindowText
    Style.Font.Height = -35
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
    TabOrder = 6
    Text = #28189'D'
    OnKeyPress = cbb_TruckNoKeyPress
    Width = 313
  end
  object Ds_Mx1: TDataSource
    Left = 669
    Top = 6
  end
  object Qry_1: TADOQuery
    DataSource = Ds_Mx1
    Parameters = <>
    Left = 709
    Top = 6
  end
  object TimerAutoClose: TTimer
    Enabled = False
    OnTimer = TimerAutoCloseTimer
    Left = 751
    Top = 6
  end
end
