class @EffectiveLogger
  @log = (message, status = 'info', details...) ->
    $.ajax
      type: 'POST',
      url: '/logs.json'
      data:
        effective_log:
          message: message
          status: status
          details: JSON.stringify(details)

    true

  @success = (message, details...) -> @log(message, 'success', details)
  @info = (message, details...) -> @log(message, 'info', details)
  @error = (message, details...) -> @log(message, 'error', details)
