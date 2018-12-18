inherited fFormPriceShow: TfFormPriceShow
  Left = 479
  Top = 373
  Width = 495
  Height = 319
  BorderStyle = bsSizeable
  Caption = #26597#30475
  OnClose = FormClose
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 12
  inherited dxLayout1: TdxLayoutControl
    Width = 479
    Height = 280
    inherited BtnOK: TButton
      Left = 333
      Top = 247
      Caption = #30830#23450
      TabOrder = 1
    end
    inherited BtnExit: TButton
      Left = 403
      Top = 247
      TabOrder = 2
    end
    object ListPrice: TcxListView [2]
      Left = 23
      Top = 36
      Width = 373
      Height = 119
      Columns = <
        item
          Caption = #21697#31181#21517#31216
          Width = 80
        end
        item
          Alignment = taCenter
          Caption = #20215#26684'('#20803'/'#21544')'
          Width = 80
        end
        item
          Caption = #20215#26684#25551#36848
          Width = 200
        end>
      ParentFont = False
      ReadOnly = True
      RowSelect = True
      SmallImages = FDM.ImageBar
      Style.Edges = [bLeft, bTop, bRight, bBottom]
      TabOrder = 0
      ViewStyle = vsReport
    end
    inherited dxLayout1Group_Root: TdxLayoutGroup
      inherited dxGroup1: TdxLayoutGroup
        Caption = #20215#26684#28165#21333
        object dxLayout1Item3: TdxLayoutItem
          AutoAligns = [aaHorizontal]
          AlignVert = avClient
          Control = ListPrice
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
