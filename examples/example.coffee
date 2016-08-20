showEditor = ->
  document.body.className += ' debug'

  preEl = document.createElement("pre")
  codeEl = document.createElement("code")

  preEl.appendChild(codeEl)
  document.body.appendChild(preEl)

  backEl = document.createElement("a")
  backEl.href = "/"
  backEl.className = "back"
  document.body.appendChild(backEl)

  link = document.createElement("link")
  link.rel = "stylesheet"
  link.href = "macClassicTheme.css"
  document.head.appendChild(link)

  script = document.createElement("script")
  script.src = "//cdnjs.cloudflare.com/ajax/libs/highlight.js/8.6/highlight.min.js"
  document.head.appendChild(script)

  script.onload = ->
    code = document.querySelector("#script").textContent.trim()
    code = hljs.highlight("javascript", code).value
    codeEl.innerHTML = code

if window == window.top
  showEditor()
