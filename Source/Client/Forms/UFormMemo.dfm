inherited fFormMemo: TfFormMemo
  Left = 1280
  Top = 387
  Width = 357
  Height = 237
  BorderStyle = bsSizeable
  Caption = #22791#27880#20449#24687
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 12
  inherited dxLayout1: TdxLayoutControl
    Width = 341
    Height = 198
    inherited BtnOK: TButton
      Left = 195
      Top = 165
      TabOrder = 1
    end
    inherited BtnExit: TButton
      Left = 265
      Top = 165
      TabOrder = 2
    end
    object Memo1: TcxMemo [2]
      Left = 23
      Top = 36
      ParentFont = False
      Properties.ScrollBars = ssVertical
      Style.Edges = [bBottom]
      TabOrder = 0
      Height = 89
      Width = 185
    end
    inherited dxLayout1Group_Root: TdxLayoutGroup
      inherited dxGroup1: TdxLayoutGroup
        Caption = #22791#27880#20449#24687
        object dxLayout1Item3: TdxLayoutItem
          AutoAligns = [aaHorizontal]
          AlignVert = avClient
          Caption = 'cxMemo1'
          ShowCaption = False
          Control = Memo1
          ControlOptions.ShowBorder = False
        end
      end
      inherited dxLayout1Group1: TdxLayoutGroup
        inherited dxLayout1Item1: TdxLayoutItem
          AutoAligns = []
          AlignVert = avBottom
        end
      end
    end
  end
end
