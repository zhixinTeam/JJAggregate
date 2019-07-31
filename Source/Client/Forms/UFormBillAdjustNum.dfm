inherited fFormBillAdjustNum: TfFormBillAdjustNum
  Left = 418
  Top = 228
  Width = 606
  Height = 403
  BorderStyle = bsSizeable
  Position = poDesktopCenter
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 12
  inherited dxLayout1: TdxLayoutControl
    Width = 598
    Height = 372
    inherited BtnOK: TButton
      Left = 452
      Top = 339
      Caption = #30830#23450
      TabOrder = 5
    end
    inherited BtnExit: TButton
      Left = 522
      Top = 339
      TabOrder = 6
    end
    object EditValue: TcxTextEdit [2]
      Left = 153
      Top = 217
      Enabled = False
      ParentFont = False
      TabOrder = 2
      Width = 200
    end
    object ListQuery: TcxListView [3]
      Left = 11
      Top = 11
      Width = 776
      Height = 151
      Align = alClient
      Columns = <
        item
          Caption = #25552#36135#21333#21495
          Width = 80
        end
        item
          Caption = #32440#21345#32534#30721
          Width = 80
        end
        item
          Caption = #19994#21153#20154#21592
          Width = 80
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
          Width = 60
        end
        item
          Caption = #25968#37327'('#21544')'
          Width = 70
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
    object EditNewPrice: TcxTextEdit [4]
      Left = 153
      Top = 242
      ParentFont = False
      TabOrder = 3
      Width = 121
    end
    object EditNewValue: TcxTextEdit [5]
      Left = 153
      Top = 267
      ParentFont = False
      TabOrder = 4
      Width = 121
    end
    object EditPrice: TcxTextEdit [6]
      Left = 153
      Top = 192
      Enabled = False
      ParentFont = False
      TabOrder = 1
      Width = 121
    end
    inherited dxLayout1Group_Root: TdxLayoutGroup
      object dxLayout1Item5: TdxLayoutItem [0]
        Control = ListQuery
        ControlOptions.ShowBorder = False
      end
      inherited dxGroup1: TdxLayoutGroup
        AutoAligns = []
        Caption = #35843#20215#35843#37327#20449#24687
        object dxLayout1Item7: TdxLayoutItem
          Caption = #21407#26469#20215#26684'('#20803'/'#21544')'#65306
          Control = EditPrice
          ControlOptions.ShowBorder = False
        end
        object dxLayout1Item4: TdxLayoutItem
          AutoAligns = [aaVertical]
          Caption = #21407#26469#25968#37327'('#21544')'#65306
          Control = EditValue
          ControlOptions.ShowBorder = False
        end
        object dxLayout1Item3: TdxLayoutItem
          Caption = #35843#25972#21518#30340#20215#26684'('#20803'/'#21544')'#65306
          Control = EditNewPrice
          ControlOptions.ShowBorder = False
        end
        object dxLayout1Item6: TdxLayoutItem
          Caption = #35843#25972#21518#30340#25968#37327'('#21544')'#65306
          Control = EditNewValue
          ControlOptions.ShowBorder = False
        end
      end
    end
  end
end
