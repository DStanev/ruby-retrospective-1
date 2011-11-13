class Song

  attr_accessor :name, :artist, :genre, :subgenre, :tags
      
  def initialize name, artist, genre, subgenre, tags
    @name = name
    @artist = artist
    @genre = genre
    @subgenre = subgenre 
    @tags = tags
  end

  def match_criteria? criteria
    criteria.keys.map{ |key| self.has_criteria?(key, criteria[key]) }.all?
  end

  def has_criteria? key, value 
    if(key == :name) then return self.name == value
    end
    if(key == :artist) then return self.artist == value
    end
    if(key == :tags) then return self.correct_tags? value
    end
    if(key == :filter) then return value.(self)
    end
  end

  def correct_tags? tags 
    tags = Array(tags)
    tags.collect{ |tag| 
      if tag.end_with? '!' 
      then not self.tags.include? tag.chomp '!' 
      else self.tags.include? tag 
      end }.all?  
  end
end


class Collection
    
  attr_accessor :songs

  def find criteria 
    @songs.select{ |song| song.match_criteria? criteria }
  end

  def initialize songs_as_string, artist_tags 
    @songs = songs_as_string.each_line.map{ |song| create song, artist_tags }
  end

  def create song, tags
    name = song_properties(song)[0]
    artist =  song_properties(song)[1]
    genre, subgenre = get_genre_and_subgenre song_properties(song)[2]
    tags = get_tags(song_properties(song)[3], artist, tags, [genre, subgenre])
    Song.new name, artist, genre, subgenre, tags
  end

  def song_properties song
    result = song.split(".")
    result.map! { |part| part.strip }
    result
  end

  def get_genre_and_subgenre str
    str.split(",").map{ |genre| genre.strip }
  end

  def get_tags str, artist, tags, genres
    res = []
    if str != nil
      res += str.split(",").map{ |tag| tag.strip }
    end
    if tags != nil and tags.include? artist
        res += tags[artist]
    end
    res + genres.select{ |genre| genre != nil }.collect{ |genre| genre.downcase}
  end
end

