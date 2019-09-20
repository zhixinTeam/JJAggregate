inherited fFormBillKW: TfFormBillKW
  Left = 418
  Top = 228
  Width = 595
  Height = 388
  BorderStyle = bsSizeable
  Position = poDesktopCenter
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 12
  inherited dxLayout1: TdxLayoutControl
    Width = 587
    Height = 357
    inherited BtnOK: TButton
      Left = 441
      Top = 324
      Caption = #30830#23450
      TabOrder = 6
    end
    inherited BtnExit: TButton
      Left = 511
      Top = 324
      TabOrder = 7
    end
    object EditSalesMan: TcxComboBox [2]
      Left = 99
      Top = 192
      ParentFont = False
      Properties.DropDownListStyle = lsEditFixedList
      Properties.DropDownRows = 20
      Properties.ImmediateDropDown = False
      Properties.ItemHeight = 18
      Properties.OnChange = EditSalesManPropertiesChange
      TabOrder = 1
      Width = 200
    end
    object EditName: TcxComboBox [3]
      Left = 99
      Top = 217
      ParentFont = False
      Properties.DropDownRows = 20
      Properties.ImmediateDropDown = False
      Properties.IncrementalSearch = False
      Properties.ItemHeight = 18
      Properties.OnChange = EditNamePropertiesEditValueChanged
      Properties.OnEditValueChanged = EditNamePropertiesEditValueChanged
      TabOrder = 2
      OnKeyPress = EditNameKeyPress
      Width = 200
    end
    object EditZK: TcxComboBox [4]
      Left = 99
      Top = 242
      ParentFont = False
      Properties.DropDownListStyle = lsEditFixedList
      Properties.DropDownRows = 20
      Properties.ImmediateDropDown = False
      Properties.IncrementalSearch = False
      Properties.ItemHeight = 20
      Properties.OnEditValueChanged = EditZKPropertiesEditValueChanged
      TabOrder = 3
      OnKeyPress = EditNameKeyPress
      Width = 200
    end
    object EditPrice: TcxTextEdit [5]
      Left = 99
      Top = 267
      ParentFont = False
      TabOrder = 4
      Width = 200
    end
    object ListQuery: TcxListView [6]
      Left = 11
      Top = 11
      Width = 776
      Height = 151
      Align = alClient
      Columns = <
        item
          Caption = #25552#36135#21333#21495
          Width = 90
        end
        item
          Caption = #32440#21345#32534#30721
          Width = 90
        end
        item
          Caption = #19994#21153#20154#21592
          Width = 90
        end
        item
          Caption = #23458#25143#21517#31216
          Width = 110
        end
        item
          Caption = #21333#20215'('#20803'/'#21544')'
          Width = 90
        end
        item
          Caption = #36710#29260#21495
          Width = 90
        end>
      HideSelection = False
      ParentFont = False
      ReadOnly = True
      RowSelect = True
      SmallImages = FDM.ImageBar
      Style.Edges = [bLeft, bTop, bRight, bBottom]
      TabOrder = 0
      ViewStyle = vsReport
    end
    object EditProject: TcxTextEdit [7]
      Left = 99
      Top = 292
      ParentFont = False
      TabOrder = 5
      Width = 121
    end
    inherited dxLayout1Group_Root: TdxLayoutGroup
      object dxLayout1Item5: TdxLayoutItem [0]
        Control = ListQuery
        ControlOptions.ShowBorder = False
      end
      inherited dxGroup1: TdxLayoutGroup
        AutoAligns = []
        Caption = #20462#25913#21518#20449#24687
        object dxLayout1Item9: TdxLayoutItem
          AutoAligns = [aaVertical]
          Caption = #19994#21153#20154#21592':'
          Control = EditSalesMan
          ControlOptions.ShowBorder = False
        end
        object dxLayout1Item10: TdxLayoutItem
          AutoAligns = []
          Caption = #23458#25143#21517#31216':'
          Control = EditName
          ControlOptions.ShowBorder = False
        end
        object dxLayout1Item3: TdxLayoutItem
          AutoAligns = [aaVertical]
          Caption = #32440#21345#32534#30721':'
          Control = EditZK
          ControlOptions.ShowBorder = False
        end
        object dxLayout1Item4: TdxLayoutItem
          AutoAligns = [aaVertical]
          Caption = #20215#26684'('#20803'/'#21544'):'
          Control = EditPrice
          ControlOptions.ShowBorder = False
        end
        object dxLayout1Item6: TdxLayoutItem
          Caption = #24037#31243#24037#22320':'
          Control = EditProject
          ControlOptions.ShowBorder = False
        end
      end
    end
  end
end
