# Introduction
After a year of testing and almost losing all data in a hard drive accident, I am releasing my very first API tool today.

I presend you VMR_AutoBalancer.

<iframe width="560" height="315" src="https://www.youtube.com/embed/DEXVh1pqIIM" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>


It brings some feature for gamers and streamers with it, like:


Autobalance incoming audio from communication tools like Teamspeak, Discord or any voice chat.

One setting for all voice communication tools.

Voice activation, so you need only setup VMR_AutoBalancer and set all other communication tools you are using to voiceactivation at 1%.

3 widgets shows mute / unmute of mic, Voicemeeter out and Voicemeeter aux out.

Jingles that played by the recorder turns down if somebody talk and rise when nobody talk to not disturb the communication.

The gate on strip 1 will rise and fall too to prevent echos.


> ## latest release: [VMR_Autobalancer-1.4.7](https://github.com/BNK3R-Boy/VMR_AutoBalancer/releases/tag/1.4.7)


# Setup your Voicemeeter to:
Strip 1 = Mic

Thats it, everything else in the 'VMR.ini'.

how to coming soon...


Mic mute/unmute = F13

// Note: You don't have the F13 key or the chance to assign a key to F13? Use my F13 tool: [https://github.com/BNK3R-Boy/F13/](https://github.com/BNK3R-Boy/F13/)



# Change incoming communication strip (will be autobalanced):


Close VMR_AutoBalancer_[VERSIONNUMBER].exe.

Open 'VMR.ini'.

Edit or insert in the [HiddenConfig] section.

'BalancedStrip=X' to set the incoming communication strip. X = 0, 1, 2, 3, ..., 8.

Save VMR.ini and start VMR_AutoBalancer_[VERSIONNUMBER].exe.

example: BalancedStrip=3




# Turn off title light show:


Close VMR_AutoBalancer_[VERSIONNUMBER].exe.

Open 'VMR.ini'.

Edit or insert in the [HiddenConfig] section.

wtf=-1

Save VMR.ini and start VMR_AutoBalancer_[VERSIONNUMBER].exe.



# Turn on title light show:


Close VMR_AutoBalancer_[VERSIONNUMBER].exe.

Open 'VMR.ini'.

Delete line 'wtf=-1' from the [HiddenConfig] section.

Save VMR.ini and start VMR_AutoBalancer_[VERSIONNUMBER].exe.
