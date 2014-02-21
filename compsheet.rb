#!/usr/bin/env ruby

require 'psd_native'
require 'oily_png'
require 'thread'

mutex = Mutex.new
mutex_png = Mutex.new

if ARGV.empty?
  puts "Usage:\ncompsheet.rb file.psd"
  exit
end

srcfile = ARGV[0]
srcfile_base = File.basename( srcfile, ".*" )

PSD.open(srcfile) do |psd|

    psdtree = psd.tree
    png_width = psd.image.width * 2
    png_height =  (psd.image.height * (psd.layer_comps.length * 0.5)).ceil
    png = ChunkyPNG::Image.new(png_width, png_height, ChunkyPNG::Color::TRANSPARENT)

    threads = []
    psd.layer_comps.each_with_index do |c,index|
            offsetx = index.modulo(2) * psd.image.width
            offsety = psd.image.height * (index / 2).floor
            threads[index] = Thread.new {
            nm = c[:name].to_s
            tmp = nil
            mutex.synchronize do
                puts "reading layer comp '%s' " % c[:name]
                tmp = psdtree.filter_by_comp(c[:id]).to_png
            end
            mutex_png.synchronize do
                puts "compositing layer comp '%s' to master sheet " % c[:name]
                png.compose!( tmp, offsetx, offsety )
            end

            }
    end
    threads.each { |t|
        t.join
    }


    outfile = "%s_compsheet.png" % [srcfile_base]
    puts "saving '%s'" % [outfile]
    png.save(outfile, :interlace => false)
end
