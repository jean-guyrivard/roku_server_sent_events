sub init()
  testTask = CreateObject("roSGNode", "TestTask")
  testTask.observeFieldScoped("event", "onEvent")
  testTask.control = "run"
end sub

sub onEvent(event)
  eventData = event.getData()

  ?"On Event", eventData
end sub