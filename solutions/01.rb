class Array
    
  def to_hash
    inject({}) { |hash, pair| hash[pair[0]] = pair[1]
      hash }
  end

  def index_by
    map { |n| [yield(n), n] }.to_hash
  end

  def subarray_count(subarray)
    each_cons(subarray.length).count(subarray)
  end

  def occurences_count
    result = Hash.new(0)
    each { |n| result[n] = self.count(n) }
    result
  end
end




