inherited fFormAuditTruck: TfFormAuditTruck
  Left = 381
  Top = 62
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = #36710#36742#23457#26680
  ClientHeight = 506
  ClientWidth = 593
  OldCreateOrder = True
  Position = poMainFormCenter
  PixelsPerInch = 96
  TextHeight = 12
  object dxLayoutControl1: TdxLayoutControl
    Left = 0
    Top = 0
    Width = 593
    Height = 506
    Align = alClient
    TabOrder = 0
    TabStop = False
    AutoContentSizes = [acsWidth, acsHeight]
    LookAndFeel = FDM.dxLayoutWeb1
    object EditType: TcxTextEdit
      Left = 81
      Top = 329
      ParentFont = False
      Properties.ReadOnly = True
      TabOrder = 1
      Width = 209
    end
    object EditTruck: TcxTextEdit
      Left = 81
      Top = 354
      ParentFont = False
      Properties.ReadOnly = True
      TabOrder = 2
      Width = 121
    end
    object EditMemo: TcxMemo
      Left = 81
      Top = 404
      Align = alClient
      ParentFont = False
      Properties.ScrollBars = ssVertical
      TabOrder = 4
      Height = 40
      Width = 252
    end
    object BtnExit: TButton
      Left = 507
      Top = 456
      Width = 75
      Height = 22
      Caption = #21462#28040
      ModalResult = 2
      TabOrder = 6
    end
    object BtnOK: TButton
      Left = 427
      Top = 456
      Width = 75
      Height = 22
      Caption = #30830#23450
      TabOrder = 5
      OnClick = BtnOKClick
    end
    object ImageTruck: TcxImage
      Left = 81
      Top = 36
      Align = alTop
      AutoSize = True
      Properties.ReadOnly = True
      TabOrder = 0
      Height = 288
      Width = 489
    end
    object EditResult: TcxComboBox
      Left = 81
      Top = 379
      Properties.DropDownListStyle = lsFixedList
      Properties.Items.Strings = (
        #36890#36807
        #39539#22238)
      Properties.ReadOnly = False
      TabOrder = 3
      Text = #36890#36807
      Width = 121
    end
    object dxLayoutControl1Group_Root: TdxLayoutGroup
      ShowCaption = False
      Hidden = True
      ShowBorder = False
      object dxLayoutControl1Group1: TdxLayoutGroup
        AutoAligns = []
        AlignHorz = ahClient
        Caption = #36710#36742#20449#24687
        object dxLayoutControl1Item9: TdxLayoutItem
          Caption = #36710#36742#22270#29255
          Control = ImageTruck
          ControlOptions.ShowBorder = False
        end
        object dxLayoutControl1Item1: TdxLayoutItem
          Caption = #36710#36742#31867#22411':'
          Control = EditType
          ControlOptions.ShowBorder = False
        end
        object dxLayoutControl1Item2: TdxLayoutItem
          Caption = #36710#29260#21495#30721':'
          Control = EditTruck
          ControlOptions.ShowBorder = False
        end
        object dxLayoutControl1Item3: TdxLayoutItem
          Caption = #23457#26680#32467#26524':'
          Control = EditResult
          ControlOptions.ShowBorder = False
        end
        object dxLayoutControl1Item6: TdxLayoutItem
          Caption = #23457#26680#22791#27880':'
          Control = EditMemo
          ControlOptions.ShowBorder = False
        end
      end
      object dxLayoutControl1Group2: TdxLayoutGroup
        AutoAligns = [aaVertical]
        AlignHorz = ahRight
        ShowCaption = False
        Hidden = True
        LayoutDirection = ldHorizontal
        ShowBorder = False
        object dxLayoutControl1Item8: TdxLayoutItem
          AutoAligns = [aaVertical]
          AlignHorz = ahRight
          Caption = 'Button2'
          ShowCaption = False
          Control = BtnOK
          ControlOptions.ShowBorder = False
        end
        object dxLayoutControl1Item7: TdxLayoutItem
          AutoAligns = []
          AlignHorz = ahRight
          AlignVert = avBottom
          Caption = 'Button1'
          ShowCaption = False
          Control = BtnExit
          ControlOptions.ShowBorder = False
        end
      end
    end
  end
end
