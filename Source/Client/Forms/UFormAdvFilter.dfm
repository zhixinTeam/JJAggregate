inherited fFormAdvFilter: TfFormAdvFilter
  Left = 1758
  Top = 503
  Width = 321
  Height = 356
  BorderStyle = bsSizeable
  Caption = #39640#32423#31579#36873
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 12
  inherited dxLayout1: TdxLayoutControl
    Width = 313
    Height = 329
    inherited BtnOK: TButton
      Left = 167
      Top = 296
      Caption = #30830#23450
      TabOrder = 2
    end
    inherited BtnExit: TButton
      Left = 237
      Top = 296
      TabOrder = 3
    end
    object List1: TcxCheckListBox [2]
      Left = 81
      Top = 61
      Width = 262
      Height = 173
      Images = Image1
      ImageLayout = ilAfterChecks
      Items = <>
      ParentFont = False
      TabOrder = 1
      OnClickCheck = List1ClickCheck
    end
    object Edit1: TcxTextEdit [3]
      Left = 81
      Top = 36
      ParentFont = False
      Properties.OnChange = Edit1PropertiesChange
      TabOrder = 0
      OnKeyPress = Edit1KeyPress
      Width = 121
    end
    inherited dxLayout1Group_Root: TdxLayoutGroup
      inherited dxGroup1: TdxLayoutGroup
        object dxLayout1Item4: TdxLayoutItem
          Caption = #31579#36873#26465#20214':'
          Control = Edit1
          ControlOptions.ShowBorder = False
        end
        object dxLayout1Item3: TdxLayoutItem
          AutoAligns = [aaHorizontal]
          AlignVert = avClient
          Caption = #21487#36873#21015#34920':'
          CaptionOptions.AlignVert = tavTop
          Control = List1
          ControlOptions.ShowBorder = False
        end
      end
    end
  end
  object Image1: TcxImageList
    Height = 18
    Width = 2
    FormatVersion = 1
    DesignInfo = 4194400
  end
end
