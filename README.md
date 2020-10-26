# VMR_AutoBalancer
 A communication remote control for Voicemeeter
 

### Setup your Voicemeeter to:
Strip 1 = Mic

Thats it, everything else in the 'VMR.ini'.

how to coming soon...


Mic mute/unmute = F13

// Note: You don't have the F13 key or the chance to assign a key to F13? Use my F13 tool: https://github.com/BNK3R-Boy/F13



### Change incoming communication strip (will be autobalanced):


Close VMR_AutoBalancer_[VERSIONNUMBER].exe

Open 'VMR.ini'.

Edit or insert in the [HiddenConfig] section.

Edit 'BalancedStrip=X' to set the incoming communication strip. X = 0, 1, 2, 3, ..., 8.

Save VMR.ini and start VMR_AutoBalancer_[VERSIONNUMBER].exe.

example: BalancedStrip=3




### Turn off title light show:


Close VMR_AutoBalancer_[VERSIONNUMBER].exe

Open 'VMR.ini'.

Edit or insert in the [HiddenConfig] section.

wtf=-1

Save VMR.ini and start VMR_AutoBalancer_[VERSIONNUMBER].exe.



### Turn on title light show:


Close VMR_AutoBalancer_[VERSIONNUMBER].exe.

Open 'VMR.ini'.

Delete line wtf from the [HiddenConfig] section.

Save VMR.ini and start VMR_AutoBalancer_[VERSIONNUMBER].exe
