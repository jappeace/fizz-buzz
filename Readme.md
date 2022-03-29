[![https://jappieklooster.nl](https://img.shields.io/badge/blog-jappieklooster.nl-lightgrey)](https://jappieklooster.nl/tag/haskell.html)
[![Jappiejappie](https://img.shields.io/badge/twitch.tv-jappiejappie-purple?logo=twitch)](https://www.twitch.tv/jappiejappie)
[![Jappiejappie](https://img.shields.io/badge/youtube-jappieklooster-red?logo=youtube)](https://www.youtube.com/channel/UCQxmXSQEYyCeBC6urMWRPVw)
[![Jappiejappie](https://img.shields.io/badge/discord-jappiejappie-black?logo=discord)](https://discord.gg/Hp4agqy)

> What then is the piping of Heaven?

This is an exploration into async exceptions through fizz buzz.

First I tried doing this time based, but that didn't quite
work out because the threads went out of sync.
Then I made a central "Flush" thread that indicates to the workers
what tick they were.
This worked.

There was still some syncing issue with the exceptions going
from the worker thread -> emitter thread.
But I fixed this by adding a timeout (this didn't go out of sync
because the ticks are emmited from same thread).

# Meditations on async exceptions

I thought these could be a channel replacement.
Looks like they can be.
And  are even strictly more powerful since (even pure)
computations can be interrupted.
It goes the other way of co-routines becuase the
interuption arrives from the outside (maybe even co-co-routines?)
, all the threads can do is disable the exceptions for blocks through masking
or handle them.

I even start to suspect this coding style is safe, 
because if you only catch your specific message type,
other async exceptions aren't caught
(like ThreadKilled, which you shouldn't catch without rethrowing!).

Of course, if you introduce this in a team, this nuance maybe lost
and it may be better to just keep on out right banning catching async exceptions.
Furthermore I'm not sure how fast this mechanism is compared to channel.
It maybe unlikely the async exception mechanismm has received much
performance attention (even though it's really cool!).

What I've been also curious about is how to represent  this 
mechanism as an algebra of sorts.
Imagine if we didn't have the runtime, how would you recreate this.
After all it can interrupt pure code.
