' Main
'
' @params {Object} externalParams
' @since verison 1.0
sub main(externalParams)
  screen = CreateObject("roSGScreen")
  port = CreateObject("roMessagePort")
  input = CreateObject("roInput")

  screen.setMessagePort(port)
  input.SetMessagePort(port)
  m.global = screen.getGlobalNode()

  'Create Main Scene
  scene = screen.CreateScene("TestScene")
  screen.show() ' vscode_rale_tracker_entry

  'Watch field to exit application
  scene.observeField("exitApplication", port)

  while(true)
    msg = wait(0, port)
    msgType = type(msg)
    if invalid <> msg
      if "roSGNodeEvent" = msgType
        msgField = msg.GetField()
        msgData = msg.getData()
        if "exitApplication" = msgField AND true = msgData then return
      else if "roDeviceInfoEvent" = msgType
        msgInfo = msg.getInfo()
        if invalid <> msgInfo AND invalid <> msgInfo.linkStatus then m.global.linkStatus = msgInfo.linkStatus
      else if "roInputEvent" = msgType
        if msg.IsInput()
          info = msg.GetInfo()
          if info.DoesExist("mediatype") and info.DoesExist("contentid")
            mediaType = info.mediatype
            contentId = info.contentid

            m.global.deeplink = {
              mediaType: mediaType,
              contentId: contentId
            }
          end if
        end if
      end if
    end if
  end while
end sub