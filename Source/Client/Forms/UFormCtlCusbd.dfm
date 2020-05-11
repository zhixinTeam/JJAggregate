inherited fFormCtlCusbd: TfFormCtlCusbd
  Left = 556
  Top = 300
  Caption = #31649#29702#23458#25143#32465#23450
  ClientHeight = 269
  ClientWidth = 592
  PixelsPerInch = 96
  TextHeight = 12
  inherited dxLayout1: TdxLayoutControl
    Width = 592
    Height = 269
    inherited BtnOK: TButton
      Left = 446
      Top = 236
      Caption = #35299#38500#32465#23450
      TabOrder = 3
    end
    inherited BtnExit: TButton
      Left = 516
      Top = 236
      TabOrder = 4
    end
    object EditContent: TcxComboBox [2]
      Left = 129
      Top = 36
      ParentFont = False
      Properties.DropDownRows = 20
      Properties.ItemHeight = 18
      Properties.OnEditValueChanged = cbbEditCustomPropertiesEditValueChanged
      TabOrder = 0
      Width = 270
    end
    object ListCustom: TcxListView [3]
      Left = 23
      Top = 65
      Width = 454
      Height = 159
      Columns = <
        item
          Caption = #24207#21495
          Width = 70
        end
        item
          Caption = #32534#21495
          Width = 80
        end
        item
          Caption = #23458#25143#21517#31216
          Width = 230
        end
        item
          Caption = #21040#26399#26102#38388
          Width = 157
        end>
      HideSelection = False
      ParentFont = False
      ReadOnly = True
      RowSelect = True
      SmallImages = FDM.ImageBar
      TabOrder = 2
      ViewStyle = vsReport
    end
    object btn1: TButton [4]
      Left = 404
      Top = 36
      Width = 65
      Height = 22
      Caption = #26597#25214
      TabOrder = 1
      OnClick = btn1Click
    end
    inherited dxLayout1Group_Root: TdxLayoutGroup
      inherited dxGroup1: TdxLayoutGroup
        object dxLayout1Group2: TdxLayoutGroup
          ShowCaption = False
          Hidden = True
          LayoutDirection = ldHorizontal
          ShowBorder = False
          object dxlytmLayout1Item3: TdxLayoutItem
            Caption = #23458#25143#21517#31216#25110#36710#29260#21495':'
            Control = EditContent
            ControlOptions.ShowBorder = False
          end
          object dxlytmLayout1Item32: TdxLayoutItem
            Control = btn1
            ControlOptions.ShowBorder = False
          end
        end
        object dxlytmLayout1Item31: TdxLayoutItem
          AutoAligns = [aaHorizontal]
          AlignVert = avBottom
          Control = ListCustom
          ControlOptions.ShowBorder = False
        end
      end
    end
  end
end
