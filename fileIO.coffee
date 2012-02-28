fs = require 'fs'
path = require 'path'


fileIO = exports

isLiteral = fileIO.isLiteral = yes

log = fileIO.log = (msg) ->
  if isLiteral then console.log msg


Object.defineProperties fileIO,
  isFileSync:
    value: (filePath) ->
      unless path.existsSync filePath then return no
      return (fs.statSync filePath).isFile()

  isFile:
    value: (filePath, cb) ->
      path.exists filePath, (doesExist) ->
        unless doesExist
          cb undefined, no
          return

        fs.stat filePath, (err, stats) ->
          if err?
            cb err
          else
            cb undefined, stats.isFile()

  isDirSync:
    value: (dirPath) ->
      unless path.existsSync dirPath then return no
      return (fs.statSync dirPath).isDirectory()

  isDir:
    value: (dirPath, cb) ->
      path.exists dirPath, (doesExist) ->
        unless doesExist then cb undefined, no
        fs.stat dirPath, (err, stats) ->
          if err?
            cb err
          else
            cb undefined, stats.isDirectory()

  copyFileSync:
    value: (sourceFile, targetFile) ->
      if path.existsSync targetFile
        if (fs.statSync targetFile).isDirectory()
          fs.rmdirSync targetFile

      data = fs.readFileSync sourceFile
      @makeDirSync path.dirname targetFile
      fs.writeFileSync targetFile, data
      log "Copy <#{sourceFile}> to <#{targetFile}>"

  makeDirSync:
    value: (dir) ->
      dir = path.resolve dir
      names = dir.split /\\|\//

      if names.length <= 1 then throw 'Cannot create directory on root or drives'

      filePath = names[0]
      for i in [1 .. names.length - 1]
        filePath = path.join filePath, names[i]

        unless path.existsSync filePath
          fs.mkdir filePath
          log "Create directory <#{filePath}>"

  copyDirSync:
    value: (sourceDir, targetDir, doesOverride = false) ->
      unless path.existsSync sourceDir then throw "<#{sourceDir}> does not exist"

      unless path.existsSync targetDir
        fileIO.makeDirSync targetDir
      else if (fs.statSync targetDir).isFile()
        fs.unlinkSync targetDir

      names = fs.readdirSync sourceDir

      for name in names
        src = path.join sourceDir, name
        srcStats = fs.statSync src
        des = path.join targetDir, name

        if srcStats.isFile()
          doesCopy = yes

          if path.existsSync des
            log "File <#{des}> exists"

            if doesOverride is no
              doesCopy = no

          if doesCopy
            @copyFileSync src, des
        else if srcStats.isDirectory()
          @copyDirSync src, des

  deleteDirSync:
    value: (dir) ->
      unless path.existsSync dir
        log 'Directory <#{dir}> does not exist'
        return false
      
      stat = fs.statSync dir
      unless stat.isDirectory() then throw "Path <#{dir}> is not a directory"

      act = (dir) ->
        names = fs.readdirSync dir

        for name in names
          filePath = path.join dir, name

          do (filePath) ->
            stat = fs.statSync filePath

            if stat.isFile()
              log "Delete #{filePath}"
              fs.unlinkSync filePath
            else if stat.isDirectory()
              act filePath

        log "Remove #{dir}"
        fs.rmdirSync dir
      act dir

  deleteSync:
    value: (filePath) ->       
      unless path.existsSync filePath then return

      stat = fs.statSync filePath

      if stat.isFile()
        fs.unlinkSync filePath
      else if stat.isDirectory()
        deleteDirSync filePath
      else
        throw 'Cannot delete <#{filePath}>'

  # deleteDir:
  #   value: (dir, callback) ->
  #     throw 'Not yet implemented'
  #     path.exists dir, (doesExist) ->
  #       unless doesExist then callback "Directory <#{dir}> does not exist"
        
  #       fs.stat dir, (err, stat) ->
  #         if err then callback err
  #         unless stat.isDirectory() then callback "Path <#{dir}> is not a directory"

  #         act = (dir, callback) ->
  #           fs.readdir dir, (err, names) ->
  #             if err then callback err

  #             for name in names
  #               filePath = path.join dir, name

  #               do (filePath) ->
  #                 fs.stat filePath, (err, stat) ->
  #                   if err then callback err

  #                   if stat.isFile()
  #                     log "Delete #{filePath}"
  #                     fs.unlink filePath, (err) ->
  #                       if err then callback err
  #                   else if stat.isDirectory()
  #                     act filePath, callback

  #             log "Remove #{dir}"
  #             fs.rmdir dir, (err) ->
  #               if err then callback err
  #         act dir, callback