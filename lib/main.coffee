{CompositeDisposable} = require('atom')
path = require('path')
child_process = require('child_process')
readline = require('readline')

save_encrypted_contents = (content, uri, pgp_id) ->
  console.log("Saving encrypted contents with pgp_id #{pgp_id} to #{uri}")
  command = "echo '#{content}' | gpg --encrypt --recipient #{pgp_id} > #{uri}"
  child_process.exec(
    command, (error, stdout, stderr) ->
      console.log(stdout)
      console.log(stderr)
  )


load_encrypted_contents = (uri) ->
  console.log("Loading encrypted contents from #{uri}")
  return new Promise( (resolve, reject) ->
    child_process.exec(
      "gpg --batch -d #{uri}",
      (error, stdout, stderr) ->
        if error is not null
          reject()
        else
          start = stderr.indexOf("ID") + 3
          pgp_id = stderr.substring(start, start+8)
          console.log("Found PGP id #{pgp_id}")
          resolve(stdout)
    )
  )

load_encrypted_contents_sync = (uri) ->
  contents = child_process.execSync("gpg --batch -d #{uri}")
  return contents


AtomPGP =
  activate: (state) ->
    atom.workspace.addOpener (uri) ->
      if /^.*gpg$/.test(uri)
        editor = atom.workspace.buildTextEditor()
        pgp_buffer = editor.getBuffer()

        pgp_buffer.updateCachedDiskContents = (flushCache=false, callback) ->
          load_encrypted_contents(@getPath()).then (contents) =>
            @cachedDiskContents = contents
            callback?()
        pgp_buffer.updateCachedDiskContentsSync = () ->
          @cachedDiskContents = load_encrypted_contents_sync(@getPath())

        pgp_buffer.save = () ->
          save_encrypted_contents(@getText(), @getPath(), "michaelaquilina@gmail.com")
        pgp_buffer.saveAs = (uri) ->
          save_encrypted_contents(@getText(), uri, "michaelaquilina@gmail.com")
        pgp_buffer.setPath(uri)
        pgp_buffer.load()
        console.log("#{pgp_buffer.file}")

        return editor


  deactivate: ->
    # remove opener?

module.exports = AtomPGP
