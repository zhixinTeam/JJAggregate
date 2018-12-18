inherited fFormTruck: TfFormTruck
  Left = 586
  Top = 381
  ClientHeight = 367
  ClientWidth = 334
  Position = poMainFormCenter
  PixelsPerInch = 96
  TextHeight = 12
  inherited dxLayout1: TdxLayoutControl
    Width = 334
    Height = 367
    inherited BtnOK: TButton
      Left = 188
      Top = 334
      TabOrder = 14
    end
    inherited BtnExit: TButton
      Left = 258
      Top = 334
      TabOrder = 15
    end
    object EditTruck: TcxTextEdit [2]
      Left = 81
      Top = 36
      ParentFont = False
      Properties.MaxLength = 15
      TabOrder = 0
      Width = 116
    end
    object EditOwner: TcxTextEdit [3]
      Left = 81
      Top = 61
      ParentFont = False
      Properties.MaxLength = 100
      TabOrder = 1
      Width = 125
    end
    object EditPhone: TcxTextEdit [4]
      Left = 81
      Top = 86
      ParentFont = False
      TabOrder = 2
      Width = 121
    end
    object CheckValid: TcxCheckBox [5]
      Left = 23
      Top = 249
      Caption = #36710#36742#20801#35768#24320#21333'.'
      ParentFont = False
      TabOrder = 9
      Transparent = True
      Width = 80
    end
    object CheckVerify: TcxCheckBox [6]
      Left = 23
      Top = 301
      Caption = #39564#35777#36710#36742#24050#21040#20572#36710#22330'.'
      ParentFont = False
      TabOrder = 12
      Transparent = True
      Width = 165
    end
    object CheckUserP: TcxCheckBox [7]
      Left = 23
      Top = 275
      Caption = #36710#36742#20351#29992#39044#32622#30382#37325'.'
      ParentFont = False
      TabOrder = 10
      Transparent = True
      Width = 165
    end
    object CheckVip: TcxCheckBox [8]
      Left = 193
      Top = 275
      Caption = 'VIP'#36710#36742
      ParentFont = False
      TabOrder = 11
      Transparent = True
      Width = 100
    end
    object CheckGPS: TcxCheckBox [9]
      Left = 193
      Top = 301
      Caption = #24050#23433#35013'GPS'
      ParentFont = False
      TabOrder = 13
      Transparent = True
      Width = 100
    end
    object EditIgnore: TcxTextEdit [10]
      Left = 81
      Top = 146
      TabOrder = 6
      Text = '0'
      Width = 121
    end
    object EditNet: TcxTextEdit [11]
      Left = 81
      Top = 121
      Properties.ReadOnly = True
      TabOrder = 4
      Width = 121
    end
    object cxLabel1: TcxLabel [12]
      Left = 23
      Top = 111
      AutoSize = False
      ParentFont = False
      Transparent = True
      Height = 5
      Width = 316
    end
    object Label1: TcxLabel [13]
      Left = 23
      Top = 171
      Align = alClient
      AutoSize = False
      Caption = #27880': '#24403#24320#21333#37327#19981#33021#23567#20110#21382#21490#26368#22823#20928#37325#26102','#21487#20197#35774#32622#20363#22806#36710#27425#25968'.'
      ParentFont = False
      Properties.WordWrap = True
      Transparent = True
      Height = 38
      Width = 288
    end
    object Label2: TcxLabel [14]
      Left = 295
      Top = 121
      Caption = #21544
      ParentFont = False
      Transparent = True
    end
    object Label3: TcxLabel [15]
      Left = 295
      Top = 146
      Caption = #27425
      ParentFont = False
      Transparent = True
    end
    inherited dxLayout1Group_Root: TdxLayoutGroup
      inherited dxGroup1: TdxLayoutGroup
        object dxLayout1Item9: TdxLayoutItem
          AutoAligns = [aaVertical]
          AlignHorz = ahClient
          Caption = #36710#29260#21495#30721':'
          Control = EditTruck
          ControlOptions.ShowBorder = False
        end
        object dxLayout1Item5: TdxLayoutItem
          AutoAligns = [aaVertical]
          AlignHorz = ahClient
          Caption = #36710#20027#22995#21517':'
          Control = EditOwner
          ControlOptions.ShowBorder = False
        end
        object dxLayout1Item3: TdxLayoutItem
          AutoAligns = [aaVertical]
          AlignHorz = ahClient
          Caption = #32852#31995#26041#24335':'
          Control = EditPhone
          ControlOptions.ShowBorder = False
        end
        object dxLayout1Item13: TdxLayoutItem
          Caption = 'cxLabel1'
          ShowCaption = False
          Control = cxLabel1
          ControlOptions.ShowBorder = False
        end
        object dxLayout1Group3: TdxLayoutGroup
          ShowCaption = False
          Hidden = True
          LayoutDirection = ldHorizontal
          ShowBorder = False
          object dxLayout1Item12: TdxLayoutItem
            AutoAligns = [aaVertical]
            AlignHorz = ahClient
            Caption = #21382#21490#20928#37325':'
            Control = EditNet
            ControlOptions.ShowBorder = False
          end
          object dxLayout1Item15: TdxLayoutItem
            Caption = 'cxLabel2'
            ShowCaption = False
            Control = Label2
            ControlOptions.ShowBorder = False
          end
        end
        object dxLayout1Group5: TdxLayoutGroup
          ShowCaption = False
          Hidden = True
          LayoutDirection = ldHorizontal
          ShowBorder = False
          object dxLayout1Item11: TdxLayoutItem
            AutoAligns = [aaVertical]
            AlignHorz = ahClient
            Caption = #21487' '#24573' '#30053':'
            Control = EditIgnore
            ControlOptions.ShowBorder = False
          end
          object dxLayout1Item16: TdxLayoutItem
            ShowCaption = False
            Control = Label3
            ControlOptions.ShowBorder = False
          end
        end
        object dxLayout1Item14: TdxLayoutItem
          Caption = 'cxLabel2'
          ShowCaption = False
          Control = Label1
          ControlOptions.ShowBorder = False
        end
      end
      object dxGroup2: TdxLayoutGroup [1]
        Caption = #36710#36742#21442#25968
        object dxLayout1Item4: TdxLayoutItem
          Caption = 'cxCheckBox1'
          ShowCaption = False
          Control = CheckValid
          ControlOptions.ShowBorder = False
        end
        object dxLayout1Group2: TdxLayoutGroup
          ShowCaption = False
          Hidden = True
          LayoutDirection = ldHorizontal
          ShowBorder = False
          object dxLayout1Item6: TdxLayoutItem
            ShowCaption = False
            Control = CheckUserP
            ControlOptions.ShowBorder = False
          end
          object dxLayout1Item8: TdxLayoutItem
            Caption = 'cxCheckBox1'
            ShowCaption = False
            Control = CheckVip
            ControlOptions.ShowBorder = False
          end
        end
        object dxLayout1Group4: TdxLayoutGroup
          ShowCaption = False
          Hidden = True
          LayoutDirection = ldHorizontal
          ShowBorder = False
          object dxLayout1Item7: TdxLayoutItem
            Caption = 'cxCheckBox2'
            ShowCaption = False
            Control = CheckVerify
            ControlOptions.ShowBorder = False
          end
          object dxLayout1Item10: TdxLayoutItem
            Caption = 'cxCheckBox1'
            ShowCaption = False
            Control = CheckGPS
            ControlOptions.ShowBorder = False
          end
        end
      end
    end
  end
end
