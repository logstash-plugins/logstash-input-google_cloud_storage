# encoding: utf-8

require 'zlib'
require 'mimemagic'

module LogStash
  module Inputs
    module CloudStorage
      # FileReader provides a unified way to read different types of log files
      # with predictable callbacks.
      class FileReader
        # read_lines reads lines from a file one at a time, optionally decoding
        # the file as gzip if decode_gzip is true.
        #
        # Handles files with both UNIX and Windows line endings.
        def self.read_lines(filename, decode_gzip, &block)
          if decode_gzip && gzip?(filename)
            read_gzip_lines(filename, &block)
          else
            read_plain_lines(filename, &block)
          end
        end

        # gzip? returns true if the given filename has a gzip file extension.
        def self.gzip?(filename)
          magic = MimeMagic.by_magic(::File.open(filename))
          magic ? magic.subtype == "gzip" : false
        end

        def self.read_plain_lines(filename, &block)
          line_num = 1
          ::File.open(filename).each do |line|
            block.call(line, line_num)
            line_num += 1
          end
        end

        def self.read_gzip_lines(filename, &block)
          line_num = 1
          Zlib::GzipReader.open(filename).each_line do |line|
            block.call(line, line_num)
            line_num += 1
          end
        end
      end
    end
  end
end
