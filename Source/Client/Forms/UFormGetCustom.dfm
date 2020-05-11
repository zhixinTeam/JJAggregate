inherited fFormGetCustom: TfFormGetCustom
  Left = 619
  Top = 253
  Width = 470
  Height = 347
  BorderStyle = bsSizeable
  Constraints.MinHeight = 300
  Constraints.MinWidth = 445
  Position = poDesktopCenter
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 12
  inherited dxLayout1: TdxLayoutControl
    Width = 454
    Height = 308
    inherited BtnOK: TButton
      Left = 298
      Top = 270
      Width = 70
      Height = 24
      Caption = #30830#23450
      TabOrder = 6
    end
    inherited BtnExit: TButton
      Left = 373
      Top = 270
      Width = 70
      Height = 24
      TabOrder = 7
    end
    object EditSMan: TcxComboBox [2]
      Left = 81
      Top = 61
      ParentFont = False
      Properties.DropDownListStyle = lsEditFixedList
      Properties.DropDownRows = 20
      Properties.ItemHeight = 18
      Properties.OnEditValueChanged = EditSManPropertiesEditValueChanged
      TabOrder = 1
      Width = 121
    end
    object EditCustom: TcxComboBox [3]
      Left = 81
      Top = 86
      ParentFont = False
      Properties.DropDownRows = 20
      Properties.ItemHeight = 18
      Properties.OnEditValueChanged = EditCustomPropertiesEditValueChanged
      TabOrder = 2
      Width = 121
    end
    object EditCus: TcxButtonEdit [4]
      Left = 81
      Top = 36
      ParentFont = False
      Properties.Buttons = <
        item
          Default = True
          Kind = bkEllipsis
        end>
      Properties.OnButtonClick = EditCIDPropertiesButtonClick
      TabOrder = 0
      OnKeyPress = OnCtrlKeyPress
      Width = 121
    end
    object ListCustom: TcxListView [5]
      Left = 23
      Top = 132
      Width = 417
      Height = 145
      Columns = <
        item
          Caption = #23458#25143#32534#21495
          Width = 70
        end
        item
          Caption = #19994#21153#21592
          Width = 70
        end
        item
          Caption = #23458#25143#21517#31216
          Width = 230
        end>
      HideSelection = False
      ParentFont = False
      ReadOnly = True
      RowSelect = True
      SmallImages = FDM.ImageBar
      Style.Edges = [bLeft, bTop, bRight, bBottom]
      TabOrder = 4
      ViewStyle = vsReport
      OnDblClick = ListCustomDblClick
      OnKeyPress = ListCustomKeyPress
    end
    object cxLabel1: TcxLabel [6]
      Left = 23
      Top = 111
      Caption = #26597#35810#32467#26524':'
      ParentFont = False
      Transparent = True
    end
    object InValidTime: TcxDateEdit [7]
      Left = 75
      Top = 270
      ParentFont = False
      Properties.Kind = ckDateTime
      Style.Font.Charset = GB2312_CHARSET
      Style.Font.Color = clBlack
      Style.Font.Height = -13
      Style.Font.Name = #24494#36719#38597#40657
      Style.Font.Style = []
      Style.IsFontAssigned = True
      TabOrder = 5
      Width = 169
    end
    inherited dxLayout1Group_Root: TdxLayoutGroup
      inherited dxGroup1: TdxLayoutGroup
        Caption = #26597#35810#26465#20214
        object dxLayout1Item5: TdxLayoutItem
          Caption = #23458#25143#21517#31216':'
          Control = EditCus
          ControlOptions.ShowBorder = False
        end
        object dxLayout1Group2: TdxLayoutGroup
          ShowCaption = False
          Hidden = True
          ShowBorder = False
          object dxLayout1Item3: TdxLayoutItem
            Caption = #19994#21153#20154#21592':'
            Control = EditSMan
            ControlOptions.ShowBorder = False
          end
          object dxLayout1Item4: TdxLayoutItem
            Caption = #23458#25143'('#36873'):'
            Control = EditCustom
            ControlOptions.ShowBorder = False
          end
        end
        object dxLayout1Item7: TdxLayoutItem
          Caption = 'cxLabel1'
          ShowCaption = False
          Control = cxLabel1
          ControlOptions.ShowBorder = False
        end
        object dxLayout1Item6: TdxLayoutItem
          AutoAligns = [aaHorizontal]
          AlignVert = avClient
          Caption = #26597#35810#32467#26524':'
          ShowCaption = False
          Control = ListCustom
          ControlOptions.ShowBorder = False
        end
      end
      inherited dxLayout1Group1: TdxLayoutGroup
        object dxLayout1Item8: TdxLayoutItem [0]
          Caption = #22833#25928#26085#26399#65306
          Control = InValidTime
          ControlOptions.ShowBorder = False
        end
      end
    end
  end
end
