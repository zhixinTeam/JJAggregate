inherited fFormWXAccount: TfFormWXAccount
  Left = 523
  Top = 464
  ClientHeight = 177
  ClientWidth = 377
  Position = poMainFormCenter
  PixelsPerInch = 96
  TextHeight = 12
  inherited dxLayout1: TdxLayoutControl
    Width = 377
    Height = 177
    inherited BtnOK: TButton
      Left = 231
      Top = 144
      Caption = #30830#23450
      TabOrder = 3
    end
    inherited BtnExit: TButton
      Left = 301
      Top = 144
      TabOrder = 4
    end
    object EditName: TcxTextEdit [2]
      Left = 81
      Top = 36
      ParentFont = False
      Properties.MaxLength = 64
      Properties.ReadOnly = False
      Style.BorderColor = clWindowFrame
      Style.BorderStyle = ebsOffice11
      TabOrder = 0
      OnKeyPress = OnCtrlKeyPress
      Width = 121
    end
    object EditMemo: TcxTextEdit [3]
      Left = 81
      Top = 61
      ParentFont = False
      Properties.MaxLength = 100
      Properties.ReadOnly = False
      Style.BorderColor = clWindowFrame
      Style.BorderStyle = ebsOffice11
      TabOrder = 1
      OnKeyPress = OnCtrlKeyPress
      Width = 121
    end
    object Check1: TcxCheckBox [4]
      Left = 23
      Top = 86
      Caption = #26159#21542#26377#25928
      ParentFont = False
      TabOrder = 2
      Transparent = True
      Width = 121
    end
    inherited dxLayout1Group_Root: TdxLayoutGroup
      inherited dxGroup1: TdxLayoutGroup
        Caption = ''
        object dxLayout1Item3: TdxLayoutItem
          Caption = #24494#20449#21517#31216':'
          Control = EditName
          ControlOptions.ShowBorder = False
        end
        object dxLayout1Item4: TdxLayoutItem
          Caption = #22791#27880#20449#24687':'
          Control = EditMemo
          ControlOptions.ShowBorder = False
        end
        object dxLayout1Item5: TdxLayoutItem
          Caption = 'cxCheckBox1'
          ShowCaption = False
          Control = Check1
          ControlOptions.ShowBorder = False
        end
      end
    end
  end
end
