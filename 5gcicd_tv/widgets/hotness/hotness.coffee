class Dashing.Hotness extends Dashing.Widget

  @accessor 'value', Dashing.AnimatedValue

  constructor: ->
    super

  onData: (data) ->
    node = $(@node)

    prios = data.priority.split(", ")
    aTrs = parseInt(prios[0].substring(2))
    bTrs = parseInt(prios[1].substring(2))
    cTrs = parseInt(prios[2].substring(2))

    #Here comes the logic for choosing the colors
    color = switch
      when aTrs >= 2   then "red"
      when bTrs >= 8   then "red"
      when cTrs >= 30  then "red"
      when aTrs >= 1   then "yellow"
      when bTrs >= 4   then "yellow"
      when cTrs >= 20  then "yellow"
      else
        "palegreen"

    backgroundClass = "hotness_#{color}"
    lastClass = @lastClass

    if lastClass != backgroundClass
      $(@node).toggleClass("#{lastClass} #{backgroundClass}")
      @lastClass = backgroundClass

  ready: ->
    @onData(null)
