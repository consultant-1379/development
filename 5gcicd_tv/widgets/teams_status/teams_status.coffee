class Dashing.TeamsStatus extends Dashing.Widget

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
      when aTrs >= 1  then "red"
      when bTrs >= 4  then "red"
      when cTrs >= 10 then "red"
      when bTrs >= 2  then "yellow"
      when cTrs >= 6  then "yellow"
      else
        "palegreen"
 
    backgroundClass = "teams_status_#{color}"
    lastClass = @lastClass

    if lastClass != backgroundClass
      $(@node).toggleClass("#{lastClass} #{backgroundClass}")
      @lastClass = backgroundClass

  ready: ->
    @onData(null)
