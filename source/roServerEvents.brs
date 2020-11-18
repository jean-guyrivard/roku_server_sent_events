function roServerEvents()
  newRoServerEvent = {}
  newRoServerEvent.url = Invalid

  newRoServerEvent.onEvent = Invalid

  newRoServerEvent.sendRequest = function()
    if Invalid <> m.url
      urlRegEx = createObject("roRegEx", "(https?):\/\/([a-z0-9:\.-]*)([\/\w\W]*)", "i")
      matches = urlRegEx.match(m.url)

      ?"Matches", matches

      address = createObject("roSocketAddress")
      address.setAddress(matches[2])

      if 0 = address.getPort()
        if "http" = matches[1]
          ?"HTTP!"
          isSecure = false
          address.setPort(80)
        else if "https" = matches[1]
          ?"HTTPS!"
          isSecure = true
          address.setPort(443)
        else
          ?"Invalid url - Port"
        end if
      end if
      ?"address.getPort()", address.getPort()

      messagePort = CreateObject("roMessagePort")

      socket = CreateObject("roStreamSocket")
      socket.setSendToAddress(address)
      socket.NotifyReadable(true)
      socket.NotifyWritable(true)
      socket.NotifyException(true)
      socket.setMessagePort(messagePort)
      If socket.Connect()
          Print "Connected Successfully"
      End If

      buffer = CreateObject("roByteArray")
      buffer[8096] = 0
      sendBuffer = CreateObject("roByteArray")

      m.state = "ClientHello"

      while True
        event = wait(1, messagePort)

        if type(event) = "roSocketEvent"
          closed = False
          if socket.isReadable()
            received = socket.receive(buffer, 0, 5)
            print "received is " received
            if received > 0
                ' print "Echo input: '"; buffer.ToAsciiString(); "'"
                for i = 0 to received
                  ?buffer[i]
                end for
                ContentType = buffer[0]
                ProtocolVersion = [buffer[1], buffer[2]]
                ContentSize = (buffer[3] << 8) + buffer[4]

                ?"ContentSize", ContentSize
                ?"ContentType", ContentType

                received = socket.receive(buffer, 0, ContentSize)
                ?"buffer", received, buffer[0], buffer[ContentSize-1]

                if 22 = ContentType
                  ' Parse handshake
                  HandshakeSize = (buffer[2] << 16) + (buffer[3] << 8) + buffer[4]
1
                  if 12 = buffer[0]
                    sendBuffer = createClientKeyExchange()
                    sendBuffer.append(changeCipher())

                    socket.send(sendBuffer, 0, sendBuffer.count())
                  end if
                end if
                ' If we are unable to send, just drop data for now.
                ' You could use notifywritable and buffer data, but that is
                ' omitted for clarity.
                'socket.send(buffer, 0, received)
            else if received=0 ' client closed
                closed = True
            end if
          end if
          if socket.IsWritable()
            if "ClientHello" = m.state
              m.state = "ServerHello"
              sendBuffer = createClientHello()

              socket.send(sendBuffer, 0, sendBuffer.count())
            end if
          end if
          if socket.IsException()
            ?socket.eAgain()
            ?socket.eAlready()
            ?socket.eBadAddr()
            ?socket.eDestAddrReq()
            ?socket.eHostUnreach()
            ?socket.eInvalid()
            ?socket.eInProgress()
            ?socket.eWouldBlock()
            ?socket.eSuccess()
            ?socket.eOK()
          end if
          if closed or not socket.eOK()
              print "closing connection " changedID
              socket.close()
          end if
        end if
      end while
    else
      ?"Invalid url"
    end if
  end function

  return newRoServerEvent
end function

function createClientHello()
  handshake = createHandshake("ClientHandshake")

  plainTextSSL = createPlainTextSSL(22, handshake)

  return plainTextSSL
end function

function createClientHelloFinished()
  handshake = createHandshake("ClientHandshakeFinished")

  plainTextSSL = createPlainTextSSL(22, handshake)

  return plainTextSSL
end function

function createCertificateVerify()
  handshake = createHandshake("ClientHandshakeCertVerify")

  plainTextSSL = createPlainTextSSL(22, handshake)

  return plainTextSSL
end function

function createClientKeyExchange()
  handshake = createHandshake("ClientHandshakeKeyExchange")

  plainTextSSL = createPlainTextSSL(22, handshake)

  return plainTextSSL
end function

function changeCipher()
  Cipher = CreateObject("roByteArray")
  Cipher[0] = 1

  plainTextSSL = createPlainTextSSL(20, Cipher)

  return plainTextSSL
end function

function createPlainTextSSL(ContentType, Content)
  plainTextSSL = createObject("roByteArray")

  index = 0
  ' Content Type
  plainTextSSL[index + 0] = ContentType
  index += 1
  ' Protocol version
  plainTextSSL[index + 0] = 3
  plainTextSSL[index + 1] = 3
  index += 2
  ' Record - Size
  plainTextSSL[index + 0] = 0
  plainTextSSL[index + 1] = 0
  index += 2

  plainTextSSL.append(Content)

  plainTextSSL[3] = Content.count() >> 8 AND 255
  plainTextSSL[4] = Content.count() AND 255

  return plainTextSSL
