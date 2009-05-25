#
#  unfollowbotDelegate.rb
#  unfollowbot
#
#  Created by Greg Borenstein on 5/22/09.
#  Copyright (c) 2009 __MyCompanyName__. All rights reserved.
#

require "base64"
require "cgi"

class ConnectionDelegate

  def initialize(parent, &block)
    @parent = parent
    @block = block
  end

  def connectionDidFinishLoading(connection)
    doc = NSXMLDocument.alloc.initWithData(@receivedData,
                                           options:NSXMLDocumentValidate,
                                           error:nil)

    if doc
      @block.call(doc)
    else
      @block.call("Invalid response")
    end
  end

  def connection(connection, didReceiveResponse:response)
    case response.statusCode
    when 401
      @block.call("Invalid username and password")
    when (400..500)
      @block.call("Unable to complete your request")
    end
  end

  def connection(connection, didReceiveData:data)
    @receivedData ||= NSMutableData.new
    @receivedData.appendData(data)
  end

  def connection(conn, didFailWithError:error)
    @parent.status_label.stringValue = "Error communicating with Twitter"
  end
end


class UnfollowbotDelegate
  attr_accessor :credentials_window, :main_window
  attr_accessor :username_field, :password_field
  attr_accessor :username, :password, :friends
  attr_accessor :table_view, :status_label
  
  def applicationDidFinishLaunching(notification)
    NSApp.beginSheet(credentials_window, 
                    modalForWindow:main_window,
                    modalDelegate:nil,
                    didEndSelector:nil,
                    contextInfo:nil)
  end
  
  def initialize
    @friends = []
  end
  
  def submitCredentials(sender)
    self.username = username_field.stringValue
    self.password = password_field.stringValue
    NSApp.endSheet(credentials_window)
    credentials_window.orderOut(sender)
    NSLog "I have username: #{username}"
    NSLog "I have password: #{password}"
    self.status_label.stringValue = "Fetching friend data..."
    getNextResultPage(1)
  end
  
  def getNextResultPage(neededPage)
    NSLog("Getting next page: #{neededPage}")
    NSLog("#{self.friends.length} friends")
    @currentPage = neededPage
    url = NSURL.URLWithString("https://twitter.com/statuses/friends.xml?page=#{neededPage}")
    request = NSMutableURLRequest.requestWithURL(url)
    auth_token = Base64.encode64("#{username}:#{password}").strip
    request.setValue("Basic #{auth_token}",
                     forHTTPHeaderField:"Authorization")
    
    delegate = ConnectionDelegate.new(self) do |doc|
      @receivedData = nil
      users = doc.rootElement.nodesForXPath('user', error:nil)
      self.friends += users.map do |u|
        UNFTTwitterUser.new(u)
      end
      NSLog "Found #{users.length} users"
    
      if users.length == 100
        getNextResultPage(@currentPage + 1)
      else
        self.friends.sort!{|a,b| b.tweets_per_day <=> a.tweets_per_day}
        table_view.reloadData
        self.status_label.stringValue = "Updated"
      end
    end

    NSURLConnection.connectionWithRequest(request, delegate:delegate)
  end
  
  def hideCredentials(sender)
    NSLog "Cancelled twitter credentials"
    NSApp.endSheet(credentials_window)
    credentials_window.orderOut(sender)
  end
  
  def link_to_twitter_page(sender)
    friend = self.friends[sender.selectedRow]
    NSWorkspace.sharedWorkspace.openURL(NSURL.URLWithString("http://twitter.com/#{friend.screen_name}"))
  end
  
  def unfollow_friend(sender)
    friend = self.friends[sender.selectedRow]
    url = NSURL.URLWithString("https://twitter.com/friendships/destroy/#{friend.user_id}.xml")
    NSLog("unfollowing: #{friend.screen_name}")
    request = NSMutableURLRequest.requestWithURL(url)
    request.HTTPMethod = "DELETE"
    auth_token = Base64.encode64("#{username}:#{password}").strip
    request.setValue("Basic #{auth_token}",
                     forHTTPHeaderField:"Authorization")
                     
    delegate = ConnectionDelegate.new(self) do |doc|
      #check for success
      # if success
        # remove the row of the given user
        self.friends = self.friends - [friend]
        table_view.reloadData
        self.status_label.stringValue = "Unfollowed #{friend.screen_name}"
        # put a success message in the status
      # else
        # complain
    end
    
    NSURLConnection.connectionWithRequest(request, delegate:delegate)

  end
end
