# this object is a kind of interface used to define
# method to use for extract required values from 
# initial objects
#
# use it by including it to your own Harvester class 
# and override method compute used to build a result 
# according to a specific inputed object 
#
class DataHarvester
  
  # constructor
  def initialize(array)
    @objects = array
  end
  
  # used to add all object to be treated
  def add(object)
    @objects.push(object)
  end
  
  # used to add all object to be treated
  def add_list(array)
    @objects.push(array)
    @objects.flatten!
  end
  
  # this method is an example one. It should be
  # override for a more interesting use
  # the return an array of Result object
  def compute(object)
    results = Array.new(Result.new(0,0))
    # TODO : override this method and place here the object
    # treatment to retreive date and value from it
    return results
  end
  
  # apply the compute method for all loaded object and
  # return an array of Result object
  def getResults
    results = []
    for object in @objects
      for r in compute(object)
        results.push(r)
      end
    end
    return results
  end
end