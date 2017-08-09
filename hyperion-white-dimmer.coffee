module.exports = (env) ->
  Promise = env.require 'bluebird'
  assert = env.require 'cassert'

  Color = require 'color'
  child_process = require("child_process")


  lastCommand = Promise.resolve()
  settledCommand = (promise) -> Promise.settle([promise])
  execCommand = (command) ->
    lastCommand = settledCommand(lastCommand).then(-> exec(command, {}))
    return lastCommand

  exec = (command, options) ->
    return new Promise( (resolve, reject) ->
      child_process.exec(command, options, (err, stdout, stderr) ->
        if err
          err.stdout = stdout.toString() if stdout?
          err.stderr = stderr.toString() if stderr?
          return reject(err)
        return resolve({stdout: stdout.toString(), stderr: stderr.toString()})
      )
    )

  delay = (t) ->
    return new Promise (resolve) ->
      setTimeout resolve, t


  class HyperionWhiteDimmer extends env.plugins.Plugin
    init: (app, @framework) =>
      deviceConfigDef = require('./device-config-schema')
      @framework.deviceManager.registerDeviceClass "HyperionDimmer", {
        configDef: deviceConfigDef.HyperionDimmer,
        createCallback: @callBackHandler("HyperionDimmer", HyperionDimmer)
      }

    callBackHandler: (className, classType) =>
      return (config, lastState) =>
        return new classType(config, lastState)


  hyperionWhiteDimmer = new HyperionWhiteDimmer

  class HyperionDimmer extends env.devices.DimmerActuator

    getLast_level: -> Promise.resolve @_last_level
    setLastLevel: (level) ->
      @_last_level = level
      @emit 'last_level', level
      return

    constructor: (@config, lastState) ->
      @config.xAttributeOptions = [
        name: 'last_level'
        hidden: true
      ]
      {@id, @name, @host, @port, @maxBrightness} = @config
      @baseStr = "hyperion-remote --address #{@host}:#{@port}"
      @attributes['last_level'] =
        description: "Last known on Level"
        type: "number"
      @_state = lastState?.state?.value or off
      @_dimlevel = lastState?.dimlevel?.value or 0
      @_last_level = lastState?.last_level?.value or @maxBrightness

      super()



    turnOn: ->
      return if @_state
      @changeDimlevelTo(@_last_level)

    turnOff: ->
      return if !@_state
      @changeDimlevelTo(0)


    changeDimlevelTo: (level) ->
      level = parseFloat(level)
      return Promise.reject("Invalid input: #{level}" ) if isNaN(level)
      level = Math.round(level/10) * 10

      return if level is @_dimlevel
      return unless 0 <= level <= @maxBrightness
      cVal = parseInt ((level * 255) / 100).toFixed(0), 10
      cmdStr = "#{@baseStr} --color #{Color.rgb(cVal,cVal,cVal).hex().slice(1,7).toLowerCase()}"
      command = execCommand(cmdStr)
      if level is 0
        command = command
          .then(=> return delay(1000))
          .then(=> return execCommand(cmdStr))
      return command
        .then(=> return @updateState(level))
        .catch(@handleError)

    handleError: (err) -> Promise.reject(err)

    updateState: (level) =>
      if @_dimlevel is 0 and @_last_level isnt level then @setLastLevel(level)
      if level is 0 then @setLastLevel(@_dimlevel)
      @_dimlevel = level
      @emit 'dimlevel', level
      return @_setState(level>0)


    destroy: ->   super()





























  return hyperionWhiteDimmer

