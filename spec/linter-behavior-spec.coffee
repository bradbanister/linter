describe 'Linter Behavior', ->
  linter = null
  linterState = null
  bottomContainer = null
  trigger = (el, name) ->
    event = document.createEvent('HTMLEvents');
    event.initEvent(name, true, false);
    el.dispatchEvent(event);

  getLinter = ->
    return {grammarScopes: ['*'], lintOnFly: false, modifiesBuffer: false, scope: 'project', lint: -> }
  getMessage = (type, filePath) ->
    return {type, text: "Some Message", filePath, range: [[0, 0], [1,1]]}


  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('linter').then ->
        linter = atom.packages.getActivePackage('linter').mainModule.instance
        linterState = linter.state
        bottomContainer = linter.views.bottomContainer

  describe 'Bottom Tabs', ->
    it 'defaults to file tab', ->
      expect(linterState.scope).toBe('File')

    it 'changes tab on click', ->
      trigger(bottomContainer.getTab('Project'), 'click')
      expect(linterState.scope).toBe('Project')

    it 'toggles panel visibility on click', ->
      expect(linter.views.panel.getVisibility()).toBe(true)
      trigger(bottomContainer.getTab('File'), 'click')
      expect(linter.views.panel.getVisibility()).toBe(false)
      trigger(bottomContainer.getTab('File'), 'click')
      expect(linter.views.panel.getVisibility()).toBe(true)

    it 're-enables panel when another tab is clicked', ->
      expect(linter.views.panel.getVisibility()).toBe(true)
      trigger(bottomContainer.getTab('File'), 'click')
      expect(linter.views.panel.getVisibility()).toBe(false)
      trigger(bottomContainer.getTab('Project'), 'click')
      expect(linter.views.panel.getVisibility()).toBe(true)

    it 'updates count on pane change', ->
      provider = getLinter()
      expect(bottomContainer.getTab('File').count).toBe(0)
      messages = [getMessage('Error', '/etc/passwd')]
      linter.setMessages(provider, messages)
      linter.messages.updatePublic()
      waitsForPromise ->
        atom.workspace.open('/etc/passwd').then ->
          expect(bottomContainer.getTab('File').count).toBe(1)
          atom.workspace.open('/tmp/non-existing-file')
        .then ->
          expect(bottomContainer.getTab('File').count).toBe(0)

  describe 'Markers', ->
    it 'automatically marks files when they are opened if they have any markers', ->
      provider = getLinter()
      messages = [getMessage('Error', '/etc/passwd')]
      linter.setMessages(provider, messages)
      waitsForPromise ->
        atom.workspace.open('/etc/passwd').then ->
          activeEditor = atom.workspace.getActiveTextEditor()
          expect(activeEditor.getMarkers().length).toBe(1)
