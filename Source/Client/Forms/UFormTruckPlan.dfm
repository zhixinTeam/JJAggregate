inherited fFormTruckPlan: TfFormTruckPlan
  Left = 586
  Top = 381
  ClientHeight = 284
  ClientWidth = 498
  Position = poMainFormCenter
  PixelsPerInch = 96
  TextHeight = 12
  inherited dxLayout1: TdxLayoutControl
    Width = 498
    Height = 284
    inherited BtnOK: TButton
      Left = 352
      Top = 251
      TabOrder = 6
    end
    inherited BtnExit: TButton
      Left = 422
      Top = 251
      TabOrder = 7
    end
    object EditCus: TcxButtonEdit [2]
      Left = 81
      Top = 36
      ParentFont = False
      Properties.Buttons = <
        item
          Default = True
          Kind = bkEllipsis
        end>
      Properties.ReadOnly = True
      Properties.OnButtonClick = EditCusPropertiesButtonClick
      TabOrder = 0
      Width = 224
    end
    object EditBegin: TcxDateEdit [3]
      Left = 81
      Top = 61
      ParentFont = False
      Properties.SaveTime = False
      Properties.ShowTime = False
      TabOrder = 1
      Width = 121
    end
    object EditEnd: TcxDateEdit [4]
      Left = 81
      Top = 86
      ParentFont = False
      Properties.SaveTime = False
      Properties.ShowTime = False
      TabOrder = 2
      Width = 121
    end
    object EditTrucks: TcxMemo [5]
      Left = 81
      Top = 111
      ParentFont = False
      TabOrder = 3
      OnDragDrop = EditTrucksDragDrop
      OnDragOver = EditTrucksDragOver
      Height = 89
      Width = 185
    end
    object ListHistory: TcxListBox [6]
      Left = 368
      Top = 61
      Width = 148
      Height = 172
      DragMode = dmAutomatic
      ItemHeight = 14
      ParentFont = False
      PopupMenu = PMenu1
      Style.Font.Charset = DEFAULT_CHARSET
      Style.Font.Color = clWindowText
      Style.Font.Height = -14
      Style.Font.Name = #23435#20307
      Style.Font.Style = []
      Style.IsFontAssigned = True
      TabOrder = 5
    end
    object EditTruck: TcxTextEdit [7]
      Left = 368
      Top = 36
      ParentFont = False
      Properties.OnChange = EditTruckPropertiesChange
      TabOrder = 4
      OnKeyPress = EditTruckKeyPress
      Width = 121
    end
    inherited dxLayout1Group_Root: TdxLayoutGroup
      inherited dxGroup1: TdxLayoutGroup
        LayoutDirection = ldHorizontal
        object dxLayout1Group3: TdxLayoutGroup
          ShowCaption = False
          Hidden = True
          ShowBorder = False
          object dxLayout1Item3: TdxLayoutItem
            Caption = #23458#25143#21517#31216':'
            Control = EditCus
            ControlOptions.ShowBorder = False
          end
          object dxLayout1Item4: TdxLayoutItem
            Caption = #29983#25928#26085#26399':'
            Control = EditBegin
            ControlOptions.ShowBorder = False
          end
          object dxLayout1Item5: TdxLayoutItem
            Caption = #22833#25928#26085#26399':'
            Control = EditEnd
            ControlOptions.ShowBorder = False
          end
          object dxLayout1Item6: TdxLayoutItem
            AutoAligns = [aaHorizontal]
            AlignVert = avClient
            Caption = #36710#36742#21015#34920':'
            Control = EditTrucks
            ControlOptions.ShowBorder = False
          end
        end
        object dxLayout1Group2: TdxLayoutGroup
          AutoAligns = [aaVertical]
          AlignHorz = ahClient
          ShowCaption = False
          Hidden = True
          ShowBorder = False
          object dxLayout1Item8: TdxLayoutItem
            Caption = #36710#36742#26816#32034':'
            Control = EditTruck
            ControlOptions.ShowBorder = False
          end
          object dxLayout1Item7: TdxLayoutItem
            AutoAligns = []
            AlignHorz = ahClient
            AlignVert = avClient
            Caption = #21382#21490#36710#36742':'
            Control = ListHistory
            ControlOptions.ShowBorder = False
          end
        end
      end
    end
  end
  object PMenu1: TPopupMenu
    AutoHotkeys = maManual
    Left = 392
    Top = 120
    object N1: TMenuItem
      Tag = 10
      Caption = #20840#37096#28155#21152
      OnClick = N1Click
    end
    object N3: TMenuItem
      Tag = 10
      Caption = #21047#26032#21015#34920
      Checked = True
      RadioItem = True
      OnClick = N3Click
    end
    object N2: TMenuItem
      Caption = '-'
    end
    object N6: TMenuItem
      Tag = 20
      Caption = #26174#31034#38544#34255
      RadioItem = True
      OnClick = N3Click
    end
    object N4: TMenuItem
      Tag = 10
      Caption = #38544#34255#36710#36742
      OnClick = N4Click
    end
    object N5: TMenuItem
      Tag = 20
      Caption = #26174#31034#36710#36742
      OnClick = N4Click
    end
  end
end
