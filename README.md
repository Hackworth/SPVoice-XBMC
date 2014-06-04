SPVoice-XBMC
==============

About
-----
SPVoice-XBMC is a [SPVoice Proxy](https://github.com/Hackworth/SPVoice) plugin that allows you to send commands to [XBMC](http://www.xbmc.org).

SPVoice-XBMC was created by Jordan Hackworth, based on SiriProxy-XBMC created by brainwave9.
You are free to use, modify, and redistribute this gem as long as you give proper credit to the original author.

Credits
-------
This project uses parts of [xbmc-client](https://github.com/colszowka/xbmc-client), created by [Christoph Olszowka](https://github.com/colszowka)


Installation
------------
To install SPVoice-XBMC, add the following to your SPVoice Proxy config.yml file (~/.spvoice/config.yml):

    - name: 'XBMC'
      git: 'git://github.com/Hackworth/SPVoice-XBMC.git'
      xbmc_host: '192.168.1.4' #Internal IP address of your computer running XBMC.
      xbmc_port: 8080          #Port that the XBMC interface listens to.
      xbmc_username: 'xbmc'    #Username as specified in XBMC
      xbmc_password: 'xbmc'    #password as specified in XBMC


Multiroom configuration
-----------------------
If you have multiple XBMC systems in your house you can configure SPVoice-XBMC to control them.
To do so, create a configuration file called xbmc_rooms.yml and put in the same folder as config.yml
Here is an example of the rooms file:

    living room:
      host: '1.2.3.4'
      port: 8080
      username: 'xbmc'
      password: 'xbmc'
    game room:
      host: '1.2.3.5'
      port: 8080
      username: 'xbmc'
      password: 'xbmc'

The names 'living room' and 'game room' is what you use as room name when using the plugin.
Use lowercase letters only for the room names, that is what SPVoice-XBMC expects.
When you create the file xbmc_rooms.yml, the settings in config.yml are no longer used.


Usage
-----
The currently implemented commands are:

    xbmc [room]

This command can be used to test the plugin is working.
SPVoice will respond with "XBMC is online"
Optionally you can specify a room name if you have configured the plugin for multiple rooms.

    I'm in the <room name>
    Use the <room name>
    Control the <room name>

These commands set the active room.
All commands will be sent to this room, until you specify another room of course.

    watch <title> [in the <room name>]

This command will first look in your TV show library and play the first unwatched episode.
If no TV show is found, it will look in your movie library and play the first matching movie.
If you specify a room name, it will be played in that room and the active room will be updated.

    watch <show name> <season number> [episode number]

You are able to specify a season and episode number, to play a specific
episode. If only a season is given, it will play the first episode in
that season and queue up the rest of the episodes.

    pause

This command pauses the video player

    resume
    unpause
    continue

These command resume the video player

    stop

This command stops the video player


Notes
-----
Fuzzy Matching of titles has been implimented. The plugin will automatically select the closest match in title between your entire TV show and movie library. Let me know if you run into any irregularities with this.

The plugin is currently not able to handle multiple users controlling multiple rooms at the same time.
It can currently only keep track of the last active room.
