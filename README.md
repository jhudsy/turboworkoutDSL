# turboworkoutDSL
This project allows you to create a workout in a simple language, which can then be converted to an ERG or MRC file, understandable by a wide variety of turbo training software (e.g., TrainerRoad, GoldenCheetah, Zwift etc).

The language aims to be both easily understandable and compact, by allowing segments to be associated with labels, which are then reused within intervals.

## The Language
An entire *workout*, as well as an *interval* is built up from three primitive components - *ramp*s,  *steady* states, or more *interval*s.

### Ramps and Steady States
Both ramps and steady states specify the amount of power that occur for some duration. Ramps smoothly move between two power levels over that duration, while steady states maintain that power for the entire duration.

For example, a steady state requiring one to hold a power of 35 for 60 seconds can be specified as 
```
steady duration: 60, power: 35
```
or equivalently `steady(duration: 60, power: 35)`.

A ramp takes a start and finish power, for example, 
```
ramp(duration: 480,start:40,finish:80)
```
which creates an 8 minute long ramp starting at a power of 40, and finishing at a power of 80.

### Labels
To allow for reuse, one can associate these states with labels, e.g.,
```
rest=steady duration: 60, power: 35
```

### Intervals
An interval is a combination of states (written within square brackets), which can be specified using labels or by declaring the interval itself. For example,
```
rest=steady duration: 60, power: 35

sprint=interval([steady(duration: 20,power: 105),
                 steady(duration: 40,power: 35)])

warmup=interval( [ramp(duration: 480,start:40,finish:80),
                 steady(duration: 60, power: 40),
                 repeat(sprint,3),
                 rest])
```
Note that the repeat keyword can be used to create an interval by repeating its component.

Comments can appear at any point within an interval, ramp or steady state. For example:
```
plusrpm=steady duration: 60, power:90, comments: [comment("+5 RPM")]
```
When the workout gets to this part of the session, the comment +5 RPM will appear (for 10 seconds by default). A more complex comment such as `comment("start interval",time:3,duration:5)` Will appear 3 seconds into the phase, and last for 5 seconds. `time:` or `duration:` can be omitted in which case the default behaviour will occur. 

### Workouts
A workout is a special interval which captures the entire training session, e.g.,
```
workout([warmup,interval1,recovery,interval2,recovery,interval1,cooldown])
```
By default, power is specified as a percent of max power, to change this to an absolute value, use
```
workout([warmup,interval1,recovery,interval2,recovery,interval1,cooldown],power:"WATTS")
```
Other parameters that can be used, which will affect the header of the ERG or MRC file are

| Parameter | Default |
|-----------|---------|
|`version:` | 2       |
|`units:`   | "ENGLISH"|
|`description:` | "A description"|
|`fileName:` | "blah.mrc"| 

## Note
The DSL is actually Ruby code, so you should avoid using words such as "if", "while", "for", "def" and "end".

## Example

As a warm-up, the following example  ramps up from 40 to 80% FTP power over 8 minutes, followed by 60 seconds at 35% power, two 20 second sprints at 150% FTP with 40 second rest, and another minute at 35%. The main session then starts with  a 3 minute isolated leg interval session, before jumping into three sets of high RPM work (varying between 100 and 110 rpm) at 80-85% FTP, with a two minute rest between sets. Finally, there's a 10 minute cool down, ramping from 70 to 40% FTP.

```
#We define rest as a 60 second steady session at 35% FTP
rest=steady duration: 60, power: 35

#A sprint interval is made up of 20s at 150% FTP, followed by 40s at 35%. A comment will appear at the start of the sprint and remain on screen for 5 seconds

sprint=interval [steady(duration: 20,power:150,comments:[comment("110rpm",duration:5)]),
                 steady(duration: 40,power:35)]


oneLeg=steady(duration:30,power: 40,comments:[comment("leg, 80rpm")])

legInterval=interval([oneLeg,
                   steady(duration: 60,power:50,comments:[comment("90+ rpm")]),
                   oneLeg,
                   rest])

wu=interval([ramp(duration:480,start:40,finish:80),
                 rest,
                 repeat(sprint,2),
                 rest ])

#Next, define steady minute sessions at 100 and 110 RPM respectively
h=steady duration: 60, power: 80,comments:[comment("100rpm")]
t=steady duration: 60, power: 85,comments:[comment("110rpm")]

#And define a rest within the main set as two minutes of rest
r=repeat(rest,2)

#The main set is a combination of the three things defined above
set=interval([h,h,t,h,h,t,h,h,t,h,h])

#and here's the entire workout
workout([wu,legInterval,set,r,set,r,set,ramp(duration:600,start:70,finish:40)])
```
