PROVIDERS =
  ec2: new (require './ec2/provider')()

boot = (type, baseConfig, overrideConfig, callback) ->
  callback = overrideConfig if not callback? and typeof overrideConfig == 'function'

  return callback? new Error "You must specificy a type" unless type?
  type = type.toLowerCase()

  provider = PROVIDERS[type]
  return callback? new Error "Unknown Provider #{type}" unless provider?

  if overrideConfig?
    baseConfig = JSON.parse JSON.stringify baseConfig
    baseConfig[option] = value for option, value of overrideConfig

  configForType = baseConfig[type]
  return callback? new Error "No configuration for #{type}" unless configForType?

  provider.start configForType, callback

module.exports = boot