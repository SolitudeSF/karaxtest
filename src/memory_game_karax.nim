import std/[strformat, dom, jscore]
import pkg/karax/[karax, vdom, karaxdsl, kajax, jjson, jdict, jstrutils]

type
  Rank = enum
    Unranked, Iron, Bronze, Silver, Gold, Platinum, Emerald, Diamond, Master, Grandmaster, Challenger

  Champion = object
    id, name: cstring

  GameStatus = enum
    Playing, Won, Lost

  AppScreen = enum
    Menu, Game

  GameState = object
    status: GameStatus
    rank: Rank
    promoted, newHighscore: bool
    score: int
    currentDeck: seq[uint8]
    openedChampions: set[uint8]

  AppState = object
    screen: AppScreen
    highScore: int
    rank: Rank
    championList: seq[Champion]
    game: GameState

const
  version = "13.16.1"
  rankToId = [Unranked: cstring"unranked", "iron", "bronze", "silver", "gold", "platinum", "emerald", "diamond", "master", "grandmaster", "challenger"]

func getRankImageUrl(r: Rank): cstring =
  "https://raw.communitydragon.org/latest/plugins/rcp-fe-lol-shared-components/global/default/images/" & ranktoId[r] & ".png"

func getChampIconUrl(id: cstring): cstring =
  "https://ddragon.leagueoflegends.com/cdn/" & version & "/img/champion/" & id & ".png"

proc getChampionList(result: var seq[Champion]) =
  const url = &"https://ddragon.leagueoflegends.com/cdn/{version}/data/en_US/champion.json"
  ajaxGet url, @[], proc(status: int, resp: cstring) =
    let data = resp.parse["data"]
    for champ in cast[JDict[cstring, JsonNode]](data).keys:
      result.add Champion(id: champ, name: data[champ]["name"].getStr)

proc getLocalStorage(t: typedesc[SomeOrdinal], name: cstring): t =
  let item = window.localStorage.getItem name
  if not item.isNil:
    result = item.parseInt.t

proc setLocalStorage(value: SomeOrdinal, name: cstring) =
  window.localStorage.setItem name, value.ord.toCstr

proc getRandomIntExclusive(max: int): int =
  return Math.floor(Math.random() * float(Math.floor(max.float)))

proc shuffle(s: var seq[uint8]) =
  var res = newSeq[uint8](s.len)
  for i in 0..<s.len:
    let idx = getRandomIntExclusive s.len
    res[i] = s[idx]
    s[idx] = s[^1]
    s.setLen s.high
  s = res

var app = AppState(screen: Menu)

proc onCardClick(idx: uint8) =
  if app.game.status != Playing: return

  if idx notin app.game.openedChampions:
    inc app.game.score
    if app.game.score == app.game.currentDeck.len:
      app.game.status = Won
      if app.game.rank > app.rank:
        app.game.promoted = true
        app.rank = app.game.rank
        app.rank.setLocalStorage "rank"
    app.game.openedChampions.incl idx
    app.game.currentDeck.shuffle
  else:
    app.game.status = Lost

  if app.game.score > app.highScore:
    app.game.newHighscore = true
    app.highScore = app.game.score
    app.highscore.setLocalStorage "highscore"

proc getNewDeck(size: int): seq[uint8] =
  var idxs: set[uint8]
  while idxs.card < size:
    idxs.incl uint8 getRandomIntExclusive app.championList.len
  for idx in idxs:
    result.add idx

proc startGame(rank: Rank) =
  app.screen = Game
  app.game = GameState(
    status: Playing,
    rank: rank,
    currentDeck: getNewDeck rank.ord * 5
  )

proc playAgain =
  app.screen = Menu

proc popup: VNode =
  buildHtml tdiv(class = "popup"):
    tdiv class = "popup-content":
      h2 class = "end-game-header":
        p:
          if app.game.status == Won:
            text "Victory!"
          else:
            text "Defeat!"
      if app.game.promoted:
        tdiv class = "new-rank-container":
          p: text "New rank!"
          p: text "You are promoted to " & $app.game.rank & "!"
          img class = "popup-rank", src = getRankImageUrl(app.game.rank), alt = cstring $app.game.rank
      p class = "result-text":
        if app.game.status == Won:
          text "You won with score of " & app.game.score.toCstr & "!"
        else:
          text "You lost with score of " & app.game.score.toCstr & ". Try again!"
      if app.game.newHighscore:
        p class = "new-highscore":
          text "New Highscore!"
      button class = "play-again":
        proc onclick =
          playAgain()
        p: text "Play again!"

proc card(idx: uint8): VNode =
  buildHtml button(class = "card"):
    proc onclick = onCardClick idx
    img src = getChampIconUrl(app.championList[idx].id), alt = app.championList[idx].name
    p: text app.championList[idx].name

proc cardBoard: VNode =
  buildHtml main(class = "card-board-container"):
    tdiv class = "info":
      p class = "score": text "Current score: " & app.game.score.toCstr
      p class = "champions-left": text "Champions left: " & (app.game.currentDeck.len - app.game.openedChampions.card).toCstr
    tdiv class = "card-board":
      for i in app.game.currentDeck:
        card i
    if app.game.status != Playing:
      popup()

proc rankButton(rank: Rank, enabled: bool): VNode =
  buildHtml button(class = "rank-btn", disabled = not enabled):
    proc onclick = startGame rank
    img class = "emblem", src = getRankImageUrl(rank), alt = cstring $rank
    p: text $rank

proc startScreen: VNode =
  buildHtml main(class = "start-screen"):
    h1: text "League of Brain"
    h2: text "Choose difficulty"
    tdiv class = "rank-list":
      for rank in Iron..app.rank.succ:
        rankButton rank, true
      for rank in app.rank.succ(2)..Rank.high:
        rankButton rank, false
    tdiv class = "rules-container":
      h3 class = "rules":
        text "Rules: "
        p: text "Click each champion only once!"

proc createDom: VNode =
  try:
    result = buildHtml(tdiv):
      header:
        tdiv class = "header-left":
          if app.screen == Game:
            button class = "quit-btn":
              proc onclick = playAgain()
              img class = "quit-btn-default", src = "https://raw.communitydragon.org/latest/plugins/rcp-fe-lol-shared-components/global/default/exit_default.png", alt = "Quit"
              img class = "quit-btn-hover", src = "https://raw.communitydragon.org/latest/plugins/rcp-fe-lol-shared-components/global/default/exit_hover.png", alt = "Quit"
          tdiv class = "current-rank":
            p: text "Your rank: " & $app.rank
            img class = "rank-image", src = getRankImageUrl(app.rank), alt = cstring $app.rank
        tdiv class = "header-right":
          p: text "High Score: " & app.highScore.toCstr
      case app.screen
      of Menu: startScreen()
      of Game: cardBoard()
  except Exception as e:
    echo e[]

app.highscore = int.getLocalStorage "highscore"
app.rank = Rank.getLocalStorage "rank"

setRenderer createDom
getChampionList(app.championList)
