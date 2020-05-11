inherited fFormGetZhiKa: TfFormGetZhiKa
  Left = 903
  Top = 192
  Width = 431
  Height = 468
  BorderStyle = bsSizeable
  Position = poDesktopCenter
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 12
  inherited dxLayout1: TdxLayoutControl
    Width = 415
    Height = 429
    inherited BtnOK: TButton
      Left = 269
      Top = 396
      Caption = #30830#23450
      TabOrder = 7
    end
    inherited BtnExit: TButton
      Left = 339
      Top = 396
      TabOrder = 8
    end
    object ListInfo: TcxMCListBox [2]
      Left = 23
      Top = 36
      Width = 338
      Height = 116
      HeaderSections = <
        item
          Text = #20449#24687#39033
          Width = 85
        end
        item
          AutoSize = True
          Text = #20449#24687#20869#23481
          Width = 249
        end>
      ParentFont = False
      Style.Edges = [bLeft, bTop, bRight, bBottom]
      TabOrder = 0
    end
    object EditCode: TcxButtonEdit [3]
      Left = 81
      Top = 157
      ParentFont = False
      Properties.Buttons = <
        item
          Default = True
          Kind = bkEllipsis
        end>
      Properties.OnButtonClick = EditIDPropertiesButtonClick
      TabOrder = 1
      OnKeyPress = OnCtrlKeyPress
      Width = 124
    end
    object EditSalesMan: TcxComboBox [4]
      Left = 268
      Top = 157
      ParentFont = False
      Properties.DropDownListStyle = lsEditFixedList
      Properties.DropDownRows = 20
      Properties.ImmediateDropDown = False
      Properties.ItemHeight = 18
      Properties.OnChange = EditSalesManPropertiesChange
      TabOrder = 2
      Width = 121
    end
    object EditName: TcxComboBox [5]
      Left = 81
      Top = 182
      ParentFont = False
      Properties.DropDownRows = 20
      Properties.ImmediateDropDown = False
      Properties.IncrementalSearch = False
      Properties.ItemHeight = 18
      Properties.OnEditValueChanged = EditNamePropertiesEditValueChanged
      TabOrder = 3
      OnKeyPress = EditNameKeyPress
      Width = 185
    end
    object ListDetail: TcxListView [6]
      Left = 23
      Top = 289
      Width = 355
      Height = 154
      Checkboxes = True
      Columns = <
        item
          Caption = #21697#31181#21517#31216
          Width = 120
        end
        item
          Caption = #21333#20215'('#20803'/'#21544')'
          Width = 100
        end
        item
          Caption = #21150#29702#37327'('#21544')'
          Width = 100
        end>
      HideSelection = False
      ParentFont = False
      ReadOnly = True
      RowSelect = True
      Style.Edges = [bLeft, bTop, bRight, bBottom]
      TabOrder = 6
      ViewStyle = vsReport
    end
    object EditZK: TcxComboBox [7]
      Left = 81
      Top = 264
      ParentFont = False
      Properties.DropDownListStyle = lsEditFixedList
      Properties.DropDownRows = 20
      Properties.ImmediateDropDown = False
      Properties.IncrementalSearch = False
      Properties.ItemHeight = 20
      Properties.OnEditValueChanged = EditZKPropertiesEditValueChanged
      TabOrder = 5
      OnKeyPress = EditNameKeyPress
      Width = 368
    end
    object EditProject: TcxComboBox [8]
      Left = 81
      Top = 239
      ParentFont = False
      Properties.OnEditValueChanged = EditProjectPropertiesEditValueChanged
      TabOrder = 4
      Width = 240
    end
    object chkMr: TCheckBox [9]
      Left = 327
      Top = 241
      Width = 80
      Height = 17
      Caption = #35774#20026#40664#35748
      Color = clWindow
      ParentColor = False
      TabOrder = 9
    end
    inherited dxLayout1Group_Root: TdxLayoutGroup
      inherited dxGroup1: TdxLayoutGroup
        Caption = '1.'#36873#25321#23458#25143
        object dxLayout1Item7: TdxLayoutItem
          AutoAligns = [aaHorizontal]
          Control = ListInfo
          ControlOptions.ShowBorder = False
        end
        object dxLayout1Group4: TdxLayoutGroup
          AutoAligns = [aaHorizontal]
          AlignVert = avBottom
          ShowCaption = False
          Hidden = True
          LayoutDirection = ldHorizontal
          ShowBorder = False
          object dxLayout1Item8: TdxLayoutItem
            AutoAligns = [aaVertical]
            Caption = #25552#36135#20195#30721':'
            Control = EditCode
            ControlOptions.ShowBorder = False
          end
          object dxLayout1Item9: TdxLayoutItem
            AutoAligns = [aaVertical]
            AlignHorz = ahClient
            Caption = #19994#21153#20154#21592':'
            Control = EditSalesMan
            ControlOptions.ShowBorder = False
          end
        end
        object dxLayout1Item10: TdxLayoutItem
          AutoAligns = []
          AlignHorz = ahClient
          AlignVert = avBottom
          Caption = #23458#25143#21517#31216':'
          Control = EditName
          ControlOptions.ShowBorder = False
        end
      end
      object dxGroup2: TdxLayoutGroup [1]
        AutoAligns = [aaHorizontal]
        AlignVert = avClient
        Caption = '2.'#36873#25321#32440#21345
        object dxLayout1Item5: TdxLayoutItem
          AutoAligns = [aaVertical]
          Caption = #24037#31243#24037#22320':'
          Control = EditProject
          ControlOptions.ShowBorder = False
        end
        object dxLayout1Item4: TdxLayoutItem
          Caption = #32440#21345#21015#34920':'
          Control = EditZK
          ControlOptions.ShowBorder = False
        end
        object dxLayout1Item3: TdxLayoutItem
          AutoAligns = [aaHorizontal]
          AlignVert = avClient
          Control = ListDetail
          ControlOptions.ShowBorder = False
        end
      end
    end
  end
end
