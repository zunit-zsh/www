Fuse = require 'fuse.js'

require('es6-promise').polyfill()
require 'isomorphic-fetch'

###*
 * Provides methods for building the documentation menu
 *
 * @type {Docs}
###
module.exports = class Docs
  ###*
   * A map of key codes
   *
   * @type {object}
  ###
  keyCodes =
    ESC: 27

  ###*
   * The documentation link in the main menu
   *
   * @type {HTMLElement}
  ###
  menuItem = document.querySelector '.nav--main-docs-link'

  ###*
   * The documentation link in the main menu
   *
   * @type {HTMLElement}
  ###
  navToggle = document.querySelector '.nav--main-mobile-nav-link'

  ###*
   * The navigation pane containing the documentation menu
   *
   * @type {HTMLElement}
  ###
  menuPane = document.querySelector '.nav--docs'

  ###*
   * The search input
   *
   * @type {HTMLElement}
  ###
  searchInput = document.querySelector '#search'

  ###*
   * The search results pane
   *
   * @type {HTMLElement}
  ###
  searchResultsPane = document.querySelector '.nav--docs-search-results'

  ###*
   * Start your engines!
   *
   * @return {Docs}
  ###
  constructor: () ->
    @registerNavListeners()
    @registerSearchListeners()
    @renderNav()

  ###*
   * Register listeners to handle search input
  ###
  registerSearchListeners: () ->
    searchInput.addEventListener 'keyup', (evt) =>
      key = evt.keyCode or evt.which

      if searchInput.value and key isnt keyCodes.ESC
        document.body.classList.add 'search--open'
        @search searchInput.value
      else
        document.body.classList.remove 'search--open'
        searchInput.value = ''

  search: (term) =>
    @getDocs()
      .then (docs) ->
        console.log 'searching'
        searchable = []

        searchable.push.apply searchable, docs.items
        delete docs.items

        # Flatten the documentation list
        for key of docs
          console.log key
          if docs[key].items?
            searchable.push.apply searchable, docs[key].items

        console.log searchable

        # Create the fuse instance
        options =
          threshold: 0.6
          keys: [{
            name: 'title'
            weight: 1
          }, {
            name: 'description'
            weight: 0.7
          }, {
            name: 'content'
            weight: 0.5
          }, {
            name: '_url'
            weight: 0.5
          }]
        fuse = new Fuse(searchable, options)

        # Filter the results
        results = fuse.search(term)
        console.log results

        # Clear the search results pane
        searchResultsPane.innerHTML = ''

        # Loop through each of the results and append them to the pane
        for result in results
          li = document.createElement 'li'
          li.classList.add 'nav--docs-search-results-item'

          a = document.createElement 'a'
          a.href = result._url

          h3 = document.createElement 'h3'
          h3.innerHTML = result.title

          p = document.createElement 'p'
          p.innerHTML = result.description

          a.appendChild h3
          a.appendChild p
          li.appendChild a
          searchResultsPane.appendChild li


  ###*
   * Register listeners for opening and closing the documentation navigation
  ###
  registerNavListeners: () ->
    listener = (evt) ->
      evt.preventDefault()

      if document.body.classList.contains 'docs--open'
        document.body.classList.remove 'docs--open'
        document.body.classList.remove 'search--open'
        searchInput.value = ''
      else
        document.body.classList.add 'docs--open'

    menuItem.addEventListener 'click', listener
    navToggle.addEventListener 'click', listener

    document.addEventListener 'keydown', (evt) ->
      key = evt.keyCode or evt.which
      open = document.body.classList.contains 'docs--open'

      if open and key is keyCodes.ESC
        document.body.classList.remove 'docs--open'

  ###*
   * Renders the navigation in the sidebar
  ###
  renderNav: () =>
    # Get the documentation in JSON form
    @getDocs()
      .then (docs) ->
        docs.main = {items: docs.items}
        # Loop through each of the documentation areas
        for key of docs
          do (key) ->
            # Find the list to put navigation items in
            lists = document.querySelectorAll ".nav--docs-#{key}"
            for list in lists
              do (list) ->
                if not list? or not docs[key]?
                  return

                # Sort the items by sequence, then alphabetically
                docs[key].items.sort (a, b) ->
                  if a.seq?
                    return (a.seq - b.seq)

                  return -1 if a.title < b.title
                  return 1 if a.title > b.title
                  return 0

                # Loop through each of the documentation items
                for item in docs[key].items
                  do (item) ->
                    # Create a list element and a link
                    li = document.createElement 'li'
                    a  = document.createElement 'a'

                    url = "#{window.baseUrl}#{item._url}"

                    # Populate the URL and title
                    a.href      = url
                    a.innerHTML = item.title

                    # Add a class of active for the current URL
                    if "#{url}" is window.location.pathname
                      a.classList.add 'active'

                    # Add the item to the list
                    li.appendChild a
                    list.appendChild li

  ###*
   * Retrieve the package index JSON, and cache it
   * in local storage for five minutes, returning
   * the object in a Promise
   *
   * @return {Promise}
  ###
  getDocs: () ->
    new Promise (resolve, reject) ->
      # Get the updated at timestamp
      updatedAt = localStorage.getItem 'documentation_updated_at'
      timestamp = new Date().getTime()

      # If we are within the cache time, get and parse the
      # cached documentation list
      if (updatedAt + 300) > timestamp
        json = localStorage.getItem 'documentation'
        resolve JSON.parse(json)
        return

      # Fetch the list from the stored JSON file
      fetch "#{window.baseDomain}#{window.baseUrl}/docs.json"
        # Parse the JSON response
        .then (response) ->
          response.json()

        # Cache the response
        .then (response) ->
          localStorage.setItem 'documentation', JSON.stringify(response.docs)
          localStorage.setItem 'documentation_updated_at', timestamp
          resolve response.docs

        # Catch parsing errors
        .catch (err) ->
          reject err
