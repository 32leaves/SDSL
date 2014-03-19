module JSUnZip

  class ZipFile

    def initialize(blob)
      @zip = `new JSUnzip(blob)`
      `self.zip.readEntries()`
    end

    def is_zip?
      `self.zip.isZipFile()`
    end

    def entries
      result = {}

      `for (var i = 0; i < self.zip.entries.length; i++) {`
      entry = `self.zip.entries[i]`
      if `entry.compressionMethod === 0`
        result[`entry.fileName`] = `entry.data`
      elsif `entry.compressionMethod === 8`
        result[`entry.fileName`] = ` JSInflate.inflate(entry.data)`
      end
      `}`

      result
    end

  end

end
