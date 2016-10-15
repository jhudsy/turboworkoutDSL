#####################################################################
#This code is provided under a creative commons licence. 
#Author: Nir Oren (nir at jhudsy dot org)
#Version: 0.00002 (alpha), 14/10/2016
#NOTE: Opal doesn't allow << in strings
#####################################################################
class Comment
  def initialize(text,time:0,duration:10)
    @text=text
    @time=time
    @duration=duration
  end
  def toErg(startTime)
   return "#{startTime+@time}\t#{@text}\t#{@duration}\n"
  end
end
##############################################
class Ramp
  def initialize(duration:,start:,finish:,comments:[])
    @duration=duration
    @start=start
    @finish=finish
    @comments=comments
  end

  #reminder: array format is array of arrays containing [startTime,finishTime,startPower,endPower]
  def toErgArray(startTime,array)
    array << [startTime,startTime+@duration,@start,@finish]
    return array
  end

  def endTime(startTime)
  	return startTime+@duration
  end

  def toErgComments(startTime)
	out=""
  	@comments.each do |c|
	  out =out + c.toErg(startTime)
	end
        return out
  end
end
##############################################
class Steady < Ramp
  def initialize(duration:,power:,comments:[])
    super(duration: duration,start: power, finish: power, comments: comments)
  end
end
#############################################
class Interval
  def initialize(components:, comments:[])
    @components=components
    @comments=comments
  end

  #reminder: array format is array of arrays containing [startTime,finishTime,startPower,endPower]
  def toErgArray(startTime,array)
    @components.each do |c|
      array=c.toErgArray(startTime,array)
      startTime=c.endTime(startTime)
    end
    return array
  end

  #condition is if the finish of the current segment is the same as the start and finish of the next one, the two can be merged. Repeat until condition doesn't hold for component, and then new index is index of unmergable component.
  #reminder: array format is array of arrays containing [startTime,finishTime,startPower,endPower]
  #SHOULD ONLY BE CALLED FROM WORKOUT
  def simplifyErgArray(array)
    current=0 #the "start"
    lookingAt=1 #the element we're looking at
    toRemove=[] #elements to remove
    while (current<array.length && lookingAt<array.length) do
      if (array[current][2]==array[current][3] && 
          array[current][2]==array[lookingAt][2] &&
          array[current][2]==array[lookingAt][3]
         ) 
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

  #only use in workout after simplifying array
  def printErgArray(array)
    out=""
    array.each do |a|
      out=out+"#{'%.02f' % (a[0]/60.0)}\t#{a[2]}\n#{'%.02f' % (a[1]/60.0)}\t#{a[3]}\n"
    end
    return out
  end
  
  def endTime(startTime)
    @components.each do |c|
      startTime=c.endTime(startTime)
    end
    return startTime
  end

  def toErgComments(startTime)
        out=""
  	@comments.each do |c|
	  out=out+c.toErg(startTime)
	end
        @components.each do |c|
          out =out + c.toErgComments(startTime)
          startTime=c.endTime(startTime)
        end
        return out
  end

  def toString(version: 2, units:"ENGLISH",description:"A description", fileName:"blah.mrc",power:"PERCENT")
    array=toErgArray(0,[])
    array=simplifyErgArray(array)
    output = "[COURSE HEADER]\nVERSION\t=\t#{version}\nUNITS\t=\t#{units}\nDESCRIPTION\t=\t#{description}\nFILE NAME\t=\t#{fileName}\nMINUTES\t#{power}\n[END COURSE HEADER]\n[COURSE DATA]\n"
    output=output+printErgArray(array)
    output =output+ "[END COURSE DATA]\n"
    output =output+ "[COURSE TEXT]\n"
    output =output+ toErgComments(0)
    output =output+ "[END COURSE TEXT]\n"
    return output
  end
end
#############################################
def steady(duration:,power:,comments:[])
  return Steady.new(duration:duration,power:power,comments:comments)
end
def ramp(duration:,start:,finish:,comments:[])
  return Ramp.new(duration:duration,start:start,finish:finish,comments:comments)
end
def interval(components,comments:[])
  return Interval.new(components:components,comments:comments)
end
def comment(c,time:0,duration:10)
  return Comment.new(c,time:time,duration:duration)
end
def repeat(thing,times)
  return Interval.new(components:[thing]*times)
end

def workout(components,version: 2, units:"ENGLISH",description:"A description", fileName:"blah.mrc",power:"PERCENT")
  w=Workout.new(components:components)
  return w.toString(version:version,units:units,description:description,fileName:fileName,power:power)
end

