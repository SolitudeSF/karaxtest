# Package

version       = "0.1.0"
author        = "SolitudeSF"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
bin           = @["memory_game_karax"]
binDir        = "public"
backend       = "js"

# Dependencies

requires "nim >= 2.0.0", "karax"
taskRequires "render", "karax"

task render, "Render index page":
  exec "nim e " & srcDir & "/index.nim " & binDir & "/index.html"
