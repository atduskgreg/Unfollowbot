#
#  UNFTTwitterUser.rb
#  unfollowbot
#
#  Created by Greg Borenstein on 5/23/09.
#  Copyright (c) 2009 __MyCompanyName__. All rights reserved.
#

class UNFTTwitterUser
  def initialize(user_node)
    @xml = user_node
  end
  
  def profile_image
    return @profile_image if @profile_image
    
    profile_image_url = get_from_xml('profile_image_url')
    url = NSURL.URLWithString(profile_image_url)
    @profile_image = NSImage.alloc.initWithContentsOfURL(url)
  end
  
  def self.unfollow_button
    @@unfollow_button ||= NSImage.alloc.initWithContentsOfFile(NSBundle.mainBundle.pathForImageResource("skull"))
  end
  
  def unfollow_button
    @unfollow_button ||= UNFTTwitterUser.unfollow_button
  end
  
  def real_name_and_screen_name
    "#{self.real_name}\n(#{self.screen_name})"
  end
  
  def user_id
    @user_id ||= get_from_xml('id')
  end
  
  def screen_name
    @screen_name ||= get_from_xml('screen_name')
  end
  
  def real_name
    @real_name ||= get_from_xml('name')
  end
  
  def created_at
    @created_at ||= get_from_xml('created_at')
  end
  
  def statuses_count
    @statuses_count ||= get_from_xml('statuses_count')
  end
  
  def get_from_xml(value)
    @xml.nodesForXPath(value, error:nil).first.stringValue
  end
      
  def tweets_per_day
    return @tweets_per_day if @tweets_per_day
    
    created_at_date = NSDate.dateWithNaturalLanguageString(self.created_at)
    time_ago = NSDate.date.timeIntervalSinceDate(created_at_date)
    days_ago = (time_ago / 60 / 60 / 24)
    @tweets_per_day = (self.statuses_count.to_i / days_ago).round(2)
  end
  
end
