#####################################################################
#Author: Nir Oren (nir at jhudsy dot org)
#Version: 0.00003 (alpha), 15/10/2016
#
#MIT License
#
#Copyright (c) 2016 Nir Oren
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.
#####################################################################

#####################################################################
# A class to store comments. The +text+ will appear as the workout runs at an appropriate +time+ and for some +duration+ (both specified in seconds).

class Comment
  def initialize(text,time:0,duration:10)
    @text=text
    @time=time
    @duration=duration
  end

  #Used to turn the comment into an ERG/MRC appropriate string. Requires the +start_time+ of the section.
  def toErg(start_time)
   return "#{start_time+@time}\t#{@text}\t#{@duration}\n"
  end
end

#####################################################################
# A class to represent ramped poweroutput. Requires a +duration+ (in seconds), a +start+ and +finish+ level of power, and an optional set of Comment objects.

class Ramp
  def initialize(duration:,start:,finish:,comments:[])
    @duration=duration
    @start=start
    @finish=finish
    @comments=comments
  end

  #This method returns the Ramp as a start time, end time, start power, end power array. Used as an intermediate step in printing out the Ramp in ERG/MRC format.
  def toErgArray(start_time,array)
    array << [start_time,start_time+@duration,@start,@finish]
    return array
  end

  #Returns the end time of the ramp given a +start_time+
  def endTime(start_time)
  	return start_time+@duration
  end

  #Returns a ERG/MRC formatted string of comments for this Ramp
  def toErgComments(start_time)
	out=""
  	@comments.each do |c|
	  out =out + c.toErg(start_time)
	end
        return out
  end
end

#####################################################################
# This class is a ramp which doesn't change its power

class Steady < Ramp
  def initialize(duration:,power:,comments:[])
    super(duration: duration,start: power, finish: power, comments: comments)
  end
end

#####################################################################
#This class is a collection of components - intervals, ramps and steady states.

class Interval
  def initialize(components:, comments:[])
    @components=components
    @comments=comments
  end

  #This method returns an array of   start time, end time, start power, end power arrays for its components. Used as an intermediate step in printing out the Ramp in ERG/MRC format. Requires the +start_time+ of the interval and the current +array+ which is added to by the method.
  def toErgArray(start_time,array)
    @components.each do |c|
      array=c.toErgArray(start_time,array)
      start_time=c.endTime(start_time)
    end
    return array
  end

  #Returns the end time of the interval (given the interval +start_time+ in seconds)
  def endTime(start_time)
    @components.each do |c|
      start_time=c.endTime(start_time)
    end
    return start_time
  end

  #Returns a ERG/MRC formatted string of comments for this interval, based on its subcomponents. Makes use of the interval's +start_time+.
  def toErgComments(start_time)
        out=""
  	@comments.each do |c|
	  out=out+c.toErg(start_time)
	end
        @components.each do |c|
          out =out + c.toErgComments(start_time)
          start_time=c.endTime(start_time)
        end
        return out
  end
end

#############################################
#The Workout is a special type of interval encapsulating the entire workout. Includes accessors for the various ERG/MRC file parameters. N.B. +power+ should be either "PERCENT" (default) or "WATTS".

class Workout < Interval
attr_accessor :version, :units, :description, :filename, :power

  @@__workout_instance=nil

  def initialize(components:, comments:[], version: 2, units:"ENGLISH",description:"A description", filename:"blah.mrc",power:"PERCENT")
    super(components:components,comments: comments)
    @@__workout_instance=self
    @version=version
    @units=units
    @description=description
    @filename=filename
    @power=power
  end

  def self.instance
    return @@__workout_instance
  end

  #This method takes in an Erg Array (of start and end time and power tuples) and strips out duplicates. Requires the array, and returns the simplified erg array.
  def simplifyErgArray(array)
    current=0 #the "start" element
    lookingAt=1 #the element we're looking at to decide if it's the same as current
    toRemove=[] #duplicate elements to remove

    while (current<array.length && lookingAt<array.length) do
      if (array[current][2]==array[current][3] && 
          array[current][2]==array[lookingAt][2] &&
          array[current][2]==array[lookingAt][3]
         ) #if elements are the same, remove them, look at next element.
        toRemove << array[lookingAt]
        lookingAt+=1
      elsif (current<(lookingAt-1)) # end of run and there's something to remove
        #current to lookingAt-1 can be merged
        array[current][1]=array[lookingAt][0]
        current=lookingAt
        lookingAt=current+1
      else #we've found nothing to remove, go to next element and repeat
        current=lookingAt
        lookingAt=current+1
      end
    end
    array=array-toRemove
    return array
  end

  #Given an ErgArray, print it out in ERG/MRC format
  def printErgArray(array)
    out=""
    array.each do |a|
      out=out+"#{'%.02f' % (a[0]/60.0)}\t#{a[2]}\n#{'%.02f' % (a[1]/60.0)}\t#{a[3]}\n"
    end
    return out
  end
  
  #Print out the entire ERG/MRC file
  def toString()
    array=toErgArray(0,[])
    array=simplifyErgArray(array)
    output = "[COURSE HEADER]\nVERSION\t=\t#{@version}\nUNITS\t=\t#{@units}\nDESCRIPTION\t=\t#{@description}\nFILE NAME\t=\t#{@filename}\nMINUTES\t#{@power}\n[END COURSE HEADER]\n[COURSE DATA]\n"
    output=output+printErgArray(array)
    output =output+ "[END COURSE DATA]\n"
    output =output+ "[COURSE TEXT]\n"
    output =output+ toErgComments(0)
    output =output+ "[END COURSE TEXT]\n"
    return output
  end
end

#####################################################################

#####################################################################
#Below here is the actual DSL functionality - methods that instantiate the appropriate objects to represent the DSL.

#Define a steady segment - creates a new Steady object.

def steady(duration:,power:,comments:[])
  return Steady.new(duration:duration,power:power,comments:comments)
end

#Define a ramp segment - creates a new Ramp object.

def ramp(duration:,start:,finish:,comments:[])
  return Ramp.new(duration:duration,start:start,finish:finish,comments:comments)
end

#Define an interval - creates a new Interval object. Takes an array of +components+ (Interval Ramp and Steady objects) as parameters.

def interval(components,comments:[])
  return Interval.new(components:components,comments:comments)
end

#Create a new Comment object.

def comment(c,time:0,duration:10)
  return Comment.new(c,time:time,duration:duration)
end

#Create a new interval by repeating +thing+ +times+ times.

def repeat(thing,times)
  return Interval.new(components:[thing]*times)
end

#Creates a new Workout object.

def workout(components,version: 2, units:"ENGLISH",description:"A description", filename:"blah.mrc",power:"PERCENT",comments:[])
  w=Workout.new(components:components,comments:comments,version:version,units:units,description:description,filename:filename,power:power)
  return w.toString
end

