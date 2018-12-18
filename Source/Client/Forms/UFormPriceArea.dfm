inherited fFormPriceArea: TfFormPriceArea
  Left = 445
  Top = 346
  ClientHeight = 411
  ClientWidth = 379
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 12
  inherited dxLayout1: TdxLayoutControl
    Width = 379
    Height = 411
    inherited BtnOK: TButton
      Left = 233
      Top = 378
      TabOrder = 8
    end
    inherited BtnExit: TButton
      Left = 303
      Top = 378
      TabOrder = 9
    end
    object EditBegin: TcxTextEdit [2]
      Left = 81
      Top = 61
      ParentFont = False
      Properties.MaxLength = 50
      Properties.ReadOnly = True
      TabOrder = 1
      Width = 174
    end
    object cxLabel1: TcxLabel [3]
      Left = 23
      Top = 111
      AutoSize = False
      ParentFont = False
      Properties.LineOptions.Alignment = cxllaBottom
      Transparent = True
      Height = 6
      Width = 238
    end
    object EditWeek: TcxComboBox [4]
      Left = 81
      Top = 36
      ParentFont = False
      Properties.DropDownListStyle = lsFixedList
      Properties.DropDownRows = 20
      Properties.ItemHeight = 18
      Properties.OnChange = EditWeekPropertiesChange
      TabOrder = 0
      Width = 121
    end
    object EditEnd: TcxTextEdit [5]
      Left = 81
      Top = 86
      ParentFont = False
      Properties.ReadOnly = True
      TabOrder = 2
      Width = 121
    end
    object cxLabel2: TcxLabel [6]
      Left = 23
      Top = 122
      AutoSize = False
      ParentFont = False
      Properties.LineOptions.Alignment = cxllaBottom
      Properties.LineOptions.Visible = True
      Transparent = True
      Height = 8
      Width = 52
    end
    object List1: TcxListView [7]
      Left = 23
      Top = 160
      Width = 121
      Height = 97
      Columns = <
        item
          Caption = #32534#21495
        end
        item
          Caption = #21517#31216
        end
        item
          Alignment = taCenter
          Caption = #21333#20215'('#20803'/'#21544')'
        end>
      ParentFont = False
      RowSelect = True
      Style.Edges = [bLeft, bTop, bRight, bBottom]
      TabOrder = 6
      ViewStyle = vsReport
      OnDblClick = List1DblClick
      OnKeyDown = List1KeyDown
    end
    object EditArea: TcxButtonEdit [8]
      Left = 81
      Top = 135
      ParentFont = False
      Properties.Buttons = <
        item
          Default = True
          Kind = bkEllipsis
        end>
      Properties.ReadOnly = True
      Properties.OnButtonClick = EditAreaPropertiesButtonClick
      TabOrder = 5
      Width = 121
    end
    object Check1: TcxCheckBox [9]
      Left = 11
      Top = 378
      Caption = #20445#23384#21518#19981#36864#20986'.'
      ParentFont = False
      TabOrder = 7
      Transparent = True
      Width = 115
    end
    inherited dxLayout1Group_Root: TdxLayoutGroup
      inherited dxGroup1: TdxLayoutGroup
        object dxLayout1Item6: TdxLayoutItem
          Caption = #20215#26684#21608#26399':'
          Control = EditWeek
          ControlOptions.ShowBorder = False
        end
        object dxLayout1Group2: TdxLayoutGroup
          ShowCaption = False
          Hidden = True
          ShowBorder = False
          object dxLayout1Item4: TdxLayoutItem
            AutoAligns = [aaVertical]
            AlignHorz = ahClient
            Caption = #24320#22987#26102#38388':'
            Control = EditBegin
            ControlOptions.ShowBorder = False
          end
          object dxLayout1Item3: TdxLayoutItem
            Caption = #32467#26463#26102#38388':'
            Control = EditEnd
            ControlOptions.ShowBorder = False
          end
        end
        object dxLayout1Item8: TdxLayoutItem
          Caption = 'cxLabel1'
          ShowCaption = False
          Control = cxLabel1
          ControlOptions.ShowBorder = False
        end
        object dxLayout1Item5: TdxLayoutItem
          Caption = 'cxLabel2'
          ShowCaption = False
          Control = cxLabel2
          ControlOptions.ShowBorder = False
        end
        object dxLayout1Item9: TdxLayoutItem
          Caption = #21306#22495#21517#31216':'
          Control = EditArea
          ControlOptions.ShowBorder = False
        end
        object dxLayout1Item7: TdxLayoutItem
          AutoAligns = [aaHorizontal]
          AlignVert = avClient
          Caption = 'cxListView1'
          ShowCaption = False
          Control = List1
          ControlOptions.ShowBorder = False
        end
      end
      inherited dxLayout1Group1: TdxLayoutGroup
        object dxLayout1Item10: TdxLayoutItem [0]
          Caption = 'cxCheckBox1'
          ShowCaption = False
          Control = Check1
          ControlOptions.ShowBorder = False
        end
      end
    end
  end
  object PanelPrice: TcxGroupBox
    Left = 40
    Top = 220
    Caption = #35774#32622#20215#26684
    PanelStyle.Active = True
    PanelStyle.OfficeBackgroundKind = pobkGradient
    ParentColor = False
    ParentFont = False
    Style.Color = clWhite
    TabOrder = 1
    DesignSize = (
      297
      81)
    Height = 81
    Width = 297
    object BtnYes: TcxButton
      Left = 190
      Top = 52
      Width = 50
      Height = 20
      Anchors = [akRight, akBottom]
      Caption = #30830#23450
      Default = True
      TabOrder = 0
      OnClick = BtnYesClick
    end
    object BtnNo: TcxButton
      Left = 240
      Top = 52
      Width = 50
      Height = 20
      Anchors = [akRight, akBottom]
      Caption = #21462#28040
      TabOrder = 1
      OnClick = BtnNoClick
    end
    object EditStock: TcxTextEdit
      Left = 45
      Top = 24
      ParentFont = False
      Properties.ReadOnly = True
      TabOrder = 2
      Width = 245
    end
    object cxLabel3: TcxLabel
      Left = 10
      Top = 24
      Caption = #21517#31216':'
      ParentFont = False
      Transparent = True
    end
    object cxLabel4: TcxLabel
      Left = 10
      Top = 54
      Caption = #21333#20215':'
      ParentFont = False
      Transparent = True
    end
    object EditPrice: TcxButtonEdit
      Left = 45
      Top = 52
      ParentFont = False
      ParentShowHint = False
      Properties.Buttons = <
        item
          Caption = 'A'
          Hint = #20840#37096#32622#38646
          Kind = bkText
        end
        item
          Caption = '0'
          Hint = #20215#26684#32622#38646
          Kind = bkText
        end>
      Properties.OnButtonClick = EditPricePropertiesButtonClick
      ShowHint = True
      TabOrder = 5
      Text = '0'
      Width = 92
    end
  end
end
