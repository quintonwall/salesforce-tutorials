# Sending Rich Push Notifications for iOS 10 with Process Builder and the Salesforce Universal Notification Framework. 

## Introduction
[Process Builder](https://trailhead.salesforce.com/modules/business_process_automation/units/process_builder) , Salesforce.com’s App Cloud tool to visually create business processes, is powerful way to automate new or existing processes. ProcessBuilder provides a number of actions to perform typical tasks such as email users, update records, post to Chatter, and more. It also supports the ability to plug in custom functions declared with the [@InvocableMethod](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_annotation_InvocableMethod.htm) annotation.  

The Dreamhouse reference app [http://www.dreamhouseapp.io/process-builder/](http://www.dreamhouseapp.io/process-builder/) and InvocableMethod to send push notifications, when a property’s price changes, to customers who have favorited a property. This implementation in the reference app works well, however, we can tweak it to make it even better. This tutorial will show you how to replace the custom push notification approach with the native Salesforce Universal Notification Framework, and how to send messages that confirm to the [new rich media format for push messages introduced in IOS10](https://developer.apple.com/videos/play/wwdc2016/708/) .  In my opinion, the Salesforce Universal Notification framework is a highly under utilized part of the platform. In fact, before this tutorial, I bet you didn’t even know it existed!

This tutorial is targeted towards the Salesforce administrator. Let’s get started.

## Add Apple Push Notification Certificate
The first thing you need to do to use the Universal Notification Framework to send push messages to iOS devices is add a valid Apple push notification certificate to the connected app your mobile device uses to authenticate users with.  The Dreamhouse app already provides a connected app we can configure. Follow the instructions [here](https://developer.salesforce.com/docs/atlas.en-us.mobile_sdk.meta/mobile_sdk/push_ios_conn_app.htm) to add a valid certification to your connected app.

## Install iOSRichMediaMessaging Package
iOS10 introduced the ability to send rich media, such as images, as part of a push notification. In order to send these notifications, the developer must create a well formed JSON message payload. To make it easy, I’ve gone ahead and created a simple helper class that does all the formatting for you. Go ahead and [install the iOSRichMediaMessaging package](javascript:srcUp(‘https%3A%2F%2Flogin.salesforce.com%2Fpackaging%2FinstallPackage.apexp%3Fp0%3D04t360000011x0E%26isdtp%3Dp1’);) now. We will use it in the next step.

The package installed a global Apex class, `RichMediaPushNotification`, with two methods: `createMutablePayload` and `createNonMutablePayload`. Both methods require the same parameters (title, subtitle, body, and imageUrl), but createMutablePayload tells the Apple Push notification Service (APS) that the iOS developer may intercept the message and change it. We will go more into why this is important for our use case in the second part of this tutorial where I will show you how to handle the push notification in your iOS app, but for now, you have to trust me and know you will need to use the createMutablePayload method for this tutorial.



## Update Invocable Method to Support Universal Notification Framework
When you installed the unmanaged package for the Dreamhouse app, an Apex Class, PushPriceChangeNotification was installed. This class defines an invocable method called pushNotification.

```
 @InvocableMethod(label='Push Price Change Notification')
    public static void pushNotification(List<Id> propertyId)
```

Go ahead and delete the body of this method. We are going to rewrite it to use the Universal Notification Framework.  First add, the following lines of code, which are actually mostly  the same as what we deleted. Just like the implementation which comes with the Dreamhouse app, we want to fetch anyone who has favorited our property.

```
 Id propId = propertyId[0]; // If bulk, only post first to avoid spamming
        System.debug('Price updated on property id '+propId);
        Property__c property = [SELECT Name, Picture__c, Price__c from Property__c WHERE Id=:propId];
        String message = property.Name + '. New Price: $' + property.Price__c.setScale(0).format();

        Set<String> userIds = new Set<String>();

        List<Favorite__c> favorites = [SELECT user__c, user__r.Name from favorite__c WHERE property__c=:propId AND User__c != null];
        for (Favorite__c favorite : favorites) {
            userIds.add(favorite.user__c);
        }
```

Now, things change for our new implementation.

```
 Messaging.PushNotification msg = new Messaging.PushNotification();


         String title = 'Price Changed to $'+property.Price__c.setScale(0).format();
         String subtitle = property.Name;
         String body = 'Heads up! The list price on a property you favorited has just been reduced.';
         String imageUrl = property.Picture__c;
         Map<String, Object> payload = RichMediaPushNotification.createMutablePayload(title,subtitle,body,imageUrl);
         msg.setPayload(payload);
        msg.send('DreamhouseNativeMobile', userIds);
```

And that’s about it! The code is pretty straight forward. The first thing we need to do is get an instance of the Universal Notification framework, then define the values we want to pass to our RichMediaPushNotificationFramework, which now also includes the URL of the property picture (stored in Picture__c in the Dreamhouse Property object).

If you need it, the full class is available [here](https://gist.github.com/quintonwall/5a49d1a26d4e35dbd625eaeb96717973) .

## What Happens Now?
For our cloud implementation, that’s it. We already have the Process Builder flow which executes on price change, and now, our new and improved invocable method will send the push notification via Apple’s Push notification Service will a fancy new look.

![](Sending%20Rich%20Push%20Notifications%20for%20iOS%2010%20with%20Process%20Builder%20and%20the%20Salesforce%20Universal%20Notification%20Framework./push-compact.png)

In the second part of this tutorial, we will update our iOS app to register for push notifications from Salesforce, and to handle the property image.

## Found an Error? Want to Contribute?
This tutorial is a github repo. If you find an error, or have something to add, please create a pull request.



#work
