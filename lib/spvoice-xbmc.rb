#
# Copyright (C) 2012 by Jordan Hackworth <dev@jordanhackworth.com>
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'cora'
require 'xbmc_library'
require 'chronic'

#######
# This is plugin to control XBMC
# Remember to configure the host and port for your XBMC computer in config.yml in the SiriProxy dir
######

class SPVoice::Plugin::XBMC < SPVoice::Plugin
  def initialize(config)
    appname = "SPVoice-XBMC"
    host = config["xbmc_host"]
    port = config["xbmc_port"]
    username = config["xbmc_username"]
    password = config["xbmc_password"]

    @roomlist = Hash["default" => Hash["host" => host, "port" => port, "username" => username, "password" => password]]

    rooms = File.expand_path('~/.spvoice/xbmc_rooms.yml')
    if (File::exists?( rooms ))
      @roomlist = YAML.load_file(rooms)
    end

    @active_room = @roomlist.keys.first

    @xbmc = XBMCLibrary.new(@roomlist, appname)
  end

  def timeseek(time)
    if (time)
      numberized_time = Chronic::Numerizer.numerize(time)
      hours_check = numberized_time.match('\d+ hour')
      minutes_check = numberized_time.match('\d+ minute')
      if hours_check
        hours = hours_check[0].match('\d+')[0].to_i
      else
        hours = 0
      end
      if minutes_check
        minutes = minutes_check[0].match('\d+')[0].to_i
      else
        minutes = 0
      end
      @xbmc.player_seek(hours, minutes)
      return "Seeking to #{hours} hours #{minutes} minutes"
    end
  end

  #show plugin status
  listen_for /[xX] *[bB] *[mM] *[cC] *(.*)/i do |roomname|
    roomname = roomname.downcase.strip
    roomcount = @roomlist.keys.length

    if (roomcount > 1 && roomname == "")
      say "You have #{roomcount} rooms, here is their status:"

      @roomlist.each { |name,room|
        if (@xbmc.connect(name))
          say "[#{name}] Online", spoken: "The #{name} is online"
        else
          say "[#{name}] Offline", spoken: "The #{name} is offline"
        end
      }
    else
      if (roomname == "")
        roomname = @roomlist.keys.first
      end
      if (roomname != "" && roomname != nil && @roomlist.has_key?(roomname))
        if (@xbmc.connect(roomname))
          say "XBMC is online"
        else
          say "XBMC is offline, please check the plugin configuration and check if XBMC is running"
        end
      else
        say "There is no room defined called \"#{roomname}\""
      end
    end
    request_completed #always complete your request! Otherwise the phone will "spin" at the user!
  end

  # stop playing
  listen_for /^stop/i do
    if (@xbmc.connect(@active_room))
      if @xbmc.stop()
        say "Video Stopped"
      else
        say "There is no video playing"
      end
    end
    request_completed #always complete your request! Otherwise the phone will "spin" at the user!
  end

  # pause playing
  listen_for /^pause/i do
    if (@xbmc.connect(@active_room))
      if @xbmc.pause()
        say "Pausing video"
      else
        say "There is no video playing"
      end
    end
    request_completed #always complete your request! Otherwise the phone will "spin" at the user!
  end

  # resume playing
  listen_for /^resume|unpause|continue/i do
    if (@xbmc.connect(@active_room))
      if @xbmc.pause()
        say "I resumed the video", spoken: "Resuming video"
      else
        say "There is no video playing"
      end
    end
    request_completed #always complete your request! Otherwise the phone will "spin" at the user!
  end

  # set default room
  listen_for /(?:(?:[Ii]'m in)|(?:[Ii] am in)|(?:[Uu]se)|(?:[Cc]ontrol)) the (.*)/i do |roomname|
    roomname = roomname.downcase.strip
    if (roomname != "" && roomname != nil && @roomlist.has_key?(roomname))
      @active_room = roomname
      say "Noted.", spoken: "Commands will be sent to the \"#{roomname}\""
    else
      say "There is no room defined called \"#{roomname}\""
    end
    request_completed #always complete your request! Otherwise the phone will "spin" at the user!
  end

  listen_for /^update my library/i do
    if (@xbmc.connect(@active_room))
      @xbmc.update_library
      say "XBMC Library updating..."
    else
      say "The XBMC interface is unavailable, please check the plugin configuration or check if XBMC is running"
    end
  end

  listen_for /^unwatched tv(.*)/i do |type|
    if (@xbmc.connect(@active_room))
      type = "TV shows"
      unwatched = @xbmc.find_unwatched_tv_shows
      answer = Array.new
      answer << "Unwatched #{type}: "
      unwatched.first(15).each { |item|
        answer << item["label"]
      }
      say "#{answer.join("\n")}"
    else
      say "The XBMC interface is unavailable, please check the plugin configuration or check if XBMC is running"
    end
    request_completed
  end

  listen_for /^recently added(.*)/i do |type|
    if (@xbmc.connect(@active_room))
      if (type.downcase.strip == "movies")
        downloaded = @xbmc.recent_movies
        type = "movies"
      else
        type = "TV shows"
        downloaded = @xbmc.recent_episodes
      end
      answer = Array.new
      answer << "Downloaded these #{type}: "
      downloaded.first(15).each { |download|
        show = ""
        if (download["showtitle"] != nil)
          show = download["showtitle"] + " "
        end
        if (download["playcount"] == 0)
          answer << show + download["label"]
        end
      }
      say "#{answer.join("\n")}"
    else
      say "The XBMC interface is unavailable, please check the plugin configuration or check if XBMC is running"
    end
    request_completed
  end

  #play movie or episode
  listen_for /watch (.+?)(?: in the (.+?))?(?: time index (.*))?$/i do |title,roomname,time|
    puts title
    puts roomname
    puts time
    if (roomname == "" || roomname == nil)
      roomname = @active_room
    else
      roomname = roomname.downcase.strip
    end

    if (@xbmc.connect(roomname))
      if @roomlist.has_key?(roomname)
        media = @xbmc.find_media(title.split(' season')[0])
        @active_room = roomname
      end
      if (media == nil)
        say "Title not found, please try again"
      else
        if (media["tvshowid"] == nil)
          say "Now playing \"#{media["title"]}\" #{timeseek(time)}"
          @xbmc.play(media["file"])
        else
          numberized_title = Chronic::Numerizer.numerize(title)
          season_check = numberized_title.match('season \d+')
          if season_check
            season = season_check[0].match('\d+')[0].to_i
            episode_check = numberized_title.match('episode \d+')
            if episode_check
              episode = episode_check[0].match('\d+')
              episode = @xbmc.find_episode(media["tvshowid"], season, episode)
              say "Now playing \"#{episode["title"]}\" (#{episode["showtitle"]}, Season #{episode["season"]}, Episode #{episode["episode"]}) #{timeseek(time)}"
              @xbmc.play(episode["file"])
              #search for spefic episode
            else
              #search for entire season
              media = @xbmc.play_season(media["tvshowid"], season)
            end
          else
            episode = @xbmc.find_first_unwatched_episode(media["tvshowid"])
            if (episode == "")
              say "No unwatched episode found for \"#{media["label"]}\""
            else
              say "Now playing \"#{episode["title"]}\" (#{episode["showtitle"]}, Season #{episode["season"]}, Episode #{episode["episode"]}) #{timeseek(time)}"
              @xbmc.play(episode["file"])
            end
          end
        end
      end
    else
      say "The XBMC interface is unavailable, please check the plugin configuration or check if XBMC is running"
    end
    request_completed #always complete your request! otherwise the phone will "spin" at the user!
  end
  listen_for /time index (.+?)$/i do |time|
    roomname = @active_room
    if (@xbmc.connect(roomname))
      say "#{timeseek(time)}"
    else
      say "The XBMC interface is unavailable, please check the plugin configuration or check if XBMC is running"
    end
    request_completed #always complete your request! otherwise the phone will "spin" at the user!
  end
end
