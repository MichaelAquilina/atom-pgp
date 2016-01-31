{CompositeDisposable} = require('atom')
path = require('path')
child_process = require('child_process')
readline = require('readline')

save_encrypted_contents = (content, uri, pgp_id) ->
  console.log("Saving encrypted contents with pgp_id #{pgp_id} to #{uri}")
  command = "echo '#{content}' | gpg --encrypt --recipient #{pgp_id} > #{uri}"
  console.log(command)
  child = child_process.exec(
    command, (error, stdout, stderr) ->
      console.log(stdout)
      console.log(stderr)
  )
  console.log("Finished saving")


AtomPGP =
  activate: (state) ->
    atom.workspace.addOpener (uri) ->
      if /^.*gpg$/.test(uri)
        editor = atom.workspace.buildTextEditor()
        child = child_process.exec("gpg -d #{uri}", (error, stdout, stderr) =>
          start = stderr.indexOf("ID") + 3
          pgp_id = stderr.substring(start, start+8)
          editor.setText(stdout)
          editor.getBuffer().setPath(uri)
          editor.getBuffer().fileSubscriptions?.dispose()
          editor.getBuffer().fileSubscriptions = new CompositeDisposable()
          editor.getBuffer().save () =>
            save_encrypted_contents(editor.getText(), uri, pgp_id)
          editor.getBuffer().saveAs = (uri) =>
            save_encrypted_contents(editor.getText(), uri, pgp_id)
        )
        return editor


  deactivate: ->
    # remove opener?

module.exports = AtomPGP
