inherited BaseForm1: TBaseForm1
  Left = 456
  Top = 435
  Width = 644
  Height = 453
  Caption = 'test -default'
  FormStyle = fsStayOnTop
  OldCreateOrder = True
  Position = poDesktopCenter
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 12
  object Memo1: TMemo
    Left = 0
    Top = 33
    Width = 628
    Height = 381
    Align = alClient
    Lines.Strings = (
      'Memo1')
    ScrollBars = ssVertical
    TabOrder = 0
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 628
    Height = 33
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    DesignSize = (
      628
      33)
    object Button1: TButton
      Left = 557
      Top = 8
      Width = 60
      Height = 20
      Anchors = [akTop, akRight]
      Caption = 'test'
      TabOrder = 0
      OnClick = Button1Click
    end
    object Edit1: TEdit
      Left = 14
      Top = 8
      Width = 539
      Height = 20
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 1
      Text = 'sql=select * from sys_user'
    end
  end
  object IdHTTP1: TIdHTTP
    AllowCookies = True
    ProxyParams.BasicAuthentication = False
    ProxyParams.ProxyPort = 0
    Request.ContentLength = -1
    Request.Accept = 'text/html, */*'
    Request.BasicAuthentication = False
    Request.UserAgent = 'Mozilla/3.0 (compatible; Indy Library)'
    HTTPOptions = [hoForceEncodeParams]
    Left = 104
    Top = 96
  end
end
