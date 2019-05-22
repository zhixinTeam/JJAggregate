inherited fFormZhiKa: TfFormZhiKa
  Left = 505
  Top = 319
  ClientHeight = 413
  ClientWidth = 378
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 12
  inherited dxLayout1: TdxLayoutControl
    Width = 378
    Height = 413
    AutoControlAlignment = False
    inherited BtnOK: TButton
      Left = 232
      Top = 380
      TabOrder = 13
    end
    inherited BtnExit: TButton
      Left = 302
      Top = 380
      TabOrder = 14
    end
    object EditPName: TcxTextEdit [2]
      Left = 81
      Top = 86
      ParentFont = False
      Properties.MaxLength = 100
      TabOrder = 2
      Width = 121
    end
    object EditLading: TcxComboBox [3]
      Left = 81
      Top = 111
      ParentFont = False
      Properties.DropDownListStyle = lsEditFixedList
      Properties.DropDownRows = 20
      Properties.IncrementalSearch = False
      Properties.ItemHeight = 18
      Properties.Items.Strings = (
        'T=T'#12289#33258#25552
        'S=S'#12289#36865#36135
        'X=X'#12289#36816#21368)
      Properties.MaxLength = 20
      TabOrder = 3
      Width = 105
    end
    object EditDays: TcxDateEdit [4]
      Left = 249
      Top = 111
      ParentFont = False
      Properties.SaveTime = False
      Properties.ShowTime = False
      TabOrder = 4
      Width = 121
    end
    object EditName: TcxTextEdit [5]
      Left = 81
      Top = 61
      ParentFont = False
      Properties.MaxLength = 100
      TabOrder = 1
      Width = 110
    end
    object EditCode: TcxButtonEdit [6]
      Left = 81
      Top = 149
      ParentFont = False
      Properties.Buttons = <
        item
          Default = True
          Kind = bkEllipsis
        end>
      Properties.ReadOnly = True
      Properties.OnButtonClick = EditCodePropertiesButtonClick
      TabOrder = 6
      Width = 121
    end
    object EditAll: TcxTextEdit [7]
      Left = 81
      Top = 174
      ParentFont = False
      Properties.ReadOnly = True
      TabOrder = 7
      Text = '0'
      Width = 105
    end
    object EditMoney: TcxTextEdit [8]
      Left = 81
      Top = 199
      ParentFont = False
      ParentShowHint = False
      Properties.OnChange = EditMoneyPropertiesChange
      ShowHint = False
      TabOrder = 9
      Text = '0'
      Width = 121
    end
    object EditCustomer: TcxButtonEdit [9]
      Left = 81
      Top = 36
      ParentFont = False
      Properties.Buttons = <
        item
          Default = True
          Kind = bkEllipsis
        end>
      Properties.ReadOnly = True
      Properties.OnButtonClick = EditCustomerPropertiesButtonClick
      TabOrder = 0
      Width = 122
    end
    object Label1: TcxLabel [10]
      Left = 23
      Top = 136
      AutoSize = False
      ParentFont = False
      Properties.LineOptions.Alignment = cxllaBottom
      Transparent = True
      Height = 8
      Width = 353
    end
    object ListItems: TcxCheckListBox [11]
      Left = 81
      Top = 224
      Width = 121
      Height = 97
      Images = cxImageList1
      ImageLayout = ilAfterChecks
      Items = <
        item
        end>
      ParentFont = False
      PopupMenu = PMenu1
      Style.Edges = []
      TabOrder = 11
      OnExit = ListItemsExit
    end
    object Check1: TcxCheckBox [12]
      Left = 11
      Top = 380
      Caption = #20351#29992#23458#25143#20840#37096#21487#29992#36164#37329'.'
      ParentFont = False
      TabOrder = 12
      Transparent = True
      OnClick = Check1Click
      Width = 165
    end
    object Label2: TcxLabel [13]
      Left = 339
      Top = 199
      Caption = #20803
      ParentFont = False
      Transparent = True
    end
    object EditUsed: TcxTextEdit [14]
      Left = 249
      Top = 174
      ParentFont = False
      Properties.ReadOnly = True
      TabOrder = 8
      Text = '0'
      Width = 105
    end
    inherited dxLayout1Group_Root: TdxLayoutGroup
      inherited dxGroup1: TdxLayoutGroup
        object dxLayout1Item7: TdxLayoutItem
          Caption = #23458#25143#21517#31216':'
          Control = EditCustomer
          ControlOptions.ShowBorder = False
        end
        object dxLayout1Item13: TdxLayoutItem
          Caption = #32440#21345#21517#31216':'
          Control = EditName
          ControlOptions.ShowBorder = False
        end
        object dxLayout1Item8: TdxLayoutItem
          Caption = #24037#31243#24037#22320':'
          Control = EditPName
          ControlOptions.ShowBorder = False
        end
        object dxLayout1Group3: TdxLayoutGroup
          ShowCaption = False
          Hidden = True
          LayoutDirection = ldHorizontal
          ShowBorder = False
          object dxLayout1Item11: TdxLayoutItem
            Caption = #25552#36135#26041#24335':'
            Control = EditLading
            ControlOptions.ShowBorder = False
          end
          object dxLayout1Item18: TdxLayoutItem
            AutoAligns = [aaVertical]
            AlignHorz = ahClient
            Caption = #26377#25928#26399#33267':'
            Control = EditDays
            ControlOptions.ShowBorder = False
          end
        end
        object dxLayout1Item9: TdxLayoutItem
          Caption = 'cxLabel1'
          ShowCaption = False
          Control = Label1
          ControlOptions.ShowBorder = False
        end
        object dxLayout1Item3: TdxLayoutItem
          AutoAligns = [aaVertical]
          AlignHorz = ahClient
          Caption = #25552#36135#20195#30721':'
          Control = EditCode
          ControlOptions.ShowBorder = False
        end
        object dxLayout1Group2: TdxLayoutGroup
          ShowCaption = False
          Hidden = True
          LayoutDirection = ldHorizontal
          ShowBorder = False
          object dxLayout1Item5: TdxLayoutItem
            Caption = #24635#39069'('#20803'):'
            Control = EditAll
            ControlOptions.ShowBorder = False
          end
          object dxLayout1Item14: TdxLayoutItem
            AutoAligns = [aaVertical]
            AlignHorz = ahClient
            Caption = #24050#29992'('#20803'):'
            Control = EditUsed
            ControlOptions.ShowBorder = False
          end
        end
        object dxLayout1Group6: TdxLayoutGroup
          ShowCaption = False
          Hidden = True
          LayoutDirection = ldHorizontal
          ShowBorder = False
          object dxLayout1Item6: TdxLayoutItem
            AutoAligns = [aaVertical]
            AlignHorz = ahClient
            Caption = #32440#21345#37329#39069':'
            Control = EditMoney
            ControlOptions.ShowBorder = False
          end
          object dxLayout1Item12: TdxLayoutItem
            Caption = 'cxLabel1'
            ShowCaption = False
            Control = Label2
            ControlOptions.ShowBorder = False
          end
        end
        object dxLayout1Item10: TdxLayoutItem
          AutoAligns = [aaHorizontal]
          AlignVert = avClient
          Caption = #25552#36135#21697#31181':'
          Control = ListItems
          ControlOptions.ShowBorder = False
        end
      end
      inherited dxLayout1Group1: TdxLayoutGroup
        object dxLayout1Item4: TdxLayoutItem [0]
          Caption = 'cxCheckBox1'
          ShowCaption = False
          Control = Check1
          ControlOptions.ShowBorder = False
        end
      end
    end
  end
  object cxImageList1: TcxImageList
    Height = 18
    Width = 1
    FormatVersion = 1
    DesignInfo = 15204404
  end
  object PMenu1: TPopupMenu
    AutoHotkeys = maManual
    Left = 24
    Top = 232
    object N1: TMenuItem
      Tag = 10
      Caption = #20840#37096#36873#20013
      OnClick = N1Click
    end
    object N2: TMenuItem
      Tag = 20
      Caption = #20840#37096#21462#28040
      OnClick = N1Click
    end
    object N3: TMenuItem
      Caption = '-'
    end
    object N4: TMenuItem
      Tag = 30
      Caption = #20840#37096#21453#36873
      OnClick = N1Click
    end
  end
end
