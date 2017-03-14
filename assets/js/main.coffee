Header = require './header'
Docs   = require './docs'

###*
 * Where it all begins
###
window.addEventListener 'DOMContentLoaded', () ->
  new Docs
  new Header
