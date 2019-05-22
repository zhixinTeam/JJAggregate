inherited fFormOrderDtl: TfFormOrderDtl
  Left = 610
  Top = 230
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  ClientHeight = 240
  ClientWidth = 480
  OldCreateOrder = True
  OnClose = FormClose
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 12
  object dxLayoutControl1: TdxLayoutControl
    Left = 0
    Top = 0
    Width = 480
    Height = 240
    Align = alClient
    TabOrder = 0
    TabStop = False
    AutoContentSizes = [acsWidth, acsHeight]
    LookAndFeel = FDM.dxLayoutWeb1
    object EditMemo: TcxMemo
      Left = 81
      Top = 136
      Hint = 'D.D_Memo'
      ParentFont = False
      Properties.MaxLength = 50
      Properties.ScrollBars = ssVertical
      Style.Edges = [bBottom]
      TabOrder = 8
      Height = 45
      Width = 385
    end
    object BtnOK: TButton
      Left = 324
      Top = 207
      Width = 70
      Height = 22
      Caption = #20445#23384
      TabOrder = 10
      OnClick = BtnOKClick
    end
    object BtnExit: TButton
      Left = 399
      Top = 207
      Width = 70
      Height = 22
      Caption = #21462#28040
      TabOrder = 11
      OnClick = BtnExitClick
    end
    object EditPValue: TcxTextEdit
      Left = 81
      Top = 111
      Hint = 'D.D_PValue'
      ParentFont = False
      TabOrder = 3
      Width = 144
    end
    object EditMValue: TcxTextEdit
      Left = 288
      Top = 111
      Hint = 'D.D_MValue'
      ParentFont = False
      TabOrder = 7
      Width = 161
    end
    object EditProID: TcxButtonEdit
      Left = 81
      Top = 61
      Hint = 'D.D_ProID'
      ParentFont = False
      Properties.Buttons = <
        item
          Default = True
          Kind = bkEllipsis
        end>
      TabOrder = 1
      OnKeyPress = EditStockKeyPress
      Width = 121
    end
    object EditProName: TcxTextEdit
      Left = 288
      Top = 61
      Hint = 'D.D_ProName'
      ParentFont = False
      TabOrder = 5
      Width = 121
    end
    object EditStock: TcxButtonEdit
      Left = 81
      Top = 36
      Hint = 'D.D_StockNo'
      ParentFont = False
      Properties.Buttons = <
        item
          Default = True
          Kind = bkEllipsis
        end>
      TabOrder = 0
      OnKeyPress = EditStockKeyPress
      Width = 121
    end
    object EditStockName: TcxTextEdit
      Left = 288
      Top = 36
      Hint = 'D.D_StockName'
      ParentFont = False
      TabOrder = 4
      Width = 121
    end
    object EditTruck: TcxButtonEdit
      Left = 81
      Top = 86
      Hint = 'D.D_Truck'
      ParentFont = False
      Properties.Buttons = <
        item
          Default = True
          Kind = bkEllipsis
        end>
      TabOrder = 2
      OnKeyPress = EditStockKeyPress
      Width = 121
    end
    object cxTextEdit3: TcxTextEdit
      Left = 288
      Top = 86
      Hint = 'D.D_KZValue'
      ParentFont = False
      TabOrder = 6
      Width = 121
    end
    object EditCheck: TcxCheckBox
      Left = 11
      Top = 207
      Caption = #26356#26032#21150#21345#35760#24405
      ParentFont = False
      State = cbsChecked
      TabOrder = 9
      Transparent = True
      Width = 121
    end
    object dxLayoutControl1Group_Root: TdxLayoutGroup
      ShowCaption = False
      Hidden = True
      ShowBorder = False
      object dxLayoutControl1Group1: TdxLayoutGroup
        Caption = #22522#26412#20449#24687
        object dxLayoutControl1Group3: TdxLayoutGroup
          ShowCaption = False
          Hidden = True
          LayoutDirection = ldHorizontal
          ShowBorder = False
          object dxLayoutControl1Group2: TdxLayoutGroup
            ShowCaption = False
            Hidden = True
            ShowBorder = False
            object dxLayoutControl1Item6: TdxLayoutItem
              Caption = #21407#26448#26009'ID:'
              Control = EditStock
              ControlOptions.ShowBorder = False
            end
            object dxLayoutControl1Item3: TdxLayoutItem
              Caption = #20379#24212#21830'ID:'
              Control = EditProID
              ControlOptions.ShowBorder = False
            end
            object dxLayoutControl1Item9: TdxLayoutItem
              Caption = #36710#29260#21495#30721':'
              Control = EditTruck
              ControlOptions.ShowBorder = False
            end
            object dxLayoutControl1Item1: TdxLayoutItem
              Caption = #30382#37325'('#21544'):'
              Control = EditPValue
              ControlOptions.ShowBorder = False
            end
          end
          object dxLayoutControl1Group4: TdxLayoutGroup
            ShowCaption = False
            Hidden = True
            ShowBorder = False
            object dxLayoutControl1Item7: TdxLayoutItem
              Caption = #21407' '#26448' '#26009':'
              Control = EditStockName
              ControlOptions.ShowBorder = False
            end
            object dxLayoutControl1Item5: TdxLayoutItem
              Caption = #20379' '#24212' '#21830':'
              Control = EditProName
              ControlOptions.ShowBorder = False
            end
            object dxLayoutControl1Item12: TdxLayoutItem
              Caption = #25187#26434'('#21544'):'
              Control = cxTextEdit3
              ControlOptions.ShowBorder = False
            end
            object dxLayoutControl1Item2: TdxLayoutItem
              Caption = #27611#37325'('#21544'):'
              Control = EditMValue
              ControlOptions.ShowBorder = False
            end
          end
        end
        object dxLayoutControl1Item4: TdxLayoutItem
          Caption = #22791#27880#20449#24687':'
          Control = EditMemo
          ControlOptions.ShowBorder = False
        end
      end
      object dxLayoutControl1Group5: TdxLayoutGroup
        AutoAligns = [aaHorizontal]
        AlignVert = avBottom
        ShowCaption = False
        Hidden = True
        LayoutDirection = ldHorizontal
        ShowBorder = False
        object dxLayoutControl1Item8: TdxLayoutItem
          Caption = 'cxCheckBox1'
          ShowCaption = False
          Control = EditCheck
          ControlOptions.ShowBorder = False
        end
        object dxLayoutControl1Item10: TdxLayoutItem
          AutoAligns = [aaVertical]
          AlignHorz = ahRight
          Caption = 'Button3'
          ShowCaption = False
          Control = BtnOK
          ControlOptions.ShowBorder = False
        end
        object dxLayoutControl1Item11: TdxLayoutItem
          AutoAligns = [aaVertical]
          AlignHorz = ahRight
          Caption = 'Button4'
          ShowCaption = False
          Control = BtnExit
          ControlOptions.ShowBorder = False
        end
      end
    end
  end
end
