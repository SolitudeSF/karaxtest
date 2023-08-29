import std/os
import pkg/karax/[karaxdsl, vdom]

proc index: VNode =
  buildHtml html(lang = "en"):
    head:
      meta(charset = "UTF-8")
      meta(content = "width=device-width, initial-scale=1", name = "viewport")
      title:
        text "Memory Card Game"
      link(`type` = "text/css", rel = "stylesheet", href = "style.css")
    body(class = "site", id = "body"):
      tdiv(id = "ROOT")
      script(src = "./memory_game_karax.js", `type` = "text/javascript")

writeFile paramStr(3), "<!DOCTYPE html>\n" & $index()
