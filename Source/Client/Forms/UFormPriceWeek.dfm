inherited fFormPriceWeek: TfFormPriceWeek
  Left = 574
  Top = 431
  ClientHeight = 268
  ClientWidth = 284
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 12
  inherited dxLayout1: TdxLayoutControl
    Width = 284
    Height = 268
    inherited BtnOK: TButton
      Left = 138
      Top = 235
      TabOrder = 7
    end
    inherited BtnExit: TButton
      Left = 208
      Top = 235
      TabOrder = 8
    end
    object EditName: TcxTextEdit [2]
      Left = 81
      Top = 36
      Hint = 'T.W_Name'
      ParentFont = False
      Properties.MaxLength = 50
      TabOrder = 0
      Width = 174
    end
    object EditMemo: TcxMemo [3]
      Left = 81
      Top = 148
      Hint = 'T.W_Memo'
      ParentFont = False
      Properties.MaxLength = 50
      Properties.ScrollBars = ssVertical
      Style.Edges = [bBottom]
      TabOrder = 5
      Height = 45
      Width = 403
    end
    object EditStart: TcxDateEdit [4]
      Left = 81
      Top = 61
      Hint = 'T.W_Begin'
      ParentFont = False
      Properties.Kind = ckDateTime
      TabOrder = 1
      Width = 168
    end
    object EditEnd: TcxDateEdit [5]
      Left = 81
      Top = 123
      Hint = 'T.W_End'
      ParentFont = False
      Properties.Kind = ckDateTime
      TabOrder = 4
      Width = 121
    end
    object Check1: TcxCheckBox [6]
      Left = 11
      Top = 235
      Hint = 'T.W_Valid'
      Caption = #21608#26399#26377#25928
      ParentFont = False
      TabOrder = 6
      Transparent = True
      Width = 86
    end
    object Check2: TcxCheckBox [7]
      Left = 23
      Top = 97
      Caption = #20020#26102#20215#26684': '#21040#26399#21518#33258#21160#21551#29992#38271#26399#20215'.'
      ParentFont = False
      Properties.OnChange = Check2PropertiesChange
      TabOrder = 3
      Transparent = True
      Width = 121
    end
    object cxLabel1: TcxLabel [8]
      Left = 23
      Top = 86
      AutoSize = False
      ParentFont = False
      Properties.LineOptions.Alignment = cxllaBottom
      Transparent = True
      Height = 6
      Width = 238
    end
    inherited dxLayout1Group_Root: TdxLayoutGroup
      inherited dxGroup1: TdxLayoutGroup
        object dxLayout1Item4: TdxLayoutItem
          AutoAligns = [aaVertical]
          AlignHorz = ahClient
          Caption = #21608#26399#21517#31216':'
          Control = EditName
          ControlOptions.ShowBorder = False
        end
        object dxLayout1Group2: TdxLayoutGroup
          ShowCaption = False
          Hidden = True
          ShowBorder = False
          object dxLayout1Item3: TdxLayoutItem
            Caption = #24320#22987#26102#38388':'
            Control = EditStart
            ControlOptions.ShowBorder = False
          end
          object dxLayout1Item8: TdxLayoutItem
            Caption = 'cxLabel1'
            ShowCaption = False
            Control = cxLabel1
            ControlOptions.ShowBorder = False
          end
          object dxLayout1Item7: TdxLayoutItem
            Caption = 'cxCheckBox1'
            ShowCaption = False
            Control = Check2
            ControlOptions.ShowBorder = False
          end
          object dxLayout1Item5: TdxLayoutItem
            AutoAligns = [aaVertical]
            AlignHorz = ahClient
            Caption = #32467#26463#26102#38388':'
            Control = EditEnd
            ControlOptions.ShowBorder = False
          end
        end
        object dxLayout1Item12: TdxLayoutItem
          AutoAligns = [aaHorizontal]
          AlignVert = avClient
          Caption = #22791#27880#20449#24687':'
          CaptionOptions.AlignVert = tavTop
          Control = EditMemo
          ControlOptions.ShowBorder = False
        end
      end
      inherited dxLayout1Group1: TdxLayoutGroup
        object dxLayout1Item6: TdxLayoutItem [0]
          Caption = 'cxCheckBox1'
          ShowCaption = False
          Control = Check1
          ControlOptions.ShowBorder = False
        end
      end
    end
  end
end
