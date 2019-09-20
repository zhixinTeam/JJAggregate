inherited fFormCarrier: TfFormCarrier
  Left = 586
  Top = 381
  ClientHeight = 132
  ClientWidth = 375
  Position = poMainFormCenter
  PixelsPerInch = 96
  TextHeight = 12
  inherited dxLayout1: TdxLayoutControl
    Width = 375
    Height = 132
    inherited BtnOK: TButton
      Left = 229
      Top = 99
      TabOrder = 1
    end
    inherited BtnExit: TButton
      Left = 299
      Top = 99
      TabOrder = 2
    end
    object EditCarrier: TcxTextEdit [2]
      Left = 93
      Top = 36
      ParentFont = False
      Properties.MaxLength = 100
      TabOrder = 0
      Width = 125
    end
    inherited dxLayout1Group_Root: TdxLayoutGroup
      inherited dxGroup1: TdxLayoutGroup
        object dxLayout1Item5: TdxLayoutItem
          AutoAligns = [aaVertical]
          AlignHorz = ahClient
          Caption = #25215#36816#21830#21517#31216':'
          Control = EditCarrier
          ControlOptions.ShowBorder = False
        end
      end
    end
  end
end
