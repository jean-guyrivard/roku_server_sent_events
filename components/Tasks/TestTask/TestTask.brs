sub init()
  m.top.functionName = "process"
end sub

sub process()
  test = roServerEvents()
  test.url = "https://192.168.11.101:8082/breaking_news.json"
  test.onEvent = onEvent
  test.sendRequest()
end sub

function onEvent()
end function