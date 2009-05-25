#
#  UnfollowTableDelegate.rb
#  unfollowbot
#
#  Created by Greg Borenstein on 5/23/09.
#  Copyright (c) 2009 __MyCompanyName__. All rights reserved.
#

class UNFTableDelegate
  attr_accessor :parent
  
  def numberOfRowsInTableView(tableView)
    parent.friends.count
  end
  
  def tableView(tableView, objectValueForTableColumn:column, row:row)
    if row < parent.friends.length
      if column.identifier == "profile_image" || column.identifier == "unfollow_button"
        cell = column.dataCellForRow(row)
        cell.image = parent.friends[row].valueForKey(column.identifier)
      end
            
      return parent.friends[row].valueForKey(column.identifier)
    end
    nil
  end
end