end function

function createHandshake(handshakeType)
  now = createObject("roDateTime")
  nowAsSeconds = now.AsSeconds()

  handshakeBuffer = createObject("roByteArray")

  index = 0
  ' Handshake Type
  if "ClientHandshake" = handshakeType
    handshakeBuffer[index + 0] = 1
  else if "ClientHandshakeCertVerify" = handshakeType
    handshakeBuffer[index + 0] = 15
  else if "ClientHandshakeKeyExchange" = handshakeType
    handshakeBuffer[index + 0] = 16
  end if
  index += 1
  ' length
  handshakeBuffer[index + 0] = 0
  handshakeBuffer[index + 1] = 0
  handshakeBuffer[index + 2] = 0
  index += 3

  if "ClientHandshake" = handshakeType
    ' ClientHello - protocol
    handshakeBuffer[index + 0] = 3
    handshakeBuffer[index + 1] = 3
    index += 2
    ' ClientHello - Random - time
    handshakeBuffer[index + 0] = nowAsSeconds >> 24 AND 255
    handshakeBuffer[index + 1] = nowAsSeconds >> 16 AND 255
    handshakeBuffer[index + 2] = nowAsSeconds >> 8 AND 255
    handshakeBuffer[index + 3] = nowAsSeconds AND 255
    index += 4

    ' ClientHello - Random - Random gen
    sessionRandom = createObject("roByteArray")
    for i = 0 to 28
      sessionRandom[i] = rnd(256) - 1
    end for
    handshakeBuffer.append(sessionRandom)
    index += 28
    ' Clienthello - Session Length
    handshakeBuffer[index + 0] = 0
    index += 1
    ' ClientHello - Cipher Length
    handshakeBuffer[index + 0] = 0
    handshakeBuffer[index + 1] = 2
    index += 2
    ' ClientHello - Ciphers
    handshakeBuffer[index + 0] = &HC0
    handshakeBuffer[index + 1] = &H2F
    index += 2
    ' ClientHello - Compression Length
    handshakeBuffer[index + 0] = 1
    index += 1
    ' Clienthello - Compression
    handshakeBuffer[index + 0] = 0
    index += 1
    ' ClientHello - Extension Length
    handshakeBuffer[index + 0] = 0
    index += 1
    ' Clienthello - Extensions
    handshakeBuffer[index + 0] = 0
    index += 1
  else if "ClientHandshakeKeyExchange" = handshakeType
    pubKey = ReadAsciiFile("pkg:/assets/https_key.pub")
    keyRegEx = CreateObject("roRegEx", "^([\w\W]+) ([\w\W]+) ([\w\W]+)\n$", "i")
    pubKeyMatches = keyRegEx.match(pubKey)
    ?pubKeyMatches
    if 3 < pubKeyMatches.count()

      pubKeyInfo = getKeyInfo(pubKeyMatches[2])
      
      ?"getKeyInfo", pubKeyInfo
      
      handshakeBuffer[index] = pubKeyInfo.n.count() AND 255
      index += 1

      handshakeBuffer.append(pubKeyInfo.n)
      index += pubKeyInfo.n.count()
    end if
  else
    ' ClientHello - protocol
    handshakeBuffer[index + 0] = 3
    handshakeBuffer[index + 1] = 0
    index += 2
  end if

  handshakeBuffer[1] = index - 4 >> 16 AND 255
  handshakeBuffer[2] = index - 4 >> 8 AND 255
  handshakeBuffer[3] = index - 4 AND 255

  return handshakeBuffer
end function

function getKeyInfo(keyString)
  keyBuffer = CreateObject("roByteArray")
  keyBuffer.fromBase64String(keyString)

  index = 0
  len = (keyBuffer[index + 0] << 24) + (keyBuffer[index + 1] << 16) + (keyBuffer[index + 2] << 8) + keyBuffer[index + 3]
  index += 4
  ?"len", len
  certType = CreateObject("roString")
  for i = 0 to len - 1
    ?keyBuffer[index + i]
    certType.appendString(chr(keyBuffer[index + i]), 1)
    ?chr(keyBuffer[index + i])
  end for
  index += len
  ?"certType", certType

  len = (keyBuffer[index + 0] << 24) + (keyBuffer[index + 1] << 16) + (keyBuffer[index + 2] << 8) + keyBuffer[index + 3]
  index += 4
  ?"len", len

  e = CreateObject("roByteArray")
  for i = 0 to len - 1
    ?keyBuffer[index + i]
    e.push(keyBuffer[index + i])
  end for
  ?"e", e.toAsciiString()
  index += len

  len = (keyBuffer[index + 0] << 24) + (keyBuffer[index + 1] << 16) + (keyBuffer[index + 2] << 8) + keyBuffer[index + 3]
  index += 4
  ?"len", len

  n = CreateObject("roByteArray")
  for i = 0 to len - 1
    ?keyBuffer[index + i]
    n.push(keyBuffer[index + i])
  end for
  index += len

  return {
    certType: certType,
    e: e,
    n: n
  }
end function