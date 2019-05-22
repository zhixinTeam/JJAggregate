inherited fFormPriceView: TfFormPriceView
  Left = 574
  Top = 431
  Width = 593
  Height = 396
  BorderIcons = [biSystemMenu, biMinimize, biMaximize]
  BorderStyle = bsSizeable
  Position = poDesktopCenter
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 12
  inherited dxLayout1: TdxLayoutControl
    Width = 585
    Height = 365
    inherited BtnOK: TButton
      Left = 439
      Top = 332
      Caption = #30830#23450
      Enabled = False
      TabOrder = 3
    end
    inherited BtnExit: TButton
      Left = 509
      Top = 332
      TabOrder = 4
    end
    object cxLabel1: TcxLabel [2]
      Left = 23
      Top = 36
      AutoSize = False
      ParentFont = False
      Properties.LineOptions.Alignment = cxllaBottom
      Transparent = True
      Height = 6
      Width = 238
    end
    object Chart1: TChart [3]
      Left = 23
      Top = 47
      Width = 400
      Height = 250
      BackWall.Brush.Color = clWhite
      BackWall.Color = clMoneyGreen
      Title.Text.Strings = (
        'TChart')
      BackColor = clMoneyGreen
      Color = clWindow
      TabOrder = 1
      OnMouseMove = Chart1MouseMove
      object Series1: TGanttSeries
        ColorEachPoint = True
        Marks.ArrowLength = 0
        Marks.Frame.Color = clGreen
        Marks.Visible = True
        SeriesColor = clRed
        Pointer.InflateMargins = True
        Pointer.Style = psRectangle
        Pointer.Visible = True
        XValues.DateTime = True
        XValues.Name = 'Start'
        XValues.Multiplier = 1.000000000000000000
        XValues.Order = loAscending
        YValues.DateTime = False
        YValues.Name = 'Y'
        YValues.Multiplier = 1.000000000000000000
        YValues.Order = loNone
        StartValues.DateTime = True
        StartValues.Name = 'Start'
        StartValues.Multiplier = 1.000000000000000000
        StartValues.Order = loAscending
        EndValues.DateTime = True
        EndValues.Name = 'End'
        EndValues.Multiplier = 1.000000000000000000
        EndValues.Order = loNone
        NextTask.DateTime = False
        NextTask.Name = 'NextTask'
        NextTask.Multiplier = 1.000000000000000000
        NextTask.Order = loNone
      end
    end
    object Edit1: TcxColorComboBox [4]
      Left = 11
      Top = 332
      ParentFont = False
      Properties.CustomColors = <
        item
          Color = clSkyBlue
          Description = #20020#26102#20215#26684
        end
        item
          Color = clMoneyGreen
          Description = #38271#26399#20215#26684
        end
        item
          Color = clBlue
          Description = #29983#25928#20020#26102#20215
        end
        item
          Color = clGreen
          Description = #29983#25928#38271#26399#20215
        end>
      Properties.DefaultDescription = #22270#20363#35828#26126
      Properties.NamingConvention = cxncNone
      Properties.PrepareList = cxplNone
      Properties.ReadOnly = True
      TabOrder = 2
      Width = 135
    end
    inherited dxLayout1Group_Root: TdxLayoutGroup
      inherited dxGroup1: TdxLayoutGroup
        Caption = ''
        object dxLayout1Item8: TdxLayoutItem
          Caption = 'cxLabel1'
          ShowCaption = False
          Control = cxLabel1
          ControlOptions.ShowBorder = False
        end
        object dxLayout1Item3: TdxLayoutItem
          AutoAligns = [aaHorizontal]
          AlignVert = avClient
          Caption = 'Chart1'
          ShowCaption = False
          Control = Chart1
          ControlOptions.AutoColor = True
          ControlOptions.ShowBorder = False
        end
      end
      inherited dxLayout1Group1: TdxLayoutGroup
        object dxLayout1Item4: TdxLayoutItem [0]
          Caption = #22791#27880':'
          ShowCaption = False
          Control = Edit1
          ControlOptions.ShowBorder = False
        end
      end
    end
  end
end
