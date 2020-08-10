inherited fFormBillPriceModify: TfFormBillPriceModify
  Left = 713
  Top = 268
  Caption = #24050#20986#21378#21333#25454#20215#26684#35843#25972
  ClientHeight = 306
  ClientWidth = 380
  Position = poOwnerFormCenter
  PixelsPerInch = 96
  TextHeight = 12
  inherited dxLayout1: TdxLayoutControl
    Width = 380
    Height = 306
    inherited BtnOK: TButton
      Left = 224
      Top = 271
      Width = 73
      Height = 24
      Caption = #30830#35748#35843#25972
      TabOrder = 10
    end
    inherited BtnExit: TButton
      Left = 302
      Top = 271
      Width = 67
      Height = 24
      TabOrder = 11
    end
    object EditStart: TcxDateEdit [2]
      Left = 87
      Top = 36
      ParentFont = False
      Properties.Kind = ckDateTime
      TabOrder = 0
      Width = 361
    end
    object EditEnd: TcxDateEdit [3]
      Left = 87
      Top = 61
      ParentFont = False
      Properties.Kind = ckDateTime
      TabOrder = 1
      Width = 361
    end
    object edt_StockName: TcxComboBox [4]
      Left = 87
      Top = 134
      ParentFont = False
      Properties.ItemHeight = 20
      Properties.OnChange = edt_StockNamePropertiesChange
      TabOrder = 4
      Width = 121
    end
    object edt_CusName: TcxTextEdit [5]
      Left = 87
      Top = 184
      ParentFont = False
      Properties.ReadOnly = False
      TabOrder = 6
      OnKeyPress = edt_CusNameKeyPress
      Width = 361
    end
    object edt_CusID: TcxTextEdit [6]
      Left = 87
      Top = 159
      ParentFont = False
      Properties.ReadOnly = True
      Style.BorderColor = clWindowFrame
      TabOrder = 5
      Width = 155
    end
    object edt_Price: TcxTextEdit [7]
      Left = 87
      Top = 209
      ParentFont = False
      Properties.ReadOnly = False
      TabOrder = 7
      Width = 90
    end
    object cxlbl1: TcxLabel [8]
      Left = 23
      Top = 234
      Align = alClient
      Caption = #27880': '#35843#39640#24050#20986#21378#21333#25454','#21487#33021#23548#33268#23458#25143#36164#37329#19981#36275' ('#36229#21457').'
      ParentFont = False
      Style.Font.Charset = GB2312_CHARSET
      Style.Font.Color = clBlack
      Style.Font.Height = -12
      Style.Font.Name = #23435#20307
      Style.Font.Style = []
      Style.TextColor = clRed
      Style.IsFontAssigned = True
      Properties.WordWrap = True
      Transparent = True
      Width = 334
    end
    object edt_StockNo: TcxTextEdit [9]
      Left = 87
      Top = 109
      ParentFont = False
      Properties.ReadOnly = True
      TabOrder = 3
      Width = 155
    end
    object cxlbl2: TcxLabel [10]
      Left = 23
      Top = 86
      Align = alClient
      AutoSize = False
      Caption = #27880': '#26102#38388#27573#20026#20986#21378#26102#38388
      ParentFont = False
      Style.Font.Charset = GB2312_CHARSET
      Style.Font.Color = clBlack
      Style.Font.Height = -12
      Style.Font.Name = #23435#20307
      Style.Font.Style = []
      Style.TextColor = clRed
      Style.IsFontAssigned = True
      Properties.WordWrap = True
      Transparent = True
      Height = 18
      Width = 294
    end
    object cxlbl3: TcxLabel [11]
      Left = 182
      Top = 209
      Caption = #20803
      ParentFont = False
      Style.Font.Charset = GB2312_CHARSET
      Style.Font.Color = clBlack
      Style.Font.Height = -12
      Style.Font.Name = #23435#20307
      Style.Font.Style = []
      Style.TextColor = clGreen
      Style.TextStyle = [fsBold]
      Style.IsFontAssigned = True
      Properties.WordWrap = True
      Transparent = True
      Width = 17
    end
    inherited dxLayout1Group_Root: TdxLayoutGroup
      inherited dxGroup1: TdxLayoutGroup
        object dxLayout1Item3: TdxLayoutItem
          Caption = #24320#22987#26102#38388#65306
          Control = EditStart
          ControlOptions.ShowBorder = False
        end
        object dxLayout1Item4: TdxLayoutItem
          Caption = #32467#26463#26102#38388#65306
          Control = EditEnd
          ControlOptions.ShowBorder = False
        end
        object dxlytmLayout1Item57: TdxLayoutItem
          ShowCaption = False
          Control = cxlbl2
          ControlOptions.ShowBorder = False
        end
        object dxlytmLayout1Item56: TdxLayoutItem
          AutoAligns = [aaVertical]
          Caption = #29289#26009#32534#21495#65306
          Control = edt_StockNo
          ControlOptions.ShowBorder = False
        end
        object dxlytmLayout1Item5: TdxLayoutItem
          Caption = #29289#26009#21697#31181#65306
          Control = edt_StockName
          ControlOptions.ShowBorder = False
        end
        object dxlytmLayout1Item52: TdxLayoutItem
          AutoAligns = [aaVertical]
          Caption = #23458#25143#32534#21495#65306
          Control = edt_CusID
          ControlOptions.ShowBorder = False
        end
        object dxlytmLayout1Item51: TdxLayoutItem
          Caption = #23458#25143#21517#31216#65306
          Control = edt_CusName
          ControlOptions.ShowBorder = False
        end
        object dxLayout1Group2: TdxLayoutGroup
          ShowCaption = False
          Hidden = True
          LayoutDirection = ldHorizontal
          ShowBorder = False
          object dxlytmLayout1Item53: TdxLayoutItem
            AutoAligns = [aaVertical]
            Caption = #24403#21069#21806#20215#65306
            Control = edt_Price
            ControlOptions.ShowBorder = False
          end
          object dxlytmLayout1Item54: TdxLayoutItem
            ShowCaption = False
            Control = cxlbl3
            ControlOptions.ShowBorder = False
          end
        end
        object dxlytmLayout1Item55: TdxLayoutItem
          AutoAligns = [aaVertical]
          AlignHorz = ahClient
          ShowCaption = False
          Control = cxlbl1
          ControlOptions.ShowBorder = False
        end
      end
    end
  end
end
