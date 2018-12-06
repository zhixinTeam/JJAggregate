inherited fFrameAuditTruck: TfFrameAuditTruck
  Width = 879
  Height = 544
  inherited ToolBar1: TToolBar
    Width = 879
    inherited BtnAdd: TToolButton
      Caption = #23457#26680
      OnClick = BtnAddClick
    end
    inherited BtnEdit: TToolButton
      Visible = False
    end
    inherited BtnDel: TToolButton
      OnClick = BtnDelClick
    end
  end
  inherited cxGrid1: TcxGrid
    Top = 205
    Width = 879
    Height = 339
    LevelTabs.Slants.Kind = skCutCorner
    LevelTabs.Style = 9
    RootLevelOptions.DetailTabsPosition = dtpTop
    OnActiveTabChanged = cxGrid1ActiveTabChanged
    inherited cxView1: TcxGridDBTableView
      PopupMenu = PMenu1
      OnDblClick = cxView1DblClick
    end
    inherited cxLevel1: TcxGridLevel
      Caption = #24050#30003#35831
    end
    object cxLevel2: TcxGridLevel
      Tag = 1
      Caption = #24050#36890#36807
    end
    object cxLevel3: TcxGridLevel
      Tag = 2
      Caption = #24050#39539#22238
    end
  end
  inherited dxLayout1: TdxLayoutControl
    Width = 879
    Height = 138
    object EditSerial: TcxButtonEdit [0]
      Left = 81
      Top = 36
      ParentFont = False
      Properties.Buttons = <
        item
          Default = True
          Kind = bkEllipsis
        end>
      Properties.OnButtonClick = EditTruckPropertiesButtonClick
      TabOrder = 0
      OnKeyPress = OnCtrlKeyPress
      Width = 125
    end
    object EditTruck: TcxButtonEdit [1]
      Left = 269
      Top = 36
      ParentFont = False
      Properties.Buttons = <
        item
          Default = True
          Kind = bkEllipsis
        end>
      Properties.OnButtonClick = EditTruckPropertiesButtonClick
      TabOrder = 1
      OnKeyPress = OnCtrlKeyPress
      Width = 125
    end
    object EditDate: TcxButtonEdit [2]
      Left = 457
      Top = 36
      ParentFont = False
      Properties.Buttons = <
        item
          Default = True
          Kind = bkEllipsis
        end>
      Properties.ReadOnly = True
      Properties.OnButtonClick = EditDatePropertiesButtonClick
      TabOrder = 2
      Width = 185
    end
    object cxTextEdit1: TcxTextEdit [3]
      Left = 81
      Top = 93
      Hint = 'T.A_Serial'
      ParentFont = False
      TabOrder = 3
      Width = 125
    end
    object cxTextEdit3: TcxTextEdit [4]
      Left = 269
      Top = 93
      Hint = 'T.A_Truck'
      ParentFont = False
      TabOrder = 4
      Width = 125
    end
    object cxTextEdit2: TcxTextEdit [5]
      Left = 457
      Top = 93
      Hint = 'T.A_Memo'
      ParentFont = False
      TabOrder = 5
      Width = 121
    end
    inherited dxGroup1: TdxLayoutGroup
      inherited GroupSearch1: TdxLayoutGroup
        object dxLayout1Item1: TdxLayoutItem
          Caption = #36710#36742#31867#22411':'
          Control = EditSerial
          ControlOptions.ShowBorder = False
        end
        object dxLayout1Item3: TdxLayoutItem
          Caption = #36710#29260#21495#30721':'
          Control = EditTruck
          ControlOptions.ShowBorder = False
        end
        object dxLayout1Item2: TdxLayoutItem
          Caption = #26085#26399#31579#36873':'
          Control = EditDate
          ControlOptions.ShowBorder = False
        end
      end
      inherited GroupDetail1: TdxLayoutGroup
        object dxLayout1Item6: TdxLayoutItem
          Caption = #36710#36742#31867#22411':'
          Control = cxTextEdit1
          ControlOptions.ShowBorder = False
        end
        object dxLayout1Item7: TdxLayoutItem
          Caption = #36710#29260#21495#30721':'
          Control = cxTextEdit3
          ControlOptions.ShowBorder = False
        end
        object dxLayout1Item4: TdxLayoutItem
          AutoAligns = [aaVertical]
          AlignHorz = ahClient
          Caption = #23457#26680#22791#27880':'
          Control = cxTextEdit2
          ControlOptions.ShowBorder = False
        end
      end
    end
  end
  inherited cxSplitter1: TcxSplitter
    Top = 197
    Width = 879
  end
  inherited TitlePanel1: TZnBitmapPanel
    Width = 879
    inherited TitleBar: TcxLabel
      Caption = #36710#36742#23457#26680#35760#24405
      Style.IsFontAssigned = True
      Width = 879
      AnchorX = 440
      AnchorY = 11
    end
  end
  inherited SQLQuery: TADOQuery
    Left = 2
    Top = 233
  end
  inherited DataSource1: TDataSource
    Left = 30
    Top = 233
  end
  object PMenu1: TPopupMenu
    AutoHotkeys = maManual
    Left = 2
    Top = 262
    object N1: TMenuItem
      Caption = #21516#27493#24494#20449#31471#23457#26680#20449#24687
      OnClick = N1Click
    end
    object N16: TMenuItem
      Caption = '-'
    end
    object N2: TMenuItem
      Caption = #23457#26680#36873#20013#36710#36742
      OnClick = N2Click
    end
    object N3: TMenuItem
      Caption = #20851#32852#38271#26399#21345
      OnClick = N3Click
    end
    object N4: TMenuItem
      Caption = #21462#28040#38271#26399#21345#20851#32852
      OnClick = N4Click
    end
    object N5: TMenuItem
      Caption = #33719#21462#35746#21333#20449#24687
      OnClick = N5Click
    end
  end
end
