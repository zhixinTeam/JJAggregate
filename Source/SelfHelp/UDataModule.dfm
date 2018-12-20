object FDM: TFDM
  OldCreateOrder = False
  Left = 378
  Top = 501
  Height = 211
  Width = 299
  object ADOConn: TADOConnection
    LoginPrompt = False
    Left = 28
    Top = 20
  end
  object SQLQuery1: TADOQuery
    Connection = ADOConn
    Parameters = <>
    Left = 82
    Top = 20
  end
  object edtStyle: TcxDefaultEditStyleController
    Style.Edges = [bBottom]
    Style.Font.Charset = GB2312_CHARSET
    Style.Font.Color = clBlack
    Style.Font.Height = -48
    Style.Font.Name = #23435#20307
    Style.Font.Style = []
    Style.TextColor = clBlack
    Style.Gradient = False
    Style.IsFontAssigned = True
    StyleDisabled.Color = clWindow
    StyleFocused.Color = clInfoBk
    Left = 144
    Top = 24
    PixelsPerInch = 96
  end
  object cxLoF1: TcxLookAndFeelController
    Kind = lfOffice11
    Left = 186
    Top = 24
  end
end
