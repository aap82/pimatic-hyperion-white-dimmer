module.exports =
  title: "pimatic-nest device config schemas"
  HyperionDimmer:
    title: "Dimmer to control white backlight of Hyperion"
    type: "object"
    properties:
      host:
        description: "Host of the Hyperion Daemon"
        type: "string"
        required: yes
        default: "localhost"
      port:
        description: "Port on host running Hyperion Daemon"
        type: "number"
        default: 19444
      maxBrightness:
        description: "The maximum brightness up to 100"
        type: "number"
        default: 100

