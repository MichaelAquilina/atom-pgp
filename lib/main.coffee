{CompositeDisposable, TextEditor} = require('atom')
path = require('path')
child_process = require('child_process')

AtomPGP =
  subscriptions: null

  activate: (state) ->
    atom.workspace.addOpener (uri) ->
      editor = new TextEditor()
      if /^.*gpg$/.test(uri)
        child = child_process.exec("gpg -d #{uri}", (error, stdout, stderr) =>
          editor.setText(stdout)
        )
      return editor


  deactivate: ->

module.exports = AtomPGP
