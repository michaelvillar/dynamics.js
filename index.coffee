class Tools
  @valuesFromURL = =>
    url = (document.location.toString() || '').split('#')
    values = {}
    if url.length > 1
      query = url[1]
      for arg in query.split(',')
        [k, v] = arg.split('=')
        values[k] = decodeURIComponent(v)
    values

  @saveValues: (args) =>
    argsString = ''
    for k, v of args
      argsString += "," unless argsString == ''
      argsString += "#{k}=#{encodeURIComponent(v)}"

    currentURL = (document.location.toString() || '').split('#')[0]
    document.location = currentURL + "#" + argsString

class App
  constructor: ->
    @panel = new Panel(Tools.valuesFromURL())
    @codeSection = document.querySelector('section.code')
    @panel.onUpdate = @update
    @update()

  update: =>
    @codeSection.innerHTML = @panel.code()
    Tools.saveValues(@panel.options)

document.addEventListener "DOMContentLoaded", ->
  app = new App
, false
