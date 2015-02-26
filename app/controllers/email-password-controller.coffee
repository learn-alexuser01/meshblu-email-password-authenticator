EmailPasswordModel = require '../models/email-password-model'
PinAuthenticatorDb = require '../models/pin-authenticator-db'
_ = require 'lodash'

class EmailPasswordController
  constructor : (uuid, dependencies) ->
    @uuid = uuid
    @meshblu = dependencies?.meshblu
    @emailPasswordModel = dependencies?.emailPasswordModel || new EmailPasswordModel( @uuid, db: new PinAuthenticatorDb( @meshblu ))

  createDevice : (email, password, device={}, callback=->) =>
    attributes = _.cloneDeep device
    attributes.configureWhitelist ?= []
    attributes.configureWhitelist.push @uuid

    @emailPasswordModel.save email, password, attributes, (error, device) =>
      if (error)
        return callback error, device?.uuid

      @meshblu.generateAndStoreToken uuid: device?.uuid, (result) =>
        callback null, { uuid: device?.uuid, token: result?.token }

  getToken : (uuid, pin, callback=->) =>
    @emailPasswordModel.checkEmailPassword uuid, pin, (error, result)=>
      return callback(error) if error
      return callback( new Error 'Email and password combination is invalid') if !result
      @meshblu.generateAndStoreToken uuid: uuid, (result) =>
        callback null, result

module.exports = EmailPasswordController