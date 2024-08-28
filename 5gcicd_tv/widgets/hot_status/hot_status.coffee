class Dashing.HotStatus extends Dashing.Widget

  constructor: ->
    super

  onData: (data) ->
    return if not @status
    status = @status.toLowerCase()
    historyResult = @historyResult.toLowerCase()
    gradient = ""
    
    if [ '1', '2', '3', '4', '5' ].indexOf(historyResult) != -1 #If success in last 5 runs, set gradient color
       gradient = "-gradient-" + historyResult

    if [ 'critical', 'warning', 'ok', 'unknown' ].indexOf(status) != -1
      backgroundClass = "hot-status-#{status}#{gradient}"
    else
      backgroundClass = "hot-status-neutral"

    lastClass = @lastClass

    if lastClass != backgroundClass
      $(@node).toggleClass("#{lastClass} #{backgroundClass}")
      @lastClass = backgroundClass

      audiosound = @get(status + 'sound')
      audioplayer = new Audio(audiosound) if audiosound?
      if audioplayer
        audioplayer.play()

  ready: ->
    @onData(null)
