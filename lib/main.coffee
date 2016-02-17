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

handle_gpg_output = (stdout, stderr)  ->
    start = stderr.indexOf("ID") + 3
    pgp_id = stderr.substring(start, start+8)
    return {
      data: stdout
      pgp_id: pgp_id
    }


load_encrypted_contents = (uri) ->
  console.log("Loading encrypted contents from #{uri}")
  return new Promise( (resolve, reject) ->
    child_process.exec(
      "gpg --batch -d #{uri}",
      (error, stdout, stderr) ->
        if error is not null
          reject()
        else
          resolve(handle_gpg_output(stdout, stderr))
    )
  )


load_encrypted_contents_sync = (uri) ->
  process = child_process.spawnSync("gpg --batch -d #{uri}")
  return handle_gpg_output(process.stdout.toString(), process.stderr.toString())


AtomPGP =
  activate: (state) ->
    atom.workspace.addOpener (uri) ->
      if /^.*gpg$/.test(uri)
        editor = atom.workspace.buildTextEditor()
        pgp_buffer = editor.getBuffer()

        pgp_buffer.updateCachedDiskContents = (flushCache=false, callback) ->
          load_encrypted_contents(@getPath()).then (result) =>
            @cachedDiskContents = result['data']
            @pgp_id = result['pgp_id']
            callback?()
        pgp_buffer.updateCachedDiskContentsSync = () ->
          result = load_encrypted_contents_sync(@getPath())
          @cachedDiskContents = result['data']
          @pgp_id = result['pgp_id']

        pgp_buffer.saveAs = (uri) ->
          save_encrypted_contents(@getText(), uri, @pgp_id)
        pgp_buffer.setPath(uri)
        pgp_buffer.load()

        return editor


  deactivate: ->
    # remove opener?

module.exports = AtomPGP
