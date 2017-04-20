# Sending Rich Push Notifications for iOS10 with Salesforce Part 2

## Introduction
In part one, we created a convenience class in Apex to allow us to construct a valid APS payload which can contain rich media such as images. We then used the Salesforce Universal Notification Framework to send the actual notification to the intended recipients. Now it is time to implement the logic within our iOS app to handle receiving, and displaying the notification correctly. 

### Price Change Notification Payload
If you set everything up correctly in part one, your APS payload should create a JSON message like the one below. The payload is pretty self-explanatory with the alert subjson the same as earlier versions of iOS. iOS10 introduces two new elements:

{
  "aps": {
    "mutable-content":1,
    "alert":{
      "title": "Notification title",
      "subtitle": "Notification subtitle",
      "body": "Notification body"
    }
  },
  "media-attachment": "https://url/to/mycontent.jpg”
}

#### media-attachment
The media-attachment element contains a URL to the property images. We are going to add this to the push notification message. Unfortunately, however, push notifications can only use local resources in messages. We will have to write some logic to fetch the image remotely and convert it to a local file. We will do this in a Notification Services extension, a new feature in iOS10

#### mutable-content
Mutable-content tells the iOS app whether the developer is able to modify the  content of the push notification or not. For our use-case, this must be set to “1” indicating we can modify the content, in particular to change the media-attachment to a local file, as mentioned above.  Using the `createMutablePayload` function in the `iOSRichMediaMessaging` package from tutorial one sets this flag to 1 for you.

## Notification Services Extension Target
Now that you know what the new APS payload looks like, we can get started working on our notification. Let’s assume that you already have a iOS project created, and have added the logic in your AppDelegate to receive notifications, and register for notifications from Salesforce. (If you need an example, you can check out the full AppDelegate class from this tutorial [here](https://github.com/quintonwall/DreamhouseAnywhere/blob/master/DreamhouseAnywhere/DreamhouseAnywhere/AppDelegate.swift) ). The first thing you need to do is add a new target to our project where we can handle working with our push notification. iOS10 introduces a new Application Extension, called Notification Services Extension, to help us out.

The Notification Services extension is where you can intercept a push notification and modify it’s contents. For example, you could change the message to include the user’s current location from their phone, or in our example, we need to take the URL  of the property image and convert it to a local file to be displayed. Push notifications messages can only use local resources. 

From your Xcode project, select `File —> New Target, and choose Notification Service Extension` from the Application Extension category. Click next, and choose any name you like. I’ve called mine `DreamhouseNotificationService`.

![](readme/notificationservice-target.png)


## NotificationService class
The target will generate a stub class, `NotificationService`, for you.  The first thing we need to do is create a mutable copy of the message which we can modify its contents. Yes, it seems a little bit of double effort to create a mutable copy, once we have already told the APS that this is what we intend to do. Without the mutable-content flag in the APS payload, service extensions do not even get called in the notification lifecycle. 

Add the following lines to your didReceive function:

```
self.contentHandler = contentHandler
	bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
	
	if let bestAttemptContent = bestAttemptContent {
		//we will add our logic here
	}
        
```

Next, we want to add the logic to fetch the remote image, and convert it to a local file. Once we have converted it, we can reattach the file to the notifications attachments for display.  Replace the line `//we will add our logic here`, with the following code:

```
if let urlString = request.content.userInfo["media-attachment"] as? String, let fileUrl = URL(string: urlString) {
	URLSession.shared.downloadTask(with: fileUrl) { (location, response, error) in
		if let location = location {
         let options = [UNNotificationAttachmentOptionsTypeHintKey: kUTTypeJPEG]
         if let attachment = try? UNNotificationAttachment(identifier: "", url: location, options: options) {
                      self.bestAttemptContent?.attachments = [attachment]
                        }
                    }
                   self.contentHandler!(self.bestAttemptContent!)
      }.resume()
}

```

That’s it. Now, whenever an push notification is received by the app, and if mutable-content is set to “1”, the Notification Extension will be executed. Of course, in many app, you may have lots of different notifications.  Our code handles this by checking for the existence of the media-attachment element, and does not modify anything else in the message. The result is that this Notification Service is very generic: if there is a notification that contains a Url to image, lets download it.

## Testing it out
To test our app, we could get the Salesforce admin to change a properties price multiple times, but that not the most efficient way. Sooner or later, the admin will have to work on other projects and may not be able to respond to as quickly as you need. When testing push notifications, I like to use a app called Boodle. Boodle, and many other tools (search the App Store for ‘apns’ if you want to check some out)  tester allows you to associate an Apple Push Notification Sandbox certificate, and a JSON payload which will be delivered to your app.  I use Boodle because I often need to customize the JSON payload, and support testing for both Apple and Android devices.

[TODO: insert PIC]

If everything goes well, when you send messages, notifications on your app should look something like this. Cool huh!

![](readme/https://github.com/quintonwall/salesforce-tutorials/blob/master/ios10-richmedia-push-notifications/graphics/push-expanded.png?raw=true)

Once you know your apps is receiving push notifications correctly via APNS testing tools like Boodle, you can try sending the notification from Salesforce using the InvocableMethod we created in the previous tutorial. 



## A complete example
This tutorial relies on the [Dreamhouse](https//dreamhouseapp.io) app schema and process flows, plus the InvocableMethod created in Part 1. For a complete iOS app example containing the the Notification Service, and much more, check out the [DreamhouseAnywhere](https://github.com/quintonwall/DreamhouseAnywhere) iOS app.

## Found an Error? Want to Contribute?
This tutorial is a github repo. If you find an error, or have something to add, please [create a pull request](https://github.com/quintonwall/salesforce-tutorials/pulls).

#work