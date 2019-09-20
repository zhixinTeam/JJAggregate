inherited fFrameCarrier: TfFrameCarrier
  inherited ToolBar1: TToolBar
    inherited BtnAdd: TToolButton
      OnClick = BtnAddClick
    end
    inherited BtnEdit: TToolButton
      OnClick = BtnEditClick
    end
    inherited BtnDel: TToolButton
      OnClick = BtnDelClick
    end
  end
  inherited dxLayout1: TdxLayoutControl
    Visible = False
  end
  inherited cxSplitter1: TcxSplitter
    Visible = False
  end
  inherited TitlePanel1: TZnBitmapPanel
    inherited TitleBar: TcxLabel
      Caption = #25215#36816#21830#31649#29702
      Style.IsFontAssigned = True
      AnchorX = 301
      AnchorY = 11
    end
  end
end
